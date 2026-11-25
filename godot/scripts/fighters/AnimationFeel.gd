class_name AnimationFeel
extends RefCounted
## Stefan Iverson Virtual Mentor 2D-to-3D fighting-animation overhaul — shared maths.
##
## Every number and curve the presentation layer uses for combat feel lives here so the
## runtime (`FighterModel3D`) and the headless audit (`tools/animation_feel_audit.gd`) read
## the exact same rules instead of re-deriving them. Nothing in this file touches combat:
## hitboxes, hurtboxes, startup/active/recovery ticks, damage, the 132 BPM beat clock and
## the 31 Patois entries stay in `BaseFighter` / `FighterRoster` untouched.
##
## The six systems, in the owner's order:
##   1. stepped arcade pose quantization (`stepped_arcade`, `quantize`)
##   2. the non-linear attack curve (`startup_progress` -> `active_progress` -> `recovery_progress`)
##   3. whole-body engagement / negative space (angles below, applied by `FightBodyModifier3D`)
##   4. alive hitstop micro-tension (`tension_amount`)
##   5. the `SquashPivot` volume-preserving impact pop (`squash_target`, `spring_step`)
##   6. the additive hit-react overlay (`recoil_strength`, `recoil_curve`) + ground pinning

# =========================================================================
# 1. Stepped arcade pose quantization
# =========================================================================
## Discrete pose steps per second while an attack, hitstun, blockstun or taunt owns the
## body. The world root, the collision body and the camera keep running at a smooth 60 fps;
## only the sampled skeleton frame is held, which is what makes a strike read as
## anticipation -> breakdown -> hit instead of one linear smear. 18 fps sits inside the
## owner's 16–20 fps band.
const STEPPED_FPS := 18.0
## Live toggle (`F4` in the arena). Static so one key press reaches every 3D proxy.
static var stepped_arcade := true


## Snap a normalised clip time onto the stepped grid. `steps` is the number of discrete
## poses the whole clip offers at `STEPPED_FPS`; with `steps <= 1` the value is untouched.
static func quantize(t: float, steps: int) -> float:
	if steps <= 1:
		return t
	return floor(clampf(t, 0.0, 1.0) * float(steps)) / float(steps)


## Number of discrete poses a clip of `length` seconds offers at the stepped rate. `fps`
## defaults to the shared 18 and is supplied by `FighterModel3D.step_fps`, so a designer can
## re-grid one body from the inspector inside the owner's 16–20 band.
static func step_count(length: float, fps: float = STEPPED_FPS) -> int:
	return maxi(1, int(round(length * clampf(fps, 16.0, 20.0))))


# =========================================================================
# 2. Non-linear attack curve — Coil -> 1-frame whip -> overshoot -> settle -> recovery
# =========================================================================
## Where the anticipation hold ends and the whip begins, as a fraction of the attack clip.
## Startup compresses into `0.0 -> 0.35`, so the body is visibly coiled before contact.
const COIL_END := 0.35
## Frames of `ACTIVE` the whip takes to cross the breakdown poses into `t_impact`.
const WHIP_FRAMES := 2
## Frames after the whip where the extended silhouette settles and holds.
const SETTLE_FRAMES := 3
## Extra clip travel the settle is allowed (the pose keeps driving a hair past contact).
const SETTLE_DRIFT := 0.02
## The crisp overshoot impulse, in degrees, on the upper spine/shoulder.
const OVERSHOOT_DEG := 4.0
## `ACTIVE`-frame ramp of the overshoot: full on frames 1–2, gone by frame 4.
const OVERSHOOT_RAMP := [0.60, 1.00, 0.85, 0.45]
## Sanity band for a measured `t_impact`; a clip that peaks outside it is clamped in.
const IMPACT_MIN := 0.36
const IMPACT_MAX := 0.62


## `STARTUP`: compress and hold into the coil. Slower than linear at the start (the body
## gathers), landing exactly on `COIL_END` at the last startup tick.
static func startup_progress(p: float) -> float:
	return COIL_END * pow(clampf(p, 0.0, 1.0), 1.6)


## `ACTIVE`: a 1–2 frame whip from the coil across the breakdown poses to the measured
## `t_impact`, then a 2–4 frame settle that keeps the extended silhouette. `frame` is the
## fighter's own `state_frame`, so hitstop (which does not advance it) holds the pose.
static func active_progress(frame: int, t_impact: float) -> float:
	if frame <= 0:
		return COIL_END
	var whip := clampf(float(mini(frame, WHIP_FRAMES)) / float(WHIP_FRAMES), 0.0, 1.0)
	if frame <= WHIP_FRAMES:
		# Ease-out, so frame 1 is already three quarters of the way onto contact and the
		# clip has visibly snapped across the breakdown poses rather than crept to them.
		var eased := 1.0 - (1.0 - whip) * (1.0 - whip)
		return lerpf(COIL_END, t_impact, eased)
	var settle := clampf(float(frame - WHIP_FRAMES) / float(maxi(1, SETTLE_FRAMES)), 0.0, 1.0)
	return lerpf(t_impact, minf(t_impact + SETTLE_DRIFT, 1.0), settle)


## `RECOVERY`: ease the extended contact pose back to the fighter's stance.
static func recovery_progress(p: float, t_impact: float) -> float:
	var eased := smoothstep(0.0, 1.0, clampf(p, 0.0, 1.0))
	return lerpf(t_impact, 1.0, eased)


## The overshoot impulse in radians for an `ACTIVE` frame: +4° on frames 1–2, settling to
## zero by frame 4. Applied to the upper spine and the striking shoulder so the contact
## pose snaps past its target and relaxes instead of arriving dead.
static func overshoot_lean(frame: int) -> float:
	if frame < 0 or frame >= OVERSHOOT_RAMP.size():
		return 0.0
	return deg_to_rad(OVERSHOOT_DEG) * float(OVERSHOOT_RAMP[frame])


## `HITSTUN` / blockstun clip progress: an instant snap into the recoil, then a slow settle.
static func hit_clip_progress(p: float) -> float:
	return pow(clampf(p, 0.0, 1.0), 0.45)


# =========================================================================
# 3. Whole-body engagement + Wolverine small-screen negative space
# =========================================================================
## KOF Vanessa-style shoulder/upper-spine counter-twist on a strike, radians at full weight.
const ENGAGE_TWIST := 0.22
## How far the off-arm is carried clear of the ribcage in a stance, radians (7°).
const NEGATIVE_SPACE := 0.12
## Head/eye-line awareness toward camera, radians (6°). Small on purpose: it must read as
## "aware of the crowd" without moving the hips or the fighting axis.
const EYE_LINE := 0.105


# =========================================================================
# 4. Alive hitstop / impact micro-tension
# =========================================================================
## Peak micro-tension on the attacker's secondary upper-body bones while a contact is held
## frozen, radians. Charged, never visibly vibrating.
const TENSION_PEAK := 0.012
const TENSION_HZ := 7.5
## Defender X-shake during hitstop, metres either side of the planted pose.
const HITSTOP_SHAKE := 0.012


static func tension_amount(clock: float, hitstop: bool) -> float:
	if not hitstop:
		return 0.0
	return sin(clock * TAU * TENSION_HZ) * TENSION_PEAK


# =========================================================================
# 5. SquashPivot volume-preserving impact pop
# =========================================================================
## Anticipation / landing / knockdown: wider and shorter, volume preserved.
const SQUASH_POP := Vector3(1.06, 0.92, 1.06)
## Heavy and special contact: longer and narrower.
const SQUASH_STRETCH := Vector3(1.07, 1.04, 0.95)
## A light strike gets half of the stretch so light exchanges stay clean.
const SQUASH_LIGHT_WEIGHT := 0.5
## Damped spring back to rest: stiff enough to snap, damped enough never to wobble.
const SQUASH_STIFFNESS := 210.0
const SQUASH_DAMPING := 26.0

## `CROUCH`/`KNOCKDOWN`-style compression shared by every fighter.
const SQUASH_LANDING := Vector3(1.06, 0.92, 1.06)


## Target scale for the impact pop, from the fighter's own combat phase. Returns
## `Vector3.ONE` when nothing is landing.
static func squash_target(state: int, state_frame: int, startup_ticks: int,
		active: bool, heavy: bool, hitstop: bool) -> Vector3:
	if state == BaseFighter.State.ATTACK_STARTUP:
		# The coil compresses as the startup completes, so the whip starts from a loaded body.
		var p := clampf(float(state_frame) / float(maxi(1, startup_ticks)), 0.0, 1.0)
		return Vector3.ONE.lerp(SQUASH_POP, smoothstep(0.55, 1.0, p))
	if state == BaseFighter.State.ATTACK_ACTIVE or (active and hitstop):
		return SQUASH_STRETCH if heavy else Vector3.ONE.lerp(SQUASH_STRETCH, SQUASH_LIGHT_WEIGHT)
	if state == BaseFighter.State.HITSTUN:
		return SQUASH_POP
	if state == BaseFighter.State.KNOCKDOWN or state == BaseFighter.State.KO:
		return SQUASH_LANDING
	return Vector3.ONE


## One damped-spring step toward `target`. Returns `[current, velocity]`; the caller keeps
## both, so the pop decays cleanly back to `Vector3.ONE` with no frame-rate dependence.
static func spring_step(current: Vector3, velocity: Vector3, target: Vector3,
		delta: float, stiffness: float = SQUASH_STIFFNESS,
		damping: float = SQUASH_DAMPING) -> Array:
	var accel := (target - current) * stiffness - velocity * damping
	var next_velocity := velocity + accel * delta
	var next := current + next_velocity * delta
	if next.distance_to(Vector3.ONE) < 0.0004 and next_velocity.length() < 0.002:
		return [Vector3.ONE, Vector3.ZERO]
	return [next, next_velocity]


# =========================================================================
# 6. Additive hit-react overlay
# =========================================================================
## Recoil strength by contact: a blocked hit barely moves the spine, a light jab rocks it,
## a heavy strike or a counter-hit whips it. Read from the existing `strike_resolved`
## result, never injected into combat.
const RECOIL_BLOCKED := 0.40
const RECOIL_LIGHT := 0.55
const RECOIL_HEAVY := 1.00
const RECOIL_COUNTER := 1.35
## Seconds the additive whip takes to travel head-to-spine and settle.
const RECOIL_SECONDS := 0.42


static func recoil_strength(damage: int, blocked: bool, counter: bool) -> float:
	if counter:
		return RECOIL_COUNTER
	if blocked:
		return RECOIL_BLOCKED
	if damage >= 14:
		return RECOIL_HEAVY
	return RECOIL_LIGHT


## 1 at the moment of contact (an instant whip), decaying to 0 over `RECOIL_SECONDS`.
static func recoil_curve(age: float) -> float:
	var p := clampf(age / RECOIL_SECONDS, 0.0, 1.0)
	if p >= 1.0:
		return 0.0
	return (1.0 - p) * (1.0 - p)


# =========================================================================
# Ground pinning
# =========================================================================
## A planted foot/toe bone sits flush on the sand: the lowest *drawn* sole is allowed to
## miss world y 0 by at most this much.
const GROUND_PIN_TOLERANCE := 0.01

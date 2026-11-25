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
## Anticipation depth: a jab gathers only to 0.42 of the clip, a full-weight heavy winds all
## the way to 0.30, so the two never read as the same swing. Visual only: the depth changes
## which pose is held, never when `ACTIVE` starts, how long it lasts or what it hits.
const COIL_END_LIGHT := 0.42
const COIL_END_HEAVY := 0.30


## Visual weight of a move, from the contact damage it already carries. Reading `damage`
## here is a read-only presentation input — the value itself is owned by `FighterRoster` and
## is never written back.
static func move_weight(damage: int) -> float:
	return clampf(float(damage) / 15.0, 0.35, 1.0)


## Where the coil ends for a move of this weight. `COIL_END` stays the neutral value used
## when the weight is unknown (and by the fixed-position curves).
static func coil_end(weight: float) -> float:
	return lerpf(COIL_END_LIGHT, COIL_END_HEAVY, clampf(weight, 0.0, 1.0))


## `STARTUP`: compress and hold into the coil. Slower than linear at the start (the body
## gathers), landing exactly on `coil` at the last startup tick.
static func startup_progress(p: float, coil: float = COIL_END) -> float:
	return clampf(coil, 0.0, 1.0) * pow(clampf(p, 0.0, 1.0), 1.6)


## `ACTIVE`: a 1–2 frame whip from the coil across the breakdown poses to the measured
## `t_impact`, then a 2–4 frame settle that keeps the extended silhouette. `frame` is the
## fighter's own `state_frame`, so hitstop (which does not advance it) holds the pose.
static func active_progress(frame: int, t_impact: float, coil: float = COIL_END) -> float:
	if frame <= 0:
		return clampf(coil, 0.0, 1.0)
	var whip := clampf(float(mini(frame, WHIP_FRAMES)) / float(WHIP_FRAMES), 0.0, 1.0)
	if frame <= WHIP_FRAMES:
		# Ease-out, so frame 1 is already three quarters of the way onto contact and the
		# clip has visibly snapped across the breakdown poses rather than crept to them.
		var eased := 1.0 - (1.0 - whip) * (1.0 - whip)
		return lerpf(clampf(coil, 0.0, 1.0), t_impact, eased)
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


# --- Arc enforcement: the swing travels a curve, not a straight line -----------------
## Lateral travel of the striking side through the whip, radians at full weight. The
## shoulder leads and the elbow trails, so the limb traces an arc instead of sliding along a
## straight line to the target — the reason a real punch reads as a body movement rather
## than a limb being translated.
const ARC_SWING := 0.16
## Extra lateral push *past* the target on the whip, radians. The overshoot is not only a
## pitch: the contact frame leans a hair beyond its own arc, which is what makes it snap.
const ARC_LATERAL_OVERSHOOT := 0.05
## `ACTIVE`-frame shape of the arc: full on the whip frame, unwinding through the settle.
const ARC_RAMP := [0.0, 1.0, 0.55, 0.20, 0.0]
## `ACTIVE` frame the whip is measured on (the first frame after the coil).
const WHIP_FRAME := 1
## Length of the cartoon limb smear, in frames. Exactly one: a smear that lasts is a bug.
const SMEAR_FRAMES := 1
## Peak stretch along the striking limb during that frame. Bone scale only, so the skin
## follows the bone and nothing is re-exported, re-skinned or turned into extra geometry.
const SMEAR_STRETCH := 0.14


## Signed lateral bias of the swing for an `ACTIVE` frame, radians. Multiply by the facing
## sign before applying: the arc leads out of the fighting side, never across the body.
static func arc_bias(frame: int, weight: float) -> float:
	if frame < 0 or frame >= ARC_RAMP.size():
		return 0.0
	var ramp := float(ARC_RAMP[frame])
	if ramp <= 0.0:
		return 0.0
	var lateral := ARC_LATERAL_OVERSHOOT if frame <= WHIP_FRAMES else 0.0
	return (ARC_SWING * ramp + lateral * ramp) * clampf(weight, 0.0, 1.0)


## 0–1 smear amount for an `ACTIVE` frame: full on the whip frame, zero everywhere else. The
## smear is deliberately one frame — it is the arcade tell for the fastest pose change in the
## move, not an effect that lingers over the contact.
static func smear_amount(frame: int) -> float:
	return 1.0 if frame == WHIP_FRAME else 0.0


## Volume-preserving stretch along the bone's own length for the smear.
static func smear_scale(amount: float) -> Vector3:
	var stretch := 1.0 + SMEAR_STRETCH * clampf(amount, 0.0, 1.0)
	var thin := 1.0 / sqrt(stretch)
	return Vector3(thin, stretch, thin)


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
## Chest cheat toward camera at the strike pose, radians (4.3°). The whole chest turns a few
## degrees out of pure profile so the contact silhouette opens up on a small screen instead
## of reading as a line. Absolute (not facing-signed): it always faces the camera.
const CHEST_CHEAT := 0.075
## Ceiling on the additive yaw ONE bone may receive, radians (17°). The layer is a garnish on
## top of a baked take, not a second animation, so a single system can never put a quarter turn
## into a spine.
const MAX_BONE_YAW := 0.30
## Ceiling on the additive yaw the whole layer may spend on one frame, radians (69°). Every
## system asking for its maximum at once fits inside it (measured 0.94 rad in the strike pose),
## so the cap only ever bites on a runaway request, and the hips — the facing authority — are
## never in the budget at all.
const INFLUENCE_CAP := 1.20


# =========================================================================
# 4. Alive hitstop / impact micro-tension
# =========================================================================
## Peak micro-tension on the attacker's secondary upper-body bones while a contact is held
## frozen, radians. Charged, never visibly vibrating.
const TENSION_PEAK := 0.012
const TENSION_HZ := 7.5
## Defender X-shake during hitstop, metres either side of the planted pose.
const HITSTOP_SHAKE := 0.012

# --- Hit-stop camera punch ---------------------------------------------------------------
## The camera answers a frozen contact with a tiny widening FOV kick and a hair of vertical
## offset, then a damped scalar spring carries both back to rest over a few frames. It is
## impulse-then-spring, never a step: the camera keeps integrating every presented frame at
## 60 fps, so a hit-stop cannot judder the view.
const CAMERA_PUNCH_FOV_DEG := 1.15
const CAMERA_PUNCH_OFFSET_M := 0.012
const CAMERA_PUNCH_STIFFNESS := 96.0
const CAMERA_PUNCH_DAMPING := 13.5
## Ceiling on one punched frame, so a stacked counter + K.O. cannot swing the lens wide.
const CAMERA_PUNCH_MAX := 1.6


static func tension_amount(clock: float, hitstop: bool) -> float:
	if not hitstop:
		return 0.0
	return sin(clock * TAU * TENSION_HZ) * TENSION_PEAK


## Camera punch impulse for a contact that froze the fight for `frames` ticks. A jab's
## 4-tick stop is a flick; a K.O.'s longer stop is a full lens kick, still clamped inside
## `CAMERA_PUNCH_MAX`. Visual only — the hit-stop itself stays in the combat FSM.
static func camera_punch(frames: int) -> float:
	if frames <= 0:
		return 0.0
	return clampf(float(frames) / 9.0, 0.18, CAMERA_PUNCH_MAX)


# =========================================================================
# 5. SquashPivot volume-preserving impact pop
# =========================================================================
## Anticipation / landing / knockdown: wider and shorter. Every preset below is authored so
## `x * y * z == 1.0` by construction — a body that squashes must not also swell, or the
## silhouette gains weight it does not have. `volume_preserve()` then pins the product at
## exactly 1.0 on every frame the spring passes through, including the interpolation.
const SQUASH_POP := Vector3(1.06, 0.89, 1.06)
## Heavy and special contact: taller and wider, thinner into the depth axis (which the camera
## looks along, so the stretch reads up and across the sand instead of toward the lens).
const SQUASH_STRETCH := Vector3(1.06, 1.02, 0.925)
## A light strike gets half of the stretch so light exchanges stay clean.
const SQUASH_LIGHT_WEIGHT := 0.5
## Damped spring back to rest: stiff enough to snap, damped enough never to wobble.
const SQUASH_STIFFNESS := 210.0
const SQUASH_DAMPING := 26.0
## How far the impact pop's scale product may drift from 1.0. The presets are exact; this is
## the guard the audit holds the live `SquashPivot` to, including mid-spring frames.
const SQUASH_VOLUME_TOLERANCE := 0.02

## `CROUCH`/`KNOCKDOWN`-style compression shared by every fighter.
const SQUASH_LANDING := Vector3(1.06, 0.89, 1.06)


## Volume of a scale triple: 1.0 means the body gained or lost nothing.
static func squash_volume(s: Vector3) -> float:
	return s.x * s.y * s.z


## Renormalise a scale triple so its product is exactly 1.0. Interpolating a spring between
## `Vector3.ONE` and a volume-preserving target does NOT preserve volume (the product is
## multiplicative, the interpolation linear), so every frame the pop writes goes through
## here. A degenerate triple returns `Vector3.ONE` rather than a division blow-up.
static func volume_preserve(s: Vector3) -> Vector3:
	var v := s.x * s.y * s.z
	if v <= 0.000001:
		return Vector3.ONE
	var k := pow(v, -1.0 / 3.0)
	return Vector3(s.x * k, s.y * k, s.z * k)


## Scalar version of `spring_step`, for values that are not a Vector3 — the camera's hit-stop
## punch. Same stiffness/damping contract: a snap out, then a clean settle with no wobble.
static func spring_scalar_step(current: float, velocity: float, target: float,
		delta: float, stiffness: float = SQUASH_STIFFNESS,
		damping: float = SQUASH_DAMPING) -> Array:
	var accel := (target - current) * stiffness - velocity * damping
	var next_velocity := velocity + accel * delta
	var next := current + next_velocity * delta
	if absf(next - target) < 0.0002 and absf(next_velocity) < 0.002:
		return [target, 0.0]
	return [next, next_velocity]


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

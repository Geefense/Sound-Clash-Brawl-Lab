class_name Arena3D
extends Node3D
## 3D Sound Clash yard presentation (AGENTS.md §9 item 43–45).
##
## Presentation only. The authoritative fight still runs in the 2D `BaseFighter` bodies —
## hitboxes, hurtboxes, push separation, input buffering, beat judgement, the round clock and
## the Patois callouts are untouched. This node mirrors both fighters onto a 3D fighting
## plane, builds the sand yard out of real geometry, and lights it with DirectionalLight3D /
## SpotLight3D / OmniLight3D rigs for Afternoon, Sunset and Night.
##
## Layout: 140 px = 1 m, the 2D floor line (y 600) is world y 0, the stage centre (x 640) is
## world x 0. The fighters stay on the z 0 plane (classic 2.5D): only x/y move, the stage
## gains real depth behind them.
##
## WebGL2: gl_compatibility-safe meshes, shaders and lights only. No GPU particles, no
## screen-space effects, no SDFGI/SSAO/volumetric fog; contact shadows are soft quads and
## the speaker cones are scaled on the beat.

const PX_PER_M := 140.0
const FLOOR_PX := 600.0
const CENTER_PX := 640.0
const STAGE_LEFT_PX := 70.0
const STAGE_RIGHT_PX := 1210.0

const CAMERA_FOV := 30.0
## Bug 3 (2026-11-25): 5% tighter than the old 4.80 m so the fighters read larger on a phone,
## chosen to keep the roster's 55–65 % screen-height framing check inside its band.
const CAMERA_DISTANCE := 4.58
## Framing dolly ceiling: when the fighters spread to the stage bounds the lens eases back
## just enough to keep both bodies (head, hips, feet) inside the frame. Neutral spacing never
## leaves `CAMERA_DISTANCE`, so the tighter default is what the player sees in a normal
## exchange.
const CAMERA_MAX_DISTANCE := 9.0
const CAMERA_HEIGHT := 1.0
const CAMERA_FOLLOW := 7.0
const CAMERA_MIN_X := -1.78
const CAMERA_MAX_X := 1.78

## Commit 5: how much extra energy the existing spots take at a full eruption peak.
const ERUPT_LIGHT_PUMP := 0.55

const MAX_BURSTS := 4
const NOTE_SPARK := 0.35
const NOTE_HEAVY := 1.0

const MODEL_SCRIPT := preload("res://scripts/fighters/FighterModel3D.gd")
const BILLBOARD_SCRIPT := preload("res://scripts/fighters/FighterBillboard3D.gd")
const CROWD_SCRIPT := preload("res://scripts/stages/CrowdController3D.gd")
const BOOTH_SCRIPT := preload("res://scripts/stages/DJBooth3D.gd")
const BURST_SCRIPT := preload("res://scripts/stages/MusicNoteBurst.gd")
const CONTACT_SHADOW := preload("res://assets/shaders/contact_shadow.gdshader")
const LIGHT_POOL := preload("res://assets/shaders/light_pool.gdshader")
const SKY_SHADER := preload("res://assets/shaders/sky_gradient.gdshader")
const SUN_SHADER := preload("res://assets/shaders/sun_disc.gdshader")

## The three round rigs. Every value is pushed into real scene objects: a DirectionalLight3D
## sun, two overhead SpotLight3Ds, a warm rim/fill, the sky gradient, depth fog and the
## visible pool on the sand. Nothing here is a full-screen tint.
const PHASES := [
	# AFTERNOON — vibrant Jamaican midday. A high, hard golden key (#FFD27A) over a tropical
	# blue zenith (#1E6FD9) that fades through a light blue mid band into a pale golden haze
	# horizon (#FFE7B0). The sand sits warm and bright under it, and the spots rest.
	{
		"name": "Afternoon Sun",
		"sky_top": Color(0.118, 0.435, 0.851, 1.0),
		"sky_mid": Color(0.42, 0.68, 0.96, 1.0),
		"sky_bottom": Color(1.0, 0.906, 0.690, 1.0),
		"sky_haze": Color(1.0, 0.945, 0.760, 1.0),
		"sky_mid_point": 0.52,
		"haze_height": 0.22,
		"haze_strength": 0.45,
		"sun_colour": Color(1.0, 0.824, 0.478, 1.0),
		"sun_energy": 2.05,
		"sun_rotation": Vector3(-52.0, -34.0, 0.0),
		"ambient": Color(0.44, 0.60, 0.90, 1.0),
		"ambient_energy": 0.55,
		"fill_colour": Color(0.62, 0.78, 1.0, 1.0),
		"fill_energy": 0.30,
		"fog": Color(0.93, 0.94, 0.96, 1.0),
		"fog_density": 0.0026,
		"sand": Color(0.88, 0.72, 0.46, 1.0),
		"mound": Color(0.80, 0.62, 0.38, 1.0),
		"horizon": Color(0.86, 0.86, 0.80, 1.0),
		"spot_colour": Color(1.0, 0.94, 0.80, 1.0),
		"stage_a": Color(1.0, 0.94, 0.80, 1.0),
		"stage_b": Color(0.90, 0.96, 1.0, 1.0),
		"stage_c": Color(1.0, 0.90, 0.70, 1.0),
		"stage_d": Color(0.85, 0.95, 1.0, 1.0),
		"stage_energy": 0.20,
		"stage_pulse": 0.04,
		"pool": Color(1.0, 0.88, 0.62, 1.0),
		"pool_alpha": 0.10,
		"rim": Color(1.0, 0.85, 0.52, 1.0),
		"rim_energy": 0.85,
		# Commit 3: the fighter cel rim per preset. Warm cream against a blue afternoon sky,
		# so the body's edge separates without fighting the key light.
		"cel_rim": Color(1.0, 0.88, 0.62, 1.0),
		"cel_rim_strength": 0.55,
		"disc": 0.35,
		"disc_colour": Color(1.0, 0.95, 0.78, 1.0),
		"disc_pos": Vector3(-3.4, 3.1, -13.6),
		"disc_size": 4.0,
	},
	# SUNSET — Kingston dusk. A violet zenith (#3B1D6E) through a crimson band (#D6336C) into
	# an orange horizon (#FF7A1A), a low warm sun (#FF9A4D) at 10° elevation and a hot
	# orange-red rim (#FF5A36). The sand burns warm and the fog goes amber.
	{
		"name": "Golden Hour / Sunset Clash",
		"sky_top": Color(0.231, 0.114, 0.431, 1.0),
		"sky_mid": Color(0.839, 0.200, 0.424, 1.0),
		"sky_bottom": Color(1.0, 0.478, 0.102, 1.0),
		"sky_haze": Color(1.0, 0.640, 0.340, 1.0),
		"sky_mid_point": 0.46,
		"haze_height": 0.30,
		"haze_strength": 0.55,
		"sun_colour": Color(1.0, 0.604, 0.302, 1.0),
		"sun_energy": 1.75,
		"sun_rotation": Vector3(-10.0, -66.0, 0.0),
		"ambient": Color(0.66, 0.34, 0.52, 1.0),
		"ambient_energy": 0.50,
		"fill_colour": Color(0.78, 0.44, 1.0, 1.0),
		"fill_energy": 0.42,
		"fog": Color(0.98, 0.50, 0.34, 1.0),
		"fog_density": 0.0115,
		"sand": Color(0.94, 0.56, 0.34, 1.0),
		"mound": Color(0.86, 0.46, 0.28, 1.0),
		"horizon": Color(0.95, 0.55, 0.30, 1.0),
		"spot_colour": Color(1.0, 0.62, 0.30, 1.0),
		"stage_a": Color(1.0, 0.62, 0.30, 1.0),
		"stage_b": Color(0.95, 0.35, 0.62, 1.0),
		"stage_c": Color(1.0, 0.78, 0.38, 1.0),
		"stage_d": Color(0.85, 0.45, 1.0, 1.0),
		"stage_energy": 0.85,
		"stage_pulse": 0.10,
		"pool": Color(1.0, 0.56, 0.30, 1.0),
		"pool_alpha": 0.26,
		"rim": Color(1.0, 0.353, 0.212, 1.0),
		"rim_energy": 1.45,
		# Hot amber edge against the crimson band: the fighter reads as a silhouette lit from
		# behind instead of dissolving into the sunset.
		"cel_rim": Color(1.0, 0.62, 0.30, 1.0),
		"cel_rim_strength": 1.05,
		"disc": 1.0,
		"disc_colour": Color(1.0, 0.62, 0.26, 1.0),
		"disc_pos": Vector3(3.2, 1.30, -13.6),
		"disc_size": 7.0,
	},
	# NIGHT — deep indigo dancehall night. A cool moon key (#6F8CFF) at low energy still casts
	# the fighters' crisp shadow, the yard is carried by four coloured stage SpotLight3Ds —
	# cyan, magenta, amber, gold-amber — whose energy pulses on the 132 BPM beat.
	{
		"name": "Late-Night Sound Clash",
		"sky_top": Color(0.027, 0.043, 0.180, 1.0),
		"sky_mid": Color(0.090, 0.075, 0.280, 1.0),
		"sky_bottom": Color(0.165, 0.106, 0.369, 1.0),
		"sky_haze": Color(0.24, 0.18, 0.50, 1.0),
		"sky_mid_point": 0.50,
		"haze_height": 0.24,
		"haze_strength": 0.38,
		"sun_colour": Color(0.435, 0.549, 1.0, 1.0),
		"sun_energy": 0.16,
		"sun_rotation": Vector3(-64.0, 150.0, 0.0),
		"ambient": Color(0.12, 0.14, 0.34, 1.0),
		"ambient_energy": 0.34,
		"fill_colour": Color(0.28, 0.48, 1.0, 1.0),
		"fill_energy": 0.50,
		"fog": Color(0.05, 0.07, 0.19, 1.0),
		"fog_density": 0.019,
		"sand": Color(0.32, 0.32, 0.46, 1.0),
		"mound": Color(0.26, 0.26, 0.38, 1.0),
		"horizon": Color(0.14, 0.13, 0.30, 1.0),
		"spot_colour": Color(0.35, 0.85, 1.0, 1.0),
		"stage_a": Color(0.20, 0.95, 1.0, 1.0),
		"stage_b": Color(1.0, 0.16, 0.72, 1.0),
		"stage_c": Color(1.0, 0.62, 0.12, 1.0),
		"stage_d": Color(1.0, 0.80, 0.28, 1.0),
		"stage_energy": 2.60,
		"stage_pulse": 0.45,
		"pool": Color(0.42, 0.78, 1.0, 1.0),
		"pool_alpha": 0.42,
		"rim": Color(0.26, 0.92, 1.0, 1.0),
		"rim_energy": 1.60,
		# Cyan edge against the indigo night. It burns hardest here because the sky is darkest
		# and the fighters have to stay readable between the stage beams.
		"cel_rim": Color(0.42, 0.90, 1.0, 1.0),
		"cel_rim_strength": 1.30,
		"disc": 0.0,
		"disc_colour": Color(0.6, 0.8, 1.0, 1.0),
		"disc_pos": Vector3(-3.4, 3.1, -13.6),
		"disc_size": 4.0,
	},
]

var camera: Camera3D
var world_env: WorldEnvironment
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var rim: OmniLight3D
var spot_left: SpotLight3D
var spot_right: SpotLight3D
## Bug 5 (2026-11-25): two more stage spots, so the night rig is four coloured beams
## (cyan / magenta / amber / gold-amber) instead of one white wash. Two directional lights,
## one omni rim and four spots is seven lights — inside Compatibility's per-object limit.
var stage_spot_a: SpotLight3D
var stage_spot_b: SpotLight3D
## The yard's own surfaces, kept so the phase palette can re-grade them instead of only
## recolouring the light that falls on them.
var sand_material: StandardMaterial3D
var mound_material: StandardMaterial3D
var horizon_material: StandardMaterial3D
## 132 BPM, the same clock the fighters and the crowd skank on.
const BPM := 132.0
var _stage_energy_base: float = 0.0
var _stage_pulse_amount: float = 0.0
var _beat_phase: float = 0.0
## Commit 5: eruption pump on the EXISTING stage spots and booth lights. A scalar multiplier
## only — no light is created, moved or re-parented, so the 7-light Compatibility ceiling and
## `light_count()` are unchanged.
var _light_pump: float = 0.0
var sky_material: ShaderMaterial
var pool_material: ShaderMaterial
var sun_material: ShaderMaterial

var fighters: Dictionary = {}          # "p1"/"p2" -> BaseFighter
var models: Dictionary = {}            # "p1"/"p2" -> FighterModel3D or FighterBillboard3D
var shadows: Dictionary = {}           # "p1"/"p2" -> MeshInstance3D

## Sound-system slots: two delivered `.glb` towers, one a side (playtest fix 2026-11-24,
## issue 3). The procedural cabinets, baffles, 18" cones, corner brackets, Rasta trim,
## amp/EQ rack and VU LEDs are all deleted — no part of a tower is built in code any more.
var _sound_stacks: Array[PropLoader] = []
## 3D atmosphere (owner request, 2026-11-22): the DJ booth behind the decks and the
## staggered silhouette crowd. Both are presentation only and are ticked from `_process`.
var crowd3d: CrowdController3D = null
var dj_booth: DJBooth3D = null
var _pulse: float = 0.0
var _kick: float = 0.0
## Velocity of the hit-stop punch spring. The lens is impulse-then-spring, never stepped:
## `_update_camera` integrates it every presented frame at 60 fps, so a frozen contact can
## punch the view without the camera ever entering the combat tick.
var _kick_velocity: float = 0.0
## Last punch value written to the lens, read by the audit. Zero is a resting camera.
var camera_punch: float = 0.0
var _shake: float = 0.0
var _camera_x: float = 0.0
## Exchange lean (Bug 3): a critically damped scalar in radians, clamped to
## `AnimationFeel.CAMERA_YAW_MAX_DEG`, integrated every presented frame. Preallocated state;
## `_yaw_hold` lets the framing audit pin an extreme angle for a few frames.
var _camera_yaw: float = 0.0
var _camera_yaw_velocity: float = 0.0
var _yaw_hold: int = 0
var _camera_distance: float = CAMERA_DISTANCE
var _live_bursts: Array = []
## The fighter cel rim the current preset owns (commit 3), and the accent spring that gives
## a K.O. blow or a special its brief cinematic push. All presentation: the camera is never
## stepped by combat and the fighters' framing distance is computed from these values.
var _cel_rim := Color(1.0, 0.88, 0.62, 1.0)
var _cel_rim_strength := 0.55
var cinematic_accent: float = 0.0
var _accent: float = 0.0
var _accent_velocity: float = 0.0
var _accent_side: int = 0
var _accent_hold: int = 0
## Audit pin for the hit-stop punch, mirroring `_accent_hold`: `hold_camera_pressure()` holds the
## punch at its ceiling for a few presented frames so the yard clearance test can measure the
## true stacked maximum instead of an already-decaying spring.
var _kick_hold: int = 0
## Every box `_add_box()` builds (barrier rails and posts, horizon band, truss, fixtures, contact
## shadows). Kept by reference because Godot renames duplicate siblings to anonymous
## `@MeshInstance3D@N`, so the barrier's nine posts cannot be found by name afterwards.
var _yard_solids: Array[MeshInstance3D] = []
var _phase_index: int = 0
var _phase_now: Dictionary = {}
var _phase_from: Dictionary = {}
var _phase_to: Dictionary = {}
var _phase_age: float = 0.0
var _phase_duration: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20261121
	_build_environment()
	_build_camera()
	_build_yard()
	_build_speakers()
	_build_truss_and_lights()
	_build_dj_booth()
	_build_crowd()
	_apply_phase(PHASES[0])


# =========================================================================
# Public API
# =========================================================================
func setup(p1: BaseFighter, p2: BaseFighter) -> void:
	fighters = {"p1": p1, "p2": p2}
	for key in fighters:
		var fighter: BaseFighter = fighters[key]
		if fighter == null:
			continue
		var model: Node3D = _make_fighter(fighter)
		models[key] = model
		shadows[key] = _make_contact_shadow()
		model.position = Vector3(px_to_world_x(fighter.global_position.x), 0.0, 0.0)
	_camera_x = px_to_world_x((p1.global_position.x + p2.global_position.x) * 0.5) if p1 != null and p2 != null else 0.0
	_camera_distance = CAMERA_DISTANCE
	camera.position = Vector3(_camera_x, CAMERA_HEIGHT, CAMERA_DISTANCE)
	_apply_mirror_variants()
	# A model built after the preset was selected still gets that preset's rim.
	_push_cel_rim()


## Default FEEDBACK vs FEEDBACK showcase: both sides use the same uploaded 3D mesh, so P2
## gets the alternate cool/gold accent. Only a genuine mirror match is tinted; a different
## opponent keeps its own material.
func _apply_mirror_variants() -> void:
	var p1: BaseFighter = fighters.get("p1")
	var p2: BaseFighter = fighters.get("p2")
	if p1 == null or p2 == null or p1.fighter_key != p2.fighter_key:
		return
	var model := models.get("p2") as FighterModel3D
	if model != null:
		model.set_mirror_variant(true)


## Called by the arena on every FSM transition that has geometry to show.
func spawn_notes(at_px: Vector2, facing: int, heavy: bool) -> void:
	var at := px_to_world(at_px)
	var power := NOTE_HEAVY if heavy else NOTE_SPARK
	var angle := 0.0 if facing >= 0 else PI
	_spawn_burst(at, power, angle)


func spawn_spark(at_px: Vector2, style: StringName = &"hit") -> void:
	var at := px_to_world(at_px)
	var power := NOTE_SPARK
	if style == &"hit_onbeat" or style == &"parry" or style == &"slam":
		power = 0.7
	_spawn_burst(at, power, 0.0)


func spawn_strike_arc(at_px: Vector2, facing: int, heavy: bool) -> void:
	var at := px_to_world(at_px)
	_spawn_burst(at, NOTE_SPARK if not heavy else 0.7, 0.0 if facing >= 0 else PI)


## Bass thump: the subwoofer cones visibly punch out of the cabinets and settle back.
func pulse_speakers(strength: float = 1.0) -> void:
	_pulse = maxf(_pulse, clampf(strength, 0.0, 2.0))


## Heavy contact / KO / knockdown: a brief subtle zoom-in plus camera shake. Hit-stop itself
## stays in the combat FSM — this never freezes or changes simulation time.
func hit_kick(strength: float = 1.0) -> void:
	_kick = maxf(_kick, clampf(strength, 0.0, AnimationFeel.CAMERA_PUNCH_MAX))
	_shake = maxf(_shake, clampf(strength, 0.0, 1.4) * 0.045)


## Hit-stop camera punch: a tiny FOV/offset impulse sized by how long the contact froze the
## fight, carried back to rest by a damped scalar spring. Purely presentational — the ticks
## still belong to `BaseFighter`, and nothing here can move a fighter or a hitbox.
func hitstop_punch(stop_frames: int, strength: float = 1.0) -> void:
	var punch := AnimationFeel.camera_punch(stop_frames) * clampf(strength, 0.2, 1.4)
	if punch <= 0.0:
		return
	_kick = minf(AnimationFeel.CAMERA_PUNCH_MAX, maxf(_kick, punch))


## Round-winning K.O. blow / special activation: a brief clamped zoom-and-angle accent.
## It composites with the exchange lean and the hit-stop punch through one clamped total
## (`_update_camera`), decays on its own critically damped spring, and can never change the
## hit-stop's length or the input timing — it reads neither. `side` +1 leans toward P1's
## side of the frame, −1 toward P2's, 0 stays centred.
func accent_camera(side: int = 0, strength: float = 1.0) -> void:
	var want := clampf(strength, 0.0, 1.0) * AnimationFeel.CAMERA_ACCENT_MAX
	_accent = maxf(_accent, want)
	_accent_side = 0 if absi(side) > 1 else side
	_accent_hold = AnimationFeel.CAMERA_ACCENT_HOLD_FRAMES


## Hold the accent at its peak for `frames` presented frames, for the framing audit. `side`
## is passed through so the audit can exercise the accent's own ±yaw and not just its dolly:
## side +1 leans toward P1's side of the frame, −1 toward P2's, 0 stays centred.
func hold_cinematic_accent(strength: float = 1.0, frames: int = 3, side: int = 0) -> void:
	_accent = clampf(strength, 0.0, 1.0) * AnimationFeel.CAMERA_ACCENT_MAX
	_accent_velocity = 0.0
	_accent_side = clampi(side, -1, 1)
	_accent_hold = maxi(1, frames)


## The accent currently written to the lens; 0 is a resting camera.
func camera_accent() -> float:
	return cinematic_accent


func apply_phase(index: int, duration: float = 0.0) -> void:
	_phase_index = clampi(index, 0, PHASES.size() - 1)
	_phase_from = _phase_now.duplicate()
	var target: Dictionary = PHASES[_phase_index]
	_phase_to = target.duplicate()
	_phase_age = 0.0
	_phase_duration = maxf(duration, 0.0)
	if _phase_now.is_empty() or _phase_duration <= 0.0:
		_apply_phase(_phase_to)


func phase_name() -> String:
	var target: Dictionary = PHASES[_phase_index]
	return String(target["name"])


func active_bursts() -> int:
	_live_bursts = _live_bursts.filter(func(node): return is_instance_valid(node) and not node.is_queued_for_deletion())
	return _live_bursts.size()


# =========================================================================
# Active atmosphere — DJ booth and staggered crowd (owner request, 2026-11-22)
# =========================================================================
## One cue in, one coordinated reaction out. `TestArena` forwards the combat events it
## already receives (HIT_LANDED, HEAVY_HIT, KNOCKDOWN, K.O., VICTORY, plus DJ tags and Hype
## surges); nothing about the fight, the hitboxes or the audio is changed here.
## `side` 0 = P1's left corner, 1 = P2's right corner, −1 = a neutral roar.
func notify_combat_event(kind: StringName, side: int = -1, on_beat: bool = false) -> void:
	if dj_booth != null:
		dj_booth.react(kind, side)
	if crowd3d != null:
		crowd3d.react(kind, side)
	# Commit 5: the eruption is reserved for the moments the yard actually loses it — a big
	# impact, a heavy that landed on the beat, a special, a knockdown, the K.O. and a Hype
	# surge. Energy is READ from the hype meters (`_hype_energy()`), never written back, so
	# the Crowd Hype rules are untouched.
	var erupt := false
	match kind:
		&"heavy_hit", &"knockdown", &"ko", &"victory", &"hype", &"special":
			erupt = true
		&"hit":
			erupt = on_beat
	if erupt:
		if crowd3d != null:
			# A Hype surge and a special are whole-yard moments; the rest keep the per-bank
			# reaction `react(kind, side)` just cued and let the eruption add the jump on top.
			crowd3d.erupt(_hype_energy(), kind == &"hype" or kind == &"special")
		_light_pump = 1.0


## Highest hype meter in the match as 0–1. Read-only: the eruption scales with the crowd's
## own reading of the fight and can never award, spend or clamp hype.
func _hype_energy() -> float:
	var best := 0.0
	for key in fighters:
		var fighter: BaseFighter = fighters[key]
		if fighter != null:
			best = maxf(best, float(fighter.hype) / float(maxi(BaseFighter.HYPE_MAX, 1)))
	return clampf(best, 0.0, 1.0)


## Current eruption pump applied to the existing spots, 0–1.
func light_pump() -> float:
	return _light_pump


## 132 BPM downbeat: the DJs nod, the mixer keeps moving even in a quiet moment, and the
## night stage beams re-lock their pulse to the real beat clock (Bug 5).
func beat_pulse() -> void:
	_beat_phase = 0.0
	if dj_booth != null:
		dj_booth.nod()


## Scalar beat envelope, 1.0 on the downbeat and decaying across the beat. The night spots'
## energy rides this, so the yard breathes with the music without a single allocation.
func stage_pulse() -> float:
	return exp(-fposmod(_beat_phase, 1.0) * 3.0)


func _update_stage_lights(delta: float) -> void:
	_beat_phase = fposmod(_beat_phase + delta * BPM / 60.0, 1.0)
	_light_pump = maxf(0.0, _light_pump - delta * 1.6)
	_apply_stage_energies()


func _apply_stage_energies() -> void:
	var pulse := (1.0 + _stage_pulse_amount * stage_pulse()) \
		* (1.0 + _light_pump * ERUPT_LIGHT_PUMP * stage_pulse())
	if spot_left != null:
		spot_left.light_energy = _stage_energy_base * pulse
	if spot_right != null:
		spot_right.light_energy = _stage_energy_base * 0.92 * pulse
	if stage_spot_a != null:
		stage_spot_a.light_energy = _stage_energy_base * 0.80 * pulse
	if stage_spot_b != null:
		stage_spot_b.light_energy = _stage_energy_base * 0.72 * pulse


## Every light the yard currently draws, for the Web per-object light-limit audit.
func light_count() -> int:
	var n := 0
	for node in find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if light != null and light.visible and light.light_energy > 0.0:
			n += 1
	return n


func directional_light_count() -> int:
	var n := 0
	for node in find_children("*", "DirectionalLight3D", true, false):
		var light := node as DirectionalLight3D
		if light != null and light.visible and light.light_energy > 0.0:
			n += 1
	return n


## Compatibility's ceiling for lights affecting one object (`rendering/limits/opengl/
## max_lights_per_object`, 8 by default). The Web preset runs this renderer.
static func max_lights_per_object() -> int:
	return int(ProjectSettings.get_setting("rendering/limits/opengl/max_lights_per_object", 8))


func stage_spot_count() -> int:
	var n := 0
	for light in [spot_left, spot_right, stage_spot_a, stage_spot_b]:
		if light != null:
			n += 1
	return n


func stage_spot_colour(index: int) -> Color:
	var lights := [spot_left, spot_right, stage_spot_a, stage_spot_b]
	if index < 0 or index >= lights.size() or lights[index] == null:
		return Color.BLACK
	return (lights[index] as SpotLight3D).light_color


func crowd_count() -> int:
	return crowd3d.count() if crowd3d != null else 0


func dj_count() -> int:
	return dj_booth.dj_count() if dj_booth != null else 0


## Real triangle cost of everything this pass added to the yard, measured from the meshes
## that were actually built. The headless check keeps it under 15 000.
func atmosphere_triangles() -> int:
	var total := 0
	if crowd3d != null:
		total += crowd3d.triangle_count()
	if dj_booth != null:
		total += dj_booth.triangle_count()
	return total


func model_for(fighter: BaseFighter) -> Node3D:
	for key in models:
		if fighters.get(key) == fighter:
			var model: Node3D = models[key]
			return model
	return null


## Height of the fighter on screen as a fraction of the 720 px frame, measured by projecting
## the feet and head through the live Camera3D (headless-safe).
func screen_fraction() -> float:
	var probe: Node3D = null
	for key in models:
		probe = models[key]
		break
	if probe == null or camera == null:
		return 0.0
	var height := 1.55
	if probe.get("model_height") != null:
		height = float(probe.get("model_height"))
	var at := Vector3(_camera_x, 0.0, 0.0)
	var feet := camera.unproject_position(at)
	var head := camera.unproject_position(at + Vector3(0.0, height, 0.0))
	var frame := float(get_viewport().get_visible_rect().size.y)
	return absf(feet.y - head.y) / maxf(frame, 1.0)


func camera_distance() -> float:
	return _camera_distance if camera != null else 0.0


## Presentation bridge: a 2D arena point (the space `BaseFighter` uses — 1280×720 with the
## floor line at y 600) as a point on the 3D fighting plane. Read-only; no camera state is
## touched, so the framing and yard-clearance audits are unaffected.
func world_point_of(p: Vector2) -> Vector3:
	return Vector3(px_to_world_x(p.x), maxf(0.0, (FLOOR_PX - p.y) / PX_PER_M), 0.0)


## Frames the exchange lean for the framing audit: hold `deg` for `frames` presented frames.
func hold_exchange_yaw(deg: float, frames: int = 2) -> void:
	_camera_yaw = deg_to_rad(deg)
	_camera_yaw_velocity = 0.0
	_yaw_hold = maxi(1, frames)


## The exchange lean currently written to the lens, degrees.
func exchange_yaw_deg() -> float:
	return rad_to_deg(_camera_yaw)


## Framing audit: hold every pressure the lens can carry AT ONCE at its ceiling — the exchange
## lean, the cinematic accent (dolly + its own yaw, with the side it leans toward) and the
## hit-stop punch — so the yard clearance test can measure the true stacked worst case instead
## of three springs already decaying at different rates. Presentational test hook only, same
## contract as `hold_exchange_yaw`; nothing in the game calls it.
func hold_camera_pressure(yaw_deg: float, accent: float = 1.0, side: int = 0,
		punch: float = 1.0, frames: int = 2) -> void:
	hold_exchange_yaw(yaw_deg, frames)
	_accent = clampf(accent, 0.0, 1.0) * AnimationFeel.CAMERA_ACCENT_MAX
	_accent_velocity = 0.0
	_accent_side = clampi(side, -1, 1)
	_accent_hold = maxi(1, frames)
	_kick = clampf(punch, 0.0, AnimationFeel.CAMERA_PUNCH_MAX)
	_kick_velocity = 0.0
	_kick_hold = maxi(1, frames)


## World-space AABBs of everything the lens must never enter, for the yard clearance audit:
## every crowd rig, the barrier's rail, lower rail and posts, the horizon band, the DJ booth and
## both filled prop slots. The crowd's depth "tiers" are a per-row Y offset, not riser geometry,
## so the rigs themselves are the only volume there is to hit. Allocated on call — audit only,
## never per frame.
func camera_obstacles() -> Array[AABB]:
	var out: Array[AABB] = []
	if crowd3d != null:
		for model in crowd3d.model_slots():
			_append_bounds(out, model)
	# Every box the yard was built from: barrier rail, lower rail, all nine posts, the horizon
	# band, the truss and the fixtures. Kept by reference in `_yard_solids`, since eight of the
	# posts end up with anonymous node names.
	for solid in _yard_solids:
		_append_bounds(out, solid)
	_append_bounds(out, dj_booth)
	for slot in _sound_stacks:
		if slot != null:
			_append_bounds(out, slot.model)
	return out


## The sky backdrop's world centre — its quad faces +Z, unrotated, so its plane is `z`.
func backdrop_centre() -> Vector3:
	var sky := get_node_or_null("SkyBackdrop") as MeshInstance3D
	return sky.global_position if sky != null else Vector3.ZERO


## Half the sky backdrop's width and height, so a ray can be tested against the visible rect.
func backdrop_half_extent() -> Vector2:
	var sky := get_node_or_null("SkyBackdrop") as MeshInstance3D
	if sky == null or not (sky.mesh is QuadMesh):
		return Vector2.ZERO
	return (sky.mesh as QuadMesh).size * 0.5


func _append_bounds(out: Array[AABB], root_node: Node) -> void:
	var box := _meshes_world_aabb(root_node)
	if box.size != Vector3.ZERO:
		out.append(box)


## Union of `root_node`'s own mesh box (when it is one) and every mesh box beneath it, in world
## space. Rest-pose AABBs for skinned rigs: the crowd's animation never leaves its own body
## volume by more than a hand, and the audit only needs the volume the lens must stay out of.
func _meshes_world_aabb(root_node: Node) -> AABB:
	var out := AABB()
	var first := true
	if root_node == null:
		return out
	var meshes: Array[Node] = []
	if root_node is MeshInstance3D:
		meshes.append(root_node)
	meshes.append_array(root_node.find_children("*", "MeshInstance3D", true, false))
	for child in meshes:
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box: AABB = mi.global_transform * mi.mesh.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out


## True while this fighter is in any attack phase: that is the side the lens leans toward.
func _is_exchanging(fighter: BaseFighter) -> bool:
	if fighter == null:
		return false
	return fighter.state == BaseFighter.State.ATTACK_STARTUP \
		or fighter.state == BaseFighter.State.ATTACK_ACTIVE \
		or fighter.state == BaseFighter.State.ATTACK_RECOVERY


# =========================================================================
# Per-frame mirror of the 2D simulation
# =========================================================================
func _process(delta: float) -> void:
	_pulse = move_toward(_pulse, 0.0, delta * 4.2)
	# Scalar spring decay for the hit-stop punch (never a stepped or linear falloff).
	if _kick_hold > 0:
		_kick_hold -= 1
		_kick_velocity = 0.0
	else:
		var kick_step: Array = AnimationFeel.spring_scalar_step(_kick, _kick_velocity, 0.0,
			clampf(delta, 0.0001, 1.0 / 30.0), AnimationFeel.CAMERA_PUNCH_STIFFNESS,
			AnimationFeel.CAMERA_PUNCH_DAMPING)
		_kick = kick_step[0]
		_kick_velocity = kick_step[1]
		if absf(_kick) < 0.0002:
			_kick = 0.0
			_kick_velocity = 0.0
	# Cinematic accent spring (K.O. / special). Same impulse-then-spring contract as the
	# punch: integrated every presented frame, clamped to CAMERA_ACCENT_MAX, never stepped by
	# the combat tick.
	if _accent_hold > 0:
		_accent_hold -= 1
	else:
		var accent_step: Array = AnimationFeel.spring_scalar_step(_accent, _accent_velocity,
			0.0, clampf(delta, 0.0001, 1.0 / 30.0), AnimationFeel.CAMERA_ACCENT_STIFFNESS,
			AnimationFeel.CAMERA_ACCENT_DAMPING)
		_accent = clampf(float(accent_step[0]), 0.0, AnimationFeel.CAMERA_ACCENT_MAX)
		_accent_velocity = float(accent_step[1])
		if absf(_accent) < 0.0002:
			_accent = 0.0
			_accent_velocity = 0.0
	_shake = move_toward(_shake, 0.0, delta * 3.0)
	_update_phase(delta)
	_update_camera(delta)
	_update_fighters()
	_update_speakers(delta)
	_update_crowd(delta)
	_update_stage_lights(delta)
	if pool_material != null:
		var base := float(_phase_now.get("pool_alpha", 0.15))
		pool_material.set_shader_parameter("intensity", base + _pulse * 0.10)


func _update_camera(delta: float) -> void:
	var p1: BaseFighter = fighters.get("p1")
	var p2: BaseFighter = fighters.get("p2")
	if p1 != null and p2 != null:
		var mid := (p1.global_position.x + p2.global_position.x) * 0.5
		var target := clampf(px_to_world_x(mid), CAMERA_MIN_X, CAMERA_MAX_X)
		_camera_x = lerpf(_camera_x, target, 1.0 - exp(-CAMERA_FOLLOW * delta))
	# Framing dolly: keep both bodies inside the horizontal half-angle at their spread, with
	# a margin for fists and hats. At neutral spacing this resolves to the tighter default.
	var view := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1280, 720)
	var aspect := maxf(view.x / maxf(view.y, 1.0), 1.0)
	# Cinematic accent (commit 3), clamped. Its yaw and dolly are added to the required
	# framing distance, so the accent can never crop a fighter: `needed` is the floor the
	# final camera distance may never go below.
	var accent := clampf(_accent, 0.0, AnimationFeel.CAMERA_ACCENT_MAX)
	var accent_yaw := deg_to_rad(AnimationFeel.CAMERA_ACCENT_YAW_DEG) * accent \
		* float(_accent_side)
	var half_span := 0.0
	half_span = maxf(half_span, absf(px_to_world_x(p1.global_position.x) - _camera_x))
	half_span = maxf(half_span, absf(px_to_world_x(p2.global_position.x) - _camera_x))
	var needed := (half_span + 0.55 + absf(sin(_camera_yaw + accent_yaw)) * 2.0
		+ accent * AnimationFeel.CAMERA_ACCENT_DOLLY) / (tan(deg_to_rad(CAMERA_FOV * 0.5)) * aspect)
	var dist_target := clampf(maxf(CAMERA_DISTANCE, needed), CAMERA_DISTANCE, CAMERA_MAX_DISTANCE)
	_camera_distance = lerpf(_camera_distance, dist_target,
		1.0 - exp(-CAMERA_FOLLOW * delta))
	var distance := maxf(_camera_distance - accent * AnimationFeel.CAMERA_ACCENT_DOLLY, needed)
	# Lean a few degrees toward whoever is driving the exchange. The spring is critically
	# damped, so the lens drifts in and out without overshoot or a snap on state changes.
	var yaw_target := 0.0
	var p1_driving := _is_exchanging(p1)
	var p2_driving := _is_exchanging(p2)
	if p1_driving and not p2_driving:
		yaw_target = deg_to_rad(AnimationFeel.CAMERA_YAW_MAX_DEG)
	elif p2_driving and not p1_driving:
		yaw_target = -deg_to_rad(AnimationFeel.CAMERA_YAW_MAX_DEG)
	if _yaw_hold > 0:
		_yaw_hold -= 1
	else:
		# Critically damped scalar, integrated in place: no array, no allocation, and the
		# angle can never leave its 4° clamp.
		var yaw_dt := clampf(delta, 0.0001, 1.0 / 30.0)
		var yaw_accel := (yaw_target - _camera_yaw) * AnimationFeel.CAMERA_YAW_STIFFNESS \
			- _camera_yaw_velocity * AnimationFeel.CAMERA_YAW_DAMPING
		_camera_yaw_velocity += yaw_accel * yaw_dt
		_camera_yaw += _camera_yaw_velocity * yaw_dt
		var yaw_limit := deg_to_rad(AnimationFeel.CAMERA_YAW_MAX_DEG)
		_camera_yaw = clampf(_camera_yaw, -yaw_limit, yaw_limit)
	var jitter := Vector3(
		_rng.randf_range(-1.0, 1.0) * _shake,
		_rng.randf_range(-1.0, 1.0) * _shake * 0.7,
		0.0)
	# ONE clamped total for the lens angle: the exchange lean plus the accent's own bias.
	var yaw_limit := deg_to_rad(AnimationFeel.CAMERA_YAW_MAX_DEG + AnimationFeel.CAMERA_ACCENT_YAW_DEG)
	var yaw_total := clampf(_camera_yaw + accent_yaw, -yaw_limit, yaw_limit)
	# Orbit the focus point by the yaw instead of rotating in place: both fighters stay on
	# the same side of the lens and the framing distance is unchanged.
	camera.position = Vector3(
		_camera_x + sin(yaw_total) * distance + jitter.x,
		CAMERA_HEIGHT + jitter.y,
		cos(yaw_total) * distance)
	camera.rotation = Vector3(0.0, yaw_total, 0.0)
	# The punch is a widening FOV kick plus a hair of vertical offset, both riding the same
	# spring value, so the impulse and its recovery are one smooth arc. The accent adds its
	# own clamped share to the same total, so the two can never stack past the punch ceiling.
	var total_kick_deg := clampf(_kick * AnimationFeel.CAMERA_PUNCH_FOV_DEG
		+ accent * AnimationFeel.CAMERA_ACCENT_FOV_DEG, 0.0,
		AnimationFeel.CAMERA_PUNCH_MAX * AnimationFeel.CAMERA_PUNCH_FOV_DEG)
	camera.fov = CAMERA_FOV - total_kick_deg
	camera.h_offset = 0.0
	camera.v_offset = -_kick * AnimationFeel.CAMERA_PUNCH_OFFSET_M
	camera_punch = _kick
	cinematic_accent = accent


func _update_fighters() -> void:
	for key in fighters:
		var fighter: BaseFighter = fighters[key]
		var model: Node3D = models.get(key)
		if fighter == null or model == null:
			continue
		var lift := maxf(0.0, (FLOOR_PX - fighter.global_position.y) / PX_PER_M)
		model.position = Vector3(px_to_world_x(fighter.global_position.x), lift, 0.0)
		var shadow: MeshInstance3D = shadows.get(key)
		if shadow != null:
			var shrink := clampf(1.0 - lift * 0.28, 0.55, 1.0)
			shadow.position = Vector3(model.position.x + lift * 0.18, 0.018, 0.02)
			shadow.scale = Vector3(shrink, 1.0, shrink)
			var mat := shadow.material_override as ShaderMaterial
			if mat != null:
				mat.set_shader_parameter("opacity", 0.58 * clampf(1.0 - lift * 0.22, 0.25, 1.0))


func _update_speakers(_delta: float = 0.0) -> void:
	# A delivered tower pops a couple of centimetres on the same beat the 2D speaker rings
	# run. Nothing is animated inside the model: the tower is one imported object now.
	var punch := _pulse * _pulse
	for slot in _sound_stacks:
		if slot == null or slot.model == null:
			continue
		var pop := 1.0 + punch * 0.012
		slot.model.scale = Vector3(pop, 1.0 + punch * 0.02, pop)


func _update_crowd(delta: float) -> void:
	# Each spectator and DJ runs its own clock and its own staggered reaction timer; the
	# arena only advances them, so nothing here can ever touch the simulation.
	if crowd3d != null:
		crowd3d.tick(delta)
	if dj_booth != null:
		dj_booth.tick(delta)


func _update_phase(delta: float) -> void:
	if _phase_duration <= 0.0:
		return
	_phase_age += delta
	var t := clampf(_phase_age / _phase_duration, 0.0, 1.0)
	_phase_now = _blend_palette(_phase_from, _phase_to, t)
	_push_palette(_phase_now)
	if t >= 1.0:
		_phase_duration = 0.0


func _blend_palette(from: Dictionary, to: Dictionary, t: float) -> Dictionary:
	var out: Dictionary = {}
	for key in to:
		var a = from.get(key, to[key])
		var b = to[key]
		match typeof(b):
			TYPE_COLOR:
				var ac: Color = a
				var bc: Color = b
				out[key] = ac.lerp(bc, t)
			TYPE_VECTOR3:
				var av: Vector3 = a
				var bv: Vector3 = b
				out[key] = av.lerp(bv, t)
			TYPE_FLOAT:
				out[key] = lerpf(float(a), float(b), t)
			_:
				out[key] = b
	return out


func _apply_phase(phase: Dictionary) -> void:
	_phase_now = phase.duplicate()
	_push_palette(_phase_now)


func _push_palette(p: Dictionary) -> void:
	if world_env == null or world_env.environment == null:
		return
	var env := world_env.environment
	env.background_color = p["sky_bottom"]
	env.ambient_light_color = p["ambient"]
	env.ambient_light_energy = float(p["ambient_energy"])
	env.fog_light_color = p["fog"]
	env.fog_density = float(p["fog_density"])
	if sun != null:
		sun.light_color = p["sun_colour"]
		sun.light_energy = float(p["sun_energy"])
		sun.rotation_degrees = p["sun_rotation"]
	if rim != null:
		rim.light_color = p["rim"]
		rim.light_energy = float(p["rim_energy"])
	# The cool camera fill is part of the phase, not a fixed value: a violet fill at dusk and a
	# deep blue fill at night are what stop the yard reading as one flat amber card.
	if fill != null:
		fill.light_color = p.get("fill_colour", fill.light_color)
		fill.light_energy = float(p.get("fill_energy", fill.light_energy))
	# The crowd and the DJ booth share one silhouette-rim material each, so the phase palette
	# repaints every silhouette in the yard with a single shader parameter write.
	if crowd3d != null:
		crowd3d.set_palette(p["rim"], p["spot_colour"], float(p["rim_energy"]))
	if dj_booth != null:
		dj_booth.set_palette(p["rim"], p["spot_colour"], float(p["rim_energy"]))
	# Bug 5: the four stage beams each own a colour, and their energy rides the 132 BPM pulse.
	if spot_left != null:
		spot_left.light_color = p["stage_a"]
	if spot_right != null:
		spot_right.light_color = p["stage_b"]
	if stage_spot_a != null:
		stage_spot_a.light_color = p["stage_c"]
	if stage_spot_b != null:
		stage_spot_b.light_color = p["stage_d"]
	_stage_energy_base = float(p["stage_energy"])
	_stage_pulse_amount = float(p.get("stage_pulse", 0.0))
	_apply_stage_energies()
	# Sand, mounds and the horizon band are re-graded with the phase, so the floor answers the
	# sky instead of staying one fixed brown card under three different skies.
	if sand_material != null:
		sand_material.albedo_color = p["sand"]
	if mound_material != null:
		mound_material.albedo_color = p["mound"]
	if horizon_material != null:
		horizon_material.albedo_color = p["horizon"]
	if sky_material != null:
		sky_material.set_shader_parameter("top_colour", p["sky_top"])
		sky_material.set_shader_parameter("mid_colour", p["sky_mid"])
		sky_material.set_shader_parameter("bottom_colour", p["sky_bottom"])
		sky_material.set_shader_parameter("haze_colour", p["sky_haze"])
		sky_material.set_shader_parameter("mid_point", float(p["sky_mid_point"]))
		sky_material.set_shader_parameter("haze_height", float(p["haze_height"]))
		sky_material.set_shader_parameter("haze_strength", float(p["haze_strength"]))
	if pool_material != null:
		pool_material.set_shader_parameter("pool_colour", p["pool"])
		pool_material.set_shader_parameter("intensity", float(p["pool_alpha"]))
	if sun_material != null:
		sun_material.set_shader_parameter("disc_colour", p["disc_colour"])
		sun_material.set_shader_parameter("intensity", float(p["disc"]))
		if _sun_disc != null:
			_sun_disc.position = p["disc_pos"]
			var s := float(p["disc_size"])
			_sun_disc.scale = Vector3(s, s, 1.0)
	# Commit 3: every fighter's cel material takes this preset's rim colour and strength, so a
	# body separates cleanly from the sky it is standing against. One parameter write per
	# body — the material itself is never rebuilt, and the albedo is never touched.
	_cel_rim = p.get("cel_rim", _cel_rim)
	_cel_rim_strength = float(p.get("cel_rim_strength", _cel_rim_strength))
	_push_cel_rim()


## Push the preset rim onto both fighter models. Presentation only; a null model (the
## billboard fallback) is simply skipped.
func _push_cel_rim() -> void:
	for key in models:
		var model := models[key] as FighterModel3D
		if model != null and is_instance_valid(model):
			model.set_cel_rim(_cel_rim, _cel_rim_strength)


## The cel rim the current preset owns, for the per-preset audit.
func cel_rim_colour() -> Color:
	return _cel_rim


func cel_rim_strength() -> float:
	return _cel_rim_strength


# =========================================================================
# World construction
# =========================================================================
## Bug 5: the environment is a graded, tone-mapped scene rather than a linear flat wash.
##
## ACES keeps the afternoon highlights from clipping while leaving the sunset's crimson and
## the night's cyan saturated. Glow is enabled at a low, additive setting for the sun disc,
## the neon rim and the stage beams — Godot 4.3+ supports glow in the Compatibility renderer,
## which is the renderer the Web export uses. Nothing here needs SSAO, SDFGI or volumetric
## fog: all three stay off, so the WebGL2 path renders exactly this.
func _build_environment() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.72, 0.90)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.78)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.08
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.fog_enabled = true
	env.fog_light_color = Color(0.80, 0.86, 0.94)
	env.fog_density = 0.004
	env.fog_sky_affect = 0.0
	env.fog_aerial_perspective = 0.0
	# Compatibility-safe: none of the screen-space effects the Web renderer cannot do.
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	world_env.environment = env
	add_child(world_env)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "StageCamera"
	camera.fov = CAMERA_FOV
	camera.near = 0.05
	camera.far = 90.0
	camera.current = true
	camera.position = Vector3(0.0, CAMERA_HEIGHT, CAMERA_DISTANCE)
	add_child(camera)


var _sun_disc: MeshInstance3D = null


func _build_yard() -> void:
	# Sand floor with real perspective depth. The material is kept so the phase palette can
	# re-grade the yard's own albedo, not just the light falling on it (Bug 5).
	sand_material = _mat(Color(0.88, 0.72, 0.46), 1.0)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(24.0, 18.0)
	floor_mesh.subdivide_width = 1
	floor_mesh.subdivide_depth = 1
	var floor_node := MeshInstance3D.new()
	floor_node.name = "SandFloor"
	floor_node.mesh = floor_mesh
	floor_node.material_override = sand_material
	floor_node.position = Vector3(0.0, 0.0, -3.5)
	add_child(floor_node)

	# Damp sand mounds, so the floor is not a flat colour card.
	mound_material = _mat(Color(0.80, 0.62, 0.38), 1.0)
	for i in 14:
		var mound := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = _rng.randf_range(0.16, 0.44)
		disc.bottom_radius = disc.top_radius * 1.6
		disc.height = 0.035
		disc.radial_segments = 12
		disc.rings = 1
		mound.mesh = disc
		mound.material_override = mound_material
		mound.position = Vector3(_rng.randf_range(-5.5, 5.5), 0.018, _rng.randf_range(-2.5, 1.4))
		mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mound)

	# Sky gradient and the afternoon/sunset disc.
	var sky_quad := QuadMesh.new()
	sky_quad.size = Vector2(44.0, 22.0)
	sky_material = ShaderMaterial.new()
	sky_material.shader = SKY_SHADER
	var sky := MeshInstance3D.new()
	sky.name = "SkyBackdrop"
	sky.mesh = sky_quad
	sky.material_override = sky_material
	sky.position = Vector3(0.0, 5.6, -15.0)
	sky.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sky)

	var sun_quad := QuadMesh.new()
	sun_quad.size = Vector2(1.0, 1.0)
	sun_material = ShaderMaterial.new()
	sun_material.shader = SUN_SHADER
	_sun_disc = MeshInstance3D.new()
	_sun_disc.name = "SunDisc"
	_sun_disc.mesh = sun_quad
	_sun_disc.material_override = sun_material
	_sun_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sun_disc.position = Vector3(-3.2, 2.9, -13.6)
	add_child(_sun_disc)

	# Horizon band and a crowd barrier: depth markers, not props stacked on the fighting lane.
	# The band takes the phase's haze colour, so the horizon glows gold at noon, burns orange
	# at dusk and sinks to indigo at night instead of reading as a grey wall.
	horizon_material = _mat(Color(0.86, 0.86, 0.80), 1.0)
	_add_box(self, "HorizonBand", Vector3(34.0, 0.55, 0.4), Vector3(0.0, 0.30, -12.4),
		horizon_material)
	_add_box(self, "BarrierRail", Vector3(13.0, 0.09, 0.09), Vector3(0.0, 0.95, -2.55),
		_mat(Color(0.66, 0.68, 0.72), 0.45, 0.7))
	_add_box(self, "BarrierLower", Vector3(13.0, 0.07, 0.07), Vector3(0.0, 0.50, -2.55),
		_mat(Color(0.58, 0.60, 0.64), 0.5, 0.6))
	for i in 9:
		_add_box(self, "BarrierPost", Vector3(0.06, 1.02, 0.06),
			Vector3(-6.0 + i * 1.5, 0.51, -2.55), _mat(Color(0.52, 0.54, 0.58), 0.5, 0.6))

	# Additive pool of stage light on the sand (the SpotLights are the real illumination).
	var pool_quad := QuadMesh.new()
	pool_quad.size = Vector2(5.6, 2.9)
	pool_material = ShaderMaterial.new()
	pool_material.shader = LIGHT_POOL
	var pool := MeshInstance3D.new()
	pool.name = "StageLightPool"
	pool.mesh = pool_quad
	pool.material_override = pool_material
	pool.rotation.x = -PI * 0.5
	pool.position = Vector3(0.0, 0.012, -0.3)
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pool)


## The two towers the yard expects. Drop these files into `assets/models/props/` and they
## appear; until then the slots stay empty and each logs `PropLoader: missing …`.
const SPEAKER_MODELS := [
	"res://assets/models/props/jamaican_speaker.glb",
	"res://assets/models/props/rasta_speaker.glb",
]


## Two empty speaker slots, one per side of the fighting lane.
func _build_speakers() -> void:
	for i in SPEAKER_MODELS.size():
		var side := -1.0 if i == 0 else 1.0
		var slot := PropLoader.new()
		slot.name = "SpeakerStackLeft" if i == 0 else "SpeakerStackRight"
		slot.model_path = SPEAKER_MODELS[i]
		slot.required = true
		slot.position = Vector3(side * 2.55, 0.0, -1.45)
		add_child(slot)
		_sound_stacks.append(slot)


# =========================================================================
# Sound-system reporting (headless checks)
# =========================================================================
func speaker_stack_count() -> int:
	return _sound_stacks.size()


## Towers actually loaded. Zero while the `.glb` files are missing — that is the expected
## state of the repo, not a failure.
func speaker_model_count() -> int:
	var n := 0
	for slot in _sound_stacks:
		if slot != null and not slot.is_empty():
			n += 1
	return n


## The model paths the two slots ask for, in left/right order.
func speaker_slot_paths() -> Array[String]:
	var paths: Array[String] = []
	for path in SPEAKER_MODELS:
		paths.append(path)
	return paths


func _build_truss_and_lights() -> void:
	var metal := _mat(Color(0.34, 0.36, 0.40), 0.45, 0.8)
	for side in [-1.0, 1.0]:
		_add_box(self, "TrussTower", Vector3(0.16, 4.4, 0.16),
			Vector3(side * 3.55, 2.2, -0.35), metal)
	_add_box(self, "TrussBeam", Vector3(7.4, 0.16, 0.16), Vector3(0.0, 4.35, -0.35), metal)
	for i in 4:
		_add_box(self, "Fixture", Vector3(0.22, 0.30, 0.22),
			Vector3(-2.4 + i * 1.6, 4.05, -0.35), _mat(Color(0.08, 0.08, 0.09), 0.7))

	spot_left = SpotLight3D.new()
	spot_left.name = "SpotLeft"
	spot_left.position = Vector3(-1.25, 3.95, 0.55)
	spot_left.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	spot_left.spot_range = 8.0
	spot_left.spot_angle = 34.0
	spot_left.spot_angle_attenuation = 0.7
	spot_left.light_energy = 1.0
	spot_left.shadow_enabled = false
	add_child(spot_left)
	spot_right = SpotLight3D.new()
	spot_right.name = "SpotRight"
	spot_right.position = Vector3(1.25, 3.95, 0.55)
	spot_right.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	spot_right.spot_range = 8.0
	spot_right.spot_angle = 34.0
	spot_right.spot_angle_attenuation = 0.7
	spot_right.light_energy = 1.0
	spot_right.shadow_enabled = false
	add_child(spot_right)

	# Bug 5: two more stage beams, angled across the fighting lane, so the night rig can light
	# the yard in cyan / magenta / amber / gold instead of one flat white overhead wash.
	stage_spot_a = SpotLight3D.new()
	stage_spot_a.name = "StageSpotMagenta"
	stage_spot_a.position = Vector3(-2.7, 3.9, 0.9)
	stage_spot_a.rotation_degrees = Vector3(-76.0, 22.0, 0.0)
	stage_spot_a.spot_range = 9.5
	stage_spot_a.spot_angle = 40.0
	stage_spot_a.spot_angle_attenuation = 0.9
	stage_spot_a.light_energy = 0.0
	stage_spot_a.shadow_enabled = false
	add_child(stage_spot_a)
	stage_spot_b = SpotLight3D.new()
	stage_spot_b.name = "StageSpotAmber"
	stage_spot_b.position = Vector3(2.7, 3.9, 0.9)
	stage_spot_b.rotation_degrees = Vector3(-76.0, -22.0, 0.0)
	stage_spot_b.spot_range = 9.5
	stage_spot_b.spot_angle = 40.0
	stage_spot_b.spot_angle_attenuation = 0.9
	stage_spot_b.light_energy = 0.0
	stage_spot_b.shadow_enabled = false
	add_child(stage_spot_b)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-56.0, -30.0, 0.0)
	sun.light_energy = 1.2
	# The fighters' crisp directional shadow is a hard requirement of the three phases, so the
	# key light always casts, with a sharp angular size and a tight bias/blur for clean edges.
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 26.0
	sun.directional_shadow_split_1 = 0.28
	sun.light_angular_distance = 0.0
	sun.shadow_blur = 0.7
	sun.shadow_bias = 0.03
	add_child(sun)

	fill = DirectionalLight3D.new()
	fill.name = "CameraFill"
	fill.rotation_degrees = Vector3(-38.0, 172.0, 0.0)
	fill.light_color = Color(0.72, 0.80, 1.0)
	fill.light_energy = 0.28
	fill.shadow_enabled = false
	add_child(fill)

	rim = OmniLight3D.new()
	rim.name = "WarmRim"
	rim.position = Vector3(0.0, 1.9, -1.6)
	rim.omni_range = 6.0
	rim.light_energy = 0.6
	rim.shadow_enabled = false
	add_child(rim)


## 3D DJ booth between the mid-ground stacks (owner request, 2026-11-22). It stands behind
## the barrier and behind the fighting lane, in the centre bay both crowd banks leave open,
## so the decks sit between the speaker stacks exactly as a real sound system is set up.
func _build_dj_booth() -> void:
	dj_booth = BOOTH_SCRIPT.new()
	dj_booth.name = "DJBooth3D"
	dj_booth.position = Vector3(0.0, 0.0, -3.20)
	add_child(dj_booth)
	dj_booth.build()


## 20 staggered, zone-loyal 3D silhouettes replace the old 26-capsule placeholder bank,
## which read as bowling pins. `CrowdController3D` owns their rigs, props and acting; this
## method only builds and places it.
func _build_crowd() -> void:
	crowd3d = CROWD_SCRIPT.new()
	crowd3d.name = "CrowdController3D"
	add_child(crowd3d)
	crowd3d.build()


## A fresh round must never open on last round's celebration: the crowd drops back to its
## neutral skank and the DJs return to the mix (owner playtest, 2026-11-23).
func reset_atmosphere() -> void:
	if crowd3d != null:
		crowd3d.settle()
	if dj_booth != null:
		dj_booth.settle()


func _make_fighter(fighter: BaseFighter) -> Node3D:
	var key := fighter.fighter_key
	if MODEL_SCRIPT.MODEL_SOURCES.has(key):
		var model = MODEL_SCRIPT.new()
		add_child(model)
		if model.bind(fighter, key):
			return model
		model.queue_free()
	var billboard = BILLBOARD_SCRIPT.new()
	add_child(billboard)
	billboard.bind(fighter, key)
	return billboard


func _make_contact_shadow() -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 0.52)
	var mat := ShaderMaterial.new()
	mat.shader = CONTACT_SHADOW
	mat.set_shader_parameter("opacity", 0.58)
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	shadow.mesh = quad
	shadow.material_override = mat
	shadow.rotation.x = -PI * 0.5
	shadow.position = Vector3(0.0, 0.018, 0.02)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	return shadow


# =========================================================================
# Signature-move props (2026-11-22)
# =========================================================================
## 3D proxy for a travelling special. L!ckshot throws a spinning dubplate with a gold rim;
## L!kkle Moore throws his school dictionary. The real hit test lives in `ProjectileWave`;
## this mesh follows the same distance and lifetime so the visual and the hitbox agree.
func spawn_projectile(kind: StringName, at_px: float, dir: int, seconds: float,
		distance_px: float) -> void:
	var node := Node3D.new()
	node.name = "MoveProjectile_%s" % kind
	add_child(node)
	node.add_to_group("arena_projectiles")
	var from := px_to_world(Vector2(at_px, FLOOR_PX - 108.0))
	node.position = from
	var spinner := Node3D.new()
	spinner.name = "Spin"
	node.add_child(spinner)

	var fade_mats: Array[StandardMaterial3D] = []
	if kind == &"dictionary":
		var cover := _mat(Color(0.10, 0.20, 0.42), 0.85)
		cover.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var pages := _mat(Color(0.94, 0.89, 0.72), 1.0)
		pages.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_add_box(spinner, "DictionaryCover", Vector3(0.36, 0.27, 0.10),
			Vector3.ZERO, cover)
		_add_box(spinner, "DictionaryPages", Vector3(0.33, 0.24, 0.085),
			Vector3(0.0, 0.0, 0.035), pages)
		fade_mats = [cover, pages]
		spinner.rotation.z = 0.25
	else:
		var disc := CylinderMesh.new()
		disc.top_radius = 0.34
		disc.bottom_radius = 0.34
		disc.height = 0.045
		disc.radial_segments = 24
		disc.rings = 1
		var vinyl := _mat(Color(0.035, 0.035, 0.045), 0.32, 0.45)
		vinyl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var disc_node := MeshInstance3D.new()
		disc_node.name = "Dubplate"
		disc_node.mesh = disc
		disc_node.material_override = vinyl
		disc_node.rotation.x = PI * 0.5
		disc_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spinner.add_child(disc_node)
		var rim := TorusMesh.new()
		rim.inner_radius = 0.30
		rim.outer_radius = 0.355
		rim.rings = 24
		rim.ring_segments = 6
		var gold := _mat(Color(1.0, 0.80, 0.24), 0.45, 0.35)
		gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var rim_node := MeshInstance3D.new()
		rim_node.name = "GoldRim"
		rim_node.mesh = rim
		rim_node.material_override = gold
		rim_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spinner.add_child(rim_node)
		var label := CylinderMesh.new()
		label.top_radius = 0.115
		label.bottom_radius = 0.115
		label.height = 0.05
		label.radial_segments = 16
		var rasta := _mat(Color(0.95, 0.82, 0.20), 0.7)
		rasta.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var label_node := MeshInstance3D.new()
		label_node.name = "Label"
		label_node.mesh = label
		label_node.material_override = rasta
		label_node.rotation.x = PI * 0.5
		label_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spinner.add_child(label_node)
		fade_mats = [vinyl, gold, rasta]

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position:x", from.x + float(dir) * distance_px / PX_PER_M,
		seconds).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(spinner, "rotation:y" if kind != &"dictionary" else "rotation:z",
		TAU * (3.0 if kind != &"dictionary" else 2.0), seconds).set_trans(Tween.TRANS_LINEAR)
	for mat in fade_mats:
		tween.tween_property(mat, "albedo_color:a", 0.0, seconds * 0.22).set_delay(seconds * 0.78)
	tween.chain().tween_callback(node.queue_free)


func active_projectiles() -> int:
	return get_tree().get_nodes_in_group("arena_projectiles").size()


## Sand kicked up by a grab slam, a throw landing or a low sweep. CPUParticles3D only:
## the WebGL2 path never uses GPU particles.
func spawn_sand_burst(at: Vector2, strength: float = 1.0) -> void:
	var puff := CPUParticles3D.new()
	puff.name = "SandBurst"
	puff.amount = clampi(int(8.0 + 16.0 * strength), 8, 24)
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.lifetime = 0.65
	puff.direction = Vector3(0.0, 1.0, 0.0)
	puff.spread = 55.0
	puff.initial_velocity_min = 0.5 + strength * 0.8
	puff.initial_velocity_max = 1.2 + strength * 1.6
	puff.gravity = Vector3(0.0, -4.6, 0.0)
	puff.scale_amount_min = 0.7
	puff.scale_amount_max = 1.8
	var quad := QuadMesh.new()
	quad.size = Vector2(0.055, 0.055)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.72, 0.48, 1.0)
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	puff.mesh = quad
	puff.material_override = mat
	puff.position = px_to_world(Vector2(at.x, FLOOR_PX - 6.0))
	add_child(puff)
	puff.emitting = true
	puff.finished.connect(puff.queue_free)


## Record Static Parry: a black vinyl disc with a gold rim snaps open and fades over the
## contact point. Presentation only — the parry itself resolved in `BaseFighter`.
func spawn_vinyl_parry(at: Vector2) -> void:
	var node := Node3D.new()
	node.name = "VinylParry"
	add_child(node)
	node.position = px_to_world(Vector2(at.x, FLOOR_PX - 110.0))
	var disc := CylinderMesh.new()
	disc.top_radius = 0.34
	disc.bottom_radius = 0.34
	disc.height = 0.035
	disc.radial_segments = 24
	var vinyl := _mat(Color(0.04, 0.04, 0.05), 0.25, 0.5)
	vinyl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var disc_node := MeshInstance3D.new()
	disc_node.mesh = disc
	disc_node.material_override = vinyl
	disc_node.rotation.x = PI * 0.5
	disc_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(disc_node)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.34
	rim.outer_radius = 0.40
	rim.rings = 24
	rim.ring_segments = 6
	var gold := _mat(Color(1.0, 0.84, 0.26), 0.4, 0.4)
	gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var rim_node := MeshInstance3D.new()
	rim_node.mesh = rim
	rim_node.material_override = gold
	rim_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(rim_node)
	node.scale = Vector3.ONE * 0.45
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector3.ONE * 2.1, 0.45)
	tween.tween_property(vinyl, "albedo_color:a", 0.0, 0.45)
	tween.tween_property(gold, "albedo_color:a", 0.0, 0.45)
	tween.chain().tween_callback(node.queue_free)


func _spawn_burst(at: Vector3, power: float, angle: float) -> void:
	# Prune freed bursts first, then recycle the oldest if the cap is reached, so a long
	# brawl can never stack note geometry.
	_live_bursts = _live_bursts.filter(func(node): return is_instance_valid(node) and not node.is_queued_for_deletion())
	if _live_bursts.size() >= MAX_BURSTS:
		var oldest = _live_bursts.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var burst = BURST_SCRIPT.new()
	add_child(burst)
	burst.burst(at, power, angle)
	_live_bursts.append(burst)


# =========================================================================
# Small geometry helpers
# =========================================================================
func _mat(colour: Color, roughness: float = 1.0, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


func _add_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		material: Material) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = box
	mi.position = at
	mi.material_override = material
	parent.add_child(mi)
	_yard_solids.append(mi)
	return mi


static func px_to_world_x(px: float) -> float:
	return (px - CENTER_PX) / PX_PER_M


static func px_to_world(at: Vector2) -> Vector3:
	return Vector3(px_to_world_x(at.x), maxf(0.0, (FLOOR_PX - at.y) / PX_PER_M), 0.0)

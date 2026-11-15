extends Node2D
## Workshop arena for Fighter #1 (UNAPPROVED — no Godot checks have been run).
##
## Wires the two fighters to one BeatService, drives the dummy, follows the action
## with the camera, shakes it on impact, and repeats the dev click loop.
##
## Stage: `Sound Clash Sand Stage` (1280x720 art, z_index -10) with the fighting floor
## at y = 600 — the sand yard starts at y ≈ 505 in that art, so both fighters stand
## inside the sand lane. The camera never zooms out past 1.0 or leaves the stage
## rectangle, so the single-layer art always covers the view.
##
## Round lighting: `set_time_of_day(phase)` runs the afternoon → golden hour →
## late-night progression (AGENTS.md §9). Round 1 defaults to phase 0; **N** cycles it
## by hand until the round controller drives it.
##
## Match flow: a best-of-3 Sound Clash runs by default (RoundController) — announce, fight,
## K.O., next round with the day → sunset → night lighting, then a rematch banner and restart.
## R reloads the scene and starts a fresh match; N still overrides the lighting by hand.
##
## Workshop keys: R reset · G dummy guard (manual guard override in every AI mode) ·
## Y cycle P2's sparring AI mode · M mute · B bird hazard · N time of day
## · J/K/L/I attacks · T taunt · C crouch · WASD/arrows move.

const CLICK_LOOP_SECONDS := 10.0      # 22 beats at 132 BPM
const CAMERA_MIN_DISTANCE := 420.0
const CAMERA_MAX_DISTANCE := 1100.0
const STAGE_SIZE := Vector2(1280, 720)
const CAMERA_MIN_ZOOM := 1.0          # keep the 1280x720 stage art covering the view
const CAMERA_MAX_ZOOM := 1.6
const CAMERA_FOCUS_LIFT := 140.0
const THUMP_ZOOM := 0.008             # 132 BPM speaker thump: 0.8% micro-pulse
const THUMP_DECAY := 7.0

## Round-based time of day (AGENTS.md §9 owner decision). `tint` is a CanvasModulate
## over the whole world canvas — the HUD lives in a CanvasLayer, so it stays readable —
## and `flood` is the aim of the warm additive floodlight over the centre lane, which
## only rises at night so both fighters stay crisp against the dark sky.
## [TODO] Phase-to-round mapping is exposed as an API, not driven: this workshop arena
## has no round lifecycle yet. The match controller calls set_time_of_day(round - 1).
const TIME_PHASES := [
	{
		"name": "Afternoon Sun",
		"tint": Color(1.0, 0.98, 0.94),
		"flood": 0.0,
		"sun": 1.0,
	},
	{
		"name": "Golden Hour / Sunset Clash",
		"tint": Color(1.0, 0.78, 0.58),
		"flood": 0.1,
		"sun": 0.6,
	},
	{
		"name": "Late-Night Sound Clash",
		"tint": Color(0.48, 0.55, 0.80),
		"flood": 0.34,
		"sun": 0.22,
	},
]
const TIME_TRANSITION_SEC := 3.0

## Long-demo safeguards for low-RAM Chromebooks (AGENTS.md §9). Rapid inputs and long
## sessions must never pile up effects, so every transient spawn goes through a cap.
const MAX_ACTIVE_BIRDS := 1           # one bird in the air at a time, however fast B is pressed
const MAX_PARRY_SPARKS := 4           # oldest spark is recycled once four are alive
const MAX_PARTICLE_AMOUNT := 16       # hard ceiling applied to every CPUParticles2D
## Where the pre-warm instances live: far outside the camera's clamped stage rectangle,
## so they are never on screen even for one frame.
const PREWARM_OFFSCREEN := Vector2(-4000.0, -4000.0)

@onready var p1: BaseFighter = $P1
@onready var p2: BaseFighter = $P2
@onready var beat: BeatService = $BeatService
@onready var music: AudioStreamPlayer = $Music
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/Ui/Hud
@onready var sparring: SparringController = $SparringAI
@onready var crowd: CrowdLine = $CrowdLine
@onready var rounds: RoundController = $RoundController
@onready var bird: BirdHazard = $BirdHazard
@onready var speaker_rings: SpeakerPulse = $SpeakerRings
@onready var time_modulate: CanvasModulate = $TimeOfDay
@onready var floodlight: Sprite2D = $Floodlight
@onready var sun_glow: Sprite2D = $SunGlow

var _dummy_guard: bool = false
var _shake_time: float = 0.0
var _shake_intensity: float = 0.0
var _thump: float = 0.0
var _time_phase: int = 0
var _time_tween: Tween = null


func _ready() -> void:
	p1.beat_service = beat
	p2.beat_service = beat
	beat.audio_player = music

	p2.use_local_input = false          # P2 is driven by the sparring controller only
	p2.input_prefix = "p2_"
	sparring.setup(p1, p2, beat)
	sparring.manual_guard = _dummy_guard

	p1.camera_shake_requested.connect(_on_shake)
	p2.camera_shake_requested.connect(_on_shake)

	hud.set("p1", p1)
	hud.set("p2", p2)
	hud.set("beat", beat)
	hud.set("sparring", sparring)
	hud.set("rounds", rounds)

	beat.beat.connect(_on_beat)
	crowd.setup(beat)
	p1.hype_surge_started.connect(_on_hype_surge)
	p2.hype_surge_started.connect(_on_hype_surge)
	p1.hype_milestone_reached.connect(_on_hype_milestone)
	p2.hype_milestone_reached.connect(_on_hype_milestone)
	p1.static_parry_triggered.connect(_on_static_parry)
	p2.static_parry_triggered.connect(_on_static_parry)
	p1.throw_broken.connect(_on_throw_broken)
	p2.throw_broken.connect(_on_throw_broken)
	p1.throw_connected.connect(_on_throw_connected)
	p2.throw_connected.connect(_on_throw_connected)
	p1.speaker_slam_triggered.connect(_on_speaker_slam)
	p2.speaker_slam_triggered.connect(_on_speaker_slam)

	rounds.setup(p1, p2, self)
	if rounds.enabled:
		rounds.start_match()          # Round 1 lighting is applied by the round controller
	else:
		set_time_of_day(_time_phase, 0.0)

	music.finished.connect(_restart_click_loop)
	if not music.playing:
		music.play()

	_cap_particles()
	_prewarm_effects()


func _process(delta: float) -> void:
	_thump = maxf(0.0, _thump - delta * THUMP_DECAY)
	_follow_action()
	_update_shake(delta)
	hud.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_R:
			get_tree().reload_current_scene()
		KEY_G:
			_dummy_guard = not _dummy_guard
			if sparring != null:
				sparring.manual_guard = _dummy_guard
		KEY_Y:
			if sparring != null:
				sparring.cycle_mode()
		KEY_M:
			music.stream_paused = not music.stream_paused
		KEY_B:
			_spawn_bird()
		KEY_N:
			cycle_time_of_day()


## 100% Crowd Hype Surge: the crowd jumps and the HUD banner flashes for the same
## window the fighter's momentum boost lasts.
func _on_hype_surge(seconds: float) -> void:
	crowd.surge(seconds)


## 50 % Crowd Hype: the line reshuffles itself even before the surge lands.
func _on_hype_milestone(_percent: int) -> void:
	crowd.celebrate()


## Record Static Parry: an electric vinyl-static spark between the two fighters.
func _on_static_parry(defender: BaseFighter, attacker: BaseFighter) -> void:
	if defender == null or attacker == null:
		return
	_add_spark((defender.global_position + attacker.global_position) * 0.5 + Vector2(0.0, -110.0))
	_on_shake(0.5, 0.12)


## Throw break: the mutual shove-apart gets the same spark flash, with no damage.
func _on_throw_broken(attacker: BaseFighter, defender: BaseFighter) -> void:
	if attacker == null or defender == null:
		return
	_add_spark((attacker.global_position + defender.global_position) * 0.5 + Vector2(0.0, -110.0))
	_on_shake(0.55, 0.14)


## A landed throw: the spinback pops the crowd (the slam's shake comes from the fighter).
func _on_throw_connected(_attacker: BaseFighter, _defender: BaseFighter, kind: StringName) -> void:
	if kind == &"back":
		crowd.celebrate()


## Speaker-Stack Bounce: electric impact right where the thrown fighter hit the stack.
func _on_speaker_slam(victim: BaseFighter, _side: int) -> void:
	if victim == null:
		return
	_add_spark(victim.global_position + Vector2(0.0, -110.0))


## Transient sparks all share the ParrySpark cap, so a long demo can never pile up nodes.
func _add_spark(at: Vector2) -> void:
	var live := _live_parry_sparks()
	if live.size() >= MAX_PARRY_SPARKS:
		# Recycle the oldest spark so the newest effect still reads.
		live[0].queue_free()
	var spark := ParrySpark.new()
	spark.global_position = at
	add_child(spark)


# =========================================================================
# Chromebook safeguards (AGENTS.md §9)
# =========================================================================
## Hard particle ceiling: applied once at start-up to every emitter in the arena, so
## adding nodes later cannot raise it by accident.
func _cap_particles() -> void:
	for node in find_children("*", "CPUParticles2D", true, false):
		var particles := node as CPUParticles2D
		particles.amount = mini(particles.amount, MAX_PARTICLE_AMOUNT)


## Spawn a bird only when none is already in the air (the hazard guards itself too;
## this is the arena-level cap so rapid B presses cannot queue work).
func _spawn_bird() -> void:
	if bird == null:
		return
	var active := 0
	for child in get_children():
		var hazard := child as BirdHazard
		if hazard != null and hazard.is_flying():
			active += 1
	if active >= MAX_ACTIVE_BIRDS:
		return
	bird.spawn_now()


func _live_parry_sparks() -> Array[ParrySpark]:
	var found: Array[ParrySpark] = []
	for child in get_children():
		var spark := child as ParrySpark
		if spark != null and not spark.is_queued_for_deletion():
			found.append(spark)
	return found


## Compile the primitive shaders and allocate the particle buffers now, off-screen and
## invisible, behind the round announce banner. Without this the first footstep, hit or
## parry pays the driver cost mid-fight, which is exactly where an Intel Chromebook's
## shared-memory GPU stutters or freezes.
func _prewarm_effects() -> void:
	var spark := ParrySpark.new()
	spark.global_position = PREWARM_OFFSCREEN
	spark.modulate.a = 0.0            # silent even if it were inside the frame
	add_child(spark)

	var puff := CPUParticles2D.new()
	puff.position = PREWARM_OFFSCREEN
	puff.amount = 4
	puff.lifetime = 0.1
	puff.one_shot = true
	puff.emitting = true
	puff.finished.connect(puff.queue_free)   # self-cleaning, no timer to leak
	add_child(puff)
	# The spark frees itself after ParrySpark.DURATION; both are invisible here.


## Stage thump: one micro-pulse per 132 BPM downbeat (BeatService.beat).
func _on_beat(_beat_index: int) -> void:
	_thump = 1.0
	if speaker_rings != null:
		speaker_rings.pulse()


# =========================================================================
# Round-based time of day (AGENTS.md §9)
# =========================================================================
## phase 0 = Afternoon Sun (Round 1), 1 = Golden Hour (Round 2), 2 = Late Night
## (Round 3 / final). `duration` 0 applies instantly; otherwise the tint, floodlight
## and sun glow cross-fade together.
func set_time_of_day(phase: int, duration: float = TIME_TRANSITION_SEC) -> void:
	_time_phase = clampi(phase, 0, TIME_PHASES.size() - 1)
	var target: Dictionary = TIME_PHASES[_time_phase]
	var tint: Color = target["tint"]
	var flood: float = target["flood"]
	var sun: float = target["sun"]

	if _time_tween != null and _time_tween.is_valid():
		_time_tween.kill()
	if duration <= 0.0:
		time_modulate.color = tint
		floodlight.modulate.a = flood
		sun_glow.modulate.a = sun
		return

	_time_tween = create_tween()
	_time_tween.set_parallel(true)
	_time_tween.set_trans(Tween.TRANS_SINE)
	_time_tween.set_ease(Tween.EASE_IN_OUT)
	_time_tween.tween_property(time_modulate, "color", tint, duration)
	_time_tween.tween_property(floodlight, "modulate:a", flood, duration)
	_time_tween.tween_property(sun_glow, "modulate:a", sun, duration)


func cycle_time_of_day(duration: float = TIME_TRANSITION_SEC) -> void:
	set_time_of_day((_time_phase + 1) % TIME_PHASES.size(), duration)


func time_of_day_phase() -> int:
	return _time_phase


func time_of_day_name() -> String:
	return String(TIME_PHASES[_time_phase]["name"])


func _restart_click_loop() -> void:
	if is_instance_valid(music) and music.stream_paused == false:
		music.play()


func _follow_action() -> void:
	var mid := (p1.global_position + p2.global_position) * 0.5
	var span := clampf(absf(p1.global_position.x - p2.global_position.x) * 1.8,
		CAMERA_MIN_DISTANCE, CAMERA_MAX_DISTANCE)
	var z := clampf(1100.0 / span, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM)
	var half := STAGE_SIZE * 0.5 / z
	var target := mid + Vector2(0.0, -CAMERA_FOCUS_LIFT)
	target.x = clampf(target.x, half.x, STAGE_SIZE.x - half.x)
	target.y = clampf(target.y, half.y, STAGE_SIZE.y - half.y)
	camera.global_position = target
	# Zooming in only ever shrinks the visible area, so the thump never exposes an edge.
	camera.zoom = Vector2(z, z) * (1.0 + THUMP_ZOOM * _thump)


func _on_shake(intensity: float, duration: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_time = maxf(_shake_time, duration)


func _update_shake(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) \
			* _shake_intensity * 14.0
		if _shake_time <= 0.0:
			_shake_time = 0.0
			_shake_intensity = 0.0
			camera.offset = Vector2.ZERO

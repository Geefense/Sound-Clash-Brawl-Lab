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
## Y cycle P2's sparring AI mode · M mute (click track + procedural SFX) · B bird hazard ·
## N time of day · V subtitles · J/K/L/I attacks · T taunt · C crouch · WASD/arrows move.
##
## Push separation (AGENTS.md §9 backlog item B7): bodies keep a shared minimum gap so the
## fighters cannot occupy the same pixel, which also keeps the 96 px grab range meaningful.
## It is skipped while a body is held, airborne, thrown or knocked down, so jumps over an
## opponent, throws, spinbacks and knockdowns pass through cleanly instead of snagging.
##
## Sound (backlog item B8): every impact cue comes from `Sfx`, which synthesises its
## samples at run time — the build ships no audio files.
##
## Crowd staging (AGENTS.md §9 item 21): `YardBarrier` closes the base of the crowd line so
## the 15 sprites stand behind something instead of being pinned onto the sand, the
## `Foreground` CanvasLayer carries one cropped near-camera silhouette for the fifth depth
## plane, and `CrowdLine` runs an unsynchronised per-person sway plus the proximity ebb.
## All three are presentation only.

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

## Crowd proximity ebb (AGENTS.md §9 item 21). A body crossing the line at this speed, or
## any thrown / landing body, pulls the nearest spectators back for a beat. Walking is 220,
## so this only fires on a dash, a jump-in, a throw or a knockdown.
const CROWD_FLINCH_SPEED := 320.0
const CROWD_FLINCH_COOLDOWN := 0.85
## Where the pre-warm instances live: far outside the camera's clamped stage rectangle,
## so they are never on screen even for one frame.
const PREWARM_OFFSCREEN := Vector2(-4000.0, -4000.0)

## Push separation (AGENTS.md §9 backlog item B7). 64 px is wider than the 60 px body, so
## the fighters never visually overlap; grabs (96 px) still reach comfortably.
const BODY_GAP := 64.0
## These states must be able to pass through the other body: a held or thrown fighter is
## positioned by the throw, and a knockdown/KO body must be allowed to land where it lands.
const NO_SEPARATION_STATES := [
	BaseFighter.State.GRABBED, BaseFighter.State.THROWN,
	BaseFighter.State.KNOCKDOWN, BaseFighter.State.KO,
]

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
var _muted: bool = false
var _separation_queued: bool = false
var _flinch_cd := [0.0, 0.0]          # per-fighter rate limit for the crowd flinch


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
	p1.taunt_finished.connect(_on_taunt_finished)
	p2.taunt_finished.connect(_on_taunt_finished)
	p1.throw_broken.connect(_on_throw_broken)
	p2.throw_broken.connect(_on_throw_broken)
	p1.throw_connected.connect(_on_throw_connected)
	p2.throw_connected.connect(_on_throw_connected)
	p1.speaker_slam_triggered.connect(_on_speaker_slam)
	p2.speaker_slam_triggered.connect(_on_speaker_slam)
	p1.strike_resolved.connect(_on_strike_resolved)
	p2.strike_resolved.connect(_on_strike_resolved)
	p1.died.connect(_on_fighter_died)
	p2.died.connect(_on_fighter_died)

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
	_update_crowd_flinch(delta)
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
			_set_muted(not _muted)
		KEY_B:
			_spawn_bird()
		KEY_N:
			cycle_time_of_day()
		KEY_V:
			hud.toggle_subtitles()


# =========================================================================
# Push separation (AGENTS.md §9 backlog item B7)
# =========================================================================
## Deferred so it runs after both fighters have finished their own `move_and_slide()`
## this physics tick — the arena is the parent node, so its `_physics_process` runs first.
func _physics_process(_delta: float) -> void:
	if _separation_queued:
		return
	_separation_queued = true
	call_deferred("_separate_fighters")


func _separate_fighters() -> void:
	_separation_queued = false
	if not _separation_allowed():
		return
	var pos1 := p1.global_position
	var pos2 := p2.global_position
	var distance := pos2.x - pos1.x
	if absf(distance) >= BODY_GAP:
		return
	var dir := 1.0 if distance >= 0.0 else -1.0
	# Split the correction evenly, then let the speaker-stack walls absorb what they can.
	var half := (BODY_GAP - absf(distance)) * 0.5
	var x1 := pos1.x - dir * half
	var x2 := pos2.x + dir * half
	x1 = clampf(x1, BaseFighter.STAGE_LEFT, BaseFighter.STAGE_RIGHT)
	x2 = clampf(x2, BaseFighter.STAGE_LEFT, BaseFighter.STAGE_RIGHT)
	if absf(x2 - x1) < BODY_GAP:
		# One body is pinned against a stack: the free one takes the whole remainder.
		if x1 <= BaseFighter.STAGE_LEFT + 0.5:
			x2 = minf(x1 + BODY_GAP, BaseFighter.STAGE_RIGHT)
		elif x2 >= BaseFighter.STAGE_RIGHT - 0.5:
			x1 = maxf(x2 - BODY_GAP, BaseFighter.STAGE_LEFT)
	if is_equal_approx(x1, pos1.x) and is_equal_approx(x2, pos2.x):
		return
	pos1.x = x1
	pos2.x = x2
	p1.global_position = pos1
	p2.global_position = pos2


## Separation only exists for two grounded bodies that are in control of their position.
func _separation_allowed() -> bool:
	if p1 == null or p2 == null:
		return false
	if p1.state in NO_SEPARATION_STATES or p2.state in NO_SEPARATION_STATES:
		return false
	# Airborne bodies pass over each other: jumping across is part of the movement feel.
	if not p1.is_on_floor() or not p2.is_on_floor():
		return false
	return true


# =========================================================================
# Sound (AGENTS.md §9 backlog item B8)
# =========================================================================
## Mute toggle for everything: the dev click loop and the procedural SFX together, so one
## key never leaves half the game talking. The Master bus carries both, and muting the bus
## (rather than pausing the stream) keeps the 132 BPM clock running, so unmuting never
## desyncs the beat judgement from the music.
func _set_muted(value: bool) -> void:
	_muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), value)
	Sfx.set_muted(value)


func is_muted() -> bool:
	return _muted


## Impact cue. Blocked contacts knock, plain contacts thud, and a strike judged on the beat
## gets the sub-bass punch so timing reads with the music muted.
func _on_strike_resolved(_attacker: BaseFighter, target: BaseFighter, result: Dictionary) -> void:
	if bool(result.get("ignored", false)) or bool(result.get("parried", false)):
		return                    # a parry has its own cue, fired from the fighter signal
	var on_beat := bool(result.get("on_beat", false))
	if on_beat:
		Sfx.play(&"hit_onbeat")
	elif bool(result.get("blocked", false)):
		Sfx.play(&"block")
	else:
		Sfx.play(&"hit")

	# B4 / §9 item 21: the struck body flashes for two ticks and throws a contact burst —
	# white/gold when the input was off the beat, green/gold when it was on it.
	if target != null and not bool(result.get("blocked", false)):
		target.flash_impact(on_beat)
	if target != null:
		_add_spark(target.global_position + Vector2(0.0, -110.0),
			&"hit_onbeat" if on_beat else &"hit")


## A fighter entering KO: the dramatic arcade drop (fired once per K.O.).
func _on_fighter_died() -> void:
	Sfx.play(&"ko")


## 100% Crowd Hype Surge: the crowd jumps and the HUD banner flashes for the same
## window the fighter's momentum boost lasts.
func _on_hype_surge(seconds: float) -> void:
	crowd.surge(seconds)
	Sfx.play(&"airhorn")
	hud.announce_subtitle("WHEEL AND COME AGAIN!", "(Translation: Rewind the track — rematch!)")


## 50 % Crowd Hype: the line reshuffles itself even before the surge lands.
func _on_hype_milestone(_percent: int) -> void:
	crowd.celebrate()


## Record Static Parry: an electric vinyl-static spark between the two fighters.
func _on_static_parry(defender: BaseFighter, attacker: BaseFighter) -> void:
	if defender == null or attacker == null:
		return
	_add_spark((defender.global_position + attacker.global_position) * 0.5 + Vector2(0.0, -110.0))
	_on_shake(0.5, 0.12)
	Sfx.play(&"parry")
	hud.announce_subtitle("BIG TUNE!", "(Translation: Cleanest block in the dance!)")


## On-beat skank taunt: the one taunt line that gets a callout (off-beat stays quiet).
func _on_taunt_finished(on_beat: bool) -> void:
	if not on_beat:
		return
	hud.announce_subtitle("YUH TOO BOD MINE!!", "(Translation: You're way too jealous!)")


## Throw break: the mutual shove-apart gets the same spark flash, with no damage.
func _on_throw_broken(attacker: BaseFighter, defender: BaseFighter) -> void:
	if attacker == null or defender == null:
		return
	_add_spark((attacker.global_position + defender.global_position) * 0.5 + Vector2(0.0, -110.0))
	_on_shake(0.55, 0.14)
	Sfx.play(&"clank")


## A landed throw: the spinback pops the crowd (the slam's shake comes from the fighter).
func _on_throw_connected(_attacker: BaseFighter, _defender: BaseFighter, kind: StringName) -> void:
	Sfx.play(&"whoosh")
	if kind == &"back":
		crowd.celebrate()


## Speaker-Stack Bounce: electric impact right where the thrown fighter hit the stack.
func _on_speaker_slam(victim: BaseFighter, _side: int) -> void:
	if victim == null:
		return
	_add_spark(victim.global_position + Vector2(0.0, -110.0), &"hit")
	Sfx.play(&"slam")
	hud.announce_subtitle("HOLD DAT!", "(Translation: Take that to the speakers!)")


## Transient sparks all share the ParrySpark cap, so a long demo can never pile up nodes.
func _add_spark(at: Vector2, style: StringName = &"parry") -> void:
	var live := _live_parry_sparks()
	if live.size() >= MAX_PARRY_SPARKS:
		# Recycle the oldest spark so the newest effect still reads.
		live[0].queue_free()
	var spark := ParrySpark.new()
	spark.style = style
	spark.global_position = at
	add_child(spark)


# =========================================================================
# Crowd staging: yard barrier, foreground silhouette and the proximity ebb (§9 item 21)
# =========================================================================
## A body that crosses the crowd line fast, or any thrown / landing body, makes the
## spectators it passes lean away and then close back in — the live-action yard-brawl
## behaviour, not a sync'd animation. Rate-limited per fighter so it never strobes.
func _update_crowd_flinch(delta: float) -> void:
	if crowd == null:
		return
	for i in _flinch_cd.size():
		_flinch_cd[i] = maxf(0.0, _flinch_cd[i] - delta)
	_flinch_for(p1, 0)
	_flinch_for(p2, 1)


func _flinch_for(fighter: BaseFighter, index: int) -> void:
	if fighter == null or _flinch_cd[index] > 0.0:
		return
	var thrown := fighter.state == BaseFighter.State.THROWN \
		or fighter.state == BaseFighter.State.KNOCKDOWN
	var fast := absf(fighter.velocity.x) >= CROWD_FLINCH_SPEED
	if not thrown and not fast:
		return
	var strength := 1.25 if thrown else 0.55
	if crowd.flinch(fighter.global_position.x, strength) > 0:
		_flinch_cd[index] = CROWD_FLINCH_COOLDOWN


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

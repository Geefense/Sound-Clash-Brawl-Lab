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
## Workshop keys: R reset · G dummy guard · M mute · B bird hazard · J/K/L/I attacks
## · T taunt · C crouch · WASD/arrows move.

const CLICK_LOOP_SECONDS := 10.0      # 22 beats at 132 BPM
const CAMERA_MIN_DISTANCE := 420.0
const CAMERA_MAX_DISTANCE := 1100.0
const STAGE_SIZE := Vector2(1280, 720)
const CAMERA_MIN_ZOOM := 1.0          # keep the 1280x720 stage art covering the view
const CAMERA_MAX_ZOOM := 1.6
const CAMERA_FOCUS_LIFT := 140.0
const THUMP_ZOOM := 0.008             # 132 BPM speaker thump: 0.8% micro-pulse
const THUMP_DECAY := 7.0

@onready var p1: BaseFighter = $P1
@onready var p2: BaseFighter = $P2
@onready var beat: BeatService = $BeatService
@onready var music: AudioStreamPlayer = $Music
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/Ui/Hud
@onready var bird: BirdHazard = $BirdHazard
@onready var speaker_rings: SpeakerPulse = $SpeakerRings

var _dummy_guard: bool = false
var _shake_time: float = 0.0
var _shake_intensity: float = 0.0
var _thump: float = 0.0


func _ready() -> void:
	p1.beat_service = beat
	p2.beat_service = beat
	beat.audio_player = music

	p2.use_local_input = false          # the dummy is driven below
	p2.input_prefix = "p2_"

	p1.camera_shake_requested.connect(_on_shake)
	p2.camera_shake_requested.connect(_on_shake)

	hud.set("p1", p1)
	hud.set("p2", p2)
	hud.set("beat", beat)

	beat.beat.connect(_on_beat)

	music.finished.connect(_restart_click_loop)
	if not music.playing:
		music.play()


func _process(delta: float) -> void:
	_thump = maxf(0.0, _thump - delta * THUMP_DECAY)
	_follow_action()
	_update_shake(delta)
	hud.queue_redraw()


func _physics_process(_delta: float) -> void:
	# Dummy: stand, or hold guard when toggled.
	var c := BaseFighter.Command.new()
	c.guard = _dummy_guard
	p2.command = c


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_R:
			get_tree().reload_current_scene()
		KEY_G:
			_dummy_guard = not _dummy_guard
		KEY_M:
			music.stream_paused = not music.stream_paused
		KEY_B:
			if bird != null:
				bird.spawn_now()


## Stage thump: one micro-pulse per 132 BPM downbeat (BeatService.beat).
func _on_beat(_beat_index: int) -> void:
	_thump = 1.0
	if speaker_rings != null:
		speaker_rings.pulse()


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

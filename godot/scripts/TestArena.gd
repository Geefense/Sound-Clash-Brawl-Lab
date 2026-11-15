extends Node2D
## Workshop arena for Fighter #1 (UNAPPROVED — no Godot checks have been run).
##
## Wires the two fighters to one BeatService, drives the dummy, follows the action
## with the camera, shakes it on impact, and repeats the dev click loop.
##
## Workshop keys: R reset · G dummy guard · M mute · J/K/L/I attacks · T taunt ·
## C crouch · WASD/arrows move.

const CLICK_LOOP_SECONDS := 10.0      # 22 beats at 132 BPM
const CAMERA_MIN_DISTANCE := 420.0
const CAMERA_MAX_DISTANCE := 1100.0

@onready var p1: BaseFighter = $P1
@onready var p2: BaseFighter = $P2
@onready var beat: BeatService = $BeatService
@onready var music: AudioStreamPlayer = $Music
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/Ui/Hud

var _dummy_guard: bool = false
var _shake_time: float = 0.0
var _shake_intensity: float = 0.0


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

	music.finished.connect(_restart_click_loop)
	if not music.playing:
		music.play()


func _process(delta: float) -> void:
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


func _restart_click_loop() -> void:
	if is_instance_valid(music) and music.stream_paused == false:
		music.play()


func _follow_action() -> void:
	var mid := (p1.global_position + p2.global_position) * 0.5
	camera.global_position = mid + Vector2(0.0, -140.0)
	var span := clampf(absf(p1.global_position.x - p2.global_position.x) * 1.8,
		CAMERA_MIN_DISTANCE, CAMERA_MAX_DISTANCE)
	var z := clampf(1100.0 / span, 0.85, 1.6)
	camera.zoom = Vector2(z, z)


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

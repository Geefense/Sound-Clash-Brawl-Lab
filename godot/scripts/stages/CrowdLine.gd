class_name CrowdLine
extends Node2D
## Beat-synced Dancehall crowd (AGENTS.md §9). Presentation only: it never touches the
## simulation, the hitboxes or either fighter's FSM.
##
## Every crowd member is a plain Sprite2D child placed in the scene. This node bobs them on
## the 132 BPM BeatService beat, and on a 100% Crowd Hype Surge it drives the rapid
## jump/cheer loop until the boost expires.

@export var bob_pixels: float = 4.0          # subtle off-beat sway during normal play
@export var surge_hop_pixels: float = 22.0   # surge jubilation
@export var surge_hop_interval: float = 0.16 # ~6 hops/s spread across the line

var beat: BeatService

var _sprites: Array[Sprite2D] = []
var _home: Array[Vector2] = []
var _home_rot: Array[float] = []
var _tweens: Array[Tween] = []
var _surge_left: float = 0.0
var _hop_timer: float = 0.0
var _hop_index: int = 0


func _ready() -> void:
	for child in get_children():
		var s := child as Sprite2D
		if s == null:
			continue
		_sprites.append(s)
		_home.append(s.position)
		_home_rot.append(s.rotation)
		_tweens.append(null)


func setup(service: BeatService) -> void:
	beat = service
	if beat != null and not beat.beat.is_connected(on_beat):
		beat.beat.connect(on_beat)


func on_beat(_beat_index: int) -> void:
	var surging := is_surging()
	for i in _sprites.size():
		if surging:
			_bounce(i, surge_hop_pixels, 0.16, float(i) * 0.015)
		else:
			_bounce(i, bob_pixels, 0.24, float(i) * 0.02)


## Called when a fighter's Hype Meter fills. `seconds` is the fighter's boost length, so
## the crowd stays up for exactly as long as the momentum boost lasts.
func surge(seconds: float) -> void:
	_surge_left = maxf(seconds, 0.1)
	_hop_timer = 0.0
	for i in _sprites.size():
		_bounce(i, surge_hop_pixels * 1.3, 0.22, float(i) * 0.03)


func is_surging() -> bool:
	return _surge_left > 0.0


func crowd_size() -> int:
	return _sprites.size()


func _process(delta: float) -> void:
	if _surge_left <= 0.0:
		return
	_surge_left = maxf(0.0, _surge_left - delta)
	_hop_timer -= delta
	if _hop_timer <= 0.0 and not _sprites.is_empty():
		_hop_timer = surge_hop_interval
		_hop_index = (_hop_index + 1) % _sprites.size()
		_bounce(_hop_index, randf_range(surge_hop_pixels * 0.7, surge_hop_pixels * 1.4),
			0.2, 0.0, randf_range(-0.12, 0.12))
	if _surge_left <= 0.0:
		_settle()


func _bounce(i: int, amp: float, duration: float, delay: float, tilt: float = 0.0) -> void:
	var sprite := _sprites[i]
	var home := _home[i]
	var previous := _tweens[i]
	if previous != null and previous.is_valid():
		previous.kill()
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(sprite, "position:y", home.y - amp, duration * 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if tilt != 0.0:
		tw.parallel().tween_property(sprite, "rotation", _home_rot[i] + tilt, duration * 0.45)
	tw.tween_property(sprite, "position:y", home.y, duration * 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if tilt != 0.0:
		tw.parallel().tween_property(sprite, "rotation", _home_rot[i], duration * 0.55)
	_tweens[i] = tw


func _settle() -> void:
	for i in _sprites.size():
		var tw := _tweens[i]
		if tw != null and tw.is_valid():
			tw.kill()
		_sprites[i].position = _home[i]
		_sprites[i].rotation = _home_rot[i]

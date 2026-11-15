class_name BirdHazard
extends Node2D
## Rare bird fly-by hazard (owner decision, AGENTS.md §9).
##
## ~5% chance every 15 s, plus `spawn_now()` on the B workshop key. The bird crosses
## the upper screen relative to the camera's visible area (so it is always on screen
## at any zoom) and drops one comedic splatter on a fighter's lane. A standing
## fighter gets a brief flinch/hitstun from BaseFighter.receive_splatter(); a dodged
## drop lands on the sand as a decal.
##
## Presentation only: no damage, no hit registry, no round state.

const SPLAT_SCRIPT := preload("res://scripts/stages/StageSplat.gd")
const SPEED := 430.0
const DROP_GRAVITY := 1500.0
const DROP_INITIAL := Vector2(40.0, 60.0)
const FLIGHT_MARGIN := 140.0
const BIRD_HEIGHT_MIN := 64.0
const BIRD_HEIGHT_MAX := 132.0

@export var auto_spawn: bool = true
@export var rare_interval_sec: float = 15.0
@export var rare_chance: float = 0.05
@export var ground_y: float = 600.0

var _clock: float = 0.0
var _flying: bool = false
var _elapsed: float = 0.0
var _duration: float = 1.0
var _dir: int = 1
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _phase: float = 0.0
var _drop_x: float = 0.0
var _dropped: bool = false
var _drops: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	_clock += delta
	if auto_spawn and _clock >= rare_interval_sec:
		_clock = 0.0
		if _rng.randf() < rare_chance:
			spawn_now()

	if _flying:
		_elapsed += delta
		_try_drop()
		if _elapsed >= _duration:
			_flying = false
	if not _drops.is_empty():
		_update_drops(delta)

	if _flying or not _drops.is_empty():
		queue_redraw()


## Debug key / scripted trigger. Ignored while a bird is already in the air.
func spawn_now() -> bool:
	if _flying:
		return false
	var camera := get_viewport().get_camera_2d()
	var centre := camera.global_position if camera != null else Vector2(640, 460)
	var zoom := camera.zoom if camera != null else Vector2.ONE
	var half := Vector2(640.0, 360.0) / Vector2(maxf(zoom.x, 0.01), maxf(zoom.y, 0.01))

	_dir = 1 if _rng.randf() < 0.5 else -1
	var start_x := centre.x - float(_dir) * (half.x + FLIGHT_MARGIN)
	var end_x := centre.x + float(_dir) * (half.x + FLIGHT_MARGIN)
	var y := centre.y - half.y + _rng.randf_range(BIRD_HEIGHT_MIN, BIRD_HEIGHT_MAX)
	_from = Vector2(start_x, y)
	_to = Vector2(end_x, y)
	_duration = maxf(absf(_to.x - _from.x) / SPEED, 0.4)
	_elapsed = 0.0
	_phase = _rng.randf() * TAU
	_dropped = false
	_flying = true

	var lane := lerpf(_from.x, _to.x, _rng.randf_range(0.35, 0.65))
	var fighters := get_tree().get_nodes_in_group("fighters")
	if not fighters.is_empty():
		var target := fighters[_rng.randi() % fighters.size()] as Node2D
		if target != null:
			lane = target.global_position.x + _rng.randf_range(-55.0, 55.0)
	_drop_x = clampf(lane, minf(_from.x, _to.x) + 40.0, maxf(_from.x, _to.x) - 40.0)
	queue_redraw()
	return true


func _bird_position() -> Vector2:
	var k := clampf(_elapsed / _duration, 0.0, 1.0)
	var p := _from.lerp(_to, k)
	p.y += sin(_elapsed * 6.0 + _phase) * 10.0
	return p


func _try_drop() -> void:
	if _dropped:
		return
	var bx := _bird_position().x
	var passed := bx >= _drop_x if _dir > 0 else bx <= _drop_x
	if not passed:
		return
	_dropped = true
	var p := _bird_position() + Vector2(-2.0 * float(_dir), 10.0)
	_drops.append({
		"pos": p,
		"vel": Vector2(DROP_INITIAL.x * float(_dir), DROP_INITIAL.y),
	})


func _update_drops(delta: float) -> void:
	for drop in _drops.duplicate():
		var vel: Vector2 = drop["vel"] + Vector2(0.0, DROP_GRAVITY * delta)
		var pos: Vector2 = drop["pos"] + vel * delta
		drop["vel"] = vel
		drop["pos"] = pos
		if _splatter_fighter(pos):
			_drops.erase(drop)
			continue
		if pos.y >= ground_y:
			_drops.erase(drop)
			_splatter_sand(Vector2(pos.x, ground_y))


## Returns true when the drop actually connected with a standing fighter.
func _splatter_fighter(pos: Vector2) -> bool:
	for node in get_tree().get_nodes_in_group("fighters"):
		var fighter := node as BaseFighter
		if fighter == null:
			continue
		if not fighter.hurt_rect().has_point(pos):
			continue
		if not fighter.receive_splatter(pos.x):
			continue
		var splat := SPLAT_SCRIPT.new() as Node2D
		splat.set("radius", 13.0)
		splat.set("life_sec", 3.0)
		splat.z_index = 6
		fighter.add_child(splat)
		splat.position = Vector2(0.0, -112.0)
		return true
	return false


func _splatter_sand(pos: Vector2) -> void:
	var splat := SPLAT_SCRIPT.new() as Node2D
	splat.set("radius", 22.0)
	splat.set("life_sec", 5.0)
	splat.z_index = -6
	add_child(splat)
	splat.position = pos


func _draw() -> void:
	if _flying:
		_draw_bird(_bird_position(), _dir)
	for drop in _drops:
		var p: Vector2 = drop["pos"]
		draw_circle(p, 3.2, Color(0.97, 0.96, 0.90, 0.95))
		draw_circle(p + Vector2(-2.0, -5.0), 1.6, Color(0.95, 0.94, 0.88, 0.7))


func _draw_bird(p: Vector2, dir: int) -> void:
	var flap := sin(_elapsed * 16.0 + _phase)
	var lift := flap * 9.0
	var body := Color(0.20, 0.21, 0.25)
	var wing := Color(0.30, 0.32, 0.38)
	var beak := Color(0.98, 0.75, 0.22)

	# Wings first so the body reads on top.
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-4.0, -1.0),
		p + Vector2(-6.0, -14.0 - lift),
		p + Vector2(-22.0, -6.0 - lift * 0.5),
	]), wing)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(2.0, -1.0),
		p + Vector2(4.0, -13.0 + lift),
		p + Vector2(-12.0, -4.0 + lift * 0.5),
	]), wing)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-9.0, -6.0),
		p + Vector2(-21.0, -11.0),
		p + Vector2(-21.0, -2.0),
	]), wing)

	draw_set_transform(p, 0.0, Vector2(1.0, 0.62))
	draw_circle(Vector2(0.0, -4.0), 11.0, body)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_circle(p + Vector2(8.0 * float(dir), -13.0), 6.5, body)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(13.0 * float(dir), -15.0),
		p + Vector2(23.0 * float(dir), -12.0),
		p + Vector2(13.0 * float(dir), -9.0),
	]), beak)
	draw_circle(p + Vector2(9.0 * float(dir), -15.0), 1.7, Color(1, 1, 1))
	draw_circle(p + Vector2(9.4 * float(dir), -15.0), 0.9, Color(0.05, 0.05, 0.06))

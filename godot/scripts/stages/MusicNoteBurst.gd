class_name MusicNoteBurst
extends Node3D
## 3D musical-note impact burst (AGENTS.md §9 item 44).
##
## Replaces the generic 2D hit spark with real 3D geometry: eighth notes, sixteenth notes and
## a stylised treble clef in Rasta green / yellow / red, plus an expanding bass shockwave ring.
## The glyphs are generated as ArrayMesh triangles in code, so the Web build needs no glyph
## font coverage, no texture atlas and no MSDF — and nothing here touches combat state.
##
## Every burst self-frees, and the arena caps how many can be alive (MAX_BURSTS), so a long
## Chromebook session cannot pile meshes up.

const NOTE_SHADER := preload("res://assets/shaders/music_note.gdshader")

const RASTA := [
	Color(0.30, 0.92, 0.34, 1.0),   # green
	Color(1.0, 0.86, 0.20, 1.0),    # yellow
	Color(1.0, 0.22, 0.18, 1.0),    # red
]
## Tighter than the first pass (owner playtest, 2026-11-24 PART 2): the burst snaps in and is
## gone before the next contact, so two quick hits never smear into one cloud.
const DURATION := 0.62
const FLASH_SECONDS := 0.16

var heavy: bool = false
var notes: Array[MeshInstance3D] = []
var ring: MeshInstance3D = null
## Crisp hard-edged contact ring, separate from the slower bass shockwave torus.
var flash: MeshInstance3D = null
var _velocities: Array[Vector3] = []
var _spins: Array[float] = []
var _sizes: Array[float] = []
var _mats: Array[ShaderMaterial] = []
var _ring_mat: ShaderMaterial = null
var _flash_mat: ShaderMaterial = null
var _age: float = 0.0

static var _meshes: Array = []


## Build a burst at a world-space point. `power` 0.4 = a jab tick, 1.0 = a heavy contact.
func burst(at: Vector3, power: float, base_angle: float = 0.0) -> void:
	position = at
	heavy = power >= 0.75
	_create_flash(power)
	_create_ring(power)
	var count := 6 if heavy else 4
	for i in count:
		_create_note(i, count, power, base_angle)


func _create_note(index: int, count: int, power: float, base_angle: float) -> void:
	var mi := MeshInstance3D.new()
	var kind := index % 3
	mi.mesh = _glyph(kind)
	var mat := ShaderMaterial.new()
	mat.shader = NOTE_SHADER
	mat.set_shader_parameter("glyph_colour", RASTA[index % RASTA.size()])
	mat.set_shader_parameter("opacity", 1.0)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Notes fan out along the strike direction, then float up and fade.
	var spread := (float(index) - float(count - 1) * 0.5) * 0.24
	var dir := Vector3(cos(base_angle + spread), sin(base_angle + spread) * 0.35, 0.0)
	mi.position = Vector3(randf_range(-0.10, 0.10), randf_range(-0.08, 0.10), randf_range(-0.05, 0.05))
	mi.rotation.z = randf_range(-0.45, 0.45)
	var size := randf_range(0.55, 0.95) * (0.85 + power * 0.45)
	_sizes.append(size)
	mi.scale = Vector3.ONE * 0.001
	add_child(mi)
	notes.append(mi)
	_mats.append(mat)
	_velocities.append(dir * randf_range(0.9, 1.7) + Vector3(0.0, 0.7, 0.0))
	_spins.append(randf_range(-4.0, 4.0))


## The bass shockwave: a thin, hard torus that opens fast and dies hard, so it reads as a
## crisp ring rather than a soft glow.
func _create_ring(power: float) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.40
	torus.outer_radius = 0.445
	torus.rings = 40
	torus.ring_segments = 6
	ring = MeshInstance3D.new()
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	_ring_mat = ShaderMaterial.new()
	_ring_mat.shader = NOTE_SHADER
	_ring_mat.set_shader_parameter("glyph_colour", RASTA[1] if not heavy else RASTA[0])
	_ring_mat.set_shader_parameter("opacity", 0.9)
	ring.material_override = _ring_mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.scale = Vector3.ONE * 0.30
	add_child(ring)


## The impact flash: a hot white-gold contact ring that is gone in a sixth of a second. This
## is the readable "hit" frame — the notes are the follow-through.
func _create_flash(power: float) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.26
	torus.outer_radius = 0.30
	torus.rings = 48
	torus.ring_segments = 6
	flash = MeshInstance3D.new()
	flash.mesh = torus
	flash.rotation.x = PI * 0.5
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = NOTE_SHADER
	_flash_mat.set_shader_parameter("glyph_colour",
		Color(1.0, 0.98, 0.86) if heavy else Color(1.0, 0.94, 0.70))
	_flash_mat.set_shader_parameter("opacity", 1.0)
	flash.material_override = _flash_mat
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.scale = Vector3.ONE * (0.55 + power * 0.20)
	add_child(flash)


func _process(delta: float) -> void:
	_age += delta
	var t := clampf(_age / DURATION, 0.0, 1.0)
	# Tighter motion: each glyph snaps to full size in an eighth of the burst, drifts, then
	# shrinks out sharply instead of hanging at full size while it fades.
	var shrink := 1.0 - smoothstep(0.55, 1.0, t) * 0.92
	for i in notes.size():
		var mi := notes[i]
		if mi == null:
			continue
		mi.position += _velocities[i] * delta
		_velocities[i] *= 0.86
		_velocities[i].y += 0.22 * delta
		mi.rotation.z += _spins[i] * delta
		var grow := minf(1.0, t * 8.0)
		mi.scale = Vector3.ONE * _sizes[i] * grow * shrink
		_mats[i].set_shader_parameter("opacity", clampf(1.0 - pow(t, 1.7) * 1.1, 0.0, 1.0))
	if flash != null:
		var ft := clampf(_age / FLASH_SECONDS, 0.0, 1.0)
		flash.scale = Vector3.ONE * (0.55 + ft * 2.4)
		_flash_mat.set_shader_parameter("opacity", clampf(1.0 - ft, 0.0, 1.0))
		if ft >= 1.0:
			flash.queue_free()
			flash = null
	if ring != null:
		ring.scale = Vector3.ONE * (0.45 + t * 3.1)
		_ring_mat.set_shader_parameter("opacity", clampf(pow(1.0 - t, 1.6), 0.0, 1.0))
	if _age >= DURATION:
		queue_free()


# =========================================================================
# Procedural glyph meshes
# =========================================================================
static func _glyph(kind: int) -> ArrayMesh:
	while _meshes.size() < 3:
		_meshes.append(null)
	if _meshes[kind] == null:
		_meshes[kind] = _build_glyph(kind)
	return _meshes[kind]


static func _build_glyph(kind: int) -> ArrayMesh:
	var tris := PackedVector3Array()
	match kind:
		1:
			_note_head(tris)
			_stem(tris, 0.02, 0.42)
			_flag(tris, 0.42, 1)
			_flag(tris, 0.30, 2)
		2:
			_clef(tris)
		_:
			_note_head(tris)
			_stem(tris, 0.02, 0.46)
			_flag(tris, 0.46, 1)
	return _mesh_from(tris)


static func _note_head(tris: PackedVector3Array) -> void:
	var centre := Vector2(-0.075, -0.02)
	var rx := 0.105
	var ry := 0.070
	var segments := 22
	var tilt := -0.35
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var p0 := Vector2(cos(a0) * rx, sin(a0) * ry).rotated(tilt) + centre
		var p1 := Vector2(cos(a1) * rx, sin(a1) * ry).rotated(tilt) + centre
		_tri(tris, Vector3(centre.x, centre.y, 0.0), Vector3(p0.x, p0.y, 0.0), Vector3(p1.x, p1.y, 0.0))


static func _stem(tris: PackedVector3Array, x: float, top: float) -> void:
	var w := 0.022
	var bottom := -0.03
	_quad(tris, Vector2(x, bottom), Vector2(x + w, bottom), Vector2(x + w, top), Vector2(x, top))


## A crisp flag: a straight taper down to a sharp point, with a doubled leading edge so the
## glyph still reads as a note at 60 px on a Chromebook screen.
static func _flag(tris: PackedVector3Array, top: float, which: int) -> void:
	var x := 0.025
	var drop := 0.12 * float(which)
	var tip := Vector2(0.215, top - drop - 0.03)
	_tri(tris, Vector3(x, top + 0.03, 0.0),
		Vector3(tip.x, tip.y, 0.0),
		Vector3(x, top - 0.11, 0.0))
	_tri(tris, Vector3(tip.x, tip.y, 0.0),
		Vector3(x + 0.010, top - 0.11, 0.0),
		Vector3(x, top - 0.11, 0.0))
	# Hard shadow edge under the flag: one darker sliver is enough to read as cel ink.
	_quad(tris, Vector2(x, top - 0.10), Vector2(tip.x * 0.94, tip.y - 0.012),
		Vector2(tip.x, tip.y), Vector2(x + 0.008, top - 0.085))


## A treble-clef silhouette from a tapering ribbon along a spiral centreline.
static func _clef(tris: PackedVector3Array) -> void:
	var steps := 34
	var prev_left := Vector2.ZERO
	var prev_right := Vector2.ZERO
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var c0 := _clef_point(t0)
		var c1 := _clef_point(t1)
		var w0 := 0.020 * (1.0 - t0 * 0.45)
		var w1 := 0.020 * (1.0 - t1 * 0.45)
		var n0 := Vector2(-(c1.y - c0.y), c1.x - c0.x).normalized() * w0
		var n1 := Vector2(-(c1.y - c0.y), c1.x - c0.x).normalized() * w1
		if i > 0:
			_quad(tris, prev_left, prev_right, c1 + n1, c1 - n1)
		prev_left = c0 + n0
		prev_right = c0 - n0


static func _clef_point(t: float) -> Vector2:
	# A loop that wraps back over itself, then drops into the clef's tail.
	var angle := -PI * 0.55 + t * TAU * 1.35
	var radius := 0.085 + 0.055 * sin(t * PI)
	var x := 0.02 + cos(angle) * radius
	var y := 0.44 - t * 0.60 + sin(angle) * radius * 0.55
	return Vector2(x, y)


static func _quad(tris: PackedVector3Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> void:
	_tri(tris, Vector3(a.x, a.y, 0.0), Vector3(b.x, b.y, 0.0), Vector3(c.x, c.y, 0.0))
	_tri(tris, Vector3(a.x, a.y, 0.0), Vector3(c.x, c.y, 0.0), Vector3(d.x, d.y, 0.0))


static func _tri(tris: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	tris.append(a)
	tris.append(b)
	tris.append(c)


static func _mesh_from(tris: PackedVector3Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = tris
	var normals := PackedVector3Array()
	normals.resize(tris.size())
	for i in normals.size():
		normals[i] = Vector3(0.0, 0.0, 1.0)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

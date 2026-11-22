class_name DJBooth3D
extends Node3D
## Active 3D Sound-System DJ booth behind the decks (owner request, 2026-11-22).
##
## Two stylized rim-lit DJs work a turntable-and-mixer rig between the mid-ground speaker
## stacks. Presentation only: this node never touches the combat simulation, hitboxes,
## frame data, the beat clock or the audio engine — it only poses geometry to the cues
## `Arena3D.notify_combat_event()` already receives.
##
## Acting:
##   * neutral  — nod/skank on the beat, hands loose, weight shifting
##   * fader    — right hand rides the channel faders and the crossfader slides
##   * point    — arm out towards the fighters on a heavy hit
##   * airhorn  — horn lifted and blown on a knockdown, K.O. or DJ tag
##   * celebrate— both arms up, head back, records spinning on a K.O. / victory / Hype surge
##
## Everything is low-poly primitives with shared meshes and one shared silhouette material,
## included in `Arena3D.atmosphere_triangles()` under the 15 000-triangle budget.

const SILHOUETTE_SHADER := preload("res://assets/shaders/silhouette_rim.gdshader")

const DJ_COUNT := 2
const STATE_IDLE := &"idle"
const STATE_FADER := &"fader"
const STATE_POINT := &"point"
const STATE_AIRHORN := &"airhorn"
const STATE_CELEBRATE := &"celebrate"

const BOOTH_W := 2.50
const BOOTH_H := 0.94

const RASTA := [
	Color(0.12, 0.42, 0.16, 1.0),
	Color(0.86, 0.68, 0.12, 1.0),
	Color(0.62, 0.10, 0.09, 1.0),
]


class DJ:
	var node: Node3D
	var torso: Node3D
	var head: Node3D
	var arm_l: Node3D
	var arm_r: Node3D
	var fore_l: Node3D
	var fore_r: Node3D
	var horn: Node3D = null
	var phase: float = 0.0
	var rate: float = 1.0
	var state: StringName = STATE_IDLE
	var hold: float = 0.0
	var point_dir: float = 1.0
	var nod: float = 0.0


var _djs: Array[DJ] = []
var _mesh_cache: Dictionary = {}
var _body_material: ShaderMaterial
var _deck_material: StandardMaterial3D
var _metal_material: StandardMaterial3D
var _vinyl_material: StandardMaterial3D
var _label_material: StandardMaterial3D
var _records: Array[Node3D] = []
var _faders: Array[MeshInstance3D] = []
var _crossfader: MeshInstance3D
var _fader_value: float = 0.5
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if _djs.is_empty():
		build()


func build() -> void:
	if not _djs.is_empty():
		return
	_rng.seed = 20261122
	_build_materials()
	_build_deck()
	_make_dj(0, -0.62, true)
	_make_dj(1, 0.62, false)


# =========================================================================
# Public API
# =========================================================================
func react(kind: StringName, side: int = -1) -> void:
	match kind:
		&"hit":
			for dj in _djs:
				dj.nod = 1.0
		&"heavy_hit":
			# Point at whoever just landed it: left corner is screen-left, right is screen-right.
			var dir := -1.0 if side == 0 else 1.0
			for i in _djs.size():
				var dj := _djs[i]
				dj.state = STATE_POINT if i == 0 else STATE_FADER
				dj.point_dir = dir if i == 0 else 1.0
				dj.hold = 1.3
		&"knockdown":
			_raise_horn(1.8)
		&"ko":
			_celebrate(3.0)
		&"victory":
			_celebrate(4.0)
		&"tag":
			# A DJ tag is the booth's own moment: horn up, the other DJ keeps the mix running.
			_raise_horn(1.6)
		&"hype":
			_celebrate(2.6)
		_:
			_celebrate(1.4)


## Beat accent from `Arena3D.beat_pulse()`: the booth nods on the 132 BPM click.
func nod() -> void:
	for dj in _djs:
		dj.nod = 1.0


func tick(delta: float) -> void:
	_time += delta
	_fader_value = 0.5 + sin(_time * 0.85) * 0.34
	for i in _faders.size():
		var fader := _faders[i]
		if fader != null:
			# 0 → 1 rides the slot; each channel moves on its own slow clock.
			var offset := 0.5 + sin(_time * (0.7 + float(i) * 0.23) + float(i)) * 0.32
			fader.position.z = lerpf(0.16, -0.16, offset)
	if _crossfader != null:
		_crossfader.position.x = lerpf(-0.12, 0.12, _fader_value)
	for record in _records:
		if record != null:
			record.rotation.y += delta * (1.8 + _energy() * 3.2)
	for dj in _djs:
		if dj.hold > 0.0:
			dj.hold -= delta
			if dj.hold <= 0.0:
				dj.state = STATE_IDLE
		dj.nod = maxf(0.0, dj.nod - delta * 3.2)
		dj.phase = fposmod(dj.phase + dj.rate * delta, TAU)
		_pose_dj(dj, delta)


## Back to a neutral mix, e.g. when a round is reset.
func settle() -> void:
	for dj in _djs:
		dj.state = STATE_IDLE
		dj.hold = 0.0
		dj.nod = 0.0


func dj_count() -> int:
	return _djs.size()


func state_of(index: int) -> StringName:
	if index < 0 or index >= _djs.size():
		return &""
	return _djs[index].state


func airhorn_up() -> bool:
	for dj in _djs:
		if dj.state == STATE_AIRHORN:
			return true
	return false


func celebrating() -> bool:
	for dj in _djs:
		if dj.state == STATE_CELEBRATE:
			return true
	return false


func pointing() -> bool:
	for dj in _djs:
		if dj.state == STATE_POINT:
			return true
	return false


func fader_position() -> float:
	return _fader_value


func record_spin() -> float:
	return _records[0].rotation.y if not _records.is_empty() and _records[0] != null else 0.0


func triangle_count() -> int:
	var total := 0
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			total += int(mi.mesh.get_faces().size() / 3)
	return total


func set_palette(rim_a: Color, rim_b: Color, strength: float) -> void:
	if _body_material == null:
		return
	_body_material.set_shader_parameter("rim_colour", rim_a.lerp(rim_b, 0.45))
	_body_material.set_shader_parameter("rim_strength", clampf(strength * 0.95, 0.2, 2.6))


# =========================================================================
# Acting
# =========================================================================
func _raise_horn(hold: float) -> void:
	for i in _djs.size():
		var dj := _djs[i]
		if dj.horn != null:
			dj.state = STATE_AIRHORN
			dj.hold = hold
		else:
			dj.state = STATE_POINT
			dj.point_dir = 1.0 if i == 0 else -1.0
			dj.hold = hold * 0.8


func _celebrate(hold: float) -> void:
	for dj in _djs:
		dj.state = STATE_CELEBRATE
		dj.hold = hold


## A quiet mix keeps the records moving; celebration spins them visibly faster.
func _energy() -> float:
	for dj in _djs:
		if dj.state == STATE_CELEBRATE or dj.state == STATE_AIRHORN:
			return 1.0
	return 0.0


func _pose_dj(dj: DJ, _delta: float) -> void:
	if dj.node == null:
		return
	var t := dj.phase
	var nod := dj.nod * 0.14
	var bob := absf(sin(t * 1.6)) * 0.025
	var torso_x := 0.04 + sin(t * 1.1) * 0.02
	var torso_z := sin(t * 0.8) * 0.06
	var head_x := -0.05 + sin(t * 1.6) * 0.06 + nod
	var arm_l := -0.20 + sin(t * 0.9) * 0.06
	var arm_r := 0.20 - sin(t * 0.9) * 0.06
	var fore_l := -0.30
	var fore_r := 0.30
	# `reach` swings an arm forward over the deck (negative X rotation = towards camera,
	# which is the way the booth faces). Without it the hands hang behind the cabinet.
	var reach_l := -0.42
	var reach_r := -0.72
	var elbow_x := 0.0
	match dj.state:
		STATE_FADER:
			# Right hand over the mixer, small precise moves; left keeps the rhythm.
			arm_r = 0.62 + sin(t * 3.2) * 0.10
			fore_r = 0.55
			arm_l = -0.18
			reach_r = -1.16
			reach_l = -0.38
			elbow_x = -0.22
			head_x = 0.10 + nod * 0.6
			torso_x = 0.10
		STATE_POINT:
			# Arm straight out at the fighters on the side that just connected.
			arm_l = -1.52 if dj.point_dir < 0.0 else -0.55
			fore_l = -0.12
			reach_l = -1.34
			torso_z = 0.10 * dj.point_dir
			head_x = -0.10
		STATE_AIRHORN:
			arm_r = 2.55 + sin(t * 2.4) * 0.08
			fore_r = 0.18
			reach_r = -0.34
			arm_l = -0.30
			reach_l = -0.50
			torso_x = -0.10
			head_x = -0.22
		STATE_CELEBRATE:
			bob = absf(sin(t * 2.0)) * 0.07
			torso_x = -0.14
			torso_z = sin(t * 2.0) * 0.10
			head_x = -0.26
			arm_l = -2.55 + sin(t * 2.3) * 0.12
			arm_r = 2.55 - sin(t * 2.3 + 0.6) * 0.12
			fore_l = -0.28
			fore_r = 0.28
			reach_l = -0.18
			reach_r = -0.18
		_:
			# Neutral skank: shoulders loose, head nodding, hands resting on the rig.
			arm_l = -0.26 + sin(t * 1.3) * 0.08
			arm_r = 0.30 - sin(t * 1.3 + 0.8) * 0.08
			fore_l = -0.38
			fore_r = 0.42
	dj.node.position.y = bob
	dj.torso.rotation = Vector3(torso_x, sin(t * 0.5) * 0.10, torso_z)
	dj.head.rotation = Vector3(head_x, sin(t * 0.7) * 0.12, sin(t * 1.1) * 0.05)
	dj.arm_l.rotation = Vector3(reach_l, 0.0, arm_l)
	dj.arm_r.rotation = Vector3(reach_r, 0.0, arm_r)
	dj.fore_l.rotation = Vector3(elbow_x, 0.0, fore_l)
	dj.fore_r.rotation = Vector3(elbow_x, 0.0, fore_r)


# =========================================================================
# Geometry
# =========================================================================
func _build_deck() -> void:
	var booth := Node3D.new()
	booth.name = "Booth"
	add_child(booth)

	_add_mesh(booth, "Plinth", _box(Vector3(BOOTH_W + 0.16, 0.16, 0.9)),
		Vector3(0.0, 0.08, 0.0), _deck_material)
	_add_mesh(booth, "Cabinet", _box(Vector3(BOOTH_W, BOOTH_H - 0.14, 0.82)),
		Vector3(0.0, 0.16 + (BOOTH_H - 0.14) * 0.5, 0.0), _deck_material)
	_add_mesh(booth, "Top", _box(Vector3(BOOTH_W + 0.12, 0.08, 0.94)),
		Vector3(0.0, BOOTH_H, 0.0), _deck_material)
	# Rasta stripe on the front panel, matching the speaker stacks.
	for i in 3:
		_add_mesh(booth, "Stripe%d" % i, _box(Vector3(BOOTH_W - 0.30, 0.075, 0.02)),
			Vector3(0.0, 0.34 + float(i) * 0.13, 0.415), _rasta_material(RASTA[i]))
	# Booth monitor wedges at each end, angled towards the DJs.
	for side in [-1.0, 1.0]:
		var wedge := _add_mesh(booth, "Monitor", _box(Vector3(0.30, 0.26, 0.24)),
			Vector3(side * (BOOTH_W * 0.5 - 0.12), BOOTH_H + 0.17, -0.42), _deck_material)
		wedge.rotation.x = -0.35

	# Two turntable platters with records and tonearms, plus a mixer in the middle.
	for side in [-1.0, 1.0]:
		_add_mesh(booth, "DeckBase", _box(Vector3(0.72, 0.07, 0.66)),
			Vector3(side * 0.80, BOOTH_H + 0.075, 0.02), _deck_material)
		_add_mesh(booth, "Platter", _cylinder(0.245, 0.245, 0.035, 12),
			Vector3(side * 0.80, BOOTH_H + 0.128, 0.02), _metal_material)
		var record := Node3D.new()
		record.name = "Record"
		record.position = Vector3(side * 0.80, BOOTH_H + 0.152, 0.02)
		booth.add_child(record)
		_add_mesh(record, "Vinyl", _cylinder(0.225, 0.225, 0.012, 12),
			Vector3.ZERO, _vinyl_material)
		_add_mesh(record, "Label", _cylinder(0.075, 0.075, 0.016, 8),
			Vector3.ZERO, _label_material)
		_records.append(record)
		var arm := _add_mesh(booth, "Tonearm", _box(Vector3(0.024, 0.014, 0.24)),
			Vector3(side * 0.80 + side * 0.24, BOOTH_H + 0.16, -0.06), _metal_material)
		arm.rotation.y = side * 0.32

	_add_mesh(booth, "Mixer", _box(Vector3(0.46, 0.12, 0.62)),
		Vector3(0.0, BOOTH_H + 0.10, 0.02), _deck_material)
	for i in 3:
		var fader := _add_mesh(booth, "ChannelFader%d" % i, _box(Vector3(0.035, 0.03, 0.05)),
			Vector3(-0.12 + float(i) * 0.12, BOOTH_H + 0.18, 0.0), _metal_material)
		_faders.append(fader)
	_crossfader = _add_mesh(booth, "Crossfader", _box(Vector3(0.05, 0.03, 0.04)),
		Vector3(0.0, BOOTH_H + 0.18, 0.22), _metal_material)
	for i in 4:
		_add_mesh(booth, "Knob%d" % i, _cylinder(0.022, 0.022, 0.028, 6),
			Vector3(-0.09 + float(i) * 0.06, BOOTH_H + 0.18, -0.18), _metal_material)

	# A small gantry sign over the booth so the deck reads at a distance.
	_add_mesh(booth, "SignPostL", _box(Vector3(0.05, 1.05, 0.05)),
		Vector3(-0.9, BOOTH_H + 0.55, -0.30), _metal_material)
	_add_mesh(booth, "SignPostR", _box(Vector3(0.05, 1.05, 0.05)),
		Vector3(0.9, BOOTH_H + 0.55, -0.30), _metal_material)
	_add_mesh(booth, "SignBoard", _box(Vector3(1.5, 0.26, 0.05)),
		Vector3(0.0, BOOTH_H + 1.0, -0.30), _deck_material)


func _make_dj(index: int, x: float, with_horn: bool) -> void:
	var dj := DJ.new()
	dj.phase = _rng.randf_range(0.0, TAU)
	dj.rate = _rng.randf_range(0.95, 1.15)

	var node := Node3D.new()
	node.name = "DJ%d" % (index + 1)
	# Behind the decks: further from the camera than the booth, in the gap between the
	# speaker stacks and the front crowd row.
	node.position = Vector3(x, 0.0, -0.62)
	add_child(node)

	_add_mesh(node, "LegL", _cylinder(0.075, 0.065, 0.80, 6),
		Vector3(-0.10, 0.40, 0.0), _body_material)
	_add_mesh(node, "LegR", _cylinder(0.075, 0.065, 0.80, 6),
		Vector3(0.10, 0.40, 0.0), _body_material)
	_add_mesh(node, "Hips", _cylinder(0.20, 0.18, 0.26, 8),
		Vector3(0.0, 0.90, 0.0), _body_material)

	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 1.00, 0.0)
	node.add_child(torso)
	_add_mesh(torso, "Chest", _cylinder(0.195, 0.170, 0.46, 8),
		Vector3(0.0, 0.23, 0.0), _body_material)
	_add_mesh(torso, "Shoulders", _cylinder(0.235, 0.215, 0.11, 8),
		Vector3(0.0, 0.42, 0.0), _body_material)
	# Mesh string vest / chain hint: one thin bright band across the chest.
	_add_mesh(torso, "Chain", _box(Vector3(0.22, 0.014, 0.02)),
		Vector3(0.0, 0.33, 0.165), _metal_material)
	dj.torso = torso

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 0.52, 0.0)
	torso.add_child(head)
	_add_mesh(head, "Skull", _sphere(0.122, 6, 3), Vector3.ZERO, _body_material)
	_add_mesh(head, "Neck", _cylinder(0.056, 0.062, 0.08, 6),
		Vector3(0.0, -0.11, 0.0), _body_material)
	if index == 0:
		# Bucket hat, held high — the selector's silhouette.
		_add_mesh(head, "HatCrown", _cylinder(0.138, 0.152, 0.12, 8),
			Vector3(0.0, 0.095, 0.0), _body_material)
		_add_mesh(head, "HatBrim", _cylinder(0.225, 0.225, 0.020, 8),
			Vector3(0.0, 0.032, 0.0), _body_material)
	else:
		# Locks and a headwrap for the second DJ.
		_add_mesh(head, "Headwrap", _cylinder(0.140, 0.150, 0.09, 8),
			Vector3(0.0, 0.075, 0.0), _body_material)
		for i in 6:
			var angle := -1.1 + float(i) * 0.44
			_add_mesh(head, "Lock%d" % i,
				_cylinder(0.022, 0.013, _rng.randf_range(0.26, 0.36), 4),
				Vector3(sin(angle) * 0.105, -0.12, cos(angle) * 0.085), _body_material)
	dj.head = head

	dj.arm_l = _make_arm(torso, -1.0, "ArmL")
	dj.arm_r = _make_arm(torso, 1.0, "ArmR")
	dj.fore_l = dj.arm_l.get_node("Forearm")
	dj.fore_r = dj.arm_r.get_node("Forearm")
	if with_horn:
		dj.horn = _make_horn(dj.fore_r)

	dj.node = node
	_pose_dj(dj, 0.0)
	_djs.append(dj)


func _make_arm(torso: Node3D, side: float, node_name: String) -> Node3D:
	var shoulder := Node3D.new()
	shoulder.name = node_name
	shoulder.position = Vector3(side * 0.225, 0.38, 0.0)
	torso.add_child(shoulder)
	_add_mesh(shoulder, "UpperArm", _cylinder(0.058, 0.048, 0.30, 6),
		Vector3(0.0, -0.15, 0.0), _body_material)
	var elbow := Node3D.new()
	elbow.name = "Forearm"
	elbow.position = Vector3(0.0, -0.30, 0.0)
	shoulder.add_child(elbow)
	_add_mesh(elbow, "LowerArm", _cylinder(0.048, 0.038, 0.28, 6),
		Vector3(0.0, -0.14, 0.0), _body_material)
	_add_mesh(elbow, "Hand", _box(Vector3(0.070, 0.095, 0.060)),
		Vector3(0.0, -0.31, 0.0), _body_material)
	return shoulder


func _make_horn(forearm: Node3D) -> Node3D:
	var horn := Node3D.new()
	horn.name = "Airhorn"
	horn.position = Vector3(0.0, -0.33, 0.03)
	forearm.add_child(horn)
	_add_mesh(horn, "HornBody", _cylinder(0.062, 0.042, 0.22, 6),
		Vector3(0.0, 0.07, 0.0), _metal_material)
	_add_mesh(horn, "HornBell", _cylinder(0.115, 0.052, 0.13, 6),
		Vector3(0.0, 0.24, 0.0), _metal_material)
	_add_mesh(horn, "HornCan", _cylinder(0.050, 0.050, 0.11, 6),
		Vector3(0.085, -0.02, 0.0), _metal_material)
	return horn


# =========================================================================
# Shared materials and primitives
# =========================================================================
func _build_materials() -> void:
	_body_material = ShaderMaterial.new()
	_body_material.shader = SILHOUETTE_SHADER
	_body_material.set_shader_parameter("body_colour", Color(0.055, 0.05, 0.07))
	_body_material.set_shader_parameter("rim_colour", Color(1.0, 0.74, 0.34))
	_body_material.set_shader_parameter("rim_strength", 1.05)
	_body_material.set_shader_parameter("rim_power", 2.4)
	_deck_material = _mat(Color(0.07, 0.07, 0.085), 0.85, 0.10)
	_metal_material = _mat(Color(0.62, 0.62, 0.58), 0.38, 0.75)
	_vinyl_material = _mat(Color(0.03, 0.03, 0.04), 0.30, 0.35)
	_label_material = _mat(Color(0.92, 0.72, 0.18), 0.55, 0.20)


func _mat(colour: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


func _rasta_material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	mat.emission_enabled = true
	mat.emission = colour * 0.4
	mat.emission_energy_multiplier = 0.7
	return mat


func _add_mesh(parent: Node3D, node_name: String, mesh: Mesh, at: Vector3,
		material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = at
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _cylinder(top: float, bottom: float, height: float, segments: int = 8) -> CylinderMesh:
	var key := "cyl_%.3f_%.3f_%.3f_%d" % [top, bottom, height, segments]
	if not _mesh_cache.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = top
		mesh.bottom_radius = bottom
		mesh.height = height
		mesh.radial_segments = segments
		mesh.rings = 1
		_mesh_cache[key] = mesh
	return _mesh_cache[key]


func _sphere(radius: float, segments: int, rings: int) -> SphereMesh:
	var key := "sph_%.3f_%d_%d" % [radius, segments, rings]
	if not _mesh_cache.has(key):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = segments
		mesh.rings = rings
		_mesh_cache[key] = mesh
	return _mesh_cache[key]


func _box(size: Vector3) -> BoxMesh:
	var key := "box_%.3f_%.3f_%.3f" % [size.x, size.y, size.z]
	if not _mesh_cache.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		_mesh_cache[key] = mesh
	return _mesh_cache[key]

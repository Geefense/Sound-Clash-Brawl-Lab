class_name DJBooth3D
extends Node3D
## Active Sound-System DJ booth behind the decks (owner playtest, 2026-11-23).
##
## Two rim-lit 2.5D DJ silhouettes work a turntable-and-mixer rig between the mid-ground
## speaker stacks. Presentation only: this node never touches the combat simulation,
## hitboxes, frame data, the beat clock or the audio engine — it only poses the layers to
## the cues `Arena3D.notify_combat_event()` already receives.
##
## The DJs are no longer lathed capsule mannequins. Each one is a camera-facing
## `StageSilhouette` wearing a mask painted by `SilhouetteArt`: neutral skank, hand on the
## faders, arm out at the fighters, horn up, or both arms up. The turntables, platters,
## records, mixer, faders, knobs, monitors and sign are still real geometry — those are
## props, not stand-in people.
##
## Real character art drops straight in: `CharacterModelSlots` instances any `.fbx`/`.glb` in
## `assets/models/dj/` behind the deck and hides the silhouette for that slot.
##
## Everything is low-poly with shared meshes, included in `Arena3D.atmosphere_triangles()`
## under the 15 000-triangle budget.

const DJ_COUNT := 2
const STATE_IDLE := &"idle"
const STATE_FADER := &"fader"
const STATE_POINT := &"point"
const STATE_AIRHORN := &"airhorn"
const STATE_CELEBRATE := &"celebrate"
const STATE_DISBELIEF := &"disbelief"
const DJ_TINT := Color(1.0, 0.98, 0.93)
const DJ_RIM := Color(1.0, 0.78, 0.34)
const HAND_BONE := "mixamorig_RightHand"

const BOOTH_W := 2.50
const BOOTH_H := 0.94
const DJ_HEIGHT := 1.62

const RASTA := [
	Color(0.12, 0.42, 0.16, 1.0),
	Color(0.86, 0.68, 0.12, 1.0),
	Color(0.62, 0.10, 0.09, 1.0),
]


class DJ:
	var node: Node3D
	var body: StageSilhouette
	var model: Node3D = null
	var player: AnimationPlayer = null
	var clips: Dictionary = {}
	var act: StringName = &""
	var hand_attachment: BoneAttachment3D = null
	var horn: Node3D = null
	var base_y: float = 0.0
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
	_load_models()


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
			# The other selector answers the knockdown with disbelief, not a cheer.
			if _djs.size() > 1:
				_djs[1].state = STATE_DISBELIEF
				_djs[1].hold = 1.4
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
	for dj in _djs:
		_play_model_act(dj, dj.state)


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
				_play_model_act(dj, dj.state)
		dj.nod = maxf(0.0, dj.nod - delta * 3.2)
		dj.phase = fposmod(dj.phase + dj.rate * delta, TAU)
		_pose_dj(dj, delta)


## Back to a neutral mix, e.g. when a round is reset.
func settle() -> void:
	for dj in _djs:
		dj.state = STATE_IDLE
		dj.hold = 0.0
		dj.nod = 0.0
		dj.act = &""
		_pose_dj(dj, 0.0)
		_play_model_act(dj, dj.state)


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


func disbelieving() -> bool:
	for dj in _djs:
		if dj.state == STATE_DISBELIEF:
			return true
	return false


## Selectors currently played by a real Mixamo character.
func animated_model_count() -> int:
	var n := 0
	for dj in _djs:
		if dj.player != null:
			n += 1
	return n


func model_act_of(index: int) -> StringName:
	if index < 0 or index >= _djs.size():
		return &""
	return _djs[index].act


func model_clip_of(index: int) -> String:
	if index < 0 or index >= _djs.size():
		return ""
	var player := _djs[index].player
	return player.current_animation if player != null else ""


func hand_attached_props() -> int:
	var n := 0
	for dj in _djs:
		if dj.hand_attachment != null:
			n += 1
	return n


func pointing() -> bool:
	for dj in _djs:
		if dj.state == STATE_POINT:
			return true
	return false


func fader_position() -> float:
	return _fader_value


func record_spin() -> float:
	return _records[0].rotation.y if not _records.is_empty() and _records[0] != null else 0.0


# =========================================================================
# 2.5D DJs and .fbx slots
# =========================================================================
## DJs currently drawn as rim-lit 2.5D silhouettes.
func silhouette_count() -> int:
	var n := 0
	for dj in _djs:
		if dj.body != null and dj.body.visible:
			n += 1
	return n


## Imported `.fbx`/`.glb` DJ characters (empty until art is delivered).
func model_slots() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for dj in _djs:
		if dj.model != null:
			found.append(dj.model)
	return found


## True while the silhouettes are the visible stand-ins.
func using_fallback() -> bool:
	for dj in _djs:
		if dj.model != null:
			return false
	return true


## Leftover capsule-mannequin geometry. Must stay at zero: the silhouettes replaced it.
func legacy_mannequin_count() -> int:
	var n := 0
	for legacy in ["LegL", "LegR", "Chest", "Skull", "Torso", "ArmL", "ArmR"]:
		n += find_children(legacy, "MeshInstance3D", true, false).size()
	return n


## Any `.fbx`/`.glb` in `assets/models/dj/` replaces a DJ silhouette, in filename order.
func _load_models() -> void:
	var paths := CharacterModelSlots.model_paths(CharacterModelSlots.DJ_DIR)
	if paths.is_empty():
		return
	for i in _djs.size():
		var dj := _djs[i]
		var model := CharacterModelSlots.spawn_one(dj.node, paths[i % paths.size()], DJ_HEIGHT)
		if model == null:
			continue
		CharacterModelSlots.apply_cel(model, DJ_TINT, DJ_RIM, 10 + i)
		dj.clips = CharacterModelSlots.install_act_clips(model)
		dj.player = dj.clips.get("player") as AnimationPlayer
		if dj.player != null:
			dj.player.speed_scale = dj.rate
		dj.act = &""
		dj.model = model
		dj.body.visible = false
		# The airhorn rides the selector's right hand, so it lifts with the real clip
		# instead of floating beside a standing body.
		if dj.horn != null:
			dj.hand_attachment = _attach_to_hand(model, dj.horn, "AirhornHand")
		_play_model_act(dj, dj.state)


## Crossfade the delivered selector to the act its booth state calls for.
func _play_model_act(dj: DJ, state: StringName) -> void:
	if dj.model == null or dj.player == null or dj.clips.is_empty():
		return
	var act: StringName = CharacterModelSlots.ACT_NEUTRAL
	match state:
		STATE_CELEBRATE:
			act = CharacterModelSlots.ACT_CHEER
		STATE_DISBELIEF:
			act = CharacterModelSlots.ACT_DISBELIEF
		STATE_POINT, STATE_AIRHORN:
			act = CharacterModelSlots.ACT_HYPE
	if act == dj.act:
		return
	dj.act = act
	CharacterModelSlots.play_act(dj.model, dj.clips, act, CharacterModelSlots.ACT_FADE)


## BoneAttachment3D is the same hand-parenting the fighters use for their mics: a prop
## reparented under `mixamorig_RightHand` follows every idle, point and celebration pose.
func _attach_to_hand(model: Node3D, prop: Node3D, node_name: String) -> BoneAttachment3D:
	if model == null or prop == null:
		return null
	var skeleton: Skeleton3D = null
	for child in model.find_children("*", "Skeleton3D", true, false):
		skeleton = child as Skeleton3D
		break
	if skeleton == null or skeleton.find_bone(HAND_BONE) < 0:
		return null
	var attachment := BoneAttachment3D.new()
	attachment.name = node_name
	attachment.bone_name = HAND_BONE
	skeleton.add_child(attachment)
	prop.reparent(attachment, false)
	prop.transform = Transform3D.IDENTITY
	return attachment


func triangle_count() -> int:
	var total := 0
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			total += int(mi.mesh.get_faces().size() / 3)
	return total


func set_palette(rim_a: Color, rim_b: Color, strength: float) -> void:
	var rim := rim_a.lerp(rim_b, 0.45)
	var boost := clampf(strength * 0.95, 0.2, 2.6)
	SilhouetteArt.set_palette(rim, boost)
	if _body_material != null:
		_body_material.set_shader_parameter("rim_colour", rim)
		_body_material.set_shader_parameter("rim_strength", boost)


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


## The acting frame: the state picks the painted mask (neutral, fader, point, horn,
## celebrate) and the DJ's own phase adds the nod, lean and little skank bounce.
func _pose_dj(dj: DJ, _delta: float) -> void:
	if dj.body == null:
		return
	var t := dj.phase
	var pose: StringName = STATE_IDLE
	match dj.state:
		STATE_FADER:
			pose = &"fader"
		STATE_POINT:
			pose = &"point"
		STATE_AIRHORN:
			pose = &"airhorn"
		STATE_CELEBRATE:
			pose = &"celebrate"
		STATE_DISBELIEF:
			pose = &"idle"
	dj.body.set_pose(pose)
	var bob := absf(sin(t * 1.6)) * 0.024 + dj.nod * 0.03
	if dj.model != null:
		# The Mixamo clip owns the body motion; a second procedural bob would double it.
		bob = 0.0
	dj.node.position.y = dj.base_y + bob
	var lean := sin(t * 0.8) * 0.05
	match dj.state:
		STATE_POINT:
			lean += 0.08 * dj.point_dir
		STATE_AIRHORN:
			lean -= 0.07
		STATE_CELEBRATE:
			lean += sin(t * 2.0) * 0.08
		STATE_FADER:
			lean += 0.05
	dj.body.lean(lean)
	dj.body.squash(-0.03 if dj.state == STATE_CELEBRATE else 0.0)
	if dj.horn != null:
		dj.horn.visible = dj.state == STATE_AIRHORN
		if dj.horn.visible:
			dj.horn.rotation.z = -0.25 + sin(t * 2.4) * 0.10


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


## One DJ: a 2.5D silhouette behind the decks (between the speaker stacks and the front
## crowd row) plus the airhorn prop that only the selector carries.
func _make_dj(index: int, x: float, with_horn: bool) -> void:
	var dj := DJ.new()
	dj.phase = _rng.randf_range(0.0, TAU)
	dj.rate = _rng.randf_range(0.95, 1.15)

	var node := Node3D.new()
	node.name = "DJ%d" % (index + 1)
	node.position = Vector3(x, 0.0, -0.62)
	add_child(node)

	var body := StageSilhouette.new()
	body.name = "Body"
	body.configure("dj", index, DJ_HEIGHT)
	node.add_child(body)

	dj.node = node
	dj.body = body
	dj.base_y = 0.0
	if with_horn:
		dj.horn = _make_horn(node)
		dj.horn.visible = false
	_pose_dj(dj, 0.0)
	_djs.append(dj)


func _make_horn(parent: Node3D) -> Node3D:
	var horn := Node3D.new()
	horn.name = "Airhorn"
	horn.position = Vector3(0.34, 1.28, 0.12)
	parent.add_child(horn)
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
	_body_material = SilhouetteArt.material_for("dj", 0, STATE_IDLE)
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


func _box(size: Vector3) -> BoxMesh:
	var key := "box_%.3f_%.3f_%.3f" % [size.x, size.y, size.z]
	if not _mesh_cache.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		_mesh_cache[key] = mesh
	return _mesh_cache[key]

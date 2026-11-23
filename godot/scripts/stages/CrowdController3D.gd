class_name CrowdController3D
extends Node3D
## Staggered, reactive 3D crowd at the barrier (owner playtest, 2026-11-23).
##
## Presentation only: this node reads no fighter state and never touches the combat
## simulation, hitboxes, frame data, audio or the round clock. `Arena3D.notify_combat_event()`
## forwards the arena's own cues (hit landed, heavy hit, knockdown, K.O., victory, DJ tag,
## Hype surge) here, and every spectator answers on its own delayed clock — ringside first,
## back rows last — so excitement ripples outward instead of the whole bank jumping in unison.
##
## Two loyalty zones: the left bank is P1's corner, the right bank is P2's corner. When a
## side scores, its bank erupts (jump, arms overhead, flags whipping) while the rival bank
## throws both hands on its head in disbelief. Neutral cues (DJ tag, Hype surge, a tie) lift
## both banks.
##
## Bodies are rim-lit 2.5D silhouettes (`StageSilhouette` + the masks painted by
## `SilhouetteArt`), not lathed capsule mannequins: one camera-facing quad per spectator,
## two triangles, a shared mask per variant and pose. Hats, headwraps and locks, the raised
## arms, the disbelief hands-on-head and the neutral skank are all baked into those masks.
## Three waving Jamaican flags, six raised lighters whose flames spark up on heavy hits and
## Hype moments, and two airhorn operators stand at the inner edge of each bank beside the
## speaker stacks.
##
## Real character art drops straight in: `CharacterModelSlots` instances any `.fbx`/`.glb`
## in `assets/models/crowd/` and hides the silhouette for those spectators, so replacing the
## placeholders later needs no change here.

## 20 spectators across two banks and three rows, matching the 16–24 owner range.
const COUNT := 20
const ZONE_LEFT := 0
const ZONE_RIGHT := 1
const ROW_Z := [-4.30, -5.60, -6.90]
const ROW_COUNTS := [4, 3, 3]              # per zone, per row: 10 people a side
const BANK_X := [Vector2(-6.15, -2.35), Vector2(2.35, 6.15)]

## Staggering. A body's reaction delay is its row's base plus how far out along the bank it
## stands, plus a small seeded jitter, so no two people ever land on the same tick.
const ROW_DELAY := 0.12
const LATERAL_DELAY := 0.028
const JITTER := 0.04
const REACT_HOLD := 2.4

const STATE_IDLE := &"idle"
const STATE_CHEER := &"cheer"
const STATE_DISBELIEF := &"disbelief"
const STATE_HYPE := &"hype"

const FLAG_COLOURS := [
	Color(0.10, 0.42, 0.16, 1.0),          # green
	Color(0.86, 0.68, 0.12, 1.0),          # gold
	Color(0.06, 0.06, 0.07, 1.0),          # black
]


class Member:
	var node: Node3D                       # anchor on the row; props ride with it
	var body: StageSilhouette              # the 2.5D silhouette (hidden once a model lands)
	var model: Node3D = null               # imported .fbx character, when one exists
	var height: float = 1.72
	var base_y: float = 0.0
	var zone: int = 0
	var row: int = 0
	var x: float = 0.0
	var phase: float = 0.0
	var rate: float = 1.0
	var delay: float = 0.0
	var state: StringName = STATE_IDLE
	var pending: StringName = &""
	var timer: float = 0.0
	var hold: float = 0.0
	var flag: Node3D = null
	var flag_cloth: Node3D = null
	var flame: Node3D = null
	var horn: Node3D = null
	var lighter: bool = false
	var lit: bool = false
	var horn_up: bool = false


var _members: Array[Member] = []
var _models: Array[Node3D] = []
var _mesh_cache: Dictionary = {}
var _body_material: ShaderMaterial
var _cloth_materials: Array[StandardMaterial3D] = []
var _flame_material: StandardMaterial3D
var _time: float = 0.0
var _reactions: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if _members.is_empty():
		build()


# =========================================================================
# Construction
# =========================================================================
## Build the banks. Called by `Arena3D` right after this node is added; `_ready()` also
## builds a standalone instance so the crowd works in any scene.
func build() -> void:
	if not _members.is_empty():
		return
	_rng.seed = 20261122
	_build_materials()
	var index := 0
	for zone in [ZONE_LEFT, ZONE_RIGHT]:
		for row in ROW_COUNTS.size():
			var count: int = ROW_COUNTS[row]
			for i in count:
				# Even spread across the bank with a little seeded jitter, so the rows read as
				# a packed yard rather than a grid.
				var t := (float(i) + 0.5) / float(count)
				var bank: Vector2 = BANK_X[zone]
				var x := lerpf(bank.x, bank.y, t) + _rng.randf_range(-0.16, 0.16)
				_members.append(_make_member(index, zone, row, x))
				index += 1
	_assign_props()
	_load_models()


func _make_member(index: int, zone: int, row: int, x: float) -> Member:
	var m := Member.new()
	m.zone = zone
	m.row = row
	m.x = x
	m.phase = _rng.randf_range(0.0, TAU)
	m.rate = _rng.randf_range(0.85, 1.35)
	m.delay = float(row) * ROW_DELAY + absf(x) * LATERAL_DELAY + _rng.randf_range(0.0, JITTER)
	m.height = _rng.randf_range(1.55, 1.90)

	var anchor := Node3D.new()
	anchor.name = "Spectator%02d" % index
	anchor.position = Vector3(x, 0.0, ROW_Z[row])
	# Everyone turns slightly towards the centre of the yard, where the fight is. A 2.5D
	# quad needs only a few degrees of yaw to stop the bank reading as one flat cardboard row.
	anchor.rotation.y = _rng.randf_range(-0.16, 0.16)
	add_child(anchor)

	var body := StageSilhouette.new()
	body.name = "Body"
	body.configure("crowd", index % 3, m.height)
	anchor.add_child(body)

	m.node = anchor
	m.body = body
	m.base_y = 0.0
	_pose_member(m, 0.0)
	return m


## Three flags, six lighters, two airhorn operators — chosen by position so the props sit in
## the banks instead of stacking on one person.
func _assign_props() -> void:
	var inner: Dictionary = {}          # zone -> member with the smallest |x| in the front row
	for m in _members:
		if m.row != 0:
			continue
		var current = inner.get(m.zone)
		if current == null or absf(m.x) < absf((current as Member).x):
			inner[m.zone] = m
	for zone in inner:
		var operator: Member = inner[zone]
		operator.horn = _add_horn(operator)
		operator.horn_up = false

	var flag_indices := [1, 9, 16]
	var lighter_indices := [3, 6, 11, 13, 17, 19]
	for i in flag_indices:
		if i >= _members.size():
			continue
		var m := _members[i]
		m.flag = _add_flag(m, i % FLAG_COLOURS.size())
	for i in lighter_indices:
		if i >= _members.size():
			continue
		var m := _members[i]
		m.lighter = true
		m.flame = _add_flame(m)


## Any `.fbx`/`.glb` character delivered into `assets/models/crowd/` replaces the silhouette
## for that spectator, in sorted filename order. No file means the fallback stays on screen.
func _load_models() -> void:
	var paths := CharacterModelSlots.model_paths(CharacterModelSlots.CROWD_DIR)
	if paths.is_empty():
		return
	for i in _members.size():
		var m := _members[i]
		var model := CharacterModelSlots.spawn_one(m.node, paths[i % paths.size()], m.height)
		if model == null:
			continue
		m.model = model
		m.body.visible = false
		_models.append(model)


func _add_flag(m: Member, colour: int) -> Node3D:
	var pole := Node3D.new()
	pole.name = "FlagPole"
	pole.position = Vector3(0.30, 0.0, 0.10)
	m.node.add_child(pole)
	_add_mesh(pole, "Pole", _cylinder(0.012, 0.012, 0.95, 4),
		Vector3(0.0, 0.52, 0.0), _body_material)
	var cloth := Node3D.new()
	cloth.name = "FlagCloth"
	cloth.position = Vector3(0.0, 1.02, 0.0)
	pole.add_child(cloth)
	_add_mesh(cloth, "Cloth", _quad(Vector2(0.46, 0.30), 3, 2),
		Vector3(0.23, 0.0, 0.0), _cloth_materials[colour])
	m.flag_cloth = cloth
	return pole


func _add_flame(m: Member) -> Node3D:
	var hand := Node3D.new()
	hand.name = "LighterHand"
	hand.position = Vector3(-0.30, 1.34, 0.12)
	m.node.add_child(hand)
	_add_mesh(hand, "Lighter", _box(Vector3(0.045, 0.075, 0.032)),
		Vector3.ZERO, _body_material)
	var flame := Node3D.new()
	flame.name = "LighterFlame"
	flame.position = Vector3(0.0, 0.09, 0.02)
	hand.add_child(flame)
	_add_mesh(flame, "Flame", _quad(Vector2(0.055, 0.115), 1, 1),
		Vector3(0.0, 0.055, 0.0), _flame_material)
	flame.visible = false
	return flame


func _add_horn(m: Member) -> Node3D:
	var horn := Node3D.new()
	horn.name = "Airhorn"
	horn.position = Vector3(0.30, 1.20, 0.12)
	m.node.add_child(horn)
	_add_mesh(horn, "HornBody", _cylinder(0.055, 0.038, 0.20, 6),
		Vector3(0.0, 0.06, 0.0), _body_material)
	_add_mesh(horn, "HornBell", _cylinder(0.105, 0.048, 0.12, 6),
		Vector3(0.0, 0.21, 0.0), _body_material)
	_add_mesh(horn, "HornCan", _cylinder(0.045, 0.045, 0.10, 6),
		Vector3(0.075, -0.02, 0.0), _body_material)
	return horn


# =========================================================================
# Public API — reactions
# =========================================================================
## Cue from `Arena3D.notify_combat_event()`. `side` is the corner that scored (0 = left /
## P1, 1 = right / P2); −1 is a neutral roar that lifts both banks.
func react(kind: StringName, side: int = -1) -> void:
	_reactions += 1
	var winner_state := STATE_CHEER
	var rival_state := STATE_DISBELIEF
	var lights := false
	var hold := REACT_HOLD
	match kind:
		&"hit":
			winner_state = STATE_CHEER
			rival_state = STATE_IDLE
			hold = 1.0
		&"heavy_hit":
			winner_state = STATE_CHEER
			rival_state = STATE_DISBELIEF
			lights = true
			hold = 2.2
		&"knockdown":
			winner_state = STATE_HYPE
			rival_state = STATE_DISBELIEF
			lights = true
			hold = 2.8
		&"ko":
			winner_state = STATE_HYPE
			rival_state = STATE_DISBELIEF
			lights = true
			hold = 4.0
		&"victory":
			winner_state = STATE_HYPE
			rival_state = STATE_DISBELIEF
			lights = true
			hold = 4.5
		&"tag":
			winner_state = STATE_CHEER
			rival_state = STATE_CHEER
			hold = 1.6
		&"hype":
			winner_state = STATE_HYPE
			rival_state = STATE_HYPE
			lights = true
			hold = 3.0
		_:
			winner_state = STATE_CHEER
			rival_state = STATE_CHEER
			hold = 1.4
	for m in _members:
		var cheers := side < 0 or m.zone == side
		var want := winner_state if cheers else rival_state
		if want == STATE_IDLE:
			continue
		# An airhorn operator answers a knockdown, K.O. or DJ tag by lifting the horn rather
		# than only cheering, so the speaker stacks get their moment.
		if m.horn != null and (kind == &"knockdown" or kind == &"ko" or kind == &"tag"):
			want = STATE_HYPE
			m.horn_up = true
		m.pending = want
		m.timer = m.delay + _rng.randf_range(0.0, JITTER)
		m.hold = 0.0
		if lights and m.lighter:
			m.lit = true


## Advance the staggered reaction queue and the ambient acting. `Arena3D` calls this from its
## `_process`; the headless check calls it directly so the ripple is measurable off-screen.
func tick(delta: float) -> void:
	_time += delta
	for m in _members:
		if m.timer > 0.0:
			m.timer -= delta
			if m.timer <= 0.0 and m.pending != &"":
				m.state = m.pending
				m.pending = &""
				m.hold = _hold_for(m.state)
		elif m.hold > 0.0:
			m.hold -= delta
			if m.hold <= 0.0:
				m.state = STATE_IDLE
				m.horn_up = false
				if m.lighter:
					m.lit = false
		m.phase = fposmod(m.phase + m.rate * delta, TAU)
		_pose_member(m, delta)


## Back to neutral: a fresh round must never open on a stale celebration.
func settle() -> void:
	for m in _members:
		m.state = STATE_IDLE
		m.pending = &""
		m.timer = 0.0
		m.hold = 0.0
		m.lit = false
		m.horn_up = false
		if m.flame != null:
			m.flame.visible = false
		_pose_member(m, 0.0)


func _hold_for(state: StringName) -> float:
	match state:
		STATE_HYPE:
			return 2.8
		STATE_CHEER:
			return 2.2
		STATE_DISBELIEF:
			return 2.0
		_:
			return 0.0


# =========================================================================
# Pose
# =========================================================================
## One spectator's acting frame. The *state* picks which painted silhouette mask is on
## screen; the person's own phase drives the hop, lean and squash, so the bank never
## marches in step.
func _pose_member(m: Member, _delta: float) -> void:
	if m.body == null:
		return
	var t := m.phase
	var pose: StringName = &"idle"
	var hop := 0.0
	var lean := 0.0
	var squash := 0.0
	match m.state:
		STATE_CHEER:
			pose = &"cheer"
			hop = absf(sin(t * 1.9)) * 0.13
			lean = sin(t * 1.9) * 0.09 - 0.02
			squash = -0.03
		STATE_DISBELIEF:
			# Both hands on the head, leaning back, shaking: the rival corner.
			pose = &"disbelief"
			hop = absf(sin(t * 2.4)) * 0.012
			lean = sin(t * 0.8) * 0.05
		STATE_HYPE:
			# Lighter or flag held high, bouncing on the spot.
			pose = &"hype"
			hop = absf(sin(t * 1.55)) * 0.17
			lean = sin(t * 0.9) * 0.08
			squash = -0.05
		_:
			# Neutral: the slow skank nod, arms loose, weight shifting side to side.
			pose = &"idle"
			hop = absf(sin(t)) * 0.026
			lean = sin(t * 0.7) * 0.055
	m.body.set_pose(pose)
	m.body.hop(hop)
	m.body.lean(lean)
	m.body.squash(squash)
	if m.flag_cloth != null:
		# Cloth whips harder the more excited its owner is.
		var amp := 0.16 if m.state == STATE_IDLE else 0.36
		m.flag_cloth.rotation.y = sin(t * 2.1) * amp
		m.flag_cloth.rotation.z = sin(t * 1.7 + 0.5) * amp * 0.5
	if m.horn != null:
		var lift := -0.62 if m.horn_up else 0.0
		m.horn.rotation.z = lerpf(m.horn.rotation.z, lift, 0.25)
		m.horn.position.y = 1.20 + (0.10 if m.horn_up else 0.0)
	if m.flame != null:
		var want := m.lit and m.state != STATE_IDLE
		m.flame.visible = want
		if want:
			var flick := 0.82 + sin(t * 9.0) * 0.16 + sin(t * 23.0) * 0.07
			m.flame.scale = Vector3(flick, flick * 1.22, flick)


# =========================================================================
# Palette and reporting
# =========================================================================
## The arena's phase palette: every silhouette shares the rim parameters, so the whole
## crowd repaints together from warm afternoon gold to sunset amber to the night's cyan.
func set_palette(rim_a: Color, rim_b: Color, strength: float) -> void:
	SilhouetteArt.set_palette(rim_a.lerp(rim_b, 0.5), strength * 0.72)
	if _body_material != null:
		_body_material.set_shader_parameter("rim_colour", rim_a.lerp(rim_b, 0.5))
		_body_material.set_shader_parameter("rim_strength", clampf(strength * 0.72, 0.15, 2.4))


func count() -> int:
	return _members.size()


func zone_count(zone: int) -> int:
	var n := 0
	for m in _members:
		if m.zone == zone:
			n += 1
	return n


## Spectators who have actually started acting (their staggered delay has elapsed).
func reacting_count() -> int:
	var n := 0
	for m in _members:
		if m.state != STATE_IDLE:
			n += 1
	return n


## Cues queued but not yet applied — the ripple's in-flight portion.
func pending_count() -> int:
	var n := 0
	for m in _members:
		if m.pending != &"":
			n += 1
	return n


func row_reacting(row: int) -> int:
	var n := 0
	for m in _members:
		if m.row == row and m.state != STATE_IDLE:
			n += 1
	return n


func zone_state_count(zone: int, state: StringName) -> int:
	var n := 0
	for m in _members:
		if m.zone == zone and m.state == state:
			n += 1
	return n


func state_of(index: int) -> StringName:
	if index < 0 or index >= _members.size():
		return &""
	return _members[index].state


func flag_count() -> int:
	var n := 0
	for m in _members:
		if m.flag != null:
			n += 1
	return n


func lighter_slots() -> int:
	var n := 0
	for m in _members:
		if m.lighter:
			n += 1
	return n


func lighter_count() -> int:
	var n := 0
	for m in _members:
		if m.lighter and m.lit:
			n += 1
	return n


func lit_flame_count() -> int:
	var n := 0
	for m in _members:
		if m.flame != null and m.flame.visible:
			n += 1
	return n


func airhorn_count() -> int:
	var n := 0
	for m in _members:
		if m.horn != null:
			n += 1
	return n


func horn_raised() -> int:
	var n := 0
	for m in _members:
		if m.horn != null and m.horn_up:
			n += 1
	return n


func reactions() -> int:
	return _reactions


# =========================================================================
# 2.5D bodies and .fbx slots
# =========================================================================
## Bodies currently drawn as rim-lit 2.5D silhouettes.
func silhouette_count() -> int:
	var n := 0
	for m in _members:
		if m.body != null and m.body.visible:
			n += 1
	return n


## Imported `.fbx`/`.glb` characters standing in the yard (empty until art is delivered).
func model_slots() -> Array[Node3D]:
	return _models


## True while the silhouettes are the visible stand-ins.
func using_fallback() -> bool:
	return _models.is_empty()


## Leftover capsule-mannequin geometry. Must stay at zero: the silhouettes replaced it.
func legacy_mannequin_count() -> int:
	var n := 0
	for legacy in ["LegL", "LegR", "Chest", "Skull", "Hips"]:
		n += find_children(legacy, "MeshInstance3D", true, false).size()
	return n


## Real triangle cost of the built crowd, measured from the actual meshes.
func triangle_count() -> int:
	var total := 0
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			total += int(mi.mesh.get_faces().size() / 3)
	return total


# =========================================================================
# Shared geometry and materials
# =========================================================================
func _build_materials() -> void:
	_body_material = SilhouetteArt.material_for("crowd", 0, STATE_IDLE)
	for colour in FLAG_COLOURS:
		var cloth := StandardMaterial3D.new()
		cloth.albedo_color = colour
		cloth.roughness = 0.95
		cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
		cloth.emission_enabled = true
		cloth.emission = colour * 0.35
		cloth.emission_energy_multiplier = 0.6
		_cloth_materials.append(cloth)
	_flame_material = StandardMaterial3D.new()
	_flame_material.albedo_color = Color(1.0, 0.68, 0.20, 1.0)
	_flame_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flame_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_flame_material.emission_enabled = true
	_flame_material.emission = Color(1.0, 0.55, 0.14)
	_flame_material.emission_energy_multiplier = 2.4


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


## Shared primitive cache: the props reuse a handful of meshes, so the crowd adds almost
## nothing to the export and every draw is the same small vertex buffer.
func _cylinder(top: float, bottom: float, height: float, segments: int = 6) -> CylinderMesh:
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


func _quad(size: Vector2, subdivide_w: int, subdivide_h: int) -> PlaneMesh:
	var key := "quad_%.3f_%.3f_%d_%d" % [size.x, size.y, subdivide_w, subdivide_h]
	if not _mesh_cache.has(key):
		var mesh := PlaneMesh.new()
		mesh.size = size
		mesh.subdivide_width = subdivide_w
		mesh.subdivide_depth = subdivide_h
		mesh.orientation = PlaneMesh.FACE_Z
		_mesh_cache[key] = mesh
	return _mesh_cache[key]

class_name CrowdController3D
extends Node3D
## Staggered, reactive 3D dark-silhouette crowd (owner request, 2026-11-22).
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
## Props, all low-poly primitives: three waving Jamaican flags, six raised lighters whose
## flames spark up on heavy hits and Hype moments, and two airhorn operators standing at the
## inner edge of each bank beside the speaker stacks.
##
## Cost: shared meshes (`_mesh_cache`) and one shared rim `ShaderMaterial` for every body, so
## the whole crowd stays far under the 15 000-triangle atmosphere budget checked by
## `tools/headless_roster_check.gd`.

const SILHOUETTE_SHADER := preload("res://assets/shaders/silhouette_rim.gdshader")

## 20 spectators across two banks and three rows: inside the requested 16–24 range, and small
## enough that 20 articulated rigs are cheap to pose every frame on an Intel Chromebook.
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

const SKIN_SHADOW := Color(0.10, 0.075, 0.06, 1.0)
const FLAG_COLOURS := [
	Color(0.10, 0.42, 0.16, 1.0),          # green
	Color(0.86, 0.68, 0.12, 1.0),          # gold
	Color(0.06, 0.06, 0.07, 1.0),          # black
]


class Member:
	var node: Node3D
	var torso: Node3D
	var head: Node3D
	var arm_l: Node3D
	var arm_r: Node3D
	var fore_l: Node3D
	var fore_r: Node3D
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


func _make_member(index: int, zone: int, row: int, x: float) -> Member:
	var m := Member.new()
	m.zone = zone
	m.row = row
	m.x = x
	m.phase = _rng.randf_range(0.0, TAU)
	m.rate = _rng.randf_range(0.85, 1.35)
	m.delay = float(row) * ROW_DELAY + absf(x) * LATERAL_DELAY + _rng.randf_range(0.0, JITTER)

	var node := Node3D.new()
	node.name = "Spectator%02d" % index
	node.position = Vector3(x, 0.0, ROW_Z[row])
	# Everyone turns slightly towards the centre of the yard, where the fight is.
	node.rotation.y = clampf(-x * 0.055, -0.34, 0.34) + _rng.randf_range(-0.10, 0.10)
	add_child(node)

	# Varied builds: 1.55–1.90 m tall and a little wider or leaner person to person.
	var height := _rng.randf_range(1.55, 1.90)
	var s := height / 1.72
	var width := s * _rng.randf_range(0.92, 1.12)

	# Legs and hips (static: these are silhouettes, the acting is in the torso and arms).
	_add_mesh(node, "LegL", _cylinder(0.070 * width, 0.058 * width, 0.80 * s, 6),
		Vector3(-0.085 * width, 0.40 * s, 0.0), _body_material)
	_add_mesh(node, "LegR", _cylinder(0.070 * width, 0.058 * width, 0.80 * s, 6),
		Vector3(0.085 * width, 0.40 * s, 0.0), _body_material)
	_add_mesh(node, "Hips", _cylinder(0.185 * width, 0.165 * width, 0.26 * s, 8),
		Vector3(0.0, 0.88 * s, 0.0), _body_material)

	# Articulated torso: its own pivot at the waist so it can lean, skank and recoil.
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, 0.98 * s, 0.0)
	node.add_child(torso)
	_add_mesh(torso, "Chest", _cylinder(0.175 * width, 0.150 * width, 0.44 * s, 8),
		Vector3(0.0, 0.22 * s, 0.0), _body_material)
	_add_mesh(torso, "Shoulders", _cylinder(0.215 * width, 0.195 * width, 0.10 * s, 8),
		Vector3(0.0, 0.40 * s, 0.0), _body_material)
	m.torso = torso

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0.0, 0.50 * s, 0.0)
	torso.add_child(head)
	_add_mesh(head, "Skull", _sphere(0.112 * s, 6, 3), Vector3.ZERO, _body_material)
	_add_mesh(head, "Neck", _cylinder(0.052 * s, 0.058 * s, 0.08 * s, 6),
		Vector3(0.0, -0.10 * s, 0.0), _body_material)
	m.head = head
	_dress_head(head, s, index)

	# Arms: shoulder pivot → upper arm → elbow pivot → forearm → hand.
	m.arm_l = _make_arm(torso, -1.0, s, width)
	m.arm_r = _make_arm(torso, 1.0, s, width)
	m.fore_l = m.arm_l.get_node("Forearm")
	m.fore_r = m.arm_r.get_node("Forearm")

	m.node = node
	m.base_y = 0.0
	_pose_member(m, 0.0)
	return m


## Hats, headwraps and dreads vary the silhouette without any new art.
func _dress_head(head: Node3D, s: float, index: int) -> void:
	match index % 5:
		0:
			# Bucket hat: crown plus brim, the yard's most common headwear.
			_add_mesh(head, "HatCrown", _cylinder(0.128 * s, 0.145 * s, 0.11 * s, 8),
				Vector3(0.0, 0.085 * s, 0.0), _body_material)
			_add_mesh(head, "HatBrim", _cylinder(0.205 * s, 0.205 * s, 0.018 * s, 8),
				Vector3(0.0, 0.028 * s, 0.0), _body_material)
		1:
			# Headwrap: a banded cloth cap.
			_add_mesh(head, "Headwrap", _cylinder(0.130 * s, 0.142 * s, 0.085 * s, 8),
				Vector3(0.0, 0.070 * s, 0.0), _body_material)
			_add_mesh(head, "WrapKnot", _box(Vector3(0.07, 0.06, 0.07) * s),
				Vector3(0.115 * s, 0.075 * s, -0.02 * s), _body_material)
		2:
			# Locks: five hanging strands, the classic silhouette.
			for i in 5:
				var angle := -0.9 + float(i) * 0.45
				_add_mesh(head, "Lock%d" % i,
					_cylinder(0.020 * s, 0.012 * s, _rng.randf_range(0.22, 0.32) * s, 4),
					Vector3(sin(angle) * 0.095 * s, -0.10 * s, cos(angle) * 0.075 * s),
					_body_material)
			_add_mesh(head, "CapCrown", _cylinder(0.120 * s, 0.128 * s, 0.075 * s, 8),
				Vector3(0.0, 0.062 * s, 0.0), _body_material)
		3:
			_add_mesh(head, "Cap", _cylinder(0.118 * s, 0.132 * s, 0.08 * s, 8),
				Vector3(0.0, 0.070 * s, 0.0), _body_material)
			_add_mesh(head, "CapPeak", _box(Vector3(0.16, 0.014, 0.11) * s),
				Vector3(0.0, 0.040 * s, 0.13 * s), _body_material)
		_:
			_add_mesh(head, "Beanie", _sphere(0.118 * s, 6, 2),
				Vector3(0.0, 0.070 * s, 0.0), _body_material)


func _make_arm(torso: Node3D, side: float, s: float, width: float) -> Node3D:
	var shoulder := Node3D.new()
	shoulder.name = "ArmL" if side < 0.0 else "ArmR"
	shoulder.position = Vector3(side * 0.205 * width, 0.36 * s, 0.0)
	torso.add_child(shoulder)
	_add_mesh(shoulder, "UpperArm", _cylinder(0.052 * s, 0.044 * s, 0.28 * s, 6),
		Vector3(0.0, -0.14 * s, 0.0), _body_material)
	var elbow := Node3D.new()
	elbow.name = "Forearm"
	elbow.position = Vector3(0.0, -0.28 * s, 0.0)
	shoulder.add_child(elbow)
	_add_mesh(elbow, "LowerArm", _cylinder(0.043 * s, 0.036 * s, 0.26 * s, 6),
		Vector3(0.0, -0.13 * s, 0.0), _body_material)
	_add_mesh(elbow, "Hand", _box(Vector3(0.062, 0.085, 0.055) * s),
		Vector3(0.0, -0.28 * s, 0.0), _body_material)
	return shoulder


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


func _add_flag(m: Member, colour: int) -> Node3D:
	var pole := Node3D.new()
	pole.name = "FlagPole"
	pole.position = Vector3(0.0, -0.30, 0.02)
	m.fore_r.add_child(pole)
	_add_mesh(pole, "Pole", _cylinder(0.012, 0.012, 0.95, 4),
		Vector3(0.0, 0.42, 0.0), _body_material)
	var cloth := Node3D.new()
	cloth.name = "FlagCloth"
	cloth.position = Vector3(0.02, 0.62, 0.0)
	pole.add_child(cloth)
	_add_mesh(cloth, "Cloth", _quad(Vector2(0.46, 0.30), 3, 2),
		Vector3(0.23, 0.0, 0.0), _cloth_materials[colour])
	m.flag_cloth = cloth
	return pole


func _add_flame(m: Member) -> Node3D:
	var flame := Node3D.new()
	flame.name = "LighterFlame"
	flame.position = Vector3(0.0, -0.31, 0.0)
	m.fore_r.add_child(flame)
	# The lighter body is always in the hand; only the flame is lit and hidden.
	_add_mesh(m.fore_r, "Lighter", _box(Vector3(0.045, 0.075, 0.032)),
		Vector3(0.0, -0.30, 0.02), _body_material)
	_add_mesh(flame, "Flame", _quad(Vector2(0.055, 0.115), 1, 1),
		Vector3(0.0, 0.055, 0.0), _flame_material)
	flame.visible = false
	return flame


func _add_horn(m: Member) -> Node3D:
	var horn := Node3D.new()
	horn.name = "Airhorn"
	horn.position = Vector3(0.0, -0.30, 0.03)
	m.fore_r.add_child(horn)
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
## One spectator's acting frame. Every value is derived from that person's own phase, so the
## bank never marches in step; the reaction *state* is what the arena's cues change.
func _pose_member(m: Member, _delta: float) -> void:
	if m.node == null:
		return
	var t := m.phase
	var bob := 0.0
	var torso_x := 0.0
	var torso_z := sin(t * 0.7) * 0.05
	var torso_y := sin(t * 0.45) * 0.08
	var head_x := sin(t * 1.4) * 0.06
	var head_z := 0.0
	var arm_l := -0.12 + sin(t * 0.9) * 0.05
	var arm_r := 0.12 - sin(t * 0.9) * 0.05
	var fore_l := -0.18
	var fore_r := 0.18
	match m.state:
		STATE_CHEER:
			bob = absf(sin(t * 1.9)) * 0.13
			torso_x = -0.10
			torso_z = sin(t * 1.9) * 0.12
			head_x = -0.14 + sin(t * 3.1) * 0.05
			arm_l = -2.45 + sin(t * 2.2) * 0.16
			arm_r = 2.45 - sin(t * 2.2 + 0.7) * 0.16
			fore_l = -0.32
			fore_r = 0.32
		STATE_DISBELIEF:
			# Both hands on the head, leaning back, head shaking: the rival corner.
			torso_x = 0.16
			torso_z = sin(t * 0.8) * 0.04
			head_x = 0.10
			head_z = sin(t * 5.0) * 0.16
			arm_l = -2.60
			arm_r = 2.60
			fore_l = -1.85
			fore_r = 1.85
		STATE_HYPE:
			# Lighter or flag held high, bouncing on the spot.
			bob = absf(sin(t * 1.55)) * 0.17
			torso_x = -0.06
			torso_z = sin(t * 0.9) * 0.09
			head_x = -0.18 + sin(t * 2.6) * 0.04
			arm_r = 2.70 + sin(t * 2.0) * 0.10
			fore_r = 0.24
			arm_l = -0.34
			fore_l = -0.50
		_:
			# Neutral: the slow skank nod, arms loose, weight shifting side to side.
			bob = absf(sin(t)) * 0.026
			torso_x = 0.02 + sin(t * 1.1) * 0.02
			torso_z = sin(t * 0.7) * 0.06
			head_x = sin(t * 2.0) * 0.09
	m.node.position.y = m.base_y + bob
	m.torso.rotation = Vector3(torso_x, torso_y, torso_z)
	m.head.rotation = Vector3(head_x, sin(t * 0.6) * 0.10, head_z)
	m.arm_l.rotation.z = arm_l
	m.arm_r.rotation.z = arm_r
	m.fore_l.rotation.z = fore_l
	m.fore_r.rotation.z = fore_r
	if m.flag_cloth != null:
		# Cloth whips harder the more excited its owner is.
		var amp := 0.16 if m.state == STATE_IDLE else 0.34
		m.flag_cloth.rotation.y = sin(t * 2.1) * amp
		m.flag_cloth.rotation.z = sin(t * 1.7 + 0.5) * amp * 0.5
	if m.flame != null:
		var want := m.lit and m.state != STATE_IDLE
		m.flame.visible = want
		if want:
			var flick := 0.82 + sin(t * 9.0) * 0.16 + sin(t * 23.0) * 0.07
			m.flame.scale = Vector3(flick, flick * 1.22, flick)


# =========================================================================
# Palette and reporting
# =========================================================================
## The arena's phase palette: one shared material, so the whole crowd's rim changes together
## from warm afternoon gold to sunset amber to the night's cyan/magenta.
func set_palette(rim_a: Color, rim_b: Color, strength: float) -> void:
	if _body_material == null:
		return
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
	_body_material = ShaderMaterial.new()
	_body_material.shader = SILHOUETTE_SHADER
	_body_material.set_shader_parameter("body_colour", SKIN_SHADOW)
	_body_material.set_shader_parameter("rim_colour", Color(1.0, 0.74, 0.34))
	_body_material.set_shader_parameter("rim_strength", 0.85)
	_body_material.set_shader_parameter("rim_power", 2.6)
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


## Shared primitive cache: 20 bodies and their props reuse a handful of meshes, so the crowd
## adds almost nothing to the export and every draw is the same small vertex buffer.
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

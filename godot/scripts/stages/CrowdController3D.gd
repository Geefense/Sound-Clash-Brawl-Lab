class_name CrowdController3D
extends Node3D
## Reactive 3D crowd at the barrier (owner playtest, 2026-11-23; silhouettes removed 2026-11-24).
##
## Presentation only: this node reads no fighter state and never touches the combat
## simulation, hitboxes, frame data, audio or the round clock. `Arena3D.notify_combat_event()`
## forwards the arena's own cues (hit landed, heavy hit, knockdown, K.O., victory, DJ tag,
## Hype surge) here, and every spectator answers on its own delayed clock — one side first,
## the other after — so excitement ripples outward instead of the banks jumping in unison.
##
## Every spectator is a delivered Mixamo character from `assets/models/crowd/` wearing the
## same cel/ink treatment as the fighters. **There is no painted or procedural stand-in of
## any kind**: the 2.5D rim-lit quads and `SilhouetteArt` masks are gone, deleted from the
## project along with the `CrowdLine` sprite layer. If a model slot cannot be filled the
## position stays empty and a warning is logged — an empty slot, never a substitute body.
##
## The yard holds four people a side instead of ten because every body is now a real
## ~3 500-triangle rig rather than two triangles; that is what keeps the whole cast inside
## the Chromebook triangle budget with all of them fully textured.
##
## Excitement is expressed through acting and timing only — which Mixamo act is crossfaded
## in, the per-person phase offset, and a small beat bobbing on the anchor. Nothing here
## tints, dims or desaturates a character: every one of them renders its full albedo.

## Four a side across one ringside row, matching the delivered model count.
const COUNT := 8
const MODEL_TINTS := [Color(1.0, 0.99, 0.94), Color(0.92, 0.97, 1.06)]
const MODEL_RIMS := [Color(1.0, 0.82, 0.42), Color(0.70, 0.86, 1.0)]
## The delivered crowd takes share one Mixamo character skin, so each body gets its own small
## tint/hue break-up through the toon shader. Presentation only.
const MODEL_LOOKS := [
	Color(1.0, 1.0, 1.0),
	Color(1.03, 0.97, 0.93),
	Color(0.94, 0.99, 1.05),
	Color(1.04, 0.95, 0.99),
]
## Hue break-up is *not* used any more: it recolours a character's albedo, and the brief is
## that every crowd body shows the texture it was delivered with. The four looks above are
## sub-percent brightness nudges that read as lighting, not as a repaint.
const MODEL_HUES := [0.0, 0.0, 0.0, 0.0]
const ZONE_LEFT := 0
const ZONE_RIGHT := 1
const ROW_Z := [-5.20]
const ROW_COUNTS := [4]                    # per zone, per row: four a side
const BANK_X := [Vector2(-6.15, -2.35), Vector2(2.35, 6.15)]

## Staggering. A body's reaction delay is how far out along the bank it stands plus a small
## seeded jitter, so no two people ever land on the same tick.
const LATERAL_DELAY := 0.028
const JITTER := 0.04
const REACT_HOLD := 2.4
## Beat bob: an anchor rise of at most 2.5 cm. Small on purpose — the character's own clip
## carries the dancing; this only stops four rigs from ticking in perfect lockstep.
const BOB := 0.025

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
	var model: Node3D = null               # imported .fbx character (always present)
	var player: AnimationPlayer = null     # the character's own Mixamo AnimationPlayer
	var clips: Dictionary = {}             # {base, cheer, disbelief, hype, player}
	var act: StringName = &""              # act currently crossfaded in
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
var _cel_materials: Array[ShaderMaterial] = []
var _mesh_cache: Dictionary = {}
var _prop_material: StandardMaterial3D
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
				# Even spread across the bank with a little seeded jitter, so the row reads
				# as a packed yard rather than a grid.
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
	m.delay = absf(x) * LATERAL_DELAY + _rng.randf_range(0.0, JITTER)
	m.height = _rng.randf_range(1.55, 1.90)

	var anchor := Node3D.new()
	anchor.name = "Spectator%02d" % index
	anchor.position = Vector3(x, 0.0, ROW_Z[row])
	# Everyone turns slightly towards the centre of the yard, where the fight is.
	anchor.rotation.y = _rng.randf_range(-0.16, 0.16)
	add_child(anchor)

	m.node = anchor
	m.base_y = 0.0
	return m


## Three flags, four lighters, two airhorn operators — chosen by position so the props sit in
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

	var flag_indices := [1, 5]
	var lighter_indices := [2, 3, 6, 7]
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


## Any `.fbx`/`.glb` character delivered into `assets/models/crowd/` fills a spectator, in
## sorted filename order. A slot with no file stays empty and warns; there is no substitute
## body of any kind behind it.
func _load_models() -> void:
	var paths := CharacterModelSlots.model_paths(CharacterModelSlots.CROWD_DIR)
	if paths.is_empty():
		push_warning("CrowdController3D: no character in %s — leaving %d empty slots"
			% [CharacterModelSlots.CROWD_DIR, _members.size()])
		return
	var slot := 0
	for m in _members:
		var model := CharacterModelSlots.spawn_one(m.node, paths[slot % paths.size()], m.height)
		slot += 1
		if model == null:
			push_warning("CrowdController3D: %s failed to instance — empty slot" % m.node.name)
			continue
		var look := (slot - 1) % MODEL_LOOKS.size()
		var applied := CharacterModelSlots.apply_cel(model, MODEL_TINTS[m.zone] * MODEL_LOOKS[look],
			MODEL_RIMS[m.zone], m.zone * MODEL_LOOKS.size() + look, MODEL_HUES[look])
		if applied == 0:
			push_warning("CrowdController3D: %s has no textured surface — empty slot"
				% m.node.name)
			m.node.remove_child(model)
			model.queue_free()
			continue
		# Every spectator logs its model, material count and bound albedo; a null binding
		# is a broken slot, so the body is dropped instead of shown untextured.
		if CharacterModelSlots.report_albedo("crowd", model) > 0:
			push_warning("CrowdController3D: %s has an unbound albedo — empty slot"
				% m.node.name)
			m.node.remove_child(model)
			model.queue_free()
			continue
		CharacterModelSlots.collect_cel_materials(model, _cel_materials)
		m.clips = CharacterModelSlots.install_act_clips(model)
		m.player = m.clips.get("player") as AnimationPlayer
		if m.player != null:
			m.player.speed_scale = m.rate
		m.act = &""
		m.model = model
		_models.append(model)
		_attach_hand_props(m)
		_play_model_act(m, m.state)


## Flags, lighters and airhorns ride the character's right hand through a
## BoneAttachment3D (the same hand-parenting the fighters use for their mics), so a prop
## lifts with the real clip instead of hovering beside a standing body.
func _attach_hand_props(m: Member) -> void:
	var skeleton: Skeleton3D = null
	for child in m.model.find_children("*", "Skeleton3D", true, false):
		skeleton = child as Skeleton3D
		break
	if skeleton == null:
		return
	# Some uploads keep an exporter tag on the bone names (`mixamorig8_RightHand`), so the
	# hand is found by suffix instead of by one exact spelling.
	var hand_bone := ""
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		if bone_name.ends_with("RightHand"):
			hand_bone = bone_name
			break
	if hand_bone == "":
		return
	var props: Array[Node3D] = []
	if m.flag != null:
		props.append(m.flag)
	if m.horn != null:
		props.append(m.horn)
	if m.flame != null and m.flame.get_parent() is Node3D:
		props.append(m.flame.get_parent() as Node3D)
	for i in props.size():
		var attachment := BoneAttachment3D.new()
		attachment.name = "HandProp%d" % i
		attachment.bone_name = hand_bone
		skeleton.add_child(attachment)
		props[i].reparent(attachment, false)
		props[i].transform = Transform3D.IDENTITY


## Crossfade a delivered character to the act its state calls for. A clip that has not
## been delivered falls back to the character's own loop inside `CharacterModelSlots`.
func _play_model_act(m: Member, state: StringName) -> void:
	if m.model == null or m.player == null or m.clips.is_empty():
		return
	var act: StringName = CharacterModelSlots.ACT_NEUTRAL
	match state:
		STATE_CHEER:
			act = CharacterModelSlots.ACT_CHEER
		STATE_DISBELIEF:
			act = CharacterModelSlots.ACT_DISBELIEF
		STATE_HYPE:
			act = CharacterModelSlots.ACT_HYPE
	if act == m.act:
		return
	m.act = act
	CharacterModelSlots.play_act(m.model, m.clips, act, CharacterModelSlots.ACT_FADE)


func _add_flag(m: Member, colour: int) -> Node3D:
	var pole := Node3D.new()
	pole.name = "FlagPole"
	pole.position = Vector3(0.30, 0.0, 0.10)
	m.node.add_child(pole)
	_add_mesh(pole, "Pole", _cylinder(0.012, 0.012, 0.95, 4),
		Vector3(0.0, 0.52, 0.0), _prop_material)
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
		Vector3.ZERO, _prop_material)
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
		Vector3(0.0, 0.06, 0.0), _prop_material)
	_add_mesh(horn, "HornBell", _cylinder(0.105, 0.048, 0.12, 6),
		Vector3(0.0, 0.21, 0.0), _prop_material)
	_add_mesh(horn, "HornCan", _cylinder(0.045, 0.045, 0.10, 6),
		Vector3(0.075, -0.02, 0.0), _prop_material)
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
				_play_model_act(m, m.state)
		elif m.hold > 0.0:
			m.hold -= delta
			if m.hold <= 0.0:
				m.state = STATE_IDLE
				m.horn_up = false
				if m.lighter:
					m.lit = false
				_play_model_act(m, m.state)
		m.phase = fposmod(m.phase + m.rate * delta, TAU)
		_pose_member(m)


## Back to neutral: a fresh round must never open on a stale celebration.
func settle() -> void:
	for m in _members:
		m.state = STATE_IDLE
		m.pending = &""
		m.timer = 0.0
		m.hold = 0.0
		m.lit = false
		m.horn_up = false
		m.act = &""
		if m.flame != null:
			m.flame.visible = false
		if m.node != null:
			m.node.position.y = m.base_y
		_play_model_act(m, STATE_IDLE)


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
## One spectator's presentation frame. The *state* picks which clip act is crossfaded in;
## the person's own phase drives a small beat bob and the props, so the bank never marches
## in step. The body itself carries no tint, hop or lean of its own.
func _pose_member(m: Member) -> void:
	if m.node == null:
		return
	var t := m.phase
	var hop := 0.0
	match m.state:
		STATE_CHEER:
			hop = absf(sin(t * 1.9)) * BOB
		STATE_DISBELIEF:
			hop = absf(sin(t * 2.4)) * BOB * 0.5
		STATE_HYPE:
			hop = absf(sin(t * 1.55)) * BOB * 1.4
		_:
			hop = absf(sin(t)) * BOB
	m.node.position.y = m.base_y + hop
	if m.flag_cloth != null:
		# Cloth whips harder the more excited its owner is.
		var amp := 0.16 if m.state == STATE_IDLE else 0.36
		m.flag_cloth.rotation.y = sin(t * 2.1) * amp
		m.flag_cloth.rotation.z = sin(t * 1.7 + 0.5) * amp * 0.5
	if m.horn != null:
		if not (m.horn.get_parent() is BoneAttachment3D):
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
## The arena's phase palette: the rim highlight every character shares follows the light rig
## from warm afternoon gold to sunset amber to the night's cyan. Rim only — no albedo, tint
## or dimming is touched, so the delivered texture stays at full brightness all night.
func set_palette(rim_a: Color, rim_b: Color, strength: float) -> void:
	var rim := rim_a.lerp(rim_b, 0.5)
	for material in _cel_materials:
		material.set_shader_parameter("rim_colour", rim)
		material.set_shader_parameter("rim_strength", clampf(strength * 0.72, 0.15, 2.4))


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
# Characters
# =========================================================================
## Imported `.fbx`/`.glb` characters standing in the yard — one per spectator.
func model_slots() -> Array[Node3D]:
	return _models


## Spectators currently played by a real Mixamo character. Must equal `count()`: the crowd has
## no other kind of body.
func animated_model_count() -> int:
	var n := 0
	for m in _members:
		if m.player != null and m.model != null:
			n += 1
	return n


## Spectators left with nothing to show. Expected to be zero with the delivered models in
## place; a non-zero value means a slot is empty, never that a stand-in was drawn.
func empty_slot_count() -> int:
	return _members.size() - _models.size()


## Props currently riding a real character's `mixamorig_RightHand`.
func hand_attached_props() -> int:
	var n := 0
	for m in _members:
		if m.model != null:
			n += m.model.find_children("HandProp*", "BoneAttachment3D", true, false).size()
	return n


func model_act_of(index: int) -> StringName:
	if index < 0 or index >= _members.size():
		return &""
	return _members[index].act


func model_clip_of(index: int) -> String:
	if index < 0 or index >= _members.size():
		return ""
	var player := _members[index].player
	return player.current_animation if player != null else ""


## Leftover capsule-mannequin geometry. Must stay at zero: the silhouettes and the lathed
## capsule bodies they replaced are both gone, so only delivered characters may be present.
func legacy_mannequin_count() -> int:
	var n := 0
	for legacy in ["LegL", "LegR", "Chest", "Skull", "Hips"]:
		n += find_children(legacy, "MeshInstance3D", true, false).size()
	return n


## Real triangle cost of the built crowd, measured from the actual meshes. Props count; the
## characters are the overwhelming majority of it now that they are real rigs.
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
## Props only: the flag poles, lighter cases and airhorns are real objects, so they get a
## plain matte plastic material rather than borrowing a character's cel material.
func _build_materials() -> void:
	_prop_material = StandardMaterial3D.new()
	_prop_material.albedo_color = Color(0.16, 0.15, 0.17, 1.0)
	_prop_material.roughness = 0.72
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

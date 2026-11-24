class_name DJBooth3D
extends Node3D
## Active Sound-System DJ booth behind the decks (owner playtest, 2026-11-23; procedural deck
## removed 2026-11-24).
##
## Two DJs work a turntable rig between the mid-ground speaker stacks. Presentation only: this
## node never touches the combat simulation, hitboxes, frame data, the beat clock or the audio
## engine — it only poses the two characters to the cues `Arena3D.notify_combat_event()`
## already receives.
##
## **Nothing here is built from primitives.** The deck, platters, records, mixer, faders, knobs,
## monitors, gantry sign and the selector's airhorn were all `BoxMesh`/`CylinderMesh` geometry
## and are deleted with the rest of the programmer art (playtest fix 2026-11-24, issue 3). The
## booth is one `PropLoader` slot for `res://assets/models/props/dj_booth.glb`; until that file
## exists the slot stays empty and warns once. The DJs themselves are delivered Mixamo
## characters and are unaffected.
##
## The men still nod, point, celebrate and raise the selector's hand on a tag — those are clip
## acts and states, not props — so the booth reads even while the deck model is missing.

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
const BOOTH_MODEL := "res://assets/models/props/dj_booth.glb"
const DJ_HEIGHT := 1.62


class DJ:
	var node: Node3D
	var model: Node3D = null
	var player: AnimationPlayer = null
	var clips: Dictionary = {}
	var act: StringName = &""
	var base_y: float = 0.0
	var phase: float = 0.0
	var rate: float = 1.0
	var state: StringName = STATE_IDLE
	var hold: float = 0.0
	var point_dir: float = 1.0
	var nod: float = 0.0


var _djs: Array[DJ] = []
## Every cel material on the two DJs, so the phase palette can move their rim highlight
## without touching albedo. Populated once at build time.
var _cel_materials: Array[ShaderMaterial] = []
var deck: PropLoader = null
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if _djs.is_empty():
		build()


func build() -> void:
	if not _djs.is_empty():
		return
	_rng.seed = 20261122
	_build_booth_slot()
	_make_dj(0, -0.62)
	_make_dj(1, 0.62)
	_load_models()


## One empty slot for the delivered deck. No plinth, no platters, no sign: nothing is drawn
## until the model exists.
func _build_booth_slot() -> void:
	deck = PropLoader.new()
	deck.name = "PropLoader"
	deck.model_path = BOOTH_MODEL
	deck.required = true
	add_child(deck)


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
			_raise(kind, 1.8)
			# The other selector answers the knockdown with disbelief, not a cheer.
			if _djs.size() > 1:
				_djs[1].state = STATE_DISBELIEF
				_djs[1].hold = 1.4
		&"ko":
			_celebrate(3.0)
		&"victory":
			_celebrate(4.0)
		&"tag":
			# A DJ tag is the booth's own moment: selector's arm up, the other keeps the mix.
			_raise(kind, 1.6)
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
	for dj in _djs:
		if dj.hold > 0.0:
			dj.hold -= delta
			if dj.hold <= 0.0:
				dj.state = STATE_IDLE
				_play_model_act(dj, dj.state)
		if dj.nod > 0.0:
			dj.nod = maxf(0.0, dj.nod - delta * 2.2)
		dj.phase = fposmod(dj.phase + dj.rate * delta, TAU)
		_pose_dj(dj, delta)


## Back to neutral: a fresh round must never open on last round's celebration.
func settle() -> void:
	for dj in _djs:
		dj.state = STATE_IDLE
		dj.hold = 0.0
		dj.nod = 0.0
		dj.act = &""
		if dj.node != null:
			dj.node.position.y = dj.base_y
		_play_model_act(dj, STATE_IDLE)


# =========================================================================
# Reporting (headless checks)
# =========================================================================
func dj_count() -> int:
	return _djs.size()


func state_of(index: int) -> StringName:
	if index < 0 or index >= _djs.size():
		return &""
	return _djs[index].state


## True while the selector's arm is up (a knockdown, K.O. or DJ tag). This is a clip state,
## not a prop: the horn itself is deleted with the rest of the procedural art.
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


func pointing() -> bool:
	for dj in _djs:
		if dj.state == STATE_POINT:
			return true
	return false


## DJ slots with no delivered character. Expected to be zero; a non-zero value means the
## booth is short a person, never that a stand-in was drawn.
func empty_slot_count() -> int:
	var n := 0
	for dj in _djs:
		if dj.model == null:
			n += 1
	return n


## True once the deck model is actually in the tree.
func deck_loaded() -> bool:
	return deck != null and not deck.is_empty()


func deck_path() -> String:
	return BOOTH_MODEL


## Imported `.fbx`/`.glb` DJ characters, one per slot.
func model_slots() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for dj in _djs:
		if dj.model != null:
			found.append(dj.model)
	return found


## Spectators currently played by a real Mixamo character.
func animated_model_count() -> int:
	var n := 0
	for dj in _djs:
		if dj.player != null and dj.model != null:
			n += 1
	return n


## Leftover capsule-mannequin geometry. Must stay at zero.
func legacy_mannequin_count() -> int:
	var n := 0
	for legacy in ["LegL", "LegR", "Chest", "Skull", "Torso", "ArmL", "ArmR"]:
		n += find_children(legacy, "MeshInstance3D", true, false).size()
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


## Props riding a delivered model's `mixamorig_RightHand`. The booth's own airhorn is gone, so
## this is zero until an artist parents something there.
func hand_attached_props() -> int:
	var n := 0
	for dj in _djs:
		if dj.model != null:
			n += dj.model.find_children("HandProp*", "BoneAttachment3D", true, false).size()
	return n


func triangle_count() -> int:
	var total := 0
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			total += int(mi.mesh.get_faces().size() / 3)
	return total


## Rim highlight only — never albedo, tint or dimming, so a DJ's delivered texture stays at
## full brightness through every phase of the night.
func set_palette(rim_a: Color, rim_b: Color, strength: float) -> void:
	var rim := rim_a.lerp(rim_b, 0.45)
	var boost := clampf(strength * 0.95, 0.2, 2.6)
	for material in _cel_materials:
		material.set_shader_parameter("rim_colour", rim)
		material.set_shader_parameter("rim_strength", boost)


# =========================================================================
# Acting
# =========================================================================
func _raise(_kind: StringName, hold: float) -> void:
	for i in _djs.size():
		var dj := _djs[i]
		# The selector (index 0) throws the arm up; the other man keeps pointing at the fight.
		if i == 0:
			dj.state = STATE_AIRHORN
			dj.hold = hold
		else:
			dj.state = STATE_POINT
			dj.point_dir = -1.0
			dj.hold = hold * 0.8


func _celebrate(hold: float) -> void:
	for dj in _djs:
		dj.state = STATE_CELEBRATE
		dj.hold = hold


## The acting frame: the state picks which clip act is crossfaded in and the DJ's own phase
## adds the nod. The body itself carries no tint, hop or lean of its own.
func _pose_dj(dj: DJ, _delta: float) -> void:
	if dj.node == null:
		return
	var t := dj.phase
	var bob := absf(sin(t * 1.6)) * 0.024 + dj.nod * 0.03
	if dj.model != null:
		# The Mixamo clip owns the body motion; a second procedural bob would double it.
		bob = 0.0
	dj.node.position.y = dj.base_y + bob


# =========================================================================
# Characters
# =========================================================================
func _make_dj(index: int, x: float) -> void:
	var dj := DJ.new()
	dj.phase = _rng.randf_range(0.0, TAU)
	dj.rate = _rng.randf_range(0.95, 1.15)

	var node := Node3D.new()
	node.name = "DJ%d" % (index + 1)
	node.position = Vector3(x, 0.0, -0.62)
	add_child(node)

	dj.node = node
	dj.base_y = 0.0
	_pose_dj(dj, 0.0)
	_djs.append(dj)


## Any `.fbx`/`.glb` in `assets/models/dj/` fills a DJ slot, in filename order.
func _load_models() -> void:
	var paths := CharacterModelSlots.model_paths(CharacterModelSlots.DJ_DIR)
	if paths.is_empty():
		push_warning("DJBooth3D: no character in %s — leaving %d empty slots"
			% [CharacterModelSlots.DJ_DIR, _djs.size()])
		return
	for i in _djs.size():
		var dj := _djs[i]
		var model := CharacterModelSlots.spawn_one(dj.node, paths[i % paths.size()], DJ_HEIGHT)
		if model == null:
			push_warning("DJBooth3D: %s failed to instance — empty slot" % dj.node.name)
			continue
		if CharacterModelSlots.apply_cel(model, DJ_TINT, DJ_RIM, 10 + i) == 0:
			push_warning("DJBooth3D: %s has no textured surface — empty slot" % dj.node.name)
			dj.node.remove_child(model)
			model.queue_free()
			continue
		if CharacterModelSlots.report_albedo("dj", model) > 0:
			push_warning("DJBooth3D: %s has an unbound albedo — empty slot" % dj.node.name)
			dj.node.remove_child(model)
			model.queue_free()
			continue
		CharacterModelSlots.collect_cel_materials(model, _cel_materials)
		dj.clips = CharacterModelSlots.install_act_clips(model)
		dj.player = dj.clips.get("player") as AnimationPlayer
		if dj.player != null:
			dj.player.speed_scale = dj.rate
		dj.act = &""
		dj.model = model
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


## BoneAttachment3D is the same hand-parenting the fighters use for their mics. Kept for the
## day a delivered deck needs a prop parented to a DJ's hand.
func _attach_to_hand(model: Node3D, prop: Node3D, node_name: String) -> BoneAttachment3D:
	var skeleton: Skeleton3D = null
	for child in model.find_children("*", "Skeleton3D", true, false):
		skeleton = child as Skeleton3D
		break
	if skeleton == null:
		return null
	var attachment := BoneAttachment3D.new()
	attachment.name = node_name
	attachment.bone_name = HAND_BONE
	skeleton.add_child(attachment)
	prop.reparent(attachment, false)
	prop.transform = Transform3D.IDENTITY
	return attachment

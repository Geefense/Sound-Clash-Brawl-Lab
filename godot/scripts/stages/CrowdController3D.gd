class_name CrowdController3D
extends Node3D
## Reactive 3D crowd at the barrier (owner playtest, 2026-11-23; silhouettes and procedural
## props removed 2026-11-24).
##
## Presentation only: this node reads no fighter state and never touches the combat
## simulation, hitboxes, frame data, audio or the round clock. `Arena3D.notify_combat_event()`
## forwards the arena's own cues (hit landed, heavy hit, knockdown, K.O., victory, DJ tag,
## Hype surge) here, and every spectator answers on its own delayed clock — one side first,
## the other after — so excitement ripples outward instead of the banks jumping in unison.
##
## Every spectator is a delivered Mixamo character from `assets/models/crowd/` wearing the
## same cel/ink treatment as the fighters. **Nothing here is a stand-in of any kind:** the
## 2.5D rim-lit quads, the `SilhouetteArt` masks and the procedural flags, lighters and
## airhorns are all deleted (playtest fix 2026-11-24, issues 2 and 3). If a model slot cannot
## be filled the position stays empty and a warning is logged — an empty slot, never a
## substitute body.
##
## The yard holds four people a side instead of ten because every body is a real
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
## Hue break-up is *not* used: it recolours a character's albedo, and the brief is that every
## crowd body shows the texture it was delivered with. These are sub-percent brightness
## nudges that read as lighting, not as a repaint.
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


class Member:
	var node: Node3D                       # anchor on the row
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


var _members: Array[Member] = []
var _models: Array[Node3D] = []
var _cel_materials: Array[ShaderMaterial] = []
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
		_play_model_act(m, m.state)


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


# =========================================================================
# Public API — reactions
# =========================================================================
## Cue from `Arena3D.notify_combat_event()`. `side` is the corner that scored (0 = left /
## P1, 1 = right / P2); −1 is a neutral roar that lifts both banks.
func react(kind: StringName, side: int = -1) -> void:
	_reactions += 1
	var winner_state := STATE_CHEER
	var rival_state := STATE_DISBELIEF
	var hold := REACT_HOLD
	match kind:
		&"hit":
			winner_state = STATE_CHEER
			rival_state = STATE_IDLE
			hold = 1.0
		&"heavy_hit":
			winner_state = STATE_CHEER
			rival_state = STATE_DISBELIEF
			hold = 2.2
		&"knockdown":
			winner_state = STATE_HYPE
			rival_state = STATE_DISBELIEF
			hold = 2.8
		&"ko":
			winner_state = STATE_HYPE
			rival_state = STATE_DISBELIEF
			hold = 4.0
		&"victory":
			winner_state = STATE_HYPE
			rival_state = STATE_DISBELIEF
			hold = 4.5
		&"tag":
			winner_state = STATE_CHEER
			rival_state = STATE_CHEER
			hold = 1.6
		&"hype":
			winner_state = STATE_HYPE
			rival_state = STATE_HYPE
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
		m.pending = want
		m.timer = m.delay + _rng.randf_range(0.0, JITTER)
		m.hold = 0.0


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
		m.act = &""
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
## the person's own phase drives a small beat bob, so the bank never marches in step. The
## body itself carries no tint, hop or lean of its own.
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


## Leftover capsule-mannequin geometry. Must stay at zero.
func legacy_mannequin_count() -> int:
	var n := 0
	for legacy in ["LegL", "LegR", "Chest", "Skull", "Hips"]:
		n += find_children(legacy, "MeshInstance3D", true, false).size()
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


## Real triangle cost of the built crowd, measured from the actual meshes.
func triangle_count() -> int:
	var total := 0
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			total += int(mi.mesh.get_faces().size() / 3)
	return total

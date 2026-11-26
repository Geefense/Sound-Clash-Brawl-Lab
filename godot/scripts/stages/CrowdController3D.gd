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
## **Packed yard (owner playtest, 2026-11-24 PART 2).** Three staggered depth rows a side —
## 4 front, 4 mid, 3 back — so 22 spectators fill both banks instead of a sparse single line
## of eight. Every slot cycles through **all seven delivered Mixamo characters** (3 male +
## 4 female), in sorted filename order, so the whole cast is on screen at once and no two
## neighbours share a model. Characters are fitted to their own height and stand on the
## row's depth tier — a per-row Y offset only, never a riser prop.
##
## Cost: each body is a real ~3 500-triangle rig, so 22 of them is ~75 000 triangles — still a
## trivial load for an Intel Chromebook GPU, and the geometry is shared (see
## `CharacterModelSlots.share_meshes()`), so the crowd costs seven meshes' worth of GPU
## memory, not twenty-two. Per-instance variety comes from one shader material each (bright,
## full albedo) plus its own tiny tint/hue nudge, which costs nothing.
##
## Excitement is expressed through acting and timing only — which Mixamo act is crossfaded
## in, the per-person phase offset, and a small beat bobbing on the anchor. Nothing here
## dims or desaturates a character: every one of them renders its full albedo.

const COUNT := 22
## Left bank warm, right bank cool, matching the stage light. Full brightness: these are
## multiplicative tint colours, and the darkest one is a 3 % nudge, never a dimmer.
const MODEL_TINTS := [Color(1.0, 0.99, 0.94), Color(0.97, 0.99, 1.03)]
const MODEL_RIMS := [Color(1.0, 0.82, 0.42), Color(0.70, 0.86, 1.0)]
const ZONE_LEFT := 0
const ZONE_RIGHT := 1
## Three depth rows behind the barrier (z −2.55): ringside, mid, back. The back rows are the
## ones that answer last, which is what makes a reaction ripple instead of snapping.
const ROW_Z := [-4.15, -5.05, -5.95]
const ROW_COUNTS := [4, 4, 3]              # per zone, per row
## Depth tiers as a plain per-row Y offset, never a prop: the back rows stand a little higher
## so their heads read over the front row from the stage camera. The barrier, the sands and
## the PropLoader contract are untouched, and no riser geometry is drawn.
const ROW_Y := [0.0, 0.20, 0.40]
## Row base delay plus a per-metre stagger: ringside answers first, the back row last.
const ROW_DELAY := [0.0, 0.11, 0.22]
## Half-width bands (mirrored by the zone sign). PART B commit 7: every row now holds the same
## 0.56 m shoulder step and each row's band is shifted by half a step relative to the one
## behind it, so the banks read as one natural cluster instead of three loose lines with a
## 0.91 m hole in the back row. The bands are also pulled inside the tighter stage camera: at
## the commit-5 distance the frame's half-width is 3.93 m at the ringside depth, and the
## outermost ringside body edge here is 3.67 m.
##
##   row 0 (z -4.15): centres 1.74 / 2.30 / 2.86 / 3.42
##   row 1 (z -5.05): centres 2.02 / 2.58 / 3.14 / 3.70   (half a step across)
##   row 2 (z -5.95): centres 2.30 / 2.86 / 3.42          (half a step across again)
const ROW_BANK_X := [Vector2(1.46, 3.70), Vector2(1.74, 3.98), Vector2(2.02, 3.70)]
## Seeded lateral jitter, a few centimetres: enough to break the grid, far too little to open a
## gap or close two shoulders. (Worst case: 0.56 - 0.04 = 0.52 m apart, still clear of the
## 0.50 m body box; widest gap 0.56 + 0.04 = 0.60 m.)
const ROW_JITTER := 0.02
## Strength of the luminance-preserving palette mix the bank wears. Capped at 0.25 by the
## brief, and by `apply_cel_shared()` too; the fighters never set it (0.0).
const CROWD_TINT := 0.22

## Staggering. A body's reaction delay is how far out along the bank it stands plus a small
## seeded jitter, so no two people ever land on the same tick.
const LATERAL_DELAY := 0.028
const JITTER := 0.04
const REACT_HOLD := 2.4
## Beat bob: an anchor rise of at most 2.5 cm. Small on purpose — the character's own clip
## carries the dancing; this only stops four rigs from ticking in perfect lockstep.
const BOB := 0.025

## --- Bug 4 (2026-11-25): scale, spacing, palette and 132 BPM motion ----------------------
## (a) Every rig stands within ±8 % of the fighter's own 1.55 m, so the yard reads as a crowd
## of adults beside the fighters instead of a bank of giants or children.
const FIGHTER_HEIGHT := 1.55
const HEIGHT_MIN := 0.92
const HEIGHT_MAX := 1.08
## (b) Minimum anchor-to-anchor spacing inside a row. Each slot's jitter is derived from its
## row's own spacing, so no pair can ever close under this and clip. The footprint is the
## audit's body box: a 0.50 m shoulder line and a 0.34 m chest depth.
const MIN_SPACING := 0.50
const BODY_HALF_WIDTH := 0.25
const BODY_HALF_DEPTH := 0.17
## (c) Dancehall palette — green, gold, red, black plus neon accents. Each rig takes one entry
## and wears it through the cel shader's per-instance accent (rim/emission only), so one
## shared material dresses the whole bank and no delivered albedo is ever dimmed.
const PALETTE := [
	{"name": "green", "accent": Color(0.10, 0.86, 0.36, 1.0)},
	{"name": "gold", "accent": Color(1.0, 0.82, 0.12, 1.0)},
	{"name": "red", "accent": Color(1.0, 0.16, 0.22, 1.0)},
	{"name": "black", "accent": Color(0.20, 0.20, 0.24, 1.0)},
	{"name": "neon_cyan", "accent": Color(0.10, 0.95, 1.0, 1.0)},
	{"name": "neon_magenta", "accent": Color(1.0, 0.16, 0.72, 1.0)},
	{"name": "neon_lime", "accent": Color(0.70, 1.0, 0.16, 1.0)},
]
## (d) 132 BPM skank: one bounce per beat with a half-beat hip sway, each rig offset inside
## the bar so the bank ripples instead of marching. Scalar math on the cached anchor only.
const BPM := 132.0
const BEAT_SEC := 60.0 / BPM
const SKANK_RISE := 0.055
const SKANK_SWAY := 0.045

## --- Commit 5: the sound-clash eruption ----------------------------------------------------
## A whole-yard eruption rides the energy the arena passes in. Full energy holds for
## `ERUPT_PEAK_SECONDS`, then settles over the rest of `ERUPT_SECONDS`; the jump itself is
## locked to the same 132 BPM clock as the skank (`BEAT_SEC`), so the yard never erupts off the
## music. The row tiers keep their existing delays, so the wave ripples from ringside back.
const ERUPT_SECONDS := 3.2
const ERUPT_PEAK_SECONDS := 0.9
const ERUPT_JUMP := 0.09
const ERUPT_SWAY := 0.5

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
	var z: float = 0.0
	var base_yaw: float = 0.0
	var beat_offset: float = 0.0
	var phase: float = 0.0
	var rate: float = 1.0
	var delay: float = 0.0
	var state: StringName = STATE_IDLE
	var pending: StringName = &""
	var timer: float = 0.0
	var hold: float = 0.0
	var accent: Color = Color.WHITE # per-instance palette accent (rim/emission only)
	var palette_name: String = ""   # which dancehall palette entry this rig wears
	var model_path: String = ""     # which of the seven delivered characters this is


var _members: Array[Member] = []
var _models: Array[Node3D] = []
var _cel_materials: Array[ShaderMaterial] = []
var _time: float = 0.0
var _reactions: int = 0
## Eruption state (PART 2, commit 5). Scalar only: `_eruption` is the 0–1 energy the arena
## passed in (read from the hype meters, never written back), `_eruption_age` runs the peak
## then the settle, and nothing here creates a node or a light.
var _eruption: float = 0.0
var _eruption_age: float = 0.0
var _eruption_live: bool = false
var _eruptions: int = 0
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
				# Even spread across the row's band at the row's own step, so the bank reads
				# as a packed yard rather than a grid. Left and right mirror each other.
				var t := (float(i) + 0.5) / float(count)
				var band: Vector2 = ROW_BANK_X[row]
				var side := -1.0 if zone == ZONE_LEFT else 1.0
				var x := lerpf(band.x, band.y, t) * side + _rng.randf_range(-ROW_JITTER, ROW_JITTER)
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
	# Row base + distance along the bank + jitter: near people first, back rows last.
	m.delay = ROW_DELAY[row] + absf(x) * LATERAL_DELAY + _rng.randf_range(0.0, JITTER)
	# (a) Scale: every rig is fitted inside a ±8 % band around the fighter's own height.
	m.height = _rng.randf_range(FIGHTER_HEIGHT * HEIGHT_MIN, FIGHTER_HEIGHT * HEIGHT_MAX)
	# (c) Look: one dancehall palette entry per rig, worn through the shared material's
	# per-instance accent. Deterministic by slot, so the two banks mirror each other's mix.
	var entry: Dictionary = PALETTE[index % PALETTE.size()]
	m.accent = entry["accent"]
	m.palette_name = String(entry["name"])
	# (d) Motion: a per-rig offset inside the 132 BPM bar, so no two people land together.
	m.beat_offset = _rng.randf_range(0.0, 1.0)

	var anchor := Node3D.new()
	anchor.name = "Spectator%02d" % index
	# A little depth jitter inside the row keeps the line from looking like a shelf; the row's
	# own Y offset is the depth tier, so the back rows read over the front row. The jitter is
	# kept well under the body's chest depth, so rows can never clip into each other.
	var z: float = float(ROW_Z[row]) + _rng.randf_range(-0.14, 0.14)
	m.z = z
	anchor.position = Vector3(x, ROW_Y[row], z)
	# Everyone turns slightly towards the centre of the yard, where the fight is.
	var inward := 14.0 if zone == ZONE_LEFT else -14.0
	anchor.rotation.y = deg_to_rad(inward) + _rng.randf_range(-0.14, 0.14)
	add_child(anchor)

	m.node = anchor
	m.base_y = ROW_Y[row]
	m.base_yaw = anchor.rotation.y
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
		var path: String = paths[slot % paths.size()]
		var model := CharacterModelSlots.spawn_one(m.node, path, m.height)
		slot += 1
		if model == null:
			push_warning("CrowdController3D: %s failed to instance — empty slot" % m.node.name)
			continue
		m.model_path = path.get_file()
		# Bug 4c: the bank SHARES one cel material per delivered atlas and takes its own
		# palette from the per-instance accent uniform — no new material per rig.
		# PART B commit 7: the palette is a luminance-preserving mix (`CROWD_TINT`), applied
		# on top of the delivered albedo rather than multiplied into it.
		var applied := CharacterModelSlots.apply_cel_shared(model, path, MODEL_RIMS[m.zone],
			m.accent, CharacterModelSlots.RIM_STRENGTH, 0.9, CROWD_TINT)
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
	if _eruption_live:
		_eruption_age += delta
		if _eruption_age > ERUPT_PEAK_SECONDS:
			_eruption = maxf(0.0, _eruption - delta / (ERUPT_SECONDS - ERUPT_PEAK_SECONDS))
		if _eruption <= 0.0:
			_eruption = 0.0
			_eruption_live = false
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


## Sound-clash eruption (commit 5): all 22 spectators take the hype act on the row-tier delays
## they already carry, and the beat-locked jump is scaled by `energy` — the arena's read-only
## hype reading, 0–1. Called by `Arena3D.notify_combat_event()`; nothing about Crowd Hype,
## the meters or the combat rules changes here.
func erupt(energy: float = 1.0, whole_yard_act: bool = true) -> void:
	var e := clampf(energy, 0.0, 1.0)
	_eruption = maxf(_eruption, e)
	_eruption_age = 0.0
	_eruption_live = true
	_eruptions += 1
	# The jump and the sway are yard-wide, but the ACT is only overwritten when the cue really
	# is a whole-yard moment (a Hype surge, a special). On a side-specific cue — a heavy hit, a
	# knockdown, a K.O. — `react(kind, side)` has already given the winner's bank its cheer and
	# the rival bank its disbelief, and that read must survive the eruption.
	if whole_yard_act:
		# Both banks, on the delays they already own (`ROW_DELAY` + lateral stagger + jitter),
		# so the wave goes ringside → mid → back instead of every rig snapping at once.
		react(&"hype", -1)


## Live eruption energy, 0–1. Zero once the settle has finished.
func eruption_energy() -> float:
	return _eruption


func eruption_active() -> bool:
	return _eruption_live


func eruption_count() -> int:
	return _eruptions


## The row-tier delay the wave uses, seconds. Strictly increasing with depth, which is what
## the headless check asserts.
func row_delay(row: int) -> float:
	return ROW_DELAY[clampi(row, 0, ROW_DELAY.size() - 1)]


## Highest anchor lift above its row tier right now. Bounded by `SKANK_RISE + BOB + ERUPT_JUMP`.
func max_lift() -> float:
	var best := 0.0
	for m in _members:
		if m.node != null:
			best = maxf(best, m.node.position.y - m.base_y)
	return best


## Back to neutral: a fresh round must never open on a stale celebration.
func settle() -> void:
	_eruption = 0.0
	_eruption_age = 0.0
	_eruption_live = false
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
## the person's own phase drives the reaction bob, and the yard-wide 132 BPM skank drives the
## bounce and hip sway under it (Bug 4d). All scalar math on the cached anchor: no nodes are
## created, no arrays are built, nothing is allocated per frame.
func _pose_member(m: Member) -> void:
	if m.node == null:
		return
	var beat := fposmod(_time / BEAT_SEC + m.beat_offset, 1.0)
	var hop := absf(sin(PI * beat)) * SKANK_RISE
	var sway := sin(TAU * beat) * SKANK_SWAY
	# Eruption ride: a beat-locked jump and a wider sway on top of whatever act is playing. The
	# arms and the hands-up read come from the delivered hype take, not from bone writes here,
	# so the eruption cannot fight the AnimationPlayer.
	if _eruption > 0.0:
		hop += _eruption * ERUPT_JUMP * absf(sin(PI * beat))
		sway *= 1.0 + _eruption * ERUPT_SWAY
	var t := m.phase
	match m.state:
		STATE_CHEER:
			hop += absf(sin(t * 1.9)) * BOB
		STATE_DISBELIEF:
			hop += absf(sin(t * 2.4)) * BOB * 0.5
		STATE_HYPE:
			hop += absf(sin(t * 1.55)) * BOB * 1.4
		_:
			hop += absf(sin(t)) * BOB * 0.5
	m.node.position.y = m.base_y + hop
	m.node.rotation.y = m.base_yaw + sway


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


# =========================================================================
# Cost and coverage reporting (headless checks)
# =========================================================================
## Distinct Mesh resources actually referenced by the crowd. Twenty-two spectators cycling
## seven characters must reference about seven meshes' worth of geometry, not twenty-two:
## `CharacterModelSlots.share_meshes()` binds the cached mesh per node path.
func unique_mesh_count() -> int:
	var ids := {}
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			ids[mi.mesh.get_instance_id()] = true
	return ids.size()


## MeshInstance3D nodes in the built crowd. Paired with `unique_mesh_count()` this proves
## the geometry is shared: many nodes, few meshes.
func mesh_instance_count() -> int:
	return find_children("*", "MeshInstance3D", true, false).size()


## Model slots each spectator is actually playing — sorted, de-duplicated filenames.
func model_names() -> Array[String]:
	var names: Array[String] = []
	for m in _members:
		if m.model_path != "" and not names.has(m.model_path):
			names.append(m.model_path)
	names.sort()
	return names


func row_count(row: int) -> int:
	var n := 0
	for m in _members:
		if m.row == row:
			n += 1
	return n


func row_z(row: int) -> float:
	return ROW_Z[clampi(row, 0, ROW_Z.size() - 1)]


## The row's depth tier: a Y offset only, so no crowd riser prop exists to load or draw.
func row_y(row: int) -> float:
	return ROW_Y[clampi(row, 0, ROW_Y.size() - 1)]


## Depth spread of the built crowd, used to prove the rows are genuinely staggered.
func depth_span() -> float:
	return ROW_Z[0] - ROW_Z[ROW_Z.size() - 1]


# =========================================================================
# Bug 4 reporting (scale, spacing, palette, 132 BPM) — headless checks
# =========================================================================
## Measured world height of one rig, ignoring the anchor's yaw.
func world_height(index: int) -> float:
	if index < 0 or index >= _members.size():
		return 0.0
	return CharacterModelSlots.local_height(_members[index].model)


## Rig height as a fraction of the fighter's own height. Bug 4a keeps every one inside
## `HEIGHT_MIN`–`HEIGHT_MAX`.
func height_ratio(index: int) -> float:
	var h := world_height(index)
	return h / FIGHTER_HEIGHT if h > 0.0 else 0.0


## PART B commit 7 — measured rig width in world space, ignoring yaw: the shoulder line the
## spacing audit is written against.
func world_width(index: int) -> float:
	if index < 0 or index >= _members.size():
		return 0.0
	var model: Node3D = _members[index].model
	if model == null:
		return 0.0
	var to_local := model.global_transform.affine_inverse()
	var merged := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box: AABB = to_local * mi.global_transform * mi.get_aabb()
		merged = box if first else merged.merge(box)
		first = false
	if first:
		return 0.0
	return merged.size.x * absf(model.scale.x)


func mean_rig_width() -> float:
	var total := 0.0
	var counted := 0
	for i in _members.size():
		var w := world_width(i)
		if w > 0.0:
			total += w
			counted += 1
	return total / float(counted) if counted > 0 else 0.0


## Widest anchor-to-anchor gap inside any one row and bank. The cluster contract is that this
## never exceeds 1.25× the mean rig width, i.e. neighbours always read as one group.
func max_row_gap() -> float:
	var widest := 0.0
	for row in ROW_COUNTS.size():
		for zone in [ZONE_LEFT, ZONE_RIGHT]:
			var xs: Array[float] = []
			for m in _members:
				if m.row == row and m.zone == zone:
					xs.append(m.x)
			xs.sort()
			for i in range(1, xs.size()):
				widest = maxf(widest, xs[i] - xs[i - 1])
	return widest


## Innermost anchor of a row on the left bank, used to prove the half-step stagger.
func row_first_center(row: int) -> float:
	var best := INF
	for m in _members:
		if m.row == row and m.zone == ZONE_LEFT:
			best = minf(best, absf(m.x))
	return 0.0 if best == INF else best


func member_position(index: int) -> Vector3:
	if index < 0 or index >= _members.size():
		return Vector3.ZERO
	return _members[index].node.global_position


## Farthest rig anchor from the yard centre line.
func max_abs_x() -> float:
	var widest := 0.0
	for m in _members:
		widest = maxf(widest, absf(m.x))
	return widest


## The palette mix the bank wears, read back from the shared cel material.
func tint_strength() -> float:
	if _cel_materials.is_empty():
		return 0.0
	return float(_cel_materials[0].get_shader_parameter("crowd_tint_strength"))


## Worst luminance change the tint can make, measured over a sweep of delivered albedo tones.
## The shader rescales the palette to the texel's own luma before mixing, so this must stay at
## float noise — anything above 10 % would mean the tint is dimming textures again.
func palette_luma_error() -> float:
	var strength := tint_strength()
	if strength <= 0.0:
		return 0.0
	var weights := Vector3(0.2126, 0.7152, 0.0722)
	var samples := [Color(0.10, 0.10, 0.10), Color(0.35, 0.30, 0.26), Color(0.55, 0.42, 0.32),
		Color(0.80, 0.78, 0.74), Color(0.95, 0.93, 0.90), Color(0.20, 0.45, 0.30)]
	var worst := 0.0
	for entry in PALETTE:
		var accent: Color = entry["accent"]
		for base in samples:
			var luma: float = base.r * weights.x + base.g * weights.y + base.b * weights.z
			var tint_luma: float = maxf(accent.r * weights.x + accent.g * weights.y
				+ accent.b * weights.z, 0.001)
			var scale := luma / tint_luma
			var palette := Vector3(accent.r, accent.g, accent.b) * scale
			var mixed := Vector3(base.r, base.g, base.b).lerp(palette, strength)
			var mixed_luma: float = mixed.x * weights.x + mixed.y * weights.y + mixed.z * weights.z
			if luma > 0.01:
				worst = maxf(worst, absf(mixed_luma - luma) / luma)
	return worst


## Smallest anchor-to-anchor distance inside any one row and bank.
func min_row_spacing() -> float:
	var best := INF
	for row in ROW_COUNTS.size():
		for zone in [ZONE_LEFT, ZONE_RIGHT]:
			var xs: Array[float] = []
			for m in _members:
				if m.row == row and m.zone == zone:
					xs.append(m.x)
			xs.sort()
			for i in range(1, xs.size()):
				best = minf(best, xs[i] - xs[i - 1])
	return 0.0 if best == INF else best


## Rigs whose body boxes intersect in plan view. Bug 4b requires zero.
func overlap_count() -> int:
	var n := 0
	for i in _members.size():
		var a := _members[i]
		for j in range(i + 1, _members.size()):
			var b := _members[j]
			if absf(a.x - b.x) < BODY_HALF_WIDTH * 2.0 \
					and absf(a.z - b.z) < BODY_HALF_DEPTH * 2.0:
				n += 1
	return n


## Distinct cel materials in the bank. Twenty-two rigs must share a handful, never one each.
func shared_material_count() -> int:
	var ids := {}
	for node in find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var material := mi.get_surface_override_material(surface)
			if material != null:
				ids[material.get_instance_id()] = true
	return ids.size()


func accent_of(index: int) -> Color:
	if index < 0 or index >= _members.size():
		return Color.BLACK
	return _members[index].accent


func palette_name_of(index: int) -> String:
	if index < 0 or index >= _members.size():
		return ""
	return _members[index].palette_name


func palette_names() -> Array[String]:
	var names: Array[String] = []
	for entry in PALETTE:
		names.append(String(entry["name"]))
	return names


## Where this rig sits inside the 132 BPM bar, 0.0–1.0. One beat later reads the same value.
func beat_phase_of(index: int) -> float:
	if index < 0 or index >= _members.size():
		return 0.0
	return fposmod(_time / BEAT_SEC + _members[index].beat_offset, 1.0)


## Live Node count of the built crowd. The 600-frame stability check compares this before and
## after, so a pose path that starts creating nodes is caught.
func node_count() -> int:
	return find_children("*", "Node", true, false).size()


func member_count() -> int:
	return _members.size()

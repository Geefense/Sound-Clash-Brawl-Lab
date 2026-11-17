class_name CrowdLine
extends Node2D
## Two-row, rotating Dancehall crowd (AGENTS.md §9). Presentation only: it never touches
## the simulation, the hitboxes or either fighter's FSM.
##
## Fifteen characters live in this node (one Sprite2D each, placed in TestArena.tscn). At any
## time five stand on the Front Rope Row (scale 1.0, crisp) and six on the Back Crowd Row
## (scale 0.85, tinted for depth); the rest wait off-stage in the pool. Every 12–18 s, and
## whenever a fighter reaches 50 % or 100 % Crowd Hype, one or two people fade out and are
## replaced by pooled characters, so the crowd keeps reshuffling.
##
## The Dancehall Queen ("Queen") is pinned to the centre front slot and never swapped out.
## Each member gets a grounded contact shadow from the shared GroundShadow script.
##
## Crowd acting (owner playtest, 2026-11-17). The line no longer bounces in unison on the beat:
## every member is cast into an *act* — flag-holder waves, rag-holder waves, horn-holder raises
## and blows, skankers skank, dancers dance, everyone else cheers — and runs it on its own phase
## and rate, so fifteen people never move together. The acts are whole-sprite motion
## (lift / tilt / squash) because the current art is one frozen drawing per character; real
## waving and horn-blowing need multi-frame sprite sheets (see the art TODO in §9 item 23).

signal crowd_rotated(moved: int)

const FRONT_ROW_Y := 556.0
const BACK_ROW_Y := 516.0
const FRONT_SLOTS := [340.0, 470.0, 640.0, 810.0, 940.0]
const BACK_SLOTS := [300.0, 428.0, 556.0, 724.0, 852.0, 980.0]
const PINNED_NAME := "Queen"
const PINNED_SLOT := 2
## Owner direction (2026-11-17): the arms-crossed man's only drawing is a lean, and there is
## nothing at the crowd line for him to lean on — bouncing that pose read as a mistake. He is
## retired from the line until a standing pose is drawn; the sprite, its texture and the scene
## node stay in the repo so no art is lost.
const RETIRED_NAMES := ["ArmsCrossed"]

## Acts. A member's act decides which motion it performs and how fast.
const ACT_FLAG := &"flag"
const ACT_RAG := &"rag"
const ACT_HORN := &"horn"
const ACT_SKANK := &"skank"
const ACT_DANCE := &"dance"
const ACT_CHEER := &"cheer"
const ACT_FOR := {
	"FlagWaver": ACT_FLAG,
	"TowelWaver": ACT_RAG,
	"AirhornHypeman": ACT_HORN,
	"FloralSkanker": ACT_SKANK,
	"RastaElder": ACT_SKANK,
	"CapElder": ACT_SKANK,
	"CheerWoman": ACT_CHEER,
	"HeadscarfClapper": ACT_CHEER,
	"HypeWoman": ACT_CHEER,
	"CupYouth": ACT_CHEER,
	"Queen": ACT_DANCE,
	"ManeQueen": ACT_DANCE,
	"Hypeman": ACT_DANCE,
	"Elder": ACT_DANCE,
}
## Cycles per second per act (Hz): cloth works slowly, skankers are the fastest in the yard.
const ACT_RATE_HZ := {
	ACT_FLAG: Vector2(0.30, 0.44),
	ACT_RAG: Vector2(0.36, 0.52),
	ACT_HORN: Vector2(0.20, 0.28),
	ACT_SKANK: Vector2(0.75, 1.05),
	ACT_DANCE: Vector2(0.58, 0.90),
	ACT_CHEER: Vector2(0.48, 0.78),
}
const ACCENT_DECAY := 4.5               # how fast a beat accent settles (per second)
## Night: the crowd drops towards silhouette so the lit fighters stay the subject.
const NIGHT_SILHOUETTE := Color(0.20, 0.24, 0.42)

@export var surge_hop_pixels: float = 18.0    # surge jubilation
@export var surge_hop_interval: float = 0.16  # ~6 hops/s spread across the line
@export var back_scale_mult: float = 0.85
@export var back_shade: Color = Color(0.80, 0.84, 0.94)
@export var rotate_min_seconds: float = 12.0
## Longest side of each crowd sprite's original art (AGENTS.md §9 item 17). The .import
## cap decodes the art smaller than the pixels the scene's scale/offset were authored
## for, so both are scaled back by (original side / decoded side).
const ART_MAX_SIDE := {
	"Queen": 824.0,
	"FlagWaver": 895.0,
	"Hypeman": 762.0,
	"CheerWoman": 949.0,
	"ArmsCrossed": 851.0,
	"Elder": 838.0,
	"CapElder": 875.0,
	"CupYouth": 878.0,
	"AirhornHypeman": 962.0,
	"HeadscarfClapper": 860.0,
	"ManeQueen": 1004.0,
	"TowelWaver": 963.0,
	"FloralSkanker": 839.0,
	"RastaElder": 963.0,
	"HypeWoman": 858.0,
}

@export var rotate_max_seconds: float = 18.0
@export var swap_min: int = 1
@export var swap_max: int = 2
@export var swap_seconds: float = 0.34

## Unsynchronised ambient life (AGENTS.md §9 item 21 / item 23). The beat accent below is
## scattered across the bar per member; these act cycles run on each member's own phase and
## rate so fifteen people never move as one chorus line — the Fatal Fury reference crowd is
## individual, not unison.
@export var sway_pixels: float = 2.6          # side-to-side drift at the shoulders, floor-level

## Proximity ebb (AGENTS.md §9 item 21, from the live-action yard-brawl clip): when a body
## dashes, is thrown or lands near the line, the spectators it passes flinch away from it and
## then close back in. Radius/shift are screen pixels of the stage.
@export var flinch_radius: float = 240.0

@export var flinch_shift: float = 9.0
@export var flinch_tilt_deg: float = 6.0
@export var flinch_seconds: float = 0.55


## One crowd member: its sprite, its contact shadow and its current slot.
class Member:
	var sprite: Sprite2D
	var shadow: GroundShadow
	var front_scale: Vector2 = Vector2.ONE
	var shadow_radius: float = 16.0
	var row: int = -1                       # 0 front, 1 back, -1 pooled (off-stage)
	var slot: int = -1
	var home: Vector2 = Vector2.ZERO
	var bounce: Tween
	var swap: Tween
	var swapping: bool = false
	var act: StringName = ACT_DANCE         # what this person actually does in the yard
	var phase: float = 0.0                  # own act phase (radians)
	var rate: float = 1.0                   # own act rate (radians/s)
	var beat_div: int = 2                   # answers every 1st/2nd/3rd beat of the bar
	var beat_offset: int = 0
	var accent: float = 0.0                 # 0–1 beat accent, decays over ~0.2 s
	var lean: float = 0.0                   # permanent body lean (radians); retired leaner only
	var flinch: float = 0.0                 # 0–1.4, decays over flinch_seconds
	var flinch_dir: float = 1.0             # −1 away to the left, +1 away to the right
	var retired: bool = false               # kept in the scene, never placed on the line


var beat: BeatService

var _members: Array[Member] = []
var _surge_left: float = 0.0
var _hop_timer: float = 0.0
var _hop_index: int = 0
var _rotate_timer: float = 0.0
var _night: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for child in get_children():
		var sprite := child as Sprite2D
		if sprite != null:
			_members.append(_make_member(sprite))
	_layout()
	_rotate_timer = _rng.randf_range(rotate_min_seconds, rotate_max_seconds)


func setup(service: BeatService) -> void:
	beat = service
	if beat != null and not beat.beat.is_connected(on_beat):
		beat.beat.connect(on_beat)


func _make_member(sprite: Sprite2D) -> Member:
	_compensate_import_cap(sprite)
	var m := Member.new()
	m.sprite = sprite
	m.front_scale = sprite.scale
	m.act = StringName(ACT_FOR.get(String(sprite.name), ACT_DANCE))
	m.phase = _rng.randf_range(0.0, TAU)   # seeded, so nobody starts on the same frame
	var hz: Vector2 = ACT_RATE_HZ.get(m.act, Vector2(0.5, 0.8))
	m.rate = _rng.randf_range(hz.x, hz.y) * TAU
	m.beat_div = _rng.randi_range(1, 3)
	m.beat_offset = _rng.randi_range(0, 2)
	m.retired = String(sprite.name) in RETIRED_NAMES
	var shadow := GroundShadow.new()
	shadow.name = "Shadow"
	shadow.squash = 0.30
	shadow.z_index = -2                 # every shadow sits under every body
	var width: float = sprite.texture.get_width() if sprite.texture != null else 64.0
	m.shadow_radius = clampf(width * sprite.scale.x * 0.42, 9.0, 24.0)
	shadow.radius = m.shadow_radius
	sprite.add_child(shadow)
	m.shadow = shadow
	return m


## Restore the authored on-screen size after an import-cache resize (ratio 1.0 is a no-op).
func _compensate_import_cap(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	var decoded := float(maxi(sprite.texture.get_width(), sprite.texture.get_height()))
	var original: float = float(ART_MAX_SIDE.get(String(sprite.name), 0.0))
	if decoded <= 0.0 or original <= 0.0:
		return
	var k := original / decoded
	sprite.scale *= k
	sprite.offset /= k


# =========================================================================
# Rows and pool
# =========================================================================
func _layout() -> void:
	var free: Array[Member] = _members.duplicate()
	var queen := _member_named(PINNED_NAME)
	if queen != null:
		_assign(queen, 0, PINNED_SLOT)
		free.erase(queen)
	for name in RETIRED_NAMES:
		var gone := _member_named(name)
		if gone != null:
			_retire(gone)
			free.erase(gone)
	for slot in [0, 1, 3, 4]:
		if free.is_empty():
			break
		_assign(free.pop_front(), 0, slot)
	for slot in range(BACK_SLOTS.size()):
		if free.is_empty():
			break
		_assign(free.pop_front(), 1, slot)
	for m in free:
		_pool(m)


## Keep a member in the scene but off the line (a pose that no longer works, kept as art).
func _retire(m: Member) -> void:
	m.retired = true
	m.row = -1
	m.slot = -1
	m.lean = 0.0
	m.sprite.visible = false
	m.sprite.rotation = 0.0
	m.sprite.self_modulate = Color.WHITE


func _assign(m: Member, row: int, slot: int) -> void:
	m.row = row
	m.slot = slot
	m.lean = 0.0
	m.home = Vector2(_slot_x(row, slot), _row_y(row))
	m.sprite.position = m.home
	m.sprite.scale = _row_scale(m, row)
	m.sprite.z_index = 0 if row == 0 else -1     # the back row never draws over the front
	m.sprite.modulate = Color(1.0, 1.0, 1.0, 1.0) if row == 0 else back_shade
	m.sprite.visible = true
	_update_shadow(m)


func _pool(m: Member) -> void:
	m.row = -1
	m.slot = -1
	m.sprite.visible = false
	if m.retired:
		return
	# Park the shadow at the front line; _assign re-grounds it when the member returns.
	m.shadow.ground_y = FRONT_ROW_Y
	m.shadow.radius = clampf(m.shadow_radius, 8.0, 24.0)
	if m.bounce != null and m.bounce.is_valid():
		m.bounce.kill()


func _update_shadow(m: Member) -> void:
	var mult: float = 1.0 if m.row == 0 else back_scale_mult
	m.shadow.ground_y = m.home.y
	m.shadow.radius = clampf(m.shadow_radius * mult, 8.0, 24.0)


func _row_scale(m: Member, row: int) -> Vector2:
	return m.front_scale if row == 0 else m.front_scale * back_scale_mult


func _slot_x(row: int, slot: int) -> float:
	return float(FRONT_SLOTS[slot]) if row == 0 else float(BACK_SLOTS[slot])


func _row_y(row: int) -> float:
	return FRONT_ROW_Y if row == 0 else BACK_ROW_Y


func _member_named(node_name: String) -> Member:
	for m in _members:
		if m.sprite.name == node_name:
			return m
	return null


# =========================================================================
# Rotation — the crowd reshuffles itself every 12–18 s
# =========================================================================
## Swap 1–2 people out of the rows for pooled characters. Returns how many moved.
func rotate_now(count: int) -> int:
	var moved := 0
	for i in count:
		if _rotate_one():
			moved += 1
	if moved > 0:
		crowd_rotated.emit(moved)
	return moved


## 50 % Crowd Hype: the crowd reacts with a reshuffle of its own.
func celebrate() -> void:
	rotate_now(_rng.randi_range(swap_min, swap_max))


func _rotate_one() -> bool:
	var outgoing := _random_visible()
	var incoming := _random_pooled()
	if outgoing == null or incoming == null:
		return false
	var row := outgoing.row
	var slot := outgoing.slot
	var target_home := Vector2(_slot_x(row, slot), _row_y(row))
	var target_scale := _row_scale(incoming, row)

	# Free the slot at once so the row counts never wobble mid-swap; the outgoing member
	# stays visible while it fades, then hides and joins the pool.
	outgoing.row = -1
	outgoing.slot = -1
	outgoing.swapping = true
	incoming.swapping = true
	if outgoing.bounce != null and outgoing.bounce.is_valid():
		outgoing.bounce.kill()

	var fade := create_tween()
	fade.tween_property(outgoing.sprite, "modulate:a", 0.0, swap_seconds * 0.5)
	fade.parallel().tween_property(outgoing.sprite, "position:y", outgoing.home.y + 7.0,
		swap_seconds * 0.5)
	fade.tween_callback(func() -> void:
		outgoing.sprite.visible = false
		outgoing.swapping = false)

	incoming.row = row
	incoming.slot = slot
	incoming.home = target_home
	incoming.sprite.position = target_home + Vector2(0.0, 9.0)
	incoming.sprite.scale = target_scale * 0.93
	incoming.sprite.modulate = Color(back_shade.r, back_shade.g, back_shade.b, 0.0) \
		if row == 1 else Color(1.0, 1.0, 1.0, 0.0)
	incoming.sprite.visible = true
	_update_shadow(incoming)

	var enter := create_tween()
	enter.tween_property(incoming.sprite, "modulate:a", 1.0, swap_seconds)
	enter.parallel().tween_property(incoming.sprite, "position", target_home, swap_seconds)
	enter.parallel().tween_property(incoming.sprite, "scale", target_scale, swap_seconds)
	enter.tween_callback(func() -> void:
		incoming.swapping = false
		_assign(incoming, row, slot))
	incoming.swap = enter
	return true


func _random_visible() -> Member:
	var candidates: Array[Member] = []
	for m in _members:
		if m.row >= 0 and not m.swapping and not m.retired \
				and m.sprite.name != PINNED_NAME:
			candidates.append(m)
	if candidates.is_empty():
		return null
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


func _random_pooled() -> Member:
	var candidates: Array[Member] = []
	for m in _members:
		if m.row < 0 and not m.swapping and not m.retired:
			candidates.append(m)
	if candidates.is_empty():
		return null
	return candidates[_rng.randi_range(0, candidates.size() - 1)]


# =========================================================================
# Beat bounce, hype surge
# =========================================================================
## 132 BPM accent. The old version hopped all fifteen people on the same frame — the
## "frozen drawings bouncing together" note from the 2026-11-17 playtest. Each member now
## answers a different beat of the bar (`beat_div` / `beat_offset`), and the act cycle below
## carries the motion in between, so the line pulses without marching in step.
func on_beat(beat_index: int) -> void:
	for m in _members:
		if m.row < 0 or m.swapping or m.retired:
			continue
		if (beat_index + m.beat_offset) % maxi(m.beat_div, 1) != 0:
			continue
		m.accent = 1.0


## Called when a fighter's Hype Meter fills. `seconds` is the fighter's boost length, so
## the crowd stays up for exactly as long as the momentum boost lasts.
func surge(seconds: float) -> void:
	_surge_left = maxf(seconds, 0.1)
	_hop_timer = 0.0
	for i in _members.size():
		var m := _members[i]
		if m.row < 0 or m.swapping:
			continue
		_bounce(m, surge_hop_pixels * 1.3, 0.22, float(i) * 0.03)
	rotate_now(1)          # 100 % Hype also reshuffles the line


func is_surging() -> bool:
	return _surge_left > 0.0


func crowd_size() -> int:
	return _members.size()


func front_row_count() -> int:
	var n := 0
	for m in _members:
		if m.row == 0:
			n += 1
	return n


func back_row_count() -> int:
	var n := 0
	for m in _members:
		if m.row == 1:
			n += 1
	return n


func pooled_count() -> int:
	var n := 0
	for m in _members:
		if m.row < 0:
			n += 1
	return n


# =========================================================================
# Ambient sway and proximity ebb (AGENTS.md §9 item 21)
# =========================================================================
## Per-member act performance. Every value is written straight from each member's own clock:
## no tween per beat, so nothing collides with the surge tweens and nothing lands in unison.
## Whole-sprite lift/tilt/squash only — the art is one frozen drawing per character.
func _update_acts(delta: float) -> void:
	var flinch_tilt := deg_to_rad(flinch_tilt_deg)
	var surging := is_surging()
	for m in _members:
		if m.row < 0 or m.swapping or m.retired or m.sprite == null:
			continue
		m.phase = fposmod(m.phase + m.rate * delta, TAU)
		if m.accent > 0.0:
			m.accent = maxf(0.0, m.accent - delta * ACCENT_DECAY)
		if m.flinch > 0.0:
			m.flinch = maxf(0.0, m.flinch - delta / maxf(flinch_seconds, 0.05))
		var away := m.flinch * m.flinch_dir
		var x := m.home.x + sin(m.phase) * sway_pixels + away * flinch_shift
		if surging:
			# The surge hop tween owns y and rotation; drift and the shadow stay live.
			m.sprite.position = Vector2(x, m.sprite.position.y)
			continue
		var t := m.phase
		var lift := 0.0
		var tilt_deg := 0.0
		var squash := 1.0
		var boost := m.accent
		match m.act:
			ACT_FLAG, ACT_RAG:
				# Cloth worked overhead: a slow sweep with a snap, plus a little body bob.
				var amp := 6.5 if m.act == ACT_FLAG else 5.0
				tilt_deg = sin(t) * amp + sin(t * 2.0) * 1.8
				lift = -absf(sin(t)) * 1.8 - boost * 2.5
			ACT_HORN:
				# Raise it, lean back, blow, lower: one horn call per cycle.
				var raise := pow(maxf(0.0, sin(t)), 1.6)
				lift = -raise * 7.0 - boost * 2.0
				tilt_deg = -1.0 - raise * 4.5
				squash = 1.0 + raise * 0.015
			ACT_SKANK:
				lift = -absf(sin(t)) * 9.0 - boost * 5.0
				tilt_deg = sin(t * 0.5) * 2.2
				squash = 1.0 - absf(sin(t)) * 0.035
			ACT_DANCE:
				lift = -absf(sin(t)) * 6.0 - boost * 4.0
				tilt_deg = sin(t * 0.5) * 3.0
				squash = 1.0 - absf(sin(t * 2.0)) * 0.02
			_:
				# Cheer: shoulders back, head up, short hop on the accent.
				lift = -absf(sin(t)) * 5.0 - boost * 6.5
				tilt_deg = -1.5 + sin(t * 0.7) * 2.0
		var base := _row_scale(m, m.row)
		m.sprite.position = Vector2(x, m.home.y + lift)
		m.sprite.rotation = m.lean + deg_to_rad(tilt_deg) + away * flinch_tilt
		m.sprite.scale = Vector2(base.x * (2.0 - squash), base.y * squash)


## Night: drop the crowd towards silhouette so the floodlit fighters stay the subject.
## Uses `self_modulate`, so it never fights the swap tweens that animate `modulate:a`.
func set_night(amount: float) -> void:
	_night = clampf(amount, 0.0, 1.0)
	var shade := Color.WHITE.lerp(NIGHT_SILHOUETTE, _night)
	for m in _members:
		if m.retired:
			continue
		m.sprite.self_modulate = shade


## Time-of-day shadows for the whole line (see `GroundShadow.light_dir` / `stretch`).
func apply_light(dir: float, stretch: float) -> void:
	for m in _members:
		if m.retired:
			continue
		m.shadow.light_dir = dir
		m.shadow.stretch = stretch


## Nearby spectators flinch away from a body that dashes, is thrown or lands beside them.
## Returns how many members reacted, so the caller can rate-limit itself.
func flinch(at_x: float, strength: float = 1.0) -> int:
	var touched := 0
	var reach := maxf(flinch_radius, 1.0)
	for m in _members:
		if m.row < 0 or m.swapping:
			continue
		var distance := absf(m.home.x - at_x)
		if distance > reach:
			continue
		var near := 1.0 - distance / reach
		var want := near * clampf(strength, 0.2, 1.4)
		if want > m.flinch:
			var away := m.home.x - at_x
			if is_zero_approx(away):
				away = -1.0 if m.slot < PINNED_SLOT else 1.0
			m.flinch_dir = 1.0 if away > 0.0 else -1.0
			m.flinch = want
		touched += 1
	return touched


## World y of the front rope row — the anchor the arena measures proximity against.
func crowd_line_y() -> float:
	return FRONT_ROW_Y


func _process(delta: float) -> void:
	_update_acts(delta)
	_rotate_timer -= delta
	if _rotate_timer <= 0.0:
		_rotate_timer = _rng.randf_range(rotate_min_seconds, rotate_max_seconds)
		rotate_now(_rng.randi_range(swap_min, swap_max))

	if _surge_left <= 0.0:
		return
	_surge_left = maxf(0.0, _surge_left - delta)
	_hop_timer -= delta
	if _hop_timer <= 0.0 and not _members.is_empty():
		_hop_timer = surge_hop_interval
		_hop_index = (_hop_index + 1) % _members.size()
		var m := _members[_hop_index]
		if m.row >= 0 and not m.swapping:
			_bounce(m, randf_range(surge_hop_pixels * 0.7, surge_hop_pixels * 1.4),
				0.2, 0.0, randf_range(-0.12, 0.12))
	if _surge_left <= 0.0:
		_settle()


func _bounce(m: Member, amp: float, duration: float, delay: float, tilt: float = 0.0) -> void:
	if m.swapping:
		return
	var previous := m.bounce
	if previous != null and previous.is_valid():
		previous.kill()
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(m.sprite, "position:y", m.home.y - amp, duration * 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if tilt != 0.0:
		tw.parallel().tween_property(m.sprite, "rotation", m.lean + tilt, duration * 0.45)
	tw.tween_property(m.sprite, "position:y", m.home.y, duration * 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if tilt != 0.0:
		tw.parallel().tween_property(m.sprite, "rotation", m.lean, duration * 0.55)
	m.bounce = tw


func _settle() -> void:
	for m in _members:
		if m.row < 0:
			continue
		var tw := m.bounce
		if tw != null and tw.is_valid():
			tw.kill()
		m.accent = 0.0
		m.sprite.position = m.home
		m.sprite.rotation = m.lean
		m.sprite.scale = _row_scale(m, m.row)

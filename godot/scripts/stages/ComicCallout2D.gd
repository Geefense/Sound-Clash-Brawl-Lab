class_name ComicCallout2D
extends Node2D
## Pre-pooled comic-book onomatopoeia (PART D). Presentation only.
##
## Twelve SFX strings pop, tilt and fade over the world-to-screen impact point, next to the
## existing hit sparks (`ArcadeVFX2D`) and music-note trails. They are **not** Patois
## dictionary entries and never touch `TestArena.CALLOUTS`, the HUD subtitles or the
## Thirty-one-entry collection.
##
## It reads existing events and writes nothing back:
##
##   * `BaseFighter.strike_resolved` -> light / medium / heavy / counter contact,
##   * `BaseFighter.attack_became_active` + `state_changed` -> a whiff (the ACTIVE window
##     ended with no contact), which is the only place the game exposes that outcome,
##   * `BaseFighter.hype_surge_started` -> the 132 BPM hype callout,
##   * `BaseFighter.static_parry_triggered` -> shipped clash: skipped, see AGENTS.md,
##   * `BaseFighter.died` -> shipped K.O.: skipped, see AGENTS.md.
##
## Slips/dodges are skipped too: this build has no slip or dodge event to read.
##
## Everything is preallocated in `_ready()`: six `Label`s, one font, one palette, and every
## phrase shaped once while hidden. A trigger picks a free label, assigns a preallocated
## string, places it and starts its clock; `_process` does scalar transform/modulate math
## only. An exhausted pool skips the new callout — it never creates a node.

## kind -> the exact phrase strings, verbatim, no others. The order is the round-robin order.
const PHRASES := {
	&"light": ["PLIM!", "BAP!"],
	&"whiff": ["BOOPS!", "ZOOPS!", "SWOOPS!"],
	&"medium": ["BLAPS!", "BIM!"],
	&"heavy": ["BRAGADAPS!", "PLAX!", "BUDUM!"],
	&"beat": ["BRRRRAP!", "PYAW! PYAW!"],
}
const CATEGORIES: Array[StringName] = [&"light", &"whiff", &"medium", &"heavy", &"beat"]
## Gold / green / red / white by category. The on-beat group reuses the bright gold, because
## a hype callout should read as the same celebration as a gold medium slap.
const COLORS := {
	&"light": Color(1.0, 1.0, 1.0, 1.0),
	&"whiff": Color(0.42, 1.0, 0.55, 1.0),
	&"medium": Color(1.0, 0.84, 0.20, 1.0),
	&"heavy": Color(1.0, 0.30, 0.26, 1.0),
	&"beat": Color(1.0, 0.93, 0.46, 1.0),
}
## Pool-tight priority. The lowest tier never takes the last free label.
const PRIORITY := {&"beat": 3, &"heavy": 2, &"medium": 2, &"light": 1, &"whiff": 1}

## Strength tiers read from the shipped move table (`BaseFighter.attacks[].damage`), which is
## the only strength data the combat code carries. A counter flag upgrades any contact.
const LIGHT_MAX_DAMAGE := 8
const MEDIUM_MAX_DAMAGE := 14

const POOL_SIZE := 6
const MIN_INTERVAL_MS := 120.0
const MAX_PER_CATEGORY := 2

## Pop, hold, fade. Heavy callouts linger slightly longer and draw larger.
const POP_SECONDS := 0.16
const FADE_SECONDS := 0.45
const LIFE_SECONDS := 0.62
const LIFE_HEAVY_SECONDS := 0.82
const PEAK_SCALE := 1.25
## Alternating tilts in degrees, cycled in order. Deterministic: no gameplay RNG is read.
const TILTS := [12.0, -13.0, 9.0, -14.0, 11.0, -9.0, 13.0, -10.0, 8.0, -12.0, 14.0, -11.0]
## The widest tilt above. Placement and the audits bound the rotated box with it, so no slot
## can lean past the margin the clamp reserved.
const MAX_TILT_DEG := 14.0

const BASE_FONT_PX := 40
const HEAVY_FONT_PX := 52
const VIEW_HEIGHT := 720.0
const SIZE_PAD := 18.0
const OUTLINE_COLOR := Color(0.035, 0.025, 0.045, 0.96)
const OUTLINE_RATIO := 0.20

## Safe play rectangle in 1280x720 canvas units. Top clears the health + hype bars (they end at
## y 88) and the debug chip; bottom clears the subtitle pill at y 646.
const SAFE_LEFT := 24.0
const SAFE_TOP := 132.0
const SAFE_RIGHT_PAD := 24.0
const SAFE_BOTTOM := 620.0
## Screen offset from the impact point: up, and toward the fighter's own side of the frame,
## so the text never sits on top of the hit flash or the note trail.
const OFFSET_UP := 46.0
const OFFSET_SIDE := 54.0
## Half a pixel of slack inside the margin, so a box clamped to the edge still tests as
## enclosed after float rounding and reads as a margin rather than a touch.
const CLAMP_INSET := 0.5

const FONT := preload("res://assets/fonts/Bungee-Regular.ttf")

## Exported options, wired to the existing options/debug path (F8 and the debug chip).
@export var callout_enabled: bool = true
@export var callout_scale: float = 1.0
@export var reduced_motion: bool = false

## The 3D camera used to project world points to screen pixels. Set by `TestArena`; a null
## camera simply means every trigger returns false.
var camera: Camera3D = null

## One pooled label and its clock. `age < 0` means idle.
class Slot:
	var label: Label
	var age: float = -1.0
	var life: float = LIFE_SECONDS
	var category: StringName = &""
	var phrase: String = ""
	var tint: Color = Color.WHITE
	var tilt: float = 0.0
	var font_px: int = BASE_FONT_PX


var _slots: Array = []
var _view: Vector2 = Vector2(1280.0, 720.0)
var _clock: float = 0.0
var _last_ms: Dictionary = {}          # fighter instance id -> last callout time (ms)
var _cursor: Dictionary = {}           # category -> round-robin index
var _fires_by_category: Dictionary = {} # category -> trigger count (headless checks)
var _phrase_text: Array[String] = []
var _phrase_category: Array[StringName] = []
var _phrase_size: Array[Vector2] = []
var _phrase_safe: Array[bool] = []
var _phrase_index: Dictionary = {}      # phrase -> index into the arrays above
var _warned_phrases: Dictionary = {}
var _pending_whiff: Dictionary = {}     # fighter instance id -> true while an ACTIVE window is unconfirmed
var _tilt_step: int = 0
var _last_category: StringName = &""
var _last_phrase: String = ""


func _ready() -> void:
	_view = get_viewport_rect().size
	get_viewport().size_changed.connect(_on_view_resized)
	for category in CATEGORIES:
		_cursor[category] = 0
		_fires_by_category[category] = 0
	_build_pool()
	_warm_phrases()
	set_process(true)


func _on_view_resized() -> void:
	_view = get_viewport_rect().size


## Six labels, one font, one palette, one time. Nothing below this line creates a node.
func _build_pool() -> void:
	for i in POOL_SIZE:
		var label := Label.new()
		label.name = "Callout%d" % i
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.add_theme_font_override("font", FONT)
		label.add_theme_font_size_override("font_size", BASE_FONT_PX)
		label.add_theme_constant_override("outline_size", _outline_px(BASE_FONT_PX))
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
		label.visible = false
		label.z_index = 20
		add_child(label)
		var slot := Slot.new()
		slot.label = label
		_slots.append(slot)


## Shape every phrase once, while hidden, and cache its box. The first on-screen use therefore
## never pays a text-shaping hitch (iPhone Safari / Chromebook).
func _warm_phrases() -> void:
	for category in CATEGORIES:
		var px := _font_px(category)
		var list: Array = PHRASES[category]
		for entry in list:
			var phrase := String(entry)
			var index := _phrase_text.size()
			_phrase_text.append(phrase)
			_phrase_category.append(category)
			_phrase_index[phrase] = index
			var safe := _has_glyphs(phrase)
			_phrase_safe.append(safe)
			var width := FONT.get_string_size(phrase, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			_phrase_size.append(Vector2(width + SIZE_PAD, float(px) * 1.30))
			if not safe:
				push_warning("ComicCallout2D: %s is missing a glyph — that phrase is skipped" % phrase)
	for i in _phrase_text.size():
		var label: Label = _slots[i % _slots.size()].label
		var px := _font_px(_phrase_category[i])
		label.text = _phrase_text[i]
		label.size = _phrase_size[i]
		label.add_theme_font_size_override("font_size", px)
		FONT.get_string_size(_phrase_text[i], HORIZONTAL_ALIGNMENT_LEFT, -1, px)
	label_clear_all()


func label_clear_all() -> void:
	for slot in _slots:
		(slot as Slot).label.text = ""


## Every character in `text` has a real glyph in the HUD font. A missing one would draw tofu,
## so the phrase is dropped instead of rendered.
func _has_glyphs(text: String) -> bool:
	for i in text.length():
		if not FONT.has_char(text.unicode_at(i)):
			return false
	return true


func _font_px(category: StringName) -> int:
	var base := HEAVY_FONT_PX if category == &"heavy" else BASE_FONT_PX
	return maxi(12, roundi(float(base) * callout_scale * (_view.y / VIEW_HEIGHT)))


func _outline_px(font_px: int) -> int:
	return maxi(4, roundi(float(font_px) * OUTLINE_RATIO))


# =========================================================================
# Triggers (read-only; every one returns false when it does not play)
# =========================================================================
## One unblocked contact. Strength comes from the shipped move table, never from a new field.
func register_strike(attacker: BaseFighter, target: BaseFighter, result: Dictionary,
		world_pos: Vector3) -> bool:
	if attacker == null or target == null:
		return false
	if bool(result.get("ignored", false)) or bool(result.get("parried", false)):
		return false
	if bool(result.get("blocked", false)):
		return false                       # a guarded contact knocks, it does not shout
	var category := classify(attacker, StringName(result.get("attack_id", &"")),
		bool(result.get("counter", false)), bool(result.get("on_beat", false)))
	return _fire(category, attacker, world_pos)


## One contact by move id, for callers that already have the read-only flags.
func register_hit(fighter: BaseFighter, attack_id: StringName, counter: bool, on_beat: bool,
		world_pos: Vector3) -> bool:
	return _fire(classify(fighter, attack_id, counter, on_beat), fighter, world_pos)


## Light / medium / heavy / counter / on-beat, from the existing move data only.
func classify(attacker: BaseFighter, attack_id: StringName, counter: bool,
		on_beat: bool) -> StringName:
	if counter:
		return &"heavy"
	if on_beat and attack_id in BaseFighter.HEAVY_ATTACK_IDS:
		return &"beat"
	if attacker == null:
		return &"light"
	var profile: Dictionary = attacker.attacks.get(attack_id, {})
	var damage := int(profile.get("damage", 15))
	if damage <= LIGHT_MAX_DAMAGE:
		return &"light"
	if damage <= MEDIUM_MAX_DAMAGE:
		return &"medium"
	return &"heavy"


## A fighter's ACTIVE window began. Remembered until a contact or the end of the window.
func note_attack_active(fighter: BaseFighter, attack_id: StringName) -> void:
	if fighter == null:
		return
	# A projectile move's contact is its travelling wave, not this window: never a whiff.
	var profile: Dictionary = fighter.attacks.get(attack_id, {})
	_pending_whiff[fighter.get_instance_id()] = not profile.has("projectile")


## Any contact (blocked, parried or clean) confirms the ACTIVE window.
func note_contact(fighter: BaseFighter) -> void:
	if fighter != null:
		_pending_whiff[fighter.get_instance_id()] = false


## The ACTIVE window ended. Into RECOVERY with no contact is a whiff; an interruption
## (HITSTUN, KNOCKDOWN, KO) is not, and is ignored.
func note_attack_ended(fighter: BaseFighter, world_pos: Vector3) -> void:
	if fighter == null:
		return
	var id := fighter.get_instance_id()
	if not bool(_pending_whiff.get(id, false)):
		return
	_pending_whiff[id] = false
	_fire(&"whiff", fighter, world_pos)


## 132 BPM hype surge (read from the existing Crowd Hype signal, never written).
func register_hype(fighter: BaseFighter, world_pos: Vector3) -> bool:
	return _fire(&"beat", fighter, world_pos)


## Every cap, the pool, the phrase rotation and the placement, in one place.
func _fire(category: StringName, fighter: BaseFighter, world_pos: Vector3) -> bool:
	if not callout_enabled or camera == null or not PHRASES.has(category):
		return false
	var slot := _first_free_slot()
	if slot == null:
		return false
	if _active_in(category) >= MAX_PER_CATEGORY:
		return false
	# The last free label is reserved for a heavy / on-beat / hype moment.
	if _free_count() <= 1 and int(PRIORITY[category]) < 2:
		return false
	var fighter_id := fighter.get_instance_id() if fighter != null else 0
	if _clock * 1000.0 - float(_last_ms.get(fighter_id, -1000000.0)) < MIN_INTERVAL_MS:
		return false
	var index := _next_phrase(category)
	if index < 0:
		return false
	var label: Label = slot.label
	var size: Vector2 = _phrase_size[index] * callout_scale
	var px := _font_px(category)
	label.text = _phrase_text[index]
	if slot.font_px != px:
		slot.font_px = px
		label.add_theme_font_size_override("font_size", px)
		label.add_theme_constant_override("outline_size", _outline_px(px))
	label.size = size
	label.pivot_offset = size * 0.5
	var centre := _centre_for(world_pos, size)
	label.position = centre - size * 0.5
	slot.age = 0.0
	slot.life = LIFE_HEAVY_SECONDS if category == &"heavy" else LIFE_SECONDS
	slot.category = category
	slot.phrase = _phrase_text[index]
	slot.tint = COLORS[category]
	slot.tilt = 0.0 if reduced_motion else deg_to_rad(float(TILTS[_tilt_step]))
	_tilt_step = (_tilt_step + 1) % TILTS.size()
	label.rotation = slot.tilt
	label.modulate = slot.tint
	label.scale = Vector2.ONE if reduced_motion else Vector2(0.001, 0.001)
	label.visible = true
	_last_ms[fighter_id] = _clock * 1000.0
	_last_category = category
	_last_phrase = slot.phrase
	_fires_by_category[category] = int(_fires_by_category.get(category, 0)) + 1
	return true


## Deterministic round-robin per category, skipping any phrase whose glyphs are missing.
func _next_phrase(category: StringName) -> int:
	var list: Array = PHRASES[category]
	var cursor := int(_cursor.get(category, 0))
	for step in list.size():
		var slot_index := (cursor + step) % list.size()
		var phrase := String(list[slot_index])
		var index := int(_phrase_index.get(phrase, -1))
		if index >= 0 and bool(_phrase_safe[index]):
			_cursor[category] = (slot_index + 1) % list.size()
			return index
	if not _warned_phrases.has(category):
		_warned_phrases[category] = true
		push_warning("ComicCallout2D: no drawable %s phrase — callout skipped" % String(category))
	return -1


func _first_free_slot() -> Slot:
	for slot in _slots:
		if (slot as Slot).age < 0.0:
			return slot
	return null


func _free_count() -> int:
	var n := 0
	for slot in _slots:
		if (slot as Slot).age < 0.0:
			n += 1
	return n


func _active_in(category: StringName) -> int:
	var n := 0
	for slot in _slots:
		var s := slot as Slot
		if s.age >= 0.0 and s.category == category:
			n += 1
	return n


# =========================================================================
# Placement
# =========================================================================
## Final screen box an AABB-clamped phrase occupies. Used by the callout itself and by the
## headless audits, so the clamp has exactly one implementation.
func _centre_for(world_pos: Vector3, size: Vector2) -> Vector2:
	var screen := camera.unproject_position(world_pos)
	var scale := maxf(callout_scale, 0.01)
	var dir := signf(screen.x - _view.x * 0.5)
	if is_zero_approx(dir):
		dir = 1.0
	screen.x += dir * OFFSET_SIDE * scale
	screen.y -= OFFSET_UP * scale
	var safe := safe_rect()
	# Rotated AABB at the pop peak, so even the overshoot frame stays inside the margin.
	var angle := deg_to_rad(MAX_TILT_DEG)
	var cos_a := absf(cos(angle))
	var sin_a := absf(sin(angle))
	var w := size.x * PEAK_SCALE
	var h := size.y * PEAK_SCALE
	var half := Vector2((w * cos_a + h * sin_a) * 0.5, (w * sin_a + h * cos_a) * 0.5)
	var min_x := safe.position.x + half.x + CLAMP_INSET
	var max_x := safe.end.x - half.x - CLAMP_INSET
	var min_y := safe.position.y + half.y + CLAMP_INSET
	var max_y := safe.end.y - half.y - CLAMP_INSET
	screen.x = safe.get_center().x if max_x < min_x else clampf(screen.x, min_x, max_x)
	screen.y = safe.get_center().y if max_y < min_y else clampf(screen.y, min_y, max_y)
	return screen


func safe_rect() -> Rect2:
	var s := _view.y / VIEW_HEIGHT
	var left := SAFE_LEFT * s
	var top := SAFE_TOP * s
	return Rect2(left, top, _view.x - left - SAFE_RIGHT_PAD * s, (SAFE_BOTTOM - SAFE_TOP) * s)


## The box `phrase` would occupy at `world_pos`, at the pop peak and the widest tilt. Pure.
func rect_for_phrase(phrase: String, world_pos: Vector3) -> Rect2:
	var index := int(_phrase_index.get(phrase, -1))
	if index < 0:
		return Rect2()
	return rect_for_size(_phrase_size[index] * callout_scale, world_pos)


func rect_for_size(size: Vector2, world_pos: Vector3) -> Rect2:
	var centre := _centre_for(world_pos, size)
	var angle := deg_to_rad(MAX_TILT_DEG)
	var cos_a := absf(cos(angle))
	var sin_a := absf(sin(angle))
	var w := size.x * PEAK_SCALE
	var h := size.y * PEAK_SCALE
	var half := Vector2((w * cos_a + h * sin_a) * 0.5, (w * sin_a + h * cos_a) * 0.5)
	return Rect2(centre - half, half * 2.0)


# =========================================================================
# Frame
# =========================================================================
func _process(delta: float) -> void:
	_step(delta)


## Headless audit hook: advance the same pool clock by a fixed step, so caps and lifetimes
## are measured deterministically instead of against the real frame rate. Nothing in the
## game calls it (same contract as `Arena3D.hold_exchange_yaw`).
func debug_advance(seconds: float) -> void:
	_step(maxf(seconds, 0.0))


func _step(delta: float) -> void:
	_clock += delta
	for slot in _slots:
		var s := slot as Slot
		if s.age < 0.0:
			continue
		s.age += delta
		if s.age >= s.life:
			s.age = -1.0
			s.label.visible = false
			continue
		var fade_start := s.life - FADE_SECONDS
		var alpha := 1.0
		if s.age > fade_start:
			alpha = clampf(1.0 - (s.age - fade_start) / FADE_SECONDS, 0.0, 1.0)
		var scale := 1.0
		if not reduced_motion and s.age < POP_SECONDS:
			var u := s.age / POP_SECONDS
			if u < 0.55:
				scale = PEAK_SCALE * (u / 0.55)
			else:
				scale = lerpf(PEAK_SCALE, 1.0, (u - 0.55) / 0.45)
		s.label.scale = Vector2(scale, scale)
		s.label.rotation = 0.0 if reduced_motion else s.tilt
		s.label.modulate = Color(s.tint.r, s.tint.g, s.tint.b, alpha)


# =========================================================================
# Options / debug path
# =========================================================================
func set_enabled(on: bool) -> void:
	callout_enabled = on
	if not on:
		for slot in _slots:
			var s := slot as Slot
			s.age = -1.0
			s.label.visible = false


func toggle_enabled() -> bool:
	set_enabled(not callout_enabled)
	return callout_enabled


# =========================================================================
# Headless reporting
# =========================================================================
func pool_size() -> int:
	return POOL_SIZE


func label_count() -> int:
	return _slots.size()


func labels() -> Array:
	var out: Array = []
	for slot in _slots:
		out.append((slot as Slot).label)
	return out


func phrase_table() -> Dictionary:
	return PHRASES


func phrase_count() -> int:
	return _phrase_text.size()


func phrase_size(phrase: String) -> Vector2:
	var index := int(_phrase_index.get(phrase, -1))
	return _phrase_size[index] if index >= 0 else Vector2.ZERO


func phrase_category(phrase: String) -> StringName:
	var index := int(_phrase_index.get(phrase, -1))
	return _phrase_category[index] if index >= 0 else &""


func is_phrase_safe(phrase: String) -> bool:
	var index := int(_phrase_index.get(phrase, -1))
	return bool(_phrase_safe[index]) if index >= 0 else false


## Every phrase whose glyphs are missing. Empty is the only acceptable shipped state.
func missing_glyphs() -> Array[String]:
	var out: Array[String] = []
	for i in _phrase_text.size():
		if not bool(_phrase_safe[i]):
			out.append(_phrase_text[i])
	return out


func active_count() -> int:
	var n := 0
	for slot in _slots:
		if (slot as Slot).age >= 0.0:
			n += 1
	return n


## Current on-screen boxes of every playing label (AABB at its live scale and tilt).
func active_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for slot in _slots:
		var s := slot as Slot
		if s.age < 0.0:
			continue
		var scale := s.label.scale.x
		var w := s.label.size.x * scale
		var h := s.label.size.y * scale
		var cos_a := absf(cos(s.label.rotation))
		var sin_a := absf(sin(s.label.rotation))
		var half := Vector2((w * cos_a + h * sin_a) * 0.5, (w * sin_a + h * cos_a) * 0.5)
		var centre: Vector2 = s.label.position + s.label.size * 0.5
		out.append(Rect2(centre - half, half * 2.0))
	return out


func last_category() -> StringName:
	return _last_category


func last_phrase() -> String:
	return _last_phrase


func fire_count(category: StringName) -> int:
	return int(_fires_by_category.get(category, 0))


func total_fires() -> int:
	var n := 0
	for category in _fires_by_category:
		n += int(_fires_by_category[category])
	return n


func is_whiff_pending(fighter: BaseFighter) -> bool:
	return fighter != null and bool(_pending_whiff.get(fighter.get_instance_id(), false))

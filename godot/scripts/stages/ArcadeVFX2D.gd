class_name ArcadeVFX2D
extends Node2D
## Retro arcade FX layer (PART 2, commit 4). Presentation only.
##
## Four optional sprite sheets (`assets/sprites/arcade_fx/`) play at 24 fps over the world
## point of an event, stepped as `hframes`/`vframes` frames on a **preallocated** pool of
## Sprite2D nodes. Nothing is created, loaded or allocated while the match runs:
##
##   * the pool (3 sprites per sheet, 12 at most) is built once in `_ready()`;
##   * playback is scalar age + `Sprite2D.frame`, no `AtlasTexture`, no `AnimatedSprite2D`;
##   * a sheet that is not present is logged **once** and draws nothing — no stand-in art,
##     no placeholder texture, no procedural substitute. The game runs with all four missing.
##
## It lives on its own `CanvasLayer` (created by `TestArena`), below the HUD, and it only reads
## the 3D camera to convert a world point to screen pixels. It never moves the camera, changes
## its FOV, clip plane or the backdrop, so the camera/yard clearance audit is untouched.
##
## PART L (2026-11-27): the two delivered sheets are **one horizontal strip of six square
## frames** — `hit_spark_sheet.png` 768 x 128 (6 x 128 px) and `bass_shockwave_sheet.png`
## 1536 x 256 (6 x 256 px) — not the 4 x 4 grid the two still-missing sheets are specified on.
## The grid is therefore READ from each texture instead of assumed, and a smaller delivered
## cell is scaled up by `FRAME_REF_PX / cell` so every sheet keeps the footprint it was
## authored at. Colours are per play, not per sheet: the coordinator passes a leading accent
## (a red edge on a counter spark, a green edge on an on-beat ring) or a three-stop ramp (the
## `SPEAKER BOX!` green -> gold -> red blowout), all as scalar lerps on a pooled sprite.

const SHEET_DIR := "res://assets/sprites/arcade_fx/"
## kind -> filename. The order is the order the missing-file warnings are logged.
const SHEETS := {
	&"hit_spark": "hit_spark_sheet.png",
	&"bass_shockwave": "bass_shockwave_sheet.png",
	&"clash_callout": "clash_callout_sheet.png",
	&"ko_callout": "ko_callout_sheet.png",
}
const KINDS: Array[StringName] = [&"hit_spark", &"bass_shockwave", &"clash_callout", &"ko_callout"]
## A texture six times as wide as it is tall is one horizontal strip of six square frames;
## anything else keeps the 4 x 4 README grid the two undelivered sheets are specified on.
const STRIP_COLUMNS := 6
const README_GRID := Vector2i(4, 4)
## The cell size `DRAW_SCALE` was tuned against. A 128 px delivered cell is drawn at twice the
## scale of a 256 px one, so both sheets cover the same screen footprint.
const FRAME_REF_PX := 256.0
const PLAYBACK_FPS := 24.0
## Three of any one effect at a time is enough for a hit, a trade and a re-hit inside the same
## half second; a fourth recycles the oldest instead of allocating.
const POOL_PER_SHEET := 3
## 256 px authored frames drawn a touch under half size, so the effect reads as an overlay and
## not as a second character.
const DRAW_SCALE := 0.45
## How long a leading accent colour takes to settle into the effect's own tint. Short enough
## to read as an edge on the contact, not as a colour wash.
const ACCENT_SECONDS := 0.14

const MODE_FLAT := 0
const MODE_ACCENT := 1
const MODE_RAMP := 2

## One pooled sprite and its playback clock. `age < 0` means idle. Every field is a scalar or
## a value type, so stepping the whole pool allocates nothing.
class Slot:
	var sprite: Sprite2D
	var age: float = -1.0
	var life: float = 0.0
	var frames: int = 0
	var alpha: float = 1.0
	var base_scale: float = DRAW_SCALE
	var mode: int = MODE_FLAT
	var c_from: Color = Color.WHITE
	var c_mid: Color = Color.WHITE
	var c_to: Color = Color.WHITE


## The 3D camera used to project world points to screen pixels. Set by `TestArena` after the
## arena exists; a null camera simply means every trigger returns false.
var camera: Camera3D = null

## F9 master switch (`TestArena.toggle_strike_fx`). Off suppresses every new play; the effects
## already on screen finish their own clip, so switching cannot leave a sprite stuck.
var enabled: bool = true

var _material: CanvasItemMaterial
var _pools: Dictionary = {}        # kind -> Array[Slot]
var _textures: Dictionary = {}     # kind -> Texture2D, only for sheets that exist
var _grid: Dictionary = {}         # kind -> Vector2i(hframes, vframes)
var _frames_for: Dictionary = {}   # kind -> frame count
var _cell_px: Dictionary = {}      # kind -> authored cell size in px
var _warned: Dictionary = {}       # kind -> true once the missing-file warning was logged
var _warnings: int = 0
var _plays: Dictionary = {}        # kind -> trigger count (headless checks)


func _ready() -> void:
	# One additive material shared by every pooled sprite: the sheets are painted for additive
	# blending (black is invisible), so the layer never needs a per-effect material.
	_material = CanvasItemMaterial.new()
	_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for kind in KINDS:
		var path := sheet_path(kind)
		var texture: Texture2D = null
		if ResourceLoader.exists(path):
			texture = load(path) as Texture2D
		if texture == null:
			# Exactly once per sheet, ever. Not once per event, not once per frame.
			push_warning("ArcadeVFX2D: %s is missing — %s draws nothing" % [path, String(kind)])
			_warnings += 1
			_warned[kind] = true
			continue
		_textures[kind] = texture
		var grid := grid_for(texture)
		_grid[kind] = grid
		_frames_for[kind] = grid.x * grid.y
		_cell_px[kind] = int(texture.get_width() / grid.x)
		_build_pool(kind, texture, grid)
	# No work when nothing was delivered: the layer still exists and stays at zero cost.
	set_process(not _pools.is_empty())


## The frame grid a delivered sheet is cut on. Pure, so the headless check can read the same
## rule the pool uses instead of re-deriving it.
static func grid_for(texture: Texture2D) -> Vector2i:
	if texture == null:
		return README_GRID
	var w := texture.get_width()
	var h := texture.get_height()
	if h > 0 and w == h * STRIP_COLUMNS:
		return Vector2i(STRIP_COLUMNS, 1)
	return README_GRID


## Uniform sprite scale for a delivered cell: a 128 px strip frame draws at 0.90, a 256 px one
## at 0.45, so both cover the 115 px footprint the layer was tuned for.
static func draw_scale_for(cell_px: int) -> float:
	if cell_px <= 0:
		return DRAW_SCALE
	return DRAW_SCALE * FRAME_REF_PX / float(cell_px)


func _build_pool(kind: StringName, texture: Texture2D, grid: Vector2i) -> void:
	var frames: int = grid.x * grid.y
	var scale := draw_scale_for(int(_cell_px[kind]))
	var pool: Array[Slot] = []
	for i in POOL_PER_SHEET:
		var sprite := Sprite2D.new()
		sprite.name = "Fx%s%d" % [String(kind), i]
		sprite.texture = texture
		sprite.hframes = grid.x
		sprite.vframes = grid.y
		sprite.frame = 0
		sprite.centered = true
		sprite.scale = Vector2(scale, scale)
		sprite.material = _material
		sprite.visible = false
		add_child(sprite)
		var slot := Slot.new()
		slot.sprite = sprite
		slot.frames = frames
		slot.life = float(frames) / PLAYBACK_FPS
		slot.base_scale = scale
		pool.append(slot)
	_pools[kind] = pool
	_plays[kind] = 0


## Play `kind` over `world_pos` (a 3D world point, e.g. an impact height), flat-tinted.
## Returns false when the layer is switched off, the sheet is missing or there is no camera to
## project through — it renders nothing either way.
func play_at_world(kind: StringName, world_pos: Vector3, strength: float = 1.0,
		tint: Color = Color.WHITE, scale_mult: float = 1.0) -> bool:
	return _play(kind, world_pos, strength, tint, tint, tint, MODE_FLAT, scale_mult)


## Play `kind` with a leading accent colour that settles into `tint` over `ACCENT_SECONDS`
## (the red edge on a heavy counter's spark, the green edge on a confirmed on-beat ring).
func play_accent(kind: StringName, world_pos: Vector3, accent: Color, tint: Color,
		strength: float = 1.0, scale_mult: float = 1.0) -> bool:
	return _play(kind, world_pos, strength, accent, accent, tint, MODE_ACCENT, scale_mult)


## Play `kind` as a three-stop colour ramp across its whole clip (the `SPEAKER BOX!` blowout:
## green -> gold -> red). One pooled sprite, one scalar per frame, no new resource.
func play_ramp(kind: StringName, world_pos: Vector3, first: Color, mid: Color, last: Color,
		strength: float = 1.0, scale_mult: float = 1.0) -> bool:
	return _play(kind, world_pos, strength, first, mid, last, MODE_RAMP, scale_mult)


func _play(kind: StringName, world_pos: Vector3, strength: float, from: Color, mid: Color,
		to: Color, mode: int, scale_mult: float) -> bool:
	if not enabled or camera == null or not _pools.has(kind):
		return false
	var slot := _claim(kind)
	if slot == null:
		return false
	slot.age = 0.0
	slot.mode = mode
	slot.c_from = from
	slot.c_mid = mid
	slot.c_to = to
	slot.alpha = clampf(strength, 0.35, 1.0)
	var scale: float = slot.base_scale * clampf(scale_mult, 0.2, 3.0)
	slot.sprite.scale = Vector2(scale, scale)
	slot.sprite.frame = 0
	slot.sprite.modulate = _colour_at(slot)
	slot.sprite.visible = true
	slot.sprite.position = camera.unproject_position(world_pos)
	_plays[kind] = int(_plays.get(kind, 0)) + 1
	return true


## First idle slot, else the one that started earliest. Reuse, never allocate.
func _claim(kind: StringName) -> Slot:
	var pool: Array = _pools.get(kind, [])
	if pool.is_empty():
		return null
	for candidate in pool:
		if (candidate as Slot).age < 0.0:
			return candidate
	var slot: Slot = pool[0]
	for candidate in pool:
		if (candidate as Slot).age > slot.age:
			slot = candidate
	return slot


## The colour a slot is drawn at this instant. Pure value math (Color is a value type), so it
## allocates nothing even when called for every sprite every frame.
func _colour_at(slot: Slot) -> Color:
	var c := slot.c_to
	if slot.mode == MODE_RAMP:
		var p := clampf(slot.age / maxf(slot.life, 0.0001), 0.0, 1.0)
		if p < 0.5:
			c = slot.c_from.lerp(slot.c_mid, p * 2.0)
		else:
			c = slot.c_mid.lerp(slot.c_to, (p - 0.5) * 2.0)
	elif slot.mode == MODE_ACCENT:
		c = slot.c_from.lerp(slot.c_to, clampf(slot.age / ACCENT_SECONDS, 0.0, 1.0))
	return Color(c.r, c.g, c.b, c.a * slot.alpha)


func _process(delta: float) -> void:
	_step(delta)


## Headless audit hook: advance the same playback clock by a fixed step, so a simulated frame
## costs no wall-clock time. Nothing in the game calls it.
func debug_advance(seconds: float) -> void:
	_step(maxf(seconds, 0.0))


func _step(delta: float) -> void:
	for kind in _pools:
		for slot in _pools[kind]:
			var s := slot as Slot
			if s.age < 0.0:
				continue
			s.age += delta
			if s.age >= s.life:
				s.age = -1.0
				s.sprite.visible = false
				continue
			var frame := int(s.age * PLAYBACK_FPS)
			s.sprite.frame = mini(frame, s.frames - 1)
			s.sprite.modulate = _colour_at(s)


## Stop every playing effect without touching the pool (used after the boot warm pass).
func clear_all() -> void:
	for kind in _pools:
		for slot in _pools[kind]:
			var s := slot as Slot
			s.age = -1.0
			s.sprite.visible = false


func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		clear_all()


func toggle_enabled() -> bool:
	set_enabled(not enabled)
	return enabled


# =========================================================================
# Headless reporting
# =========================================================================
func sheet_path(kind: StringName) -> String:
	return SHEET_DIR + String(SHEETS.get(kind, ""))


func has_sheet(kind: StringName) -> bool:
	return _textures.has(kind)


## True when the missing-file warning was logged for this kind.
func warned(kind: StringName) -> bool:
	return _warned.get(kind, false)


func warning_count() -> int:
	return _warnings


## Delivered sheet size in pixels, or Vector2i.ZERO when it is missing.
func sheet_size(kind: StringName) -> Vector2i:
	var texture: Texture2D = _textures.get(kind)
	return Vector2i(texture.get_width(), texture.get_height()) if texture != null else Vector2i.ZERO


## The grid the delivered sheet is cut on: `(6, 1)` for the delivered strips, `(4, 4)` for the
## README grid of a sheet that is not here yet.
func sheet_grid(kind: StringName) -> Vector2i:
	return _grid.get(kind, README_GRID)


func frame_count(kind: StringName) -> int:
	return int(_frames_for.get(kind, 0))


func cell_px(kind: StringName) -> int:
	return int(_cell_px.get(kind, 0))


## Pooled Sprite2D nodes in this layer. Zero when no sheet was delivered.
func sprite_count() -> int:
	var n := 0
	for kind in _pools:
		n += (_pools[kind] as Array).size()
	return n


func playing_count() -> int:
	var n := 0
	for kind in _pools:
		for slot in _pools[kind]:
			if (slot as Slot).age >= 0.0:
				n += 1
	return n


func play_count(kind: StringName) -> int:
	return int(_plays.get(kind, 0))


func total_plays() -> int:
	var n := 0
	for kind in _plays:
		n += int(_plays[kind])
	return n


## Zero the trigger counters, so a check measures the match and not the boot warm pass.
func reset_counts() -> void:
	for kind in KINDS:
		_plays[kind] = 0


## The sprite currently playing `kind` (first one), for the headless colour/scale audit.
func playing_sprite(kind: StringName) -> Sprite2D:
	for slot in _pools.get(kind, []):
		if (slot as Slot).age >= 0.0:
			return (slot as Slot).sprite
	return null

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
## Sheet spec (grid, frame size, fps, pivot) is `assets/sprites/arcade_fx/README.md`.

const SHEET_DIR := "res://assets/sprites/arcade_fx/"
## kind -> filename. The order is the order the missing-file warnings are logged.
const SHEETS := {
	&"hit_spark": "hit_spark_sheet.png",
	&"bass_shockwave": "bass_shockwave_sheet.png",
	&"clash_callout": "clash_callout_sheet.png",
	&"ko_callout": "ko_callout_sheet.png",
}
const KINDS: Array[StringName] = [&"hit_spark", &"bass_shockwave", &"clash_callout", &"ko_callout"]
const HFRAMES := 4
const VFRAMES := 4
const FRAME_COUNT := HFRAMES * VFRAMES
const FRAME_PX := 256
const PLAYBACK_FPS := 24.0
## Three of any one effect at a time is enough for a hit, a trade and a re-hit inside the same
## half second; a fourth recycles the oldest instead of allocating.
const POOL_PER_SHEET := 3
## 256 px authored frames drawn a touch under half size, so the effect reads as an overlay and
## not as a second character.
const DRAW_SCALE := 0.45

## One pooled sprite and its playback clock. `age < 0` means idle.
class Slot:
	var sprite: Sprite2D
	var age: float = -1.0


## The 3D camera used to project world points to screen pixels. Set by `TestArena` after the
## arena exists; a null camera simply means every trigger returns false.
var camera: Camera3D = null

var _material: CanvasItemMaterial
var _pools: Dictionary = {}        # kind -> Array[Slot]
var _textures: Dictionary = {}     # kind -> Texture2D, only for sheets that exist
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
		_build_pool(kind, texture)
	# No work when nothing was delivered: the layer still exists and stays at zero cost.
	set_process(not _pools.is_empty())


func _build_pool(kind: StringName, texture: Texture2D) -> void:
	var pool: Array[Slot] = []
	for i in POOL_PER_SHEET:
		var sprite := Sprite2D.new()
		sprite.name = "Fx%s%d" % [String(kind), i]
		sprite.texture = texture
		sprite.hframes = HFRAMES
		sprite.vframes = VFRAMES
		sprite.frame = 0
		sprite.centered = true
		sprite.scale = Vector2(DRAW_SCALE, DRAW_SCALE)
		sprite.material = _material
		sprite.visible = false
		add_child(sprite)
		var slot := Slot.new()
		slot.sprite = sprite
		pool.append(slot)
	_pools[kind] = pool
	_plays[kind] = 0


## Play `kind` over `world_pos` (a 3D world point, e.g. an impact height). Returns false when
## the sheet is missing or there is no camera to project through — it renders nothing either way.
func play_at_world(kind: StringName, world_pos: Vector3, strength: float = 1.0) -> bool:
	if camera == null or not _pools.has(kind):
		return false
	var pool: Array = _pools[kind]
	var slot: Slot = null
	for candidate in pool:
		if candidate.age < 0.0:
			slot = candidate
			break
	if slot == null:
		# Every slot busy: recycle the one that started earliest. Reuse, never allocate.
		slot = pool[0]
		for candidate in pool:
			if candidate.age > slot.age:
				slot = candidate
	slot.age = 0.0
	slot.sprite.frame = 0
	slot.sprite.visible = true
	slot.sprite.modulate = Color(1.0, 1.0, 1.0, clampf(strength, 0.35, 1.0))
	slot.sprite.position = camera.unproject_position(world_pos)
	_plays[kind] = int(_plays.get(kind, 0)) + 1
	return true


func _process(delta: float) -> void:
	for kind in _pools:
		for slot in _pools[kind]:
			if slot.age < 0.0:
				continue
			slot.age += delta
			var frame := int(slot.age * PLAYBACK_FPS)
			if frame >= FRAME_COUNT:
				slot.age = -1.0
				slot.sprite.visible = false
			else:
				slot.sprite.frame = frame


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
			if slot.age >= 0.0:
				n += 1
	return n


func play_count(kind: StringName) -> int:
	return int(_plays.get(kind, 0))

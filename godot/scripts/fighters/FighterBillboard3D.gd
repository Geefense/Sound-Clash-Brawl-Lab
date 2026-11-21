class_name FighterBillboard3D
extends Node3D
## 2.5D fallback for a roster entry with no 3D upload (L!kkle Moore, AGENTS.md §9 item 43).
##
## The fighter's existing `AnimatedSprite2D` is hidden by `BaseFighter.set_3d_presentation()`
## and its current frame is mirrored onto a camera-facing `Sprite3D` on the 3D fighting plane.
## That keeps the approved sprite art, the y 592 sole alignment and the whole shared FSM,
## while the arena, lights, camera and impact notes are true 3D. When his `.glb` arrives he
## moves to `FighterModel3D` with no combat change.

const PX_PER_M := 140.0
## Adult 3D models are authored at 1.55 m; the billboard keeps the roster's relative scale
## (L!kkle Moore is 82 % of an adult) instead of inheriting the 2D framing.
const ADULT_HEIGHT := 1.55

var fighter: BaseFighter = null
var sprite: Sprite3D = null
var triangles: int = 0
var model_height: float = 0.0
var _texture: Texture2D = null
var _anim: StringName = &""
var _frame: int = -1
var _flip: bool = false


func bind(target: BaseFighter, _key: StringName = &"") -> bool:
	fighter = target
	sprite = Sprite3D.new()
	sprite.name = "FighterBillboard"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.double_sided = true
	sprite.transparent = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.22
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.centered = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sprite)
	_refresh(true)
	return sprite.texture != null


func describe() -> Dictionary:
	return {
		"key": String(fighter.fighter_key) if fighter != null else "",
		"triangles": 2,
		"bones": 0,
		"rigged": false,
		"height": model_height,
		"billboard": true,
	}


func triangle_count() -> int:
	return triangles


func model_source_label() -> String:
	return "2D sprite billboard (no 3D upload yet)"


func _process(_delta: float) -> void:
	_refresh(false)


func _refresh(force: bool) -> void:
	if fighter == null or sprite == null or fighter.sprite == null:
		return
	var frames := fighter.sprite.sprite_frames
	if frames == null:
		return
	var anim := fighter.sprite.animation
	var frame := fighter.sprite.frame
	var flip := fighter.facing < 0
	if not force and anim == _anim and frame == _frame and flip == _flip:
		return
	_anim = anim
	_frame = frame
	_flip = flip
	var texture := frames.get_frame_texture(anim, frame)
	if texture == null:
		return
	sprite.texture = texture
	sprite.flip_h = flip
	# Normalise to the 3D plane instead of the old 2D camera framing: the roster's relative
	# stand height decides the target, so the kid stays visibly smaller than an adult.
	var relative := clampf(float(fighter.stand_size.y) / 160.0, 0.5, 1.25)
	model_height = ADULT_HEIGHT * relative
	sprite.pixel_size = model_height / maxf(float(texture.get_height()), 1.0)
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	_texture = texture

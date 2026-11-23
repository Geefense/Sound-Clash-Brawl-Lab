class_name SilhouetteArt
extends RefCounted
## Procedural silhouette art for the 2.5D crowd and DJ layers (owner playtest, 2026-11-23).
##
## The capsule/cylinder stand-in mannequins are gone. Every spectator and DJ is now one
## camera-facing quad wearing `silhouette_mask.gdshader`, and this class paints the mask it
## samples: a body coverage channel and a slightly dilated rim channel, both from signed
## distance fields of simple 2D strokes (capsules, ellipses, boxes).
##
## Why procedural instead of a new art file: it keeps the repository free of placeholder
## character art, costs a few kilobytes of code, and can be replaced the moment real
## Mixamo `.fbx` characters land in `assets/models/crowd/` and `assets/models/dj/` (see
## `CharacterModelSlots`). Nothing here touches the fight, the beat clock or the audio.
##
## Cost: one 96 x 192 RGBA mask per (set, variant, pose) — 22 in total — each built once
## and cached, so a Chromebook pays a few milliseconds at start-up and nothing per frame.
## Every pose of a variant shares the body geometry; only the arms and the headwear differ.

const MASK_SHADER := preload("res://assets/shaders/silhouette_mask.gdshader")

const W := 96
const H := 192
## How far the rim band reaches outside the contour, in mask pixels.
const RIM_PX := 2.6
const BODY_COLOUR := Color(0.055, 0.05, 0.07, 1.0)
const DEFAULT_RIM := Color(1.0, 0.74, 0.34, 1.0)

const CROWD_POSES := [&"idle", &"cheer", &"disbelief", &"hype"]
const DJ_POSES := [&"idle", &"fader", &"point", &"airhorn", &"celebrate"]

static var _textures: Dictionary = {}
static var _materials: Dictionary = {}
static var _rim: Color = DEFAULT_RIM
static var _rim_strength: float = 0.9


# =========================================================================
# Public API
# =========================================================================
## The one shared-per-pose material a silhouette quad wears. Materials are cached by
## (set, variant, pose) because a ShaderMaterial carries one mask texture.
static func material_for(set_name: String, variant: int, pose: StringName) -> ShaderMaterial:
	var key := _key(set_name, variant, pose)
	if _materials.has(key):
		return _materials[key]
	var mat := ShaderMaterial.new()
	mat.shader = MASK_SHADER
	mat.set_shader_parameter("mask_tex", mask_texture(set_name, variant, pose))
	mat.set_shader_parameter("body_colour", BODY_COLOUR)
	mat.set_shader_parameter("rim_colour", _rim)
	mat.set_shader_parameter("rim_strength", _rim_strength)
	mat.set_shader_parameter("rim_power", 1.7)
	mat.set_shader_parameter("rim_energy", 0.55)
	mat.set_shader_parameter("alpha_mul", 1.0)
	_materials[key] = mat
	return mat


## Phase palette: repaint every silhouette in one pass. A material created after this call
## already carries the current rim colour.
static func set_palette(rim: Color, strength: float) -> void:
	_rim = rim
	_rim_strength = clampf(strength, 0.15, 2.6)
	for value in _materials.values():
		var mat: ShaderMaterial = value
		mat.set_shader_parameter("rim_colour", _rim)
		mat.set_shader_parameter("rim_strength", _rim_strength)


static func mask_texture(set_name: String, variant: int, pose: StringName) -> ImageTexture:
	var key := _key(set_name, variant, pose)
	if _textures.has(key):
		return _textures[key]
	var texture := ImageTexture.create_from_image(_build_image(set_name, variant, pose))
	_textures[key] = texture
	return texture


static func texture_count() -> int:
	return _textures.size()


static func material_count() -> int:
	return _materials.size()


static func has_pose(set_name: String, pose: StringName) -> bool:
	return pose in (DJ_POSES if set_name == "dj" else CROWD_POSES)


# =========================================================================
# Painting
# =========================================================================
static func _key(set_name: String, variant: int, pose: StringName) -> String:
	return "%s/%d/%s" % [set_name, variant, pose]


static func _build_image(set_name: String, variant: int, pose: StringName) -> Image:
	var prims: Array = []
	_body(prims, variant)
	if set_name == "dj":
		_dj_arms(prims, pose)
	else:
		_crowd_arms(prims, pose)
	_headwear(prims, variant)
	return _rasterize(prims)


## Shared body: two legs, feet, hips, torso, shoulders and a head. Variants shift the
## stance width a little so the bank does not read as one person copied 20 times.
static func _body(prims: Array, variant: int) -> void:
	var widen := 1.0 + float(variant % 3) * 0.055
	var stride := float(variant % 3) * 1.4
	prims.append(_seg(42.0 - stride, 112.0, 43.0, 170.0, 6.4))
	prims.append(_seg(54.0 + stride, 112.0, 53.0, 170.0, 6.4))
	prims.append(_ell(41.0 - stride, 176.0, 8.5, 5.0))
	prims.append(_ell(56.0 + stride, 176.0, 8.5, 5.0))
	prims.append(_ell(48.0, 111.0, 15.0 * widen, 10.0))
	prims.append(_seg(48.0, 64.0, 48.0, 108.0, 14.2 * widen))
	prims.append(_ell(48.0, 60.0, 16.5 * widen, 7.0))
	prims.append(_seg(48.0, 44.0, 48.0, 52.0, 5.0))
	prims.append(_ell(48.0, 32.0, 10.5, 12.5))


## Crowd acting: neutral skank, both hands up, hands on head, or one arm punched up.
static func _crowd_arms(prims: Array, pose: StringName) -> void:
	match pose:
		&"cheer":
			prims.append(_seg(35.0, 64.0, 25.0, 42.0, 5.0))
			prims.append(_seg(25.0, 42.0, 21.0, 18.0, 4.6))
			prims.append(_ell(21.0, 15.0, 4.4, 4.4))
			prims.append(_seg(61.0, 64.0, 71.0, 42.0, 5.0))
			prims.append(_seg(71.0, 42.0, 75.0, 18.0, 4.6))
			prims.append(_ell(75.0, 15.0, 4.4, 4.4))
		&"disbelief":
			# Both hands clapped on the head: the rival corner watching a knockdown.
			prims.append(_seg(35.0, 64.0, 25.0, 44.0, 5.0))
			prims.append(_seg(25.0, 44.0, 39.0, 24.0, 4.6))
			prims.append(_ell(41.0, 21.0, 4.4, 4.4))
			prims.append(_seg(61.0, 64.0, 71.0, 44.0, 5.0))
			prims.append(_seg(71.0, 44.0, 57.0, 24.0, 4.6))
			prims.append(_ell(55.0, 21.0, 4.4, 4.4))
		&"hype":
			# Lighter/flag hand punched high, other arm out for balance.
			prims.append(_seg(61.0, 64.0, 68.0, 38.0, 5.0))
			prims.append(_seg(68.0, 38.0, 66.0, 12.0, 4.6))
			prims.append(_ell(66.0, 9.0, 4.4, 4.4))
			prims.append(_seg(35.0, 64.0, 24.0, 74.0, 5.0))
			prims.append(_seg(24.0, 74.0, 14.0, 82.0, 4.6))
			prims.append(_ell(12.0, 84.0, 4.4, 4.4))
		_:
			# Neutral skank: hands loose at the waist, weight on both feet.
			prims.append(_seg(35.0, 64.0, 30.0, 90.0, 5.0))
			prims.append(_seg(30.0, 90.0, 32.0, 114.0, 4.6))
			prims.append(_ell(32.0, 117.0, 4.4, 4.4))
			prims.append(_seg(61.0, 64.0, 66.0, 90.0, 5.0))
			prims.append(_seg(66.0, 90.0, 64.0, 114.0, 4.6))
			prims.append(_ell(64.0, 117.0, 4.4, 4.4))


## DJ acting: riding the faders, pointing at the fighters, horn up, or both arms up.
static func _dj_arms(prims: Array, pose: StringName) -> void:
	match pose:
		&"fader":
			# Right hand down over the mixer, left hand loose by the channel faders.
			prims.append(_seg(61.0, 64.0, 70.0, 86.0, 5.0))
			prims.append(_seg(70.0, 86.0, 58.0, 104.0, 4.6))
			prims.append(_ell(56.0, 107.0, 4.6, 4.0))
			prims.append(_seg(35.0, 64.0, 41.0, 88.0, 5.0))
			prims.append(_seg(41.0, 88.0, 38.0, 108.0, 4.6))
			prims.append(_ell(38.0, 111.0, 4.6, 4.0))
		&"point":
			# Left arm straight out at whoever just connected.
			prims.append(_seg(35.0, 64.0, 20.0, 70.0, 5.0))
			prims.append(_seg(20.0, 70.0, 7.0, 71.0, 4.6))
			prims.append(_ell(4.0, 71.0, 4.0, 4.0))
			prims.append(_seg(61.0, 64.0, 55.0, 84.0, 5.0))
			prims.append(_seg(55.0, 84.0, 44.0, 96.0, 4.6))
			prims.append(_ell(42.0, 99.0, 4.6, 4.0))
		&"airhorn":
			# Horn hand up beside the head; the other keeps the record steady.
			prims.append(_seg(61.0, 64.0, 70.0, 44.0, 5.0))
			prims.append(_seg(70.0, 44.0, 66.0, 24.0, 4.6))
			prims.append(_ell(66.0, 21.0, 4.4, 4.4))
			prims.append(_seg(35.0, 64.0, 40.0, 88.0, 5.0))
			prims.append(_seg(40.0, 88.0, 38.0, 108.0, 4.6))
			prims.append(_ell(38.0, 111.0, 4.6, 4.0))
		&"celebrate":
			prims.append(_seg(35.0, 64.0, 24.0, 40.0, 5.0))
			prims.append(_seg(24.0, 40.0, 20.0, 14.0, 4.6))
			prims.append(_ell(20.0, 11.0, 4.4, 4.4))
			prims.append(_seg(61.0, 64.0, 72.0, 40.0, 5.0))
			prims.append(_seg(72.0, 40.0, 76.0, 14.0, 4.6))
			prims.append(_ell(76.0, 11.0, 4.4, 4.4))
		_:
			# Neutral: both hands resting on the deck, head nodding.
			prims.append(_seg(35.0, 64.0, 32.0, 90.0, 5.0))
			prims.append(_seg(32.0, 90.0, 34.0, 110.0, 4.6))
			prims.append(_ell(34.0, 113.0, 4.6, 4.0))
			prims.append(_seg(61.0, 64.0, 64.0, 90.0, 5.0))
			prims.append(_seg(64.0, 90.0, 62.0, 110.0, 4.6))
			prims.append(_ell(62.0, 113.0, 4.6, 4.0))


## Bucket hat, headwrap with a knot, or hanging locks — silhouette variety with no new art.
static func _headwear(prims: Array, variant: int) -> void:
	match variant % 3:
		0:
			prims.append(_ell(48.0, 22.0, 18.0, 4.0))
			prims.append(_ell(48.0, 15.5, 11.5, 7.0))
		1:
			prims.append(_ell(48.0, 23.0, 12.5, 6.5))
			prims.append(_box(61.0, 21.0, 3.0, 3.0))
		_:
			for i in 5:
				prims.append(_seg(38.0 + float(i) * 5.0, 38.0,
					35.0 + float(i) * 6.5, 64.0, 2.2))
			prims.append(_ell(48.0, 22.0, 11.5, 5.5))


# =========================================================================
# Rasterizer: signed distance strokes → one RGBA mask
# =========================================================================
static func _seg(ax: float, ay: float, bx: float, by: float, radius: float) -> Array:
	return [0, Vector2(ax, ay), Vector2(bx, by), Vector2(radius, radius)]


static func _ell(cx: float, cy: float, rx: float, ry: float) -> Array:
	return [1, Vector2(cx, cy), Vector2(cx, cy), Vector2(rx, ry)]


static func _box(cx: float, cy: float, hx: float, hy: float) -> Array:
	return [2, Vector2(cx, cy), Vector2(cx, cy), Vector2(hx, hy)]


static func _rasterize(prims: Array) -> Image:
	var dist := PackedFloat32Array()
	dist.resize(W * H)
	dist.fill(9999.0)
	for prim in prims:
		var kind: int = int(prim[0])
		var a: Vector2 = prim[1]
		var b: Vector2 = prim[2]
		var r: Vector2 = prim[3]
		var pad := maxf(r.x, r.y) + 2.0
		var min_x := clampi(int(floor(minf(a.x, b.x) - pad)), 0, W - 1)
		var max_x := clampi(int(ceil(maxf(a.x, b.x) + pad)), 0, W - 1)
		var min_y := clampi(int(floor(minf(a.y, b.y) - pad)), 0, H - 1)
		var max_y := clampi(int(ceil(maxf(a.y, b.y) + pad)), 0, H - 1)
		for py in range(min_y, max_y + 1):
			var row := py * W
			for px in range(min_x, max_x + 1):
				var p := Vector2(float(px) + 0.5, float(py) + 0.5)
				var d := 9999.0
				match kind:
					0:
						var ab := b - a
						var t := 0.0
						if ab.length_squared() > 0.0001:
							t = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
						d = (p - (a + ab * t)).length() - r.x
					1:
						var q := (p - a) / Vector2(maxf(r.x, 0.001), maxf(r.y, 0.001))
						d = (q.length() - 1.0) * minf(r.x, r.y)
					_:
						var e := (p - a).abs() - r
						d = e.length() + minf(maxf(e.x, e.y), 0.0)
				var index := row + px
				if d < dist[index]:
					dist[index] = d
	return _pack(dist)


## Two anti-aliased channels: G = body coverage, R = the dilated rim band the shader reads.
static func _pack(dist: PackedFloat32Array) -> Image:
	var bytes := PackedByteArray()
	bytes.resize(W * H * 4)
	for i in W * H:
		var d := dist[i]
		var body := clampf((0.9 - d) / 1.8, 0.0, 1.0)
		var rim := clampf((RIM_PX + 0.9 - d) / 1.8, 0.0, 1.0)
		var at := i * 4
		bytes[at] = int(round(rim * 255.0))
		bytes[at + 1] = int(round(body * 255.0))
		bytes[at + 2] = 0
		bytes[at + 3] = 255
	return Image.create_from_data(W, H, false, Image.FORMAT_RGBA8, bytes)

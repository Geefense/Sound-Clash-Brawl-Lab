extends Node3D
## Sprite Stage Test — illustrated Feedback on the current 3D beach stage (preview only).
##
## THE LOOP (the checkpoint this file exists for): idle → two steps → BOX → guard → short
## pause, FX off, at the fight-camera distance, one fixed-Y billboard `Sprite3D` standing on
## the sand at the fighters' z 0 plane. Diagnostics (stage/camera/shadow/lighting/footwork/
## presentation filters, frame stepping, ghost, contact-sheet capture) hang off the same
## object; nothing here is referenced by the match.
##
## Reuse, not a second stage: the whole set is the shipped `Arena3D` — illustrated backdrop,
## sand, lights, booth, speakers, the three time-of-day presets — built once by its own
## `_ready()`. This script then freezes the arena's own `_process` (so its camera cannot fight
## the test camera) and owns only the preview actor's root x, the camera and the shadow.
##
## Units: the arena's 140 px = 1 m, floor line at 2D y 600 = world y 0. The billboard's
## `pixel_size` is ONE global number derived from the live 3D Feedback's measured idle height,
## so disagreement between the illustrated sets shows up instead of being normalised away.
##
## No per-frame allocations: textures are loaded once, the timeline is packed arrays, and the
## per-frame path is adds and transform writes. The HUD string is rebuilt only when the
## displayed frame or the sampled tick changes (≈10 Hz at most), never every frame.

const FRAME_DIR := "res://assets/sprites/legacy_feedback/"
## Preloaded, not a global `class_name`: the production export drops both files, and a
## `class_name` would leave the test helper registered in the shared global class cache.
const HUD_SCRIPT := preload("res://scripts/sprite_test/SpriteStageHud.gd")

## Live-measured reference, `tools/sprite_stage_metrics.gd` (2026-11-28):
##   `FighterModel3D.measured_height()` on the real TestArena p1 = 1.542 m
##   illustrated idle alpha bbox height (alpha >= 0.22) = 488 px
const REFERENCE_HEIGHT_M := 1.542
const IDLE_FIGURE_PX := 488.0
const PIXEL_SIZE := REFERENCE_HEIGHT_M / IDLE_FIGURE_PX     # 0.003160 m/px

## The preview actor's own speed only. Authored = boot separation at CONTACT (246.0 px mean)
## over one 132 BPM beat; measured = the least-squares slide-minimising speed over the four
## support intervals. Both land on 1.623 m/s in this art (per-interval 1.14 … 2.12 m/s), which
## is exactly why the manual option exists.
const AUTHORED_SPEED := 1.623
const MEASURED_SPEED := 1.623

const FIGHT_FOV := 30.0
const FIGHT_DISTANCE := 4.10
const FIGHT_HEIGHT := 1.0
## Long lens: the same vertical framing at 16°, so the fighter keeps its screen height.
const LONG_FOV := 16.0
const LONG_DISTANCE := 7.8206
## Orthographic: `size` = the same visible height at the fight plane.
const ORTHO_SIZE := 2.1971

const WALK_WRAP_M := 3.0

const FRAMES := [
	{"name": "idle", "index": 0, "file": "idle_01.png", "pivot": Vector2(768.0, 900.0), "hold": 0.4545, "walk": false},
	{"name": "walk", "index": 0, "file": "walk_01_contact_a.png", "pivot": Vector2(229.7, 566.0), "hold": 0.2273, "walk": true},
	{"name": "walk", "index": 1, "file": "walk_02_pass_a.png", "pivot": Vector2(229.7, 566.0), "hold": 0.2273, "walk": true},
	{"name": "walk", "index": 2, "file": "walk_03_contact_b.png", "pivot": Vector2(229.7, 566.0), "hold": 0.2273, "walk": true},
	{"name": "walk", "index": 3, "file": "walk_04_pass_b.png", "pivot": Vector2(229.7, 566.0), "hold": 0.2273, "walk": true},
	{"name": "box", "index": 0, "file": "box_01_windup.png", "pivot": Vector2(768.0, 900.0), "hold": 0.1500, "walk": false},
	{"name": "box", "index": 1, "file": "box_02_contact.png", "pivot": Vector2(768.0, 900.0), "hold": 0.0667, "walk": false},
	{"name": "box", "index": 2, "file": "box_03_followthrough.png", "pivot": Vector2(768.0, 900.0), "hold": 0.3000, "walk": false},
	{"name": "guard", "index": 0, "file": "guard_01.png", "pivot": Vector2(768.0, 900.0), "hold": 0.2273, "walk": false},
	{"name": "pause", "index": 0, "file": "guard_01.png", "pivot": Vector2(768.0, 900.0), "hold": 0.1136, "walk": false},
]

enum StageMode { BEACH, FLAT }
enum CameraMode { FIGHT, LONG, ORTHO }
enum ShadowMode { NONE, CAST, ELLIPSE }
enum Footwork { AUTHORED, MEASURED, MANUAL }
enum TintMode { UNSHADED, PRESET }

var arena: Arena3D = null
var camera: Camera3D = null
var actor: Node3D = null
var sprite: Sprite3D = null
var ghost: Sprite3D = null
var ellipse: MeshInstance3D = null
var hud = null

var stage_mode: StageMode = StageMode.BEACH
var booth_on: bool = false
var speakers_on: bool = false
var camera_mode: CameraMode = CameraMode.FIGHT
var shadow_mode: ShadowMode = ShadowMode.ELLIPSE
var light_mode: int = 0
var footwork: Footwork = Footwork.AUTHORED
var manual_speed: float = 1.62
var tint_mode: TintMode = TintMode.UNSHADED
var flip_p2: bool = false
var nearest_filter: bool = false
var paused: bool = false
var slow_motion: bool = false
var ghost_on: bool = false
var ellipse_offset: float = 0.0
var ellipse_size: float = 0.45
var ellipse_opacity: float = 0.55

var tick: int = 0
var loop_seconds: float = 0.0
var root_x: float = 0.0

var _textures: Array[Texture2D] = []
var _durations: PackedFloat32Array = PackedFloat32Array()
var _walk_flags: PackedByteArray = PackedByteArray()
var _pivots: Array[Vector2] = []
var _labels: PackedStringArray = PackedStringArray()
var _cursor: int = 0
var _frame_age: float = 0.0
var _shown_tick: int = -1
var _shown_label: String = ""
var _speed_now: float = 0.0
var _sheet_texture: ImageTexture = null
var _sheet_note: String = ""


func _ready() -> void:
	_build_timeline()
	_build_stage()
	_build_actor()
	_build_shadow()
	_build_camera()
	_build_hud()
	_set_frame(0, true)
	_apply_stage_mode()
	_apply_lighting()
	_apply_camera_mode()
	_apply_shadow_mode()
	_apply_presentation()
	if hud != null:
		hud.refresh()


# ---------------------------------------------------------------- construction
func _build_timeline() -> void:
	for spec in FRAMES:
		var tex := load(FRAME_DIR + String(spec["file"])) as Texture2D
		if tex == null:
			push_warning("SpriteStageTest: missing frame %s" % spec["file"])
			tex = PlaceholderTexture2D.new()
		_textures.append(tex)
		_durations.append(float(spec["hold"]))
		_walk_flags.append(1 if spec["walk"] else 0)
		_pivots.append(spec["pivot"])
		_labels.append("%s %d" % [spec["name"], int(spec["index"])])
		loop_seconds += float(spec["hold"])


## The shipped beach stage, built exactly as a match builds it (`Arena3D._ready`). Its own
## `_process` is then frozen: the match camera follows two fighters that do not exist here, and
## it would overwrite the test lens every frame.
func _build_stage() -> void:
	arena = Arena3D.new()
	arena.name = "Arena3D"
	arena.stage_props_enabled = false
	add_child(arena)
	arena.set_process(false)
	arena.set_booth_visible(booth_on)
	arena.set_speakers_visible(speakers_on)
	camera = arena.camera


func _build_actor() -> void:
	actor = Node3D.new()
	actor.name = "SpriteActor"
	add_child(actor)

	ghost = Sprite3D.new()
	ghost.name = "GhostFrame"
	_style_sprite(ghost)
	ghost.modulate = Color(1, 1, 1, 0.3)
	ghost.visible = false
	ghost.position = Vector3(0.0, 0.0, -0.004)
	actor.add_child(ghost)

	sprite = Sprite3D.new()
	sprite.name = "Feedback"
	_style_sprite(sprite)
	actor.add_child(sprite)


func _style_sprite(s: Sprite3D) -> void:
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.double_sided = true
	s.transparent = true
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.alpha_scissor_threshold = 0.22
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	s.centered = false
	s.pixel_size = PIXEL_SIZE
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Test-only soft ground contact ellipse (the same `contact_shadow` shader the arena's own
## fighter shadows use). Sliders drive offset, size and opacity.
func _build_shadow() -> void:
	ellipse = MeshInstance3D.new()
	ellipse.name = "TestContactEllipse"
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	ellipse.mesh = quad
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/contact_shadow.gdshader")
	mat.set_shader_parameter("opacity", ellipse_opacity)
	ellipse.material_override = mat
	ellipse.rotation.x = -PI * 0.5
	ellipse.position = Vector3(0.0, 0.006, 0.12)
	ellipse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ellipse)
	_apply_ellipse()


func _build_camera() -> void:
	if camera == null:
		camera = Camera3D.new()
		camera.name = "StageCamera"
		camera.far = 90.0
		add_child(camera)
	camera.current = true
	camera.fov = FIGHT_FOV
	camera.near = 0.05
	camera.far = 90.0
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	camera.position = Vector3(0.0, FIGHT_HEIGHT, FIGHT_DISTANCE)
	camera.rotation = Vector3.ZERO


func _build_hud() -> void:
	hud = HUD_SCRIPT.new()
	hud.name = "PreviewHud"
	hud.stage = self
	add_child(hud)


# ---------------------------------------------------------------- playback
func _process(delta: float) -> void:
	if paused:
		return
	var rate := 0.25 if slow_motion else 1.0
	var dt := delta * rate
	_frame_age += dt

	var guard := 0
	while _frame_age >= _durations[_cursor]:
		_frame_age -= _durations[_cursor]
		_cursor = (_cursor + 1) % _durations.size()
		guard += 1
		if _cursor == 0:
			root_x = 0.0
			tick = 0
		_set_frame(_cursor, false)
		if guard > 8:
			break

	# The preview actor's own displacement — never BaseFighter's. Only walk frames travel.
	_speed_now = _current_speed()
	if _speed_now != 0.0 and _walk_flags[_cursor] == 1:
		root_x += _speed_now * dt
		if absf(root_x) > WALK_WRAP_M:
			root_x = -WALK_WRAP_M      # cut, not a slide: the loop restarts from the left
	actor.position.x = root_x
	if camera != null:
		camera.position.x = root_x
	if ellipse != null:
		ellipse.position.x = root_x + ellipse_offset

	tick += int(round(dt * 60.0))
	_refresh_hud_throttled()


## The frame swap is the only work a new frame costs: one texture reference, two offsets, and
## the outgoing frame handed to the ghost. No allocation.
func _set_frame(index: int, force: bool) -> void:
	if sprite == null:
		return
	var tex := _textures[index]
	if not force and sprite.texture == tex:
		_shown_label = _labels[index]
		return
	if ghost != null and sprite.texture != null:
		ghost.texture = sprite.texture
		ghost.offset = sprite.offset
	sprite.texture = tex
	sprite.offset = Vector2(-_pivots[index].x, -_pivots[index].y)
	_shown_label = _labels[index]


func _refresh_hud_throttled() -> void:
	if hud == null:
		return
	# One string rebuild per displayed tick sample, never per frame: the tick readout is
	# sampled at ~10 Hz and the frame label changes at most 10 times per loop.
	if tick == _shown_tick or tick % 6 != 0:
		return
	_shown_tick = tick
	hud.refresh_status(_status_line())


func _status_line() -> String:
	var speed := _current_speed()
	return "%s · tick %d · %s · %s · speed %.2f m/s · loop %.2f s%s" % [
		_shown_label, tick, _camera_label(), _shadow_label(), speed, loop_seconds,
		" · PAUSED" if paused else (" · 0.25×" if slow_motion else ""),
	]


func _current_speed() -> float:
	match footwork:
		Footwork.MEASURED:
			return MEASURED_SPEED
		Footwork.MANUAL:
			return manual_speed
		_:
			return AUTHORED_SPEED


# ---------------------------------------------------------------- controls
func toggle_stage() -> void:
	stage_mode = StageMode.FLAT if stage_mode == StageMode.BEACH else StageMode.BEACH
	_apply_stage_mode()
	_refresh_hud()


func toggle_booth() -> void:
	booth_on = not booth_on
	if arena != null:
		arena.set_booth_visible(booth_on)
	_refresh_hud()


func toggle_speakers() -> void:
	speakers_on = not speakers_on
	if arena != null:
		arena.set_speakers_visible(speakers_on)
	_refresh_hud()


func cycle_camera() -> void:
	camera_mode = ((int(camera_mode) + 1) % 3) as CameraMode
	_apply_camera_mode()
	_refresh_hud()


func cycle_shadow() -> void:
	shadow_mode = ((int(shadow_mode) + 1) % 3) as ShadowMode
	_apply_shadow_mode()
	_refresh_hud()


func cycle_light() -> void:
	light_mode = (light_mode + 1) % 3
	_apply_lighting()
	_refresh_hud()


func cycle_footwork() -> void:
	footwork = ((int(footwork) + 1) % 3) as Footwork
	_refresh_hud()


func set_manual_speed(value: float) -> void:
	manual_speed = value
	footwork = Footwork.MANUAL
	_refresh_hud()


func cycle_tint() -> void:
	tint_mode = TintMode.PRESET if tint_mode == TintMode.UNSHADED else TintMode.UNSHADED
	_apply_presentation()
	_refresh_hud()


func toggle_flip() -> void:
	flip_p2 = not flip_p2
	if sprite != null:
		sprite.flip_h = flip_p2
	if ghost != null:
		ghost.flip_h = flip_p2
	_refresh_hud()


func toggle_filter() -> void:
	nearest_filter = not nearest_filter
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST if nearest_filter \
		else BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if ghost != null:
		ghost.texture_filter = sprite.texture_filter
	_refresh_hud()


func toggle_pause() -> void:
	paused = not paused
	_refresh_hud()


func toggle_speed() -> void:
	slow_motion = not slow_motion
	_refresh_hud()


func step_frame(direction: int) -> void:
	paused = true
	_cursor = posmod(_cursor + direction, _durations.size())
	_frame_age = 0.0
	tick = 0
	_set_frame(_cursor, false)
	_shown_tick = -1
	_refresh_hud()
	hud.refresh_status(_status_line())


func toggle_ghost() -> void:
	ghost_on = not ghost_on
	if ghost != null:
		ghost.visible = ghost_on
	_refresh_hud()


func set_ellipse_offset(value: float) -> void:
	ellipse_offset = value
	_apply_ellipse()
	_refresh_hud()


func set_ellipse_size(value: float) -> void:
	ellipse_size = value
	_apply_ellipse()


func set_ellipse_opacity(value: float) -> void:
	ellipse_opacity = value
	_apply_ellipse()


## On demand only (never in the playback path): compose a PNG strip of every frame in the
## loop, show it in the preview and write it to `user://`. On the Web build `user://` is the
## browser's IndexedDB-backed virtual filesystem — the strip always shows, but the file is not
## a downloads-folder file, so the preview path is the reliable one there.
func capture_sheet() -> void:
	var cell_h := 160
	var gap := 4
	var cells: Array[Image] = []
	var width := 0
	for i in _textures.size():
		var img := _textures[i].get_image()
		if img == null or img.is_empty():
			continue
		var scale := float(cell_h) / float(img.get_height())
		var w := maxi(int(round(float(img.get_width()) * scale)), 1)
		img.resize(w, cell_h, Image.INTERPOLATE_NEAREST)
		cells.append(img)
		width += w + gap
	if cells.is_empty():
		_sheet_note = "CAPTURE FAILED · no frame images"
		_refresh_hud()
		return
	width += gap
	var strip := Image.create(width, cell_h + 2 * gap, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0.07, 0.06, 0.09, 1.0))
	var x := gap
	for img in cells:
		strip.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, gap))
		x += img.get_width() + gap
	_sheet_texture = ImageTexture.create_from_image(strip)
	var err := strip.save_png("user://sprite_stage_contact.png")
	_sheet_note = "CONTACT SHEET · %d frames · %d×%d px · user://sprite_stage_contact.png (%s)" % [
		cells.size(), strip.get_width(), strip.get_height(), "ok" if err == OK else "error %d" % err,
	]
	if hud != null:
		hud.show_sheet(_sheet_texture, _sheet_note)
	_refresh_hud()


# ---------------------------------------------------------------- apply
func _apply_stage_mode() -> void:
	if arena == null:
		return
	if stage_mode == StageMode.BEACH:
		arena.apply_phase(light_mode)     # a phase re-textures the illustrated quad
	_apply_backdrop()


func _apply_lighting() -> void:
	if arena == null:
		return
	arena.apply_phase(light_mode)
	_apply_backdrop()
	if tint_mode == TintMode.PRESET:
		_apply_presentation()


## One variable: the illustrated quad (and with it the painted sky) on or off. Flat keeps the
## sand, the lights and the booth/speaker gates, so only the backdrop changes.
func _apply_backdrop() -> void:
	if arena == null:
		return
	var beach := stage_mode == StageMode.BEACH
	var sky := arena.get_node_or_null("SkyBackdrop")
	if sky is Node3D:
		(sky as Node3D).visible = beach
	if beach:
		return
	if arena.world_env != null and arena.world_env.environment != null:
		var env := arena.world_env.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.36, 0.36, 0.38)


## Unshaded = the art exactly as authored. Tint = the preset's key and ambient folded into a
## modulate (normalised so the brightest channel stays at 1.0), which keeps the reading stable
## where a shaded billboard's normal would not exist.
func _apply_presentation() -> void:
	if sprite == null:
		return
	if tint_mode == TintMode.UNSHADED:
		sprite.modulate = Color.WHITE
		ghost.modulate = Color(1, 1, 1, 0.3)
		return
	var key := Color.WHITE
	var ambient := Color(0.5, 0.5, 0.5)
	if arena != null and arena.sun != null:
		key = arena.sun.light_color
	var tint := Color(
		key.r * 0.62 + ambient.r * 0.38,
		key.g * 0.62 + ambient.g * 0.38,
		key.b * 0.62 + ambient.b * 0.38, 1.0)
	var peak := maxf(tint.r, maxf(tint.g, tint.b))
	if peak > 0.001:
		tint = Color(tint.r / peak, tint.g / peak, tint.b / peak, 1.0)
	sprite.modulate = tint
	ghost.modulate = Color(tint.r, tint.g, tint.b, 0.3)


func _apply_camera_mode() -> void:
	if camera == null:
		return
	match camera_mode:
		CameraMode.LONG:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = LONG_FOV
			camera.position = Vector3(root_x, FIGHT_HEIGHT, LONG_DISTANCE)
		CameraMode.ORTHO:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = ORTHO_SIZE
			camera.position = Vector3(root_x, FIGHT_HEIGHT, FIGHT_DISTANCE)
		_:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = FIGHT_FOV
			camera.position = Vector3(root_x, FIGHT_HEIGHT, FIGHT_DISTANCE)
	camera.rotation = Vector3.ZERO


func _apply_shadow_mode() -> void:
	if sprite != null:
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON \
			if shadow_mode == ShadowMode.CAST else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if ellipse != null:
		ellipse.visible = shadow_mode == ShadowMode.ELLIPSE


func _apply_ellipse() -> void:
	if ellipse == null:
		return
	ellipse.scale = Vector3(ellipse_size * 2.0, ellipse_size * 2.0 * 0.42, 1.0)
	ellipse.position = Vector3(root_x + ellipse_offset, 0.006, 0.12)
	var mat := ellipse.material_override as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("opacity", ellipse_opacity)


func _refresh_hud() -> void:
	if hud != null:
		hud.refresh()
		hud.refresh_status(_status_line())


func _camera_label() -> String:
	match camera_mode:
		CameraMode.LONG:
			return "camera long 16°"
		CameraMode.ORTHO:
			return "camera ortho"
		_:
			return "camera fight 30°"


func _shadow_label() -> String:
	match shadow_mode:
		ShadowMode.CAST:
			return "shadow cast"
		ShadowMode.NONE:
			return "shadow none"
		_:
			return "shadow ellipse"


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Shortcuts deliberately avoid F4 / F6 / F7 / F8 / F10 (used by the match HUD) and F1 /
	# F3 / F5 / F9 / F11 / F12 (browser and OS). Letters and Space/arrows only.
	match key.keycode:
		KEY_Q: toggle_stage()
		KEY_E: toggle_booth()
		KEY_R: toggle_speakers()
		KEY_C: cycle_camera()
		KEY_V: cycle_shadow()
		KEY_L: cycle_light()
		KEY_F: cycle_footwork()
		KEY_G: cycle_tint()
		KEY_X: toggle_flip()
		KEY_T: toggle_filter()
		KEY_SPACE: toggle_pause()
		KEY_Z: toggle_speed()
		KEY_H: toggle_ghost()
		KEY_P: capture_sheet()
		KEY_LEFT: step_frame(-1)
		KEY_RIGHT: step_frame(1)
		_: return
	get_viewport().set_input_as_handled()

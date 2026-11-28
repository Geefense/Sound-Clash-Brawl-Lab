extends CanvasLayer
## Compact preview HUD for `SpriteStageTest` (preview only). No `class_name`: the production
## export strips this file, and a global class would leave it registered in the shared cache.
##
## Every diagnostic control is an on-screen Button or Slider so the test can be driven by touch
## on a Chromebook or an iPhone; the keyboard shortcut is printed on the button. The panel is
## built ONCE (`_ready`), and `refresh()` / `refresh_status()` only rewrite text, so playback
## never allocates Controls. Shortcuts avoid F4/F6/F7/F8/F10 and the browser's own F-keys.
##
## The status line and the captured contact strip live at the bottom, clear of the fighter's
## head at the fight camera.

const FONT := preload("res://assets/fonts/ChakraPetch-Bold.ttf")

const PANEL := Color(0.05, 0.04, 0.07, 0.84)
const INK := Color(0.96, 0.94, 0.86, 1.0)
const DIM := Color(0.72, 0.70, 0.64, 1.0)
const GOLD := Color(1.0, 0.86, 0.32, 1.0)

var stage: Node = null

var _buttons: Dictionary = {}
var _status: Label = null
var _sheet: TextureRect = null
var _sheet_caption: Label = null


func _ready() -> void:
	layer = 8
	var root := Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := PanelContainer.new()
	panel.name = "Controls"
	panel.position = Vector2(10, 10)
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	panel.add_child(column)

	var title := Label.new()
	title.text = "SPRITE STAGE TEST · illustrated Feedback on the 3D beach"
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", GOLD)
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 2)
	column.add_child(grid)

	_add_button(grid, "stage", "Q")
	_add_button(grid, "booth", "E")
	_add_button(grid, "speakers", "R")
	_add_button(grid, "camera", "C")
	_add_button(grid, "shadow", "V")
	_add_button(grid, "light", "L")
	_add_button(grid, "footwork", "F")
	_add_button(grid, "sprite", "G")
	_add_button(grid, "flip", "X")
	_add_button(grid, "filter", "T")
	_add_button(grid, "pause", "SPACE")
	_add_button(grid, "speed", "Z")
	_add_button(grid, "prev", "←")
	_add_button(grid, "next", "→")
	_add_button(grid, "ghost", "H")
	_add_button(grid, "capture", "P")

	_add_slider(column, "manual speed (m/s)", 0.0, 3.0, 0.01,
		float(stage.get("manual_speed")) if stage != null else 1.62, _on_manual_speed)
	_add_slider(column, "ellipse offset x (m)", -0.6, 0.6, 0.01,
		float(stage.get("ellipse_offset")) if stage != null else 0.0, _on_ellipse_offset)
	_add_slider(column, "ellipse size (m)", 0.15, 1.4, 0.01,
		float(stage.get("ellipse_size")) if stage != null else 0.45, _on_ellipse_size)
	_add_slider(column, "ellipse opacity", 0.0, 1.0, 0.01,
		float(stage.get("ellipse_opacity")) if stage != null else 0.55, _on_ellipse_opacity)

	var legend := Label.new()
	legend.text = "FX OFF · one actor · fight camera. Touch or keys; no F-keys are bound."
	legend.add_theme_font_override("font", FONT)
	legend.add_theme_font_size_override("font_size", 10)
	legend.add_theme_color_override("font_color", DIM)
	column.add_child(legend)

	_status = Label.new()
	_status.name = "Status"
	_status.add_theme_font_override("font", FONT)
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", INK)
	_status.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_status.position = Vector2(12, 700)
	_status.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(_status)

	_sheet = TextureRect.new()
	_sheet.name = "ContactSheet"
	_sheet.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sheet.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_sheet.size = Vector2(640, 90)
	_sheet.position = Vector2(628, 600)
	_sheet.visible = false
	root.add_child(_sheet)

	_sheet_caption = Label.new()
	_sheet_caption.add_theme_font_override("font", FONT)
	_sheet_caption.add_theme_font_size_override("font_size", 10)
	_sheet_caption.add_theme_color_override("font_color", DIM)
	_sheet_caption.position = Vector2(628, 694)
	root.add_child(_sheet_caption)

	refresh()


func _add_button(grid: GridContainer, id: String, key_hint: String) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(164, 22)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 10)
	b.add_theme_color_override("font_color", INK)
	b.pressed.connect(_on_button.bind(id))
	grid.add_child(b)
	_buttons[id] = b


func _add_slider(parent: VBoxContainer, label: String, lo: float, hi: float, step: float,
		initial: float, handler: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var name_label := Label.new()
	name_label.text = label
	name_label.custom_minimum_size = Vector2(132, 0)
	name_label.add_theme_font_override("font", FONT)
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", DIM)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = lo
	slider.max_value = hi
	slider.step = step
	slider.custom_minimum_size = Vector2(150, 18)
	slider.focus_mode = Control.FOCUS_NONE
	# Value first, THEN the signal: setting it must not look like a user drag (that would
	# silently switch footwork to MANUAL on boot).
	slider.value = initial
	slider.value_changed.connect(handler)
	row.add_child(slider)


func _on_button(id: String) -> void:
	if stage == null:
		return
	match id:
		"stage": stage.call("toggle_stage")
		"booth": stage.call("toggle_booth")
		"speakers": stage.call("toggle_speakers")
		"camera": stage.call("cycle_camera")
		"shadow": stage.call("cycle_shadow")
		"light": stage.call("cycle_light")
		"footwork": stage.call("cycle_footwork")
		"sprite": stage.call("cycle_tint")
		"flip": stage.call("toggle_flip")
		"filter": stage.call("toggle_filter")
		"pause": stage.call("toggle_pause")
		"speed": stage.call("toggle_speed")
		"prev": stage.call("step_frame", -1)
		"next": stage.call("step_frame", 1)
		"ghost": stage.call("toggle_ghost")
		"capture": stage.call("capture_sheet")


func _on_manual_speed(v: float) -> void:
	if stage != null:
		stage.call("set_manual_speed", v)


func _on_ellipse_offset(v: float) -> void:
	if stage != null:
		stage.call("set_ellipse_offset", v)


func _on_ellipse_size(v: float) -> void:
	if stage != null:
		stage.call("set_ellipse_size", v)


func _on_ellipse_opacity(v: float) -> void:
	if stage != null:
		stage.call("set_ellipse_opacity", v)


## Rewrite every button label from the controller's state. Called on a setting change only.
func refresh() -> void:
	if stage == null:
		return
	var camera_mode: int = int(stage.get("camera_mode"))
	var shadow_mode: int = int(stage.get("shadow_mode"))
	var footwork: int = int(stage.get("footwork"))
	var tint_mode: int = int(stage.get("tint_mode"))
	var light_mode: int = int(stage.get("light_mode"))
	_set_button("stage", "STAGE: %s" % _pick(stage.get("stage_mode"), ["BEACH", "FLAT"]), "Q")
	_set_button("booth", "BOOTH: %s" % _on_off(stage.get("booth_on")), "E")
	_set_button("speakers", "SPEAKERS: %s" % _on_off(stage.get("speakers_on")), "R")
	_set_button("camera", "CAMERA: %s" % ["FIGHT 30°", "LONG 16°", "ORTHO"][camera_mode], "C")
	_set_button("shadow", "SHADOW: %s" % ["NONE", "CAST", "ELLIPSE"][shadow_mode], "V")
	_set_button("light", "LIGHT: %s" % ["AFTERNOON", "SUNSET", "NIGHT"][light_mode], "L")
	_set_button("footwork", "FOOTWORK: %s" % ["AUTHORED", "MEASURED", "MANUAL"][footwork], "F")
	_set_button("sprite", "SPRITE: %s" % ["UNSHADED", "PRESET TINT"][tint_mode], "G")
	_set_button("flip", "P2 FLIP: %s" % _on_off(stage.get("flip_p2")), "X")
	_set_button("filter", "FILTER: %s" % ["LINEAR", "NEAREST"][1 if stage.get("nearest_filter") else 0], "T")
	_set_button("pause", "PAUSE: %s" % _on_off(stage.get("paused")), "SPACE")
	_set_button("speed", "SPEED: %s" % ["1×", "0.25×"][1 if stage.get("slow_motion") else 0], "Z")
	_set_button("prev", "◀ PREV FRAME", "←")
	_set_button("next", "NEXT FRAME ▶", "→")
	_set_button("ghost", "GHOST 30%%: %s" % _on_off(stage.get("ghost_on")), "H")
	_set_button("capture", "CAPTURE CONTACT SHEET", "P")


func _pick(value: Variant, names: Array) -> String:
	return String(names[clampi(int(value), 0, names.size() - 1)])


func _on_off(value: Variant) -> String:
	return "ON" if bool(value) else "OFF"


func _set_button(id: String, text: String, key_hint: String) -> void:
	var b: Button = _buttons.get(id)
	if b == null:
		return
	b.text = "%s   [%s]" % [text, key_hint]


## Live readout: animation, frame index, tick, camera/shadow, speed, loop length.
func refresh_status(line: String) -> void:
	if _status != null:
		_status.text = line


func show_sheet(texture: Texture2D, caption: String) -> void:
	if _sheet == null:
		return
	_sheet.texture = texture
	_sheet.visible = texture != null
	if _sheet_caption != null:
		_sheet_caption.text = caption

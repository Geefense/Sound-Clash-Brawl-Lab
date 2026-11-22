extends Control
## Arcade title screen and Character & Match Setup (AGENTS.md §9 backlog item B1).
##
## Splash: SOUND CLASH BRAWL — PRESS START / CLICK TO CLASH, Bungee Shade, one key or one
## click to continue. Setup: P1 fighter, P2 opponent, AI style and the Patois subtitle
## toggle, all keyboard-navigable, then ENTER boots TestArena with those choices through
## the MatchSetup autoload. Esc in the arena returns here without losing the selection.
##
## Everything is drawn with primitives plus the project's OFL fonts: no new art is
## introduced, and nothing here touches the FSM, the beat clock or combat.

enum Phase { SPLASH, SETUP }

const FONT_SHADE := preload("res://assets/fonts/BungeeShade-Regular.ttf")
const FONT_INLINE := preload("res://assets/fonts/BungeeInline-Regular.ttf")
const FONT_BUNGEE := preload("res://assets/fonts/Bungee-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ChakraPetch-Bold.ttf")

const ROW_P1 := 0
const ROW_P2 := 1
const ROW_AI := 2
const ROW_SUBTITLES := 3
const ROW_COUNT := 4

const BEAT_TOAST_SECONDS := 2.2

var phase: Phase = Phase.SPLASH
var row: int = ROW_P1
var _beat_toast: String = ""
var _beat_toast_life: float = 0.0


func _ready() -> void:
	# The active beat starts with the screen and keeps the select menu alive. It is faded
	# out again in `_start()` so FIGHT! has no background music under the round sting.
	MusicBed.play_title()
	# Coming back from the arena via Esc skips the splash and keeps the selection.
	if MatchSetup.return_to_setup:
		phase = Phase.SETUP
		MatchSetup.return_to_setup = false
	set_process(true)


func _process(delta: float) -> void:
	if _beat_toast_life > 0.0:
		_beat_toast_life = maxf(0.0, _beat_toast_life - delta)
		if _beat_toast_life == 0.0:
			_beat_toast = ""
	queue_redraw()


## M auditions Beat 1 → Beat 2 → Beat 3 → Off and flashes the current state in the corner,
## so the menu cycle is visible instead of blind (AGENTS.md §9 item 48).
func _audition_beat() -> void:
	MusicBed.cycle()
	_beat_toast = "MUSIC · %s · M TO CYCLE" % MusicBed.label()
	_beat_toast_life = BEAT_TOAST_SECONDS


func beat_toast_text() -> String:
	return _beat_toast


# =========================================================================
# Input
# =========================================================================
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).physical_keycode
	if phase == Phase.SPLASH:
		if key == KEY_ESCAPE:
			return                      # the splash is already the top level
		if key == KEY_M:
			_audition_beat()             # audition without leaving the splash
			return
		_enter_setup()
		return

	match key:
		KEY_ESCAPE:
			phase = Phase.SPLASH
			row = ROW_P1
		KEY_UP, KEY_W:
			row = posmod(row - 1, ROW_COUNT)
		KEY_DOWN, KEY_S:
			row = posmod(row + 1, ROW_COUNT)
		KEY_LEFT, KEY_A:
			_change(-1)
		KEY_RIGHT, KEY_D:
			_change(1)
		KEY_V:
			MatchSetup.toggle_subtitles()
		KEY_M:
			# Audit the three menu beats without leaving Character Select.
			_audition_beat()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_start()
		KEY_Q:
			pass


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return
	if phase == Phase.SPLASH:
		_enter_setup()
		return
	# Clicking a row selects it; clicking the selected row confirms.
	var clicked := _row_at((event as InputEventMouseButton).position)
	if clicked < 0:
		return
	if clicked == row:
		_start()
	else:
		row = clicked


func _enter_setup() -> void:
	phase = Phase.SETUP
	row = ROW_P1
	# Browsers only unlock audio on the first gesture; restart the bed now so the beat is
	# definitely audible the moment Character Select appears.
	MusicBed.play_title()


func _change(dir: int) -> void:
	match row:
		ROW_P1:
			MatchSetup.cycle_p1(dir)
		ROW_P2:
			MatchSetup.cycle_p2(dir)
		ROW_AI:
			MatchSetup.cycle_ai(dir)
		ROW_SUBTITLES:
			MatchSetup.toggle_subtitles()


func _start() -> void:
	MusicBed.stop_for_fight()
	MatchSetup.start_match()


# =========================================================================
# Layout helpers
# =========================================================================
func _panel() -> Rect2:
	return Rect2(Vector2(190, 232), Vector2(900, 316))


func _row_rect(index: int) -> Rect2:
	var panel := _panel()
	return Rect2(Vector2(panel.position.x + 26.0, panel.position.y + 62.0 + index * 56.0),
		Vector2(panel.size.x - 52.0, 46.0))


func _row_at(point: Vector2) -> int:
	for i in ROW_COUNT:
		if _row_rect(i).has_point(point):
			return i
	return -1


func _fit(font: Font, text: String, preferred: int, max_width: float) -> int:
	var size := preferred
	while size > 8:
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			return size
		size -= 1
	return size


## Drop shadow + dark outline + crisp face, the same treatment the HUD uses, so type
## stays readable over the sunset bands.
func _text(pos: Vector2, text: String, font: Font, font_size: int, colour: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	if text == "":
		return
	var outline := maxi(2, int(round(float(font_size) * 0.14)))
	draw_string(font, pos + Vector2(2, 3), text, align, width, font_size,
		Color(0, 0, 0, 0.45 * colour.a))
	draw_string_outline(font, pos, text, align, width, font_size, outline,
		Color(0.04, 0.02, 0.06, 0.9 * colour.a))
	draw_string(font, pos, text, align, width, font_size, colour)


# =========================================================================
# Draw
# =========================================================================
func _draw() -> void:
	var width := size.x
	var height := size.y
	if width < 100.0:
		width = 1280.0
		height = 720.0
	_backdrop(width, height)
	if phase == Phase.SPLASH:
		_draw_splash(width, height)
	else:
		_draw_setup(width, height)
	_draw_beat_toast(width)


## Sunset yard: warm bands top to bottom, a low sun, a dark sand lane and two speaker
## stacks in silhouette. Primitive only.
func _backdrop(width: float, height: float) -> void:
	var bands := 36
	for i in bands:
		var t := float(i) / float(bands - 1)
		var colour := Color(0.20, 0.09, 0.16).lerp(Color(0.86, 0.44, 0.18), t)
		colour = colour.lerp(Color(0.10, 0.06, 0.09), smoothstep(0.62, 1.0, t))
		draw_rect(Rect2(0.0, height * t, width, height / float(bands) + 1.0), colour, true)
	draw_circle(Vector2(width * 0.5, height * 0.52), 190.0, Color(1.0, 0.78, 0.34, 0.16))
	draw_circle(Vector2(width * 0.5, height * 0.52), 120.0, Color(1.0, 0.86, 0.46, 0.22))
	# Sand lane.
	draw_rect(Rect2(0.0, height * 0.82, width, height * 0.18), Color(0.13, 0.09, 0.08, 0.92), true)
	# Speaker stacks left and right.
	for side in [-1.0, 1.0]:
		var x: float = width * 0.5 + side * width * 0.40
		for i in 3:
			var box := Rect2(x - 46.0, height * 0.44 + i * 56.0, 92.0, 50.0)
			draw_rect(box, Color(0.05, 0.04, 0.06, 0.96), true)
			draw_rect(box, Color(0.32, 0.22, 0.16, 0.9), false, 2.0)
			draw_circle(box.position + Vector2(46.0, 25.0), 14.0, Color(0.16, 0.12, 0.12))
			draw_circle(box.position + Vector2(46.0, 25.0), 6.0, Color(0.30, 0.22, 0.16))


func _draw_splash(width: float, height: float) -> void:
	var title_y := height * 0.30
	var l1 := "SOUND CLASH"
	_text(Vector2(0, title_y), l1, FONT_SHADE, _fit(FONT_SHADE, l1, 96, width - 120.0),
		Color(1.0, 0.96, 0.86), HORIZONTAL_ALIGNMENT_CENTER, width)
	var l2 := "BRAWL"
	_text(Vector2(0, title_y + 108.0), l2, FONT_INLINE, _fit(FONT_INLINE, l2, 112, width - 240.0),
		Color(1.0, 0.83, 0.30), HORIZONTAL_ALIGNMENT_CENTER, width)
	var sub := "132 BPM · KINGSTON YARD · 1P VS AI"
	_text(Vector2(0, title_y + 158.0), sub, FONT_BODY, _fit(FONT_BODY, sub, 22, width - 200.0),
		Color(0.94, 0.90, 0.82, 0.9), HORIZONTAL_ALIGNMENT_CENTER, width)

	# Blinking prompt.
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.55 + 0.45 * absf(sin(t * 2.0))
	var prompt := "PRESS START / CLICK TO CLASH"
	_text(Vector2(0, height * 0.70), prompt, FONT_BUNGEE,
		_fit(FONT_BUNGEE, prompt, 34, width - 260.0),
		Color(1.0, 0.99, 0.94, pulse), HORIZONTAL_ALIGNMENT_CENTER, width)
	# Roster line comes from FighterRoster, so the owner's I→! styling rule applies here too
	# and a rename never leaves a stale hard-coded name on the splash.
	var names := PackedStringArray()
	for key in FighterRoster.ORDER:
		names.append(FighterRoster.display_name(key))
	_text(Vector2(0, height * 0.76), " · ".join(names), FONT_BODY, 16,
		Color(0.85, 0.80, 0.74, 0.75), HORIZONTAL_ALIGNMENT_CENTER, width)


func _draw_setup(width: float, height: float) -> void:
	var panel := _panel()
	draw_rect(panel, Color(0.05, 0.04, 0.07, 0.80), true)
	draw_rect(panel, Color(1.0, 0.86, 0.32, 0.55), false, 2.0)

	var header := "CHARACTER & MATCH SETUP"
	_text(Vector2(panel.position.x, panel.position.y - 18.0), header, FONT_INLINE,
		_fit(FONT_INLINE, header, 30, panel.size.x), Color(1.0, 0.92, 0.72))

	_setup_row(ROW_P1, "P1 FIGHTER", FighterRoster.display_name(MatchSetup.p1_fighter))
	_setup_row(ROW_P2, "P2 OPPONENT", FighterRoster.display_name(MatchSetup.p2_fighter))
	_setup_row(ROW_AI, "AI MODE", MatchSetup.ai_mode_name().to_upper())
	_setup_row(ROW_SUBTITLES, "PATOIS SUBTITLES", "ON" if MatchSetup.subtitles else "OFF")

	# Detail line for the highlighted row: fighter stats or the AI style description.
	var detail_y := panel.position.y + panel.size.y - 34.0
	var detail := ""
	if row == ROW_P1 or row == ROW_P2:
		var key: StringName = MatchSetup.p1_fighter if row == ROW_P1 else MatchSetup.p2_fighter
		var data := FighterRoster.profile(key)
		var reach := float(data["reach_bonus"])
		detail = "%s · walk %d · reach %s" % [
			String(data["tagline"]), int(round(float(data["walk_speed"]))),
			("+%d px" % int(reach)) if reach > 0.0 else "standard",
		]
	elif row == ROW_AI:
		detail = "%s · %s" % [MatchSetup.ai_mode_name(), MatchSetup.ai_mode_tag()]
	else:
		detail = "Patois callouts with a deadpan English gloss · V in the arena toggles it"
	_text(Vector2(panel.position.x + 26.0, detail_y), detail, FONT_BODY,
		_fit(FONT_BODY, detail, 16, panel.size.x - 52.0), Color(0.86, 0.86, 0.92, 0.9))

	var footer := "UP/DOWN SELECT · LEFT/RIGHT CHANGE · ENTER FIGHT · V SUBTITLES · ESC BACK"
	_text(Vector2(0, height * 0.915), footer, FONT_BODY,
		_fit(FONT_BODY, footer, 16, width - 80.0),
		Color(0.90, 0.90, 0.95, 0.75), HORIZONTAL_ALIGNMENT_CENTER, width)
	# Menu beat state, so M's audition cycle is visible instead of blind.
	var music_line := "%s · M TO CYCLE" % MusicBed.label()
	_text(Vector2(0, height * 0.958), music_line, FONT_BODY,
		_fit(FONT_BODY, music_line, 14, width - 80.0),
		Color(1.0, 0.86, 0.32, 0.8), HORIZONTAL_ALIGNMENT_CENTER, width)


## Corner label for the M-key beat audition. Both the splash and the select screen use it.
func _draw_beat_toast(width: float) -> void:
	if _beat_toast == "" or _beat_toast_life <= 0.0:
		return
	var fade := clampf(_beat_toast_life / 0.5, 0.0, 1.0)
	var font_size := _fit(FONT_BODY, _beat_toast, 14, 400.0)
	var text_w := FONT_BODY.get_string_size(_beat_toast, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var box_w := clampf(text_w + 30.0, 240.0, 430.0)
	var box := Rect2(Vector2(width - 24.0 - box_w, 24.0), Vector2(box_w, 34.0))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.74 * fade), true)
	draw_rect(box, Color(1.0, 0.86, 0.32, 0.8 * fade), false, 1.0)
	_text(Vector2(box.position.x, box.position.y + 22.0), _beat_toast, FONT_BODY, font_size,
		Color(1.0, 0.92, 0.70, fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)


func _setup_row(index: int, label: String, value: String) -> void:
	var rect := _row_rect(index)
	var selected := index == row
	draw_rect(rect, Color(0.10, 0.08, 0.12, 0.9 if selected else 0.55), true)
	if selected:
		draw_rect(rect, Color(1.0, 0.86, 0.32, 0.95), false, 2.0)
	_text(rect.position + Vector2(16.0, 30.0), label, FONT_BODY, 16,
		Color(1.0, 0.97, 0.88) if selected else Color(0.76, 0.77, 0.84))
	# Value: arrows on the selected row so the control is obvious without a legend.
	var arrows := selected
	var prefix := "◀ " if arrows else ""
	var suffix := " ▶" if arrows else ""
	_text(Vector2(rect.position.x + 300.0, rect.position.y + 32.0), prefix + value + suffix,
		FONT_BUNGEE, _fit(FONT_BUNGEE, value, 20, rect.size.x - 340.0),
		Color(1.0, 0.86, 0.32) if selected else Color(0.92, 0.92, 0.96),
		HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 316.0)

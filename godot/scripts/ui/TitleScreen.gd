extends Control
## Arcade title screen and Character Select (AGENTS.md §9 backlog item B1).
##
## Splash: SOUND CLASH BRAWL — PRESS START / CLICK TO CLASH, Bungee Shade, one key or one
## click to continue.
##
## Select (rebuilt 2026-11-24): **P1 and P2 each own a cursor and their own lock**, with no
## shared "selected" state anywhere. P1 starts on Feedback and P2 on L!ckshot, so the menu
## never opens on a Feedback mirror by accident. Each panel is tagged P1 (gold) or P2 (cyan);
## a locked panel says LOCKED and the pick is printed on both sides. Mirror matches are
## allowed and shown plainly. The fight only starts once both are locked, and the two ids go
## to the match scene through the `MatchSetup` autoload.
##
## One keyboard can drive both panels: P1's keys (A/D move, J lock/cancel) act on whichever
## panel is focused, so 1P vs CPU is lock P1 → move the CPU pick → lock it. P2's own keys
## (←/→ move, L lock, O cancel) always act on P2 and are never consumed by P1's handler.
## Every action fires on key press, never on release, and no animation gates a cursor move.
##
## Everything is drawn with primitives plus the project's OFL fonts: no new art is
## introduced, and nothing here touches the FSM, the beat clock or combat.

enum Phase { SPLASH, SETUP }

const FONT_SHADE := preload("res://assets/fonts/BungeeShade-Regular.ttf")
const FONT_INLINE := preload("res://assets/fonts/BungeeInline-Regular.ttf")
const FONT_BUNGEE := preload("res://assets/fonts/Bungee-Regular.ttf")
const FONT_BODY := preload("res://assets/fonts/ChakraPetch-Bold.ttf")

const BEAT_TOAST_SECONDS := 2.2
const LOCK_FLASH_SECONDS := 0.45

## P1 owns gold, P2 owns cyan. Both the cursor and the panel carry the tag.
const P1_COLOUR := Color(1.0, 0.86, 0.32)
const P2_COLOUR := Color(0.42, 0.88, 1.0)
const PANEL_DARK := Color(0.05, 0.04, 0.07, 0.86)
## PART 2 scale-up (owner playtest, 2026-11-24): the select screen was set for a desktop
## monitor; at Chromebook and iPhone size the cards, names and prompts were too small to read.
## Every card is now taller with a Rasta top rail, an inner gold/cyan frame and much larger
## type. Nothing here reads combat state.
const RASTA := [Color(0.10, 0.52, 0.22), Color(0.96, 0.78, 0.20), Color(0.72, 0.13, 0.12)]

var phase: Phase = Phase.SPLASH
## Independent cursors, as FighterRoster.ORDER indices. P1 → Feedback, P2 → L!ckshot.
var p1_cursor: int = 0
var p2_cursor: int = 1
var p1_locked: bool = false
var p2_locked: bool = false
## Which panel P1's own keys drive. False once P1 is locked, so one player can pick the CPU.
var p1_focus: bool = true
var _beat_toast: String = ""
var _beat_toast_life: float = 0.0
var _lock_flash: float = 0.0


func _ready() -> void:
	# The active beat starts with the screen and keeps the select menu alive. It is faded
	# out again in `_start()` so FIGHT! has no background music under the round sting.
	MusicBed.play_title()
	# Coming back from the arena via Esc skips the splash and keeps the selection.
	if MatchSetup.return_to_setup:
		phase = Phase.SETUP
		MatchSetup.return_to_setup = false
		_sync_cursors_from_setup()
	set_process(true)


## The cursors are this screen's own state; the autoload only holds what was last committed.
func _sync_cursors_from_setup() -> void:
	p1_cursor = MatchSetup.fighter_index(MatchSetup.p1_fighter)
	p2_cursor = MatchSetup.fighter_index(MatchSetup.p2_fighter)
	p1_locked = false
	p2_locked = false
	p1_focus = true


func _process(delta: float) -> void:
	if _beat_toast_life > 0.0:
		_beat_toast_life = maxf(0.0, _beat_toast_life - delta)
		if _beat_toast_life == 0.0:
			_beat_toast = ""
	_lock_flash = maxf(0.0, _lock_flash - delta)
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
# Selection state (read by the headless checks)
# =========================================================================
func p1_key() -> StringName:
	return FighterRoster.ORDER[posmod(p1_cursor, FighterRoster.ORDER.size())]


func p2_key() -> StringName:
	return FighterRoster.ORDER[posmod(p2_cursor, FighterRoster.ORDER.size())]


func both_locked() -> bool:
	return p1_locked and p2_locked


## True while P1's keys drive the P2 panel (1P vs CPU: lock yourself, then pick the CPU).
func p1_drives_p2() -> bool:
	return p1_locked and not p1_focus


# =========================================================================
# Input
# =========================================================================
func _unhandled_input(event: InputEvent) -> void:
	# Press only: a cursor move must never wait for the key release, and echo is ignored so
	# a held key does not run the cursor away. Nothing is marked handled, so P2's keys still
	# reach this same handler afterwards.
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
		# ---- P1's own keys: act on whichever panel is focused -------------------
		KEY_A:
			_move_focused(-1)
		KEY_D:
			_move_focused(1)
		KEY_J, KEY_SPACE:
			_lock_focused()
		KEY_K:
			_cancel_p1()
		# ---- P2's own keys: always P2, never intercepted ------------------------
		KEY_LEFT:
			_move_p2(-1)
		KEY_RIGHT:
			_move_p2(1)
		KEY_L:
			_lock_p2()
		KEY_O:
			_cancel_p2()
		# ---- Match settings ----------------------------------------------------
		KEY_TAB:
			MatchSetup.cycle_ai(1)
		KEY_V:
			MatchSetup.toggle_subtitles()
		KEY_M:
			_audition_beat()
		KEY_ENTER, KEY_KP_ENTER:
			_start()
		KEY_ESCAPE:
			_escape()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return
	if phase == Phase.SPLASH:
		_enter_setup()
		return
	var point := (event as InputEventMouseButton).position
	if _p1_rect().has_point(point):
		if not p1_locked:
			p1_focus = true
		return
	if _p2_rect().has_point(point):
		# Clicking P2's card locks or unlocks it, so the screen is usable without a keyboard.
		_lock_p2()


func _move_focused(dir: int) -> void:
	if p1_focus and not p1_locked:
		p1_cursor = posmod(p1_cursor + dir, FighterRoster.ORDER.size())
	else:
		_move_p2(dir)


func _move_p2(dir: int) -> void:
	if p2_locked:
		return
	p2_cursor = posmod(p2_cursor + dir, FighterRoster.ORDER.size())


func _lock_focused() -> void:
	if p1_focus and not p1_locked:
		p1_locked = true
		p1_focus = false            # hand the keyboard to the CPU pick
		_lock_flash = LOCK_FLASH_SECONDS
	else:
		_lock_p2()


func _lock_p2() -> void:
	p2_locked = true
	p1_focus = false
	_lock_flash = LOCK_FLASH_SECONDS


func _cancel_p1() -> void:
	if p1_locked:
		p1_locked = false
		p1_focus = true
		_lock_flash = LOCK_FLASH_SECONDS


func _cancel_p2() -> void:
	if p2_locked:
		p2_locked = false
		p1_focus = false
		_lock_flash = LOCK_FLASH_SECONDS


func _escape() -> void:
	# Esc walks the lock state back one step before it leaves the screen.
	if p2_locked:
		p2_locked = false
		return
	if p1_locked:
		p1_locked = false
		p1_focus = true
		return
	phase = Phase.SPLASH


func _enter_setup() -> void:
	phase = Phase.SETUP
	p1_focus = true
	# Browsers only unlock audio on the first gesture; restart the bed now so the beat is
	# definitely audible the moment Character Select appears.
	MusicBed.play_title()


func _start() -> void:
	# Both sides must be locked. An unlocked panel is never quietly filled with a default.
	if not both_locked():
		_lock_flash = LOCK_FLASH_SECONDS
		return
	MusicBed.stop_for_fight()
	MatchSetup.commit_match(p1_key(), p2_key())
	MatchSetup.start_match()


# =========================================================================
# Layout
# =========================================================================
func _p1_rect() -> Rect2:
	return Rect2(Vector2(84.0, 196.0), Vector2(544.0, 348.0))


func _p2_rect() -> Rect2:
	return Rect2(Vector2(652.0, 196.0), Vector2(544.0, 348.0))


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
	var title_y := height * 0.28
	var l1 := "SOUND CLASH"
	_text(Vector2(0, title_y), l1, FONT_SHADE, _fit(FONT_SHADE, l1, 120, width - 100.0),
		Color(1.0, 0.96, 0.86), HORIZONTAL_ALIGNMENT_CENTER, width)
	var l2 := "BRAWL"
	_text(Vector2(0, title_y + 134.0), l2, FONT_INLINE, _fit(FONT_INLINE, l2, 136, width - 220.0),
		Color(1.0, 0.83, 0.30), HORIZONTAL_ALIGNMENT_CENTER, width)
	var sub := "132 BPM · KINGSTON YARD · 1P VS AI"
	_text(Vector2(0, title_y + 186.0), sub, FONT_BODY, _fit(FONT_BODY, sub, 27, width - 180.0),
		Color(0.96, 0.92, 0.84, 0.94), HORIZONTAL_ALIGNMENT_CENTER, width)

	# Blinking prompt.
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.55 + 0.45 * absf(sin(t * 2.0))
	var prompt := "PRESS START / CLICK TO CLASH"
	_text(Vector2(0, height * 0.71), prompt, FONT_BUNGEE,
		_fit(FONT_BUNGEE, prompt, 44, width - 200.0),
		Color(1.0, 0.99, 0.94, pulse), HORIZONTAL_ALIGNMENT_CENTER, width)
	# Roster line comes from FighterRoster, so the owner's I→! styling rule applies here too
	# and a rename never leaves a stale hard-coded name on the splash.
	var names := PackedStringArray()
	for key in FighterRoster.ORDER:
		names.append(FighterRoster.display_name(key))
	_text(Vector2(0, height * 0.785), " · ".join(names), FONT_BODY, 21,
		Color(0.90, 0.86, 0.80, 0.85), HORIZONTAL_ALIGNMENT_CENTER, width)


func _draw_setup(width: float, height: float) -> void:
	var header := "CHARACTER SELECT"
	_text(Vector2(0, 142.0), header, FONT_INLINE, _fit(FONT_INLINE, header, 62, width - 140.0),
		Color(1.0, 0.92, 0.72), HORIZONTAL_ALIGNMENT_CENTER, width)
	var hint := "BOTH PANELS MUST BE LOCKED BEFORE THE CLASH STARTS"
	_text(Vector2(0, 180.0), hint, FONT_BODY, _fit(FONT_BODY, hint, 20, width - 160.0),
		Color(0.90, 0.88, 0.82, 0.9), HORIZONTAL_ALIGNMENT_CENTER, width)

	_fighter_panel(_p1_rect(), "P1", P1_COLOUR, p1_cursor, p1_locked,
		p1_focus and not p1_locked)
	_fighter_panel(_p2_rect(), "P2", P2_COLOUR, p2_cursor, p2_locked,
		(not p1_focus) and not p2_locked)

	# Mirror match notice: shown plainly instead of being hidden or blocked.
	if p1_key() == p2_key():
		var mirror := "MIRROR MATCH · BOTH PLAYERS PICKED %s" % FighterRoster.display_name(p1_key())
		_text(Vector2(0, 572.0), mirror, FONT_BUNGEE,
			_fit(FONT_BUNGEE, mirror, 26, width - 160.0),
			Color(1.0, 0.99, 0.90, 0.95), HORIZONTAL_ALIGNMENT_CENTER, width)

	var ai := "AI STYLE · %s   (TAB)" % MatchSetup.ai_mode_name().to_upper()
	_text(Vector2(0, 610.0), ai, FONT_BODY, _fit(FONT_BODY, ai, 21, width - 120.0),
		Color(0.88, 0.90, 0.98, 0.94), HORIZONTAL_ALIGNMENT_CENTER, width)
	var subs := "PATOIS SUBTITLES · %s   (V)" % ("ON" if MatchSetup.subtitles else "OFF")
	_text(Vector2(0, 638.0), subs, FONT_BODY, _fit(FONT_BODY, subs, 21, width - 120.0),
		Color(0.88, 0.90, 0.98, 0.94), HORIZONTAL_ALIGNMENT_CENTER, width)

	var footer := "P1  A/D MOVE · J LOCK · K CANCEL      P2  ←/→ MOVE · L LOCK · O CANCEL      ENTER FIGHT"
	_text(Vector2(0, height * 0.945), footer, FONT_BODY,
		_fit(FONT_BODY, footer, 19, width - 40.0),
		Color(0.94, 0.94, 0.98, 0.86), HORIZONTAL_ALIGNMENT_CENTER, width)
	var music_line := "%s · M TO CYCLE" % MusicBed.label()
	_text(Vector2(0, height * 0.978), music_line, FONT_BODY,
		_fit(FONT_BODY, music_line, 17, width - 60.0),
		Color(1.0, 0.86, 0.32, 0.85), HORIZONTAL_ALIGNMENT_CENTER, width)


## One player's card: tag, cursor arrows, fighter name and stats, and a LOCKED banner.
func _fighter_panel(rect: Rect2, tag: String, colour: Color, cursor: int, locked: bool,
		active: bool) -> void:
	draw_rect(rect, PANEL_DARK, true)
	# Outer colour frame, a dark inset and a thin gold rail inside it: an arcade card rather
	# than a flat rectangle.
	var border := colour if active else Color(colour.r, colour.g, colour.b, 0.55)
	draw_rect(rect, border, false, 5.0 if active else 3.0)
	draw_rect(rect.grow(-7.0), Color(0.01, 0.008, 0.02, 0.75), false, 2.0)
	draw_rect(rect.grow(-9.0), Color(1.0, 0.84, 0.24, 0.40 if not locked else 0.75), false, 1.0)
	# Rasta top rail across the card, the same trim the HUD banners carry.
	var rail := Rect2(rect.position + Vector2(9.0, 0.0), Vector2(rect.size.x - 18.0, 6.0))
	for i in 3:
		var rail_colour: Color = RASTA[i]
		draw_rect(Rect2(rail.position + Vector2(float(i) * rail.size.x / 3.0, 0.0),
			Vector2(rail.size.x / 3.0, rail.size.y)), rail_colour, true)

	# The player tag, top-left, in that player's colour — the thing that tells the two
	# cursors apart at a glance.
	var tag_box := Rect2(rect.position + Vector2(18.0, 18.0), Vector2(94.0, 58.0))
	draw_rect(tag_box, colour, true)
	draw_rect(tag_box, Color(0.02, 0.01, 0.03, 0.85), false, 2.0)
	_text(tag_box.position + Vector2(tag_box.size.x * 0.5, 42.0), tag, FONT_BUNGEE, 34,
		Color(0.07, 0.05, 0.08), HORIZONTAL_ALIGNMENT_CENTER, tag_box.size.x)

	var key := FighterRoster.ORDER[posmod(cursor, FighterRoster.ORDER.size())]
	var data := FighterRoster.profile(key)
	var name_text := FighterRoster.display_name(key)

	# Cursor arrows beside the name, only on the panel the keyboard is driving.
	var name_x := rect.position.x + 124.0
	if active and not locked:
		_text(Vector2(rect.position.x + 22.0, rect.position.y + 148.0), "▶", FONT_BUNGEE, 38,
			colour)
		_text(Vector2(rect.end.x - 52.0, rect.position.y + 148.0), "◀", FONT_BUNGEE, 38,
			colour)
	_text(Vector2(name_x, rect.position.y + 150.0), name_text, FONT_INLINE,
		_fit(FONT_INLINE, name_text, 58, rect.size.x - 176.0), Color(1.0, 0.97, 0.88))

	# Portrait stand-in: the fighter's own roster colour block, never a drawn character.
	var swatch := Rect2(Vector2(rect.position.x + 18.0, rect.position.y + 166.0),
		Vector2(rect.size.x - 36.0, 10.0))
	draw_rect(swatch, colour, true)
	draw_rect(Rect2(swatch.position, Vector2(swatch.size.x, 3.0)), colour.lightened(0.35), true)

	var reach := float(data["reach_bonus"])
	var line1 := "%s" % String(data["tagline"])
	_text(Vector2(rect.position.x + 28.0, rect.position.y + 216.0), line1, FONT_BODY,
		_fit(FONT_BODY, line1, 22, rect.size.x - 56.0), Color(0.92, 0.92, 0.96, 0.95))
	var line2 := "WALK %d · REACH %s" % [int(round(float(data["walk_speed"]))),
		("+%d PX" % int(reach)) if reach > 0.0 else "STANDARD"]
	_text(Vector2(rect.position.x + 28.0, rect.position.y + 250.0), line2, FONT_BODY, 19,
		Color(0.82, 0.85, 0.93, 0.88))

	# Lock state: a filled bar across the bottom of the card.
	var badge := Rect2(Vector2(rect.position.x + 18.0, rect.end.y - 72.0),
		Vector2(rect.size.x - 36.0, 54.0))
	if locked:
		draw_rect(badge, colour, true)
		draw_rect(badge, Color(1.0, 0.99, 0.94, 0.55), false, 2.0)
		_text(badge.position + Vector2(badge.size.x * 0.5, 38.0), "LOCKED", FONT_BUNGEE, 30,
			Color(0.07, 0.05, 0.08), HORIZONTAL_ALIGNMENT_CENTER, badge.size.x)
	else:
		draw_rect(badge, Color(1.0, 1.0, 1.0, 0.07), true)
		draw_rect(badge, Color(colour.r, colour.g, colour.b, 0.7), false, 2.0)
		_text(badge.position + Vector2(14.0, 36.0), "PICKING…", FONT_BODY, 21,
			Color(0.94, 0.94, 0.98, 0.9))


## Corner label for the M-key beat audition. Both the splash and the select screen use it.
func _draw_beat_toast(width: float) -> void:
	if _beat_toast == "" or _beat_toast_life <= 0.0:
		return
	var fade := clampf(_beat_toast_life / 0.5, 0.0, 1.0)
	var font_size := _fit(FONT_BODY, _beat_toast, 18, 440.0)
	var text_w := FONT_BODY.get_string_size(_beat_toast, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var box_w := clampf(text_w + 34.0, 280.0, 470.0)
	var box := Rect2(Vector2(width - 24.0 - box_w, 24.0), Vector2(box_w, 40.0))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.74 * fade), true)
	draw_rect(box, Color(1.0, 0.86, 0.32, 0.8 * fade), false, 1.0)
	_text(Vector2(box.position.x, box.position.y + 27.0), _beat_toast, FONT_BODY, font_size,
		Color(1.0, 0.93, 0.72, fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)

extends Control
## Workshop HUD: health bars, P1 Crowd Hype bar, a beat pulse, the P2 AI mode banner,
## round banners, and the deadpan Patois subtitle pill.
## UNAPPROVED. Primitives plus the Bungee / Chakra Petch OFL fonts (AGENTS.md §9 item 19).
##
## **PART 2 scale-up (owner playtest, 2026-11-24):** the bars, the Hype meter, the round clock
## and every banner are far larger and carry Rasta/gold arcade framing, because the previous
## sizes were unreadable on a Chromebook screen and an iPhone. Nothing here reads or writes
## combat state — it draws what `BaseFighter` / `RoundController` already publish.

var p1: BaseFighter
var p2: BaseFighter
var beat: BeatService
var sparring: SparringController
var rounds: RoundController

const BAR_W := 442.0
const BAR_H := 32.0
const MARGIN := 22.0
## Rasta/gold arcade frame around every readout.
const FRAME_DARK := Color(0.04, 0.035, 0.05, 0.86)
const CYAN := Color(0.36, 0.88, 1.0)
const GREEN := Color(0.10, 0.56, 0.24)

# Bungee family (SIL OFL) + Chakra Petch Bold for the deadpan subtitles.
const FONT_BUNGEE := preload("res://assets/fonts/Bungee-Regular.ttf")
const FONT_INLINE := preload("res://assets/fonts/BungeeInline-Regular.ttf")
const FONT_SHADE := preload("res://assets/fonts/BungeeShade-Regular.ttf")
const FONT_SUB := preload("res://assets/fonts/ChakraPetch-Bold.ttf")

# Subtitle pill (AGENTS.md §9 item 19): one line at a time, 4 s cooldown, 1.8 s fade.
const SUBTITLE_SECONDS := 1.8
const SUBTITLE_COOLDOWN_SECONDS := 4.0
const SUBTITLE_FADE := 0.45

# ---- Bottom button bar (STEP 3, 2026-11-27) -----------------------------------------
## The three bottom readouts used to share one band and print through each other: the key
## strip sat at y 700 across the whole width, the F6/F7/HitchLog chip at y 672 right-aligned,
## and the 64 px callout pill at y 614-678 in the middle — so the chip crossed the pill's lower
## edge and the strip's sixth key landed under it. They are now one measured vertical stack:
## a two-row button bar pinned to the bottom, the status chip in its own band above it, and the
## callout pill above that. `bottom_layout()` is the single source of truth for all three, so
## `_draw()` and the headless rect-overlap audit can never disagree about where a label goes.
const KEY_LABELS := [
	"J jab", "K box", "L tump", "I upper box", "U grab/tech", "T taunt", "C crouch",
	"G dummy guard", "Y AI mode", "B bird", "N time of day", "V subtitles", "F4 stepped",
	"F6 look", "F7 quality", "R reset", "M mute/beats",
]
const KEY_FONT_SIZE := 12
const KEY_CHIP_H := 24.0
const KEY_PAD_X := 7.0
const KEY_GAP_X := 6.0
const KEY_GAP_Y := 4.0
const KEY_MARGIN := 22.0
const KEY_BAR_PAD := 6.0
const KEY_BOTTOM_MARGIN := 6.0
const KEY_MAX_ROWS := 2
const CHIP_BAND_H := 22.0
const CHIP_MAX_W := 545.0
const PILL_H := 62.0
## Gap between the bar, the chip band and the pill band. Never less than 4 px, so no two
## readouts can share a pixel even at the smallest canvas.
const BAND_GAP := 4.0

## Cached layout, keyed by the view size: `_draw()` calls `bottom_layout()` every frame, and a
## HUD must not re-measure 17 strings per frame. The entries are rebuilt only when the canvas
## size changes.
var _layout_key := Vector2(-1.0, -1.0)
var _layout: Dictionary = {}
var _layout_font_size := KEY_FONT_SIZE
## Match-intro proverb banner (AGENTS.md §8, 2026-11-22) sits under the round banner, so the
## round name and the yard wisdom read as one intro card. The English gloss is only drawn
## while subtitles are on (V).
const WISDOM_Y := 214.0
const WISDOM_FADE := 0.4
## Brief corner label after M auditions the menu/victory beats (AGENTS.md §9 item 48).
const MUSIC_TOAST_SECONDS := 2.2

## Arcade cabinet typography (owner playtest, 2026-11-23): every callout gets a thick black
## ink outline, a three-step extruded drop shadow, a gold rim under the face, and a punchy
## scale-pop on entrance, so a banner lands instead of fading in politely.
const POP_SECONDS := 0.26
const POP_GAIN := 0.34
const GOLD := Color(1.0, 0.84, 0.24)
const RASTA_STRIP := [
	Color(0.10, 0.52, 0.22),          # green
	Color(0.96, 0.78, 0.20),          # gold
	Color(0.72, 0.13, 0.12),          # red
]

var subtitles_enabled: bool = true
## Persistent corner chip for the presentation toggles (F6 look A/B, F7 render quality). Unlike
## the M toast it never fades: the owner compares two looks on device and has to see which one
## is live without pressing the key again.
var debug_chip: String = ""

var _sub: String = ""              # Patois shout
var _sub_translation: String = ""  # deadpan English
var _sub_life: float = 0.0
var _sub_cooldown: float = 0.0
var _proverb: String = ""
var _proverb_gloss: String = ""
var _proverb_life: float = 0.0
var _music_toast: String = ""
var _music_life: float = 0.0
## Entrance-pop ages, one per banner kind, advanced in `_process`.
var _pop: Dictionary = {}
var _last_banner: String = ""
var _surge_shown: bool = false


func _process(delta: float) -> void:
	for key in _pop.keys():
		_pop[key] = float(_pop[key]) + delta
	# A new banner text is a new entrance: stamp the pop so every round, K.O. and rematch
	# snaps on instead of simply appearing.
	if rounds != null and rounds.banner != _last_banner:
		_last_banner = rounds.banner
		_stamp_pop(&"round")
	var surging := (p1 != null and p1.is_hype_surging()) or (p2 != null and p2.is_hype_surging())
	if surging and not _surge_shown:
		_stamp_pop(&"surge")
	_surge_shown = surging
	if _sub_life > 0.0:
		_sub_life = maxf(0.0, _sub_life - delta)
		if _sub_life == 0.0:
			_sub = ""
			_sub_translation = ""
			_layout = {}
			_layout_key = Vector2(-1.0, -1.0)
	_sub_cooldown = maxf(0.0, _sub_cooldown - delta)
	if _proverb_life > 0.0:
		_proverb_life = maxf(0.0, _proverb_life - delta)
		if _proverb_life == 0.0:
			_proverb = ""
			_proverb_gloss = ""
	if _music_life > 0.0:
		_music_life = maxf(0.0, _music_life - delta)
		if _music_life == 0.0:
			_music_toast = ""


# =========================================================================
# Subtitle API (TestArena triggers these)
# =========================================================================
## A big-moment callout. Returns false (and shows nothing) while the cooldown runs or
## while subtitles are off, so a burst of triggers can never stack pills.
func announce_subtitle(patois: String, translation: String) -> bool:
	if not subtitles_enabled or _sub_cooldown > 0.0:
		return false
	_sub = patois
	_sub_translation = translation
	_sub_life = SUBTITLE_SECONDS
	_sub_cooldown = SUBTITLE_COOLDOWN_SECONDS
	# The pill band is measured from the callout text, so a longer line re-measures it.
	_layout = {}
	_layout_key = Vector2(-1.0, -1.0)
	_stamp_pop(&"sub")
	queue_redraw()
	return true


## V toggle. Turning subtitles off clears the pill immediately.
func toggle_subtitles() -> bool:
	subtitles_enabled = not subtitles_enabled
	if not subtitles_enabled:
		_sub = ""
		_sub_translation = ""
		_sub_life = 0.0
		_layout = {}
		_layout_key = Vector2(-1.0, -1.0)
	return subtitles_enabled


func has_subtitle() -> bool:
	return _sub_life > 0.0


func subtitle_text() -> String:
	return _sub


func subtitle_cooldown_left() -> float:
	return _sub_cooldown


## Match-intro yard wisdom. The Patois line stays up for the announce; the gloss follows the V
## toggle, so turning subtitles off never hides the proverb itself.
func show_proverb(patois: String, translation: String, seconds: float = 3.4) -> bool:
	if patois == "":
		return false
	_proverb = patois
	_proverb_gloss = translation
	_proverb_life = maxf(seconds, 0.5)
	_stamp_pop(&"wisdom")
	queue_redraw()
	return true


func proverb_text() -> String:
	return _proverb


func proverb_gloss() -> String:
	return _proverb_gloss if subtitles_enabled else ""


## Brief corner label for the M-key beat audition on the post-KO screen. Also the shared
## slot for a presentation toggle (F4 stepped arcade), so two corner labels can never stack.
func show_toast(text: String) -> void:
	if text == "":
		return
	_music_toast = text
	_music_life = MUSIC_TOAST_SECONDS
	_stamp_pop(&"music")
	queue_redraw()


## Set the persistent presentation chip (F6 look, F7 quality). Empty hides it.
func set_debug_chip(text: String) -> void:
	if text == debug_chip:
		return
	debug_chip = text
	# The chip's rect is measured from this text, so the cached bottom layout is stale now.
	_layout = {}
	_layout_key = Vector2(-1.0, -1.0)
	queue_redraw()


func show_music_toast(text: String) -> void:
	show_toast(text)


func music_toast_text() -> String:
	return _music_toast


# =========================================================================
# Draw
# =========================================================================
func _draw() -> void:
	if p1 == null or p2 == null:
		return
	var width := size.x
	_bar(Vector2(MARGIN, MARGIN), BAR_W, p1.health, float(p1.max_health), Color(0.32, 0.92, 0.44), false)
	_bar(Vector2(width - MARGIN - BAR_W, MARGIN), BAR_W, p2.health, float(p2.max_health), Color(1.0, 0.36, 0.34), true)
	_fighter_name(Vector2(MARGIN, MARGIN), BAR_W, _name_of(p1, "P1"), false)
	_fighter_name(Vector2(width - MARGIN - BAR_W, MARGIN), BAR_W, _name_of(p2, "P2"), true)
	_hype_bar(Vector2(MARGIN, MARGIN + BAR_H + 12.0))
	_beat_pulse(Vector2(width * 0.5, MARGIN + BAR_H * 0.5))
	_ai_banner(Vector2(width * 0.5 - 176.0, MARGIN + 44.0))
	# STEP 3: one measured bottom stack — button bar, status chip band, callout band.
	var bottom := bottom_layout(size)
	_round_clock(width)
	_round_pips(width)
	_surge_banner(Vector2(width * 0.5, size.y * 0.34))
	_round_banner(width)
	_wisdom_banner(width)
	_music_toast_label(width)
	_subtitle_pill(bottom)
	_debug_chip_label(bottom)
	_key_bar(bottom)


## Every label now draws like a classic arcade cabinet: three stacked extruded shadows, a
## thick black ink outline, a one-pixel gold rim under the face, then the crisp face. That
## keeps the type readable over sky, sand and the night tint and makes it jump off screen.
func _text(pos: Vector2, text: String, font: Font, font_size: int, colour: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	if text == "":
		return
	var outline := maxi(3, int(round(float(font_size) * 0.24)))
	var depth := maxf(1.5, float(font_size) * 0.085)
	for step in [3, 2, 1]:
		var off := Vector2(depth * 0.55 * float(step), depth * float(step))
		draw_string(font, pos + off, text, align, width, font_size,
			Color(0.014, 0.010, 0.020, 0.62 * colour.a))
	draw_string_outline(font, pos, text, align, width, font_size, outline,
		Color(0.012, 0.008, 0.018, 0.96 * colour.a))
	draw_string(font, pos + Vector2(0.0, -1.0), text, align, width, font_size,
		Color(GOLD.r, GOLD.g, GOLD.b, 0.55 * colour.a))
	draw_string(font, pos, text, align, width, font_size, colour)


## Mark a banner's entrance. Its size pops above `POP_GAIN` and settles over `POP_SECONDS`.
func _stamp_pop(key: StringName) -> void:
	_pop[key] = 0.0


func _pop_scale(key: StringName) -> float:
	var age := float(_pop.get(key, 99.0))
	if age >= POP_SECONDS:
		return 1.0
	var t := age / POP_SECONDS
	return 1.0 + POP_GAIN * (1.0 - t) * (1.0 - t)


func _pop_size(key: StringName, base: int) -> int:
	return maxi(9, int(round(float(base) * _pop_scale(key))))


## Three-block Rasta accent bar along a banner's top edge, the sound-system trim colour.
func _rasta_strip(box: Rect2, alpha: float) -> void:
	var block := box.size.x / 3.0
	for i in 3:
		var colour: Color = RASTA_STRIP[i]
		draw_rect(Rect2(box.position + Vector2(float(i) * block, 0.0),
			Vector2(block, 3.0)), Color(colour.r, colour.g, colour.b, alpha), true)


## Shrink the size until the string fits the box (Bungee is a very wide face).
func _fit_size(font: Font, text: String, preferred: int, max_width: float) -> int:
	var size := preferred
	while size > 9:
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			return size
		size -= 1
	return size


## Health bar with an arcade frame: dark plate, gold border, Rasta corner block, a bright
## two-tone fill (lit top edge over the base colour) and a trailing "lost health" ghost so a
## hit reads instantly at Chromebook size.
func _bar(pos: Vector2, w: float, value: int, maximum: float, colour: Color, right_aligned: bool) -> void:
	var h := BAR_H
	var ratio := clampf(float(value) / maxf(maximum, 1.0), 0.0, 1.0)
	var plate := Rect2(pos, Vector2(w, h))
	draw_rect(plate, FRAME_DARK, true)
	# Rasta corner tab on the inside edge the bar drains towards.
	var tab := Rect2(Vector2(pos.x if not right_aligned else pos.x + w - 7.0, pos.y),
		Vector2(7.0, h))
	var tab_colour: Color = GREEN if not right_aligned else RASTA_STRIP[2]
	draw_rect(tab, tab_colour, true)
	var inner := Rect2(pos + Vector2(9, 4), Vector2(w - 13.0, h - 8.0))
	draw_rect(inner, Color(0.10, 0.09, 0.12, 0.94), true)
	var fill := Rect2(inner.position, Vector2(inner.size.x * ratio, inner.size.y))
	if right_aligned:
		fill.position.x = inner.end.x - fill.size.x
	draw_rect(fill, colour.darkened(0.22), true)
	# Lit top edge: a cleaner arcade read than a flat block of colour.
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, maxf(3.0, fill.size.y * 0.34))),
		colour.lightened(0.28), true)
	draw_rect(plate, Color(GOLD.r, GOLD.g, GOLD.b, 0.92), false, 2.0)
	draw_rect(plate.grow(-3.0), Color(0, 0, 0, 0.55), false, 1.0)


## Bungee fighter tag inside the health bar (above it clips the viewport edge).
func _fighter_name(bar_pos: Vector2, bar_w: float, name: String, right_aligned: bool) -> void:
	var w := 300.0
	var x := bar_pos.x + bar_w - w - 12.0 if right_aligned else bar_pos.x + 14.0
	_text(Vector2(x, bar_pos.y + BAR_H - 8.0), name, FONT_BUNGEE,
		_fit_size(FONT_BUNGEE, name, 23, w), Color(1.0, 0.93, 0.56, 1.0),
		HORIZONTAL_ALIGNMENT_RIGHT if right_aligned else HORIZONTAL_ALIGNMENT_LEFT, w)


## Roster name from the fighter profile, with the old side label as the fallback.
func _name_of(fighter: BaseFighter, fallback: String) -> String:
	if fighter == null or fighter.display_name == "":
		return fallback
	return fighter.display_name


## Crowd Hype meter: twice the old width and height, gold frame, Rasta tick at the 50 %
## half-hype milestone and a big numeric readout.
func _hype_bar(pos: Vector2) -> void:
	var w := 264.0
	var h := 22.0
	var plate := Rect2(pos, Vector2(w, h))
	draw_rect(plate, FRAME_DARK, true)
	var ratio := clampf(float(p1.hype) / float(BaseFighter.HYPE_MAX), 0.0, 1.0)
	var inner := Rect2(pos + Vector2(4, 4), Vector2(w - 8.0, h - 8.0))
	draw_rect(inner, Color(0.10, 0.09, 0.12, 0.94), true)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * ratio, inner.size.y)),
		Color(0.99, 0.80, 0.22), true)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x * ratio, inner.size.y * 0.36)),
		Color(1.0, 0.93, 0.52), true)
	draw_rect(Rect2(Vector2(inner.position.x + inner.size.x * 0.5 - 1.0, pos.y),
		Vector2(2.0, h)), Color(GOLD.r, GOLD.g, GOLD.b, 0.75), true)
	draw_rect(plate, Color(GOLD.r, GOLD.g, GOLD.b, 0.9), false, 2.0)
	_text(pos + Vector2(w + 12.0, h - 3.0), "HYPE %d" % p1.hype, FONT_BUNGEE,
		_fit_size(FONT_BUNGEE, "HYPE 100", 17, 150.0), Color(1.0, 0.94, 0.66))


func _beat_pulse(centre: Vector2) -> void:
	if beat == null:
		return
	var j := beat.judge()
	var on_beat := bool(j.get("on_beat", false))
	var colour := Color(0.35, 1.0, 0.55) if on_beat else Color(0.30, 0.34, 0.44)
	draw_circle(centre, 13.0 if on_beat else 9.0, Color(colour.r, colour.g, colour.b, 0.55))
	draw_circle(centre, 8.0 if on_beat else 5.0, colour)


## Active P2 sparring AI mode. Y cycles it; G stays a manual guard override in every mode.
func _ai_banner(pos: Vector2) -> void:
	if sparring == null:
		return
	var box := Rect2(pos, Vector2(352, 50))
	draw_rect(box, FRAME_DARK, true)
	draw_rect(box, Color(CYAN.r, CYAN.g, CYAN.b, 0.65), false, 2.0)
	_rasta_strip(box, 0.9)
	var title := "P2 AI %d · %s" % [sparring.mode_index(), sparring.mode_name()]
	_text(pos + Vector2(12, 22), title, FONT_BUNGEE,
		_fit_size(FONT_BUNGEE, title, 16, 328.0), Color(0.96, 0.98, 1.0))
	_text(pos + Vector2(12, 40), "%s · Y switch · G guard" % sparring.mode_tag(), FONT_SUB, 13,
		Color(0.74, 0.84, 0.96))


## 60-second round clock (AGENTS.md §9 backlog item B6) centred between the health bars.
## Bungee for the digits so they read at a glance, Chakra Petch for the round caption.
func _round_clock(width: float) -> void:
	if rounds == null or not rounds.enabled:
		return
	if rounds.phase == RoundController.Phase.IDLE or rounds.phase == RoundController.Phase.MATCH_OVER:
		return
	var seconds := int(ceil(maxf(rounds.clock, 0.0)))
	var urgent := rounds.clock_running() and rounds.clock <= 10.0
	var box := Rect2(Vector2(width * 0.5 - 80.0, MARGIN - 8.0), Vector2(160.0, 66.0))
	draw_rect(box, FRAME_DARK, true)
	draw_rect(box, Color(GOLD.r, GOLD.g, GOLD.b, 0.98 if urgent else 0.7), false, 3.0)
	_rasta_strip(box, 0.95)
	var colour := Color(1.0, 0.40, 0.32) if urgent else Color(1.0, 0.92, 0.44)
	_text(Vector2(box.position.x, box.position.y + 44.0), "%02d" % seconds, FONT_BUNGEE, 40,
		colour, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	_text(Vector2(box.position.x, box.position.y + 59.0), "ROUND %d" % rounds.round_number(),
		FONT_SUB, 13, Color(0.86, 0.90, 0.98), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)


## Round-win pips: two per fighter, filled as rounds are taken.
func _round_pips(width: float) -> void:
	if rounds == null:
		return
	for side in 2:
		for i in rounds.rounds_to_win:
			var filled: bool = rounds.wins[side] > i
			var pos := Vector2(MARGIN + 12.0 + float(i) * 24.0, MARGIN + BAR_H + 46.0)
			if side == 1:
				pos.x = width - MARGIN - 12.0 - float(i) * 24.0
			draw_circle(pos, 8.0, Color(0.05, 0.04, 0.06, 0.85))
			draw_circle(pos, 7.0,
				Color(1.0, 0.84, 0.26) if filled else Color(0.26, 0.26, 0.32, 0.95))
			draw_arc(pos, 8.0, 0.0, TAU, 16, Color(GOLD.r, GOLD.g, GOLD.b, 0.8), 1.5)


## Round / K.O. / rematch banner published by the round controller. The face carries the
## weight of the moment: Shade for the K.O., Inline for the rematch, Bungee otherwise — all
## with the arcade ink outline, gold rim and a scale-pop on every new banner text.
func _round_banner(width: float) -> void:
	if rounds == null or rounds.banner == "" or rounds.banner_alpha <= 0.01:
		return
	var alpha: float = rounds.banner_alpha
	var text: String = rounds.banner
	var font: Font = FONT_BUNGEE
	var preferred := 36
	var max_width := 780.0
	var face := Color(1.0, 0.90, 0.42, alpha)
	if text.begins_with("K.O."):
		font = FONT_SHADE
		preferred = 88
		max_width = 470.0
		face = Color(1.0, 0.97, 0.86, alpha)
	elif text.begins_with("WHEEL AND COME AGAIN"):
		font = FONT_INLINE
		preferred = 46
		max_width = 1020.0
	var font_size := _fit_size(font, text, _pop_size(&"round", preferred), max_width)
	var box_w := clampf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		+ 82.0, 320.0, width - 2.0 * MARGIN)
	var y := size.y * 0.19
	var box := Rect2(Vector2(width * 0.5 - box_w * 0.5, y - 42.0),
		Vector2(box_w, 96.0 if text.begins_with("K.O.") else 78.0))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.70 * alpha), true)
	draw_rect(box, Color(GOLD.r, GOLD.g, GOLD.b, 0.90 * alpha), false, 3.0)
	_rasta_strip(box, 0.95 * alpha)
	_text(Vector2(box.position.x, box.position.y + box.size.y * 0.5 + font_size * 0.34), text,
		font, font_size, face, HORIZONTAL_ALIGNMENT_CENTER, box_w)


## 100% Crowd Hype Surge callout. Flashes while either fighter's surge boost is live.
func _surge_banner(centre: Vector2) -> void:
	var who := ""
	if p1 != null and p1.is_hype_surging():
		who = "P1"
	elif p2 != null and p2.is_hype_surging():
		who = "P2"
	if who == "":
		return
	var flash := int(Time.get_ticks_msec() / 140) % 2 == 0
	var box := Rect2(centre - Vector2(324.0, 56.0), Vector2(648.0, 112.0))
	draw_rect(box, Color(0.06, 0.04, 0.06, 0.78), true)
	draw_rect(box, Color(GOLD.r, GOLD.g, GOLD.b, 0.9 if flash else 0.35), false, 4.0)
	_rasta_strip(box, 0.95)
	var colour := Color(1.0, 0.86, 0.28) if flash else Color(1.0, 0.98, 0.86)
	_text(centre + Vector2(-300.0, -6.0), "FORWARD!", FONT_INLINE,
		_fit_size(FONT_INLINE, "FORWARD!", _pop_size(&"surge", 48), 600.0), colour,
		HORIZONTAL_ALIGNMENT_CENTER, 600.0)
	_text(centre + Vector2(-300.0, 42.0), "PULL UP! · %s 100%% HYPE" % who, FONT_BUNGEE,
		_fit_size(FONT_BUNGEE, "PULL UP! · P1 100% HYPE", 22, 600.0),
		Color(1.0, 1.0, 1.0, 0.95), HORIZONTAL_ALIGNMENT_CENTER, 600.0)


# =========================================================================
# Bottom stack geometry (STEP 3)
# =========================================================================
## One measured layout for everything that lives at the bottom of the screen: the button bar,
## its key chips, the status chip and the callout pill. Pure arithmetic over the view size and
## the current strings — it reads no game state, draws nothing, and is cached per view size so a
## frame costs one Dictionary lookup. The headless audit calls exactly this, which is why a
## collision cannot be "fixed in the test" without moving the drawing.
func bottom_layout(view: Vector2) -> Dictionary:
	if _layout_key == view and not _layout.is_empty():
		return _layout
	_layout_key = view
	var bar_width := maxf(view.x - 2.0 * KEY_MARGIN, 240.0)
	var font_size := KEY_FONT_SIZE
	var widths: Array = []
	var packed: Array = []
	while font_size >= 9:
		widths = []
		for label in KEY_LABELS:
			widths.append(FONT_SUB.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1,
				font_size).x + KEY_PAD_X * 2.0)
		packed = _pack_rows(widths, bar_width - 2.0 * KEY_BAR_PAD)
		if packed.size() <= KEY_MAX_ROWS:
			break
		font_size -= 1
	var rows: int = packed.size()
	var bar_h := KEY_BAR_PAD * 2.0 + float(rows) * KEY_CHIP_H \
		+ float(maxi(rows - 1, 0)) * KEY_GAP_Y
	var bar := Rect2(Vector2(KEY_MARGIN, view.y - KEY_BOTTOM_MARGIN - bar_h),
		Vector2(bar_width, bar_h))
	var chips: Array = []
	var labels: Array = []
	for row in rows:
		var entry: Array = packed[row]
		var indices: Array = entry[0]
		var used: float = entry[1]
		var gaps := maxi(indices.size() - 1, 0)
		var space := bar_width - 2.0 * KEY_BAR_PAD - used
		var gap := KEY_GAP_X
		if gaps > 0 and space > 0.0:
			gap = maxf(KEY_GAP_X, space / float(gaps))
		var x := bar.position.x + KEY_BAR_PAD
		var y := bar.position.y + KEY_BAR_PAD + float(row) * (KEY_CHIP_H + KEY_GAP_Y)
		for i in indices.size():
			var index: int = indices[i]
			var w: float = widths[index]
			chips.append(Rect2(Vector2(x, y), Vector2(w, KEY_CHIP_H)))
			labels.append(String(KEY_LABELS[index]))
			x += w + gap
	# The status chip owns the band directly above the bar, right-aligned, and is measured from
	# the text it will actually draw (the live F6 / F7 / HitchLog / callout line).
	var chip_w := clampf(FONT_SUB.get_string_size(debug_chip, HORIZONTAL_ALIGNMENT_LEFT, -1,
		_chiptext_size(bar_width)).x + 26.0, 210.0, minf(CHIP_MAX_W, bar_width))
	var debug_rect := Rect2(Vector2(view.x - KEY_MARGIN - chip_w,
		bar.position.y - BAND_GAP - CHIP_BAND_H), Vector2(chip_w, CHIP_BAND_H))
	# The callout pill owns the band above the chip. It is measured from the widest string it
	# would draw right now, so its rect is honest even while it is faded out.
	var shout_w := FONT_BUNGEE.get_string_size(_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 27).x
	var trans_w := FONT_SUB.get_string_size(_sub_translation, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var pill_w := clampf(maxf(shout_w, trans_w) + 56.0, 280.0, bar_width)
	var pill := Rect2(Vector2(view.x * 0.5 - pill_w * 0.5,
		debug_rect.position.y - BAND_GAP - PILL_H), Vector2(pill_w, PILL_H))
	_layout = {
		"view": view,
		"bar": bar,
		"chips": chips,
		"labels": labels,
		"debug": debug_rect,
		"pill": pill,
		"font_size": font_size,
		"rows": rows,
	}
	return _layout


## Greedy row packing. Returns [[indices, used_width], ...] — one entry per row.
func _pack_rows(widths: Array, limit: float) -> Array:
	var packed: Array = []
	var line: Array = []
	var used := 0.0
	for i in widths.size():
		var w: float = widths[i]
		var extra := w if line.is_empty() else w + KEY_GAP_X
		if not line.is_empty() and used + extra > limit:
			packed.append([line, used])
			line = []
			used = 0.0
			extra = w
		line.append(i)
		used += extra
	if not line.is_empty():
		packed.append([line, used])
	return packed


## Font size the status chip is measured/drawn at, so the rect and the drawn text agree.
func _chiptext_size(_width: float) -> int:
	return _fit_size(FONT_SUB, debug_chip, 14, CHIP_MAX_W - 26.0)


## The button bar: a dark plate with the Rasta trim, and one bordered chip per key. Every chip
## is a rect from `bottom_layout()`, so a label can never straddle another.
func _key_bar(layout: Dictionary) -> void:
	var bar: Rect2 = layout["bar"]
	draw_rect(bar, Color(0.04, 0.035, 0.05, 0.80), true)
	draw_rect(bar, Color(GOLD.r, GOLD.g, GOLD.b, 0.80), false, 2.0)
	_rasta_strip(bar, 0.90)
	var chips: Array = layout["chips"]
	var labels: Array = layout["labels"]
	var font_size: int = int(layout["font_size"])
	for i in chips.size():
		var rect: Rect2 = chips[i]
		draw_rect(rect, Color(0.09, 0.08, 0.11, 0.94), true)
		draw_rect(rect, Color(GOLD.r, GOLD.g, GOLD.b, 0.45), false, 1.0)
		_text(Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5
			+ float(font_size) * 0.36), String(labels[i]), FONT_SUB, font_size,
			Color(0.90, 0.94, 1.0), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x)


## Patois shout + deadpan translation in a compact translucent pill, above the button bar.
func _subtitle_pill(layout: Dictionary) -> void:
	if not subtitles_enabled or _sub == "" or _sub_life <= 0.0:
		return
	var fade := clampf(_sub_life / SUBTITLE_FADE, 0.0, 1.0)
	var pill: Rect2 = layout["pill"]
	var pill_w := pill.size.x
	var h := pill.size.y
	var shout_size := _fit_size(FONT_BUNGEE, _sub, _pop_size(&"sub", 27), pill_w - 44.0)
	var sub_size := 16
	var origin := pill.position
	var bg := Color(0.04, 0.03, 0.06, 0.72 * fade)
	draw_rect(Rect2(origin, Vector2(pill_w, h)), bg, true)
	draw_circle(origin + Vector2(0.0, h * 0.5), h * 0.5, bg)
	draw_circle(origin + Vector2(pill_w, h * 0.5), h * 0.5, bg)
	draw_rect(Rect2(origin + Vector2(0.0, -1.0), Vector2(pill_w, 2.0)),
		Color(1.0, 0.86, 0.32, 0.5 * fade), true)
	draw_rect(Rect2(origin + Vector2(0.0, 3.0), Vector2(pill_w, 2.0)),
		Color(GOLD.r, GOLD.g, GOLD.b, 0.8 * fade), true)
	_text(Vector2(origin.x, origin.y + 32.0), _sub, FONT_BUNGEE, shout_size,
		Color(1.0, 0.93, 0.60, fade), HORIZONTAL_ALIGNMENT_CENTER, pill_w)
	_text(Vector2(origin.x, origin.y + 55.0), _sub_translation, FONT_SUB, sub_size,
		Color(0.84, 0.88, 0.96, fade), HORIZONTAL_ALIGNMENT_CENTER, pill_w)


## Rotating match-intro proverb card. A short gold heading keeps it distinct from the
## round banner; the Patois line is verbatim, and the English gloss only appears with V on.
func _wisdom_banner(width: float) -> void:
	if _proverb == "" or _proverb_life <= 0.0:
		return
	var fade := clampf(_proverb_life / WISDOM_FADE, 0.0, 1.0)
	var gloss := _proverb_gloss if subtitles_enabled else ""
	var max_w := width - 2.0 * MARGIN - 80.0
	var line_size := _fit_size(FONT_INLINE, _proverb, _pop_size(&"wisdom", 30), max_w)
	var line_w := FONT_INLINE.get_string_size(_proverb, HORIZONTAL_ALIGNMENT_LEFT, -1, line_size).x
	var gloss_w := FONT_SUB.get_string_size(gloss, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var box_w := clampf(maxf(line_w, gloss_w) + 86.0, 480.0, max_w + 86.0)
	var box_h := 88.0 if gloss != "" else 66.0
	var box := Rect2(Vector2(width * 0.5 - box_w * 0.5, WISDOM_Y), Vector2(box_w, box_h))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.66 * fade), true)
	draw_rect(box, Color(GOLD.r, GOLD.g, GOLD.b, 0.7 * fade), false, 2.0)
	_rasta_strip(box, 0.95 * fade)
	_text(box.position + Vector2(0.0, 20.0), "YARD WISDOM", FONT_BUNGEE, 13,
		Color(GOLD.r, GOLD.g, GOLD.b, 0.95 * fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)
	_text(box.position + Vector2(0.0, 22.0 + line_size), _proverb, FONT_INLINE, line_size,
		Color(1.0, 0.90, 0.46, fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)
	if gloss != "":
		_text(box.position + Vector2(0.0, box_h - 12.0), gloss, FONT_SUB, 14,
			Color(0.80, 0.85, 0.93, fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)


## Corner HUD label shown briefly after M auditions a beat, so the cycle is never blind.
func _music_toast_label(width: float) -> void:
	if _music_toast == "" or _music_life <= 0.0:
		return
	var fade := clampf(_music_life / 0.5, 0.0, 1.0)
	var text_size := _fit_size(FONT_SUB, _music_toast, _pop_size(&"music", 17), 380.0)
	var text_w := FONT_SUB.get_string_size(_music_toast, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var box_w := clampf(text_w + 30.0, 240.0, 400.0)
	var box := Rect2(Vector2(width - MARGIN - box_w, MARGIN + BAR_H + 62.0),
		Vector2(box_w, 36.0))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.72 * fade), true)
	draw_rect(box, Color(1.0, 0.86, 0.32, 0.75 * fade), false, 1.0)
	_text(Vector2(box.position.x, box.position.y + 24.0), _music_toast, FONT_SUB, text_size,
		Color(1.0, 0.90, 0.48, fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)


## Persistent presentation chip (F6 look, F7 quality, the HitchLog lines and the F8 callout
## state), in its OWN band above the button bar. It is right-aligned inside that band, so no
## HitchLog line can ever reach the key chips below it.
func _debug_chip_label(layout: Dictionary) -> void:
	if debug_chip == "":
		return
	var box: Rect2 = layout["debug"]
	var text_size := _chiptext_size(box.size.x)
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.78), true)
	draw_rect(box, Color(GOLD.r, GOLD.g, GOLD.b, 0.70), false, 1.0)
	_text(Vector2(box.position.x, box.position.y + box.size.y * 0.5 + float(text_size) * 0.35),
		debug_chip, FONT_SUB, text_size, Color(0.92, 0.96, 1.0),
		HORIZONTAL_ALIGNMENT_CENTER, box.size.x)

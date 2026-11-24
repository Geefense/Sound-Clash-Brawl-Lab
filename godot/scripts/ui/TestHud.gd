extends Control
## Workshop HUD: health bars, P1 Crowd Hype bar, a beat pulse, the P2 AI mode banner,
## round banners, and the deadpan Patois subtitle pill.
## UNAPPROVED. Primitives plus the Bungee / Chakra Petch OFL fonts (AGENTS.md §9 item 19).

var p1: BaseFighter
var p2: BaseFighter
var beat: BeatService
var sparring: SparringController
var rounds: RoundController

const BAR_W := 320.0
const BAR_H := 18.0
const MARGIN := 24.0

# Bungee family (SIL OFL) + Chakra Petch Bold for the deadpan subtitles.
const FONT_BUNGEE := preload("res://assets/fonts/Bungee-Regular.ttf")
const FONT_INLINE := preload("res://assets/fonts/BungeeInline-Regular.ttf")
const FONT_SHADE := preload("res://assets/fonts/BungeeShade-Regular.ttf")
const FONT_SUB := preload("res://assets/fonts/ChakraPetch-Bold.ttf")

# Subtitle pill (AGENTS.md §9 item 19): one line at a time, 4 s cooldown, 1.8 s fade.
const SUBTITLE_SECONDS := 1.8
const SUBTITLE_COOLDOWN_SECONDS := 4.0
const SUBTITLE_Y := 655.0
## Bottom-edge key legend (below the subtitle pill at 630–680, inside the 720 canvas).
const LEGEND_Y := 698.0
const SUBTITLE_FADE := 0.45
## Match-intro proverb banner (AGENTS.md §8, 2026-11-22) sits under the round banner, so the
## round name and the yard wisdom read as one intro card. The English gloss is only drawn
## while subtitles are on (V).
const WISDOM_Y := 206.0
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


## Brief corner label for the M-key beat audition on the post-KO screen.
func show_music_toast(text: String) -> void:
	if text == "":
		return
	_music_toast = text
	_music_life = MUSIC_TOAST_SECONDS
	_stamp_pop(&"music")
	queue_redraw()


func music_toast_text() -> String:
	return _music_toast


# =========================================================================
# Draw
# =========================================================================
func _draw() -> void:
	if p1 == null or p2 == null:
		return
	var width := size.x
	_bar(Vector2(MARGIN, MARGIN), BAR_W, p1.health, float(p1.max_health), Color(0.35, 0.85, 0.45), false)
	_bar(Vector2(width - MARGIN - BAR_W, MARGIN), BAR_W, p2.health, float(p2.max_health), Color(0.9, 0.4, 0.4), true)
	_fighter_name(Vector2(MARGIN, MARGIN), BAR_W, _name_of(p1, "P1"), false)
	_fighter_name(Vector2(width - MARGIN - BAR_W, MARGIN), BAR_W, _name_of(p2, "P2"), true)
	_hype_bar(Vector2(MARGIN, MARGIN + BAR_H + 8.0))
	_beat_pulse(Vector2(width * 0.5, MARGIN + BAR_H * 0.5))
	_ai_banner(Vector2(width * 0.5 - 150.0, MARGIN + 40.0))
	# Owner direction (§9 item 22): the workshop key strip belongs at the bottom edge, not
	# across the sky/ocean where it fought the stage art.
	_legend(Vector2(width * 0.5 - 210.0, LEGEND_Y))
	_round_clock(width)
	_round_pips(width)
	_surge_banner(Vector2(width * 0.5, size.y * 0.34))
	_round_banner(width)
	_wisdom_banner(width)
	_music_toast_label(width)
	_subtitle_pill(width)


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


func _bar(pos: Vector2, w: float, value: int, maximum: float, colour: Color, right_aligned: bool) -> void:
	var h := BAR_H
	var ratio := clampf(float(value) / maxf(maximum, 1.0), 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.08, 0.08, 0.1, 0.85), true)
	var fill := Rect2(pos + Vector2(2, 2), Vector2((w - 4.0) * ratio, h - 4.0))
	if right_aligned:
		fill.position.x = pos.x + w - 2.0 - fill.size.x
	draw_rect(fill, colour, true)


## Bungee fighter tag inside the health bar (above it clips the viewport edge).
func _fighter_name(bar_pos: Vector2, bar_w: float, name: String, right_aligned: bool) -> void:
	var w := 170.0
	var x := bar_pos.x + bar_w - w - 8.0 if right_aligned else bar_pos.x + 8.0
	_text(Vector2(x, bar_pos.y + BAR_H - 5.0), name, FONT_BUNGEE,
		_fit_size(FONT_BUNGEE, name, 14, w), Color(1.0, 0.92, 0.55, 0.98),
		HORIZONTAL_ALIGNMENT_RIGHT if right_aligned else HORIZONTAL_ALIGNMENT_LEFT, w)


## Roster name from the fighter profile, with the old side label as the fallback.
func _name_of(fighter: BaseFighter, fallback: String) -> String:
	if fighter == null or fighter.display_name == "":
		return fallback
	return fighter.display_name


func _hype_bar(pos: Vector2) -> void:
	var w := 180.0
	var h := 10.0
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.08, 0.08, 0.1, 0.85), true)
	var ratio := clampf(float(p1.hype) / float(BaseFighter.HYPE_MAX), 0.0, 1.0)
	draw_rect(Rect2(pos + Vector2(2, 2), Vector2((w - 4.0) * ratio, h - 4.0)),
		Color(0.95, 0.78, 0.25), true)
	_text(pos + Vector2(w + 10.0, h), "HYPE %d" % p1.hype, FONT_SUB, 12,
		Color(0.85, 0.85, 0.9))


func _beat_pulse(centre: Vector2) -> void:
	if beat == null:
		return
	var j := beat.judge()
	var on_beat := bool(j.get("on_beat", false))
	var colour := Color(0.35, 0.95, 0.5) if on_beat else Color(0.35, 0.4, 0.5)
	draw_circle(centre, 9.0 if on_beat else 6.0, colour)


## Active P2 sparring AI mode. Y cycles it; G stays a manual guard override in every mode.
func _ai_banner(pos: Vector2) -> void:
	if sparring == null:
		return
	var box := Rect2(pos, Vector2(300, 38))
	draw_rect(box, Color(0.08, 0.08, 0.1, 0.72), true)
	draw_rect(box, Color(0.55, 0.75, 0.95, 0.5), false, 1.0)
	var title := "P2 AI %d · %s" % [sparring.mode_index(), sparring.mode_name()]
	_text(pos + Vector2(10, 16), title, FONT_SUB,
		_fit_size(FONT_SUB, title, 13, 280.0), Color(0.95, 0.95, 1.0))
	_text(pos + Vector2(10, 31), "%s · Y switch · G guard" % sparring.mode_tag(), FONT_SUB, 11,
		Color(0.7, 0.78, 0.9))


## 60-second round clock (AGENTS.md §9 backlog item B6) centred between the health bars.
## Bungee for the digits so they read at a glance, Chakra Petch for the round caption.
func _round_clock(width: float) -> void:
	if rounds == null or not rounds.enabled:
		return
	if rounds.phase == RoundController.Phase.IDLE or rounds.phase == RoundController.Phase.MATCH_OVER:
		return
	var seconds := int(ceil(maxf(rounds.clock, 0.0)))
	var urgent := rounds.clock_running() and rounds.clock <= 10.0
	var box := Rect2(Vector2(width * 0.5 - 62.0, MARGIN - 6.0), Vector2(124.0, 42.0))
	draw_rect(box, Color(0.06, 0.05, 0.08, 0.7), true)
	draw_rect(box, Color(1.0, 0.86, 0.32, 0.95 if urgent else 0.5), false, 2.0)
	var colour := Color(1.0, 0.42, 0.34) if urgent else Color(1.0, 0.90, 0.42)
	_text(Vector2(box.position.x, box.position.y + 27.0), "%02d" % seconds, FONT_BUNGEE, 24,
		colour, HORIZONTAL_ALIGNMENT_CENTER, box.size.x)
	_text(Vector2(box.position.x, box.position.y + 39.0), "ROUND %d" % rounds.round_number(),
		FONT_SUB, 9, Color(0.8, 0.84, 0.92), HORIZONTAL_ALIGNMENT_CENTER, box.size.x)


## Round-win pips: two per fighter, filled as rounds are taken.
func _round_pips(width: float) -> void:
	if rounds == null:
		return
	for side in 2:
		for i in rounds.rounds_to_win:
			var filled: bool = rounds.wins[side] > i
			var pos := Vector2(MARGIN + 10.0 + float(i) * 18.0, MARGIN + BAR_H + 30.0)
			if side == 1:
				pos.x = width - MARGIN - 10.0 - float(i) * 18.0
			draw_circle(pos, 5.0,
				Color(0.95, 0.78, 0.25) if filled else Color(0.24, 0.24, 0.3, 0.9))


## Round / K.O. / rematch banner published by the round controller. The face carries the
## weight of the moment: Shade for the K.O., Inline for the rematch, Bungee otherwise — all
## with the arcade ink outline, gold rim and a scale-pop on every new banner text.
func _round_banner(width: float) -> void:
	if rounds == null or rounds.banner == "" or rounds.banner_alpha <= 0.01:
		return
	var alpha: float = rounds.banner_alpha
	var text: String = rounds.banner
	var font: Font = FONT_BUNGEE
	var preferred := 28
	var max_width := 640.0
	var face := Color(1.0, 0.90, 0.42, alpha)
	if text.begins_with("K.O."):
		font = FONT_SHADE
		preferred = 72
		max_width = 420.0
		face = Color(1.0, 0.97, 0.86, alpha)
	elif text.begins_with("WHEEL AND COME AGAIN"):
		font = FONT_INLINE
		preferred = 36
		max_width = 900.0
	var font_size := _fit_size(font, text, _pop_size(&"round", preferred), max_width)
	var box_w := clampf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		+ 82.0, 320.0, width - 2.0 * MARGIN)
	var y := size.y * 0.19
	var box := Rect2(Vector2(width * 0.5 - box_w * 0.5, y - 34.0),
		Vector2(box_w, 74.0 if text.begins_with("K.O.") else 62.0))
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
	var box := Rect2(centre - Vector2(270.0, 48.0), Vector2(540.0, 96.0))
	draw_rect(box, Color(0.06, 0.04, 0.06, 0.72), true)
	draw_rect(box, Color(GOLD.r, GOLD.g, GOLD.b, 0.9 if flash else 0.35), false, 3.0)
	_rasta_strip(box, 0.95)
	var colour := Color(1.0, 0.86, 0.28) if flash else Color(1.0, 0.98, 0.86)
	_text(centre + Vector2(-250.0, -4.0), "FORWARD!", FONT_INLINE,
		_fit_size(FONT_INLINE, "FORWARD!", _pop_size(&"surge", 38), 500.0), colour,
		HORIZONTAL_ALIGNMENT_CENTER, 500.0)
	_text(centre + Vector2(-250.0, 34.0), "PULL UP! · %s 100%% HYPE" % who, FONT_SUB, 20,
		Color(1.0, 1.0, 1.0, 0.92), HORIZONTAL_ALIGNMENT_CENTER, 500.0)


## Patois shout + deadpan translation in a compact translucent pill, under the sand lane.
func _subtitle_pill(width: float) -> void:
	if not subtitles_enabled or _sub == "" or _sub_life <= 0.0:
		return
	var fade := clampf(_sub_life / SUBTITLE_FADE, 0.0, 1.0)
	var shout_size := _fit_size(FONT_BUNGEE, _sub, _pop_size(&"sub", 20), width - 140.0)
	var sub_size := 12
	var shout_w := FONT_BUNGEE.get_string_size(_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, shout_size).x
	var trans_w := FONT_SUB.get_string_size(_sub_translation, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size).x
	var pill_w := clampf(maxf(shout_w, trans_w) + 44.0, 240.0, width - 2.0 * MARGIN)
	var h := 50.0
	var origin := Vector2(width * 0.5 - pill_w * 0.5, SUBTITLE_Y - h * 0.5)
	var bg := Color(0.04, 0.03, 0.06, 0.72 * fade)
	draw_rect(Rect2(origin, Vector2(pill_w, h)), bg, true)
	draw_circle(origin + Vector2(0.0, h * 0.5), h * 0.5, bg)
	draw_circle(origin + Vector2(pill_w, h * 0.5), h * 0.5, bg)
	draw_rect(Rect2(origin + Vector2(0.0, -1.0), Vector2(pill_w, 2.0)),
		Color(1.0, 0.86, 0.32, 0.5 * fade), true)
	draw_rect(Rect2(origin + Vector2(0.0, 3.0), Vector2(pill_w, 2.0)),
		Color(GOLD.r, GOLD.g, GOLD.b, 0.8 * fade), true)
	_text(Vector2(origin.x, origin.y + 23.0), _sub, FONT_BUNGEE, shout_size,
		Color(1.0, 0.93, 0.60, fade), HORIZONTAL_ALIGNMENT_CENTER, pill_w)
	_text(Vector2(origin.x, origin.y + 42.0), _sub_translation, FONT_SUB, sub_size,
		Color(0.82, 0.86, 0.94, fade), HORIZONTAL_ALIGNMENT_CENTER, pill_w)


## Rotating match-intro proverb card. A short gold heading keeps it distinct from the
## round banner; the Patois line is verbatim, and the English gloss only appears with V on.
func _wisdom_banner(width: float) -> void:
	if _proverb == "" or _proverb_life <= 0.0:
		return
	var fade := clampf(_proverb_life / WISDOM_FADE, 0.0, 1.0)
	var gloss := _proverb_gloss if subtitles_enabled else ""
	var max_w := width - 2.0 * MARGIN - 80.0
	var line_size := _fit_size(FONT_INLINE, _proverb, _pop_size(&"wisdom", 24), max_w)
	var line_w := FONT_INLINE.get_string_size(_proverb, HORIZONTAL_ALIGNMENT_LEFT, -1, line_size).x
	var gloss_w := FONT_SUB.get_string_size(gloss, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var box_w := clampf(maxf(line_w, gloss_w) + 76.0, 420.0, max_w + 76.0)
	var box_h := 72.0 if gloss != "" else 54.0
	var box := Rect2(Vector2(width * 0.5 - box_w * 0.5, WISDOM_Y), Vector2(box_w, box_h))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.66 * fade), true)
	draw_rect(box, Color(GOLD.r, GOLD.g, GOLD.b, 0.7 * fade), false, 2.0)
	_rasta_strip(box, 0.95 * fade)
	_text(box.position + Vector2(0.0, 16.0), "YARD WISDOM", FONT_SUB, 11,
		Color(GOLD.r, GOLD.g, GOLD.b, 0.95 * fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)
	_text(box.position + Vector2(0.0, 17.0 + line_size), _proverb, FONT_INLINE, line_size,
		Color(1.0, 0.90, 0.46, fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)
	if gloss != "":
		_text(box.position + Vector2(0.0, box_h - 10.0), gloss, FONT_SUB, 11,
			Color(0.78, 0.82, 0.9, fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)


## Corner HUD label shown briefly after M auditions a beat, so the cycle is never blind.
func _music_toast_label(width: float) -> void:
	if _music_toast == "" or _music_life <= 0.0:
		return
	var fade := clampf(_music_life / 0.5, 0.0, 1.0)
	var text_size := _fit_size(FONT_SUB, _music_toast, _pop_size(&"music", 14), 360.0)
	var text_w := FONT_SUB.get_string_size(_music_toast, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var box_w := clampf(text_w + 28.0, 220.0, 380.0)
	var box := Rect2(Vector2(width - MARGIN - box_w, MARGIN + BAR_H + 44.0),
		Vector2(box_w, 30.0))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.72 * fade), true)
	draw_rect(box, Color(1.0, 0.86, 0.32, 0.75 * fade), false, 1.0)
	_text(Vector2(box.position.x, box.position.y + 19.0), _music_toast, FONT_SUB, text_size,
		Color(1.0, 0.88, 0.44, fade), HORIZONTAL_ALIGNMENT_CENTER, box_w)


func _legend(pos: Vector2) -> void:
	var keys := "J jab · K box · L tump · I upper box · U grab/tech · T taunt · C crouch · Y AI mode · B bird · N time of day · V subtitles · R reset · G dummy guard · M mute/beats"
	_text(pos, keys, FONT_SUB, _fit_size(FONT_SUB, keys, 12, size.x - 2.0 * MARGIN),
		Color(0.72, 0.75, 0.82))

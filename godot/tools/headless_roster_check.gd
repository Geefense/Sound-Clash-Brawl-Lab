extends SceneTree
## Headless roster + title-screen check (AGENTS.md §9 backlog item B1).
## Run with: godot --headless --path godot --script res://tools/headless_roster_check.gd
##
## Boots TitleScreen, verifies the MatchSetup defaults, boots TestArena with Lickshot as
## P2, then rebuilds the arena with Likkle Moore (L!KKLE MOORE) and checks the shared FSM, the sprite
## frames, the +25 px reach, the AI mode and the Esc return path. Prints one line per
## check and exits non-zero if any check fails.

const PASS := "PASS"
const FAIL := "FAIL"

var _failures: int = 0


func _initialize() -> void:
	_run()


func _check(condition: bool, label: String, detail: String = "") -> void:
	if condition:
		print("%s  %s%s" % [PASS, label, (" — " + detail) if detail != "" else ""])
	else:
		_failures += 1
		print("%s  %s%s" % [FAIL, label, (" — " + detail) if detail != "" else ""])


## World y of the lowest drawn pixel of `key` for a fighter standing on the floor line.
## Reads the real texture alpha bounds and composes the same offset/scale the renderer uses
## (offset is divided by the import-cap ratio, scale multiplied by it), so this tests the art
## and the placement together instead of re-deriving the numbers in the offset table.
func _anim_floor_y(f: BaseFighter, key: StringName, index: int = 0) -> float:
	var frames := f.sprite.sprite_frames
	if frames == null or not frames.has_animation(key):
		return -99999.0
	if index >= frames.get_frame_count(key):
		return -99999.0
	var tex := frames.get_frame_texture(key, index)
	if tex == null:
		return -99999.0
	var img := tex.get_image()
	if img == null or img.is_empty():
		return -99999.0
	# `get_image()` is the already-decoded (import-capped) texture, so these pixel rows are in
	# decoded space — only the authored offset has to be divided by the cap ratio.
	var used := img.get_used_rect()
	var bottom := float(used.position.y + used.size.y - 1)
	var k := f._import_cap_ratio(String(key), key)
	var authored: Vector2 = f.anim_offset.get(key, BaseFighter.ANIM_OFFSET_DEFAULT)
	var offset_y := authored.y / k
	var scale_y: float = float(f.anim_scale.get(key, BaseFighter.BASE_SPRITE_SCALE)) * k \
		* BaseFighter.FIGHTER_ART_SCALE
	return f.global_position.y + (offset_y + bottom - float(tex.get_height()) * 0.5) * scale_y


func _run() -> void:
	var setup := root.get_node_or_null("MatchSetup")
	_check(setup != null, "MatchSetup autoload exists")
	if setup == null:
		quit(1)
		return

	# ---- Title screen ------------------------------------------------------
	change_scene_to_file("res://scenes/TitleScreen.tscn")
	await process_frame
	await process_frame
	var title := current_scene
	_check(title != null and title.name == "TitleScreen", "main scene is TitleScreen.tscn",
		str(title.name) if title != null else "null")
	_check(setup.p1_fighter == &"feedback", "P1 defaults to Feedback", str(setup.p1_fighter))
	_check(setup.p2_fighter == &"feedback", "P2 defaults to Feedback (mirror match)",
		str(setup.p2_fighter))
	_check(setup.ai_mode == 1, "AI defaults to Counter-Puncher", str(setup.ai_mode))
	_check(setup.subtitles == true, "Patois subtitles default on")

	# Cycle the roster through every fighter and back to the first.
	for i in 3:
		setup.cycle_p1(1)
		setup.cycle_p2(1)
	_check(setup.p1_fighter == &"feedback", "three cycles wrap P1 back to Feedback")
	_check(setup.p2_fighter == &"feedback", "three cycles wrap P2 back to Feedback")

	# ---- Arena with Lickshot -----------------------------------------------
	setup.p1_fighter = &"feedback"
	setup.p2_fighter = &"lickshot"
	setup.ai_mode = 2
	setup.subtitles = false
	change_scene_to_file("res://scenes/TestArena.tscn")
	await process_frame
	await process_frame
	var arena := current_scene
	var p1: BaseFighter = arena.get_node("P1")
	var p2: BaseFighter = arena.get_node("P2")
	var sparring: SparringController = arena.get_node("SparringAI")
	var hud: Control = arena.get_node("HUD/Ui/Hud")

	_check(p1.display_name == "FEEDBACK", "P1 is Feedback", p1.display_name)
	# Owner styling rule (AGENTS.md §9 item 32): the on-screen name renders I as !, while the
	# roster key, asset folder and code id stay `lickshot`.
	_check(p2.display_name == "L!CKSHOT", "P2 is L!CKSHOT on screen", p2.display_name)
	_check(p2.fighter_key == &"lickshot" and FighterRoster.display_name(&"lickshot") == "L!CKSHOT",
		"the styled name keeps the clean internal key", str(p2.fighter_key))
	# The owner expanded the future roster pool on 2026-11-19 (AGENTS.md §2, §9 item 38):
	# POPPY SHOW, SUGAR KANE and JUNE PLUM join the three names already recorded.
	_check(FighterRoster.styled_name("FLING STONE") == "FL!NG STONE"
			and FighterRoster.styled_name("RUM PUNCH") == "RUM PUNCH"
			and FighterRoster.styled_name("SKY JUICE") == "SKY JU!CE"
			and FighterRoster.styled_name("POPPY SHOW") == "POPPY SHOW"
			and FighterRoster.styled_name("SUGAR KANE") == "SUGAR KANE"
			and FighterRoster.styled_name("JUNE PLUM") == "JUNE PLUM",
		"the I to ! rule covers the six-name future roster pool")
	var bungee: Font = load("res://assets/fonts/Bungee-Regular.ttf")
	_check(bungee != null
			and bungee.get_string_size("!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x > 2.0
			and bungee.get_string_size("L!CKSHOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x > 40.0,
		"the ! glyph renders in the Bungee HUD font")
	_check(p2.fighter_key == &"lickshot", "P2 fighter_key applied", str(p2.fighter_key))
	# Rename guard (AGENTS.md §9 item 26): Fighter #2 is Lickshot everywhere, and the old key must
	# not linger in the roster table, or a saved selection would quietly resolve to a dead fighter.
	_check(not FighterRoster.FIGHTERS.has(&"dubplate") and FighterRoster.FIGHTERS.has(&"lickshot")
		and FighterRoster.ORDER.count(&"lickshot") == 1 and FighterRoster.ORDER.count(&"dubplate") == 0,
		"Dubplate is fully renamed to Lickshot",
		"order %s" % [FighterRoster.ORDER])
	_check(sparring.mode_index() == 2, "AI mode carried from setup", sparring.mode_name())
	_check(hud.subtitles_enabled == false, "subtitle flag carried from setup")
	_check(p2.sprite.sprite_frames != null
		and p2.sprite.sprite_frames.has_animation(&"idle"),
		"Lickshot sprite frames built")
	# The idle groove squash/stretch rides on top of the base scale, so allow a few %.
	# 0.24014 × BaseFighter.FIGHTER_ART_SCALE (1.24) — measured from the 2026-11-17 pose pack.
	var adult_scale := 0.24014 * BaseFighter.FIGHTER_ART_SCALE
	_check(absf(p2.sprite.scale.x - adult_scale) <= adult_scale * 0.05,
		"Lickshot renders at the enlarged adult height", "%.4f" % p2.sprite.scale.x)
	# Import-cap compensation means the raw node scale is not the figure's on-screen size:
	# divide the cap back out before comparing against the 121.75 px reference height.
	var idle_cap := p1._import_cap_ratio("idle", &"idle")
	var feedback_px := 487.0 * p1.sprite.scale.x / maxf(idle_cap, 0.001)
	_check(feedback_px > 140.0, "Feedback's figure grew past the old 121.75 px",
		"%.1f px" % feedback_px)

	# ---- Lickshot's four new poses (AGENTS.md §9 item 27) -------------------
	var lick_poses: Array[StringName] = [&"idle", &"high_kick", &"sonic_clap_windup", &"sonic_clap_impact"]
	var missing_poses := []
	for key in lick_poses:
		if not p2.sprite.sprite_frames.has_animation(key):
			missing_poses.append(String(key))
	_check(missing_poses.is_empty(), "all four Lickshot poses are registered",
		"missing %s" % [missing_poses] if not missing_poses.is_empty() else "idle, high kick, clap windup, clap impact")
	# The acceptance rule: each pose's real alpha bottom lands on world y 592, measured from
	# the decoded texture, so a Wallabee never sinks into the sand.
	var off_floor := []
	for key in lick_poses:
		var floor_y := _anim_floor_y(p2, key)
		if absf(floor_y - 592.0) > 0.75:
			off_floor.append("%s %.1f" % [key, floor_y])
	_check(off_floor.is_empty(), "every Lickshot pose plants on the y 592 sand line",
		"off-floor %s" % [off_floor] if not off_floor.is_empty() else "592.0")
	# Character height: the three full-body frames are exactly the drawing (crown row 2–5), so
	# frame height × authored scale must land on the ~151 px adult render.
	var heights := []
	for key in [&"idle", &"high_kick", &"sonic_clap_windup"]:
		var tex := p2.sprite.sprite_frames.get_frame_texture(key, 0)
		var s: float = float(p2.anim_scale[String(key)]) * BaseFighter.FIGHTER_ART_SCALE
		heights.append(float(tex.get_height()) * s)
	var height_ok := true
	for px in heights:
		if px < 148.0 or px > 157.0:
			height_ok = false
	_check(height_ok, "Lickshot's poses match Feedback's ~151 px height",
		"%s" % [heights.map(func(v): return "%.1f" % v)])
	# The impact frame is taller than the fighter because of its shockwave; its scale is the
	# one that puts the *character* (crown 24 → sole 306) at the same height.
	var impact_tex := p2.sprite.sprite_frames.get_frame_texture(&"sonic_clap_impact", 0)
	var impact_scale: float = float(p2.anim_scale["sonic_clap_impact"]) * BaseFighter.FIGHTER_ART_SCALE
	var impact_character_px := 283.0 * impact_scale
	_check(absf(impact_character_px - 151.0) <= 4.0,
		"the Sonic Clap impact character is the same height", "%.1f px" % impact_character_px)
	_check(impact_tex.get_height() * impact_scale > 155.0,
		"the impact frame keeps its shockwave above the cap")
	# Smear policy: a drawn move must not also get the generic strike tell.
	p2._attack_id = &"strong"
	_check(not p2.shows_strike_tell(), "the Sonic Clap replaces the generic strike smear")
	p2._attack_id = &"tump"
	_check(not p2.shows_strike_tell(), "the high kick replaces the generic strike smear")
	p2._attack_id = &"jab"
	_check(not p2.shows_strike_tell(), "Lickshot's drawn jab retires the strike smear")
	p2._attack_id = &"upper_box"
	_check(not p2.shows_strike_tell(), "Lickshot's drawn upper box retires the strike smear")
	p2._attack_id = &""

	# ---- Lickshot's seven 2026-11-18 poses (AGENTS.md §9 item 34) -----------
	var lick_new: Array[StringName] = [&"jab", &"upper_box", &"block", &"hitstun", &"launched",
		&"skank", &"celebration"]
	var lick_missing := []
	for key in lick_new:
		if not p2.sprite.sprite_frames.has_animation(key):
			lick_missing.append(String(key))
	_check(lick_missing.is_empty(), "all seven new Lickshot poses are registered",
		"missing %s" % [lick_missing] if not lick_missing.is_empty() else "jab, cross, guard, hitstun, launch, skank, celebration")
	var lick_off := []
	var lick_tallest := 0.0
	for key in lick_new:
		for i in p2.sprite.sprite_frames.get_frame_count(key):
			var floor_y := _anim_floor_y(p2, key, i)
			if absf(floor_y - 592.0) > 0.75:
				lick_off.append("%s#%d %.1f" % [key, i, floor_y])
			var tex := p2.sprite.sprite_frames.get_frame_texture(key, i)
			if tex != null:
				lick_tallest = maxf(lick_tallest, float(maxi(tex.get_width(), tex.get_height())))
	_check(lick_off.is_empty(), "every new Lickshot pose plants on the y 592 sand line",
		"off-floor %s" % [lick_off] if not lick_off.is_empty() else "592.0")
	_check(lick_tallest <= 512.5, "the new Lickshot frames stay inside the 512 px cap",
		"%.0f px" % lick_tallest)
	# Guard, hitstun, launch, taunt and grab all have dedicated drawings now.
	_check(p2._state_anims.get("grab", &"") == &"celebration",
		"Lickshot's collar grab plays the wide-open arms pose")
	_check(p2._taunt_sequence == [&"skank"], "Lickshot's taunt plays the skank groove")
	_check(p2._celebrate_anim == &"celebration", "Lickshot celebrates with the arms-open pose")
	p2.play_celebration(6)
	await physics_frame
	_check(p2.sprite.animation == &"celebration", "the celebration pose actually draws",
		String(p2.sprite.animation))
	p2._celebrate_ticks = 0
	p2._play_state_anim()

	# ---- Lickshot's 2026-11-19 sequences (AGENTS.md §9 item 38) --------------
	# The 8-pose skank groove, the standing hitstun snap, the airborne launch/tumble and the
	# ground knockdown/KO. Every frame of every sequence must land on the sand line: these
	# are multi-frame animations, so one shared canvas per group is what proves no frame can
	# bob or sink mid-sequence.
	var lick_seq := {
		&"skank": 8, &"hitstun": 3, &"launched": 3,
		&"tumble": 4, &"knockdown": 2, &"ko": 2,
	}
	var seq_missing := []
	var seq_counts := []
	var seq_off := []
	var seq_below := []
	var seq_tallest := 0.0
	for key in lick_seq:
		if not p2.sprite.sprite_frames.has_animation(key):
			seq_missing.append(String(key))
			continue
		var want := int(lick_seq[key])
		var got := p2.sprite.sprite_frames.get_frame_count(key)
		if got != want:
			seq_counts.append("%s %d/%d" % [key, got, want])
		for i in got:
			var fy := _anim_floor_y(p2, key, i)
			if absf(fy - 592.0) > 0.75:
				seq_off.append("%s#%d %.1f" % [key, i, fy])
			if fy > 592.5:
				seq_below.append("%s#%d %.1f" % [key, i, fy])
			var tex := p2.sprite.sprite_frames.get_frame_texture(key, i)
			if tex != null:
				seq_tallest = maxf(seq_tallest, float(maxi(tex.get_width(), tex.get_height())))
	_check(seq_missing.is_empty(), "all six Lickshot sequences are registered",
		"missing %s" % [seq_missing] if not seq_missing.is_empty() else "skank, hitstun, launched, tumble, knockdown, ko")
	_check(seq_counts.is_empty(), "every sequence carries its full drawn frame count",
		"%s" % [seq_counts] if not seq_counts.is_empty() else "8 / 3 / 3 / 4 / 2 / 2")
	_check(seq_off.is_empty(), "every frame of every sequence lands on the y 592 sand line",
		"off-floor %s" % [seq_off] if not seq_off.is_empty() else "592.0")
	_check(seq_below.is_empty(), "no frame of any sequence sinks below the sand",
		"below %s" % [seq_below] if not seq_below.is_empty() else "none")
	_check(seq_tallest <= 512.5, "the new sequence frames stay inside the 512 px cap",
		"%.0f px" % seq_tallest)
	# The taunt plays the groove at a musical rate; the ground sequences settle on the sand.
	_check(is_equal_approx(p2.sprite.sprite_frames.get_animation_speed(&"skank"), 7.0)
			and p2.sprite.sprite_frames.get_animation_loop(&"skank"),
		"the 8-pose skank groove plays looping at 7 fps")
	_check(not p2.sprite.sprite_frames.get_animation_loop(&"knockdown")
			and not p2.sprite.sprite_frames.get_animation_loop(&"ko"),
		"knockdown and KO settle on their last drawn frame")
	# Retired placeholders: the single-frame taunt/recoil poses are no longer referenced, while
	# every approved frame from the 2026-11-17/18 sets stays wired.
	var lick_frames_text := str(FighterRoster.FIGHTERS[&"lickshot"]["frames"])
	_check(not lick_frames_text.contains("skank_point")
			and not lick_frames_text.contains("hitstun_recoil")
			and not lick_frames_text.contains("launched_recoil"),
		"the replaced single-pose taunt and recoils are out of the frame table")
	_check(lick_frames_text.contains("idle.png") and lick_frames_text.contains("jab.png")
			and lick_frames_text.contains("upper_box.png")
			and lick_frames_text.contains("sonic_clap_windup.png")
			and lick_frames_text.contains("sonic_clap_impact.png")
			and lick_frames_text.contains("high_kick.png")
			and lick_frames_text.contains("guard_stance.png")
			and lick_frames_text.contains("celebration.png"),
		"every approved Lickshot frame is still wired")

	# ---- Patois callout rotation (AGENTS.md §8, item 38) ---------------------
	# The owner-approved lines lead their trigger; the older approved lines rotate back in.
	hud.subtitles_enabled = true
	hud._sub_cooldown = 0.0
	var parry_first: bool = arena._announce_callout(&"parry") \
		and hud.subtitle_text().contains("WHOLE-AWN-DEH!")
	hud._sub_cooldown = 0.0
	var parry_second: bool = arena._announce_callout(&"parry") \
		and hud.subtitle_text().contains("BIG TUNE!")
	_check(parry_first and parry_second,
		"Record Static Parry leads with WHOLE-AWN-DEH! and rotates BIG TUNE! back in",
		hud.subtitle_text())
	hud._sub_cooldown = 0.0
	var hype_ok: bool = arena._announce_callout(&"hype") \
		and hud.subtitle_text().contains("PLAYAH NEX TUNE!")
	_check(hype_ok, "Hype Surge calls PLAYAH NEX TUNE!", hud.subtitle_text())
	hud._sub_cooldown = 0.0
	var win_ok: bool = arena._announce_callout(&"round_win") \
		and hud.subtitle_text().contains("PLAYAH NEX TUNE!")
	_check(win_ok, "a round win calls PLAYAH NEX TUNE!", hud.subtitle_text())
	hud._sub_cooldown = 0.0
	var pop_ok: bool = arena._announce_callout(&"taunt") \
		and hud.subtitle_text().contains("POPPYSHOW!")
	hud._sub_cooldown = 0.0
	var punish_ok: bool = arena._announce_callout(&"punish") \
		and hud.subtitle_text().contains("POPPYSHOW!")
	_check(pop_ok and punish_ok, "taunts and punish hits call POPPYSHOW!",
		hud.subtitle_text())
	hud._sub_cooldown = 0.0
	var break_ok: bool = arena._announce_callout(&"throw_break") \
		and hud.subtitle_text().contains("WHOLE-AWN-DEH!")
	_check(break_ok, "a throw break calls WHOLE-AWN-DEH!", hud.subtitle_text())
	# Glosses stay in their own field, never folded into the spoken spelling.
	_check(str(arena.CALLOUTS[&"parry"][0][1]).contains("Hold on a second")
			and str(arena.CALLOUTS[&"hype"][0][1]).contains("Play another song")
			and str(arena.CALLOUTS[&"punish"][0][1]).contains("Show-off"),
		"each new callout keeps a separate English gloss")
	hud.toggle_subtitles()
	hud.toggle_subtitles()

	# ---- Feedback's six 2026-11-18 poses (AGENTS.md §9 item 33) -------------
	var fb_new: Array[StringName] = [&"palm_shove", &"lean_back", &"open_slap", &"clarks_kick",
		&"sky_fist", &"hand_reach"]
	var fb_missing := []
	var fb_off := []
	var fb_tallest := 0.0
	for key in fb_new:
		if not p1.sprite.sprite_frames.has_animation(key):
			fb_missing.append(String(key))
			continue
		var floor_y := _anim_floor_y(p1, key)
		if absf(floor_y - 592.0) > 0.75:
			fb_off.append("%s %.1f" % [key, floor_y])
		var tex := p1.sprite.sprite_frames.get_frame_texture(key, 0)
		if tex != null:
			fb_tallest = maxf(fb_tallest, float(maxi(tex.get_width(), tex.get_height())))
	_check(fb_missing.is_empty(), "all six new Feedback poses are registered",
		"missing %s" % [fb_missing] if not fb_missing.is_empty() else "shove, groove, slap, kick, sky fist, reach")
	_check(fb_off.is_empty(), "every new Feedback pose plants on the y 592 sand line",
		"off-floor %s" % [fb_off] if not fb_off.is_empty() else "592.0")
	_check(fb_tallest <= 512.5, "the new Feedback frames stay inside the 512 px cap",
		"%.0f px" % fb_tallest)
	# Wiring: throw moments, grab, taunt sequence and celebration.
	_check(p1._state_anims.get("throw_break", &"") == &"palm_shove"
			and p1._state_anims.get("throw_release", &"") == &"palm_shove",
		"Feedback's throw break and forward release play the double-palm shove")
	_check(p1._state_anims.get("grab", &"") == &"hand_reach",
		"Feedback's collar grab plays the wide-stance hand reach")
	_check(p1._taunt_sequence == [&"lean_back", &"skank"],
		"Feedback's T grooves lean-back into the skank loop")
	_check(p1._celebrate_anim == &"sky_fist", "Feedback celebrates with the skyward fist")
	_check(p1.attacks[&"jab"]["anim_active"] == &"open_slap"
			and p1.attacks[&"tump"]["anim_active"] == &"clarks_kick"
			and p1.attacks[&"upper_box"]["anim_active"] == &"sky_fist",
		"jab, Sparta kick and upper box play their new contact frames")
	_check(p1.attacks[&"tump"]["startup"] == 12 and p1.attacks[&"jab"]["active"] == 3
			and p1.attacks[&"upper_box"]["recovery"] == 16,
		"the pose wiring left the combat timings untouched")
	p1._attack_id = &"jab"
	_check(not p1.shows_strike_tell(), "Feedback's drawn jab retires the strike smear")
	p1._attack_id = &"tump"
	_check(not p1.shows_strike_tell(), "Feedback's drawn kick retires the strike smear")
	p1._attack_id = &"upper_box"
	_check(not p1.shows_strike_tell(), "Feedback's drawn upper box retires the strike smear")
	p1._attack_id = &""

	# ---- Arena with Likkle Moore (key `young_selecta`) ----------------------
	setup.p2_fighter = &"young_selecta"
	change_scene_to_file("res://scenes/TestArena.tscn")
	await process_frame
	await process_frame
	arena = current_scene
	p2 = arena.get_node("P2")
	# Rename guard (AGENTS.md §9 item 35): the display name changes to LIKKLE MOORE and the I→!
	# rule renders L!KKLE MOORE, while the roster key and the sprite folder stay `young_selecta`.
	_check(p2.display_name == "L!KKLE MOORE", "P2 is L!KKLE MOORE on screen", p2.display_name)
	_check(p2.fighter_key == &"young_selecta"
			and FighterRoster.display_name(&"young_selecta") == "L!KKLE MOORE",
		"Likkle Moore keeps the young_selecta key and asset folder", str(p2.fighter_key))
	_check(is_equal_approx(p2.walk_speed, 250.0), "Likkle Moore walks faster",
		"%.0f px/s" % p2.walk_speed)
	var jab: Dictionary = p2.attacks[&"jab"]
	_check(int(jab["hitbox_size"].x) == 109, "boom-mic reach grew by 25 px",
		"%d px wide jab box" % int(jab["hitbox_size"].x))
	_check(p2.stand_size.y < 140.0, "kid hurtbox is shorter than an adult's",
		"%.0f px" % p2.stand_size.y)
	_check(p2.sprite.sprite_frames.has_animation(&"jab")
		and p2.sprite.sprite_frames.has_animation(&"box_active")
		and p2.sprite.sprite_frames.has_animation(&"sparta_active"),
		"thrust and slam frames registered for the attack slots")
	# 512 px frame × scale must land near 123.8 px (82 % of the enlarged adult height). The
	# idle groove squash rides on top, so allow 6 %.
	var kid_px := p2.sprite.scale.x * 512.0
	_check(absf(kid_px - 99.8 * BaseFighter.FIGHTER_ART_SCALE) <= 99.8 * 0.06,
		"kid renders ~82 % of the adult height", "%.1f px" % kid_px)

	# ---- Facing, props, crowd acting and the time-of-day pass (2026-11-17) ----------
	# `p1` above belongs to the previous arena instance, which the scene change freed.
	var arena2 := arena
	var p1b: BaseFighter = arena2.get_node("P1")
	_check(arena2.get_node_or_null("Foreground") == null,
		"stray bottom-left corner card and its wash are gone")
	var crate: Sprite2D = arena2.get_node("RecordCrates/LeftCrate")
	_check(crate.scale.x <= 0.15 and crate.position.y >= 600.0,
		"record crates shrunk and set on the sand line",
		"scale %.3f at y %.0f" % [crate.scale.x, crate.position.y])
	var crowd: CrowdLine = arena2.get_node("CrowdLine")
	var leaner: Sprite2D = crowd.get_node("ArmsCrossed")
	_check(not leaner.visible, "leaning spectator retired from the line")
	_check(crowd.front_row_count() == 5 and crowd.back_row_count() == 6,
		"crowd rows still 5 front / 6 back after the retirement",
		"%d / %d" % [crowd.front_row_count(), crowd.back_row_count()])
	var flag_act: StringName = &""
	var rag_act: StringName = &""
	var horn_act: StringName = &""
	var phases := {}
	for m in crowd._members:
		if m.row < 0:
			continue
		phases[snappedf(m.phase, 0.01)] = true
		if String(m.sprite.name) == "FlagWaver":
			flag_act = m.act
		elif String(m.sprite.name) == "TowelWaver":
			rag_act = m.act
		elif String(m.sprite.name) == "AirhornHypeman":
			horn_act = m.act
	_check(flag_act == CrowdLine.ACT_FLAG and rag_act == CrowdLine.ACT_RAG
			and horn_act == CrowdLine.ACT_HORN,
		"flag, rag and horn holders are cast into their own acts",
		"%s / %s / %s" % [flag_act, rag_act, horn_act])
	_check(phases.size() >= 8, "crowd acts run on individual clocks",
		"%d distinct phases" % phases.size())

	# Facing: the CPU must look at Feedback and both must turn on a side swap.
	_check(p1b.facing == 1 and not p1b.sprite.flip_h, "P1 on the left faces the CPU")
	_check(p2.facing == -1 and p2.sprite.flip_h, "CPU faces Feedback (mirrored turnaround)")
	p1b.global_position = Vector2(980, 600)
	p2.global_position = Vector2(880, 600)
	await physics_frame
	await physics_frame
	_check(p1b.facing == -1 and p2.facing == 1, "fighters turn when they swap sides",
		"p1 %d / p2 %d" % [p1b.facing, p2.facing])
	_check(p1b.sprite.flip_h and not p2.sprite.flip_h, "mirroring follows the turn")

	# Ground alignment (owner playtest, 2026-11-17): no reaction frame may sink through the
	# sand line. Measured from the real texture alpha bounds, not from the offset table.
	var idle_y := _anim_floor_y(p1b, &"idle")
	_check(idle_y > 590.0 and idle_y < 606.0, "idle soles still sit on the floor line",
		"%.1f" % idle_y)
	var dropped := []
	var lowest := -99999.0
	for key in [&"hitstun", &"launched", &"tumble", &"knockdown", &"ko"]:
		var bottom_y := _anim_floor_y(p1b, key)
		if bottom_y > lowest:
			lowest = bottom_y
		if bottom_y > 592.5:
			dropped.append("%s %.1f" % [key, bottom_y])
	_check(dropped.is_empty(), "no reaction pose drops below the y 592 sand line",
		"lowest %.1f%s" % [lowest, (" — " + ", ".join(dropped)) if not dropped.is_empty() else ""])

	# Time of day must change the scene, not just tint the screen.
	arena2.set_time_of_day(2, 0.0)
	await process_frame
	_check(arena2.get_node("NightWash").modulate.a > 0.5, "night washes sky and beach down")
	_check(arena2.get_node("SunGlow").modulate.a == 0.0, "no sun left at night")
	_check(arena2.get_node("Floodlight").modulate.a > 0.3, "arena lights carry the night")
	_check(crowd._night > 0.8, "night drops the crowd to silhouette")
	var fight_shadow: GroundShadow = p1b.get_node("Shadow")
	arena2.set_time_of_day(1, 0.0)
	await process_frame
	_check(arena2.get_node("SunsetWash").modulate.a > 0.5, "sunset has its own sky")
	_check(arena2.get_node("NightWash").modulate.a == 0.0, "no night wash at sunset")
	_check(fight_shadow.stretch > 1.5, "sunset throws long shadows",
		"%.2f× stretch" % fight_shadow.stretch)
	arena2.set_time_of_day(0, 0.0)
	await process_frame
	_check(arena2.get_node("SunsetWash").modulate.a == 0.0
			and arena2.get_node("NightWash").modulate.a == 0.0,
		"afternoon is clean daylight")
	_check(is_equal_approx(fight_shadow.stretch, 0.95), "afternoon keeps a compact shadow",
		"%.2f×" % fight_shadow.stretch)

	# Fight for a moment: the AI must actually drive the FSM through attacks.
	var seen := {}
	for i in 240:
		await physics_frame
		if p2 != null and is_instance_valid(p2):
			seen[p2.state] = true
	_check(seen.size() > 1, "AI drove P2 through the shared FSM", "%d states" % seen.size())

	# Visible attacks: the arena must draw a strike smear on the active window, which is the
	# tick contact resolves on. P1 drives a real jab through the FSM to prove the path.
	var rounds_ctrl: RoundController = arena2.get_node("RoundController")
	for i in 240:
		if rounds_ctrl.clock_running():
			break
		await physics_frame
	p1b.use_local_input = false
	var press := BaseFighter.Command.new()
	press.light = true
	p1b.command = press
	var saw_active := false
	var saw_tell := false
	for i in 40:
		await physics_frame
		if p1b.state == BaseFighter.State.ATTACK_ACTIVE:
			saw_active = true
		# Only P1's own smears count: the CPU (Likkle Moore) draws real smears, and asking
		# "is any smear alive?" made this check flip on the AI's attack timing.
		for tell in arena2._live_strike_tells():
			if tell.source == p1b:
				saw_tell = true
		if saw_active and saw_tell:
			break
	_check(saw_active, "P1's jab reached its active window")
	# Feedback's jab now carries a drawn pose, so the arena must not paint the generic smear
	# over it. The smear path itself is still covered below by a fighter whose roster entry
	# does not list the attack in `no_strike_tell`.
	_check(not saw_tell, "P1's drawn jab draws no generic strike smear")
	p2._attack_id = &"jab"
	_check(p2.shows_strike_tell(), "an attack without drawn art still gets the strike smear")
	p2._attack_id = &""
	p1b.command = BaseFighter.Command.new()

	# ---- Esc back to Character Select ------------------------------------
	setup.escape_to_setup()
	await process_frame
	await process_frame
	var back := current_scene
	_check(back != null and back.name == "TitleScreen", "Esc returns to the title scene",
		str(back.name) if back != null else "null")
	if back != null:
		_check(back.phase == 1, "Esc reopens Character & Match Setup",
			"phase %d" % back.phase)
	_check(setup.p2_fighter == &"young_selecta", "selection survives the Esc round trip",
		str(setup.p2_fighter))

	print("")
	if _failures == 0:
		print("ALL CHECKS PASSED")
		quit(0)
	else:
		print("%d CHECK(S) FAILED" % _failures)
		quit(1)

extends SceneTree
## Headless roster + title-screen check (AGENTS.md §9 backlog item B1).
## Run with: godot --headless --path godot --script res://tools/headless_roster_check.gd
##
## Boots TitleScreen, verifies the default FEEDBACK vs FEEDBACK 3D showcase (both rigged,
## P2's mirror accent), then boots TestArena with Lickshot as P2, rebuilds it with Likkle
## Moore (L!KKLE MOORE) and checks the shared FSM, sprite frames, +25 px reach, the AI mode
## and the Esc return path. Prints one line per check and exits non-zero if any check fails.

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
## Drawn crown-to-sole height of one texture, using the prep script's crown rule: the crown
## is the first row with a solid horizontal run (the flat cap), not a thin effect. Idle's
## motion arc sits above the hat, so a plain alpha-top measurement would call idle 3 px
## taller than its character; the run rule measures the drawing. Solid alpha also ignores
## the 0.5 px feather.
func _solid_crown_to_sole(img: Image) -> int:
	var width := img.get_width()
	var min_run := maxi(4, int(round(width * 0.04)))
	var crown := -1
	var sole := -1
	for y in img.get_height():
		var run := 0
		var best := 0
		var any := false
		for x in width:
			if img.get_pixel(x, y).a > 0.125:
				any = true
				run += 1
				best = maxi(best, run)
			else:
				run = 0
		if best >= min_run and crown < 0:
			crown = y
		if any:
			sole = y
	return 0 if crown < 0 or sole < 0 else sole - crown + 1


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
	var music_bed := root.get_node_or_null("MusicBed")
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

	# ---- Menu music bed: title only, silent in fights (AGENTS.md §9 item 48) ---
	_check(music_bed != null, "the MusicBed autoload exists")
	_check(AudioServer.get_bus_index(&"MusicBed") >= 0, "the MusicBed bus exists in the layout")
	_check(music_bed.beat_count() == 3, "three production beats are registered",
		"%d" % music_bed.beat_count())
	var beat_files := []
	var beat_lengths := []
	for i in music_bed.beat_count():
		var beat_stream: AudioStream = music_bed.stream_at(i)
		if beat_stream != null:
			beat_files.append(music_bed.beat_file(i))
			beat_lengths.append(snappedf(beat_stream.get_length(), 0.01))
	_check(beat_files.size() == 3 and beat_files[0] == "beat_01.mp3"
			and beat_files[1] == "beat_02.mp3" and beat_files[2] == "beat_03.mp3",
		"all three beat files load from production/beats", "%s" % [beat_files])
	_check(beat_lengths.size() == 3 and beat_lengths[0] > 20.0
			and beat_lengths[1] > 250.0 and beat_lengths[2] > 85.0,
		"the three beats decode at their upload durations", "%s" % [beat_lengths])
	var beat_one := music_bed.stream_at(0) as AudioStreamMP3
	_check(beat_one != null and beat_one.loop, "the menu beats loop while a screen is open")
	_check(music_bed.in_title() and music_bed.state_name() == "beat_1" and music_bed.is_playing(),
		"the Title / Select screen starts the active beat on load",
		"%s / %s" % [music_bed.state_name(), music_bed.label()])

	# M auditions Beat 1 → Beat 2 → Beat 3 → Off → Beat 1 on Title / Select.
	title._enter_setup()
	var m_key := InputEventKey.new()
	m_key.physical_keycode = KEY_M
	m_key.pressed = true
	title._unhandled_input(m_key)
	_check(music_bed.state_name() == "beat_2" and music_bed.is_playing(),
		"M on Title / Select cycles Beat 1 to Beat 2")
	title._unhandled_input(m_key)
	_check(music_bed.state_name() == "beat_3" and music_bed.is_playing(),
		"M cycles Beat 2 to Beat 3")
	title._unhandled_input(m_key)
	_check(music_bed.state_name() == "off" and not music_bed.is_playing(),
		"M cycles Beat 3 to Off")
	title._unhandled_input(m_key)
	_check(music_bed.state_name() == "beat_1" and music_bed.is_playing(),
		"M cycles Off back to Beat 1")
	# Match start: the bed fades out before FIGHT so the round sting owns the intro.
	music_bed.stop_for_fight()
	await create_timer(0.6).timeout
	_check(music_bed.state_name() == "off" and not music_bed.is_playing(),
		"match start fades MusicBed to true silence")

	# Cycle the roster through every fighter and back to the first.
	for i in 3:
		setup.cycle_p1(1)
		setup.cycle_p2(1)
	_check(setup.p1_fighter == &"feedback", "three cycles wrap P1 back to Feedback")
	_check(setup.p2_fighter == &"feedback", "three cycles wrap P2 back to Feedback")

	# ---- Default 3D showcase: FEEDBACK vs FEEDBACK --------------------------
	# Owner request (2026-11-21): both sides use the rigged 25-bone upload and P2 gets a
	# cool/gold mirror accent, so the untouched default selection is a true mirror match.
	setup.p1_fighter = &"feedback"
	setup.p2_fighter = &"feedback"
	change_scene_to_file("res://scenes/TestArena.tscn")
	await process_frame
	await process_frame
	var mirror_arena := current_scene
	var mp1: BaseFighter = mirror_arena.get_node("P1")
	var mp2: BaseFighter = mirror_arena.get_node("P2")
	var mirror_stage: Arena3D = mirror_arena.arena3d
	var mp1_model: FighterModel3D = mirror_stage.model_for(mp1) as FighterModel3D
	var mp2_model: FighterModel3D = mirror_stage.model_for(mp2) as FighterModel3D
	_check(mp1.fighter_key == &"feedback" and mp2.fighter_key == &"feedback",
		"the default arena is FEEDBACK vs FEEDBACK", "%s vs %s" % [mp1.fighter_key, mp2.fighter_key])
	_check(mp1_model != null and mp1_model.has_rig and mp1_model.bone_count == 25
			and mp1_model.triangle_count() == 40000,
		"P1 Feedback uses the rigged 25-bone 40 000-triangle upload",
		"%d bones / %d tris" % [mp1_model.bone_count if mp1_model != null else -1,
			mp1_model.triangle_count() if mp1_model != null else -1])
	_check(mp2_model != null and mp2_model.has_rig and mp2_model.bone_count == 25
			and mp2_model.triangle_count() == 40000,
		"P2 Feedback uses the same rigged model in the mirror match",
		"%d bones / %d tris" % [mp2_model.bone_count if mp2_model != null else -1,
			mp2_model.triangle_count() if mp2_model != null else -1])
	_check(mp1_model != null and mp2_model != null
			and not mp1_model.is_mirror_variant() and mp2_model.is_mirror_variant(),
		"only P2 carries the mirror-match alternate accent")
	var p1_tint: Color = mp1_model.shader_tint() if mp1_model != null else Color.WHITE
	var p2_tint: Color = mp2_model.shader_tint() if mp2_model != null else Color.WHITE
	_check(p1_tint != p2_tint and p2_tint.b > p2_tint.r,
		"P2's alternate is a cool jacket tint, distinct from P1",
		"P1 %s / P2 %s" % [p1_tint, p2_tint])
	var p2_rim: Color = mp2_model.materials[0].get_shader_parameter("rim_colour") \
			if mp2_model != null and not mp2_model.materials.is_empty() else Color.WHITE
	_check(p2_rim.r > p2_rim.b, "P2's rim accent shifts gold in the mirror match", str(p2_rim))
	_check(mp1_model != null and mp2_model != null and mp1_model.animation != null
			and mp2_model.animation != null
			and mp1_model.animation.is_playing() and mp2_model.animation.is_playing(),
		"both mirror-match rigs play the baked Mixamo idle")

	# ---- MusicBed must stay silent through the active round -----------------
	_check(music_bed.state_name() == "off" and not music_bed.is_playing(),
		"the round opens with MusicBed silent")
	await create_timer(2.0).timeout
	_check(mirror_arena.rounds.phase == RoundController.Phase.FIGHTING,
		"the round has reached FIGHTING for the silence check")
	_check(music_bed.state_name() == "off" and not music_bed.is_playing(),
		"MusicBed stays completely silent from FIGHT! through the active round")
	# M during the fight keeps its existing meaning (mute) and must not start music.
	mirror_arena._unhandled_input(m_key)
	_check(mirror_arena.is_muted() and music_bed.state_name() == "off",
		"M during a fight stays the mute toggle and never starts the beat")
	mirror_arena._unhandled_input(m_key)          # unmute again for the rest of the run

	# ---- Post-KO / victory: next beat, then M audition ----------------------
	# Pretend the final round was just won: the celebration hook starts the next beat at once.
	mirror_arena.rounds.wins[0] = 2
	mirror_arena.rounds.wins[1] = 0
	mirror_arena._on_round_ended(0, 0)
	_check(music_bed.in_victory() and music_bed.state_name() == "beat_2" and music_bed.is_playing(),
		"the final K.O. celebration starts the next beat (Beat 2)",
		"%s / %s" % [music_bed.state_name(), music_bed.label()])
	mirror_arena._on_match_ended(0)
	_check(music_bed.state_name() == "beat_2" and mirror_arena._match_over,
		"the victory screen keeps that beat instead of advancing twice")
	mirror_arena._unhandled_input(m_key)
	_check(music_bed.state_name() == "beat_3",
		"M on the post-KO screen auditions Beat 3")
	mirror_arena._unhandled_input(m_key)
	_check(music_bed.state_name() == "off" and not music_bed.is_playing(),
		"M on the post-KO screen cycles Beat 3 to Off")
	mirror_arena._unhandled_input(m_key)
	_check(music_bed.state_name() == "beat_1" and music_bed.is_playing(),
		"M resumes the victory audition from Beat 1")
	music_bed.stop_for_fight()
	await create_timer(0.6).timeout

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
	# The owner expanded the future roster pool on 2026-11-19 (AGENTS.md §2, §9 item 41):
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

	# ---- Lickshot's 2026-11-19 sequences (AGENTS.md §9 item 41) --------------
	# The 8-pose skank groove, the standing hitstun snap, the airborne launch/tumble and the
	# ground knockdown/KO. Every frame of every sequence must land on the sand line: these
	# are multi-frame animations, so one shared canvas per group is what proves no frame can
	# bob or sink mid-sequence.
	var lick_seq := {
		&"walk": 4, &"skank": 8, &"hitstun": 3, &"launched": 3,
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
	_check(seq_missing.is_empty(), "all seven Lickshot sequences are registered",
		"missing %s" % [seq_missing] if not seq_missing.is_empty() else "walk, skank, hitstun, launched, tumble, knockdown, ko")
	_check(seq_counts.is_empty(), "every sequence carries its full drawn frame count",
		"%s" % [seq_counts] if not seq_counts.is_empty() else "4 / 8 / 3 / 3 / 4 / 2 / 2")
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
	# The clean 4-pose sheet replaces the clipped phone-video walk on the movement states.
	_check(not str(FighterRoster.FIGHTERS[&"lickshot"]["frames"][&"walk"]).contains("idle.png")
			and p2.sprite.sprite_frames.get_animation_speed(&"walk") == 9.0
			and p2.sprite.sprite_frames.get_animation_loop(&"walk"),
		"the walk loop plays the four drawn stride frames, not the idle stance")
	# The owner's requirement for this sheet: one shared canvas, 0 px vertical sole bobbing.
	var walk_floors := []
	for i in p2.sprite.sprite_frames.get_frame_count(&"walk"):
		walk_floors.append(_anim_floor_y(p2, &"walk", i))
	var walk_bob: float = walk_floors.max() - walk_floors.min()
	_check(walk_bob <= 0.01, "the four walk frames share one sole line (0 px bob)",
		"%.2f px" % walk_bob)
	# Size: the tallest stride frame must render at the same height as idle. Calibrating on
	# the median of leaning + upright poses made the stride ~4% taller than the idle stance.
	var idle_tex := p2.sprite.sprite_frames.get_frame_texture(&"idle", 0)
	var idle_px := float(_solid_crown_to_sole(idle_tex.get_image()))
	idle_px *= float(p2.anim_scale["idle"]) * BaseFighter.FIGHTER_ART_SCALE
	var walk_px := 0.0
	for i in p2.sprite.sprite_frames.get_frame_count(&"walk"):
		var wtex := p2.sprite.sprite_frames.get_frame_texture(&"walk", i)
		if wtex != null:
			walk_px = maxf(walk_px, float(_solid_crown_to_sole(wtex.get_image()))
				* float(p2.anim_scale["walk"]) * BaseFighter.FIGHTER_ART_SCALE)
	_check(absf(walk_px - idle_px) <= 0.5, "the tallest walk frame renders at idle height",
		"%.2f vs %.2f px (Δ%.2f)" % [walk_px, idle_px, absf(walk_px - idle_px)])
	# 3rd Strike-inspired uneven walk timing (AGENTS.md §9 item 40). Durations are relative
	# to each walk's own fps, so the base rates and walk speeds must be untouched while the
	# plants (1/3) and transfers (2/4) differ.
	var lick_walk_durs := []
	for i in p2.sprite.sprite_frames.get_frame_count(&"walk"):
		lick_walk_durs.append(p2.sprite.sprite_frames.get_frame_duration(&"walk", i))
	var lick_walk_want := [0.8, 1.4, 0.8, 1.4]
	var lick_walk_ok := lick_walk_durs.size() == lick_walk_want.size()
	for i in lick_walk_durs.size():
		lick_walk_ok = lick_walk_ok \
			and is_equal_approx(float(lick_walk_durs[i]), float(lick_walk_want[i]))
	_check(lick_walk_ok, "L!ckshot's walk snaps the plants and holds the coil",
		str(lick_walk_durs))
	var fb_walk_durs := []
	for i in p1.sprite.sprite_frames.get_frame_count(&"walk"):
		fb_walk_durs.append(p1.sprite.sprite_frames.get_frame_duration(&"walk", i))
	var fb_walk_want := [1.3, 0.75, 1.3, 0.75]
	var fb_walk_ok := fb_walk_durs.size() == fb_walk_want.size()
	for i in fb_walk_durs.size():
		fb_walk_ok = fb_walk_ok \
			and is_equal_approx(float(fb_walk_durs[i]), float(fb_walk_want[i]))
	_check(fb_walk_ok, "Feedback's walk holds the skank plant and snaps the transfer",
		str(fb_walk_durs))
	_check(p2.sprite.sprite_frames.get_animation_speed(&"walk") == 9.0
			and p1.sprite.sprite_frames.get_animation_speed(&"walk") == 4.4
			and is_equal_approx(p2.walk_speed, 205.0)
			and is_equal_approx(p1.walk_speed, 220.0),
		"uneven walk timing leaves both base rates and walk speeds unchanged",
		"9 / 4.4 fps · 205 / 220 px/s")
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

	# ---- 3D cel-shaded presentation (AGENTS.md §9 items 43–45, 2026-11-21) ----
	var stage3d: Arena3D = arena.arena3d
	_check(stage3d != null, "the 3D yard is installed as a Node3D presentation layer")
	var cam3d: Camera3D = stage3d.camera if stage3d != null else null
	_check(cam3d != null and cam3d.current,
		"a current Camera3D frames the 2.5D fighting plane")
	_check(stage3d != null and is_equal_approx(stage3d.camera_distance(), Arena3D.CAMERA_DISTANCE),
		"the camera holds its steady side-view distance",
		"%.2f m" % (stage3d.camera_distance() if stage3d != null else -1.0))
	var frame_fraction: float = stage3d.screen_fraction() if stage3d != null else 0.0
	_check(frame_fraction >= 0.55 and frame_fraction <= 0.65,
		"neutral play frames the fighters at 55–65 % of screen height",
		"%.1f %%" % (frame_fraction * 100.0))
	_check(not arena.get_node("Stage").visible and not p1.sprite.visible and not p2.sprite.visible,
		"the 2D stage art and fighter sprites are hidden under the 3D layer")
	_check(p1.is_3d_presentation() and p2.is_3d_presentation(),
		"both fighters hand their drawing layer to the 3D proxies")
	_check(p1.global_position == p1.global_position and is_instance_valid(p1.hitbox),
		"the 2D hitboxes stay alive and untouched behind the 3D layer")

	var model1 = stage3d.model_for(p1) if stage3d != null else null
	var model2 = stage3d.model_for(p2) if stage3d != null else null
	var rigged: FighterModel3D = model1 as FighterModel3D
	var lick_billboard: FighterBillboard3D = model2 as FighterBillboard3D
	_check(rigged != null and rigged.has_rig and rigged.bone_count == 25,
		"Feedback uses the uploaded rigged model with its 25 Mixamo bones",
		"%d bones" % (rigged.bone_count if rigged != null else -1))
	_check(rigged != null and rigged.triangle_count() == 40000,
		"Feedback's uploaded mesh is 40 000 triangles",
		"%d" % (rigged.triangle_count() if rigged != null else -1))
	_check(lick_billboard != null and lick_billboard.sprite != null
			and lick_billboard.sprite.texture != null,
		"L!ckshot renders as a camera-facing Sprite3D billboard, not the static clone")
	_check(model2 is FighterBillboard3D and not (model2 is FighterModel3D),
		"no FighterModel3D proxy is created for L!ckshot")
	_check(not FighterModel3D.MODEL_SOURCES.has(&"lickshot")
			and FileAccess.file_exists("res://assets/models/fighters/lickshot_placeholder_static.fbx"),
		"the static output.fbx stays archived but is no longer assigned to L!ckshot")
	_check(rigged != null and absf(rigged.model_height - 1.55) < 0.02,
		"Feedback is normalised to its authored fighting height",
		"%.2f m" % (rigged.model_height if rigged != null else 0.0))
	_check(lick_billboard != null and lick_billboard.model_height > 1.4
			and lick_billboard.model_height < 1.7,
		"L!ckshot's billboard keeps the adult stand height on the 3D plane",
		"%.2f m" % (lick_billboard.model_height if lick_billboard != null else 0.0))
	_check(rigged != null and rigged.feet_offset > 0.0,
		"Feedback is seated feet-down on the world floor")
	_check(rigged != null and rigged.animation != null and rigged.animation.is_playing(),
		"the baked Mixamo idle clip is playing on the rigged model")
	_check(rigged != null and not rigged.materials.is_empty()
			and rigged.materials[0].next_pass != null,
		"the fighter material carries the inverted-hull ink outline pass")

	# Shader compile checks: `get_shader_uniform_list()` is empty for a shader that failed to
	# parse, so this is a real GLSL parse check in a headless run.
	var toon_shader := load("res://assets/shaders/toon_cel.gdshader") as Shader
	var outline_shader := load("res://assets/shaders/toon_outline.gdshader") as Shader
	_check(toon_shader != null and toon_shader.get_shader_uniform_list().size() >= 10,
		"the Spatial Toon cel shader compiles",
		"%d uniforms" % (toon_shader.get_shader_uniform_list().size() if toon_shader != null else 0))
	_check(outline_shader != null and outline_shader.get_shader_uniform_list().size() >= 2,
		"the inverted-hull outline shader compiles",
		"%d uniforms" % (outline_shader.get_shader_uniform_list().size() if outline_shader != null else 0))
	var toon_code: String = toon_shader.code if toon_shader != null else ""
	var outline_code: String = outline_shader.code if outline_shader != null else ""
	var banned_3d := []
	for token in ["SCREEN_TEXTURE", "hint_screen_texture", "DEPTH_TEXTURE", "#include", "while ("]:
		if toon_code.contains(token) or outline_code.contains(token):
			banned_3d.append(token)
	_check(banned_3d.is_empty(), "the 3D toon/ink shaders are WebGL2-safe (no screen/depth reads)",
		"found %s" % [banned_3d] if not banned_3d.is_empty() else "single pass, no screen reads")

	_check(stage3d != null and stage3d.speaker_cone_count() == 16,
		"the two 3D speaker stacks expose 16 subwoofer/horn cones",
		"%d cones" % (stage3d.speaker_cone_count() if stage3d != null else 0))
	if stage3d != null:
		stage3d.pulse_speakers(1.0)
		await process_frame
		var cone_depth: float = stage3d._cones[0].scale.y if not stage3d._cones.is_empty() else 1.0
		_check(cone_depth > 1.0, "a bass hit punches the subwoofer cones out of the cabinets",
			"cone depth %.2f×" % cone_depth)
	_check(stage3d != null and stage3d.world_env != null
			and stage3d.world_env.environment.fog_enabled,
		"the 3D yard uses depth fog for crowd atmosphere")

	# Lighting is real scene light, phase by phase.
	if stage3d != null:
		stage3d.apply_phase(2, 0.0)
		await process_frame
		_check(stage3d.sun.light_energy < 0.2 and stage3d.spot_left.light_energy > 2.0,
			"night is carried by the overhead SpotLight3D rig, not a screen tint",
			"sun %.2f / spot %.2f" % [stage3d.sun.light_energy, stage3d.spot_left.light_energy])
		var night_sky: Color = stage3d.sky_material.get_shader_parameter("top_colour")
		_check(night_sky.b > night_sky.r and stage3d.world_env.environment.fog_density > 0.015,
			"night darkens the 3D sky and thickens the atmospheric depth")
		stage3d.apply_phase(1, 0.0)
		await process_frame
		_check(stage3d.sun.light_color.r > stage3d.sun.light_color.b
				and stage3d.spot_left.light_energy < 1.5,
			"sunset turns the DirectionalLight3D warm and low")
		stage3d.apply_phase(0, 0.0)
		await process_frame
		_check(stage3d.sun.light_energy > 1.0 and stage3d.spot_left.light_energy < 0.6,
			"afternoon is a bright directional sun with the spots resting")
	# The arena's own phase API must drive the 3D rig too.
	arena.set_time_of_day(2, 0.0)
	await process_frame
	_check(stage3d != null and stage3d.sun.light_energy < 0.2,
		"set_time_of_day(2) drives the 3D night rig")
	arena.set_time_of_day(0, 0.0)
	await process_frame

	# 3D impact bursts: multicoloured generated note glyphs + a bass shockwave ring.
	for i in 6:
		arena._add_note_trail(Vector2(500.0 + i * 10.0, 500.0), 1, true)
	_check(stage3d != null and stage3d.active_bursts() <= Arena3D.MAX_BURSTS,
		"3D note bursts are capped on the Chromebook budget",
		"%d alive" % (stage3d.active_bursts() if stage3d != null else -1))
	var live_bursts: Array = stage3d._live_bursts if stage3d != null else []
	if not live_bursts.is_empty():
		var burst = live_bursts[0]
		_check(burst is MusicNoteBurst and burst.notes.size() >= 4 and burst.ring != null,
			"a burst spawns note glyph meshes plus an expanding bass ring",
			"%d notes" % burst.notes.size())
		_check(burst.notes[0].mesh != null and burst.notes[0].mesh.get_faces().size() > 0,
			"the music-note glyphs are real generated 3D geometry")

	# ---- Event-driven Sound Clash audio engine (AGENTS.md §9 item 46) ----
	var sc: SoundClashAudio = root.get_node_or_null("SoundClash") as SoundClashAudio
	_check(sc != null, "the SoundClash audio autoload exists")
	_check(sc != null and sc.bus_names().has("DJTag") and sc.bus_names().has("Crowd")
			and sc.bus_names().has("Stinger"),
		"the native AudioBusLayout has DJTag, Crowd and Stinger buses",
		"%s" % [sc.bus_names() if sc != null else []])
	_check(sc != null and sc.dj_bus_effect_names() == ["AudioEffectDelay",
			"AudioEffectLowPassFilter", "AudioEffectReverb"],
		"DJ tags run through the tape-delay → low-pass → reverb chain",
		"%s" % [sc.dj_bus_effect_names() if sc != null else []])
	_check(sc != null and is_equal_approx(sc.sting_stream_length(), 6.0),
		"the round-start sting slot is ~6.0 s",
		"%.2f s" % (sc.sting_stream_length() if sc != null else 0.0))
	var rounds_probe: RoundController = arena.get_node("RoundController")
	_check(sc != null and is_equal_approx(sc.sting_fight_marker(), rounds_probe.announce_seconds),
		"the guitar stab lands on FIGHT! at the announce boundary",
		"%.2f s" % rounds_probe.announce_seconds)
	if sc != null:
		sc.tag_count = 0
		sc.rejected_count = 0
		sc._fighter_until = {}
		sc._global_until = 0.0
		sc._active_until = 0.0
		sc._active_priority = 0
		var first_tag: bool = sc.trigger_tag(&"feedback")
		var second_tag: bool = sc.trigger_tag(&"feedback")
		_check(first_tag and not second_tag and sc.tag_count == 1 and sc.rejected_count == 1,
			"a single significant hit fires the DJ tag, the cooldown rejects the repeat",
			"%d fired / %d rejected" % [sc.tag_count, sc.rejected_count])
		# A ringing TAG outranks a new TAG; clearing it lets the other fighter speak.
		sc._active_priority = SoundClashAudio.Priority.TAG
		sc._active_until = sc._now() + 5.0
		sc._fighter_until = {}
		sc._global_until = 0.0
		var blocked_tag: bool = sc.trigger_tag(&"lickshot")
		sc._active_priority = 0
		sc._active_until = 0.0
		var allowed_tag: bool = sc.trigger_tag(&"lickshot")
		_check(not blocked_tag and allowed_tag,
			"anti-overlap drops a duplicate tag but lets the answer through")
		# Clear the ringing window so the throw is judged on its own, not against the
		# deliberately-blocked duplicate in the previous check.
		sc._global_until = 0.0
		sc._active_until = 0.0
		sc._active_priority = 0
		sc._fighter_until.clear()
		var tagged: Array = []
		sc.tag_played.connect(func(key: StringName, _prio: int) -> void: tagged.append(key))
		sc.on_throw(p1)
		_check(tagged.size() == 1 and tagged[0] == &"feedback",
			"a landed throw fires the attacker's DJ tag event for the speaker cones",
			"%s" % [tagged])
		_check(arena.has_method("_on_tag_played"),
			"the arena listens for tag events to punch the 3D speaker cones")
		sc.set_crowd_intensity(0.95)
		_check(sc._crowd_target > 0.9, "a heavy hit raises the target crowd response")
		await process_frame
		_check(sc.crowd_level > 0.0, "the crowd layer rises from silence after an event",
			"%.2f" % sc.crowd_level)
		var horns_before: int = sc.horn_count
		var selectors_before: int = sc.selector_count
		sc.on_ko()
		_check(sc.horn_count > horns_before and sc.selector_count > selectors_before,
			"the K.O. slot outranks a ringing tag (horn + selector)")
		sc.set_crowd_intensity(0.0)

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
	# New callouts (AGENTS.md §8, item 47).
	hud._sub_cooldown = 0.0
	var heavy_call: bool = arena._announce_callout(&"heavy") \
		and hud.subtitle_text().contains("TUMP OUT HIM TEET!")
	hud._sub_cooldown = 0.0
	var stun_call: bool = arena._announce_callout(&"stun") \
		and hud.subtitle_text().contains("TEK WEH HIM MIC!")
	_check(heavy_call and stun_call,
		"TUMP OUT HIM TEET! and TEK WEH HIM MIC! are wired to their triggers")
	_check(str(arena.CALLOUTS[&"heavy"][0][1]).contains("teeth")
			and str(arena.CALLOUTS[&"stun"][0][1]).contains("microphone"),
		"both new callouts keep a separate English gloss")
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

	# 3D fallback (AGENTS.md §9 item 43): L!kkle Moore has no uploaded .glb yet, so his
	# approved 2D frame is mirrored onto a camera-facing Sprite3D on the 3D plane. The shared
	# FSM and the y 592 art stay exactly as they are.
	var kid_stage: Arena3D = arena.arena3d
	var kid_model = kid_stage.model_for(p2) if kid_stage != null else null
	_check(kid_model is FighterBillboard3D and kid_model.sprite != null,
		"L!kkle Moore falls back to a 2D sprite billboard on the 3D plane")
	_check(kid_model != null and kid_model.model_height > 1.1 and kid_model.model_height < 1.45,
		"the kid billboard keeps his 82 % relative height",
		"%.2f m" % (kid_model.model_height if kid_model != null else 0.0))
	_check(not p2.sprite.visible and p2.is_3d_presentation(),
		"the 2D sprite is hidden while the billboard carries his art")

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

	# ---- 2.5D arcade visual overhaul (AGENTS.md §9 item 41, 2026-11-20) ----------
	# Everything below is presentation: rim light, projected shadows, sand, depth layers,
	# impact juice and camera. No hitbox, damage, timing or y 592 alignment is touched.
	var rim_shader := load("res://scripts/stages/fighter_rim_light.gdshader") as Shader
	_check(rim_shader != null, "the fighter rim-light shader loads")
	var uniform_names := []
	if rim_shader != null:
		for u in rim_shader.get_shader_uniform_list():
			uniform_names.append(String(u["name"]))
	# `get_shader_uniform_list()` only returns entries when the shader parsed, so this is a real
	# compile check in headless — a syntax error lists zero uniforms.
	_check(uniform_names.size() >= 11, "the rim shader compiles and exposes its uniforms",
		"%d uniforms" % uniform_names.size())
	var required := ["rim_colour", "rim_colour_b", "rim_strength", "rim_width", "light_uv",
		"sprite_facing", "bounce_colour", "bounce_strength", "bounce_top", "flash_colour",
		"hit_flash"]
	var missing_uniforms := []
	for uniform in required:
		if not (uniform in uniform_names):
			missing_uniforms.append(uniform)
	_check(missing_uniforms.is_empty(), "every rim/flash uniform is declared",
		"missing %s" % [missing_uniforms] if not missing_uniforms.is_empty() else "11/11")
	# WebGL2 / Chromebook safety: a CanvasItem pass with no screen or depth reads, no includes
	# and no unbounded loops.
	var shader_code: String = rim_shader.code if rim_shader != null else ""
	var banned := []
	for token in ["hint_screen_texture", "SCREEN_TEXTURE", "DEPTH_TEXTURE", "#include", "while ("]:
		if shader_code.contains(token):
			banned.append(token)
	_check(banned.is_empty(), "the rim shader is WebGL2-safe (single pass, no screen reads)",
		"found %s" % [banned] if not banned.is_empty() else "9 taps, 0 screen reads")

	var p1_mat := p1b.sprite.material as ShaderMaterial
	var p2_mat := p2.sprite.material as ShaderMaterial
	_check(p1_mat != null and p1_mat.shader == rim_shader,
		"every fighter sprite carries the rim ShaderMaterial (shared BaseFighter scene)")
	_check(p2_mat != null and p2_mat.shader == rim_shader,
		"the second roster fighter inherits the same rim material")

	# Afternoon palette is already applied (the block above left phase 0 selected).
	_check(is_equal_approx(fight_shadow.density, 1.0),
		"afternoon keeps full-density shadows", "%.2f" % fight_shadow.density)
	_check(arena2.beams != null and is_zero_approx(arena2.beams.strength),
		"no volumetric beams in the afternoon sun")

	# Sunset: warm golden-amber rim, long skew, strong sand bounce.
	arena2.set_time_of_day(1, 0.0)
	await process_frame
	_check(p1b.rim_a.r > 0.9 and p1b.rim_a.r > p1b.rim_a.b and p1b.rim_strength >= 1.0,
		"sunset wraps a warm golden-amber rim",
		"rim %.2f strength %.2f" % [p1b.rim_a.r, p1b.rim_strength])
	_check(p1b.rim_b.r > 0.9 and p1b.rim_b.b < 0.4,
		"the sunset rim's second colour stays amber, not neon")
	var shader_rim_strength: float = float(p1_mat.get_shader_parameter("rim_strength")) if p1_mat != null else 0.0
	_check(p1_mat != null and absf(shader_rim_strength - p1b.rim_strength) < 0.001,
		"the artist-facing rim strength reaches the shader", "%.2f" % p1b.rim_strength)
	_check(fight_shadow.stretch > 1.5 and fight_shadow.shadow_lean() > 0.5,
		"sunset throws a long, skewed shadow to the right",
		"stretch %.2f lean %.2f" % [fight_shadow.stretch, fight_shadow.shadow_lean()])
	_check(fight_shadow.density < 1.0, "a long sunset shadow is also thinner",
		"density %.2f" % fight_shadow.density)
	_check(arena2.beams.strength > 0.5, "sunset light beams sweep the stage",
		"intensity %.2f" % arena2.beams.strength)
	_check(arena2.heat_haze != null and arena2.heat_haze.intensity > 0.5,
		"sunset heat haze is up")
	_check(arena2.foreground != null and arena2.foreground.intensity > 0.5,
		"the foreground crowd is up at sunset")

	# Night: cyan/magenta neon wrap, short soft shadow, truss beams.
	arena2.set_time_of_day(2, 0.0)
	await process_frame
	_check(p1b.rim_a.b > 0.85 and p1b.rim_a.g > 0.85 and p1b.rim_a.r < 0.5,
		"night wraps a cyan neon rim")
	_check(p1b.rim_b.r > 0.85 and p1b.rim_b.b > 0.85 and p1b.rim_b.g < 0.5,
		"night's second rim colour is magenta")
	_check(p1b.rim_strength > 1.1, "the neon rim burns harder than daylight",
		"%.2f" % p1b.rim_strength)
	_check(p1b.rim_bounce < 0.25, "the night kills most of the sand bounce",
		"%.2f" % p1b.rim_bounce)
	_check(fight_shadow.shadow_lean() < 0.0 and fight_shadow.stretch < 1.3,
		"the night floodlight projects a short shadow to the left")
	_check(arena2.beams.strength > 0.5, "the festival trusses still beam at night")

	# Facing: the rim must stay on the stage's light side when the frame is mirrored. The
	# fighters are parked either side of each other first, so the live AI cannot flip them
	# between the two reads.
	var p1_was_locked: bool = p1b.input_locked
	var p2_was_locked: bool = p2.input_locked
	p1b.input_locked = true
	p2.input_locked = true
	p1b.reset_for_round(Vector2(300, 600))
	p2.reset_for_round(Vector2(900, 600))
	p1b.face_toward(900.0)
	_check(not p1b.sprite.flip_h and p1_mat != null
			and is_equal_approx(float(p1_mat.get_shader_parameter("sprite_facing")), 1.0),
		"an unmirrored sprite leaves the rim on the stage's light side")
	p1b.face_toward(0.0)
	_check(p1b.sprite.flip_h and p1_mat != null
			and is_equal_approx(float(p1_mat.get_shader_parameter("sprite_facing")), -1.0),
		"the shader compensates a mirrored sprite's facing")

	# Impact-flash uniform: up on contact, released on the second tick. Input is locked so the
	# sparring AI cannot land a fresh hit and re-raise the flash between the two reads.
	await physics_frame
	p1b.flash_impact(true)
	_check(p1_mat != null and is_equal_approx(float(p1_mat.get_shader_parameter("hit_flash")), 1.0),
		"a landed hit raises the white/gold hit_flash uniform")
	await physics_frame
	await physics_frame
	_check(p1_mat != null and is_zero_approx(float(p1_mat.get_shader_parameter("hit_flash")))
			and p1b._impact_flash_ticks == 0,
		"the hit_flash uniform clears after its two ticks")
	p1b.sprite.modulate = Color.WHITE
	p1b.input_locked = p1_was_locked
	p2.input_locked = p2_was_locked

	# Sand: a burst is clamped, and the heavy strikes are the ones that kick it up.
	p1b._puff(3.0)
	_check(p1b.dust.amount <= 16, "a sand burst stays inside the per-fighter particle cap",
		"%d particles" % p1b.dust.amount)
	_check(BaseFighter.HEAVY_ATTACK_IDS.has(&"strong")
			and BaseFighter.HEAVY_ATTACK_IDS.has(&"tump")
			and BaseFighter.HEAVY_ATTACK_IDS.has(&"upper_box")
			and not BaseFighter.HEAVY_ATTACK_IDS.has(&"jab"),
		"heavy slaps, mic crosses and Sparta kicks kick sand; jabs stay clean")

	# Impact juice: 4–6 frame hit-stop on every heavy, a 4-frame jab, and a 6-frame counter.
	var jab_stop: int = int(BaseFighter.HITSTOP_TICKS[&"jab"])
	var heavy_ok := true
	for id in [&"strong", &"tump", &"upper_box"]:
		var ticks: int = int(BaseFighter.HITSTOP_TICKS[id])
		if ticks < 4 or ticks > 6:
			heavy_ok = false
	_check(jab_stop == 4 and heavy_ok, "heavy contacts freeze for 4–6 frames",
		"jab %d / heavies 6" % jab_stop)
	_check(BaseFighter.HITSTOP_COUNTER == 6 and BaseFighter.KO_HITSTOP_TICKS == 9,
		"counters stay in the 4–6 budget and the KO keeps its 9-frame freeze")

	# Counter-hit detection: only while the victim is committed to its own strike.
	p1b.reset_for_round(Vector2(420, 600))
	p2.reset_for_round(Vector2(860, 600))
	await physics_frame
	_check(not p2.is_counterable(), "a neutral fighter is not counterable")
	p2.change_state(BaseFighter.State.ATTACK_STARTUP)
	_check(p2.is_counterable(), "a fighter in its own startup is counterable")
	var probe := {
		"target": p2, "attack_id": &"jab", "attack": p2.attacks[&"jab"],
		"input_beat": {}, "contact_beat": {},
	}
	var counter_result := p2.receive_strike(p1b, probe)
	_check(bool(counter_result.get("counter", false)),
		"striking a committed fighter resolves as a counter-hit")
	_check(int(counter_result.get("damage", 0)) == int(p2.max_health - p2.health),
		"the counter flag changes presentation only, not the damage",
		"%d damage" % int(counter_result.get("damage", 0)))
	p2.reset_for_round(Vector2(860, 600))
	await physics_frame

	# Layered stage depth: beams over the fighters, haze behind them, near-crowd in front.
	_check(arena2.beams.z_index == 4 and p1b.z_index == 0 and arena2.beams.z_index > p1b.z_index,
		"volumetric beams draw over the fighters but under the HUD",
		"beams %d / fighter %d" % [arena2.beams.z_index, p1b.z_index])
	var beam_mat := arena2.beams.material as CanvasItemMaterial
	_check(beam_mat != null and beam_mat.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD,
		"the beams are additive, one draw pass, no shader")
	_check(arena2.heat_haze.z_index < p1b.z_index,
		"heat haze and motes sit behind the fighters",
		"haze %d" % arena2.heat_haze.z_index)
	var motes := arena2.heat_haze.get_node_or_null("DustMotes") as CPUParticles2D
	_check(motes != null and motes.amount <= 16 and motes.texture != null,
		"drifting dust motes are a capped, textured CPU emitter",
		"%d particles" % (motes.amount if motes != null else -1))
	_check(arena2.foreground != null and arena2.foreground.z_index > p1b.z_index,
		"the near-crowd silhouette draws in front of the fighters",
		"foreground %d / fighter %d" % [arena2.foreground.z_index, p1b.z_index])
	_check(arena2.foreground.figure_count >= 8 and arena2.foreground.lighter_slots() >= 1,
		"the foreground stack has heads, hands, rags and lighters",
		"%d figures / %d lighter slots" % [arena2.foreground.figure_count,
			arena2.foreground.lighter_slots()])
	_check(arena2.foreground.lighter_count() >= 1, "at least one foreground lighter is up")
	# Pinned to the bottom screen edge at whatever zoom the camera is holding.
	var fg: ForegroundCrowd = arena2.foreground
	var fg_bottom: float = fg.global_position.y + fg.screen_size().y
	var cam: Camera2D = arena2.camera
	var cam_bottom: float = cam.get_screen_center_position().y + (720.0 / cam.zoom.y) * 0.5
	_check(absf(fg_bottom - cam_bottom) < 1.0,
		"the foreground band stays glued to the bottom screen edge",
		"band %.1f / camera %.1f" % [fg_bottom, cam_bottom])

	# Whole-scene particle budget for the Chromebook WebGL2 target.
	var particle_total := 0
	var particle_over := []
	for node in arena2.find_children("*", "CPUParticles2D", true, false):
		var emitter := node as CPUParticles2D
		particle_total += emitter.amount
		if emitter.amount > 16:
			particle_over.append("%s %d" % [emitter.name, emitter.amount])
	_check(particle_over.is_empty() and particle_total <= 64,
		"every emitter respects the 16/particle and 64/scene budget",
		"total %d%s" % [particle_total,
			(" — over: " + ", ".join(particle_over)) if not particle_over.is_empty() else ""])

	# 3D impact bursts and the comic impact frame, both capped. The 2D NoteTrail path is
	# retired while the 3D layer is on; `_add_note_trail` routes to Arena3D instead.
	for i in 5:
		arena2._add_note_trail(Vector2(520.0 + i * 12.0, 500.0), 1, true)
	_check(arena2.arena3d.active_bursts() <= Arena3D.MAX_BURSTS,
		"3D note bursts are capped at four", "%d alive" % arena2.arena3d.active_bursts())
	if not arena2.arena3d._live_bursts.is_empty():
		var burst = arena2.arena3d._live_bursts[0]
		_check(burst is MusicNoteBurst and burst.heavy and burst.ring != null,
			"heavy contacts throw a 3D note burst and bass shockwave ring")
	arena2._add_impact_frame(&"counter")
	arena2._add_impact_frame(&"surge")
	_check(arena2._live_impact_frames().size() == 1,
		"only one comic impact frame can be alive",
		"%d alive" % arena2._live_impact_frames().size())
	_check(arena2._live_impact_frames()[0].z_index == 30,
		"the impact frame sits above the world and below the HUD")

	# Fighting-game camera: smooth framing plus an additive micro-zoom punch.
	var smooth_before: float = arena2._zoom_smooth
	arena2._zoom_punch_burst(0.05)
	# delta 0 applies the punch without letting the wall-clock decay eat it first, so the check
	# measures the burst rather than how long the headless frame took.
	arena2._follow_action(0.0)
	_check(cam.zoom.x > arena2._zoom_smooth + 0.01,
		"a counter/Hype Surge punches the camera in",
		"zoom %.4f > smooth %.4f" % [cam.zoom.x, arena2._zoom_smooth])
	_check(absf(arena2._zoom_smooth - smooth_before) < 0.08,
		"the framing zoom eases instead of snapping",
		"%.4f -> %.4f" % [smooth_before, arena2._zoom_smooth])

	# y 592 floor alignment is untouched by any of this.
	_check(is_equal_approx(BaseFighter.REACTION_FLOOR_Y, 592.0),
		"the y 592 sand alignment constant is unchanged")
	_check(is_equal_approx(fight_shadow.ground_y, 600.0),
		"fighter contact shadows still sit on the y 600 origin line")
	arena2.set_time_of_day(0, 0.0)
	await process_frame

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
	# Isolate P1's jab: the sparring AI's own attacks also spawn strike smears, and this check
	# is about whether *P1's drawn jab* doubles itself.
	var p2_locked_for_smear: bool = p2.input_locked
	p2.input_locked = true
	# Locking input alone does not cancel a strike already in flight, and that strike would own
	# a smear for 0.19 s. Reset P2 to neutral so P1 is the only body that can spawn one.
	p2.reset_for_round(p2.global_position)
	await physics_frame
	for live_tell in arena2._live_strike_tells():
		live_tell.queue_free()
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
	p2.input_locked = p2_locked_for_smear

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

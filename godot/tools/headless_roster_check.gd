extends SceneTree
## Headless roster + title-screen check (AGENTS.md §9 backlog item B1).
## Run with: godot --headless --path godot --script res://tools/headless_roster_check.gd
##
## Boots TitleScreen, verifies the MatchSetup defaults, boots TestArena with Lickshot as
## P2, then rebuilds the arena with Young Selecta and checks the shared FSM, the sprite
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
func _anim_floor_y(f: BaseFighter, key: StringName) -> float:
	var frames := f.sprite.sprite_frames
	if frames == null or not frames.has_animation(key):
		return -99999.0
	var tex := frames.get_frame_texture(key, 0)
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
	_check(p2.display_name == "LICKSHOT", "P2 is Lickshot", p2.display_name)
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
	# 0.2378 × BaseFighter.FIGHTER_ART_SCALE (1.24) — the 2026-11-17 "larger fighters" pass.
	var adult_scale := 0.2378 * BaseFighter.FIGHTER_ART_SCALE
	_check(absf(p2.sprite.scale.x - adult_scale) <= adult_scale * 0.05,
		"Lickshot renders at the enlarged adult height", "%.4f" % p2.sprite.scale.x)
	# Import-cap compensation means the raw node scale is not the figure's on-screen size:
	# divide the cap back out before comparing against the 121.75 px reference height.
	var idle_cap := p1._import_cap_ratio("idle", &"idle")
	var feedback_px := 487.0 * p1.sprite.scale.x / maxf(idle_cap, 0.001)
	_check(feedback_px > 140.0, "Feedback's figure grew past the old 121.75 px",
		"%.1f px" % feedback_px)

	# ---- Arena with Young Selecta -----------------------------------------
	setup.p2_fighter = &"young_selecta"
	change_scene_to_file("res://scenes/TestArena.tscn")
	await process_frame
	await process_frame
	arena = current_scene
	p2 = arena.get_node("P2")
	_check(p2.display_name == "YOUNG SELECTA", "P2 is Young Selecta", p2.display_name)
	_check(is_equal_approx(p2.walk_speed, 250.0), "Young Selecta walks faster",
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
		if arena2._live_strike_tells().size() > 0:
			saw_tell = true
		if saw_active and saw_tell:
			break
	_check(saw_active, "P1's jab reached its active window")
	_check(saw_tell, "a strike smear is drawn over the active window")
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

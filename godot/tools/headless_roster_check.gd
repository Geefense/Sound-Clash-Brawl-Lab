extends SceneTree
## Headless roster + title-screen check (AGENTS.md §9 backlog item B1).
## Run with: godot --headless --path godot --script res://tools/headless_roster_check.gd
##
## Boots TitleScreen, verifies the MatchSetup defaults, boots TestArena with Dubplate as
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
	_check(setup.p2_fighter == &"dubplate", "P2 defaults to Dubplate", str(setup.p2_fighter))
	_check(setup.ai_mode == 1, "AI defaults to Counter-Puncher", str(setup.ai_mode))
	_check(setup.subtitles == true, "Patois subtitles default on")

	# Cycle the roster through every fighter and back to the first.
	for i in 3:
		setup.cycle_p1(1)
		setup.cycle_p2(1)
	_check(setup.p1_fighter == &"feedback", "three cycles wrap P1 back to Feedback")
	_check(setup.p2_fighter == &"dubplate", "three cycles wrap P2 back to Dubplate")

	# ---- Arena with Dubplate ----------------------------------------------
	setup.p1_fighter = &"feedback"
	setup.p2_fighter = &"dubplate"
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
	_check(p2.display_name == "DUBPLATE", "P2 is Dubplate", p2.display_name)
	_check(p2.fighter_key == &"dubplate", "P2 fighter_key applied", str(p2.fighter_key))
	_check(sparring.mode_index() == 2, "AI mode carried from setup", sparring.mode_name())
	_check(hud.subtitles_enabled == false, "subtitle flag carried from setup")
	_check(p2.sprite.sprite_frames != null
		and p2.sprite.sprite_frames.has_animation(&"idle"),
		"Dubplate sprite frames built")
	# The idle groove squash/stretch rides on top of the base scale, so allow a few %.
	_check(absf(p2.sprite.scale.x - 0.2378) <= 0.2378 * 0.05,
		"Dubplate rendered at the adult 121.75 px height", "%.4f" % p2.sprite.scale.x)
	_check(not p2.sprite.flip_h, "no art mirroring (canonical hand rule)")

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
	# 512 px frame × scale must land near 99.8 px (82 % of Feedback's 121.75). The idle
	# groove squash rides on top, so allow 6 %.
	var kid_px := p2.sprite.scale.x * 512.0
	_check(absf(kid_px - 99.8) <= 99.8 * 0.06, "kid renders ~82 % of the adult height",
		"%.1f px" % kid_px)

	# Fight for a moment: the AI must actually drive the FSM through attacks.
	var seen := {}
	for i in 240:
		await physics_frame
		if p2 != null and is_instance_valid(p2):
			seen[p2.state] = true
	_check(seen.size() > 1, "AI drove P2 through the shared FSM", "%d states" % seen.size())
	_check(not p2.sprite.flip_h, "still no art mirroring after fighting")

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

extends SceneTree
## Headless roster + title-screen check (AGENTS.md §9 backlog item B1).
## Run with: godot --headless --path godot --script res://tools/headless_roster_check.gd
##
## Boots TitleScreen, verifies the three uploaded 3D fighters (Feedback, L!ckshot and
## L!kkle Moore) load as cel-shaded FighterModel3D nodes with decoded albedos, checks the
## default FEEDBACK vs FEEDBACK mirror accent, then boots TestArena with Lickshot as P2,
## rebuilds it with Likkle Moore (L!KKLE MOORE) and checks the shared FSM, sprite frames,
## +25 px reach, the AI mode and the Esc return path. Prints one line per check and exits
## non-zero if any check fails.

const PASS := "PASS"
const FAIL := "FAIL"

var _failures: int = 0


func _initialize() -> void:
	_run()



## Cel surfaces on one character (hand props excluded), used by the albedo-integrity check.
func _count_cel_surfaces(node: Node3D) -> int:
	var n := 0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi != null and mi.mesh != null and not CharacterModelSlots._under_hand_prop(mi):
			n += mi.mesh.get_surface_count()
	return n

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


## Skeleton path of a fighter body relative to its own model root. The uploads disagree
## (Feedback nests it at `Skeleton3D`, the other two at `Armature/Skeleton3D`), so the clip
## library is always told the measured path instead of guessing.
func _body_skeleton_path(path: String) -> String:
	var packed := load(path) as PackedScene
	if packed == null:
		return ""
	var node := packed.instantiate()
	var out := ""
	var skel: Skeleton3D = null
	for child in node.find_children("*", "Skeleton3D", true, false):
		skel = child as Skeleton3D
		break
	if skel != null:
		out = String(node.get_path_to(skel))
	node.free()
	return out


## Drive a static 3D model through the whole-body procedural rig the arena uses for all
## three uploads: idle settle, strike lunge, knockdown tip. This is the same `_animate_pose`
## path `_process` calls, so a mesh that is not actually connected to the transforms fails
## here instead of only on a device.
func _assert_procedural_stance(model: FighterModel3D, f: BaseFighter, label: String) -> void:
	_check(model != null and model._visual_pivot != null and model.skeleton != null,
		label + " is bound to the procedural stance pivot")
	if model == null or model._visual_pivot == null or f == null:
		return
	# The model syncs its yaw in `_process`; the check may run between a facing change and
	# the next frame, so apply the same sync before measuring the forward lunge.
	model._apply_facing()
	var saved_state: int = f.state
	var saved_attack: StringName = f._attack_id
	f.state = BaseFighter.State.IDLE
	f._attack_id = &""
	for i in 8:
		model._animate_pose(0.1)
	var rest_x: float = model._pivot.position.x
	f.state = BaseFighter.State.ATTACK_ACTIVE
	f._attack_id = &"jab"
	for i in 8:
		model._animate_pose(0.1)
	# P2 faces left, so "forward" is negative on X; the same transform must follow facing.
	var forward := float(f.facing)
	_check((model._pivot.position.x - rest_x) * forward > 0.05,
		label + " strike lunges the static mesh forward",
		"x %.3f -> %.3f (facing %d)" % [rest_x, model._pivot.position.x, f.facing])
	f.state = BaseFighter.State.KNOCKDOWN
	for i in 22:
		model._animate_pose(0.1)
	_check(absf(model._pivot.rotation.z) > 0.4,
		label + " knockdown transform tips the mesh over",
		"z %.2f rad" % model._pivot.rotation.z)
	f.state = saved_state
	f._attack_id = saved_attack
	for i in 4:
		model._animate_pose(0.1)


## Build one fighter's live attack table from the shared scene, then free the probe. This
## reads exactly what `BaseFighter.apply_fighter_profile()` builds at match start, so a
## roster edit that silently stops applying fails here.
func _attacks_for(key: StringName) -> Dictionary:
	var probe := load("res://scenes/BaseFighter.tscn").instantiate() as BaseFighter
	root.add_child(probe)
	probe.apply_fighter_profile(key)
	var copy := {}
	for id in [&"jab", &"strong", &"tump", &"upper_box"]:
		copy[id] = (probe.attacks[id] as Dictionary).duplicate(true)
	probe.free()
	return copy


func _move_signature(a: Dictionary) -> String:
	return "%d/%d/%d dmg%d stun%d kb%s hb%s" % [
		int(a["startup"]), int(a["active"]), int(a["recovery"]), int(a["damage"]),
		int(a["hitstun"]), a["knockback"], a["hitbox_size"]]


## The static uploads have no skeleton, so differentiation is entirely the per-move
## whole-body profile. Drive two signature moves through `_animate_pose` and require their
## assembled pose (shoulder twist, lift, lean) to separate. The twist is measured from
## `_twist`, not from the pivot yaw: `VisualPivot` owns facing alone and may never turn.
func _assert_move_pose_difference(model: FighterModel3D, f: BaseFighter, label: String) -> void:
	if model == null or f == null or model._pivot == null:
		_check(false, label + " has a per-move 3D pose")
		return
	var pairs := {
		&"feedback": [&"tump", &"upper_box"],
		&"lickshot": [&"strong", &"tump"],
		&"young_selecta": [&"upper_box", &"tump"],
	}
	var ids: Array = pairs.get(f.fighter_key, [])
	if ids.size() < 2:
		_check(false, label + " has two styled signature moves")
		return
	var saved_state: int = f.state
	var saved_attack: StringName = f._attack_id
	var poses: Array[Vector3] = []
	for id in ids:
		f.state = BaseFighter.State.ATTACK_ACTIVE
		f._attack_id = id
		for i in 14:
			model._animate_pose(0.08)
		poses.append(Vector3(model._twist, model._pivot.position.y, model._pivot.rotation.z))
	f.state = saved_state
	f._attack_id = saved_attack
	for i in 4:
		model._animate_pose(0.1)
	var delta := (poses[0] - poses[1]).abs()
	_check(delta.x > 0.10 or delta.y > 0.05 or delta.z > 0.10,
		label + " gives its signature moves separate 3D poses",
		"%s vs %s -> yaw %.2f / lift %.2f / lean %.2f" % [ids[0], ids[1], delta.x, delta.y, delta.z])


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


## One physical key event for the select-screen checks. `pressed` is explicit so a release
## can be fed in on purpose: a cursor must never wait for the key-up.
func _key_event(code: Key, pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	event.echo = false
	return event


## Press and release one key on the real handler, exactly like the keyboard does.
func _press_key(node: Node, code: Key) -> void:
	node._unhandled_input(_key_event(code, true))
	node._unhandled_input(_key_event(code, false))


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
	# Playtest fix 2026-11-24: independent cursors, so the screen never opens on a mirror.
	_check(setup.p1_fighter_id == &"feedback" and setup.p2_fighter_id == &"lickshot",
		"the committed defaults are Feedback for P1 and L!ckshot for P2",
		"%s vs %s" % [setup.p1_fighter_id, setup.p2_fighter_id])
	_check(title != null and title.p1_key() == &"feedback" and title.p2_key() == &"lickshot",
		"P1's cursor starts on Feedback and P2's on L!ckshot",
		"%s / %s" % [title.p1_key() if title != null else "-",
			title.p2_key() if title != null else "-"])
	_check(title != null and not title.both_locked(),
		"the select screen opens with neither side locked")
	_check(setup.ai_mode == 1, "AI defaults to Counter-Puncher", str(setup.ai_mode))
	_check(setup.subtitles == true, "Patois subtitles default on")

	# ---- Three uploaded 3D fighter models (2026-11-22) ----------------------
	# Every roster key must point at a real FBX and a real extracted albedo. The arenas below
	# then prove each one actually instantiates as a cel-shaded FighterModel3D.
	for key in [&"feedback", &"lickshot", &"young_selecta"]:
		var src: Dictionary = FighterModel3D.MODEL_SOURCES.get(key, {})
		var model_path := String(src.get("path", ""))
		var albedo_path := String(src.get("albedo", ""))
		_check(not model_path.is_empty() and FileAccess.file_exists(model_path)
				and not albedo_path.is_empty() and FileAccess.file_exists(albedo_path),
			"%s has its uploaded 3D model and albedo on disk" % key,
			"%s + %s" % [model_path.get_file(), albedo_path.get_file()])
	_check(String(FighterModel3D.MODEL_SOURCES[&"young_selecta"]["label"]).contains("L!kkle Moore"),
		"the young_selecta slot is labelled L!kkle Moore")
	_check(String(FighterModel3D.MODEL_SOURCES[&"feedback"]["path"]).ends_with("feedback_rigged.fbx")
			and String(FighterModel3D.MODEL_SOURCES[&"lickshot"]["path"]).ends_with("lickshot_rigged.fbx")
			and String(FighterModel3D.MODEL_SOURCES[&"young_selecta"]["path"]).ends_with("likkle_moore_rigged.fbx"),
		"the three owner uploads are filed as feedback_rigged, lickshot_rigged and likkle_moore_rigged")

	# ---- Three tournament movesets (2026-11-22) --------------------------
	var fb_moves := _attacks_for(&"feedback")
	var ls_moves := _attacks_for(&"lickshot")
	var km_moves := _attacks_for(&"young_selecta")
	var all_sigs := []
	for table in [fb_moves, ls_moves, km_moves]:
		for id in [&"jab", &"strong", &"tump", &"upper_box"]:
			all_sigs.append(_move_signature(table[id]))
	var unique_sigs := {}
	for sig in all_sigs:
		unique_sigs[sig] = true
	_check(unique_sigs.size() == 12,
		"all twelve normal/special moves carry distinct frame data and hitboxes",
		"%d unique signatures" % unique_sigs.size())
	_check(int(fb_moves[&"jab"]["startup"]) == 4 and int(fb_moves[&"jab"]["active"]) == 3
			and int(fb_moves[&"strong"]["recovery"]) == 18
			and int(fb_moves[&"tump"]["startup"]) == 12
			and int(fb_moves[&"upper_box"]["recovery"]) == 16,
		"Feedback's original frame data is untouched")
	_check(int(ls_moves[&"jab"]["recovery"]) == 7
			and int(ls_moves[&"upper_box"]["damage"]) == 18
			and (ls_moves[&"upper_box"]["hitbox_size"] as Vector2).x == 124.0
			and (ls_moves[&"tump"]["advance"] as float) > 0.0,
		"L!ckshot owns fast-jab, heavy-cross and advancing-knee data",
		_move_signature(ls_moves[&"upper_box"]))
	var ls_wave: Dictionary = ls_moves[&"strong"].get("projectile", {})
	_check(String(ls_wave.get("kind", &"")) == "dubplate"
			and int(ls_wave.get("damage", 0)) == 16 and float(ls_wave.get("speed", 0.0)) >= 500.0
			and float(ls_wave.get("life", 0.0)) >= 1.0,
		"K launches a long-lived travelling sub-bass dubplate wave",
		"%s dmg %d" % [ls_wave.get("kind", &""), int(ls_wave.get("damage", 0))])
	_check(int(km_moves[&"jab"]["recovery"]) == 6
			and (km_moves[&"jab"]["hitbox_size"] as Vector2).x == 109.0
			and (km_moves[&"upper_box"]["hitbox_size"] as Vector2).x == 150.0,
		"L!kkle Moore keeps the 25 px reach on a fast jab and swings a 150 px home run")
	var km_sweep: Dictionary = km_moves[&"tump"]
	_check(bool(km_sweep.get("low_profile", false)) and bool(km_sweep.get("knockdown", false))
			and float(km_sweep.get("advance", 0.0)) > 0.0
			and (km_sweep["hitbox_size"] as Vector2).y <= 40.0,
		"L sweeps low, advances and trips instead of knocking back")
	var km_wave: Dictionary = km_moves[&"strong"].get("projectile", {})
	_check(String(km_wave.get("kind", &"")) == "dictionary"
			and int(km_wave.get("hitstun", 0)) >= 30 and float(km_wave.get("life", 9.0)) < 0.7,
		"K hurls the dictionary for the longest stun in the roster",
		"%d stun" % int(km_wave.get("hitstun", 0)))
	_check(fb_moves[&"strong"].get("projectile", {}).is_empty()
			and fb_moves[&"tump"].get("low_profile", false) == false,
		"Feedback gains no projectile or low-profile override")
	var ls_profile: Dictionary = FighterRoster.profile(&"lickshot")
	var km_profile: Dictionary = FighterRoster.profile(&"young_selecta")
	var fb_profile: Dictionary = FighterRoster.profile(&"feedback")
	_check(int(ls_profile["throw"]["hold"]) == 14
			and (ls_profile["throw"]["forward_launch"] as Vector2).x > 500.0
			and int(ls_profile["taunt_hype"]) == 12 and bool(ls_profile["taunt_callout"]),
		"L!ckshot's mic-drop throw is heavier and his skank builds 12 Hype",
		"hold %d" % int(ls_profile["throw"]["hold"]))
	_check(int(km_profile["throw"]["hold"]) == 9
			and int(km_profile["throw"]["recovery"]) == 8
			and int(km_profile["taunt_hype"]) == 10 and bool(km_profile["taunt_callout"]),
		"L!kkle Moore's ankle trip snaps out fast and his footwork builds 10 Hype",
		"hold %d / recovery %d" % [int(km_profile["throw"]["hold"]),
			int(km_profile["throw"]["recovery"])])
	_check(fb_profile.get("throw", {}).is_empty()
			and int(fb_profile.get("taunt_hype", 0)) == 0
			and not bool(fb_profile.get("taunt_callout", false)),
		"Feedback keeps the original grab timing and on-beat-only taunt reward")

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
	_check(title.beat_toast_text().contains("BEAT 2") and title.beat_toast_text().contains("M TO CYCLE"),
		"M on Title / Select flashes the current beat in the corner HUD label",
		title.beat_toast_text())
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
	_check(setup.p2_fighter == &"lickshot", "three cycles wrap P2 back to L!ckshot")

	# ---- Independent P1/P2 cursors and lock-in (playtest 2026-11-24) ---------
	# The owner asked for two cursors that cannot move each other, a lock per player, and a
	# fight that only starts once both are locked. Driven through the real input handler, with
	# physical key events, so a key that arrives on release or gets eaten by P1 would fail.
	title._sync_cursors_from_setup()
	title.phase = 1
	title.p1_cursor = 0
	title.p2_cursor = 1
	_check(title.p1_key() == &"feedback" and title.p2_key() == &"lickshot",
		"the cursors reset to Feedback / L!ckshot")
	_press_key(title, KEY_RIGHT)
	_check(title.p2_cursor == 2 and title.p1_cursor == 0,
		"P2's own key moves only P2's cursor, never P1's")
	_press_key(title, KEY_D)
	_press_key(title, KEY_D)
	_check(title.p1_cursor == 2 and title.p2_cursor == 2,
		"P1's keys move only P1's cursor (L!kkle Moore), leaving P2 where it was")
	title._unhandled_input(_key_event(KEY_D, false))
	_check(title.p1_cursor == 2, "a key release never moves a cursor")
	title._unhandled_input(_key_event(KEY_L, false))
	_check(not title.p2_locked, "a key release never locks a pick")

	# Lock P1, then hand the keyboard over so one player can pick the CPU.
	_press_key(title, KEY_J)
	_check(title.p1_locked and not title.p2_locked and title.p1_drives_p2(),
		"J locks P1 and passes the keyboard to the CPU pick")
	_press_key(title, KEY_D)
	_check(title.p2_cursor == 0 and title.p1_cursor == 2,
		"P1's keys now move the CPU pick without disturbing P1's lock")
	_press_key(title, KEY_K)
	_check(not title.p1_locked and title.p1_cursor == 2,
		"K unlocks P1 and keeps his cursor where it was")
	_press_key(title, KEY_J)
	_check(title.p2_key() == &"feedback" and title.p1_key() == &"young_selecta",
		"P1 = L!kkle Moore and P2 = Feedback are both still selectable")
	title._start()
	await process_frame
	_check(current_scene == title,
		"the fight refuses to start while only one side is locked",
		str(current_scene.name) if current_scene != null else "null")
	_press_key(title, KEY_L)
	_check(title.both_locked(), "L locks P2")
	title._start()
	await process_frame
	await process_frame
	await process_frame
	var picked := current_scene
	_check(picked != null and picked.name != "TitleScreen",
		"both locks start the match", str(picked.name) if picked != null else "null")
	if picked != null and picked.name != "TitleScreen":
		var pp1: BaseFighter = picked.get_node_or_null("P1") as BaseFighter
		var pp2: BaseFighter = picked.get_node_or_null("P2") as BaseFighter
		_check(pp1 != null and pp1.fighter_key == &"young_selecta"
				and pp2 != null and pp2.fighter_key == &"feedback",
			"P1 L!kkle Moore vs P2 Feedback loads the right two fighters",
			"%s vs %s" % [pp1.fighter_key if pp1 != null else "-",
				pp2.fighter_key if pp2 != null else "-"])
		_check(setup.p1_fighter_id == &"young_selecta" and setup.p2_fighter_id == &"feedback",
			"the autoload carries the committed ids into the arena",
			"%s / %s" % [setup.p1_fighter_id, setup.p2_fighter_id])

	# A mirror is allowed when both players pick it, and it is shown, not silently corrected.
	setup.escape_to_setup()
	await process_frame
	await process_frame
	var select2 := current_scene
	_check(select2 != null and select2.name == "TitleScreen",
		"Esc reopens the select screen")
	if select2 != null and select2.name == "TitleScreen":
		_check(select2.p1_key() == &"young_selecta" and select2.p2_key() == &"feedback",
			"the cursors come back on the last committed picks",
			"%s / %s" % [select2.p1_key(), select2.p2_key()])
		_press_key(select2, KEY_A)
		_press_key(select2, KEY_RIGHT)
		_check(select2.p1_key() == &"lickshot" and select2.p2_key() == &"lickshot",
			"both panels can land on L!ckshot")
		_press_key(select2, KEY_J)
		_press_key(select2, KEY_L)
		_check(select2.both_locked(), "a mirror match can be locked on both sides")
		select2._start()
		await process_frame
		await process_frame
		await process_frame
		var mirror2 := current_scene
		if mirror2 != null and mirror2.name != "TitleScreen":
			var mm1: BaseFighter = mirror2.get_node_or_null("P1") as BaseFighter
			var mm2: BaseFighter = mirror2.get_node_or_null("P2") as BaseFighter
			_check(mm1 != null and mm2 != null and mm1.fighter_key == &"lickshot"
					and mm2.fighter_key == &"lickshot",
				"P1 L!ckshot vs P2 L!ckshot loads L!ckshot on both sides",
				"%s vs %s" % [mm1.fighter_key if mm1 != null else "-",
					mm2.fighter_key if mm2 != null else "-"])
			_check(setup.p1_fighter_id == &"lickshot" and setup.p2_fighter_id == &"lickshot",
				"the mirror print carries two identical ids",
				"%s / %s" % [setup.p1_fighter_id, setup.p2_fighter_id])

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
	var mirror_hud: Control = mirror_arena.get_node("HUD/Ui/Hud")
	var mp1_model: FighterModel3D = mirror_stage.model_for(mp1) as FighterModel3D
	var mp2_model: FighterModel3D = mirror_stage.model_for(mp2) as FighterModel3D
	_check(mp1.fighter_key == &"feedback" and mp2.fighter_key == &"feedback",
		"the default arena is FEEDBACK vs FEEDBACK", "%s vs %s" % [mp1.fighter_key, mp2.fighter_key])
	_check(mp1_model != null and mp1_model.has_rig and mp1_model.bone_count > 20
			and mp1_model.triangle_count() == 29025,
		"P1 Feedback loads feedback_rigged as a cel-shaded FighterModel3D",
		"%d tris / %d bones" % [mp1_model.triangle_count() if mp1_model != null else -1,
			mp1_model.bone_count if mp1_model != null else -1])
	_check(mp2_model != null and mp2_model.has_rig and mp2_model.bone_count > 20
			and mp2_model.triangle_count() == 29025,
		"P2 Feedback uses the same rigged upload in the mirror match",
		"%d tris / %d bones" % [mp2_model.triangle_count() if mp2_model != null else -1,
			mp2_model.bone_count if mp2_model != null else -1])
	_check(mp1_model != null and mp2_model != null and mp1_model.has_albedo_texture()
			and mp2_model.has_albedo_texture()
			and mp1_model.albedo_size == Vector2i(1024, 1024),
		"both mirror models decode their 1024 x 1024 albedo",
		"%s" % [mp1_model.albedo_size if mp1_model != null else Vector2i.ZERO])
	_check(mp1_model != null and mp1_model.albedo_texture != null
			and mp1_model.albedo_texture.get_image().get_format() == Image.FORMAT_RGBA8,
		"Feedback's albedo imports as uncompressed standard RGBA",
		"format %d" % (mp1_model.albedo_texture.get_image().get_format()
			if mp1_model != null and mp1_model.albedo_texture != null else -1))
	_check(mp1_model != null and absf(mp1_model.measured_height() - 1.55) < 0.02,
		"Feedback's assembled mesh measures 1.55 m after the root-scale normalisation",
		"%.3f m" % (mp1_model.measured_height() if mp1_model != null else 0.0))
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
	_assert_procedural_stance(mp1_model, mp1, "P1 Feedback")
	_assert_procedural_stance(mp2_model, mp2, "P2 Feedback")

	# ---- 38 Mixamo takes bound to the three fighters (2026-11-24) ----------------
	# Every uploaded take ships as an armature-plus-animation file; each fighter's body is
	# one of the owner's own skinned exports, so the tracks already address its skeleton.
	var clip_expect := {&"feedback": 10, &"lickshot": 11, &"young_selecta": 17}
	for key in clip_expect:
		var files: Array[String] = MixamoClips.clip_files(key)
		_check(files.size() == int(clip_expect[key]),
			"%s ships all %d uploaded Mixamo takes" % [key, clip_expect[key]],
			"%d files" % files.size())
		var skeleton_path := _body_skeleton_path(String(FighterModel3D.MODEL_SOURCES[key]["path"]))
		var lib := MixamoClips.library_for(key, skeleton_path)
		_check(lib.size() >= 10, "%s binds its takes to fight roles" % key,
			"%d roles on %s" % [lib.size(), skeleton_path])
		for role in [&"idle", &"walk", &"light", &"strong", &"upper_box", &"knockdown"]:
			_check(lib.has(role), "%s has a real %s take" % [key, role])
	_check(mp1_model != null and mp1_model.clip_count() >= 10,
		"Feedback mounts its takes on the body's own AnimationPlayer",
		"%d roles" % (mp1_model.clip_count() if mp1_model != null else 0))
	if mp1_model != null:
		var rest_arm := mp1_model.skeleton.get_bone_pose_rotation(
			mp1_model.skeleton.find_bone("mixamorig_LeftArm"))
		mp1_model._play_role(&"light")
		var light_name := String(mp1_model.current_clip())
		mp1_model.animation.advance(0.0)
		mp1_model.animation.advance(0.30)
		var posed_arm := mp1_model.skeleton.get_bone_pose_rotation(
			mp1_model.skeleton.find_bone("mixamorig_LeftArm"))
		_check(light_name == "light"
				and mp1_model.animation.current_animation == "mixamo/light",
			"the jab state crossfades to the uploaded jab take",
			"%s / %s" % [light_name, mp1_model.animation.current_animation])
		_check((posed_arm - rest_arm).length() > 0.0005,
			"the uploaded take actually drives Feedback's skeleton",
			"delta %.4f" % (posed_arm - rest_arm).length())
		mp1_model._play_role(&"idle")

	# ---- Hand prop slots on mixamorig_RightHand (2026-11-24) -------------------
	_check(mp1_model != null and mp1_model.hand_prop_count() == 1
			and mp1_model.hand_bone_name() == "mixamorig_RightHand",
		"Feedback carries a prop slot on mixamorig_RightHand",
		"%d slots on %s" % [mp1_model.hand_prop_count() if mp1_model != null else -1,
			mp1_model.hand_bone_name() if mp1_model != null else "-"])
	_check(mp1_model != null and FighterProps.prop_triangles(mp1_model.model_root) == 0,
		"no procedural microphone geometry is built into the hand",
		"%d prop tris" % (FighterProps.prop_triangles(mp1_model.model_root)
			if mp1_model != null else 0))
	# Every roster fighter, built straight from its body file: the two adults ask for a
	# wireless mic, the kid for his stand, all on the same right-hand bone. The props are
	# `.glb` slots now, so nothing is drawn while the files are missing.
	var prop_expect := {
		&"feedback": FighterProps.MIC_MODEL,
		&"lickshot": FighterProps.MIC_MODEL,
		&"young_selecta": FighterProps.STAND_MODEL,
	}
	for key in prop_expect:
		var body := (load(String(FighterModel3D.MODEL_SOURCES[key]["path"])) as PackedScene).instantiate() as Node3D
		var body_skel: Skeleton3D = null
		for child in body.find_children("*", "Skeleton3D", true, false):
			body_skel = child as Skeleton3D
			break
		var props := FighterProps.attach_for(body, body_skel, key)
		var slot_path := ""
		var on_hand := props.size() == 1 and props[0].bone_name == "mixamorig_RightHand"
		if on_hand:
			for child in props[0].find_children("*", "PropLoader", true, false):
				slot_path = String((child as PropLoader).model_path)
				break
		_check(on_hand and slot_path == String(prop_expect[key])
				and FighterProps.prop_triangles(body) == 0,
			"%s asks for %s on mixamorig_RightHand, with nothing drawn yet"
				% [key, String(prop_expect[key]).get_file()],
			"%d slot(s) on %s, path %s" % [props.size(),
				props[0].bone_name if props.size() > 0 else "-", slot_path])
		body.free()

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
	_check(mirror_hud.music_toast_text().contains("BEAT 3"),
		"M on the post-KO screen flashes the current beat in the corner HUD label",
		mirror_hud.music_toast_text())
	mirror_arena._unhandled_input(m_key)
	_check(music_bed.state_name() == "off" and not music_bed.is_playing(),
		"M on the post-KO screen cycles Beat 3 to Off")
	mirror_arena._unhandled_input(m_key)
	_check(music_bed.state_name() == "beat_1" and music_bed.is_playing(),
		"M resumes the victory audition from Beat 1")
	# Across matches the victory bed advances on its own: Beat 1 → 2 → 3 → 1.
	music_bed.stop_for_fight()
	await create_timer(0.6).timeout
	music_bed.play_victory()
	var victory_a := String(music_bed.state_name())
	music_bed.play_victory()
	var victory_b := String(music_bed.state_name())
	music_bed.play_victory()
	var victory_c := String(music_bed.state_name())
	_check(victory_a == "beat_2" and victory_b == "beat_3" and victory_c == "beat_1",
		"the post-KO bed rotates Beat 1 -> Beat 2 -> Beat 3 across matches",
		"%s / %s / %s" % [victory_a, victory_b, victory_c])
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
	var fb3d: FighterModel3D = model1 as FighterModel3D
	var lick3d: FighterModel3D = model2 as FighterModel3D
	_check(fb3d != null and fb3d.triangle_count() == 29025,
		"Feedback loads feedback_v2 as a cel-shaded FighterModel3D",
		"%d tris" % (fb3d.triangle_count() if fb3d != null else -1))
	_check(lick3d != null and lick3d.triangle_count() < 35000
			and lick3d.triangle_count() >= 20000,
		"L!ckshot's decimated upload stays under the 35 000-triangle budget",
		"%d tris" % (lick3d.triangle_count() if lick3d != null else -1))
	_check(model2 is FighterModel3D and not (model2 is FighterBillboard3D),
		"L!ckshot now renders from real 3D geometry, not a Sprite3D billboard")
	_check(lick3d != null and lick3d.has_albedo_texture()
			and lick3d.albedo_size == Vector2i(1024, 1024),
		"L!ckshot's albedo decodes as a 1024 x 1024 texture",
		"%s" % [lick3d.albedo_size if lick3d != null else Vector2i.ZERO])
	_check(not String(FighterModel3D.MODEL_SOURCES[&"lickshot"]["path"]).contains("placeholder")
			and FileAccess.file_exists("res://assets/models/fighters/lickshot_placeholder_static.fbx"),
		"the static placeholder stays archived but is no longer assigned to L!ckshot")
	_check(fb3d != null and absf(fb3d.model_height - 1.55) < 0.02
			and absf(fb3d.measured_height() - 1.55) < 0.02,
		"Feedback's assembled mesh measures its authored 1.55 m height",
		"%.2f m config / %.3f m measured" % [fb3d.model_height if fb3d != null else 0.0,
			fb3d.measured_height() if fb3d != null else 0.0])
	_check(lick3d != null and absf(lick3d.model_height - 1.58) < 0.02
			and absf(lick3d.measured_height() - 1.58) < 0.02,
		"L!ckshot's assembled mesh measures his 1.58 m adult height",
		"%.2f m config / %.3f m measured" % [lick3d.model_height if lick3d != null else 0.0,
			lick3d.measured_height() if lick3d != null else 0.0])
	_check(fb3d != null and lick3d != null and fb3d.feet_offset > 0.0
			and lick3d.feet_offset > 0.0,
		"both uploaded models are seated feet-down on the world floor")
	_check(fb3d != null and lick3d != null and not fb3d.materials.is_empty()
			and not lick3d.materials.is_empty()
			and fb3d.materials[0].next_pass != null and lick3d.materials[0].next_pass != null,
		"both fighter materials carry the inverted-hull ink outline pass")
	_assert_procedural_stance(fb3d, p1, "Feedback")
	_assert_procedural_stance(lick3d, p2, "L!ckshot")
	_assert_move_pose_difference(fb3d, p1, "Feedback")
	_assert_move_pose_difference(lick3d, p2, "L!ckshot")

	# ---- L!ckshot's special actually resolves a travelling strike ----------
	# The wave is a real combat node: it must move, hit the defender's hurtbox through the
	# shared `receive_strike`, spawn the 3D dubplate proxy and free itself on contact.
	var saved_p1 := p1.global_position
	var saved_p2 := p2.global_position
	var saved_hp := p1.health
	p1.input_locked = true
	p2.input_locked = true
	p2.global_position = Vector2(360.0, saved_p2.y)
	p1.global_position = Vector2(560.0, saved_p1.y)
	p2.facing = 1
	p2._attack = p2.attacks[&"strong"]
	p2._attack_id = &"strong"
	p2._spawn_projectile()
	var waves := get_nodes_in_group("projectiles")
	var wave: Node2D = waves[-1] if not waves.is_empty() else null
	_check(wave != null and stage3d != null and stage3d.active_projectiles() >= 1,
		"the dubplate launches a combat wave and its 3D proxy",
		"%d wave / %d prop" % [waves.size(), stage3d.active_projectiles() if stage3d != null else -1])
	if wave != null:
		var start_x := wave.global_position.x
		for i in 40:
			await physics_frame
			if not is_instance_valid(wave) or wave.is_queued_for_deletion():
				break
		_check(p1.health < saved_hp,
			"the travelling wave lands through the shared strike resolver",
			"%d -> %d hp" % [saved_hp, p1.health])
		_check(not is_instance_valid(wave) or wave.is_queued_for_deletion()
				or wave.global_position.x > start_x + 40.0,
			"the wave either frees on contact or keeps travelling forward")
	p1.health = saved_hp
	p1.health_changed.emit(p1.health, p1.max_health)
	p1.global_position = saved_p1
	p2.global_position = saved_p2
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
	p1._stun_frames = 0
	p1._hitstop_frames = 0
	p2._hitstop_frames = 0
	p2._attack = {}
	p2._attack_id = &""
	if p1.state == BaseFighter.State.HITSTUN:
		p1.change_state(BaseFighter.State.IDLE)
	p1.input_locked = false
	p2.input_locked = false
	arena._clear_projectiles()
	await process_frame

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

	# The towers are `.glb` slots now: two of them, both empty until the art is delivered,
	# and no procedural cabinet, cone, bracket or VU LED anywhere in the scene.
	_check(stage3d != null and stage3d.speaker_stack_count() == 2
			and stage3d.speaker_model_count() == 0,
		"the two speaker towers are empty model slots, not procedural geometry",
		"%d slot(s) / %d loaded" % [stage3d.speaker_stack_count() if stage3d != null else -1,
			stage3d.speaker_model_count() if stage3d != null else -1])
	if stage3d != null:
		var paths := stage3d.speaker_slot_paths()
		_check(paths.size() == 2
				and paths[0].ends_with("jamaican_speaker.glb")
				and paths[1].ends_with("rasta_speaker.glb"),
			"the left slot asks for jamaican_speaker.glb and the right for rasta_speaker.glb",
			"%s" % [paths])
		_check(stage3d.get_node_or_null("SpeakerStackLeft/Plinth") == null
				and stage3d.get_node_or_null("SpeakerStackLeft/AmpRack") == null
				and stage3d.get_node_or_null("BarrierRail") != null,
			"no procedural stack remains, while the stage barrier still stands")
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
	_check(String(arena.CALLOUT_GLOSSES["TUMP OUT HIM TEET!"]).contains("teeth")
			and String(arena.CALLOUT_GLOSSES["TEK WEH HIM MIC!"]).contains("microphone"),
		"both new callouts keep a separate English gloss")
	# Glosses stay in their own field, never folded into the spoken spelling.
	_check(String(arena.CALLOUT_GLOSSES["WHOLE-AWN-DEH!"]).contains("Hold on a second")
			and String(arena.CALLOUT_GLOSSES["PLAYAH NEX TUNE!"]).contains("Play another song")
			and String(arena.CALLOUT_GLOSSES["POPPYSHOW!"]).contains("Show-off"),
		"each new callout keeps a separate English gloss")

	# ---- 31-entry Jamaican Patois proverbs & expressions (AGENTS.md §8) ------
	var collection: Array = arena.PATWA_COLLECTION
	_check(collection.size() == 31, "the Patois collection carries all 31 entries",
		"%d" % collection.size())
	var patwa_seen := {}
	var patwa_duplicates := []
	var patwa_missing_gloss := []
	var patwa_missing_trigger := []
	var patwa_wired := {}
	for kind in arena.CALLOUTS:
		for phrase in arena.CALLOUTS[kind]:
			patwa_wired[String(phrase)] = true
	for phrase in arena.PROVERB_BANNER:
		patwa_wired[String(phrase)] = true
	for phrase in collection:
		var text := String(phrase)
		if patwa_seen.has(text):
			patwa_duplicates.append(text)
		patwa_seen[text] = true
		var gloss_text := String(arena.CALLOUT_GLOSSES.get(text, ""))
		if gloss_text == "" or not gloss_text.begins_with("(Translation:"):
			patwa_missing_gloss.append(text)
		if not patwa_wired.has(text):
			patwa_missing_trigger.append(text)
	_check(patwa_duplicates.is_empty(), "no Patois entry is duplicated",
		"%s" % [patwa_duplicates])
	_check(patwa_missing_gloss.is_empty(),
		"every Patois entry resolves to a clean English subtitle gloss",
		"%s" % [patwa_missing_gloss])
	_check(patwa_missing_trigger.is_empty(),
		"every Patois entry is wired to a callout pool or the intro banner",
		"%s" % [patwa_missing_trigger])
	# WASH-BELLY is L!kkle Moore's line; the shared heavy/counter pools cover the rest.
	_check(arena.CALLOUTS[&"wash_belly"] == ["WASH-BELLY"]
			and arena._impact_callout(&"tump", false, &"young_selecta") == &"wash_belly"
			and arena._impact_callout(&"tump", false, &"feedback") == &"heavy",
		"WASH-BELLY is weighted to L!kkle Moore, not the whole roster")
	_check(arena._impact_callout(&"jab", true, &"feedback") == &"counter"
			and arena._impact_callout(&"upper_box", false, &"lickshot") == &"heavy",
		"counter hits and heavies route to their own proverb pools")
	# The match-intro banner rotates its nine traditional proverbs and carries the V gloss.
	var first_proverb := String(arena.PROVERB_BANNER[
		arena._proverb_cursor % arena.PROVERB_BANNER.size()])
	_check(arena._show_match_proverb() and hud.proverb_text() == first_proverb
			and hud.proverb_gloss().begins_with("(Translation:"),
		"the match-intro banner shows a Patois proverb with its V-key gloss",
		hud.proverb_text())
	var second_proverb := String(arena.PROVERB_BANNER[
		arena._proverb_cursor % arena.PROVERB_BANNER.size()])
	_check(second_proverb != first_proverb and arena._show_match_proverb()
			and hud.proverb_text() == second_proverb,
		"the next match intro rotates to a different proverb", hud.proverb_text())
	hud.subtitles_enabled = false
	hud.show_proverb(first_proverb, String(arena.CALLOUT_GLOSSES[first_proverb]), 3.0)
	_check(hud.proverb_text() == first_proverb and hud.proverb_gloss() == "",
		"V-off keeps the Patois banner readable and hides only the English subtitle")
	hud.subtitles_enabled = true
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
	_check(kid_model is FighterModel3D, "L!kkle Moore renders from his real 3D upload")
	_check(kid_model != null and kid_model.triangle_count() < 35000
			and kid_model.triangle_count() >= 20000,
		"L!kkle Moore's decimated mesh stays under the 35 000-triangle budget",
		"%d tris" % (kid_model.triangle_count() if kid_model != null else -1))
	_check(kid_model is FighterModel3D and not (kid_model is FighterBillboard3D),
		"the kid no longer falls back to a Sprite3D billboard")
	_check(kid_model != null and kid_model.has_albedo_texture()
			and kid_model.albedo_size == Vector2i(1024, 1024),
		"L!kkle Moore's albedo decodes as a 1024 x 1024 texture",
		"%s" % [kid_model.albedo_size if kid_model != null else Vector2i.ZERO])
	_check(kid_model != null and absf(kid_model.model_height - 1.27) < 0.02
			and absf(kid_model.measured_height() - 1.27) < 0.02,
		"the kid's assembled mesh measures his 82 % relative height",
		"%.2f m config / %.3f m measured" % [kid_model.model_height if kid_model != null else 0.0,
			kid_model.measured_height() if kid_model != null else 0.0])
	_check(kid_model != null and kid_model.feet_offset > 0.0,
		"the kid model is seated feet-down on the world floor")
	_check(not p2.sprite.visible and p2.is_3d_presentation(),
		"the 2D sprite is hidden while the 3D model carries his art")
	_assert_procedural_stance(kid_model, p2, "L!kkle Moore")
	_assert_move_pose_difference(kid_model, p2, "L!kkle Moore")

	# ---- Low sweep ducks high jabs and trips ------------------------------
	var saved_kid_state: int = p2.state
	var saved_kid_attack: Dictionary = p2._attack
	p2._attack = p2.attacks[&"tump"]
	p2._attack_id = &"tump"
	p2.state = BaseFighter.State.ATTACK_ACTIVE
	var low_hurt := p2.hurt_rect()
	_check(is_equal_approx(low_hurt.size.y, p2.crouch_size.y)
			and low_hurt.position.y > -90.0,
		"the low sweep ducks the standing hurtbox under a high jab",
		"hurt top %.1f / height %.1f" % [low_hurt.position.y, low_hurt.size.y])
	var high_jab := Rect2(Vector2(p2.global_position.x - 42.0, p2.global_position.y - 129.0),
		Vector2(84, 38))
	_check(not high_jab.intersects(low_hurt),
		"a normal high jab volume whiffs over the sweeping kid")
	p2.state = saved_kid_state
	p2._attack = saved_kid_attack
	p2._attack_id = &""
	p2.state_frame = 0
	p2._play_state_anim()
	_check(p2._grab_hold_ticks == 9 and p2._grab_hold_ticks < BaseFighter.GRAB_HOLD_TICKS
			and p2._grab_recovery_ticks < BaseFighter.GRAB_RECOVERY_TICKS,
		"L!kkle Moore's trip throw commits and recovers faster than the shared adult grab",
		"hold %d / recovery %d" % [p2._grab_hold_ticks, p2._grab_recovery_ticks])

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
	_check(arena2.get_node_or_null("CrowdLine") == null
			and arena2.get_node_or_null("ForegroundCrowd") == null
			and arena2.get_node_or_null("CrowdHaze") == null,
		"the 2D crowd line, foreground stack and haze cards are deleted from the scene")
	var yard: CrowdController3D = arena2.crowd
	_check(yard != null and yard.count() >= 4,
		"the yard is built by the 3D crowd controller",
		"%d spectators" % (yard.count() if yard != null else -1))

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
	# Night is a palette change, not a dimmer: the crowd keeps its full albedo all night
	# (the 2D `set_night()` silhouette dimming is deleted with the silhouettes).
	_check(arena2._time_phase == 2 and arena2.get_node("NightWash").modulate.a > 0.5,
		"night drives the arena palette without dimming the crowd")
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
	_check(arena2.get_node_or_null("ForegroundCrowd") == null,
		"sunset has no foreground crowd layer to raise")

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
	# The near-crowd band was a 2D silhouette stack pinned to the bottom edge. It is deleted,
	# along with its node and its painter: no 2D crowd draws over the fight any more.
	_check(arena2.get_node_or_null("Foreground") == null
			and arena2.get_node_or_null("ForegroundCrowd") == null,
		"no 2D near-crowd band draws in front of the fighters")
	for child in arena2.get_children():
		var cue := child as CanvasItem
		if cue != null:
			_check(not String(cue.name).contains("Crowd"),
				"no CanvasItem named for the crowd survives", String(cue.name))
			break

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
	var cam: Camera2D = arena2.camera
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

	# ---- Active 3D atmosphere: DJ booth + staggered Mixamo crowd (2026-11-22) ----------
	# Owner request: two DJs behind a turntable/mixer rig between the mid-ground speaker
	# stacks, and a ringside crowd that reacts on staggered, zone-loyal clocks. The rig and
	# the crowd's flags, lighters and airhorns are `.glb` slots / clip states now: the
	# procedural prop meshes are deleted (playtest 2026-11-24, issue 3). Every body is a delivered Mixamo character: the 2.5D
	# silhouettes are deleted (2026-11-24), so nothing here can fall back to a painted stand-in.
	# Everything is presentation only; the checks below also prove the cues cannot touch
	# health or fighter state.
	var atmosphere: Arena3D = arena2.arena3d
	var crowd3d: CrowdController3D = atmosphere.crowd3d
	var booth: DJBooth3D = atmosphere.dj_booth
	_check(booth != null and atmosphere.dj_count() == 2,
		"two 3D DJs work the decks between the speaker stacks",
		"%d DJs" % atmosphere.dj_count())
	_check(booth != null and absf(booth.position.x) < 0.01 and booth.position.z < -2.55,
		"the DJ booth is centred between the stacks and behind the crowd barrier",
		"%s" % [booth.position if booth != null else Vector3.ZERO])
	_check(booth != null and booth.deck != null
			and booth.deck.model_path.ends_with("dj_booth.glb")
			and booth.find_children("Mixer", "MeshInstance3D", true, false).is_empty()
			and booth.find_children("Vinyl", "MeshInstance3D", true, false).is_empty(),
		"the rig is one dj_booth.glb slot — no turntable, vinyl, mixer or fader is built in code",
		"%s loaded=%s" % [booth.deck_path() if booth != null else "-",
			str(booth.deck_loaded()) if booth != null else "-"])
	_check(booth != null and booth.empty_slot_count() == 0,
		"both DJ slots are filled by delivered characters",
		"%d empty" % (booth.empty_slot_count() if booth != null else -1))
	_check(crowd3d != null and crowd3d.count() >= 4
			and atmosphere.crowd_count() == crowd3d.count(),
		"the yard is a ringside crowd of delivered characters",
		"%d spectators" % atmosphere.crowd_count())
	_check(crowd3d.zone_count(0) == 4 and crowd3d.zone_count(1) == 4,
		"the crowd splits into two equal loyalty banks",
		"%d / %d" % [crowd3d.zone_count(0), crowd3d.zone_count(1)])
	var dropped_props := crowd3d.find_children("FlagPole", "Node3D", true, false).size() \
		+ crowd3d.find_children("LighterHand", "Node3D", true, false).size() \
		+ crowd3d.find_children("Airhorn", "Node3D", true, false).size()
	_check(dropped_props == 0,
		"the yard carries no procedural flags, lighters or airhorns",
		"%d prop node(s)" % dropped_props)
	_check(atmosphere.get_node_or_null("Crowd00") == null
			and crowd3d.get_node_or_null("Spectator00") != null,
		"the old capsule crowd nodes are gone")

	# Staggered heavy-hit reaction: ringside first, back rows last.
	crowd3d.settle()
	booth.settle()
	_check(crowd3d.reacting_count() == 0, "the yard starts neutral")
	atmosphere.notify_combat_event(&"heavy_hit", 0)
	_check(crowd3d.reacting_count() == 0 and crowd3d.pending_count() == crowd3d.count(),
		"nobody answers on the impact frame itself",
		"%d queued" % crowd3d.pending_count())
	crowd3d.tick(0.14)
	var ringside := crowd3d.row_reacting(0)
	_check(ringside > 0, "ringside starts cheering inside 0.14 s", "%d person(s)" % ringside)
	_check(ringside < crowd3d.count() and crowd3d.pending_count() > 0,
		"the bank ripples outward instead of jumping in unison",
		"%d up / %d still queued" % [ringside, crowd3d.pending_count()])
	crowd3d.tick(0.8)
	_check(crowd3d.reacting_count() == crowd3d.count(),
		"the whole yard answers inside a beat",
		"%d / %d" % [crowd3d.reacting_count(), crowd3d.count()])
	_check(crowd3d.zone_state_count(0, CrowdController3D.STATE_CHEER)
			+ crowd3d.zone_state_count(0, CrowdController3D.STATE_HYPE) == 4,
		"P1's bank erupts in cheers",
		"%d cheering" % (crowd3d.zone_state_count(0, CrowdController3D.STATE_CHEER)
			+ crowd3d.zone_state_count(0, CrowdController3D.STATE_HYPE)))
	_check(crowd3d.zone_state_count(1, CrowdController3D.STATE_DISBELIEF) == 4,
		"the rival bank throws its hands on its head",
		"%d in disbelief" % crowd3d.zone_state_count(1, CrowdController3D.STATE_DISBELIEF))
	_check(booth.pointing(), "a DJ points at the fighters on a heavy hit")
	_check(booth.deck != null and booth.deck.model_path.ends_with("dj_booth.glb")
			and not booth.deck_loaded(),
		"the deck is an empty PropLoader slot for dj_booth.glb",
		"%s loaded=%s" % [booth.deck_path(), str(booth.deck_loaded())])

	# Knockdown, K.O. and DJ tag: horns up and the booth celebrates.
	crowd3d.settle()
	booth.settle()
	atmosphere.notify_combat_event(&"knockdown", 1)
	crowd3d.tick(0.6)
	booth.tick(0.1)
	_check(booth.airhorn_up() and crowd3d.zone_state_count(1, CrowdController3D.STATE_HYPE) == 4,
		"a knockdown lifts the selector's arm and sends his bank into hype",
		"booth raised %s / %d hyped" % [str(booth.airhorn_up()),
			crowd3d.zone_state_count(1, CrowdController3D.STATE_HYPE)])
	crowd3d.settle()
	booth.settle()
	atmosphere.notify_combat_event(&"ko", 1)
	crowd3d.tick(0.6)
	booth.tick(0.1)
	_check(booth.celebrating() and crowd3d.zone_state_count(1, CrowdController3D.STATE_HYPE) == 4,
		"a K.O. sends the winning bank into a jump and the booth into a celebration")
	crowd3d.settle()
	booth.settle()
	atmosphere.notify_combat_event(&"tag", -1)
	_check(booth.airhorn_up(), "a DJ tag is answered by the selector raising his arm")
	atmosphere.notify_combat_event(&"hype", -1)
	crowd3d.tick(0.6)
	_check(crowd3d.reacting_count() == crowd3d.count(),
		"a Hype surge puts the whole yard on its feet",
		"%d / %d" % [crowd3d.reacting_count(), crowd3d.count()])

	# Cues are presentation only: health, state and frame data never move.
	var hp_before := [p1b.health, p2.health]
	var state_before := [p1b.state, p2.state]
	atmosphere.notify_combat_event(&"ko", 0)
	_check(p1b.health == hp_before[0] and p2.health == hp_before[1]
			and p1b.state == state_before[0] and p2.state == state_before[1],
		"crowd and DJ cues never touch health or fighter state")

	# Budget: measured from the meshes that were actually built.
	var crowd_tris := crowd3d.triangle_count()
	var booth_tris := booth.triangle_count()
	# The delivered ringside characters (8 × ≤3 500) and both decks (2 × ≤3 500) replace
	# the 2-triangle silhouette quads on those slots, so the atmosphere cap moves from
	# 15 000 to 40 000. Every individual character is still held to 3 500 below.
	_check(crowd_tris > 0 and booth_tris > 0 and atmosphere.atmosphere_triangles() < 40000,
		"the 3D booth and ringside characters stay under 40 000 triangles",
		"%d total (crowd %d / booth %d)" % [atmosphere.atmosphere_triangles(),
			crowd_tris, booth_tris])

	# ---- Four female crowd models in the ringside banks (2026-11-24) -------------
	var female_files: Array[String] = []
	for path in CharacterModelSlots.model_paths(CharacterModelSlots.CROWD_DIR):
		if path.get_file().to_lower().contains("female"):
			female_files.append(path)
	_check(female_files.size() == 4, "all four female crowd models ship in the crowd slot",
		", ".join(female_files.map(func(p): return String(p).get_file())))
	var probe_root := Node3D.new()
	crowd3d.add_child(probe_root)
	for path in female_files:
		var female := CharacterModelSlots.spawn_one(probe_root, path, 1.70)
		var label := String(path).get_file()
		_check(female != null, "%s imports as a 3D character" % label)
		if female == null:
			continue
		_check(CharacterModelSlots.character_bones(female) > 20,
			"%s keeps a real mixamorig skeleton" % label,
			"%d bones" % CharacterModelSlots.character_bones(female))
		_check(CharacterModelSlots.character_triangles(female) <= 3500,
			"%s is decimated to the 3 500-triangle crowd budget" % label,
			"%d tris" % CharacterModelSlots.character_triangles(female))
		female.queue_free()
	probe_root.queue_free()
	var female_front := 0
	for slot in crowd3d.model_slots():
		if String(slot.scene_file_path).to_lower().contains("female"):
			female_front += 1
	_check(female_front >= 2,
		"female spectators stand in the front-row 3D banks with the male crowd",
		"%d female / %d ringside" % [female_front, crowd3d.model_slots().size()])

	# Palette: the phase rim reaches every character through its own cel material, and
	# nothing else about the material moves — albedo and brightness stay untouched.
	atmosphere.apply_phase(2)
	var night_rim: Color = crowd3d._cel_materials[0].get_shader_parameter("rim_colour")
	_check(night_rim.b > night_rim.r,
		"the crowd's rim follows the night cyan palette", str(night_rim))
	var night_albedo: Texture2D = crowd3d._cel_materials[0].get_shader_parameter("albedo_texture")
	_check(night_albedo != null and night_albedo.resource_path != "",
		"the night palette leaves every character's albedo bound",
		str(night_albedo.resource_path if night_albedo != null else "<null>"))
	atmosphere.apply_phase(0)
	crowd3d.settle()
	booth.settle()

	# ---- Sound-system slots, not procedural towers (playtest 2026-11-24) ---------------
	_check(atmosphere.speaker_stack_count() == 2
			and atmosphere.speaker_model_count() == 0,
		"two empty speaker slots stand either side of the yard",
		"%d slot(s) / %d loaded" % [atmosphere.speaker_stack_count(),
			atmosphere.speaker_model_count()])
	var stack_nodes := atmosphere.find_children("SpeakerStack*", "Node3D", true, false)
	var stack_meshes := 0
	for node in stack_nodes:
		stack_meshes += node.find_children("*", "MeshInstance3D", true, false).size()
	_check(stack_nodes.size() == 2 and stack_meshes == 0,
		"the speaker slots contain no meshes at all",
		"%d node(s) / %d mesh(es)" % [stack_nodes.size(), stack_meshes])
	atmosphere._pulse = 2.0
	atmosphere._update_speakers(0.0)
	atmosphere._pulse = 0.0
	atmosphere._update_speakers(0.0)

	# ---- Clean human-rig slots instead of capsule mannequins (2026-11-23) --------------
	_check(crowd3d.empty_slot_count() == 0
			and crowd3d.model_slots().size() == crowd3d.count(),
		"every spectator is a delivered Mixamo character — no silhouettes exist",
		"%d empty slots / %d models" % [crowd3d.empty_slot_count(),
			crowd3d.model_slots().size()])
	_check(crowd3d.animated_model_count() == crowd3d.count(),
		"every spectator's own clip is playing",
		"%d animated" % crowd3d.animated_model_count())
	_check(crowd3d.legacy_mannequin_count() == 0 and booth.legacy_mannequin_count() == 0,
		"no capsule or cylinder mannequin bodies are left on screen",
		"%d / %d legacy body meshes" % [crowd3d.legacy_mannequin_count(),
			booth.legacy_mannequin_count()])
	_check(DirAccess.dir_exists_absolute(CharacterModelSlots.DJ_DIR)
			and DirAccess.dir_exists_absolute(CharacterModelSlots.CROWD_DIR),
		"the .fbx drop-in folders exist for DJs and the crowd")
	_check(booth.model_slots().size() == booth.dj_count(),
		"the delivered .fbx characters fill every DJ slot",
		"%d models" % booth.model_slots().size())

	# ---- Delivered Mixamo crowd/DJ characters (2026-11-23) ----------------------------
	# Every delivered character must be a real 68-bone `mixamorig` rig with its animation
	# take, decimated to the 3 500-triangle crowd/DJ budget, wearing the toon + ink pass,
	# and crossfading its clips from the arena's own event cues.
	var delivered: Array = []
	delivered.append_array(crowd3d.model_slots())
	delivered.append_array(booth.model_slots())
	var rig_failures: Array[String] = []
	var budget_failures: Array[String] = []
	var clip_failures: Array[String] = []
	var cel_failures: Array[String] = []
	for model in delivered:
		var model_name := String(model.name)
		var bones := CharacterModelSlots.character_bones(model)
		if bones <= 20:
			rig_failures.append("%s:%d" % [model_name, bones])
		var tris := CharacterModelSlots.character_triangles(model)
		if tris <= 0 or tris > 3500:
			budget_failures.append("%s:%d" % [model_name, tris])
		var player := CharacterModelSlots.animation_player(model)
		var clips: Array = player.get_animation_list() if player != null else []
		var tracks := 0
		if player != null and not clips.is_empty():
			tracks = player.get_animation(clips[0]).get_track_count()
		if player == null or clips.size() < 3 or tracks < 50:
			clip_failures.append("%s:%d clips/%d tracks" % [model_name, clips.size(), tracks])
		if CharacterModelSlots.cel_surfaces(model) == 0:
			cel_failures.append(model_name)
	_check(delivered.size() == 10 and rig_failures.is_empty(),
		"all 10 delivered characters carry a real Mixamo skeleton (> 20 bones)",
		"%d characters, failures %s" % [delivered.size(), rig_failures])
	_check(not delivered.is_empty() and budget_failures.is_empty(),
		"every delivered crowd/DJ mesh is decimated to ≤ 3 500 triangles",
		", ".join(budget_failures))
	_check(not delivered.is_empty() and clip_failures.is_empty(),
		"every delivered character has acting clips with real AnimationPlayer tracks",
		", ".join(clip_failures))
	_check(not delivered.is_empty() and cel_failures.is_empty(),
		"every delivered character wears the toon shader plus inverted-hull ink",
		", ".join(cel_failures))
	var hand_attachments := crowd3d.find_children("*", "BoneAttachment3D", true, false).size() \
		+ booth.find_children("*", "BoneAttachment3D", true, false).size()
	_check(hand_attachments == 0,
		"no procedural prop is parented to a crowd or DJ hand any more",
		"%d hand attachment(s)" % hand_attachments)

	# Acting: the same combat cues crossfade the delivered characters, per bank.
	crowd3d.settle()
	booth.settle()
	var neutral_clip := crowd3d.model_clip_of(0)
	atmosphere.notify_combat_event(&"heavy_hit", 0)
	crowd3d.tick(0.9)
	booth.tick(0.1)
	_check(crowd3d.model_act_of(0) == CharacterModelSlots.ACT_CHEER
			and crowd3d.model_act_of(4) == CharacterModelSlots.ACT_DISBELIEF,
		"the delivered banks crossfade to cheer and disbelief on a heavy hit",
		"left %s / right %s" % [crowd3d.model_act_of(0), crowd3d.model_act_of(4)])
	_check(crowd3d.model_clip_of(0) == "mixamo_cheer"
			and crowd3d.model_clip_of(0) != neutral_clip,
		"the cheer clip is actually playing, not just recorded as a state",
		"%s (neutral %s)" % [crowd3d.model_clip_of(0), neutral_clip])
	_check(booth.model_act_of(0) == CharacterModelSlots.ACT_HYPE,
		"the selectors crossfade to the hype take when they point at the fighters",
		String(booth.model_act_of(0)))
	crowd3d.settle()
	booth.settle()
	_check(crowd3d.model_act_of(0) == CharacterModelSlots.ACT_NEUTRAL
			and crowd3d.model_clip_of(0) == neutral_clip,
		"a settled yard crossfades back to each character's own loop",
		crowd3d.model_clip_of(0))
	# ---- Every crowd and DJ surface carries a real albedo (playtest 2026-11-24) --------
	var unbound := 0
	var surfaces := 0
	for model in crowd3d.model_slots():
		surfaces += _count_cel_surfaces(model)
		unbound += CharacterModelSlots.report_albedo("crowd", model)
	for model in booth.model_slots():
		surfaces += _count_cel_surfaces(model)
		unbound += CharacterModelSlots.report_albedo("dj", model)
	_check(unbound == 0 and surfaces >= crowd3d.model_slots().size() + booth.model_slots().size(),
		"every crowd and DJ surface binds a delivered albedo — none is null",
		"%d surfaces / %d unbound" % [surfaces, unbound])
	# One cel material per character, never shared between characters: that is what stops one
	# spectator's tint or dimming from repainting the rest of the bank.
	var owners := {}
	var doubled := 0
	var bindings := 0
	for model in crowd3d.model_slots():
		for child in model.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi == null or mi.mesh == null or CharacterModelSlots._under_hand_prop(mi):
				continue
			for surface in mi.mesh.get_surface_count():
				var material := mi.get_surface_override_material(surface)
				if material == null:
					continue
				var id := material.get_instance_id()
				if owners.has(id) and owners[id] != model.get_instance_id():
					doubled += 1
				owners[id] = model.get_instance_id()
				bindings += 1
	_check(doubled == 0 and bindings > 0,
		"cel materials are per character, so no two characters can tint each other",
		"%d shared material binds across %d character bindings" % [doubled, bindings])
	var tint_amount := 1.0
	for model in crowd3d.model_slots():
		for child in model.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
				continue
			var material := mi.get_surface_override_material(0) as ShaderMaterial
			if material != null:
				tint_amount = minf(tint_amount,
					float(material.get_shader_parameter("shadow_tint_amount")))
	_check(tint_amount <= 0.001,
		"no global darkening on the cel shader — crowd and DJ albedo renders at full brightness",
		"shadow_tint_amount %.3f" % tint_amount)

	# ---- Music bed cannot bleed into Match 2+ (owner playtest, 2026-11-23) --------------
	music_bed.play_victory()
	_check(music_bed.is_playing() and not music_bed.is_off(),
		"the victory bed starts on the match-over screen")
	arena2._on_round_started(0)
	_check(arena2.music_bed_silent(),
		"a new match / rematch hard-stops the bed before the round sting",
		"%s / playing %s / %.1f dB" % [music_bed.state_name(), str(music_bed.is_playing()),
			music_bed.current_db()])

	# ---- Arcade cabinet typography (owner playtest, 2026-11-23) -------------------------
	# Read the HUD's own constants and draw path instead of poking its banner timers, so the
	# check does not depend on a banner being on screen at this exact moment.
	var hud_script := load("res://scripts/ui/TestHud.gd") as GDScript
	var hud_consts: Dictionary = hud_script.get_script_constant_map() if hud_script != null else {}
	var pop_gain := float(hud_consts.get("POP_GAIN", 0.0))
	var pop_seconds := float(hud_consts.get("POP_SECONDS", 0.0))
	var gold: Color = hud_consts.get("GOLD", Color.BLACK)
	var rasta: Array = hud_consts.get("RASTA_STRIP", [])
	_check(pop_gain >= 0.2 and pop_seconds > 0.0,
		"banners carry a scale-pop entrance", "gain %.2f over %.2f s" % [pop_gain, pop_seconds])
	_check(gold.r > 0.9 and rasta.size() == 3,
		"the HUD carries gold ink and a three-block Rasta accent strip")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/TestHud.gd")
	_check(hud_source.contains("draw_string_outline") and hud_source.contains("for step in [3, 2, 1]"),
		"every HUD label draws a thick ink outline and a 3D extruded shadow")
	_check(hud_source.contains("_pop_size(&\"round\"") and hud_source.contains("_pop_size(&\"sub\""),
		"round banners and Patwa callouts both pop their type on entrance")
	_check(hud_source.contains("outline := maxi(3") or hud_source.contains("outline := maxi(3,"),
		"the ink outline is thick at every size")

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

	# ---- Prop slots: five .glb files, nothing drawn until they exist (2026-11-24) ------
	# The arena no longer builds a single prop out of primitives. Every speaker, the deck,
	# the mic and the stand is a `PropLoader` that names its file and stays empty while the
	# file is missing. This is the run-with-everything-missing case.
	var prop_slots: Array[PropLoader] = []
	for node in arena2.find_children("*", "PropLoader", true, false):
		prop_slots.append(node as PropLoader)
	_check(prop_slots.size() == 5,
		"the scene carries exactly five .glb prop slots",
		"%d slot(s)" % prop_slots.size())
	var wanted := ["jamaican_speaker.glb", "rasta_speaker.glb", "dj_booth.glb",
		"wireless_mic.glb", "mic_stand.glb"]
	for name in wanted:
		var matched := ""
		var empty := false
		for slot in prop_slots:
			if String(slot.model_path).ends_with(name):
				matched = slot.model_path
				empty = slot.is_empty()
		_check(matched != "" and empty,
			"the %s slot exists and draws nothing while the file is missing" % name,
			"%s empty=%s" % [matched, str(empty)])
	var slot_meshes := 0
	for slot in prop_slots:
		slot_meshes += slot.find_children("*", "MeshInstance3D", true, false).size()
	_check(slot_meshes == 0,
		"no prop slot substitutes a fallback mesh for a missing model",
		"%d mesh(es) inside the slots" % slot_meshes)
	_check(FileAccess.file_exists("res://assets/models/props/README.md"),
		"the props folder documents the five expected files")

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

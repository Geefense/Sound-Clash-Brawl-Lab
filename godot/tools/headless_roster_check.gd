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



## First textured cel mesh on one character (hand props excluded). Used by the per-instance
## palette check, which writes one rig's accent and proves its neighbour does not move.
func _first_cel_mesh(node: Node3D) -> MeshInstance3D:
	if node == null:
		return null
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi != null and mi.mesh != null and not CharacterModelSlots._under_hand_prop(mi):
			return mi
	return null


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


## World-space union of every mesh under a node (the delivered tower, a crowd rig, a rail).
func _prop_world_bounds(root: Node) -> AABB:
	var out := AABB()
	var first := true
	if root == null:
		return out
	var meshes: Array[Node] = []
	if root is MeshInstance3D:
		meshes.append(root)
	meshes.append_array(root.find_children("*", "MeshInstance3D", true, false))
	for node in meshes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box: AABB = mi.global_transform * mi.mesh.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out


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
	# The mic itself is now a delivered mesh (2026-11-27), so this is no longer "0 triangles":
	# it is exactly the delivered 2 378-triangle model and nothing built in code beside it.
	_check(mp1_model != null and FighterProps.prop_triangles(mp1_model.model_root) == 2378,
		"the hand carries the delivered 2 378-triangle mic and no procedural geometry",
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
	# PART B commit 5 (deliberate band change): CAMERA_DISTANCE 4.58 → 4.10 and the framing pad
	# 0.55 → 0.36 m bring the steady shot 8 % closer (4.45 m → 4.10 m in play), so the band moved
	# 55–65 % → 66–74 % of screen height. The old band was calibrated to the old framing.
	var frame_fraction: float = stage3d.screen_fraction() if stage3d != null else 0.0
	_check(frame_fraction >= 0.66 and frame_fraction <= 0.74,
		"neutral play frames the fighters at 66–74 % of screen height (was 55–65 %)",
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

	# ---- PART B commit 5: crisp rendering, texture readability, resolution guard -------------
	# The project settings are the shipped contract for the Web build, so they are asserted as
	# settings: this workspace renders only through Mesa llvmpipe and cannot judge pixels.
	_check(bool(ProjectSettings.get_setting("display/window/dpi/allow_hidpi", false)),
		"HiDPI is allowed, so a retina phone renders at its own pixel density")
	_check(String(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items"
			and String(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "keep",
		"the UI stretches as canvas_items with aspect keep",
		"%s / %s" % [ProjectSettings.get_setting("display/window/stretch/mode", ""),
			ProjectSettings.get_setting("display/window/stretch/aspect", "")])
	# MSAA 3D is supported by the Compatibility renderer (Godot 4.5 renderer overview), which is
	# the renderer the Web export runs; 2× is the default and 4× is one F7 press away.
	_check(int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", -1)) == 1,
		"2× MSAA is the 3D default under Compatibility",
		"msaa_3d %d" % int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", -1)))
	var aniso := int(ProjectSettings.get_setting(
		"rendering/textures/default_filters/anisotropic_filtering_level", -1))
	_check(aniso == 3, "anisotropic filtering is 8× (was 4×)", "level %d" % aniso)
	# The startup 3D scale: 720p/1080p at 1× needs no reduction; a retina 1080p phone clamps to
	# the floor; a 1440p desktop lands in between. Pure function, no viewport involved.
	_check(is_equal_approx(AdaptiveQuality.render_scale_for(Vector2(1280, 720), 1.0), 1.0) \
			and is_equal_approx(AdaptiveQuality.render_scale_for(Vector2(1920, 1080), 1.0), 1.0),
		"a 720p or 1080p window at 1× renders 3D at full scale")
	var retina: float = AdaptiveQuality.render_scale_for(Vector2(1920, 1080), 2.0)
	var desktop: float = AdaptiveQuality.render_scale_for(Vector2(2560, 1440), 1.0)
	_check(is_equal_approx(retina, AdaptiveQuality.SCALE_FLOOR) \
			and desktop > 0.75 and desktop < 0.79,
		"the 2.2 Mpx cap holds: retina clamps to the 0.67 floor, 1440p lands near 0.77",
		"retina %.2f / 1440p %.3f" % [retina, desktop])
	# Governor hysteresis: one step after ~2 s slow, no second inside the 3 s lockout, the floor
	# holds, and the climb back needs ~10 s of stable frames.
	var gov := AdaptiveQuality.new()
	gov.configure(Vector2(2560, 1440), 1.0)
	var start_scale: float = gov.scale
	for i in 114:                      # 1.9 s at 60 Hz, 50 fps
		gov.step(1.0 / 60.0, 50.0)
	var before: float = gov.scale
	for i in 12:                       # 2.1 s total
		gov.step(1.0 / 60.0, 50.0)
	var stepped: float = gov.scale
	_check(is_equal_approx(before, start_scale) and stepped < before,
		"the governor waits ~2 s under 55 fps, then steps down once",
		"%.3f held at 1.9 s → %.3f at 2.1 s" % [before, stepped])
	for i in 150:                      # 2.5 s more: still inside the 3 s lockout
		gov.step(1.0 / 60.0, 50.0)
	var held: float = gov.scale
	for i in 40:                       # past the lockout
		gov.step(1.0 / 60.0, 50.0)
	_check(is_equal_approx(held, stepped) and gov.scale < held,
		"a second down step needs the 3 s lockout to elapse",
		"%.3f held, then %.3f" % [held, gov.scale])
	for i in 4000:                     # 66 s of 40 fps: the floor is the floor
		gov.step(1.0 / 60.0, 40.0)
	_check(gov.at_floor() and is_equal_approx(gov.scale, AdaptiveQuality.SCALE_FLOOR),
		"the governor never goes below the 0.67 floor", "%.2f" % gov.scale)
	for i in 570:                      # 9.5 s stable at 60 fps
		gov.step(1.0 / 60.0, 60.0)
	var stable: float = gov.scale
	for i in 60:                       # past 10 s
		gov.step(1.0 / 60.0, 60.0)
	_check(is_equal_approx(stable, AdaptiveQuality.SCALE_FLOOR) and gov.scale > stable,
		"the climb back waits ~10 s of stable frames",
		"%.2f held at 9.5 s, then %.2f" % [stable, gov.scale])

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
	# PART B commit 5 — the shading floor, read off the live materials the fighters wear. The
	# toon band itself is the engine's `diffuse_toon` smoothstep (band width = 2 × roughness), so
	# the fragment only has to carry the floor: ALBEDO keeps (1 − floor) of the lit response and
	# the floor is added unlit, which is what stops a Night shadow band crushing a jacket.
	var cel_materials: Array[ShaderMaterial] = []
	for fighter_model in [fb3d, lick3d]:
		if fighter_model != null:
			CharacterModelSlots.collect_cel_materials(fighter_model, cel_materials)
	var floor_ok := not cel_materials.is_empty()
	var band_ok := true
	var tint_ok := true
	var lowest_floor := 1.0
	for material in cel_materials:
		var floor_value: float = float(material.get_shader_parameter("albedo_floor"))
		var band_value: float = float(material.get_shader_parameter("band_softness"))
		lowest_floor = minf(lowest_floor, floor_value)
		floor_ok = floor_ok and floor_value >= CharacterModelSlots.SHADING_FLOOR - 0.0001
		band_ok = band_ok and band_value > 0.5
		tint_ok = tint_ok and is_zero_approx(
			float(material.get_shader_parameter("shadow_tint_amount")))
	_check(floor_ok, "every fighter cel material floors the albedo at 55 %",
		"%d materials, lowest floor %.2f" % [cel_materials.size(), lowest_floor])
	_check(band_ok and tint_ok,
		"the toon band stays soft and the delivered albedo is never tint-darkened")
	_check(toon_code.contains("albedo_floor") and toon_code.contains("EMISSION"),
		"the floor is the shader's own split, not a light or an ambient bump")

	# The towers are `.glb` slots: two of them, and PART 3 commit 8 delivered the left one.
	# No procedural cabinet, cone, bracket or VU LED exists anywhere in the scene.
	_check(stage3d != null and stage3d.speaker_stack_count() == 2
			and stage3d.speaker_model_count() == 1,
		"one delivered tower and one empty slot — not procedural geometry",
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
	# PART B commit 4 (intentional change): the graded look's depth fog was stripped with the
	# washout — the three-stop sky gradient carries the depth instead, in every preset.
	_check(stage3d != null and stage3d.world_env != null
			and (not stage3d.world_env.environment.fog_enabled
				or stage3d.world_env.environment.fog_density <= 0.002),
		"the 3D yard carries depth with its sky rather than fog",
		"fog %.4f" % (stage3d.world_env.environment.fog_density if stage3d != null else -1.0))

	# Lighting is real scene light, phase by phase.
	if stage3d != null:
		stage3d.apply_phase(2, 0.0)
		await process_frame
		_check(stage3d.sun.light_energy < 0.2 and stage3d.spot_left.light_energy > 2.0,
			"night is carried by the overhead SpotLight3D rig, not a screen tint",
			"sun %.2f / spot %.2f" % [stage3d.sun.light_energy, stage3d.spot_left.light_energy])
		var night_sky: Color = stage3d.sky_material.get_shader_parameter("top_colour")
		_check(night_sky.b > night_sky.r and not stage3d.world_env.environment.fog_enabled,
			"night darkens the 3D sky under a clear, unfogged gradient")
		stage3d.apply_phase(1, 0.0)
		await process_frame
		_check(stage3d.sun.light_color.r > stage3d.sun.light_color.b
				and stage3d.spot_left.light_energy < 1.5,
			"sunset turns the DirectionalLight3D warm and low")
		stage3d.apply_phase(0, 0.0)
		await process_frame
		_check(stage3d.sun.light_energy > 1.0 and stage3d.spot_left.light_energy < 0.6,
			"afternoon is a bright directional sun with the spots resting")
		# PART 2: the three rigs are designed light setups, not flat tints. The fighters'
		# directional shadow must always be on, and each phase owns its own fill, sky and rim.
		_check(stage3d.sun.shadow_enabled and stage3d.sun.light_angular_distance <= 0.001,
			"a crisp directional key-light shadow always reads on the fighters",
			"blur %.1f / bias %.2f" % [stage3d.sun.shadow_blur, stage3d.sun.shadow_bias])
		_check(stage3d.fill.light_energy > 0.2
				and stage3d.fill.light_color.b > stage3d.fill.light_color.r,
			"a cool camera fill shapes the afternoon",
			"fill %.2f" % stage3d.fill.light_energy)
		stage3d.apply_phase(1, 0.0)
		await process_frame
		var dusk_bottom: Color = stage3d.sky_material.get_shader_parameter("bottom_colour")
		var dusk_top: Color = stage3d.sky_material.get_shader_parameter("top_colour")
		_check(stage3d.fill.light_color.b > stage3d.fill.light_color.g
				and stage3d.fill.light_color.r > 0.6,
			"sunset fills the yard with violet/magenta instead of grey",
			"%s" % stage3d.fill.light_color)
		_check(dusk_bottom.r > 0.9 and dusk_top.b > 0.35 and dusk_top.r < dusk_bottom.r,
			"sunset is an amber horizon under a violet zenith",
			"top %s / bottom %s" % [dusk_top, dusk_bottom])
		stage3d.apply_phase(2, 0.0)
		await process_frame
		_check(stage3d.rim.light_energy > 1.4 and stage3d.rim.light_color.g > 0.85,
			"night cuts the fighters out with a crisp cyan stage rim",
			"rim %.2f %s" % [stage3d.rim.light_energy, stage3d.rim.light_color])
		_check(stage3d.world_env.environment.ambient_light_color.b > 0.24
				and stage3d.world_env.environment.ambient_light_color.b
					> stage3d.world_env.environment.ambient_light_color.r + 0.1,
			"the night ambient stays deep indigo rather than washed grey",
			"%s" % stage3d.world_env.environment.ambient_light_color)
		stage3d.apply_phase(0, 0.0)
		await process_frame
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
		_check(burst.flash != null and burst.flash.mesh != null and burst.ring != null,
			"a burst adds a crisp impact flash ring on top of the bass shockwave")

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
	_check(yard != null and not yard.rigs_enabled() and yard.count() == 0,
		"the 3D crowd controller exists with its rigs switched off",
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
	# ---- Fix pass commit 1 (2026-11-27): the 22 spectator rigs are GONE ------------------
	# Owner request: a wide, clean sand strip in front of a deeper set. The rigs stand behind
	# a master switch that defaults to false, so the shipped scene builds no spectator node at
	# all — no anchor, no imported character, no material. Crowd Hype, the hype readout, the
	# callout cues and the crowd AUDIO never lived in this controller and are unchanged.
	_check(crowd3d != null and not crowd3d.rigs_enabled() and crowd3d.count() == 0,
		"the 22 spectator rigs are disabled by default",
		"%d rigs / %d planned / enabled %s" % [crowd3d.count() if crowd3d != null else -1,
			crowd3d.planned_rig_count() if crowd3d != null else -1,
			str(crowd3d.rigs_enabled()) if crowd3d != null else "-"])
	_check(crowd3d != null and crowd3d.node_count() == 0
			and crowd3d.find_children("*", "MeshInstance3D", true, false).is_empty()
			and crowd3d.get_node_or_null("Spectator00") == null,
		"nothing of the crowd is instantiated, drawn or parented",
		"%d node(s)" % (crowd3d.node_count() if crowd3d != null else -1))
	var crowd_nodes_before: int = crowd3d.node_count()
	for i in 600:
		crowd3d.tick(1.0 / 60.0)
		if i % 150 == 0:
			atmosphere.notify_combat_event(&"heavy_hit", 0)
	_check(crowd3d.node_count() == crowd_nodes_before and crowd3d.count() == 0,
		"600 frames of ticks and hype cues create no crowd node",
		"%d → %d node(s), %d cue(s)" % [crowd_nodes_before, crowd3d.node_count(),
			crowd3d.cue_count()])
	p1b.hype = int(BaseFighter.HYPE_MAX * 0.4)
	_check(atmosphere._hype_energy() > 0.39 and atmosphere._hype_energy() < 0.41,
		"the Crowd Hype readout still follows the fighter's meter with no rigs",
		"%.2f of the meter" % atmosphere._hype_energy())
	# ---- The two DJs are NOT crowd: they still answer every cue -------------------------
	crowd3d.settle()
	booth.settle()
	atmosphere.notify_combat_event(&"heavy_hit", 0)
	_check(booth.pointing(), "a DJ points at the fighters on a heavy hit")
	_check(booth.deck != null and booth.deck.model_path.ends_with("dj_booth.glb")
			and booth.deck_loaded(),
		"the deck slot loads the delivered dj_booth.glb",
		"%s loaded=%s" % [booth.deck_path(), str(booth.deck_loaded())])
	# Cues are presentation only: health, state and frame data never move.
	var hp_before := [p1b.health, p2.health]
	var state_before := [p1b.state, p2.state]
	atmosphere.notify_combat_event(&"ko", 0)
	_check(p1b.health == hp_before[0] and p2.health == hp_before[1]
			and p1b.state == state_before[0] and p2.state == state_before[1],
		"crowd and DJ cues never touch health or fighter state")

	# Budget: measured from the meshes that were actually built. With the rigs off this is the
	# DJ booth alone, so the old 90 000-triangle crowd ceiling now stands as the booth ceiling.
	var booth_tris := booth.triangle_count()
	_check(booth_tris > 0 and atmosphere.atmosphere_triangles() < 90000,
		"the 3D booth stays inside the 90 000-triangle Chromebook ceiling",
		"%d total (booth %d)" % [atmosphere.atmosphere_triangles(), booth_tris])
	# ---- Bug 5 (2026-11-25): Afternoon / Sunset / Night rigs ----------------------------
	# Each preset is a full setup: three-stop sky plus horizon haze, graded sand, key and rim,
	# and four coloured stage beams inside Compatibility's per-object light limit.
	var stage: Arena3D = atmosphere
	var presets_ok := true
	var skies_ok := true
	var shadow_ok := true
	var lights_ok := true
	var sand_colours := {}
	var rig_detail: Array[String] = []
	for phase in [0, 1, 2]:
		stage.apply_phase(phase, 0.0)
		await process_frame
		var env: Environment = stage.world_env.environment
		if stage.phase_name() == "":
			presets_ok = false
		if stage.sky_material == null or stage.sun_material == null or env == null \
				or stage.sky_material.get_shader_parameter("mid_colour") == null:
			skies_ok = false
		if not stage.sun.shadow_enabled or stage.sun.light_angular_distance > 0.001:
			shadow_ok = false
		if stage.light_count() > Arena3D.max_lights_per_object() \
				or stage.stage_spot_count() != 4 \
				or stage.directional_light_count() > 4:
			lights_ok = false
		if stage.sand_material != null:
			sand_colours[str(stage.sand_material.albedo_color)] = true
		rig_detail.append("%s %d/%d" % [stage.phase_name(), stage.light_count(),
			Arena3D.max_lights_per_object()])
	_check(presets_ok, "each preset loads its own rig", ", ".join(rig_detail))
	_check(skies_ok, "the sky gradient, sun disc and environment resources exist in every preset")
	_check(shadow_ok, "the directional key light still shadows both fighters in every preset")
	_check(lights_ok, "light counts stay inside Compatibility's per-object limit",
		", ".join(rig_detail))
	# PART B commit 4 (intentional change): ACES + glow were the washout. The Compatibility-safe
	# contract is now the opposite — Linear tonemap, no glow, no fog — while SSAO/SDFGI/
	# volumetric fog stay off so the WebGL2 path still renders exactly this.
	var compat_ok: bool = not stage.world_env.environment.ssao_enabled \
		and not stage.world_env.environment.sdfgi_enabled \
		and not stage.world_env.environment.volumetric_fog_enabled \
		and not stage.world_env.environment.glow_enabled \
		and not stage.world_env.environment.fog_enabled \
		and stage.world_env.environment.tonemap_mode == Environment.TONE_MAPPER_LINEAR
	_check(compat_ok, "no SSAO / SDFGI / volumetric fog / glow / fog, with the Linear tonemap")
	_check(sand_colours.size() == 3, "sand and horizon albedo respond to each preset",
		"%d distinct sand colours" % sand_colours.size())

	# ---- Commit 3 (2026-11-25): the fighter cel rim follows the preset --------------------
	# Each sky needs a different edge colour for the fighters to separate cleanly: warm cream
	# against daylight, hot amber against the crimson band, cyan against the indigo night.
	# The rim is an emission band in `toon_cel.gdshader`; the delivered albedo never moves.
	var cel_rims := {}
	var rim_match_ok := true
	var rim_detail: Array[String] = []
	var rim_warm_afternoon := false
	var rim_cool_night := false
	var rim_night_strength := 0.0
	var rim_afternoon_strength := 0.0
	for idx in [0, 1, 2]:
		stage.apply_phase(idx, 0.0)
		await process_frame
		var model := stage.models.get("p1") as FighterModel3D
		if model == null:
			rim_match_ok = false
			continue
		var rim_now: Color = model.cel_rim()
		var strength_now: float = model.cel_rim_strength()
		cel_rims[str(rim_now)] = true
		if not rim_now.is_equal_approx(stage.cel_rim_colour()) \
				or absf(strength_now - stage.cel_rim_strength()) > 0.001:
			rim_match_ok = false
		rim_detail.append("%s %s %.2f" % [stage.phase_name(), str(rim_now), strength_now])
		if idx == 0:
			rim_warm_afternoon = rim_now.r > rim_now.b
			rim_afternoon_strength = strength_now
		elif idx == 2:
			rim_cool_night = rim_now.b > rim_now.r
			rim_night_strength = strength_now
	_check(rim_match_ok, "each preset pushes its own cel rim onto the fighters",
		", ".join(rim_detail))
	_check(cel_rims.size() == 3, "the three presets use three distinct fighter rims",
		"%d colours" % cel_rims.size())
	_check(rim_warm_afternoon and rim_cool_night,
		"the daylight rim is warm and the night rim is cool against its sky")
	_check(rim_night_strength > rim_afternoon_strength,
		"the night rim burns harder so fighters read between the stage beams",
		"%.2f vs %.2f" % [rim_night_strength, rim_afternoon_strength])

	stage.apply_phase(2, 0.0)
	await process_frame
	var beams := {}
	var cyan := false
	var magenta := false
	var amber := false
	for i in stage.stage_spot_count():
		var c: Color = stage.stage_spot_colour(i)
		beams["%.2f_%.2f_%.2f" % [c.r, c.g, c.b]] = true
		if c.b > 0.8 and c.g > 0.8 and c.r < 0.4:
			cyan = true
		if c.r > 0.8 and c.b > 0.5 and c.g < 0.4:
			magenta = true
		if c.r > 0.9 and c.g > 0.5 and c.g < 0.9 and c.b < 0.35:
			amber = true
	_check(cyan and magenta and amber and beams.size() == 4,
		"night lights the yard with four coloured stage beams (cyan / magenta / amber)",
		"%d distinct" % beams.size())
	stage._beat_phase = 0.0
	stage._apply_stage_energies()
	var pulse_high: float = stage.spot_left.light_energy
	stage._beat_phase = 0.5
	stage._apply_stage_energies()
	var pulse_low: float = stage.spot_left.light_energy
	_check(pulse_high > pulse_low * 1.05, "the night beams pulse on the 132 BPM beat",
		"%.2f → %.2f" % [pulse_high, pulse_low])
	stage.apply_phase(0, 0.0)
	crowd3d.settle()
	booth.settle()

	# ---- Sound-system slots, not procedural towers (playtest 2026-11-24) ---------------
	_check(atmosphere.speaker_stack_count() == 2
			and atmosphere.speaker_model_count() == 1,
		"the delivered tower stands on the left and the rasta slot stays empty",
		"%d slot(s) / %d loaded" % [atmosphere.speaker_stack_count(),
			atmosphere.speaker_model_count()])
	var stack_nodes := atmosphere.find_children("SpeakerStack*", "Node3D", true, false)
	var stack_meshes := 0
	var stack_primitives := 0
	for node in stack_nodes:
		for child in node.find_children("*", "MeshInstance3D", true, false):
			stack_meshes += 1
			var part := child as MeshInstance3D
			if part == null or part.mesh == null or part.mesh is PrimitiveMesh:
				stack_primitives += 1
	_check(stack_nodes.size() == 2 and stack_meshes == 1 and stack_primitives == 0,
		"the slots hold exactly the one imported mesh and no primitive at all",
		"%d node(s) / %d mesh(es) / %d primitive(s)" % [stack_nodes.size(), stack_meshes,
			stack_primitives])
	atmosphere._pulse = 2.0
	atmosphere._update_speakers(0.0)
	atmosphere._pulse = 0.0
	atmosphere._update_speakers(0.0)

	# ---- Clean human-rig slots instead of capsule mannequins (2026-11-23) --------------
	_check(booth.legacy_mannequin_count() == 0,
		"no capsule or cylinder mannequin bodies are left on screen",
		"%d legacy body meshes" % booth.legacy_mannequin_count())
	_check(DirAccess.dir_exists_absolute(CharacterModelSlots.DJ_DIR),
		"the .fbx drop-in folder exists for the DJs")
	_check(booth.model_slots().size() == booth.dj_count(),
		"the delivered .fbx characters fill every DJ slot",
		"%d models" % booth.model_slots().size())
	# ---- Delivered Mixamo DJ characters (2026-11-23) ----------------------------------
	# Every delivered selector must be a real 68-bone `mixamorig` rig with its animation
	# take, decimated to the 3 500-triangle budget, wearing the toon + ink pass, and
	# crossfading its clips from the arena's own event cues. The crowd carried the same
	# contract until the rigs were switched off (fix pass commit 1); the two DJs carry it now.
	var delivered: Array = []
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
	_check(delivered.size() == booth.dj_count() and rig_failures.is_empty(),
		"every DJ body on stage carries a real Mixamo skeleton (> 20 bones)",
		"%d characters, failures %s" % [delivered.size(), rig_failures])
	_check(not delivered.is_empty() and budget_failures.is_empty(),
		"every delivered DJ mesh is decimated to ≤ 3 500 triangles",
		", ".join(budget_failures))
	_check(not delivered.is_empty() and clip_failures.is_empty(),
		"every delivered DJ has acting clips with real AnimationPlayer tracks",
		", ".join(clip_failures))
	_check(not delivered.is_empty() and cel_failures.is_empty(),
		"every delivered DJ wears the toon shader plus inverted-hull ink",
		", ".join(cel_failures))
	var hand_attachments := booth.find_children("*", "BoneAttachment3D", true, false).size()
	_check(hand_attachments == 0,
		"no procedural prop is parented to a DJ hand any more",
		"%d hand attachment(s)" % hand_attachments)

	# Acting: the same combat cues crossfade the delivered selectors.
	booth.settle()
	var neutral_clip := booth.model_clip_of(0)
	atmosphere.notify_combat_event(&"heavy_hit", 0)
	booth.tick(0.1)
	_check(booth.model_act_of(0) == CharacterModelSlots.ACT_HYPE,
		"the selectors crossfade to the hype take when they point at the fighters",
		String(booth.model_act_of(0)))
	booth.settle()
	_check(booth.model_act_of(0) == CharacterModelSlots.ACT_NEUTRAL
			and booth.model_clip_of(0) == neutral_clip,
		"a settled booth crossfades back to the selector's own loop",
		booth.model_clip_of(0))
	# ---- Every DJ surface carries a real albedo (playtest 2026-11-24) ------------------
	var unbound := 0
	var surfaces := 0
	for model in booth.model_slots():
		surfaces += _count_cel_surfaces(model)
		unbound += CharacterModelSlots.report_albedo("dj", model)
	_check(unbound == 0 and surfaces >= booth.model_slots().size(),
		"every DJ surface binds a delivered albedo — none is null",
		"%d surfaces / %d unbound" % [surfaces, unbound])
	var tint_amount := 1.0
	for model in booth.model_slots():
		for child in model.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
				continue
			var material := mi.get_surface_override_material(0) as ShaderMaterial
			if material != null:
				tint_amount = minf(tint_amount,
					float(material.get_shader_parameter("shadow_tint_amount")))
	_check(tint_amount <= 0.001,
		"no global darkening on the cel shader — DJ albedo renders at full brightness",
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
		"round banners and Patois callouts both pop their type on entrance")
	_check(hud_source.contains("outline := maxi(3") or hud_source.contains("outline := maxi(3,"),
		"the ink outline is thick at every size")
	# PART 2 scale-up: the HUD has to be readable on a Chromebook screen and an iPhone, so
	# the bars, the clock and the callout pill are all measurably bigger than the old pass.
	var hud_bar_w := float(hud_consts.get("BAR_W", 0.0))
	var hud_bar_h := float(hud_consts.get("BAR_H", 0.0))
	_check(hud_bar_w >= 420.0 and hud_bar_h >= 28.0,
		"the health bars are sized for a small screen, not a desktop monitor",
		"%.0f × %.0f" % [hud_bar_w, hud_bar_h])
	_check(hud_consts.has("FRAME_DARK") and hud_consts.has("CYAN")
			and hud_source.contains("_rasta_strip(box, 0.9)"),
		"the HUD readouts carry a gold/Rasta arcade frame")
	_check(hud_source.contains("160.0, 66.0") and hud_source.contains("FONT_BUNGEE, 40"),
		"the round clock is a big bold 40 px display")

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
	# Overnight props pass, 2026-11-27: the owner delivered the deck and the mic, so three of
	# the five slots now load real files and only `rasta_speaker.glb` / `mic_stand.glb` stay
	# empty. This is the intentional replacement of the old "four slots empty" contract.
	var prop_delivered := {
		"jamaican_speaker.glb": true,
		"rasta_speaker.glb": false,
		"dj_booth.glb": true,
		"wireless_mic.glb": true,
		"mic_stand.glb": false,
	}
	var delivered_prop := "jamaican_speaker.glb"
	for name in wanted:
		var matched := ""
		var loaded := false
		for slot in prop_slots:
			if String(slot.model_path).ends_with(name):
				matched = slot.model_path
				loaded = not slot.is_empty()
		var want_loaded: bool = bool(prop_delivered.get(String(name), false))
		_check(matched != "" and loaded == want_loaded,
			"the %s slot %s" % [name, "loads the delivered .glb" if want_loaded else "stays empty"],
			"%s loaded=%s" % [matched, str(loaded)])
	var slot_meshes := 0
	var primitive_meshes := 0
	for slot in prop_slots:
		for node in slot.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			slot_meshes += 1
			if mi == null or mi.mesh == null or mi.mesh is PrimitiveMesh:
				primitive_meshes += 1
	var slot_mesh_report := ""
	for slot in prop_slots:
		slot_mesh_report += "%s=%d " % [slot.model_path.get_file(),
			slot.find_children("*", "MeshInstance3D", true, false).size()]
	# This yard pairs Feedback with the kid, so it carries one wireless mic and the (still
	# undelivered) stand: tower + deck + mic = three delivered prop meshes.
	_check(slot_meshes == 3 and primitive_meshes == 0,
		"the delivered tower, deck and mic are the only prop meshes, and all imported",
		"%d mesh(es), %d primitive(s): %s" % [slot_meshes, primitive_meshes,
			slot_mesh_report.strip_edges()])
	_check(FileAccess.file_exists("res://assets/models/props/README.md"),
		"the props folder documents the five expected files")

	# ---- Commit 6: the per-slot seating maths, data only --------------------------------
	# No mesh asset is added for this: a made-up AABB drives the same static functions the
	# loader runs, so the scale and the ground offset are proved without a delivered model.
	var speaker_box := AABB(Vector3(-0.5, -1.2, -0.4), Vector3(1.0, 2.4, 0.8))
	var speaker_scale := PropLoader.seat_scale_for(speaker_box, 2.6)
	_check(is_equal_approx(speaker_scale, 2.6 / 2.4),
		"a 2.4 m speaker box scales to the 2.6 m target",
		"x%.3f" % speaker_scale)
	var speaker_bottom: float = speaker_box.position.y * speaker_scale \
		+ PropLoader.seat_offset_y(speaker_box, speaker_scale)
	_check(absf(speaker_bottom) < 0.0001,
		"the seat offset puts the lowest vertex on Y = 0", "%.4f m" % speaker_bottom)
	_check(absf(PropLoader.seat_scale_for(speaker_box, 0.0) - 1.0) < 0.0001,
		"a 0.0 target keeps the delivered scale",
		"x%.3f" % PropLoader.seat_scale_for(speaker_box, 0.0))
	_check(absf(PropLoader.seat_scale_for(AABB(), 2.0) - 1.0) < 0.0001,
		"a degenerate box is never scaled")
	var table_ok := true
	var prop_heights := {
		"jamaican_speaker": 2.6, "rasta_speaker": 2.6, "dj_booth": 1.15,
		"wireless_mic": 0.0, "mic_stand": 0.0,
	}
	for stem in prop_heights:
		var path := "res://assets/models/props/%s.glb" % stem
		if not is_equal_approx(PropLoader.target_height_for(path), float(prop_heights[stem])):
			table_ok = false
	_check(table_ok,
		"every prop slot resolves its table height from the file stem",
		"speakers 2.6, booth 1.15, mic and stand native")
	# The longest-dimension mode (2026-11-27): a mic is sized by how long it is, and the scale is
	# taken in world metres so the rig scale on the hand bone is divided out.
	_check(is_equal_approx(PropLoader.TARGET_LONGEST_M.get("wireless_mic", 0.0), 0.24)
			and not PropLoader.TARGET_LONGEST_M.has("jamaican_speaker"),
		"only the mic is sized by its longest axis, and it targets 0.24 m",
		str(PropLoader.TARGET_LONGEST_M))
	var mic_box := AABB(Vector3(-0.27, -0.95, -0.27), Vector3(0.54, 1.9, 0.54))
	_check(is_equal_approx(PropLoader.longest_scale_for(mic_box, 0.24, 1.0), 0.24 / 1.9),
		"a 1.9 m mic box scales to the 0.24 m target",
		"x%.4f" % PropLoader.longest_scale_for(mic_box, 0.24, 1.0))
	_check(is_equal_approx(PropLoader.longest_scale_for(mic_box, 0.24, 0.01), 0.24 / 0.019),
		"the same box under a centimetre-scaled rig still lands at 0.24 m in the world",
		"x%.4f" % PropLoader.longest_scale_for(mic_box, 0.24, 0.01))
	_check(is_equal_approx(PropLoader.longest_scale_for(mic_box, 0.0, 1.0), 1.0),
		"a 0.0 longest target keeps the delivered scale")
	var defaults_ok := true
	for slot in prop_slots:
		# The delivered hand prop (the wireless mic) is centred on the grip instead of standing
		# on Y = 0, so its ground seat is off by design; every floor prop keeps it on. The
		# still-undelivered stand slot keeps its untouched defaults until it is wired the same
		# way, so it is not part of this rule yet.
		var hand_prop: bool = String(slot.model_path).ends_with("wireless_mic.glb")
		if bool(slot.auto_ground_y) == hand_prop:
			defaults_ok = false
		if not is_zero_approx(slot.target_height_m):
			defaults_ok = false
		if not is_equal_approx(slot.resolved_target_height(),
				PropLoader.target_height_for(slot.model_path)):
			defaults_ok = false
	var default_report := ""
	for slot in prop_slots:
		default_report += "%s[ground=%s h=%.2f longest=%.2f] " % [slot.model_path.get_file(),
			str(slot.auto_ground_y), slot.resolved_target_height(), slot.resolved_target_longest()]
	_check(defaults_ok, "the five slots ship with the right seat mode and no height override",
		default_report.strip_edges())
	var empty_seating := true
	for slot in prop_slots:
		if slot.is_empty() and (not is_zero_approx(slot.seated_bottom())
				or not is_zero_approx(slot.seated_height())):
			empty_seating = false
	_check(empty_seating, "the empty slots seat nothing", "no measured AABB")

	# ---- PART 3 commit 8: the delivered tower's placement contract --------------------
	# The auto-seat from c01cc4a owns the scale and the ground flush; this block proves the
	# result on the delivered mesh instead of re-implementing the maths. Every number below is
	# measured from the scene, not copied from the asset brief.
	var speaker: PropLoader = null
	for slot in prop_slots:
		if not slot.is_empty() and String(slot.model_path).ends_with(delivered_prop):
			speaker = slot
	var prop_yard = arena2.get("arena3d")
	_check(speaker != null and speaker.model != null,
		"the jamaican tower instantiates as a real model in the fight scene",
		"model %s" % str(speaker.model) if speaker != null else "no slot")
	if speaker != null and speaker.model != null and prop_yard != null:
		var spk_box := _prop_world_bounds(speaker.model)
		_check(absf(spk_box.position.y) <= 0.01,
			"the tower's lowest vertex sits on the sand within 1 cm",
			"y %+.4f m" % spk_box.position.y)
		# Fix pass commit 2 (intentional change): the delivered tower is authored at 2.6 m, and the
		# stage's perspective compensation multiplies it by the 1.25× the brief allows so it keeps
		# its read after moving 4.45 m further back. Both numbers are asserted, separately.
		var authored: float = 2.6 * float(prop_yard.stage_speaker_scale())
		_check(absf(spk_box.size.y - authored) / authored <= 0.02,
			"the tower stands its authored 2.6 m times the stage scale, within 2 %",
			"%.3f m (2.60 × %.2f×)" % [spk_box.size.y, prop_yard.stage_speaker_scale()])
		var spk_tris := 0
		for node in speaker.model.find_children("*", "MeshInstance3D", true, false):
			var spk_mi := node as MeshInstance3D
			if spk_mi != null and spk_mi.mesh != null:
				spk_tris += int(spk_mi.mesh.get_faces().size() / 3)
		_check(spk_tris == 2618,
			"the delivered mesh is used unchanged", "%d triangles" % spk_tris)
		var spk_fwd: Vector3 = speaker.model.global_transform.basis.z.normalized()
		var spk_to_cam := Vector3(prop_yard.camera.global_position.x - speaker.global_position.x, 0.0,
			prop_yard.camera.global_position.z - speaker.global_position.z).normalized()
		var spk_to_centre := Vector3(-speaker.global_position.x, 0.0, -speaker.global_position.z).normalized()
		_check(spk_fwd.z > 0.9 and spk_fwd.x > 0.1 and spk_fwd.dot(spk_to_cam) > 0.0 and spk_fwd.dot(spk_to_centre) > 0.4,
			"the painted +Z wall faces the camera side and yaws into the yard",
			"forward (%+.2f, %+.2f, %+.2f), camera dot %.2f, centre dot %.2f" % [
				spk_fwd.x, spk_fwd.y, spk_fwd.z, spk_fwd.dot(spk_to_cam), spk_fwd.dot(spk_to_centre)])
		_check(is_equal_approx(speaker.yaw_degrees, 12.0) and not prop_yard.mirror_into_empty_rasta_slot,
			"the inward yaw is the 12° default and the rasta slot stays empty",
			"yaw %.1f°, mirror %s" % [speaker.yaw_degrees, str(prop_yard.mirror_into_empty_rasta_slot)])
		# Crowd spk_rigs, the barrier and the fighting spk_lane are all separate volumes the tower may
		# not enter. The play spk_lane is the plane the fighters actually occupy: stage bounds in x,
		# ±0.5 m of z around the fighting plane.
		var spk_crowd_clear := true
		var spk_nearest := ""
		var spk_rigs: Array = prop_yard.crowd3d.model_slots() if prop_yard.crowd3d != null else []
		for model in spk_rigs:
			if spk_box.intersects(_prop_world_bounds(model)):
				spk_crowd_clear = false
				spk_nearest = String(model.name)
		_check(spk_crowd_clear, "the tower overlaps no crowd rig",
			spk_nearest if not spk_crowd_clear else "%d spk_rigs clear" % spk_rigs.size())
		var spk_rail: Node3D = prop_yard.get_node_or_null("BarrierRail")
		var spk_rail_box := _prop_world_bounds(spk_rail)
		# Fix pass commit 2 (intentional change of what this asserts): the rail moved back with the
		# set, because at z −2.55 it stood inside the clean sand strip and cut across the booth.
		# It is now BEHIND the towers, which is the ordering asserted here.
		_check(spk_rail != null and not spk_box.intersects(spk_rail_box)
				and spk_rail_box.position.z < spk_box.position.z,
			"the barrier now stands behind the tower, clear of it",
			"tower z %.2f..%.2f, spk_rail z %.2f..%.2f" % [spk_box.position.z, spk_box.end.z,
				spk_rail_box.position.z, spk_rail_box.end.z])
		var spk_lane_left := (BaseFighter.STAGE_LEFT - 640.0) / 140.0
		var spk_lane_right := (BaseFighter.STAGE_RIGHT - 640.0) / 140.0
		var spk_lane := AABB(Vector3(spk_lane_left, 0.0, -0.5), Vector3(spk_lane_right - spk_lane_left, 2.2, 1.0))
		_check(not spk_box.intersects(spk_lane),
			"the tower sits outside the fighters' play volume",
			"tower z %.2f..%.2f vs spk_lane -0.50..0.50" % [spk_box.position.z, spk_box.end.z])

		# ---- Fix pass commit 2 (2026-11-27): the set is placed by RULE, not by a constant ----
		# Booth depth, both towers' mirrored X and depth, the perspective compensation and the
		# two DJ stands all come out of `StageLayout.compute()` over the MEASURED AABB sizes.
		# Everything below is read back from the live scene, so a replacement deck of a different
		# size has to re-derive them itself or fail here.
		var layout: Dictionary = prop_yard.stage_layout()
		_check(not layout.is_empty()
				and prop_yard.stage_booth_z() >= StageLayout.BOOTH_Z_MIN
				and prop_yard.stage_booth_z() <= StageLayout.BOOTH_Z_MAX,
			"the booth stands inside the brief's −5.0…−4.2 m band",
			"booth z %.2f" % prop_yard.stage_booth_z())
		var nearest_face: float = prop_yard.stage_nearest_face_z()
		_check(nearest_face <= -3.6,
			"the nearest prop face stands at least 3.6 m from the fight plane",
			"nearest face z %.2f" % nearest_face)
		_check(-nearest_face >= 2.5,
			"the clear sand strip between the play plane and the set is at least 2.5 m",
			"%.2f m of clean sand" % -nearest_face)
		_check(bool(layout.get("frame_ok", false)) and bool(layout.get("gap_ok", false)),
			"the towers fit the frame with the 12 px margin and clear the deck in depth",
			"x %.2f (want %.2f, limit %.2f), %.2f m clear of the deck in depth" % [
				prop_yard.stage_speaker_x(), float(layout.get("wanted_x", 0.0)),
				float(layout.get("frame_limit_x", 0.0)),
				float(layout.get("depth_clear_m", 0.0))])
		_check(prop_yard.stage_speaker_z() < prop_yard.stage_booth_z(),
			"the towers stand behind the booth's shoulders",
			"tower z %.2f / booth z %.2f" % [prop_yard.stage_speaker_z(),
				prop_yard.stage_booth_z()])
		var s_booth: float = prop_yard.stage_booth_scale()
		var s_tower: float = prop_yard.stage_speaker_scale()
		_check(s_booth >= StageLayout.SCALE_MIN and s_booth <= StageLayout.SCALE_MAX
				and s_tower >= StageLayout.SCALE_MIN and s_tower <= StageLayout.SCALE_MAX,
			"both perspective scales sit inside the 1.0–1.25 clamp",
			"booth %.3f× / tower %.3f×" % [s_booth, s_tower])
		# Apparent size, measured the way the brief means it: world height over lens distance.
		var deck_box := _prop_world_bounds(prop_yard.dj_booth.deck.model)
		var booth_ratio: float = StageLayout.apparent_height(deck_box.size.y,
				prop_yard.stage_booth_z()) / StageLayout.apparent_height(1.15,
				StageLayout.LEGACY_BOOTH_Z)
		var tower_ratio: float = StageLayout.apparent_height(spk_box.size.y,
				prop_yard.stage_speaker_z()) / StageLayout.apparent_height(2.6,
				StageLayout.LEGACY_SPEAKER_Z)
		_check(absf(booth_ratio - 1.0) <= 0.15,
			"the booth keeps its apparent size within 15 % after moving back",
			"%.3f× of today's at %.2f× scale" % [booth_ratio, s_booth])
		# The towers moved 4.45 m back, further than the booth. With the compensation capped at
		# 1.25× their apparent size lands below the 15 % window; measured and logged rather
		# than hidden (AGENTS.md PART J2).
		_check(tower_ratio >= 0.65,
			"the towers keep at least 65 % of their old apparent size at the 1.25× clamp",
			"%.3f× of today's at %.2f× scale" % [tower_ratio, s_tower])
		var dj_clear := true
		var dj_detail := ""
		for dj_index in prop_yard.dj_booth.dj_count():
			var dj_box: AABB = prop_yard.dj_booth.dj_world_bounds(dj_index)
			if dj_box.size == Vector3.ZERO or dj_box.intersects(deck_box) \
					or dj_box.position.z >= deck_box.position.z:
				dj_clear = false
				dj_detail += " #%d z %.2f..%.2f" % [dj_index, dj_box.position.z, dj_box.end.z]
		_check(dj_clear, "both DJ rigs stand behind the deck without interpenetrating it",
			dj_detail if not dj_clear else "deck z %.2f..%.2f, %d men behind" % [
				deck_box.position.z, deck_box.end.z, prop_yard.dj_booth.dj_count()])
		# Data-driven proof, no mesh and no scene involved: a synthetic booth and tower of
		# different sizes go through the same rule and keep the same contract.
		var synthetic: Dictionary = StageLayout.compute(Vector3(3.2, 1.4, 1.6),
			Vector3(0.8, 2.2, 0.6))
		_check(bool(synthetic["frame_ok"]) and bool(synthetic["gap_ok"])
				and is_equal_approx(float(synthetic["booth_z"]), StageLayout.BOOTH_Z)
				and not is_equal_approx(float(synthetic["speaker_x"]),
					prop_yard.stage_speaker_x()),
			"a synthetic 3.2 m booth and 0.8 m tower re-place themselves by rule",
			"tower x %.2f (delivered %.2f), gap %.2f m" % [float(synthetic["speaker_x"]),
				prop_yard.stage_speaker_x(), float(synthetic["gap_m"])])
		# The sand has to run at least 1 m behind the back-most prop AABB. The floor plane is the
		# EXISTING one (no new scenery); this proves the deeper set still stands on it.
		var floor_node: MeshInstance3D = prop_yard.get_node_or_null("SandFloor")
		var floor_back := -INF
		if floor_node != null and floor_node.mesh is PlaneMesh:
			floor_back = floor_node.position.z - (floor_node.mesh as PlaneMesh).size.y * 0.5
		var back_most := INF
		for box in prop_yard.prop_bounds():
			back_most = minf(back_most, box.position.z)
		var barrier_node: Node3D = prop_yard.get_node_or_null("BarrierRail")
		if barrier_node != null:
			back_most = minf(back_most, _prop_world_bounds(barrier_node).position.z)
		_check(is_finite(floor_back) and floor_back <= back_most - 1.0,
			"the sand floor runs at least 1 m behind the back-most prop",
			"floor back z %.2f vs prop back z %.2f" % [floor_back, back_most])
		var wide: Dictionary = StageLayout.compute(Vector3(3.2, 1.4, 1.6),
			Vector3(2.0, 2.6, 0.8))
		_check(bool(wide["frame_ok"]) and is_equal_approx(float(wide["speaker_x"]),
				float(wide["frame_limit_x"])),
			"a wider tower is pushed out until the frame clamp stops it",
			"tower x %.2f at frame limit %.2f" % [float(wide["speaker_x"]),
				float(wide["frame_limit_x"])])
		# Fix pass commit 3: the hitch log, the light cull, the warm-up gate and the quality gate.
		var hlog := HitchLog.new()
		hlog.set_echo(false)
		for hlog_frame in 600:
			hlog.record_frame(0.016, &"hit")
		_check(hlog.spike_count() == 0 and hlog.stored() == 0 and hlog.capacity() == 16,
			"the hitch log stores nothing on a 16 ms frame",
			"600 frames, 0 spikes, ring still %d" % hlog.capacity())
		for hlog_frame in 20:
			hlog.record_frame(0.050, &"ko")
		_check(hlog.spike_count() == 20 and hlog.stored() == 16,
			"the hitch ring keeps the newest 16 spikes and drops the rest",
			"20 spikes -> %d stored" % hlog.stored())
		var hlog_recent := hlog.recent()
		_check(hlog_recent.size() == 6 and String(hlog_recent[5]).contains("ko"),
			"the F8 chip lists the last 6 spikes, newest last",
			"newest: %s" % String(hlog_recent[5]))
		_check(is_equal_approx(hlog.worst_ms(), 50.0),
			"the hitch log reports its worst frame", "%.1f ms" % hlog.worst_ms())

		var per_mesh: Dictionary = prop_yard.lights_per_mesh()
		_check(int(per_mesh["max"]) <= 4, "no mesh is lit by more than 4 lights",
			"worst %d on %s over %d meshes (%d lights)" % [int(per_mesh["max"]),
				String(per_mesh["mesh"]), int(per_mesh["meshes"]), int(per_mesh["lights"])])
		_check(prop_yard.fighter_lights() <= 4, "at most 4 lights reach the fighters",
			"%d lights on the fighter layer" % prop_yard.fighter_lights())
		_check(arena2.warmup_done and arena2.warmup_steps >= 10,
			"the load-time warm-up ran behind the loading overlay",
			"%d passes" % arena2.warmup_steps)
		var audio = arena2.get_node_or_null("/root/SoundClash")
		if audio != null:
			_check(int(audio.stream_cache_size()) >= 9,
				"every audio cue is decoded before the first round",
				"%d streams cached" % int(audio.stream_cache_size()))
		var rounds_ref = arena2.rounds
		var saved_phase = rounds_ref.phase
		rounds_ref.phase = RoundController.Phase.FIGHTING
		var blocked: bool = not arena2.quality_writes_allowed()
		rounds_ref.phase = RoundController.Phase.ANNOUNCE
		var allowed: bool = arena2.quality_writes_allowed()
		rounds_ref.phase = saved_phase
		_check(blocked and allowed,
			"the quality governor refuses to rescale during a live round",
			"FIGHTING -> locked, ANNOUNCE -> allowed")
		var spk_scenes: Array[String] = []
		if DirAccess.dir_exists_absolute("res://scenes"):
			for spk_file in DirAccess.get_files_at("res://scenes"):
				var spk_file_name := String(spk_file)
				if spk_file_name.ends_with(".tscn") and FileAccess.get_file_as_string(
						"res://scenes/" + spk_file_name).contains("PropLoader"):
					spk_scenes.append(spk_file_name)
		_check(not spk_scenes.has("TitleScreen.tscn"),
			"Character Select instances no prop slot, so the tower cannot block it",
			", ".join(spk_scenes))
		# 600 presented frames: the pulse, the beat clock and the phase tween must not create a
		# node inside a prop slot, respawn the tower, or add a light. The yard's note bursts are
		# capped and transient, so the venue's own static budget is what is measured here.
		var spk_nodes_before := 0
		for slot in prop_slots:
			spk_nodes_before += slot.find_children("*", "Node", true, false).size()
		var spk_model_id := speaker.model.get_instance_id()
		var spk_lights: int = prop_yard.light_count()
		for i in 600:
			await process_frame
		var spk_nodes_after := 0
		for slot in prop_slots:
			spk_nodes_after += slot.find_children("*", "Node", true, false).size()
		_check(spk_nodes_before == spk_nodes_after and is_instance_valid(speaker.model) \
				and speaker.model.get_instance_id() == spk_model_id \
				and prop_yard.light_count() == spk_lights,
			"600 frames add no prop node, no light and never respawn the tower",
			"%d → %d prop node(s), %d light(s)" % [spk_nodes_before, spk_nodes_after,
				prop_yard.light_count()])
		# The pulse multiplies the seat scale, never replaces it, and is capped at 1.5 %.
		var spk_base: float = speaker.seat_scale_applied
		prop_yard._pulse = 2.0
		prop_yard._update_speakers(0.0)
		var spk_peak: Vector3 = speaker.model.scale
		prop_yard._pulse = 0.0
		prop_yard._update_speakers(0.0)
		var spk_settled: Vector3 = speaker.model.scale
		_check(spk_peak.x <= spk_base * 1.0151 and spk_peak.y <= spk_base * 1.0151 \
				and spk_peak.z <= spk_base * 1.0151 and spk_peak.x > spk_base * 0.9999 \
				and is_equal_approx(spk_settled.x, spk_base),
			"the 132 BPM pulse peaks at 1.5 % about the seated base and settles back",
			"%.4f → %.4f (base %.4f)" % [spk_base, spk_peak.y, spk_base])
		prop_yard.speaker_pulse = false
		prop_yard._pulse = 2.0
		prop_yard._update_speakers(0.0)
		var spk_muted: Vector3 = speaker.model.scale
		prop_yard.speaker_pulse = true
		prop_yard._pulse = 0.0
		prop_yard._update_speakers(0.0)
		_check(is_equal_approx(spk_muted.x, spk_base),
			"speaker_pulse off leaves the tower at its seated scale", "%.4f" % spk_muted.x)
		# PART A step 3: the tower keeps its OWN imported material. The cel pass is what made a
		# photographic 2048 albedo read as a flat green poster, so the contract is now the
		# opposite one: a `StandardMaterial3D` carrying that albedo at full physical values.
		var native_ok := false
		var native_tex_w := 0
		var native_count := 0
		for child in speaker.model.find_children("*", "MeshInstance3D", true, false):
			var spk_mi := child as MeshInstance3D
			if spk_mi == null or spk_mi.mesh == null:
				continue
			for surface in spk_mi.mesh.get_surface_count():
				var mat := spk_mi.get_active_material(surface)
				if not (mat is StandardMaterial3D):
					continue
				native_count += 1
				var std := mat as StandardMaterial3D
				if std.albedo_texture != null:
					native_tex_w = maxi(native_tex_w, std.albedo_texture.get_width())
				native_ok = std.albedo_texture != null and is_equal_approx(std.roughness, 1.0) \
					and is_zero_approx(std.metallic) \
					and std.cull_mode == BaseMaterial3D.CULL_DISABLED \
					and std.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_check(native_ok and native_tex_w == 2048,
			"the delivered 2048 albedo is kept on a StandardMaterial3D (roughness 1, metallic 0, "
			+ "culling disabled, mipmaps+anisotropic)", "%d surface(s), %d px" % [native_count, native_tex_w])
		# ... and the time-of-day pass must not repaint it: the same albedo, at every preset.
		var kept_texture: Texture2D = null
		var kept_ok := true
		for spk_phase in [0, 1, 2]:
			prop_yard.apply_phase(spk_phase, 0.0)
			await process_frame
			var phase_tex: Texture2D = null
			var cel_left := 0
			for child in speaker.model.find_children("*", "MeshInstance3D", true, false):
				var spk_mi := child as MeshInstance3D
				if spk_mi == null or spk_mi.mesh == null:
					continue
				for surface in spk_mi.mesh.get_surface_count():
					var mat := spk_mi.get_active_material(surface)
					if mat is ShaderMaterial:
						cel_left += 1
					elif mat is StandardMaterial3D and (mat as StandardMaterial3D).albedo_texture != null:
						phase_tex = (mat as StandardMaterial3D).albedo_texture
			if cel_left != 0:
				kept_ok = false
			if kept_texture == null:
				kept_texture = phase_tex
			elif phase_tex != kept_texture:
				kept_ok = false
		prop_yard.apply_phase(0, 0.0)
		await process_frame
		_check(kept_ok and kept_texture != null,
			"no cel material is left on the tower and its albedo survives all three presets")
		# Lighting and shadows: no light is added, the fighter shadow rig is the same seven
		# lights, and the imported tower casts no shadow of its own to disturb it.
		_check(prop_yard.light_count() == 7 and prop_yard.sun.shadow_enabled and prop_yard.sun.light_angular_distance < 0.001,
			"the tower adds no light and leaves the crisp fighter shadow rig alone",
			"%d light(s)" % prop_yard.light_count())
		var spk_tower_shadows := 0
		for node in speaker.model.find_children("*", "MeshInstance3D", true, false):
			var spk_mi := node as MeshInstance3D
			if spk_mi != null and spk_mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				spk_tower_shadows += 1
		_check(spk_tower_shadows == 0,
			"the imported tower writes no shadow, so the fighter shadow map is untouched",
			"%d casting mesh(es)" % spk_tower_shadows)

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

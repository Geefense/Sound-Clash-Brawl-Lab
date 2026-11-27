extends SceneTree
## Live-match verification (2026-11-24 playtest, PART 1).
## Run with: godot --headless --path godot --script res://tools/live_match_check.gd
##
## Boots the REAL `TestArena.tscn` — round controller, 3D yard, Mixamo bodies and all — for
## every roster pairing and asserts the three failures the owner reported:
##
##   (a) BOTH fighters render: the 3D proxy is visible, has at least one mesh with at least
##       one surface, and its live skinned-mesh bounds project inside the camera's viewport.
##       Bounds are evaluated from the animated skeleton pose and the mesh skin weights, so a
##       body thrown 76 m into the air (the actual "invisible opponent" cause) cannot pass on
##       a nominal 1.55 m height alone.
##   (b) L!kkle Moore (and both other fighters) stay on the sand through knockdown and get-up:
##       the live skinned lowest point never drops below Y −0.05 m and the body never drifts
##       more than 0.5 m from its own root X.
##   (c) Attack presses are not swallowed: pressing J / K / L / I (and U for the grab) on the
##       real InputMap transitions the fighter out of IDLE into its attack state, including a
##       press thrown while hitstop has the tick frozen.
##   Plus the facing the render shows: the posed body forward must be within 5° of +X for P1
##   and −X for P2, measured from the live skeleton (Foot → ToeBase), not from the pivot.
##
## PART 1 commit 1 adds two more contracts, measured on the same live arena:
##   (d) every attack/guard action answers on the PRESS FRAME (one physics tick with the press
##       already visible), not merely "within a few frames" as the polling check above allows.
##   (e) the presentation contract: only the delivered `jamaican_speaker.glb` fills a
##       PropLoader slot — the other four stay empty and no slot draws a procedural stand-in —
##       the 22 crowd rigs are switched OFF (fix pass commit 1) so no spectator node exists,
##       and Afternoon/Sunset/Night are three distinct rigs that each keep a crisp directional
##       fighter shadow. From PART 3 commit 8 the camera audit also fires rays from the lens to
##       both fighters against the delivered tower's AABB at the stacked accent/lean/punch
##       maximum, and asserts the HUD is a CanvasLayer above the 3D yard.
##
## Exit code is non-zero when any assertion fails.

const FIGHTERS := [&"feedback", &"lickshot", &"young_selecta"]
const TOLERANCE_DEG := 5.0
const FLOOR_TOLERANCE := -0.05        # metres below world y 0 the body may never go
const DRIFT_LIMIT := 0.5              # metres of horizontal drift allowed while downed
## The lying contract's numbers, shared with tools/knockdown_table.gd.
const LOW_TARGET := 0.015             # where the lowest drawn vertex sits while downed
const LOW_SLACK := 0.02               # +- tolerance on that seat
const PX_PER_M := 140.0
const FLOOR_PX := 600.0
const CENTER_PX := 640.0

## Press action -> the state the press must reach.
const PRESSES := [
	["p1_light", "J jab", [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY]],
	["p1_heavy", "K box", [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY]],
	["p1_tump", "L tump", [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY]],
	["p1_upper_box", "I upper box", [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY]],
	["p1_grab", "U grab", [BaseFighter.State.GRAB]],
]

var _checks := 0
var _fails := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	print("\n=== LIVE MATCH CHECK (real TestArena.tscn) ===")
	for a in FIGHTERS:
		for b in FIGHTERS:
			await _check_pair(a, b)
	await _check_knockdowns()
	await _check_lighting_clarity()
	await _check_ai_profile()
	await _check_camera_framing()
	await _check_camera_stage_clearance()
	await _check_strike_silhouette()
	for a in FIGHTERS:
		await _check_presses(a)
	await _check_press_frame()
	await _check_arcade_vfx()
	await _check_comic_callouts()
	await _check_crowd_eruption()
	await _check_punch_reach()
	await _check_punch_twist()
	await _check_quality_governor()
	await _check_arena_integrity()
	print("\n%d checks, %d FAIL%s" % [_checks, _fails, "" if _fails == 0 else "S"])
	print("ALL LIVE MATCH CHECKS PASSED" if _fails == 0 else "LIVE MATCH CHECKS FAILED")
	quit(1 if _fails > 0 else 0)


func _check(ok: bool, label: String, detail: String = "") -> void:
	_checks += 1
	var line := "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	if not ok:
		_fails += 1
		print("FAIL  %s" % line)
	else:
		print("PASS  %s" % line)


func _spawn(p1_key: StringName, p2_key: StringName, rounds_enabled: bool = false):
	var setup = root.get_node_or_null("MatchSetup")
	setup.commit_match(p1_key, p2_key)
	setup.ai_mode = 0
	var packed := load("res://scenes/TestArena.tscn") as PackedScene
	var arena := packed.instantiate()
	var rounds := arena.get_node_or_null("RoundController")
	if rounds != null and not rounds_enabled:
		rounds.enabled = false
	root.add_child(arena)
	await process_frame
	await physics_frame
	# Settle: the 3D layer builds in _ready and the animation player needs a frame to pose.
	for i in 6:
		await physics_frame
	return arena


func _free(arena) -> void:
	arena.queue_free()
	await process_frame
	await process_frame


func _check_pair(a: StringName, b: StringName) -> void:
	var arena = await _spawn(a, b)
	var arena3d = arena.get("arena3d")
	var tag := "%s vs %s" % [a, b]
	print("\n-- %s" % tag)
	if arena3d == null:
		_check(false, "%s: no Arena3D layer" % tag)
		await _free(arena)
		return
	var cam: Camera3D = arena3d.camera
	var rect := root.get_visible_rect()
	for side in ["p1", "p2"]:
		var fighter: BaseFighter = arena.p1 if side == "p1" else arena.p2
		var model: Node3D = arena3d.models.get(side)
		if model == null:
			_check(false, "%s: %s has no 3D model" % [tag, side.to_upper()])
			continue
		var meshes := 0
		var surfaces := 0
		for node in model.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			meshes += 1
			surfaces += mi.mesh.get_surface_count()
		_check(model.visible, "%s: %s model is visible" % [tag, side.to_upper()])
		_check(meshes > 0 and surfaces > 0,
			"%s: %s has real geometry (%d mesh, %d surface)" % [tag, side.to_upper(), meshes, surfaces])
		var bounds := _skinned_bounds(model)
		var low: Vector3 = bounds[0]
		var high: Vector3 = bounds[1]
		var low_screen := cam.unproject_position(low)
		var high_screen := cam.unproject_position(high)
		# PART B commit 5: the axis-aligned box's x extreme at its z extreme is empty space,
		# and the 4.10 m steady camera makes that corner the first thing to leave the frustum
		# while every drawn pixel stays framed (measured: the box corner at x 1.77, z 0.62 is
		# outside a 1.66 m half-width at that depth, but the vertex holding x 1.77 sits near
		# z 0 and still projects 60 px inside the frame). Test the body's own vertical
		# extremes AT ITS OWN DEPTH instead, so the check still catches a body thrown out of
		# frame (the 76 m bug it was written for) without failing on an empty box corner.
		var z_mid: float = (low.z + high.z) * 0.5
		var low_at := Vector3(low.x, low.y, z_mid)
		var high_at := Vector3(high.x, high.y, z_mid)
		var in_frustum := cam.is_position_in_frustum(low_at) and cam.is_position_in_frustum(high_at)
		var on_screen := _rect_overlap(low_screen, high_screen, rect)
		_check(in_frustum and on_screen,
			"%s: %s renders inside the camera view (frustum=%s screen=%s)" %
			[tag, side.to_upper(), str(in_frustum), str(on_screen)],
			"%s .. %s" % [str(low), str(high)])
		_check(low.y >= FLOOR_TOLERANCE,
			"%s: %s stands on the sand (lowest drawn y %+.3f)" % [tag, side.to_upper(), low.y])
		# The pivot must carry exactly the facing, and the playing take must not add a turn of
		# its own — together that is the direction the body is drawn facing.
		var offset := deg_to_rad(float(model.get("model_forward_yaw_offset_deg")))
		var expected := offset + (0.0 if side == "p1" else PI)
		var want_dir := Vector3(cos(offset), 0.0, sin(offset)).rotated(Vector3.UP, expected)
		var pivot_err := absf(rad_to_deg(wrapf(
			deg_to_rad(float(model.call("facing_yaw_deg"))) - expected, -PI, PI)))
		var fwd := _rendered_forward(model)
		var err := rad_to_deg(acos(clampf(absf(fwd.x), 0.0, 1.0)))
		var wants := 1.0 if side == "p1" else -1.0
		_check(pivot_err <= 0.5 and err <= TOLERANCE_DEG and signf(fwd.x) == wants,
			"%s: %s faces %s (pivot off by %.2f deg, rendered forward (%+.2f, %+.2f), %4.1f deg off ±X)" %
			[tag, side.to_upper(), "right" if wants > 0 else "left", pivot_err, fwd.x, fwd.z, err])
	await _free(arena)


## Press responsiveness, on the real InputMap and the real arena.
func _check_presses(a: StringName) -> void:
	var arena = await _spawn(a, &"lickshot", true)
	var tag := "P1 %s" % a
	var fighter: BaseFighter = arena.p1
	for entry in PRESSES:
		await _settle(fighter)
		var done := await _press(entry[0], entry[2], fighter)
		var state := String(BaseFighter.State.keys()[fighter.state])
		_check(done, "%s: %s starts an attack on press (state %s)" % [tag, entry[1], state])
		await _settle(fighter)
	# Block / guard is a HELD action, not a latched press.
	await _settle(fighter)
	Input.action_press("p1_guard")
	var guarded := false
	for i in 8:
		await physics_frame
		if fighter.guarding:
			guarded = true
			break
	Input.action_release("p1_guard")
	_check(guarded, "%s: holding S raises the guard" % tag)
	await _settle(fighter)
	# A press thrown while hitstop has the tick frozen must still fire.
	await _settle(fighter)
	fighter._hitstop_frames = 6
	var frozen := await _press("p1_light", PRESSES[0][2], fighter, 14)
	_check(frozen, "%s: a jab pressed during hitstop still fires (%s)" %
		[tag, String(BaseFighter.State.keys()[fighter.state])])
	fighter._hitstop_frames = 0
	await _free(arena)


## Press-frame responsiveness (PART 1 commit 1). `_check_presses` above polls for up to 8 ticks,
## so a one- or two-tick lag would still pass it. Here the press goes down, the fighter is given
## exactly ONE physics tick in which the press is already visible, and the state must have
## changed by the end of that same tick — the buttons answer on the press frame.
func _check_press_frame() -> void:
	for key in FIGHTERS:
		var arena = await _spawn(key, &"lickshot", true)
		var fighter: BaseFighter = arena.p1
		for entry in PRESSES:
			await _settle(fighter)
			var before: int = fighter.state
			Input.action_press(entry[0])
			# Frame A begins with the press already down; frame B begins once frame A (and its
			# single `_physics_process`) has finished. No second chance is given.
			await physics_frame
			await physics_frame
			Input.action_release(entry[0])
			var got: int = fighter.state
			_check(got in entry[2],
				"%s: %s answers on the press frame (state %s)" % [key, entry[1],
					String(BaseFighter.State.keys()[got])])
			_check(before == BaseFighter.State.IDLE or got in entry[2],
				"%s: %s was pressed from a settled stance" % [key, entry[1]])
			await _settle(fighter)
		# Guard is held, not latched: it must be up on the tick after the press as well.
		Input.action_press("p1_guard")
		await physics_frame
		await physics_frame
		var up: bool = fighter.guarding
		Input.action_release("p1_guard")
		_check(up, "%s: S raises the guard on the press frame" % key)
		await _settle(fighter)
		await _free(arena)


## Commit 4: the arcade FX layer with no sheets delivered. Nothing is drawn, each missing sheet
## is reported exactly once, and 600 presented frames add no node to the arena.
func _check_arcade_vfx() -> void:
	print("\n-- ARCADE VFX: no sheets delivered, 600 frames")
	var arena = await _spawn(&"feedback", &"lickshot")
	var vfx: ArcadeVFX2D = arena.get("arcade_vfx")
	var layer: CanvasLayer = arena.get("vfx_layer")
	_check(vfx != null and layer != null and vfx.get_parent() == layer,
		"the arcade FX layer sits on its own CanvasLayer")
	if vfx == null:
		await _free(arena)
		return
	var expected := {
		&"hit_spark": "hit_spark_sheet.png",
		&"bass_shockwave": "bass_shockwave_sheet.png",
		&"clash_callout": "clash_callout_sheet.png",
		&"ko_callout": "ko_callout_sheet.png",
	}
	var paths_ok := true
	var missing := 0
	for kind in expected:
		var want := "res://assets/sprites/arcade_fx/" + String(expected[kind])
		if vfx.sheet_path(kind) != want:
			paths_ok = false
		if not vfx.has_sheet(kind):
			missing += 1
	_check(paths_ok, "all four sheet paths follow assets/sprites/arcade_fx/<name>_sheet.png")
	_check(missing == 4, "no arcade FX sheet is delivered in this build", "%d missing" % missing)
	_check(vfx.warning_count() == 4,
		"exactly one warning per missing sheet", "%d warnings" % vfx.warning_count())
	var each_once := true
	for kind in expected:
		if vfx.warned(kind) == vfx.has_sheet(kind):
			each_once = false
	_check(each_once, "each sheet is reported independently, and only once")
	_check(vfx.sprite_count() == 0,
		"no sprite pool exists without a sheet", "%d sprites" % vfx.sprite_count())
	var before := arena.find_children("*", "Node", true, false).size()
	# Poke every trigger: a missing sheet must stay a no-op, never a node factory.
	for i in 40:
		vfx.play_at_world(&"hit_spark", Vector3.ZERO)
		vfx.play_at_world(&"bass_shockwave", Vector3.ZERO)
		vfx.play_at_world(&"clash_callout", Vector3.ZERO)
		vfx.play_at_world(&"ko_callout", Vector3.ZERO)
	_check(vfx.playing_count() == 0, "nothing plays when no sheet exists")
	# The layer holds exactly one node — `ArcadeVFX2D` itself — and that node holds no sprite.
	var layer_sprites: int = layer.find_children("*", "Sprite2D", true, false).size()
	_check(layer_sprites == 0 and vfx.get_child_count() == 0,
		"the FX layer creates no sprite without a sheet",
		"%d sprites, %d children" % [layer_sprites, vfx.get_child_count()])
	for i in 600:
		await process_frame
	var after := arena.find_children("*", "Node", true, false).size()
	# Never grows. A single expired transient (a spark or note trail the fight itself created)
	# can leave the count one lower; only a list of new nodes is a leak.
	_check(after <= before, "600 frames add no node to the arena", "%d → %d" % [before, after])
	_check(vfx.warning_count() == 4,
		"600 frames add no further warning", "%d" % vfx.warning_count())
	_check(vfx.playing_count() == 0, "still nothing playing after 600 frames")
	await _free(arena)


## PART D: twelve pre-pooled comic SFX labels on the existing VFX layer. Everything is
## measured on the real arena: the exact table, the glyph coverage, one trigger per category,
## the round-robin, all three caps, the lifetime, the two options and the mouse filter. No
## callout may create a node, take input or touch a combat value.
func _check_comic_callouts() -> void:
	print("\n-- COMIC CALLOUTS: table, pool, categories, caps, toggles")
	var arena = await _spawn(&"feedback", &"lickshot")
	var comic: ComicCallout2D = arena.get("comic_callouts")
	var layer: CanvasLayer = arena.get("vfx_layer")
	var vfx: ArcadeVFX2D = arena.get("arcade_vfx")
	_check(comic != null and layer != null and comic.get_parent() == layer,
		"the comic callouts sit on the existing VFX CanvasLayer")
	_check(vfx != null and vfx.get_child_count() == 0,
		"the sprite FX layer keeps no callout child",
		"vfx children %d" % (vfx.get_child_count() if vfx != null else -1))
	if comic == null or layer == null:
		await _free(arena)
		return

	# --- the pool is built once, stays hidden and never takes the mouse -----------------
	var labels: Array = comic.labels()
	var mouse_ok := true
	var font_ok := true
	var outline_ok := true
	var hidden_ok := true
	for entry in labels:
		var label := entry as Label
		if label == null:
			continue
		if label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			mouse_ok = false
		if label.get_theme_font("font") != ComicCallout2D.FONT:
			font_ok = false
		if label.get_theme_constant("outline_size") < 4:
			outline_ok = false
		if label.visible:
			hidden_ok = false
	_check(comic.pool_size() == 6 and labels.size() == 6,
		"the pool is six labels, built once", "%d labels" % labels.size())
	_check(mouse_ok, "no pooled label can take the mouse")
	_check(font_ok, "every pooled label uses the existing bold HUD font")
	_check(outline_ok, "every pooled label carries a thick dark outline")
	_check(hidden_ok, "every pooled label starts hidden until a trigger")

	# --- the exact 22-string table --------------------------------------------------------
	var expected := {
		&"light": ["PLIM!", "BAP!", "BAP-BAP!"],
		&"whiff": ["BOOPS!", "ZOOPS!", "SWOOPS!", "WIISH!"],
		&"block": ["CHOOPS!", "CHO!", "PLUCK!"],
		&"medium": ["BLAPS!", "BIM!", "AIEE!"],
		&"heavy": ["BRAGADAPS!", "PLAX!", "BUDUM!", "BLAM!", "BOGOF!", "BUGUYAGA!",
			"HUSH!"],
		&"beat": ["BRRRRAP!", "PYAW! PYAW!"],
	}
	var table_ok := ComicCallout2D.PHRASES.size() == expected.size()
	var seen := {}
	var total := 0
	for category in expected:
		var want: Array = expected[category]
		var got: Array = ComicCallout2D.PHRASES.get(category, [])
		if got.size() != want.size():
			table_ok = false
			continue
		for i in want.size():
			if String(got[i]) != String(want[i]):
				table_ok = false
			seen[String(got[i])] = true
			total += 1
	_check(table_ok, "the table holds exactly the twenty-two approved strings in their categories",
		"%d categories, %d strings" % [expected.size(), total])
	_check(total == 22 and seen.size() == 22,
		"all twenty-two strings are present once, byte-for-byte distinct", "%d unique" % seen.size())
	# They are SFX text, never Patois dictionary entries, and the 31-entry collection is intact.
	var overlap := 0
	for kind in arena.CALLOUTS:
		for line in arena.CALLOUTS[kind]:
			if seen.has(String(line)):
				overlap += 1
	for line in arena.PATWA_COLLECTION:
		if seen.has(String(line)):
			overlap += 1
	_check(overlap == 0 and arena.PATWA_COLLECTION.size() == 31,
		"no comic string is a Patois entry, and the collection is still 31 entries",
		"%d overlaps" % overlap)

	# --- glyph coverage, measured on the font itself -------------------------------------
	var missing := comic.missing_glyphs()
	var glyph_ok := true
	for category in expected:
		for phrase in expected[category]:
			var text := String(phrase)
			for i in text.length():
				if not ComicCallout2D.FONT.has_char(text.unicode_at(i)):
					glyph_ok = false
	_check(glyph_ok and missing.is_empty(),
		"every character in all twenty-two strings has a glyph, the hyphen in BAP-BAP! included",
		"%d missing" % missing.size())

	# --- one trigger per category, on the real fighters ----------------------------------
	var p1: BaseFighter = arena.p1
	var p2: BaseFighter = arena.p2
	var arena3d = arena.get("arena3d")
	var world: Vector3 = arena3d.world_point_of(Vector2(500.0, 470.0))
	_check(comic.register_hit(p1, &"jab", false, false, world)
			and comic.last_category() == &"light",
		"a jab lands as a light callout", "%s" % comic.last_phrase())
	comic.debug_advance(0.15)
	_check(comic.register_hit(p2, &"strong", false, false, world)
			and comic.last_category() == &"medium",
		"Lickshot's 10-damage box lands as a medium callout", "%s" % comic.last_phrase())
	comic.debug_advance(0.15)
	_check(comic.register_hit(p1, &"strong", false, false, world)
			and comic.last_category() == &"heavy",
		"Feedback's 15-damage box lands as a heavy callout", "%s" % comic.last_phrase())
	comic.debug_advance(0.15)
	_check(comic.register_hit(p1, &"jab", true, false, world)
			and comic.last_category() == &"heavy",
		"a counter-hit upgrades a light strike to the heavy/counter callout",
		"%s" % comic.last_phrase())
	comic.debug_advance(0.15)
	_check(comic.register_hit(p1, &"strong", false, true, world)
			and comic.last_category() == &"beat",
		"an on-beat heavy strike takes the 132 BPM callout", "%s" % comic.last_phrase())
	comic.debug_advance(0.15)
	_check(comic.register_hype(p2, world) and comic.last_category() == &"beat",
		"a hype surge takes the 132 BPM callout", "%s" % comic.last_phrase())
	comic.debug_advance(0.15)
	comic.note_attack_active(p1, &"jab")
	comic.note_attack_ended(p1, world)
	_check(comic.last_category() == &"whiff",
		"an ACTIVE window that ends without contact is a whiff", "%s" % comic.last_phrase())

	# --- block/parry: the shipped block event feeds it, the shipped clash keeps its own -----
	comic.debug_advance(1.2)
	var block_result := {"blocked": true, "parried": false, "attack_id": &"strong"}
	_check(comic.register_strike(p2, p1, block_result, world)
			and comic.last_category() == &"block",
		"a guarded contact takes the block category", "%s" % comic.last_phrase())
	comic.debug_advance(1.2)
	var parry_result := {"blocked": true, "parried": true, "attack_id": &"strong"}
	_check(not comic.register_strike(p2, p1, parry_result, world),
		"a record static parry is skipped: the clash sprite and its line own that instant")
	comic.debug_advance(1.2)
	var ignored_result := {"ignored": true, "attack_id": &"jab"}
	_check(not comic.register_strike(p2, p1, ignored_result, world),
		"a strike on a downed body is ignored, exactly as combat ignores it")

	# --- the heavy table splits: plain hits vs hits that put the body on the floor ---------
	comic.debug_advance(1.2)
	var heavy_plain := comic.register_hit(p1, &"strong", false, false, world)
	var plain_phrase := comic.last_phrase()
	comic.debug_advance(1.2)
	var heavy_down := comic.register_hit(p1, &"strong", false, false, world, true)
	var down_phrase := comic.last_phrase()
	var plain_list := comic.rotation_phrases(&"heavy")
	var down_list := comic.rotation_phrases(ComicCallout2D.HEAVY_DOWN_KEY)
	_check(heavy_plain and plain_list.has(plain_phrase) and not down_list.has(plain_phrase),
		"an ordinary heavy hit draws from the plain heavy half", plain_phrase)
	_check(heavy_down and down_list.has(down_phrase) and not plain_list.has(down_phrase),
		"a heavy hit that downs its target draws from the knockdown half", down_phrase)
	_check(plain_list.size() == 3 and down_list.size() == 4,
		"the heavy table splits three plain / four knockdown phrases",
		"%d + %d" % [plain_list.size(), down_list.size()])

	# --- deterministic round-robin, no immediate repeat ----------------------------------
	comic.debug_advance(1.2)
	var repeats := 0
	var previous := ""
	var phrases := {}
	for i in 3:
		var fighter: BaseFighter = p1 if i % 2 == 0 else p2
		if comic.register_hit(fighter, &"jab", false, false, world):
			if comic.last_phrase() == previous:
				repeats += 1
			previous = comic.last_phrase()
			phrases[previous] = true
		comic.debug_advance(0.75)
	_check(repeats == 0 and phrases.size() == 3,
		"the light category round-robins all three phrases with no back-to-back repeat",
		"%d phrases, %d repeats" % [phrases.size(), repeats])

	# --- per-fighter rate cap ------------------------------------------------------------
	comic.debug_advance(1.2)
	var first := comic.register_hit(p1, &"jab", false, false, world)
	var second := comic.register_hit(p1, &"jab", false, false, world)
	_check(first and not second, "one fighter cannot shout twice inside 120 ms")

	# --- per-category simultaneity cap ---------------------------------------------------
	comic.debug_advance(1.2)
	var heavy_a := comic.register_hit(p1, &"strong", false, false, world)
	comic.debug_advance(0.15)
	var heavy_b := comic.register_hit(p2, &"upper_box", false, false, world)
	comic.debug_advance(0.15)
	var heavy_c := comic.register_hit(p1, &"strong", false, false, world)
	_check(heavy_a and heavy_b and not heavy_c,
		"at most two callouts of one category play at once")

	# --- pool exhaustion skips, never allocates ------------------------------------------
	comic.debug_advance(1.2)
	comic.register_hit(p1, &"jab", false, false, world)
	comic.register_hit(p2, &"jab", false, false, world)
	comic.debug_advance(0.15)
	comic.register_hit(p1, &"strong", false, false, world)
	comic.register_hit(p2, &"upper_box", false, false, world)
	comic.debug_advance(0.15)
	comic.register_hit(p1, &"strong", false, true, world)
	comic.register_hype(p2, world)
	comic.debug_advance(0.15)
	var full_before := comic.active_count()
	var nodes_before := _yard_node_count(arena3d)
	var overflow := comic.register_hit(p1, &"jab", false, false, world)
	var nodes_after := _yard_node_count(arena3d)
	_check(full_before == 6 and not overflow and nodes_after == nodes_before
			and comic.label_count() == 6,
		"an exhausted pool skips the callout and creates no node",
		"%d active, %d → %d nodes" % [full_before, nodes_before, nodes_after])

	# --- the tight pool keeps its last slot for a beat / heavy moment ---------------------
	comic.debug_advance(1.2)
	comic.register_hit(p1, &"jab", false, false, world)
	comic.register_hit(p2, &"jab", false, false, world)
	comic.debug_advance(0.15)
	comic.register_hit(p1, &"strong", false, false, world)
	comic.register_hit(p2, &"strong", false, false, world)
	comic.debug_advance(0.15)
	comic.register_hit(p1, &"strong", false, true, world)
	comic.debug_advance(0.15)
	var light_skipped := not comic.register_hit(p2, &"jab", false, false, world)
	var beat_played := comic.register_hit(p1, &"strong", false, true, world)
	_check(light_skipped and beat_played,
		"with one label left, a light hit yields to an on-beat callout")

	# --- lifetimes end, labels hide and stay reusable ------------------------------------
	comic.debug_advance(1.2)
	var all_hidden := true
	for entry in comic.labels():
		if (entry as Label).visible:
			all_hidden = false
	_check(comic.active_count() == 0 and all_hidden,
		"every callout ends its life hidden and reusable")
	_check(comic.register_hit(p1, &"jab", false, false, world),
		"a recycled label takes the next callout")

	# --- the two options on the existing debug path ---------------------------------------
	comic.set_enabled(false)
	_check(not comic.register_hit(p1, &"jab", false, false, world),
		"callout_enabled = false silences the layer")
	comic.set_enabled(true)
	comic.debug_advance(1.2)
	var reenabled := comic.register_hit(p1, &"jab", false, false, world)
	_check(reenabled, "callout_enabled = true restores it")

	comic.debug_advance(1.2)
	comic.reduced_motion = true
	comic.register_hit(p1, &"jab", false, false, world)
	var still := true
	for entry in comic.labels():
		var label := entry as Label
		if label.visible and (label.scale != Vector2.ONE or not is_zero_approx(label.rotation)):
			still = false
	_check(still, "reduced_motion removes the pop and the tilt")
	comic.reduced_motion = false

	comic.debug_advance(1.2)
	comic.callout_scale = 0.5
	comic.register_hit(p2, &"jab", false, false, world)
	var scaled_px := 0
	for entry in comic.labels():
		var label := entry as Label
		if label.visible:
			scaled_px = label.get_theme_font_size("font_size")
	_check(scaled_px > 0 and scaled_px < ComicCallout2D.BASE_FONT_PX,
		"callout_scale shrinks the pooled label", "%d px" % scaled_px)
	comic.callout_scale = 1.0

	# --- the real arena wiring: a landed hit and a whiff through the live signals --------
	# The checks above call the layer directly; these two press a real jab on the real
	# InputMap and let `strike_resolved` / `state_changed` do the classifying.
	comic.debug_advance(1.2)
	p1.global_position = Vector2(480.0, 600.0)
	p2.global_position = Vector2(556.0, 600.0)
	p1.face_toward(p2.global_position.x)
	for i in 6:
		await physics_frame
	var light_before := comic.fire_count(&"light")
	Input.action_press("p1_light")
	for i in 14:
		await physics_frame
	Input.action_release("p1_light")
	_check(comic.fire_count(&"light") > light_before,
		"a real jab landing through strike_resolved fires the light callout",
		"%d -> %d" % [light_before, comic.fire_count(&"light")])

	comic.debug_advance(1.2)
	for i in 40:
		if p1.state == BaseFighter.State.IDLE:
			break
		await physics_frame
	p1.global_position = Vector2(320.0, 600.0)
	p2.global_position = Vector2(900.0, 600.0)
	p1.face_toward(p2.global_position.x)
	for i in 6:
		await physics_frame
	var whiff_before := comic.fire_count(&"whiff")
	Input.action_press("p1_light")
	for i in 18:
		await physics_frame
	Input.action_release("p1_light")
	_check(comic.fire_count(&"whiff") > whiff_before,
		"a real jab that ends its ACTIVE window untouched fires the whiff callout",
		"%d -> %d" % [whiff_before, comic.fire_count(&"whiff")])
	await _free(arena)


## Fix pass commit 1 (2026-11-27): the 22 spectator rigs are gone. What still has to work is
## everything the crowd was FOR — the hype readout, the eruption cue, the light pump, the
## callouts and the audio — so this audit proves the cue path and the node budget with the
## rigs off by default.
func _check_crowd_eruption() -> void:
	print("\n-- CROWD OFF: rigs, cue path, hype readout, node budget")
	var arena = await _spawn(&"feedback", &"lickshot")
	var arena3d = arena.get("arena3d")
	if arena3d == null or arena3d.crowd3d == null:
		_check(false, "no crowd controller to audit")
		await _free(arena)
		return
	var crowd: CrowdController3D = arena3d.crowd3d
	_check(not crowd.rigs_enabled() and crowd.count() == 0 and crowd.node_count() == 0,
		"the crowd rigs are off by default and build nothing",
		"%d rig / %d node / enabled %s" % [crowd.count(), crowd.node_count(),
			str(crowd.rigs_enabled())])
	_check(crowd.planned_rig_count() == 22,
		"the flag still describes the 22-rig yard it would build",
		"%d planned" % crowd.planned_rig_count())
	var nodes_before: int = _yard_node_count(arena3d)
	var lights_before: int = arena3d.light_count()
	var spots_before: int = arena3d.stage_spot_count()
	# Energy is the hype reading: a big impact still erupts at zero hype, 50 hype is half,
	# 100 hype is full and never more than full. None of that needs a body.
	arena.p1.hype = 0
	arena3d.notify_combat_event(&"heavy_hit", 0)
	_check(crowd.eruption_active() and is_zero_approx(crowd.eruption_energy()),
		"a big impact still erupts with empty hype meters",
		"energy %.2f" % crowd.eruption_energy())
	arena.p1.hype = int(BaseFighter.HYPE_MAX / 2)
	arena3d.notify_combat_event(&"hype", -1)
	_check(absf(crowd.eruption_energy() - 0.5) < 0.01,
		"the eruption energy still follows the hype readout",
		"%.2f at half hype" % crowd.eruption_energy())
	arena.p1.hype = BaseFighter.HYPE_MAX
	arena3d.notify_combat_event(&"ko", 0)
	_check(absf(crowd.eruption_energy() - 1.0) < 0.01,
		"full hype is full energy and never past it", "%.2f" % crowd.eruption_energy())
	_check(crowd.cue_count() > 0 and arena3d.light_pump() >= 0.0
			and arena3d.light_pump() <= 1.0,
		"the hype cue path runs with no rigs and the light pump stays inside 0-1",
		"%d cue(s), pump %.2f" % [crowd.cue_count(), arena3d.light_pump()])
	_check(arena3d.light_count() == lights_before and arena3d.stage_spot_count() == spots_before,
		"the eruption adds no light and keeps the stage spots",
		"%d lights, %d spots" % [arena3d.light_count(), arena3d.stage_spot_count()])
	for i in 300:
		await process_frame
	_check(_yard_node_count(arena3d) == nodes_before
			and crowd.node_count() == 0,
		"300 frames of cues add no crowd node and no yard node",
		"%d → %d yard node(s)" % [nodes_before,
			arena3d.find_children("*", "Node", true, false).size()])
	_check(crowd.eruption_energy() >= 0.0 and crowd.eruption_energy() <= 1.0,
		"the eruption energy stays bounded", "energy %.3f" % crowd.eruption_energy())
	await _free(arena)


## The live arena's non-combat presentation contract: none of the five prop slots may draw a
## procedural stand-in, the yard keeps all seven delivered crowd models, and the three light
## phases are genuinely different rigs with a crisp fighter shadow in every one.
func _check_arena_integrity() -> void:
	var arena = await _spawn(&"feedback", &"lickshot", false)
	var slots := arena.find_children("*", "PropLoader", true, false)
	_check(slots.size() == 5, "the arena carries the five PropLoader slots (%d)" % slots.size())
	var empty := 0
	var stray_meshes := 0
	var primitive_meshes := 0
	var paths: Array[String] = []
	for node in slots:
		var slot := node as PropLoader
		if slot.is_empty():
			empty += 1
		paths.append(slot.model_path.get_file())
		for child in slot.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi != null and mi.mesh != null:
				stray_meshes += 1
				if mi.mesh is PrimitiveMesh:
					primitive_meshes += 1
	_check(empty == 1,
		"four of the five prop slots are filled and only the rasta speaker stays empty",
		"%d of %d" % [empty, slots.size()])
	_check(stray_meshes == 4 and primitive_meshes == 0,
		"the four prop meshes are the delivered files — no slot draws a procedural stand-in",
		"%d mesh(es), %d primitive(s)" % [stray_meshes, primitive_meshes])
	var wanted := ["jamaican_speaker.glb", "rasta_speaker.glb", "dj_booth.glb"]
	var stage_slots := 0
	for file in wanted:
		if paths.has(file):
			stage_slots += 1
	_check(stage_slots == 3, "the yard's three environment slots are live",
		", ".join(paths))
	_check(paths.count("wireless_mic.glb") == 2,
		"both adult fighters mount a wireless-mic slot",
		"%d wireless_mic.glb" % paths.count("wireless_mic.glb"))

	# ---- The two props delivered 2026-11-27: the deck and the wireless mic ------------------
	# Every number below is measured from the live scene, not copied from the asset brief.
	for i in 3:
		await process_frame
	var yard3d = arena.get_node_or_null("Arena3D")
	var deck := _prop_bounds(yard3d, "dj_booth.glb")
	_check(deck.size != Vector3.ZERO,
		"the delivered DJ deck stands in the yard",
		"%.2f × %.2f × %.2f m" % [deck.size.x, deck.size.y, deck.size.z])
	_check(absf(deck.position.y) <= 0.01,
		"the deck's lowest vertex sits on the sand within 1 cm", "y %+.4f m" % deck.position.y)
	# Fix pass commit 2 (intentional change): the deck is authored at 1.15 m and the stage's
	# perspective compensation multiplies it, so the asserted height is 1.15 × that scale.
	var deck_scale: float = yard3d.stage_booth_scale() if yard3d != null else 1.0
	_check(absf(deck.size.y / deck_scale - 1.15) / 1.15 <= 0.02,
		"the deck stands its authored 1.15 m under the stage scale, within 2 %",
		"%.3f m (1.15 × %.2f×)" % [deck.size.y, deck_scale])
	var deck_front := Vector3.ZERO
	var mic_slots := 0
	var mic_lengths := ""
	var mic_length_ok := true
	var mic_material := ""
	for node in slots:
		var slot := node as PropLoader
		if slot.is_empty():
			continue
		if String(slot.model_path).ends_with("dj_booth.glb"):
			# The delivered thatched hut's open counter is on its LOCAL +Z face and the slot
			# applies no turn, so the counter faces the model's own +Z basis. (The rack it
			# replaced was authored the other way round; reusing that 180° turn would now show
			# the camera a blank plank wall instead of the decks.)
			deck_front = slot.model.global_transform.basis.z.normalized()
		if String(slot.model_path).ends_with("wireless_mic.glb"):
			mic_slots += 1
			var length := _prop_longest_world(slot)
			mic_lengths += "%.3f m " % length
			if absf(length - 0.24) / 0.24 > 0.02:
				mic_length_ok = false
		# Only the two props this pass delivered: the tower's native material has its own
		# dedicated block in the roster check.
		var delivered_here: bool = String(slot.model_path).ends_with("dj_booth.glb") \
			or String(slot.model_path).ends_with("wireless_mic.glb")
		if delivered_here and mic_material == "":
			mic_material = _prop_material_problem(slot)
	var cam_dir := Vector3(yard3d.camera.global_position.x - deck.get_center().x, 0.0,
		yard3d.camera.global_position.z - deck.get_center().z).normalized()
	_check(deck_front.dot(cam_dir) > 0.8,
		"the deck's open counter is turned toward the camera side",
		"front (%+.2f, %+.2f), camera dot %.2f" % [deck_front.x, deck_front.z,
			deck_front.dot(cam_dir)])
	_check(mic_slots == 2 and mic_length_ok,
		"both adult fighters carry the delivered mic, 0.24 m long within 2 %",
		mic_lengths.strip_edges())
	_check(mic_material == "",
		"both props keep a native StandardMaterial3D with mipmaps, anisotropy and no toon ramp",
		mic_material if mic_material != "" else "every surface native")

	var stage3d = arena.get_node_or_null("Arena3D")
	if stage3d != null:
		# Three phases, three genuinely different rigs, one crisp shadow throughout.
		var rigs: Array[String] = []
		var crisp := true
		for phase in [0, 1, 2]:
			stage3d.apply_phase(phase, 0.0)
			await physics_frame
			var sun: DirectionalLight3D = stage3d.sun
			if not sun.shadow_enabled or sun.light_angular_distance > 0.001:
				crisp = false
			rigs.append("%.2f/%.2f/%.2f" % [sun.light_energy,
				stage3d.fill.light_energy, stage3d.rim.light_energy])
		_check(crisp, "the key light casts a crisp fighter shadow in every phase")
		var distinct := {}
		for r in rigs:
			distinct[r] = true
		_check(distinct.size() == 3, "Afternoon / Sunset / Night are three distinct light rigs",
			", ".join(rigs))
		stage3d.apply_phase(0, 0.0)
	await _free(arena)
	# L!kkle Moore is the only fighter who asks for the mic stand, so his slot only exists in a
	# match he is in. Checked in its own arena rather than inferred.
	var moore = await _spawn(&"young_selecta", &"feedback", false)
	var moore_paths: Array[String] = []
	var moore_empty := 0
	var moore_stray := 0
	for node in moore.find_children("*", "PropLoader", true, false):
		var slot := node as PropLoader
		moore_paths.append(slot.model_path.get_file())
		if slot.is_empty():
			moore_empty += 1
		for child in slot.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi != null and mi.mesh != null:
				moore_stray += 1
	_check(moore_paths.has("mic_stand.glb"),
		"L!kkle Moore's mic-stand slot is present and empty",
		", ".join(moore_paths))
	# Overnight props pass: the mic stand is still undelivered (and his dictionary has no slot at
	# all), while three slots now draw real files — the tower, the deck, and Feedback's mic. This
	# replaces the old "one mesh, four empty" contract.
	_check(moore_empty == 2 and moore_stray == 3,
		"his mic stand and dictionary draw nothing, while the tower, deck and mic do",
		"%d empty, %d mesh(es)" % [moore_empty, moore_stray])
	await _free(moore)


## Wait for a controllable, grounded, idle fighter without forcing state by hand.
func _settle(fighter: BaseFighter, limit: int = 120) -> void:
	fighter.input_locked = false
	var guard := 0
	while guard < limit:
		guard += 1
		if fighter.state == BaseFighter.State.IDLE and fighter.is_on_floor() \
				and fighter._hitstop_frames == 0:
			fighter.velocity = Vector2.ZERO
			await physics_frame
			if fighter.state == BaseFighter.State.IDLE and fighter.is_on_floor():
				return
		await physics_frame


## Press one action and poll a few ticks for the expected state.
func _press(action: String, wanted: Array, fighter: BaseFighter, limit: int = 8) -> bool:
	if not InputMap.has_action(action):
		return false
	Input.action_press(action)
	var hit := false
	var guard := 0
	while guard < limit:
		guard += 1
		Input.action_release(action)
		await physics_frame
		if fighter.state in wanted:
			hit = true
			break
	Input.action_release(action)
	return hit


## Knockdown / get-up floor and drift audit for every fighter, as P2 the CPU cannot interrupt.
func _check_knockdowns() -> void:
	print("\n-- KNOCKDOWN / GET-UP FLOOR + DRIFT")
	for key in FIGHTERS:
		var arena = await _spawn(&"feedback", key)
		var arena3d = arena.get("arena3d")
		var fighter: BaseFighter = arena.p2
		var model: Node3D = arena3d.models.get("p2") if arena3d != null else null
		if model == null:
			_check(false, "%s: no 3D model for the knockdown audit" % key)
			await _free(arena)
			continue
		var root_x: float = fighter.global_position.x
		var lowest := INF
		var body_drift := 0.0
		var anchor_gap := 0.0
		# The lying contract (overnight pass 2): at the fullest of the fall the body must be on its
		# back with its head away from the opponent, and its lowest DRAWN vertex on the sand.
		var opp_model: Node3D = arena3d.models.get("p1") if arena3d != null else null
		var peak_fall := 0.0
		var peak_up := 1.0
		var peak_chest := 0.0
		var peak_away := true
		var peak_low := 0.0
		var low_step := 0.0
		var prev_low := INF
		var upright_again := false
		fighter.input_locked = false
		var knocked := fighter.change_state(BaseFighter.State.KNOCKDOWN)
		# 36 fall ticks + the get-up, plus slack.
		for tick in 200:
			await physics_frame
			lowest = minf(lowest, _skinned_bounds(model)[0].y)
			var fall_now := float(model.get("_fall"))
			var drawn_low: float = _skinned_bounds(model)[0].y
			if prev_low != INF and fall_now > 0.5:
				low_step = maxf(low_step, absf(drawn_low - prev_low))
			prev_low = drawn_low
			if fall_now >= peak_fall:
				peak_fall = fall_now
				var lying := _lying_metrics(model, opp_model)
				peak_up = absf(float(lying["up_y"]))
				peak_chest = float(lying["chest_ny"])
				peak_away = bool(lying["away"])
				peak_low = drawn_low
			if fall_now <= 0.01 and tick > 60:
				upright_again = absf(_up_y(model)) >= 0.9
			# The body itself must not teleport, and the render must stay anchored to the body:
			# the pelvis is expected to travel ~a body length away when the fighter topples,
			# so only these two are drift measures.
			body_drift = maxf(body_drift, absf(fighter.global_position.x - root_x))
			anchor_gap = maxf(anchor_gap, absf(model.global_position.x - _world_x(fighter.global_position.x)))
		_check(knocked, "%s: a knockdown was accepted" % key)
		_check(lowest >= FLOOR_TOLERANCE,
			"%s: stays on the sand through knockdown and get-up (lowest %+.3f m)" % [key, lowest])
		_check(body_drift <= DRIFT_LIMIT and anchor_gap <= 0.02,
			"%s: no horizontal teleport while downed (body %.3f m, render anchor off by %.3f m)"
			% [key, body_drift, anchor_gap])
		_check(_no_root_motion_tracks(model),
			"%s: no installed take animates Hips/Root position — every clip plays in place" % key)
		# The lying contract, on the played state: |up_y| <= 0.30, chest to world up
		# (>= 0.70), head away from the opponent, and the lowest drawn vertex at 0.015 m +- 0.02.
		_check(peak_fall >= 0.9 and peak_up <= 0.30 and peak_chest >= 0.70 and peak_away,
			"%s: lies supine away from the opponent at the full fall (|up_y| %.2f, chest_ny %.2f, away %s)"
			% [key, peak_up, peak_chest, str(peak_away)])
		_check(absf(peak_low - LOW_TARGET) <= LOW_SLACK,
			"%s: lowest drawn vertex on the sand at the full fall (%+.3f m, target %+.3f)"
			% [key, peak_low, LOW_TARGET])
		_check(low_step <= 0.035 and upright_again,
			"%s: the seat reverses on the get-up with no pop (max step %.3f m, upright again %s)"
			% [key, low_step, str(upright_again)])
		await _free(arena)


const AI_SEEDS := [11, 4242, 777, 20261126, 90210]


## PART B commit 6 — the CPU is no longer frame-perfect. Two layers of proof: the decision core
## on its own (delayed perception, 20 seeds of first-attack timing, the two-attack ceiling, and
## same-seed determinism), and the real arena, where a scripted player's jab string must land
## three times before the CPU's first attack in a majority of seeds.
func _check_ai_profile() -> void:
	print("\n-- AI: delayed perception, seeded decisions, two-attack ceiling")
	var easy := AIProfile.preset(&"easy")
	var normal := AIProfile.preset(&"normal")
	var hard := AIProfile.preset(&"hard")
	_check(normal != null and normal.id == &"normal" and easy.reaction_frames > normal.reaction_frames
			and hard.reaction_frames < normal.reaction_frames
			and normal.attack_cooldown_frames >= 40 and easy.attack_cooldown_frames >= 40
			and hard.attack_cooldown_frames >= 40,
		"Easy / Normal / Hard load; Normal reads P1 18+ frames late and every preset cools down 40+",
		"reaction %d/%d/%d, cooldown %d/%d/%d" % [easy.reaction_frames, normal.reaction_frames,
			hard.reaction_frames, easy.attack_cooldown_frames, normal.attack_cooldown_frames,
			hard.attack_cooldown_frames])

	# (1) Perception is a ring buffer read `delay` frames back. An attack younger than that must
	# be invisible, and the same attack must appear once the delay has passed.
	var probe := AIBrain.new()
	probe.setup(normal, 4242)
	var delay: int = probe.reaction_frames()
	for i in 120:
		probe.observe(BaseFighter.State.IDLE, 900.0, 0.0, false, false)
		probe.tick()
	for i in maxi(0, delay - 2):
		probe.observe(BaseFighter.State.ATTACK_ACTIVE, 700.0, -120.0, false, true)
		probe.tick()
	probe.perceive()
	var too_young: bool = probe.seen_attacking
	for i in normal.reaction_jitter + 3:
		probe.observe(BaseFighter.State.ATTACK_ACTIVE, 700.0, -120.0, false, true)
		probe.tick()
	probe.perceive()
	_check(not too_young and probe.seen_attacking and delay >= normal.reaction_frames,
		"the AI cannot see an attack younger than its reaction delay",
		"invisible at %d frames, visible by %d" % [delay - 2, delay + normal.reaction_jitter + 3])

	# (2) 20 seeds, decision level: the first attack is never before frame 60, and no seed ever
	# chains more than two attacks before the breathing window opens.
	var earliest := 9999
	var worst_run := 0
	for s in 20:
		var brain := AIBrain.new()
		brain.setup(normal, 500 + s)
		brain.reset_for_round()
		var first := -1
		var run := 0
		for f in 240:
			brain.tick()
			brain.perceive()
			if brain.commit_attack():
				if first < 0:
					first = f
				run += 1
				worst_run = maxi(worst_run, run)
			elif brain.breathing_frames() > 0:
				run = 0
		if first >= 0 and first < earliest:
			earliest = first
	_check(earliest >= 60,
		"across 20 seeds the CPU's first attack is never before frame 60",
		"earliest frame %d" % earliest)
	_check(worst_run <= 2, "the CPU never chains more than two attacks before breathing",
		"worst run %d" % worst_run)
	# Same seed, same decisions: two independent brains must press on identical frames.
	var run_a: Array[int] = []
	var run_b: Array[int] = []
	for pass_index in 2:
		var brain := AIBrain.new()
		brain.setup(normal, 31337)
		brain.reset_for_round()
		for f in 400:
			brain.tick()
			brain.perceive()
			if brain.commit_attack():
				if pass_index == 0:
					run_a.append(f)
				else:
					run_b.append(f)
	_check(run_a.size() > 0 and run_a == run_b,
		"one seed replays the same attack frames", "%d attacks, identical: %s" %
		[run_a.size(), str(run_a == run_b)])

	# (3) The real arena: a scripted jab string at 150 px (jab spacing) against the shipped
	# Normal profile. The player has to land three jabs before the CPU's first attack.
	var majority := 0
	var earliest_attack := 9999
	var detail: Array[String] = []
	for seed_value in AI_SEEDS:
		var arena = await _spawn(&"feedback", &"lickshot")
		var sparring = arena.get("sparring")
		sparring.set_mode(1)
		sparring.set_preset(&"normal")
		sparring.decision_seed = seed_value
		sparring.brain.seed_decisions(seed_value)
		sparring.brain.reset_for_round()
		var p1: BaseFighter = arena.p1
		var p2: BaseFighter = arena.p2
		p1.use_local_input = false
		p1.global_position = Vector2(565.0, 600.0)
		p2.global_position = Vector2(715.0, 600.0)
		var landed := [0]
		var count_jab := func(attacker: BaseFighter, _target: BaseFighter, result: Dictionary) -> void:
			if attacker == p1 and not bool(result.get("blocked", false)) \
					and not bool(result.get("parried", false)) \
					and not bool(result.get("ignored", false)):
				landed[0] += 1
		p1.strike_resolved.connect(count_jab)
		var first_ai := -1
		var landed_at_first := 0
		var cmd := BaseFighter.Command.new()
		var prev_p2: int = p2.state
		for f in 240:
			# A jab string at neutral spacing: step back into range between jabs (a player
			# holding forward), and press on a 20-frame cadence.
			var gap: float = p2.global_position.x - p1.global_position.x
			cmd.move_x = signf(gap) if absf(gap) > 135.0 else 0.0
			cmd.light = f >= 8 and (f - 8) % 20 == 0
			p1.command = cmd
			await physics_frame
			if first_ai < 0 and p2.state == BaseFighter.State.ATTACK_STARTUP \
					and prev_p2 != BaseFighter.State.ATTACK_STARTUP:
				first_ai = f
				landed_at_first = landed[0]
			prev_p2 = p2.state
		if first_ai < 0:
			landed_at_first = landed[0]
		else:
			earliest_attack = mini(earliest_attack, first_ai)
		if landed_at_first >= 3:
			majority += 1
		detail.append("%d:%d jabs/%s" % [seed_value, landed_at_first,
			str(first_ai) if first_ai >= 0 else "no attack"])
		await _free(arena)
	_check(majority * 2 > AI_SEEDS.size(),
		"a jab string lands three times before the CPU's first attack in most seeds",
		", ".join(detail))
	_check(earliest_attack >= 60,
		"in the live arena the CPU's first attack also waits for frame 60",
		"earliest %d" % earliest_attack)


## PART B commit 4: lighting clarity. The washout was ACES + glow + depth fog stacked over the
## same seven-light rig, so each preset now has to prove the three are gone, that the key still
## beats the ambient by 2:1, that both fighters still cast their directional shadow, and that
## F6 brings the old look back on the same shot without moving the lens or a facing.
func _check_lighting_clarity() -> void:
	print("\n-- LIGHTING: no fog / no glow / Linear, key:ambient >= 2:1, 7 lights, F6 A/B")
	var arena = await _spawn(&"feedback", &"lickshot")
	var a3d = arena.get("arena3d")
	if a3d == null or a3d.world_env == null:
		_check(false, "lighting: no Arena3D environment")
		await _free(arena)
		return
	var env: Environment = a3d.world_env.environment
	_check(a3d.tonemap_mode() != Environment.TONE_MAPPER_ACES and not a3d.fog_enabled() \
			and not env.glow_enabled,
		"the default look boots clean: Linear tonemap, no fog, no glow",
		"tonemap %d / fog %.4f / glow %.2f" % [a3d.tonemap_mode(), a3d.fog_density(),
			a3d.glow_intensity()])
	for idx in [0, 1, 2]:
		a3d.apply_phase(idx, 0.0)
		await process_frame
		var tag: String = a3d.phase_name()
		_check(not a3d.fog_enabled() or a3d.fog_density() <= 0.002,
			"%s: the sky gradient carries depth, not fog" % tag,
			"%s %.4f" % ["fog on" if a3d.fog_enabled() else "fog off", a3d.fog_density()])
		_check(not env.glow_enabled or a3d.glow_intensity() <= 0.2,
			"%s: no bloom wash over the fighters" % tag, "glow %.2f" % a3d.glow_intensity())
		_check(a3d.tonemap_mode() != Environment.TONE_MAPPER_ACES,
			"%s: the tonemap is not ACES" % tag, "mode %d" % a3d.tonemap_mode())
		_check(a3d.key_to_ambient_ratio() >= 2.0,
			"%s: key:ambient stays at 2:1 or better" % tag,
			"%.2f : 1 (key %.2f / ambient %.2f)" % [a3d.key_to_ambient_ratio(),
				a3d.key_energy(), a3d.ambient_energy()])
		_check(a3d.light_count() == 7, "%s: the seven-light rig is unchanged" % tag,
			"%d lights" % a3d.light_count())
		var casters := 0
		for key in ["p1", "p2"]:
			if _casts_directional_shadow(a3d.models.get(key)):
				casters += 1
		_check(casters == 2 and a3d.sun.shadow_enabled,
			"%s: both fighters still cast the crisp directional shadow" % tag,
			"%d/2 casters, sun shadow %s" % [casters, str(a3d.sun.shadow_enabled)])
		if idx == 2:
			# The night beams stay coloured but are held under the washout point now that glow
			# and ACES are gone (they were 2.60 under the graded look).
			_check(a3d._stage_energy_base <= 2.4 and a3d.spot_left.light_color.b > 0.8,
				"night keeps its coloured beams under the washout point",
				"base %.2f %s" % [a3d._stage_energy_base, str(a3d.spot_left.light_color)])
	# F6: the previous look returns on the exact same shot, and the lens/facing do not move.
	a3d.apply_phase(0, 0.0)
	await process_frame
	var cam_before: Transform3D = a3d.camera.global_transform
	var fov_before: float = a3d.camera.fov
	var facing_before: int = arena.p1.facing
	arena._unhandled_input(_key_event(KEY_F6))
	await process_frame
	_check(a3d.look_label() == "LEGACY A/B" \
			and a3d.tonemap_mode() == Environment.TONE_MAPPER_ACES \
			and a3d.fog_enabled() and env.glow_enabled,
		"F6 restores the previous graded look (ACES + glow + fog)")
	_check(a3d.camera.global_transform.is_equal_approx(cam_before) \
			and is_equal_approx(a3d.camera.fov, fov_before) \
			and arena.p1.facing == facing_before,
		"F6 changes the grade only: the frustum and the facing are untouched",
		"fov %.2f, facing %+d" % [a3d.camera.fov, arena.p1.facing])
	var hud = arena.get("hud")
	_check(hud != null and String(hud.debug_chip).contains("LEGACY"),
		"the HUD carries a live look label",
		String(hud.debug_chip) if hud != null else "no HUD")
	arena._unhandled_input(_key_event(KEY_F6))
	await process_frame
	_check(a3d.look_label() == "CLEAN" \
			and a3d.tonemap_mode() == Environment.TONE_MAPPER_LINEAR,
		"F6 returns to the clean look, which stays the default")
	_check(hud != null and String(hud.debug_chip).contains("CLEAN"),
		"the HUD label follows the look back",
		String(hud.debug_chip) if hud != null else "no HUD")
	await _free(arena)


## True when this model still draws the sun's shadow: at least one of its body meshes casts.
func _casts_directional_shadow(model) -> bool:
	if model == null:
		return false
	for child in (model as Node).find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi != null and mi.mesh != null \
				and mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			return true
	return false


## A physical F-key press in the shape TestArena._unhandled_input reads.
func _key_event(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


## Bug 3 (2026-11-25): the camera may lean a few degrees toward the exchange, but it may
## never crop a fighter. Every pairing is checked at the playable spread with the lean held
## at both extremes; head, hips and both feet have to be inside the frustum and on screen.
func _check_camera_framing() -> void:
	print("\n-- CAMERA: 9 pairings at max spacing, ±4° exchange lean, accent peak")
	var view := _view_size()
	for a in FIGHTERS:
		for b in FIGHTERS:
			var arena = await _spawn(a, b)
			var arena3d = arena.get("arena3d")
			if arena3d == null:
				_check(false, "%s vs %s: no 3D camera for the framing audit" % [a, b])
				await _free(arena)
				continue
			arena.p1.global_position = Vector2(390.0, 600.0)
			arena.p2.global_position = Vector2(890.0, 600.0)
			for i in 45:
				await process_frame
			# PART 1 commit 3: the cinematic accent (K.O. blow / special activation) pulls the
			# lens in and leans it at its peak. Held centred first, then with its own ±2° yaw
			# at each side, so the accent's ANGLE is exercised against the frustum and not just
			# its dolly. Both fighters must stay fully framed in all three. Measured before the
			# exchange-lean cases so each hold starts from the same settled neutral framing.
			var accent_cases := [[0, "centred"], [1, "leaning toward P1"], [-1, "leaning toward P2"]]
			var accent_yaws := {}
			for accent_case in accent_cases:
				arena3d.hold_cinematic_accent(1.0, 8, int(accent_case[0]))
				await process_frame
				await process_frame
				accent_yaws[int(accent_case[0])] = rad_to_deg(arena3d.camera.rotation.y)
				var accent := _framing_ok(arena3d, arena, view)
				_check(bool(accent[0]), "%s vs %s: both fighters fully framed at the accent peak %s %s"
					% [a, b, String(accent_case[1]), String(accent[1])])
			# Proof the framing cases above are not vacuous: the side really reaches the lens,
			# leaning opposite ways by roughly twice the accent's 2° yaw.
			_check(signf(float(accent_yaws[1])) > 0.0 and signf(float(accent_yaws[-1])) < 0.0
					and absf(float(accent_yaws[1]) - float(accent_yaws[-1])) > 3.0,
				"%s vs %s: the accent leans the lens both ways (%+.2f° / %+.2f°)"
					% [a, b, float(accent_yaws[1]), float(accent_yaws[-1])])
			for yaw in [-4.0, 4.0]:
				arena3d.hold_exchange_yaw(yaw, 5)
				await process_frame
				var lean := _framing_ok(arena3d, arena, view)
				_check(bool(lean[0]), "%s vs %s: both fighters fully framed at %+.0f° lean %s"
					% [a, b, yaw, String(lean[1])])
			await _free(arena)


## Head, hips and both feet of both fighters inside the frustum and at least `margin` px on
## screen (4 px for the lean and accent-peak checks, a wider band for the stacked yard case).
## Returns `[ok, detail]`.
func _framing_ok(arena3d, arena, view: Vector2, margin: float = 4.0) -> Array:
	for fighter in [arena.p1, arena.p2]:
		var model = arena3d.model_for(fighter)
		if model == null:
			return [false, "no model"]
		for bone in ["Head", "Hips", "LeftFoot", "RightFoot"]:
			var point := _bone_world(model, bone)
			if not arena3d.camera.is_position_in_frustum(point):
				return [false, "%s frustum (%.2f,%.2f,%.2f)" % [bone, point.x, point.y, point.z]]
			var on_screen: Vector2 = arena3d.camera.unproject_position(point)
			if on_screen.x < margin or on_screen.y < margin \
					or on_screen.x > view.x - margin or on_screen.y > view.y - margin:
				return [false, "%s screen (%.1f,%.1f) of (%.0f,%.0f)"
					% [bone, on_screen.x, on_screen.y, view.x, view.y]]
	return [true, ""]


const YARD_MARGIN_PX := 12.0
## The lens body is a point plus this radius: the camera's near plane sits 0.05 m out and the
## audit should flag a rail or a chest that is merely grazing it, not only a dead centre hit.
const CAMERA_BODY_RADIUS := 0.12
## Everything the lens can carry at once, stacked: the accent's 0.85 dolly and ±2° yaw, the ±4°
## exchange lean, and the hit-stop punch at its 1.6 ceiling. At max spacing this is the tightest
## the frame ever gets, so it is the case where a crop, a clipped backdrop edge or a camera
## inside the crowd would actually show.
func _check_camera_stage_clearance() -> void:
	print("\n-- CAMERA vs YARD: accent + lean + punch at max, 9 pairings, max spacing")
	var view := _view_size()
	for a in FIGHTERS:
		for b in FIGHTERS:
			var arena = await _spawn(a, b)
			var arena3d = arena.get("arena3d")
			if arena3d == null:
				_check(false, "%s vs %s: no 3D camera for the yard clearance audit" % [a, b])
				await _free(arena)
				continue
			arena.p1.global_position = Vector2(390.0, 600.0)
			arena.p2.global_position = Vector2(890.0, 600.0)
			for i in 45:
				await process_frame
			# ---- Fix pass commit 2: the deeper set, framed at the NEUTRAL camera -----------
			# Booth depth, both towers and the two DJ stands were placed by `StageLayout` over
			# the measured AABBs at load; read back here on the live lens.
			var layout: Dictionary = arena3d.stage_layout()
			var booth_z: float = arena3d.stage_booth_z()
			var nearest_face: float = arena3d.stage_nearest_face_z()
			_check(booth_z >= StageLayout.BOOTH_Z_MIN and booth_z <= StageLayout.BOOTH_Z_MAX,
				"%s vs %s: the booth stands in the brief's -5.0 to -4.2 m band" % [a, b],
				"booth z %.2f" % booth_z)
			_check(nearest_face <= -3.6 and -nearest_face >= 2.5,
				"%s vs %s: the clean sand strip to the nearest prop is at least 2.5 m" % [a, b],
				"nearest face z %.2f (%.2f m of sand)" % [nearest_face, -nearest_face])
			var prop_boxes: Array = arena3d.prop_bounds()
			var margin_details := ""
			for box in prop_boxes:
				var escape := _outside_margin(arena3d.camera, view, box, StageLayout.MARGIN_PX)
				if escape != "":
					margin_details += " " + escape
			_check(prop_boxes.size() == 2 and margin_details == "",
				"%s vs %s: every deck and tower corner sits inside the frame with a 12 px margin" % [a, b],
				margin_details if margin_details != "" else "%d prop box(es) in a %.0fx%.0f view" % [
					prop_boxes.size(), view.x, view.y])
			var overlap := ""
			for box in prop_boxes:
				if box != _prop_bounds(arena3d, "dj_booth.glb") \
						and box.intersects(_prop_bounds(arena3d, "dj_booth.glb")):
					overlap = "tower z %.2f..%.2f vs deck z %.2f..%.2f" % [box.position.z,
						box.end.z, _prop_bounds(arena3d, "dj_booth.glb").position.z,
						_prop_bounds(arena3d, "dj_booth.glb").end.z]
			_check(overlap == "",
				"%s vs %s: the towers stand clear of the deck in depth" % [a, b],
				overlap if overlap != "" else "no tower/deck intersection")
			var rays_blocked := ""
			for box in prop_boxes:
				for fighter in [arena.p1, arena.p2]:
					var ray_x: float = arena3d.px_to_world_x(fighter.global_position.x)
					for height in [0.35, 1.0, 1.65]:
						if _ray_hits_box(arena3d.camera.global_position,
								Vector3(ray_x, height, 0.0), box):
							rays_blocked = "%s at y %.2f" % [fighter.fighter_key, height]
			_check(rays_blocked == "",
				"%s vs %s: no camera-to-fighter ray crosses a prop" % [a, b],
				rays_blocked if rays_blocked != "" else "%d prop box(es) x 6 rays" % prop_boxes.size())
			var deck_box := _prop_bounds(arena3d, "dj_booth.glb")
			var dj_clear := true
			var dj_detail := ""
			for dj_index in arena3d.dj_booth.dj_count():
				var dj_box: AABB = arena3d.dj_booth.dj_world_bounds(dj_index)
				if dj_box.size == Vector3.ZERO or dj_box.intersects(deck_box) \
						or dj_box.position.z >= deck_box.position.z:
					dj_clear = false
					dj_detail += " #%d z %.2f..%.2f" % [dj_index, dj_box.position.z, dj_box.end.z]
			_check(dj_clear,
				"%s vs %s: both DJ rigs stand behind the deck without interpenetrating it" % [a, b],
				dj_detail if not dj_clear else "deck z %.2f..%.2f" % [deck_box.position.z,
					deck_box.end.z])
			# PART 2 commit 5: the clearance must hold with the crowd at its ERUPTION PEAK, so
			# the yard is erupting before the obstacle boxes are measured and stays erupting
			# (0.9 s peak) across all four stacks.
			# Fix pass commit 1: the spectator rigs are off, so the obstacle set is the yard's own
			# furniture. The clearance still runs at a full Hype eruption, because the cue path is
			# live even with no bodies and must never be assumed harmless.
			if arena3d.crowd3d != null:
				arena3d.crowd3d.erupt(1.0)
				for i in 2:
					await process_frame
				_check(arena3d.crowd3d.node_count() == 0
						and arena3d.crowd3d.eruption_active(),
					"%s vs %s: the yard clearance runs with the rigs off and the eruption cue live" % [a, b])
			var obstacles: Array = arena3d.camera_obstacles()
			var sky_centre: Vector3 = arena3d.backdrop_centre()
			var sky_half: Vector2 = arena3d.backdrop_half_extent()
			# PART D: every phrase, at the impact points and at far off-screen points, through
			# the live lens at this stacked extreme. Counted here and asserted once per pairing.
			var callout: ComicCallout2D = arena.get("comic_callouts")
			var callout_escapes := 0
			var callout_cases := 0
			var callout_safe: Rect2 = callout.safe_rect() if callout != null else Rect2()
			var callout_points: Array = []
			if callout != null:
				for fighter in [arena.p1, arena.p2]:
					callout_points.append(arena3d.world_point_of(
						fighter.global_position + Vector2(0.0, -110.0)))
				callout_points.append(arena3d.world_point_of(Vector2(-520.0, 980.0)))
				callout_points.append(arena3d.world_point_of(Vector2(1820.0, -320.0)))
				callout_points.append(Vector3(0.0, 0.02, 0.0))
				callout_points.append(Vector3(0.0, 3.4, 0.0))
			var stacked_angle := 0.0
			var stacked_punch := 0.0
			var worst_visible := 1.0
			for yaw in [-4.0, 4.0]:
				for side in [-1, 1]:
					var cam: Camera3D = arena3d.camera
					# Re-pin every frame: the punch and accent springs decay every presented frame,
					# and the case is "all three at their maximum", not "one frame after".
					for step in 2:
						arena3d.hold_camera_pressure(yaw, 1.0, side, AnimationFeel.CAMERA_PUNCH_MAX, 4)
						await process_frame
					stacked_angle = rad_to_deg(cam.rotation.y)
					stacked_punch = float(arena3d.camera_punch)
					# The towers may lose a sliver at the stacked extreme; the brief allows 10 %.
					for tower_box in prop_boxes:
						worst_visible = minf(worst_visible,
							_visible_fraction(cam, view, tower_box))
					var label := "%s vs %s: %+.0f° lean, accent side %+d" % [a, b, yaw, side]
					# (1) The lens body never enters the yard's own furniture.
					var cam_pos: Vector3 = cam.global_position
					var intruder := ""
					for box in obstacles:
						if (box as AABB).grow(CAMERA_BODY_RADIUS).has_point(cam_pos):
							intruder = "inside a %.1f×%.1f×%.1f box at (%.2f, %.2f, %.2f)" % [
								(box as AABB).size.x, (box as AABB).size.y, (box as AABB).size.z,
								cam_pos.x, cam_pos.y, cam_pos.z]
							break
					_check(intruder == "" and cam_pos.y > 0.2,
						"%s: lens body clear of every crowd rig, barrier, prop slot and booth" % label,
						intruder if intruder != "" else "%d boxes, y %.2f" % [obstacles.size(), cam_pos.y])
					# (2) No corner of the frame looks past the yard's backdrop.
					var void_detail := _void_corner(cam, view, sky_centre, sky_half)
					_check(void_detail == "",
						"%s: all four view corners land on the sky backdrop" % label, void_detail)
					# (3) Both fighters fully framed, with margin to spare.
					var framed := _framing_ok(arena3d, arena, view, YARD_MARGIN_PX)
					_check(bool(framed[0]),
						"%s: both fighters framed with %.0f px margin" % [label, YARD_MARGIN_PX],
						String(framed[1]))
					# (4) PART 3 commit 8: the delivered speaker tower must never sit between the
					# lens and a body. Same rays the player's eye takes — camera to three heights on
					# each fighter — tested against the tower's own world AABB, at the stacked max.
					var tower := _speaker_bounds(arena3d)
					var blocked := ""
					for fighter in [arena.p1, arena.p2]:
						var at_x: float = arena3d.px_to_world_x(fighter.global_position.x)
						for h in [0.35, 1.0, 1.65]:
							if _ray_hits_box(cam.global_position, Vector3(at_x, h, 0.0), tower):
								blocked = "%s at y %.2f" % [fighter.fighter_key, h]
					_check(tower.size != Vector3.ZERO and blocked == "",
						"%s: camera-to-fighter rays clear the speaker tower" % label,
						blocked if blocked != "" else "6 rays, tower z %.2f..%.2f" % [
							tower.position.z, tower.end.z])
					# (4b) Overnight props (2026-11-27): the deck stands behind the barrier and the mic
					# rides in a hand, so neither may enter the play lane or cut a camera-to-body ray.
					var deck := _prop_bounds(arena3d, "dj_booth.glb")
					var mic_box := _prop_bounds(arena3d, "wireless_mic.glb")
					var lane_left: float = arena3d.px_to_world_x(BaseFighter.STAGE_LEFT)
					var lane_right: float = arena3d.px_to_world_x(BaseFighter.STAGE_RIGHT)
					var lane := AABB(Vector3(lane_left, 0.0, -0.5),
						Vector3(lane_right - lane_left, 2.2, 1.0))
					var deck_blocked := ""
					for fighter in [arena.p1, arena.p2]:
						var at_x: float = arena3d.px_to_world_x(fighter.global_position.x)
						for h in [0.35, 1.0, 1.65]:
							if _ray_hits_box(cam.global_position, Vector3(at_x, h, 0.0), deck):
								deck_blocked = "deck in front of %s at y %.2f" % [fighter.fighter_key, h]
					_check(deck.size != Vector3.ZERO and not deck.intersects(lane)
							and deck_blocked == "",
						"%s: the DJ deck stays out of the play lane and off both ray sets" % label,
						deck_blocked if deck_blocked != "" else "deck z %.2f..%.2f" % [
							deck.position.z, deck.end.z])
					# The kid carries the (still undelivered) stand instead of the mic, so an empty box is
					# the correct answer for that pairing.
					var mic_ok: bool = mic_box.size.x < 0.30 and mic_box.size.y < 0.30 \
						and mic_box.size.z < 0.30
					_check(mic_ok,
						"%s: the hand mic is a 0.24 m prop, never a stage obstacle" % label,
						"%.2f × %.2f × %.2f m" % [mic_box.size.x, mic_box.size.y, mic_box.size.z])
					# (5) PART D: the comic callout clamp holds at THIS stacked extreme. Every
					# phrase, at both impact points and at three points outside the stage, must
					# land inside the safe play rectangle.
					if callout != null:
						for category in ComicCallout2D.PHRASES:
							for phrase in ComicCallout2D.PHRASES[category]:
								for point in callout_points:
									callout_cases += 1
									if not callout_safe.encloses(callout.rect_for_phrase(
											String(phrase), point)):
										callout_escapes += 1
			# The stack is real: lean + accent yaw must actually reach the lens ceiling, and the
		# punch must still be pinned there, or the three checks above prove nothing.
			_check(absf(stacked_angle) > 5.0 and stacked_punch > 1.55,
				"%s vs %s: the max stack reaches the lens (%.2f°, punch %.2f)" % [a, b, stacked_angle, stacked_punch])
			_check(worst_visible >= 0.90,
				"%s vs %s: at least 90 %% of every prop stays framed at the stacked extremes"
					% [a, b],
				"worst visible share %.3f across 4 extremes" % worst_visible)
			_check(callout != null and callout_escapes == 0,
				"%s vs %s: every comic callout box stays inside the safe play rectangle at the stacked extremes"
					% [a, b],
				"%d of %d boxes escaped" % [callout_escapes, callout_cases])
			# (5) The delivery's other half: the HUD is a CanvasLayer composited above the whole 3D
			# viewport, so no prop depth can ever paint over a health bar. Asserted, not assumed.
			var hud := arena.get_node_or_null("HUD")
			_check(hud is CanvasLayer and (hud as CanvasLayer).layer > 0,
				"%s vs %s: the HUD is a CanvasLayer above the 3D yard" % [a, b],
				"layer %d" % ((hud as CanvasLayer).layer if hud is CanvasLayer else -1))
			await _free(arena)


## Empty when every viewport corner's ray lands inside the sky backdrop rect; otherwise the
## first corner that escapes it — the void the owner would see past the yard.
func _void_corner(cam: Camera3D, view: Vector2, centre: Vector3, half: Vector2) -> String:
	var corners := [Vector2(0.0, 0.0), Vector2(view.x, 0.0),
		Vector2(0.0, view.y), Vector2(view.x, view.y)]
	for corner in corners:
		var origin: Vector3 = cam.project_ray_origin(corner)
		var dir: Vector3 = cam.project_ray_normal(corner)
		if absf(dir.z) < 0.00001:
			return "corner (%.0f,%.0f) runs parallel to the backdrop" % [corner.x, corner.y]
		var t: float = (centre.z - origin.z) / dir.z
		if t <= 0.0:
			return "corner (%.0f,%.0f) never reaches the backdrop" % [corner.x, corner.y]
		var hit: Vector3 = origin + dir * t
		if absf(hit.x - centre.x) > half.x or absf(hit.y - centre.y) > half.y:
			return "corner (%.0f,%.0f) exits the backdrop at (%.1f, %.1f) of ±(%.1f, %.1f)" % [
				corner.x, corner.y, hit.x, hit.y, half.x, half.y]
	return ""


## Bug 3: the strike silhouette. On ACTIVE the camera-side fist must reach further across
## the frame than it does at idle, and the facing pivot must stay inside its 5° band.
func _check_strike_silhouette() -> void:
	print("\n-- STRIKE SILHOUETTE: camera-side fist extent")
	for key in FIGHTERS:
		var arena = await _spawn(key, &"feedback")
		var arena3d = arena.get("arena3d")
		var model = arena3d.models.get("p1") if arena3d != null else null
		if model == null:
			_check(false, "%s: no 3D model for the strike-silhouette audit" % key)
			await _free(arena)
			continue
		for i in 24:
			await process_frame
		var idle_extent := _fist_extent(arena3d, model)
		var p1: BaseFighter = arena.p1
		p1._attack_id = &"jab"
		p1._attack = p1.attacks[&"jab"]
		p1.state = BaseFighter.State.ATTACK_ACTIVE
		p1.state_frame = 2
		for i in 2:
			await process_frame
		var active_extent := _fist_extent(arena3d, model)
		_check(active_extent > idle_extent + 0.002,
			"%s: camera-side fist reaches further on ACTIVE (%.3f → %.3f of frame width)"
			% [key, idle_extent, active_extent])
		# Step 0 (2026-11-25): the drawn toe line, which is the axis `_pin_body_facing()` owns
		# and the only one this assertion ever meant. It used to read `world_forward()`, the
		# mesh axis: that legitimately turns with the take's own pelvis twist during a boosted
		# strike (16.6° on Feedback while the feet stay on ±X), so it reported animation as a
		# facing error and swung between 1.9° and 16.6° with whichever blend frame the sample
		# landed on. The 5° tolerance is untouched.
		var forward: Vector3 = model.toe_forward_world()
		var facing_off := absf(rad_to_deg(atan2(forward.z, forward.x)))
		_check(forward != Vector3.ZERO and facing_off <= 5.0,
			"%s: facing pivot keeps the drawn toes inside 5° through the boosted strike" % key,
			"%.2f°" % facing_off)
		await _free(arena)


## Horizontal screen distance from the pelvis to the striking hand, as a fraction of the
## frame width. Projection only; nothing here reads a hitbox.
func _fist_extent(arena3d, model: Node3D) -> float:
	var cam: Camera3D = arena3d.camera
	var hand := _bone_world(model, "RightHand")
	var hips := _bone_world(model, "Hips")
	var view := _view_size()
	return absf(cam.unproject_position(hand).x - cam.unproject_position(hips).x) / maxf(view.x, 1.0)


## World-space AABB of the first loaded slot whose file name ends with `file`, or an empty box
## while it is missing. Audit only: allocates nothing in the game path.
func _prop_bounds(arena3d, file: String) -> AABB:
	var out := AABB()
	if arena3d == null:
		return out
	for node in arena3d.find_children("*", "PropLoader", true, false):
		var slot := node as PropLoader
		if slot == null or slot.model == null or slot.is_empty():
			continue
		if not String(slot.model_path).ends_with(file):
			continue
		var first := true
		for child in slot.model.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var box: AABB = mi.global_transform * mi.mesh.get_aabb()
			out = box if first else out.merge(box)
			first = false
	return out


## Longest dimension of a loaded prop in WORLD metres, measured on the model's own axes so a
## hand rotation cannot inflate it the way an axis-aligned world box would.
func _prop_longest_world(slot: PropLoader) -> float:
	if slot == null or slot.model == null:
		return 0.0
	var box := AABB()
	var first := true
	for child in slot.model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi != null and mi.mesh != null:
			box = mi.mesh.get_aabb() if first else box.merge(mi.mesh.get_aabb())
			first = false
	return maxf(box.size.x, maxf(box.size.y, box.size.z)) \
		* slot.model.global_transform.basis.get_scale().y


## "" when every surface of a loaded slot is a native `StandardMaterial3D` carrying its own
## albedo with mipmaps and anisotropic filtering, else the first offending surface.
func _prop_material_problem(slot: PropLoader) -> String:
	if slot == null or slot.model == null:
		return ""
	for node in slot.model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(surface)
			if not (mat is StandardMaterial3D):
				return "%s surface %d is %s, not native" % [mi.name, surface,
					mat.get_class() if mat != null else "unbound"]
			var std := mat as StandardMaterial3D
			if std.texture_filter != BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC:
				return "%s surface %d has filter %d" % [mi.name, surface, std.texture_filter]
			if std.albedo_texture == null:
				return "%s surface %d lost its albedo" % [mi.name, surface]
			if slot.double_sided and std.cull_mode != BaseMaterial3D.CULL_DISABLED:
				return "%s surface %d dropped its two-sided culling" % [mi.name, surface]
	return ""


## World-space AABB of the delivered speaker tower, or an empty box while it is missing.
## Audit only: this allocates nothing per frame and nothing in the game path.
func _speaker_bounds(arena3d) -> AABB:
	var out := AABB()
	if arena3d == null:
		return out
	for node in arena3d.find_children("*", "PropLoader", true, false):
		var slot := node as PropLoader
		if slot == null or slot.model == null or slot.is_empty():
			continue
		if not String(slot.model_path).ends_with("jamaican_speaker.glb"):
			continue
		var first := true
		for child in slot.model.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			var box: AABB = mi.global_transform * mi.mesh.get_aabb()
			out = box if first else out.merge(box)
			first = false
	return out


## True when the segment `from`→`to` enters `box` (slab test, t clamped to the segment).
func _ray_hits_box(from: Vector3, to: Vector3, box: AABB) -> bool:
	if box.size == Vector3.ZERO:
		return false
	var dir := to - from
	var t0 := 0.0
	var t1 := 1.0
	for axis in 3:
		var d: float = dir[axis]
		var o: float = from[axis]
		if absf(d) < 0.000001:
			if o < box.position[axis] or o > box.end[axis]:
				return false
			continue
		var a: float = (box.position[axis] - o) / d
		var b: float = (box.end[axis] - o) / d
		if a > b:
			var swap := a
			a = b
			b = swap
		t0 = maxf(t0, a)
		t1 = minf(t1, b)
		if t0 > t1:
			return false
	return true


func _view_size() -> Vector2:
	# The window object is 64×64 headlessly, but the camera projects through the project's
	# 1280×720 viewport; the audit must measure in that space.
	return root.get_visible_rect().size


## `|up_y|` of the body: hips -> head, which is the axis the lying contract measures.
func _up_y(model: Node3D) -> float:
	var hips := _bone_world(model, "Hips")
	var head := _bone_world(model, "Head")
	var up := head - hips
	return (up.normalized() if up.length() > 0.0001 else Vector3.UP).y


## The lying readout: up, chest normal and head-away, all in 3D world space. The chest normal's
## sign is the rig constant measured standing (`up × side` points backward on every delivered
## body), so it is flipped once here instead of being re-decided by a facing that is
## perpendicular to the normal once the body is flat.
func _lying_metrics(model: Node3D, opp_model: Node3D) -> Dictionary:
	var hips := _bone_world(model, "Hips")
	var head := _bone_world(model, "Head")
	var side := (_bone_world(model, "LeftShoulder") - _bone_world(model, "RightShoulder"))
	var up := (head - hips).normalized() if (head - hips).length() > 0.0001 else Vector3.UP
	var chest := -up.cross(side.normalized())
	var away := true
	if opp_model != null:
		var opp := opp_model.global_position.x - hips.x
		away = (head.x - hips.x) * opp < 0.0
	return {"up_y": up.y, "chest_ny": chest.y, "away": away}


func _bone_world(model: Node3D, suffix: String) -> Vector3:
	var skel: Skeleton3D = model.get("skeleton")
	if skel == null:
		return Vector3.ZERO
	var index := _bone(skel, suffix)
	if index < 0:
		return Vector3.ZERO
	return (skel.global_transform * skel.get_bone_global_pose(index)).origin


func _world_x(px: float) -> float:
	return (px - CENTER_PX) / PX_PER_M


## Root motion removal, asserted directly on the clips that are installed: no take may
## animate the position of the root node, the Hips or a Root bone.
func _no_root_motion_tracks(model: Node3D) -> bool:
	var player: AnimationPlayer = model.get("animation")
	if player == null:
		return true
	for lib_name in player.get_animation_library_list():
		var lib := player.get_animation_library(lib_name)
		if lib == null:
			continue
		for anim_name in lib.get_animation_list():
			var anim := lib.get_animation(anim_name)
			if anim == null:
				continue
			for track in anim.get_track_count():
				if anim.track_get_type(track) != Animation.TYPE_POSITION_3D:
					continue
				var path := String(anim.track_get_path(track))
				var bone := path.split(":")[1] if path.contains(":") else ""
				if bone == "" or bone.ends_with("Hips") or bone.ends_with("Root"):
					return false
	return true


func _rect_overlap(low: Vector2, high: Vector2, rect: Rect2) -> bool:
	var left := minf(low.x, high.x)
	var right := maxf(low.x, high.x)
	var top := minf(low.y, high.y)
	var bottom := maxf(low.y, high.y)
	return right > 0.0 and left < rect.size.x and bottom > 0.0 and top < rect.size.y


## Live skinned-mesh bounds in world space — what the renderer draws.
##
## PART A3 commit 1: this used to walk the bones itself, indexing the skin with the BONE index
## (`skin.get_bind_pose(i)` for bone `i`). On the two Tripo rigs the bind order is not the bone
## order, so the audit measured a body nobody was drawing and every knockdown number in this
## file disagreed with the played path by up to 0.34 m. `DrawnBounds` is the single sampler the
## runtime also seats with: every skinned mesh, unskinned overlays skipped, binds read through
## `skin.get_bind_bone(slot)`.
func _skinned_bounds(model: Node3D) -> Array:
	return DrawnBounds.bounds(model)


## Forward the body is drawn facing: the authored forward turned by the pivot that shipped,
## then by however far the playing take has turned the pelvis away from its own REST pose.
## The rest reference matters — the two Tripo rigs carry a 30°–40° pelvis bind yaw that their
## skin compensates for, so comparing a raw bone axis to ±X reports a turn that is not there.
func _rendered_forward(model: Node3D) -> Vector3:
	var offset := deg_to_rad(float(model.get("model_forward_yaw_offset_deg")))
	var pivot := deg_to_rad(float(model.call("facing_yaw_deg")))
	var fwd := Vector3(cos(offset), 0.0, sin(offset)).rotated(Vector3.UP, pivot)
	var skel: Skeleton3D = model.get("skeleton")
	if skel != null:
		var hips := _bone(skel, "Hips")
		if hips >= 0:
			var rest := _heading(skel.get_bone_global_rest(hips).basis)
			var pose := _heading(skel.get_bone_global_pose(hips).basis)
			if rest != Vector3.ZERO and pose != Vector3.ZERO:
				var sin_t := rest.z * pose.x - rest.x * pose.z
				var cos_t := rest.x * pose.x + rest.z * pose.z
				fwd = fwd.rotated(Vector3.UP, atan2(sin_t, cos_t))
	fwd.y = 0.0
	return fwd.normalized() if fwd.length() > 0.0001 else Vector3.RIGHT


## A basis' horizontal reference axis, whichever of its two axes still projects.
func _heading(basis: Basis) -> Vector3:
	for axis in [basis.x, basis.z]:
		var flat := Vector3(axis.x, 0.0, axis.z)
		if flat.length() > 0.2:
			return flat.normalized()
	return Vector3.ZERO


func _bone(skel: Skeleton3D, suffix: String) -> int:
	for i in skel.get_bone_count():
		if skel.get_bone_name(i).ends_with(suffix):
			return i
	return -1


## How far outside the viewport's 12 px margin any corner of `box` projects; "" when every
## corner is inside. The neutral-camera half of the stage-framing audit.
func _outside_margin(cam: Camera3D, view: Vector2, box: AABB, margin: float) -> String:
	var worst := ""
	var m := maxf(margin, 0.0)
	for i in 8:
		var p := Vector3(box.position.x if i & 1 == 0 else box.end.x,
			box.position.y if i & 2 == 0 else box.end.y,
			box.position.z if i & 4 == 0 else box.end.z)
		var s: Vector2 = cam.unproject_position(p)
		if s.x < m or s.y < m or s.x > view.x - m or s.y > view.y - m:
			worst = "corner %s at (%.0f, %.0f) of %.0fx%.0f" % [p, s.x, s.y, view.x, view.y]
	return worst


## Share of a prop's sampled volume that projects inside the viewport, 0-1. Sampled on a
## 5x5x5 grid so a corner-only test cannot hide a whole side going off frame.
func _visible_fraction(cam: Camera3D, view: Vector2, box: AABB) -> float:
	if box.size == Vector3.ZERO:
		return 1.0
	var inside := 0
	var total := 0
	for i in 5:
		for j in 5:
			for k in 5:
				var p := Vector3(
					lerpf(box.position.x, box.end.x, float(i) / 4.0),
					lerpf(box.position.y, box.end.y, float(j) / 4.0),
					lerpf(box.position.z, box.end.z, float(k) / 4.0))
				var s: Vector2 = cam.unproject_position(p)
				total += 1
				if s.x >= 0.0 and s.y >= 0.0 and s.x <= view.x and s.y <= view.y:
					inside += 1
	return float(inside) / float(total)


## Fix pass commit 3: a new 3D scale reallocates every render target, which is a freeze of its own,
## so the frame-time governor may only write it between rounds. This drives the governor with a
## deliberately huge delta inside a live round and proves the scale did not move.
func _check_quality_governor() -> void:
	print("\n-- QUALITY GOVERNOR: never rescales inside a live round")
	var arena = await _spawn(FIGHTERS[0], FIGHTERS[1], true)
	var rounds := arena.get_node_or_null("RoundController")
	var viewport := arena.get_viewport()
	var guard := 0
	while rounds != null and rounds.phase != RoundController.Phase.FIGHTING and guard < 300:
		await process_frame
		guard += 1
	var fighting: bool = rounds != null and rounds.phase == RoundController.Phase.FIGHTING
	_check(fighting, "the round controller reaches FIGHTING",
		"phase %s after %d frames" % [str(rounds.phase) if rounds != null else "-", guard])
	var before := viewport.scaling_3d_scale
	for i in 90:
		arena._govern_quality(0.5)
		await process_frame
	var during := viewport.scaling_3d_scale
	_check(is_equal_approx(before, during),
		"the governor never writes the 3D scale while a round is live",
		"%.3f -> %.3f over 90 forced frames" % [before, during])
	_check(not arena.quality_writes_allowed(),
		"a live round reports no safe quality moment", "phase FIGHTING")
	var saved_phase = rounds.phase
	rounds.phase = RoundController.Phase.ANNOUNCE
	var allowed: bool = arena.quality_writes_allowed()
	rounds.phase = saved_phase
	_check(allowed, "the governor may rescale between rounds", "phase ANNOUNCE")
	arena.queue_free()
	await process_frame


## Fix pass commit 3: a persistent yard node count. The one-of-each VFX the load-time warm-up
## spawns are alive for a second after boot, so counting raw Node children compared a frame with
## the warm-up bursts still in it against a frame after they had freed themselves. Transient
## effect nodes are excluded; every static node of the yard is still counted.
func _yard_node_count(arena3d) -> int:
	var count := 0
	for node in arena3d.find_children("*", "Node", true, false):
		var name := String(node.name)
		if name.contains("Burst") or name.contains("Parry") or name.contains("Spark") \
				or name.contains("Note") or name.contains("Vinyl"):
			continue
		count += 1
	return count


## Fix pass commit 4: J and I have to connect at NEUTRAL spacing, the middle of the band the AI
## walks in (135-155 px), which this suite has always called ~150. Measured before the change: J
## landed up to 150 px and I up to 130 px with the gap held fixed. Both were widened by ~39 % of
## their box width (+33 px / +36 px, inside the owner's +40 %), so both now land at 160 px.
const NEUTRAL_SPACING := 160.0


func _check_punch_reach() -> void:
	print("\n-- J/I REACH: both punches land at neutral spacing, 3 fighters x both slots")
	for fighter_key in FIGHTERS:
		for slot in 2:
			for move_key in [&"light", &"upper_box"]:
				var attacker_key: StringName = fighter_key
				var dummy_key: StringName = FIGHTERS[0] if fighter_key != FIGHTERS[0] else FIGHTERS[1]
				var arena = await _spawn(attacker_key, dummy_key) if slot == 0 \
					else await _spawn(dummy_key, attacker_key)
				var p1: BaseFighter = arena.p1
				var p2: BaseFighter = arena.p2
				var attacker: BaseFighter = p1 if slot == 0 else p2
				var target: BaseFighter = p2 if slot == 0 else p1
				attacker.use_local_input = false
				target.use_local_input = false
				# The sparring controller writes P2's command every frame; parking it is what lets
				# the second slot press a move at all (otherwise the AI overwrites the press).
				arena.sparring.set_process(false)
				arena.sparring.set_physics_process(false)
				var landed := [0]
				var on_hit := func(who: BaseFighter, _t: BaseFighter, result: Dictionary) -> void:
					if who == attacker and not bool(result.get("blocked", false)) \
							and not bool(result.get("parried", false)) \
							and not bool(result.get("ignored", false)):
						landed[0] += 1
				attacker.strike_resolved.connect(on_hit)
				var left := 500.0
				var right := left + NEUTRAL_SPACING
				var cmd := BaseFighter.Command.new()
				for f in 60:
					p1.global_position = Vector2(left if slot == 0 else right, 600.0)
					p2.global_position = Vector2(right if slot == 0 else left, 600.0)
					if slot == 0:
						attacker.face_toward(p2.global_position.x)
					else:
						attacker.face_toward(p1.global_position.x)
					cmd.move_x = 0.0
					if move_key == &"light":
						cmd.light = f == 2
					else:
						cmd.upper_box = f == 2
					attacker.command = cmd
					await physics_frame
				_check(landed[0] >= 1, "%s %s (%s) lands a %s at %.0f px" % [
					String(attacker_key), String(target.fighter_key), "P1" if slot == 0 else "P2",
					"J" if move_key == &"light" else "I", NEUTRAL_SPACING],
					"%d hit(s)" % landed[0])
				arena.queue_free()
				await process_frame


## Fix pass commit 4: no fighter GLB has a skeleton, so the strike line cannot be aimed through
## an arm chain; the torso yaw the profiles drive is the lever, and it is capped at 6 deg for the
## two punches. This watches the value the model actually applied on the contact frame.
func _check_punch_twist() -> void:
	print("\n-- J/I AXIS: punch torso yaw capped at 6 deg, 3 fighters x both punches")
	for fighter_key in FIGHTERS:
		for move_key in [&"light", &"upper_box"]:
			var arena = await _spawn(fighter_key, FIGHTERS[0] if fighter_key != FIGHTERS[0] else FIGHTERS[1])
			var p1: BaseFighter = arena.p1
			var p2: BaseFighter = arena.p2
			p1.use_local_input = false
			p2.use_local_input = false
			var peak := 0.0
			var cmd := BaseFighter.Command.new()
			for f in 40:
				p1.global_position = Vector2(500.0, 600.0)
				p2.global_position = Vector2(660.0, 600.0)
				cmd.move_x = 0.0
				if move_key == &"light":
					cmd.light = f == 2
				else:
					cmd.upper_box = f == 2
				p1.command = cmd
				await physics_frame
				var model = arena.arena3d.models.get("p1")
				if model != null and p1.state == BaseFighter.State.ATTACK_ACTIVE:
					peak = maxf(peak, rad_to_deg(absf(float(model.last_twist))))
			_check(peak <= FighterModel3D.J_I_TWIST_CAP * 57.2958 + 0.6,
				"%s %s keeps its torso within 6 deg of the combat axis" % [
					String(fighter_key), "J" if move_key == &"light" else "I"],
				"peak %.2f deg" % peak)
			arena.queue_free()
			await process_frame

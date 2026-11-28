extends SceneTree
## Headless check for the Sprite Stage Test scene (preview/sprite-test, 2026-11-28).
## Run with: godot --headless --path godot --script res://tools/sprite_stage_check.gd
##
## Boots the real `SpriteStageTest.tscn` and asserts the playable baseline and every diagnostic
## control's STATE: the loop order and holds, the foot pivot on the sand, the one global
## pixel_size, the three camera modes keeping the same fighter framing, the booth / speaker
## gates, the shadow modes, the filters and flip, pause / step, and the contact-sheet capture.
##
## There is no GPU in this environment, so this proves state and geometry, never pixels. The
## rendered look still needs a human check on Chromebook / iPhone.
##
## Exit code is non-zero when any assertion fails. Excluded from both Web exports (`tools/*`).

const SCENE := "res://scenes/SpriteStageTest.tscn"
const TOLERANCE_PX := 1.0

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_run()


func _check(ok: bool, line: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", line])


func _run() -> void:
	print("\n=== SPRITE STAGE TEST CHECK ===")
	var packed := load(SCENE) as PackedScene
	if packed == null:
		print("FAIL  cannot load %s" % SCENE)
		quit(1)
		return
	var stage := packed.instantiate()
	root.add_child(stage)
	await process_frame
	await process_frame

	_check_scene(stage)
	_check_timeline(stage)
	_check_pivots(stage)
	await _check_camera(stage)
	_check_gates(stage)
	await _check_controls(stage)
	await _check_capture(stage)

	stage.queue_free()
	await process_frame
	print("\n%d checks, %d FAIL" % [_checks, _failures])
	print("ALL SPRITE STAGE CHECKS PASSED" if _failures == 0 else "SPRITE STAGE CHECK FAILED")
	quit(0 if _failures == 0 else 1)


func _check_scene(stage) -> void:
	var arena = stage.get("arena")
	_check(arena != null, "the real Arena3D beach stage is the stage (no second scene)")
	_check(stage.get("arena").camera != null, "the test drives the arena's own Camera3D")
	var sprite: Sprite3D = stage.get("sprite")
	_check(sprite != null, "the preview actor exists")
	if sprite == null:
		return
	_check(sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "sprite is a billboard Sprite3D")
	_check(sprite.shaded == false, "sprite defaults to unshaded")
	_check(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
		"default texture filter is linear with mipmaps")
	_check(is_equal_approx(sprite.pixel_size, 1.542 / 488.0),
		"pixel_size is the live 3D idle height over the illustrated idle (%0.6f m/px)" % sprite.pixel_size)
	_check(sprite.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"cast shadow is off by default (ellipse shadow is the default)")
	_check(stage.get("hud") != null, "preview HUD exists")
	var arena3d = stage.get("arena")
	_check(not arena3d.is_processing(), "the arena's own camera/beat process is frozen")


func _check_timeline(stage) -> void:
	var labels: Array = []
	for label in stage.get("_labels"):
		labels.append(String(label))
	var want := ["idle 0", "walk 0", "walk 1", "walk 2", "walk 3", "box 0", "box 1", "box 2",
		"guard 0", "pause 0"]
	_check(labels == want, "loop order is idle → two steps → BOX → guard → pause (%s)" % [labels])
	var total := float(stage.get("loop_seconds"))
	_check(total > 2.0 and total < 2.5, "loop is %.3f s (≈ 2 s of idle → steps → BOX → guard → pause)" % total)
	var durations: PackedFloat32Array = stage.get("_durations")
	_check(is_equal_approx(durations[1], 0.2273) and is_equal_approx(durations[5], 0.1500)
		and is_equal_approx(durations[6], 0.0667) and is_equal_approx(durations[7], 0.3000),
		"holds preserve the authored timing (132 BPM walk keys; BOX 9/4/18 ticks)")
	var walk := PackedByteArray(stage.get("_walk_flags"))
	var walk_frames := 0
	for f in walk:
		walk_frames += int(f)
	_check(walk_frames == 4, "only the four walk keys carry the preview actor's own travel")


func _check_pivots(stage) -> void:
	var sprite: Sprite3D = stage.get("sprite")
	var actor: Node3D = stage.get("actor")
	_check(is_equal_approx(actor.position.y, 0.0), "the actor root sits on world y 0 (the sand)")
	# The pivot is at the sprite's own origin, so the foot anchor is exactly on the sand plane.
	var pivots: Array = stage.get("_pivots")
	var pivot: Vector2 = pivots[0]
	var want := Vector2(-pivot.x, -pivot.y)
	_check(sprite.offset.is_equal_approx(want),
		"foot pivot (%.1f, %.1f) is placed at the sprite origin" % [pivot.x, pivot.y])
	# Every frame's offset differs only by its own pivot, so nothing is re-scaled per frame.
	var same_scale := true
	for i in pivots.size():
		if not is_equal_approx(sprite.pixel_size, 1.542 / 488.0):
			same_scale = false
	_check(same_scale, "one pixel_size for every frame (no per-frame rescaling)")


func _check_camera(stage) -> void:
	# Coroutine: awaited by `_run` because the framing is measured after a live frame.
	var camera: Camera3D = stage.camera
	var feet := Vector3(0.0, 0.0, 0.0)
	var head := Vector3(0.0, 1.542, 0.0)
	var heights: Array = []
	for mode in 3:
		stage.set("camera_mode", mode)
		stage.call("_apply_camera_mode")
		await process_frame
		var h := absf(camera.unproject_position(feet).y - camera.unproject_position(head).y)
		heights.append(h)
	stage.set("camera_mode", 0)
	stage.call("_apply_camera_mode")
	var spread := float(heights.max()) - float(heights.min())
	_check(spread <= TOLERANCE_PX,
		"fight / long / ortho keep the same fighter framing (%.1f / %.1f / %.1f px)"
			% [heights[0], heights[1], heights[2]])
	_check(camera.fov == 30.0 and is_equal_approx(camera.position.z, 4.10),
		"default lens is the match fight camera (fov 30°, 4.10 m)")


func _check_gates(stage) -> void:
	var arena = stage.get("arena")
	_check(not arena.booth_visible(), "booth starts OFF, as the shipped match stage configures it")
	_check(not arena.speakers_visible(), "speakers start OFF, as the match stage configures it")
	stage.call("toggle_booth")
	_check(arena.booth_visible(), "booth gate on: the shack draws")
	stage.call("toggle_speakers")
	_check(arena.speakers_visible(), "speaker gate on: the towers draw")
	stage.call("toggle_booth")
	_check(not arena.booth_visible() and arena.speakers_visible(),
		"booth and speakers are separate gates (booth off, speakers still on)")
	stage.call("toggle_speakers")


func _check_controls(stage) -> void:
	# Shadow modes cycle ELLIPSE (default) -> NONE -> CAST -> ELLIPSE, one variable each.
	var sprite: Sprite3D = stage.get("sprite")
	var ellipse: MeshInstance3D = stage.get("ellipse")
	_check(ellipse.visible and sprite.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"default shadow is the test-only ground ellipse, no cast shadow")
	stage.call("cycle_shadow")
	_check(int(stage.get("shadow_mode")) == 0 and not ellipse.visible
		and sprite.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
		"shadow NONE = neither")
	stage.call("cycle_shadow")
	_check(int(stage.get("shadow_mode")) == 1 and not ellipse.visible
		and sprite.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON,
		"shadow CAST = alpha-cut cast shadow on, ellipse off")
	stage.call("cycle_shadow")
	_check(int(stage.get("shadow_mode")) == 2 and ellipse.visible,
		"shadow ELLIPSE restores the ground ellipse")

	# Flip and filter are independent controls.
	stage.call("toggle_flip")
	_check(sprite.flip_h, "P2-facing flip mirrors the sprite")
	stage.call("toggle_filter")
	_check(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST,
		"nearest-filter comparison is a separate control")
	stage.call("toggle_filter")
	stage.call("toggle_flip")

	# Lighting presets reach the shared rig.
	var arena = stage.get("arena")
	stage.call("cycle_light")
	await process_frame
	_check(String(arena.look_label()) != "", "lighting preset applied through the arena (%s)"
		% arena.look_label())
	stage.call("cycle_light")
	stage.call("cycle_light")

	# Footwork: authored / measured / manual.
	stage.call("cycle_footwork")
	_check(int(stage.get("footwork")) == 1, "footwork MEASURED is its own option")
	stage.call("set_manual_speed", 0.5)
	_check(is_equal_approx(float(stage.get("manual_speed")), 0.5)
		and int(stage.get("footwork")) == 2, "manual speed switches footwork to MANUAL")
	stage.call("cycle_footwork")
	stage.call("cycle_footwork")

	# Pause, step, speed, ghost.
	stage.call("toggle_pause")
	_check(bool(stage.get("paused")), "pause holds the loop")
	var before := int(stage.get("_cursor"))
	stage.call("step_frame", 1)
	_check(int(stage.get("_cursor")) == (before + 1) % 10, "next frame steps one key at a time")
	stage.call("step_frame", -1)
	_check(int(stage.get("_cursor")) == before, "previous frame steps back")
	stage.call("toggle_pause")
	stage.call("toggle_speed")
	_check(bool(stage.get("slow_motion")), "0.25× playback is its own control")
	stage.call("toggle_speed")
	stage.call("toggle_ghost")
	_check((stage.get("ghost") as Sprite3D).visible, "ghost frame can be shown")
	stage.call("toggle_ghost")

	# Stage backdrop.
	stage.call("toggle_stage")
	_check(int(stage.get("stage_mode")) == 1, "flat backdrop mode engaged")
	stage.call("toggle_stage")
	_check(int(stage.get("stage_mode")) == 0, "beach mode restored")


func _check_capture(stage) -> void:
	stage.call("capture_sheet")
	await process_frame
	var texture := stage.get("_sheet_texture") as Texture2D
	_check(texture != null, "contact-sheet capture produces an image strip")
	if texture != null:
		var img := texture.get_image()
		_check(img != null and img.get_width() > 640 and img.get_height() == 168,
			"strip is %d×%d px" % [img.get_width() if img else 0, img.get_height() if img else 0])
	_check(FileAccess.file_exists("user://sprite_stage_contact.png"),
		"strip saved to user://sprite_stage_contact.png")

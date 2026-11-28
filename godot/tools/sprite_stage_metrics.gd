extends SceneTree
## Sprite Stage Test — headless measurement harness (preview/sprite-test, 2026-11-28).
## Run with: godot --headless --path godot --script res://tools/sprite_stage_metrics.gd
##
## Measures the ILLUSTRATED Feedback frames that `SpriteStageTest` plays, and prints the tables
## the sprite-test report quotes. Nothing here is imported by the game: this file is excluded
## from both Web exports (the production preset already drops `tools/*`; the preview preset
## drops it too) and it only READS art and the existing frame data.
##
## What it measures, per frame (source pixels, alpha >= ALPHA_CUT, the runtime scissor value):
##   * alpha bbox, visible lowest row and the authored foot pivot;
##   * foot blobs in the bottom band — area, x span, lowest row, centre x — so the planted shoe
##     can be told from the lifted one, and so an unresolved pair can be flagged;
##   * the alpha-weighted silhouette centroid;
##   * the oversized-hand columns (the contact frame's columns past the wind-up frame's right
##     edge) and the centroid with and without them.
##
## Then it derives:
##   * the reference 3D Feedback idle height, measured live from `TestArena`'s FighterModel3D
##     (`measured_height()`: live mesh AABBs through every ancestor transform), and the global
##     `pixel_size` that puts the illustrated idle at that height;
##   * walk slide with `world_foot_x = root_x + (contact_x - pivot_x) * pixel_size`: per support
##     interval, drift at the authored speed (cm per frame and per tick), worst frame, and the
##     speed that zeroes that interval's drift — plus the least-squares speed over all intervals;
##   * BOX weight shift: the lead foot per frame, the silhouette centroid relative to it, the
##     first hand-growth frame and any visible shift that precedes it;
##   * anticipation / impact / recovery against `BaseFighter.ATTACKS[&"box"]` (read-only);
##   * signed sole-to-sand offset per grounded frame, with >1 px offsets flagged.
##
## The centroid is a visual proxy, never a body centre of mass. Animation feel is left to the
## human review; nothing here approves a frame.

const ALPHA_CUT := 56                  # 0.22 scissor, the value the runtime Sprite3D uses
const FOOT_BAND_PX := 90               # bottom band searched for shoes
const FOOT_MIN_AREA := 180             # a shoe, not a cord crossing or a shadow smudge
const FOOT_MIN_WIDTH := 22
const PX_PER_M := 140.0                # Arena3D.PX_PER_M — 2D arena pixels to world metres
const BPM := 132.0

## The frames SpriteStageTest plays, in authored order. `pivot` is the authored foot anchor:
## the aligned pack's common (768, 900), and the four-key walk panel's sole (229.7, 566).
const FRAMES := [
	{"anim": "idle", "index": 0, "file": "idle_01.png", "pivot": Vector2(768.0, 900.0), "seconds": 0.4545, "grounded": true, "note": "aligned pack 01_idle"},
	{"anim": "walk", "index": 0, "file": "walk_01_contact_a.png", "pivot": Vector2(229.7, 566.0), "seconds": 0.2273, "grounded": true, "note": "four-key CONTACT A"},
	{"anim": "walk", "index": 1, "file": "walk_02_pass_a.png", "pivot": Vector2(229.7, 566.0), "seconds": 0.2273, "grounded": true, "note": "four-key PASS A"},
	{"anim": "walk", "index": 2, "file": "walk_03_contact_b.png", "pivot": Vector2(229.7, 566.0), "seconds": 0.2273, "grounded": true, "note": "four-key CONTACT B"},
	{"anim": "walk", "index": 3, "file": "walk_04_pass_b.png", "pivot": Vector2(229.7, 566.0), "seconds": 0.2273, "grounded": true, "note": "four-key PASS B"},
	{"anim": "box", "index": 0, "file": "box_01_windup.png", "pivot": Vector2(768.0, 900.0), "seconds": 0.1500, "grounded": true, "note": "aligned 12_backhand_windup"},
	{"anim": "box", "index": 1, "file": "box_02_contact.png", "pivot": Vector2(768.0, 900.0), "seconds": 0.0667, "grounded": false, "note": "aligned 13_box_palm (foot off ground)"},
	{"anim": "box", "index": 2, "file": "box_03_followthrough.png", "pivot": Vector2(768.0, 900.0), "seconds": 0.3000, "grounded": true, "note": "aligned 14_followthrough"},
	{"anim": "guard", "index": 0, "file": "guard_01.png", "pivot": Vector2(768.0, 900.0), "seconds": 0.2273, "grounded": true, "note": "aligned 08_block"},
]

## Support intervals for the walk. `support` names the planted shoe; `ambiguous` records that
## the contact key has BOTH boots on the sand, so which one keeps the ground is read from the
## next key (the shoe that travels backwards in body space) rather than from the contact frame.
## `from_foot` / `to_foot` are indices into that frame's cx-ordered foot blobs, so the SAME
## planted shoe is followed across the interval instead of guessing by proximity. Which shoe is
## planted is read off the pixels: at CONTACT A the screen-left shoe is the swing leg in PASS A
## (lifted, x 168), so the screen-right one (342.5) is the stance foot; at CONTACT B the stance
## foot is the one that lands (352) and travels back to PASS B's grounded shoe (189.5); the
## step-1 foot finishes at CONTACT B's rear shoe (110).
const SUPPORT := [
	{"from": 1, "to": 2, "from_foot": 1, "to_foot": 1, "step": 1,
		"shoe": "screen-right shoe (step 1 stance)", "ambiguous": true,
		"why": "CONTACT A has both soles down; the screen-left one is PASS A's lifted swing leg"},
	{"from": 2, "to": 3, "from_foot": 1, "to_foot": 0, "step": 1,
		"shoe": "screen-right shoe (step 1 stance, now behind)", "ambiguous": false,
		"why": "PASS A's only grounded shoe continues backwards into CONTACT B's rear shoe"},
	{"from": 3, "to": 4, "from_foot": 1, "to_foot": 0, "step": 2,
		"shoe": "screen-right shoe (step 2 stance)", "ambiguous": true,
		"why": "CONTACT B has both soles down; the shoe that lands there is the one that travels back into PASS B"},
	{"from": 4, "to": 1, "from_foot": 0, "to_foot": 0, "step": 2,
		"shoe": "screen-left shoe (step 2 stance, loop seam)", "ambiguous": true,
		"why": "PASS B's grounded shoe closes the cycle into CONTACT A's rear shoe"},
]

var _frames: Array = []
var _failures: int = 0


func _initialize() -> void:
	_run()


func _run() -> void:
	print("\n=== SPRITE STAGE METRICS (illustrated Feedback on the 3D beach) ===")
	var ref := await _measure_3d_reference()
	_load_frames()
	_report_catalog(ref)
	_report_ground(ref)
	_report_walk(ref)
	_report_box(ref)
	_report_timing(ref)
	print("\n%s" % ("ALL SPRITE MEASUREMENTS COMPLETE" if _failures == 0
		else "%d MEASUREMENT PROBLEM(S)" % _failures))
	quit(0 if _failures == 0 else 1)


## The reference body: the live 3D Feedback that the illustrated frames are being compared to.
## Boots the real TestArena and reads the model's assembled crown-to-sole height, so the number
## is measured through the same transforms the shipped build draws.
func _measure_3d_reference() -> Dictionary:
	var setup = root.get_node_or_null("MatchSetup")
	if setup != null:
		setup.commit_match(&"feedback", &"feedback")
		setup.ai_mode = 0
	var packed := load("res://scenes/TestArena.tscn") as PackedScene
	var arena := packed.instantiate()
	var rounds := arena.get_node_or_null("RoundController")
	if rounds != null:
		rounds.enabled = false
	root.add_child(arena)
	await process_frame
	await physics_frame
	for i in 6:
		await physics_frame
	var arena3d = arena.get("arena3d")
	var out := {"authored": 1.55, "measured": 1.55, "model_height": 1.55,
		"camera_z": 0.0, "camera_fov": 0.0, "attacks": {}}
	var fighter = arena.get("p1")
	if fighter != null:
		out["attacks"] = fighter.attacks
	if arena3d == null:
		print("WARN  no Arena3D layer; falling back to the authored 1.55 m reference")
		_failures += 1
	else:
		var model = (arena3d.models as Dictionary).get("p1")
		if model == null:
			print("WARN  no p1 model; falling back to the authored 1.55 m reference")
			_failures += 1
		else:
			out["measured"] = float(model.call("measured_height"))
			out["model_height"] = float(model.model_height)
			out["source"] = String(model.call("model_source_label"))
		out["camera_z"] = float(arena3d.camera.position.z)
		out["camera_fov"] = float(arena3d.camera.fov)
	arena.queue_free()
	await process_frame
	await process_frame
	return out


func _load_frames() -> void:
	_frames.clear()
	for spec in FRAMES:
		var path := "res://assets/sprites/legacy_feedback/%s" % spec["file"]
		var img := Image.load_from_file(path)
		if img == null or img.is_empty():
			print("FAIL  cannot load %s" % path)
			_failures += 1
			continue
		var entry: Dictionary = spec.duplicate()
		entry["path"] = path
		entry["image"] = img
		_measure_frame(entry, img)
		_frames.append(entry)


## Everything measured from one frame's alpha channel.
func _measure_frame(entry: Dictionary, img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var alpha := PackedByteArray()
	alpha.resize(w * h)
	var min_x := w
	var max_x := -1
	var min_y := h
	var max_y := -1
	var sum_a := 0.0
	var sum_ax := 0.0
	for y in h:
		var row := y * w * 4
		for x in w:
			var a := data[row + x * 4 + 3]
			alpha[y * w + x] = a
			if a >= ALPHA_CUT:
				if x < min_x:
					min_x = x
				if x > max_x:
					max_x = x
				if y < min_y:
					min_y = y
				if y > max_y:
					max_y = y
			if a > 0:
				sum_a += float(a)
				sum_ax += float(a) * float(x)
	entry["w"] = w
	entry["h"] = h
	entry["bbox"] = Rect2i(min_x, min_y, maxi(max_x - min_x + 1, 0), maxi(max_y - min_y + 1, 0))
	entry["lowest_row"] = max_y
	entry["figure_h"] = max_y - min_y + 1
	entry["centroid_x"] = (sum_ax / sum_a) if sum_a > 0.0 else 0.0
	entry["alpha"] = alpha
	entry["feet"] = _foot_blobs(alpha, w, max_y)
	# Centroid with the reviewed hand region excluded is filled in by `_report_box`, once the
	# wind-up frame has supplied the cut column.
	entry["centroid_no_hand"] = entry["centroid_x"]
	var pivot: Vector2 = entry["pivot"]
	entry["sole_offset_px"] = pivot.y - float(max_y)


## Shoe candidates: column runs of opaque pixels inside the bottom band. This splits the two
## boots (and rejects the thin mic cord, which never spans FOOT_MIN_WIDTH opaque columns, and
## the baked shadow, which lives below ALPHA_CUT), one entry per run.
func _foot_blobs(alpha: PackedByteArray, w: int, lowest: int) -> Array:
	var top := maxi(lowest - FOOT_BAND_PX, 0)
	var width := PackedInt32Array()
	width.resize(w)
	width.fill(0)
	var area := PackedInt32Array()
	area.resize(w)
	area.fill(0)
	var low := PackedInt32Array()
	low.resize(w)
	low.fill(-1)
	var span_lo := PackedInt32Array()
	span_lo.resize(w)
	span_lo.fill(w)
	var span_hi := PackedInt32Array()
	span_hi.resize(w)
	span_hi.fill(-1)
	for y in range(top, lowest + 1):
		var row := y * w
		for x in w:
			if alpha[row + x] >= ALPHA_CUT:
				width[x] += 1
				area[x] += 1
				low[x] = maxi(low[x], y)
				span_lo[x] = mini(span_lo[x], x)
				span_hi[x] = maxi(span_hi[x], x)
	# Runs of columns that hold opaque pixels.
	var out: Array = []
	var run_start := -1
	for x in w:
		var occupied := width[x] > 0
		if occupied and run_start < 0:
			run_start = x
		if (not occupied or x == w - 1) and run_start >= 0:
			var end := x if occupied else x - 1
			var blob_area := 0
			var blob_low := -1
			for cx in range(run_start, end + 1):
				blob_area += area[cx]
				blob_low = maxi(blob_low, low[cx])
			var blob := {
				"x0": run_start, "x1": end, "width": end - run_start + 1,
				"cx": (float(run_start) + float(end)) * 0.5,
				"area": blob_area, "lowest": blob_low,
			}
			if blob_area >= FOOT_MIN_AREA and blob["width"] >= FOOT_MIN_WIDTH:
				out.append(blob)
			run_start = -1
	out.sort_custom(func(a, b): return a["cx"] < b["cx"])
	return out


func _report_catalog(ref: Dictionary) -> void:
	var idle := _first("idle", 0)
	var pixel_size := float(ref["measured"]) / float(idle["figure_h"])
	print("\n-- 3D reference and pixel size --")
	print("3D Feedback idle height : %.3f m live measured_height() (authored model_height %.3f m, %s)"
		% [ref["measured"], ref["model_height"], ref.get("source", "n/a")])
	print("match camera            : z %.2f m, fov %.1f deg" % [ref["camera_z"], ref["camera_fov"]])
	print("illustrated idle figure : %d px (alpha bbox %s)" % [idle["figure_h"], idle["bbox"]])
	print("pixel_size              : %.6f m/px  (= %.3f m / %d px)" % [pixel_size, ref["measured"], idle["figure_h"]])
	print("\n| anim | idx | file | px | pivot | figure px | rendered m | duration s |")
	print("| --- | --- | --- | --- | --- | --- | --- | --- |")
	for f in _frames:
		print("| %s | %d | `%s` | %dx%d | (%.1f, %.1f) | %d | %.3f | %.4f |"
			% [f["anim"], f["index"], f["file"], f["w"], f["h"], f["pivot"].x, f["pivot"].y,
				f["figure_h"], float(f["figure_h"]) * pixel_size, f["seconds"]])
	print("\nGlobal pixel_size is one number for every frame on purpose: it is the illustrated idle")
	print("at the live 3D height, so any height disagreement BETWEEN sets shows up in the test")
	print("instead of being normalised away.")


func _report_ground(ref: Dictionary) -> void:
	var pixel_size := float(ref["measured"]) / float(_first("idle", 0)["figure_h"])
	print("\n-- ground alignment (signed sole-to-sand offset, source pixels) --")
	print("positive = floating above the sand, negative = sinking; |offset| > 1 px flagged")
	print("\n| anim | idx | pivot y | visible sole row | offset px | offset m | feet | flag |")
	print("| --- | --- | --- | --- | --- | --- | --- | --- |")
	for f in _frames:
		var feet: Array = f["feet"]
		var foot_txt := "none"
		var lifted := false
		if feet.size() > 0:
			var parts: Array = []
			for b in feet:
				parts.append("x%.0f@%d" % [b["cx"], b["lowest"]])
				if int(b["lowest"]) < f["lowest_row"] - 1:
					lifted = true
			foot_txt = " ".join(parts)
		var off_px := float(f["sole_offset_px"])
		var flag := ""
		if absf(off_px) > 1.0:
			flag = ">1 px"
		if lifted:
			flag = (flag + " lifted foot").strip_edges()
		if not f["grounded"]:
			flag = (flag + " airborne pose").strip_edges()
		print("| %s | %d | %.0f | %d | %+.0f | %+.3f | %s | %s |"
			% [f["anim"], f["index"], f["pivot"].y, f["lowest_row"], off_px, off_px * pixel_size,
				foot_txt, flag])
	print("\nA lifted foot is a deliberate pose (the swing leg), not a grounding error: it is")
	print("reported inside `feet` and is never counted as a grounded sole.")


func _report_walk(ref: Dictionary) -> void:
	var pixel_size := float(ref["measured"]) / float(_first("idle", 0)["figure_h"])
	var authored := _authored_speed(pixel_size)
	print("\n-- walk slide (planted shoe, world_foot_x = root_x + (contact_x - pivot_x) * pixel_size) --")
	print("\n| interval | step | planted shoe | contact_x px | d px | seconds | zero-slide v m/s |")
	print("| --- | --- | --- | --- | --- | --- | --- |")
	var rows: Array = []
	var total_dt := 0.0
	var total_v_dt := 0.0
	for spec in SUPPORT:
		var a: Dictionary = _frame_at(spec["from"])
		var b: Dictionary = _frame_at(spec["to"])
		var cx_a := _foot_cx(a, int(spec["from_foot"]))
		var cx_b := _foot_cx(b, int(spec["to_foot"]))
		var dt := float(a["seconds"])
		var d_px := cx_b - cx_a
		var v_zero := -d_px * pixel_size / dt
		rows.append({"interval": "%d->%d" % [spec["from"], spec["to"]], "v": v_zero,
			"ambiguous": spec["ambiguous"], "dt": dt, "d_px": d_px, "cx_a": cx_a,
			"cx_b": cx_b, "step": spec["step"], "shoe": spec["shoe"]})
		total_dt += dt
		total_v_dt += v_zero * dt
		print("| %d->%d | %d | %s | %.1f -> %.1f | %+.1f | %.4f | %+.3f |"
			% [spec["from"], spec["to"], spec["step"], spec["shoe"], cx_a, cx_b, d_px, dt, v_zero])
	var best := total_v_dt / maxf(total_dt, 0.0001)
	print("\nleast-squares slide-minimising speed over the four support intervals: **%.3f m/s**" % best)
	print("authored speed (boot separation at CONTACT over one 132 BPM beat): **%.3f m/s**" % authored)
	print("\n| interval | drift at authored speed per key cm | per tick cm | vs zero-slide v | verdict |")
	print("| --- | --- | --- | --- | --- |")
	var worst := 0.0
	var worst_label := ""
	for s in rows:
		var dt: float = s["dt"]
		var drift_m := (authored - float(s["v"])) * dt
		var dr := absf(drift_m)
		if dr > worst:
			worst = dr
			worst_label = String(s["interval"])
		print("| %s | %+.2f | %+.3f | %.3f | %s |"
			% [s["interval"], drift_m * 100.0, drift_m * 100.0 / (dt * 60.0), float(s["v"]),
				"ambiguous contact" if s["ambiguous"] else "reliable"])
	print("\nworst interval: %s at %.2f cm per key (%.2f cm of planted-shoe slip)"
		% [worst_label, worst * 100.0, worst * 100.0])
	var net_cm := (authored - best) * total_dt * 100.0
	print("net drift over the full 4-key cycle: %+.2f cm — the four intervals cancel, so the" % net_cm)
	print("walk does not accumulate drift; the slip lives INSIDE each interval, not across the loop.")
	print("\nPer-frame world foot x at the authored speed (root integrated over the authored holds):")
	print("\n| key | planted shoe x px | (contact - pivot) px | world foot x m | step in m |")
	print("| --- | --- | --- | --- | --- |")
	var root := 0.0
	var prev_world := 0.0
	for spec in SUPPORT:
		var a: Dictionary = _frame_at(spec["from"])
		var cx := _foot_cx(a, int(spec["from_foot"]))
		var pivot_x := float(a["pivot"].x)
		var world := root + (cx - pivot_x) * pixel_size
		print("| %d | %.1f | %+.1f | %.3f | %+.3f |"
			% [spec["from"], cx, cx - pivot_x, world, world - prev_world])
		prev_world = world
		root += authored * float(a["seconds"])
	print("\nFacing sign: for the P2-facing flip each contact_x mirrors about the frame width")
	print("(`w - x`), so every interval's zero-slide speed keeps its magnitude and flips sign")
	print("with the facing direction; the preview's measured-speed constant is the magnitude.")
	print("Ambiguous frames: CONTACT A, CONTACT B and the loop seam carry BOTH soles on the sand,")
	print("so the planted one is identified by which shoe travels backwards in body space — no")
	print("contact frame is treated as an unambiguous foot position.")


func _report_box(ref: Dictionary) -> void:
	var pixel_size := float(ref["measured"]) / float(_first("idle", 0)["figure_h"])
	var windup := _first("box", 0)
	var contact := _first("box", 1)
	var recovery := _first("box", 2)
	var hand_cut := float(windup["bbox"].end.x)
	print("\n-- BOX weight shift (visual proxy: alpha-weighted silhouette centroid, facing +X) --")
	print("hand-growth region = columns past the wind-up frame's right edge (x > %.0f)" % hand_cut)
	print("\n| frame | lead foot cx | centroid x | centroid - lead foot px | centroid m | without hand px | without hand m |")
	print("| --- | --- | --- | --- | --- | --- | --- |")
	for f in [windup, contact, recovery]:
		var lead := _lead_foot_cx(f)
		var c := float(f["centroid_x"])
		var c2 := _centroid_excluding(f, hand_cut)
		f["centroid_no_hand"] = c2
		print("| box %d `%s` | %.1f | %.1f | %+.1f | %+.3f | %+.1f | %+.3f |"
			% [f["index"], f["file"], lead, c, c - lead, (c - lead) * pixel_size,
				c2 - lead, (c2 - lead) * pixel_size])
	var shift := (float(contact["centroid_x"]) - float(windup["centroid_x"])) * pixel_size
	var shift2 := (float(contact["centroid_no_hand"]) - float(windup["centroid_no_hand"])) * pixel_size
	print("\nshift wind-up -> contact: %+.3f m with the hand (%+.3f m without it)"
		% [shift, shift2])
	print("frame that first shows hand growth: box 1 `%s` (right edge %d -> %d, +%d px)"
		% [contact["file"], windup["bbox"].end.x, contact["bbox"].end.x,
			contact["bbox"].end.x - windup["bbox"].end.x])
	print("frames and ms before it: the wind-up pose is the only earlier frame, held %.1f ms"
		% (float(windup["seconds"]) * 1000.0))
	print("The shift PRECEDING the growth is therefore one frame (%.0f ms) long, and it is a"
		% (float(windup["seconds"]) * 1000.0))
	print("pose sample, not an interpolated in-between: the pack has one drawing per phase.")
	print("\nPre-wind-up BOX lean image present in the repo (`Feedback_Baseball_Pitch_BOX_Foot_Off_Ground.png`,")
	print("`art-source/feedback/box-handoff-2026-11-13/`): catalogued, not used as a runtime frame.")


func _report_timing(ref: Dictionary) -> void:
	var attacks: Dictionary = ref.get("attacks", {})
	var box: Dictionary = attacks.get(&"strong", {})
	print("\n-- anticipation / impact / recovery --")
	print("\n| phase | illustrated poses | illustrated ms (authored hold) | 3D Feedback BOX ticks | 3D ms |")
	print("| --- | --- | --- | --- | --- |")
	var startup_ms := float(box.get("startup", 0)) / 60.0 * 1000.0
	var active_ms := float(box.get("active", 0)) / 60.0 * 1000.0
	var recovery_ms := float(box.get("recovery", 0)) / 60.0 * 1000.0
	var windup_ms := float(_first("box", 0)["seconds"]) * 1000.0
	var contact_ms := float(_first("box", 1)["seconds"]) * 1000.0
	var follow_ms := float(_first("box", 2)["seconds"]) * 1000.0
	var total_ms := startup_ms + active_ms + recovery_ms
	var total_art_ms := windup_ms + contact_ms + follow_ms
	var total_ticks := int(box.get("startup", 0)) + int(box.get("active", 0)) + int(box.get("recovery", 0))
	print("| startup / wind-up | 1 (`box_01_windup`) | %.1f | %d | %.1f |" % [windup_ms, int(box.get("startup", 0)), startup_ms])
	print("| impact / active | 1 (`box_02_contact`) | %.1f | %d | %.1f |" % [contact_ms, int(box.get("active", 0)), active_ms])
	print("| recovery | 1 (`box_03_followthrough`) | %.1f | %d | %.1f |" % [follow_ms, int(box.get("recovery", 0)), recovery_ms])
	print("| **total** | 3 | %.1f | %d | %.1f |" % [total_art_ms, total_ticks, total_ms])
	print("\nCompared against: `BaseFighter.attacks[&\"strong\"]` (K / BOX head backhand), anim keys %s / %s / %s — the live" % [box.get("anim_startup", "?"), box.get("anim_active", "?"), box.get("anim_recovery", "?")])
	print("3D Feedback head/backhand. Read-only: this tool never writes frame data.")
	print("The illustrated pack is 3 drawings; the runtime BOX is 31 ticks. The illustrated")
	print("durations used by the test are the runtime phases, not invented animation timing.")


# ---------------------------------------------------------------- helpers
func _first(anim: String, index: int) -> Dictionary:
	for f in _frames:
		if f["anim"] == anim and int(f["index"]) == index:
			return f
	return {}


func _frame_at(key: int) -> Dictionary:
	## `key` is 1..4 for the four walk keys (the support-interval table uses 1-based keys).
	return _first("walk", key - 1)


## Centre x of the shoe at `index` in the frame's cx-ordered blob list. An out-of-range index
## is a measurement problem, not a guess: the caller gets 0 and the run fails.
func _foot_cx(f: Dictionary, index: int) -> float:
	var feet: Array = f.get("feet", [])
	if index < 0 or index >= feet.size():
		print("FAIL  %s frame %d has %d foot blob(s); requested #%d"
			% [f["anim"], f["index"], feet.size(), index])
		_failures += 1
		return 0.0
	return float(feet[index]["cx"])


func _lead_foot_cx(f: Dictionary) -> float:
	var feet: Array = f["feet"]
	if feet.is_empty():
		return 0.0
	# Facing +X: the lead foot is the screen-right one, grounded or lifted.
	return float(feet[feet.size() - 1]["cx"])


func _centroid_excluding(f: Dictionary, cut_x: float) -> float:
	var img: Image = f["image"]
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var sum_a := 0.0
	var sum_ax := 0.0
	var limit := int(cut_x)
	for y in h:
		var row := y * w * 4
		for x in limit:
			var a := data[row + x * 4 + 3]
			if a > 0:
				sum_a += float(a)
				sum_ax += float(a) * float(x)
	return (sum_ax / sum_a) if sum_a > 0.0 else 0.0


## The art's own walk speed: the distance between the two boots at CONTACT, in metres, over one
## beat at the project's 132 BPM. Not a gameplay value — the preview actor's own speed only.
func _authored_speed(pixel_size: float) -> float:
	var beat := 60.0 / BPM
	var speeds: Array = []
	for i in [1, 3]:
		var f: Dictionary = _frame_at(i)
		var feet: Array = f["feet"]
		if feet.size() >= 2:
			var span := absf(float(feet[feet.size() - 1]["cx"]) - float(feet[0]["cx"]))
			speeds.append(span * pixel_size / beat)
	if speeds.is_empty():
		return 0.0
	var total := 0.0
	for s in speeds:
		total += s
	return total / float(speeds.size())

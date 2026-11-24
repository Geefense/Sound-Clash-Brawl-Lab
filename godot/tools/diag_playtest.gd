extends SceneTree
## Playtest diagnostic (2026-11-24). Measurement only — asserts nothing, prints facts.
## Run with: godot --headless --path godot --script res://tools/diag_playtest.gd
##
## Two questions this answers from the data itself rather than from a guess:
##   1. Which world axis does each rigged fighter upload face at rest? Measured from the
##      Mixamo skeleton: `ToeBase` always sits forward of `Foot` on a human rig, so the
##      horizontal Foot→Toe vector IS the character's forward axis.
##   2. Which crowd/DJ surface binds which albedo texture, and is any of them null?

const RIGGED := {
	&"feedback": "res://assets/models/fighters/feedback_rigged.fbx",
	&"lickshot": "res://assets/models/fighters/lickshot_rigged.fbx",
	&"young_selecta": "res://assets/models/fighters/likkle_moore_rigged.fbx",
}


func _initialize() -> void:
	_measure_fighters()
	_measure_crowd()
	quit(0)


func _measure_fighters() -> void:
	print("\n=== FIGHTER MODEL FORWARD AXIS (rest pose, Foot -> ToeBase) ===")
	for key in RIGGED:
		var packed := load(String(RIGGED[key])) as PackedScene
		if packed == null:
			print("%s: FAILED TO LOAD" % key)
			continue
		var inst := packed.instantiate() as Node3D
		var skel: Skeleton3D = null
		for node in inst.find_children("*", "Skeleton3D", true, false):
			skel = node as Skeleton3D
			break
		if skel == null:
			print("%s: no Skeleton3D" % key)
			inst.free()
			continue
		# Bone names may carry an exporter tag; match by suffix.
		var idx := {}
		for i in skel.get_bone_count():
			var n := skel.get_bone_name(i)
			for want in ["LeftFoot", "LeftToeBase", "RightFoot", "RightToeBase", "Head", "Hips",
					"LeftUpLeg", "RightUpLeg", "LeftArm", "RightArm"]:
				if n.ends_with(want) and not idx.has(want):
					idx[want] = i
		# Bone rests are SKELETON space, so fold in the chain from the instantiated root to
		# the Skeleton3D first — an `Armature` node may carry its own rotation.
		var chain := _chain(inst, skel)
		if idx.has("LeftUpLeg") and idx.has("RightUpLeg"):
			# A humanoid's hip sockets are a wide, stance-independent left/right axis, so
			# this beats the splayed feet. For up +Y and character-right R, forward is U x R.
			var l: Vector3 = (chain * skel.get_bone_global_rest(idx["LeftUpLeg"])).origin
			var r: Vector3 = (chain * skel.get_bone_global_rest(idx["RightUpLeg"])).origin
			var rr := Vector3(r.x - l.x, 0.0, r.z - l.z)
			if rr.length() > 0.0001:
				rr = rr.normalized()
				var fwd := Vector3(rr.z, 0.0, -rr.x).normalized()
				var yaw_h := atan2(fwd.x, fwd.z)
				print("%s  HIPS forward=(%.3f, %.3f)  yaw_from_+Z=%+.1f deg  -> offset to +X = %+.1f deg"
					% [key, fwd.x, fwd.z, rad_to_deg(yaw_h), rad_to_deg(PI * 0.5 - yaw_h)])
		for want in ["LeftFoot", "LeftToeBase"]:
			if not idx.has(want):
				print("%s: bone %s missing (have %d bones)" % [key, want, skel.get_bone_count()])
		var names := []
		for i in skel.get_bone_count():
			names.append(skel.get_bone_name(i))
		if idx.has("LeftFoot") and idx.has("LeftToeBase"):
			var foot: Vector3 = (chain * skel.get_bone_global_rest(idx["LeftFoot"])).origin
			var toe: Vector3 = (chain * skel.get_bone_global_rest(idx["LeftToeBase"])).origin
			var a := Vector3(toe.x - foot.x, 0.0, toe.z - foot.z)
			if a.length() < 0.0001:
				print("%s: degenerate left foot->toe" % key)
			else:
				a = a.normalized()
				var yaw := atan2(a.x, a.z)
				print("%s  left forward=(%.3f, %.3f)  yaw_from_+Z=%+.1f deg  -> offset to +X = %+.1f deg"
					% [key, a.x, a.z, rad_to_deg(yaw), rad_to_deg(PI * 0.5 - yaw)])
		if idx.has("RightFoot") and idx.has("RightToeBase"):
			var foot2: Vector3 = (chain * skel.get_bone_global_rest(idx["RightFoot"])).origin
			var toe2: Vector3 = (chain * skel.get_bone_global_rest(idx["RightToeBase"])).origin
			var b := Vector3(toe2.x - foot2.x, 0.0, toe2.z - foot2.z)
			if b.length() > 0.0001:
				b = b.normalized()
				var yaw2 := atan2(b.x, b.z)
				print("%s  right forward=(%.3f, %.3f)  yaw_from_+Z=%+.1f deg  -> offset to +X = %+.1f deg"
					% [key, b.x, b.z, rad_to_deg(yaw2), rad_to_deg(PI * 0.5 - yaw2)])
		print("%s  root_type=%s  skeleton_node=%s  chain_yaw=%+.1f deg  skel_scale=%s  bone0=%s"
			% [key, inst.get_class(), skel.get_parent().name,
				rad_to_deg(chain.basis.get_euler().y), skel.scale,
				names[0] if names.size() > 0 else "?"])
		_measure_mesh(key, inst)
		inst.free()


## Independent of the skeleton: the toe is the point of each foot furthest from that foot's
## own centroid, and human feet are longer in front than behind, so the mean of the two
## foot centroid->toe vectors is the mesh's own forward axis.
func _measure_mesh(key: StringName, inst: Node3D) -> void:
	var verts: Array[Vector3] = []
	for node in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := _chain(inst, mi)
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var v = arr[Mesh.ARRAY_VERTEX]
			if v == null:
				continue
			for p in v:
				verts.append(xf * (p as Vector3))
	if verts.is_empty():
		print("  %s: no vertices" % key)
		return
	var lo := INF
	var hi := -INF
	for p in verts:
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
	var h := maxf(hi - lo, 0.0001)
	var foot_y := lo + h * 0.10
	var feet: Array[Vector3] = []
	for p in verts:
		if p.y <= foot_y:
			feet.append(p)
	if feet.size() < 8:
		print("  %s: too few foot vertices (%d)" % [key, feet.size()])
		return
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for p in feet:
		if p.x < 0.0:
			left.append(p)
		else:
			right.append(p)
	var dirs: Array[Vector3] = []
	for group in [left, right]:
		if group.size() < 4:
			continue
		var c := Vector3.ZERO
		for p in group:
			c += p
		c /= float(group.size())
		var best := Vector3.ZERO
		var far := 0.0
		for p in group:
			var d := Vector3(p.x - c.x, 0.0, p.z - c.z)
			if d.length() > far:
				far = d.length()
				best = d
		if far > 0.0001:
			dirs.append(best / far)
	if dirs.is_empty():
		print("  %s: no foot direction" % key)
		return
	var sum := Vector3.ZERO
	for d in dirs:
		sum += d
	sum = sum.normalized()
	var yaw := atan2(sum.x, sum.z)
	print("  %s  MESH forward=(%.3f, %.3f) [%d dirs]  yaw_from_+Z=%+.1f deg  -> offset to +X = %+.1f deg"
		% [key, sum.x, sum.z, dirs.size(), rad_to_deg(yaw), rad_to_deg(PI * 0.5 - yaw)])


## Transform from `root` down to (and including) `node`, as one matrix.
func _chain(root: Node3D, node: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cursor: Node = node
	while cursor != null and cursor != root:
		if cursor is Node3D:
			xf = (cursor as Node3D).transform * xf
		cursor = cursor.get_parent()
	return xf


func _measure_crowd() -> void:
	print("\n=== CROWD / DJ ALBEDO BINDINGS ===")
	for dir_path in [CharacterModelSlots.CROWD_DIR, CharacterModelSlots.DJ_DIR]:
		for path in CharacterModelSlots.model_paths(dir_path):
			var packed := load(path) as PackedScene
			if packed == null:
				print("%s: FAILED TO LOAD" % path)
				continue
			var node := packed.instantiate() as Node3D
			var count := CharacterModelSlots.apply_cel(node, Color.WHITE, Color.WHITE, 99)
			var surfaces := 0
			var nulls := 0
			var texes := {}
			for child in node.find_children("*", "MeshInstance3D", true, false):
				var mi := child as MeshInstance3D
				if mi == null or mi.mesh == null:
					continue
				for s in mi.mesh.get_surface_count():
					surfaces += 1
					var mat := mi.get_surface_override_material(s) as ShaderMaterial
					if mat == null:
						nulls += 1
						continue
					var tex := mat.get_shader_parameter("albedo_texture") as Texture2D
					if tex == null:
						nulls += 1
					else:
						texes[tex.resource_path if tex.resource_path != "" else "<runtime image %dx%d>" % [tex.get_width(), tex.get_height()]] = true
			var sources := {}
			for child in node.find_children("*", "MeshInstance3D", true, false):
				var mi := child as MeshInstance3D
				if mi == null or mi.mesh == null:
					continue
				for s in mi.mesh.get_surface_count():
					var src := mi.mesh.surface_get_material(s)
					if src == null:
						sources["<no source material>"] = true
					else:
						var t := ""
						if src is BaseMaterial3D and (src as BaseMaterial3D).albedo_texture != null:
							t = (src as BaseMaterial3D).albedo_texture.resource_path
						sources["%s albedo=%s" % [src.get_class(), t if t != "" else "<null>"]] = true
			print("%s\n    model=%s surfaces=%d cel_applied=%d null_or_missing=%d\n    bound=%s\n    source=%s"
				% [path.get_file(), node.get_class(), surfaces, count, nulls,
					str(texes.keys()), str(sources.keys())])
			node.free()

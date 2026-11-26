class_name DrawnBounds
extends RefCounted
## Where a fighter's body actually is on screen, in world space.
##
## One sampler, used by the runtime seat AND by every audit, so the two cannot disagree about
## how high the body is.
##
## Two facts drive the whole file, and both were measured, not assumed:
##
## 1. A vertex bone entry is either a SKIN BIND slot or a skeleton BONE index, and the three
##    delivered uploads disagree: Feedback (Mixamo) stores bind slots, the two Tripo bodies
##    (L!ckshot, Young Selecta) store bone indices. Assuming bind slots everywhere reported
##    Young Selecta's drawn body 0.51 m in the air (`low_mapped -0.500` vs `low_direct +0.002`,
##    PART A3). The convention is therefore decided PER MESH from the bind pose, by the rule
##    the runtime already used: whichever reading puts the drawn sole closest to the lowest
##    foot/toe BONE is the real one. A wrong mapping on a 1.5 m body is off by half a metre,
##    so the choice is never ambiguous.
## 2. `meshes[0]` on these rigs can be an unskinned overlay whose vertices are already in model
##    space. Only skinned meshes are sampled; an overlay never represents the animated body.
##
## Presentation only. It reads transforms and vertex arrays; it never writes anything.

## Ceiling on samples per mesh. The delivered bodies are ~30k vertices and the seat runs every
## physics tick; the lowest point of a limb is not a needle, so a strided sample is enough.
const SAMPLE_BUDGET := 4000

## `{mesh resource id: uses_bind_slots}`. Decided once per upload from the rest pose, so the
## decision cannot wobble with the animation. Keyed by the mesh resource, because the
## convention belongs to the upload rather than to one instance of it.
static var _bind_choice: Dictionary = {}


## Every mesh in `model` that is driven by a skin, in tree order.
static func skinned_meshes(model: Node3D) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if model != null:
		_collect(model, out)
	return out


static func _collect(node: Node, out: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			if mi.skin != null and mi.mesh != null and mi.mesh.get_surface_count() > 0:
				out.append(mi)
		_collect(child, out)


## Drawn bounding box in world space, or an empty `AABB` when nothing can be sampled.
static func box(model: Node3D) -> AABB:
	var skel: Skeleton3D = model.get("skeleton") if model != null else null
	if skel == null:
		return AABB()
	var low := Vector3(INF, INF, INF)
	var high := Vector3(-INF, -INF, -INF)
	for mi in skinned_meshes(model):
		var pair := _read_mesh(mi, skel, low, high, false, uses_bind_slots(mi, skel))
		low = pair[0]
		high = pair[1]
	if low.x == INF:
		return AABB()
	return AABB(low, high - low)


## `[low, high]` world-space corners, kept for the audits that were written against that shape.
static func bounds(model: Node3D) -> Array:
	var b := box(model)
	if b == AABB():
		return [Vector3.ZERO, Vector3.UP]
	return [b.position, b.end]


## The one number the seat needs: lowest drawn vertex in world Y, or `INF` when unsampleable.
static func lowest_y(model: Node3D) -> float:
	var b := box(model)
	return INF if b == AABB() else b.position.y


## Which convention this upload uses. `true` = vertex bones are skin bind slots (read through
## `Skin.get_bind_bone()`), `false` = they are skeleton bone indices already.
static func uses_bind_slots(mi: MeshInstance3D, skel: Skeleton3D) -> bool:
	if mi == null or mi.mesh == null:
		return true
	var key: int = mi.mesh.get_instance_id()
	if _bind_choice.has(key):
		return bool(_bind_choice[key])
	var mapped := true
	var feet: Array[int] = []
	for i in skel.get_bone_count():
		var name := skel.get_bone_name(i)
		if name.ends_with("Foot") or name.ends_with("ToeBase"):
			feet.append(i)
	if not feet.is_empty():
		var bone_low := INF
		for i in feet:
			bone_low = minf(bone_low, (skel.global_transform * skel.get_bone_global_rest(i)).origin.y)
		var best := INF
		for candidate in [true, false]:
			var low := _lowest(mi, skel, true, candidate)
			if low == INF:
				continue
			var err := absf(bone_low - low)
			if err < absf(best):
				best = err
				mapped = candidate
	_bind_choice[key] = mapped
	return mapped


## Lowest drawn Y of one mesh, optionally in the bind/rest pose (used by the convention test).
static func _lowest(mi: MeshInstance3D, skel: Skeleton3D, use_rest: bool,
		mapped: bool) -> float:
	var pair := _read_mesh(mi, skel, Vector3(INF, INF, INF), Vector3(-INF, -INF, -INF),
		use_rest, mapped)
	return INF if pair[0].y == INF else pair[0].y


## Reads one skinned mesh into the running low/high pair. The bind table is built from that
## mesh's own `Skin` under the convention `uses_bind_slots()` decided for it.
static func _read_mesh(mi: MeshInstance3D, skel: Skeleton3D, low: Vector3, high: Vector3,
		use_rest: bool, mapped: bool = true) -> Array:
	var bone_xf := _bone_transforms(skel, mi.skin, use_rest, mapped)
	var arrays := mi.mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return [low, high]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var vbones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	if verts.is_empty():
		return [low, high]
	var per := 0
	if vbones != null and weights != null and vbones.size() >= verts.size() and not bone_xf.is_empty():
		per = int(vbones.size() / verts.size())
	var step := maxi(1, int(float(verts.size()) / float(SAMPLE_BUDGET)))
	var i := 0
	while i < verts.size():
		var p := verts[i]
		if per > 0:
			var acc := Vector3.ZERO
			var total := 0.0
			for k in per:
				var bi := int(vbones[i * per + k])
				var w := float(weights[i * per + k])
				if w <= 0.0 or bi < 0 or bi >= bone_xf.size():
					continue
				acc += (bone_xf[bi] * p) * w
				total += w
			p = acc / total if total > 0.0 else mi.global_transform * p
		else:
			p = mi.global_transform * p
		low = Vector3(minf(low.x, p.x), minf(low.y, p.y), minf(low.z, p.z))
		high = Vector3(maxf(high.x, p.x), maxf(high.y, p.y), maxf(high.z, p.z))
		i += step
	return [low, high]


## One transform per `ARRAY_BONES` entry, under the chosen convention.
static func _bone_transforms(skel: Skeleton3D, skin: Skin, use_rest: bool,
		mapped: bool) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	if skin != null and mapped:
		for slot in skin.get_bind_count():
			var bone := skin.get_bind_bone(slot)
			if bone < 0 or bone >= skel.get_bone_count():
				out.append(Transform3D.IDENTITY)
				continue
			var pose := skel.get_bone_global_rest(bone) if use_rest \
				else skel.get_bone_global_pose(bone)
			out.append(skel.global_transform * pose * skin.get_bind_pose(slot))
	else:
		for i in skel.get_bone_count():
			var pose2 := skel.get_bone_global_rest(i) if use_rest \
				else skel.get_bone_global_pose(i)
			var xf: Transform3D = skel.global_transform * pose2
			if skin != null and i < skin.get_bind_count():
				xf = xf * skin.get_bind_pose(i)
			out.append(xf)
	return out

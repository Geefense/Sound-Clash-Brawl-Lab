class_name DrawnBounds
extends RefCounted
## Where a fighter's body actually is on screen, in world space (PART A2, 2026-11-26).
##
## One sampler, used by the runtime seat AND by every audit, so the two cannot disagree about
## how high the body is. Before this, `FighterModel3D` measured with `skin.get_bind_bone()`
## while the audits measured with the bone index and `skin.get_bind_pose(i)`; on the two Tripo
## rigs the bind order is not the bone order, and the two readings parted by 0.34 m on Lickshot.
##
## The mapping is the renderer's own: a vertex bone index is a SKIN BIND slot, so the bone is
## `skin.get_bind_bone(slot)` and the inverse bind is `skin.get_bind_pose(slot)`. The audits
## used to assume bind order equals bone order; on the two Tripo rigs it does not, which is
## what put 0.34 m between the runtime's reading and the audit's on Lickshot. It samples EVERY
## skinned mesh and skips unskinned overlays: `meshes[0]` on these rigs is an unskinned overlay
## whose vertices are already in model space, so including it would report a body that never
## moved.
##
## Presentation only. It reads transforms and vertex arrays; it never writes anything.

## Ceiling on samples per mesh. The delivered bodies are ~30k vertices and the seat runs every
## physics tick; the lowest point of a limb is not a needle, so a strided sample is enough.
const SAMPLE_BUDGET := 4000

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
		var pair := _read_mesh(mi, skel, low, high)
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


## Reads one skinned mesh into the running low/high pair. The bind table is built from that
## mesh's own `Skin`: overlays and body can bind differently, and the delivered rigs do.
static func _read_mesh(mi: MeshInstance3D, skel: Skeleton3D,
		low: Vector3, high: Vector3) -> Array:
	var bone_xf: Array[Transform3D] = []
	var skin: Skin = mi.skin
	if skin != null:
		for slot in skin.get_bind_count():
			var bone := skin.get_bind_bone(slot)
			var xf: Transform3D = skel.global_transform \
				* skel.get_bone_global_pose(bone if bone >= 0 else 0)
			bone_xf.append(xf * skin.get_bind_pose(slot))
	else:
		for i in skel.get_bone_count():
			bone_xf.append(skel.global_transform * skel.get_bone_global_pose(i))
	var arrays := mi.mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return [low, high]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var vbones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	if verts.is_empty():
		return [low, high]
	var per := 0
	if vbones != null and weights != null and vbones.size() >= verts.size():
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

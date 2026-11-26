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


## Lowest drawn vertex in the BIND/rest pose — the foot pin's calibration, measured through
## the same skinned meshes (and the same per-mesh convention) as everything else.
static func rest_lowest_y(model: Node3D) -> float:
	var skel: Skeleton3D = model.get("skeleton") if model != null else null
	if skel == null:
		return INF
	var low := INF
	for mi in skinned_meshes(model):
		low = minf(low, _lowest(mi, skel, true, uses_bind_slots(mi, skel)))
	return low


## Which convention this upload uses, as one flag for the audit readout: `true` when every
## skinned mesh indexes skin bind slots, `false` when at least one stores bone indices.
static func bind_convention(model: Node3D) -> bool:
	var skel: Skeleton3D = model.get("skeleton") if model != null else null
	if skel == null:
		return true
	for mi in skinned_meshes(model):
		if not uses_bind_slots(mi, skel):
			return false
	return true


## Every sampled drawn vertex in world space, `SAMPLE_BUDGET` per mesh. Used once at load by
## the downed-pose calibration, never per frame.
static func cloud(model: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	var skel: Skeleton3D = model.get("skeleton") if model != null else null
	if skel == null:
		return out
	for mi in skinned_meshes(model):
		for p in _mesh_points(mi, skel, uses_bind_slots(mi, skel)):
			out.append(p)
	return out


static func _mesh_points(mi: MeshInstance3D, skel: Skeleton3D, mapped: bool) -> PackedVector3Array:
	var out := PackedVector3Array()
	var bone_xf := _bone_transforms(skel, mi.skin, false, mapped)
	var arrays := mi.mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return out
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var vbones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	if verts.is_empty():
		return out
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
		out.append(p)
		i += step
	return out


## Principal axes of a sampled point cloud, largest variance first: `{centroid, axes, values}`
## with three orthonormal `Vector3` axes. Power iteration with deflation — the body's own
## geometry decides its long axis, so no bone axis is ever trusted to name it.
static func principal_axes(points: PackedVector3Array) -> Dictionary:
	if points.size() < 32:
		return {}
	var centroid := Vector3.ZERO
	for p in points:
		centroid += p
	centroid /= float(points.size())
	var m := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]        # xx xy xz yy yz zz
	for p in points:
		var d := p - centroid
		m[0] += d.x * d.x
		m[1] += d.x * d.y
		m[2] += d.x * d.z
		m[3] += d.y * d.y
		m[4] += d.y * d.z
		m[5] += d.z * d.z
	var n := float(points.size())
	for i in 6:
		m[i] = float(m[i]) / n
	var first := _leading_axis(m)
	if first == Vector3.ZERO:
		return {}
	var l1 := _rayleigh(m, first)
	var rest := m.duplicate()
	_deflate(rest, first, l1)
	var second := _leading_axis(rest)
	if second == Vector3.ZERO:
		return {}
	var l2 := _rayleigh(m, second)
	var third := first.cross(second).normalized()
	if third == Vector3.ZERO:
		return {}
	var axes: Array[Vector3] = [first, third.cross(first).normalized(), third]
	return {"centroid": centroid, "axes": axes, "values": [l1, l2, _rayleigh(m, third)]}


static func _mat_vec(m: Array, v: Vector3) -> Vector3:
	return Vector3(float(m[0]) * v.x + float(m[1]) * v.y + float(m[2]) * v.z,
		float(m[1]) * v.x + float(m[3]) * v.y + float(m[4]) * v.z,
		float(m[2]) * v.x + float(m[4]) * v.y + float(m[5]) * v.z)


static func _rayleigh(m: Array, v: Vector3) -> float:
	return _mat_vec(m, v).dot(v)


## The dominant direction of a symmetric 3x3 matrix. Four seeds, longest run kept, so a start
## vector that happens to be orthogonal to the answer cannot decide it.
static func _leading_axis(m: Array) -> Vector3:
	var best := Vector3.ZERO
	var best_value := -INF
	for seed in [Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(0.5774, 0.5774, 0.5774)]:
		var v: Vector3 = seed
		for step in 80:
			var nv := _mat_vec(m, v)
			if nv.length() < 1e-9:
				break
			v = nv.normalized()
		var value := _rayleigh(m, v)
		if value > best_value:
			best_value = value
			best = v
	return best


static func _deflate(m: Array, axis: Vector3, value: float) -> void:
	m[0] = float(m[0]) - value * axis.x * axis.x
	m[1] = float(m[1]) - value * axis.x * axis.y
	m[2] = float(m[2]) - value * axis.x * axis.z
	m[3] = float(m[3]) - value * axis.y * axis.y
	m[4] = float(m[4]) - value * axis.y * axis.z
	m[5] = float(m[5]) - value * axis.z * axis.z


## The bone a skin slot drives. Godot stores either a bone INDEX (`get_bind_bone`) or a named
## bind (`get_bind_name`, whose `get_bind_bone` is -1). **Every delivered upload here is named**:
## 52/52 and 65/65 slots return -1, which is why reading `get_bind_bone()` directly collapsed
## Feedback's whole body into a 1 cm blob at the origin — slot 0 was `mixamorig_RightHandThumb2`
## and every unresolved slot fell back to IDENTITY. Resolving the name is the fix.
static func slot_bone(skin: Skin, skel: Skeleton3D, slot: int) -> int:
	if skin == null or skel == null:
		return -1
	var bone := skin.get_bind_bone(slot)
	if bone >= 0:
		return bone
	var named := String(skin.get_bind_name(slot))
	if named == "":
		return -1
	return skel.find_bone(named)


## Which convention this upload uses. `true` = a vertex bone entry is a SKIN BIND slot (read
## through `slot_bone()`), `false` = it is a skeleton bone index already.
##
## Decided per upload from the BIND POSE, by the one measurement that cannot be ambiguous: a
## drawn body is as tall as its own skeleton. The wrong reading is either a collapsed blob
## (~1 cm) or a body in the wrong units/place; the right one matches the rest bone span within
## a few percent. This replaces the earlier "drawn sole nearest the foot bone" rule, which the
## collapsed blob satisfied by sitting on the ground at y 0.
static func uses_bind_slots(mi: MeshInstance3D, skel: Skeleton3D) -> bool:
	if mi == null or mi.mesh == null:
		return true
	var key: int = mi.mesh.get_instance_id()
	if _bind_choice.has(key):
		return bool(_bind_choice[key])
	var span := _bone_span(skel)
	var mapped := true
	if span > 0.01:
		var best := INF
		for candidate in [true, false]:
			var pair := _read_mesh(mi, skel, Vector3(INF, INF, INF), Vector3(-INF, -INF, -INF),
				true, candidate)
			if pair[0].x == INF:
				continue
			var err := absf((pair[1].y - pair[0].y) - span) / span
			if err < best:
				best = err
				mapped = candidate
	_bind_choice[key] = mapped
	return mapped


## World-space extent of the skeleton's own rest bone origins.
static func _bone_span(skel: Skeleton3D) -> float:
	if skel == null or skel.get_bone_count() == 0:
		return 0.0
	var low := INF
	var high := -INF
	for i in skel.get_bone_count():
		var y: float = (skel.global_transform * skel.get_bone_global_rest(i)).origin.y
		low = minf(low, y)
		high = maxf(high, y)
	return high - low if high > low else 0.0


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
			var bone := slot_bone(skin, skel, slot)
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

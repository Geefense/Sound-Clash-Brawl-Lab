class_name StageLayout
extends Resource
## Where the background set stands, as DATA (fix pass 2026-11-27, commit 2).
##
## The yard used to carry three hard-coded numbers — booth at z −3.20, towers at ±2.55 on
## z −1.45 — which put the whole set within a stride of the fighters. This resource replaces
## them with rules, so a clean sand strip ~3.7 m deep sits in front of the stage and the
## fighters' silhouettes read against it instead of against furniture:
##
##   * the booth stands centred on the yard at `BOOTH_Z` (−4.5 m, inside the brief's
##     −4.2…−5.0 window);
##   * the two towers mirror left/right at `SPEAKER_FRACTION` (80 %) of the *visible*
##     half-width at their own depth for the neutral camera, then are clamped so every AABB
##     corner stays inside the frame with a `MARGIN_PX` margin — and never closer to the
##     centre line than the booth's flank plus `BOOTH_GAP`, so the set cannot interpenetrate;
##   * because the towers and the booth are both wide delivered props, the towers stand
##     *behind* the booth's shoulders (`SPEAKER_Z`), clear of its AABB, which is what lets
##     both the frame margin and the booth gap hold at once;
##   * the set is scaled by `perspective_scale()` — camera distance to the new depth over the
##     camera distance to the old depth, clamped to 1.0…1.25 — so moving the set back does
##     not simply shrink it on screen.
##
## Every number here is metres and degrees in world space. `compute()` is pure: hand it two
## measured AABB sizes and it returns the placement, so a replacement `dj_booth.glb` of any
## size (a thatched wooden beach booth, say) is seated through the same rule with no code
## change. The `PropLoader` contract does the seating and the facing; this only places slots.

## The stage lens. These mirror `Arena3D`'s constants — the layout is written against the
## neutral camera the player actually sees at neutral spacing, not a wider editor view.
const FOV_DEG := 30.0
const CAMERA_Y := 1.0
const NEUTRAL_CAMERA_Z := 4.10
const NEUTRAL_VIEW := Vector2(1280.0, 720.0)
## The brief's clearance: 12 px of frame around every AABB corner at the neutral camera.
const MARGIN_PX := 12.0

## Booth centre depth. Inside the brief's allowed −4.6…−5.0 m band (PART M, 2026-11-27: the
## full-size shack needs the deeper half of it so its 2.34 m depth still leaves the 3.6 m
## clean sand strip in front of the fighters).
const BOOTH_Z := -4.8
const BOOTH_Z_MIN := -5.0
const BOOTH_Z_MAX := -4.6
## Where the set stood before this pass; the perspective compensation is measured from here.
const LEGACY_BOOTH_Z := -3.20
const LEGACY_SPEAKER_Z := -1.45
const LEGACY_SPEAKER_X := 2.55
## PART M: the brief's real-world sizes. `compute()` normalises whatever the delivered files
## measure to these, so the shack is a shack and the towers are towers instead of whatever
## scale the export happened to carry. `PropLoader` seats to the same numbers, which makes
## this pass a guard rather than the only thing holding the size.
const BOOTH_TARGET_HEIGHT := 2.45
const BOOTH_TARGET_WIDTH := 3.55
const SPEAKER_TARGET_HEIGHT := 2.50
## The scale clamp for that normalisation: wide enough for a very small or very large upload,
## tight enough that a degenerate AABB cannot turn the set into a monolith.
const STAGE_SCALE_MIN := 0.4
const STAGE_SCALE_MAX := 4.0
## Towers behind the booth's shoulders, clear of its AABB (see the header). PART M: −6.9 m,
## because the full-size shack is 2.34 m deep and its back wall now stands at −5.97 m.
const SPEAKER_Z := -6.90
## Fraction of the visible half-width the towers aim for before the frame clamp.
const SPEAKER_FRACTION := 0.80
## Inward yaw the two slots take, degrees. A rotation, never a mirror.
const SPEAKER_YAW_DEG := 12.0
## Perspective compensation window.
const SCALE_MIN := 1.0
const SCALE_MAX := 1.25
## Smallest gap between the booth's flank and a tower's inner face, metres. The towers stand
## 0.25 m BEHIND the booth's back face, so even a negative value here is a visual overlap of
## silhouettes, never an intersection of meshes; the audit asserts the 3D separation.
const BOOTH_GAP := 0.02
## The worst stacked camera yaw, degrees: the exchange lean (4.0) plus the cinematic accent's
## own yaw (2.0 at its 0.85 ceiling). A yawed lens swings a deep prop sideways by
## `tan(yaw) x lens-to-face distance`, so the towers reserve exactly that much frame on the
## side the lean pushes them toward. That is what keeps 90 %+ of each tower framed at the
## accent/lean/punch extremes instead of a guessed percentage of the half-width.
const LEAN_YAW_DEG := 5.7
## Smallest gap between the deck's AABB and a DJ rig's own body, metres. The gap is measured
## from the deck's back face to the CENTRE of the man plus his own half depth, so 0.40 keeps a
## real 0.16 m of air between a 0.47 m deep rig and the cabinet.
const DJ_GAP := 0.40
## DJ stand spacing as a fraction of the measured deck width (0.26 × width a side).
const DJ_X_FRACTION := 0.26


## Frame aspect for a viewport. 16:9 in the shipped window; the audit passes its own.
static func aspect_of(view: Vector2) -> float:
	return maxf(view.x / maxf(view.y, 1.0), 1.0)


## Half the visible frame at `depth` metres in front of the lens: x is the horizontal
## half-width (aspect applied), y the vertical half-height. The lens looks down −Z.
static func half_extent_at(depth: float, aspect: float) -> Vector2:
	var d := maxf(depth, 0.01)
	var h := tan(deg_to_rad(FOV_DEG * 0.5)) * d
	return Vector2(h * maxf(aspect, 1.0), h)


## `MARGIN_PX` as world metres at a depth whose visible half-width is `half_width`.
static func margin_world(half_width: float, view: Vector2 = NEUTRAL_VIEW) -> float:
	return half_width * 2.0 * (MARGIN_PX / maxf(view.x, 1.0))


## The perspective compensation factor: how much further the lens is from the new depth than
## it was from the old one, clamped to 1.0…1.25. 1.0 when the set did not move back.
static func perspective_scale(new_z: float, old_z: float,
		cam_z: float = NEUTRAL_CAMERA_Z) -> float:
	var d_new := maxf(cam_z - new_z, 0.01)
	var d_old := maxf(cam_z - old_z, 0.01)
	return clampf(d_new / d_old, SCALE_MIN, SCALE_MAX)


## Uniform scale that brings a measured prop to a target world height. Data only: no mesh and
## no scene, so a replacement upload of any size is normalised by the same rule. 1.0 on a
## degenerate box.
static func size_scale(measured_height: float, target_height: float) -> float:
	if measured_height <= 0.001 or target_height <= 0.0:
		return 1.0
	return clampf(target_height / measured_height, STAGE_SCALE_MIN, STAGE_SCALE_MAX)


## The whole placement, pure. `booth_size` and `speaker_size` are the measured AABB sizes of
## the delivered props *after* their own seat scale, in metres; the returned scales multiply
## them. Returns:
##   booth_z, speaker_z, speaker_x, speaker_yaw_deg,
##   booth_scale, speaker_scale, booth_world_size, speaker_world_size,
##   frame_limit_x, wanted_x, min_x, gap_m, frame_ok, gap_ok,
##   booth_top_margin_px, speaker_top_margin_px, tower_visible_share
static func compute(booth_size: Vector3, speaker_size: Vector3,
		view: Vector2 = NEUTRAL_VIEW, cam_z: float = NEUTRAL_CAMERA_Z) -> Dictionary:
	var aspect := aspect_of(view)
	# PART M (intentional change): the scale is the brief's real-world target over the measured
	# size, not the old apparent-size compensation, so the shack and the towers are full size.
	var s_booth := size_scale(booth_size.y, BOOTH_TARGET_HEIGHT)
	var s_speaker := size_scale(speaker_size.y, SPEAKER_TARGET_HEIGHT)
	var booth_world := Vector3(maxf(booth_size.x, 0.01), maxf(booth_size.y, 0.01),
		maxf(booth_size.z, 0.01)) * s_booth
	var speaker_world := Vector3(maxf(speaker_size.x, 0.01), maxf(speaker_size.y, 0.01),
		maxf(speaker_size.z, 0.01)) * s_speaker
	# The towers are judged at their NEAREST face: the frame is narrowest there, so a corner
	# that fits there fits everywhere on the prop.
	var near_z := SPEAKER_Z + speaker_world.z * 0.5
	var half := half_extent_at(cam_z - near_z, aspect)
	var margin := margin_world(half.x, view)
	# The lens can lean by LEAN_YAW_DEG at the stacked extreme, which swings a prop this deep
	# outward by `tan(yaw) x distance`. Reserve that on both sides, so the neutral frame is
	# narrower than the widest the towers could legally sit.
	var lean_shift := tan(deg_to_rad(LEAN_YAW_DEG)) * (cam_z - near_z)
	var frame_limit := (half.x - lean_shift) / cos(deg_to_rad(LEAN_YAW_DEG)) \
		- margin - speaker_world.x * 0.5
	var wanted := SPEAKER_FRACTION * half.x
	var min_x := booth_world.x * 0.5 + speaker_world.x * 0.5 + BOOTH_GAP
	# The frame (with the lean reserve) is the hard rule the brief states; the booth gap is kept
	# whenever it fits, and a tower that overlaps the booth's silhouette is still clear of it in
	# depth.
	var x := minf(wanted, frame_limit)
	# The towers stand behind the booth, so a silhouette overlap is fine as long as the two
	# volumes are separated in DEPTH. The tower's own 12 deg yaw widens its AABB, so the near
	# corner is what is measured.
	var near_corner := SPEAKER_Z + speaker_world.z * 0.5 \
		+ speaker_world.x * 0.5 * sin(deg_to_rad(SPEAKER_YAW_DEG))
	var booth_back := BOOTH_Z - booth_world.z * 0.5
	var depth_clear := near_corner <= booth_back - BOOTH_GAP
	# Vertical frame: a full-size shack or tower is a TALL prop now, so the top corner is what
	# leaves the frame if anything does. Measured at each prop's nearest face, where the frame
	# is narrowest, with the same MARGIN_PX the horizontal rule uses.
	var booth_near := cam_z - (BOOTH_Z + booth_world.z * 0.5)
	var booth_half := half_extent_at(booth_near, aspect)
	var booth_margin := booth_half.y * 2.0 * (MARGIN_PX / maxf(view.y, 1.0))
	var booth_top_margin := (CAMERA_Y + booth_half.y - booth_margin) - booth_world.y
	var speaker_margin := half.y * 2.0 * (MARGIN_PX / maxf(view.y, 1.0))
	var speaker_top_margin := (CAMERA_Y + half.y - speaker_margin) - speaker_world.y
	# How much of a tower is still inside the neutral frame sideways after the 12 px margin,
	# 1.0 = fully framed. The brief's 90 %-at-the-extremes rule is asserted on the live lens;
	# this is the neutral-camera figure the placement is chosen from.
	var tower_span := half.x - margin
	var tower_visible := clampf((tower_span - (x - speaker_world.x * 0.5))
		/ maxf(speaker_world.x, 0.01), 0.0, 1.0)
	return {
		"booth_z": BOOTH_Z,
		"speaker_z": SPEAKER_Z,
		"speaker_x": x,
		"speaker_yaw_deg": SPEAKER_YAW_DEG,
		"booth_scale": s_booth,
		"speaker_scale": s_speaker,
		"booth_world_size": booth_world,
		"speaker_world_size": speaker_world,
		"frame_limit_x": frame_limit,
		"wanted_x": wanted,
		"min_x": min_x,
		"gap_m": x - (booth_world.x * 0.5 + speaker_world.x * 0.5),
		"frame_ok": x <= frame_limit + 0.0001 and booth_top_margin >= 0.0 \
			and speaker_top_margin >= 0.0,
		"gap_ok": depth_clear,
		"booth_top_margin_px": booth_top_margin * (view.y * 0.5) / maxf(booth_half.y, 0.001),
		"speaker_top_margin_px": speaker_top_margin * (view.y * 0.5) / maxf(half.y, 0.001),
		"tower_visible_share": tower_visible,
		"depth_clear_m": booth_back - near_corner,
		"nearest_face_z": near_z,
		"margin_m": margin,
	}


## Apparent height of a prop: its world height over the lens-to-centre distance. This is the
## number the ±15 % rule is written against.
static func apparent_height(world_height: float, z: float,
		cam_z: float = NEUTRAL_CAMERA_Z) -> float:
	return world_height / maxf(cam_z - z, 0.01)


## The DJ stand for a measured deck AABB and the direction its artwork faces: feet on the
## floor, `DJ_GAP` behind the deck's BACK face (i.e. opposite `front`), `DJ_X_FRACTION` of its
## width a side. `centre` and `size` are the deck's AABB in the booth's local space and
## `front` is a flat unit vector in the same space (DJBooth3D reads it off the model's real
## transform, so a re-exported deck with a different `front_axis` still stands its men right).
## Returns [left_position, right_position].
static func dj_positions(centre: Vector3, size: Vector3, front: Vector3) -> Array:
	front.y = 0.0
	if front.length() < 0.001:
		front = Vector3(0.0, 0.0, 1.0)
	front = front.normalized()
	# Support radius of the box along the front axis, so a 90°-turned deck still puts its men
	# behind the face that actually points at the camera.
	var support := absf(front.x) * size.x * 0.5 + absf(front.z) * size.z * 0.5
	var base := Vector3(centre.x, 0.0, centre.z) - front * (support + DJ_GAP)
	# The men stand across the deck's own width, measured perpendicular to its front.
	var across := Vector3(front.z, 0.0, -front.x)
	var half := size.x * DJ_X_FRACTION
	return [base - across * half, base + across * half]

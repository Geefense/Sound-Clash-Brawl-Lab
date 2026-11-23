class_name StageSilhouette
extends MeshInstance3D
## One camera-facing 2.5D silhouette body (owner playtest, 2026-11-23).
##
## Replaces the capsule/cylinder mannequins that stood in for real character art: a single
## quad, two triangles, wearing the mask material painted by `SilhouetteArt`. The quad is
## anchored at the feet (`center_offset` lifts the mesh so local y 0 is the floor), which
## keeps the crowd rows and the DJ booth standing on the same ground line as the fighters.
##
## Swapping the acting pose only swaps the material handle — the mask textures themselves
## are shared and cached — so a whole bank changing its mind costs no allocation per frame.
## When real rigged `.fbx` characters land, `CharacterModelSlots` hides this node and shows
## the imported model instead; nothing in the arena has to change.

var art_set: String = "crowd"
var variant: int = 0
var body_height: float = 1.72
var pose: StringName = &"idle"

var _quad: QuadMesh


## `set_name` is "crowd" or "dj"; `height` is the figure's world height in metres.
func configure(set_name: String, art_variant: int, height: float) -> void:
	art_set = set_name
	variant = art_variant
	body_height = maxf(height, 0.4)
	_quad = QuadMesh.new()
	_quad.size = Vector2(body_height * 0.5, body_height)
	_quad.center_offset = Vector3(0.0, body_height * 0.5, 0.0)
	mesh = _quad
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 2.0
	set_pose(&"idle")


func set_pose(next: StringName) -> void:
	if pose == next and material_override != null:
		return
	pose = next
	material_override = SilhouetteArt.material_for(art_set, variant, next)


## Feet stay planted; the caller moves y for a hop and rotation.z for a lean.
func hop(amount: float) -> void:
	position.y = maxf(amount, 0.0)


func lean(radians: float) -> void:
	rotation.z = radians


func squash(amount: float) -> void:
	var value := clampf(amount, -0.25, 0.25)
	scale = Vector3(1.0 + value, 1.0 - value, 1.0)

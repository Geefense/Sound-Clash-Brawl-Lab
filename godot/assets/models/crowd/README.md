# Crowd character slot

Delivered 2026-11-23 from the owner's 45-file Mixamo upload on `feature/3d-cel-shaded`:
`Crowd Male Angry Gesture`, `Crowd Male Cheering` and `Crowd Male Rallying`.
The untouched owner originals are archived at `art-source/mixamo/crowd/`; the files here are
the weight-aware decimated game copies.

- Each model is a **68-bone `mixamorig` rig** with one animation take and **3 491 triangles**
  (from 10 220), produced with `godot/tools/decimate_mixamo_blender.py`. The collapse
  interpolates vertex groups, so the skinning, armature, materials and take all survive.
- Embedded textures are extracted to `*_0.png`, `*_1.png`, `*_2.png` and import lossless
  (`compress/mode=0`) with mipmaps, matching the fighter albedo policy.
- `CrowdController3D` fills only the **ringside row** (8 bodies, 4 per bank). The back rows
  keep the rim-lit silhouettes, so the yard never pays for 20 full characters on a Chromebook.
- Acting is event-driven: the shared `mixamorig` clip library is installed on every character
  (filename role: `cheer` → Cheering, `angry` → Angry Gesture, `rally` → Rallying) and
  `CrowdController3D` crossfades 0.12 s into the clip a state calls for. Neutral plays each
  character's own take.
- Every surface gets the Spatial Toon shader plus the inverted-hull ink `next_pass`; the left
  bank is warm, the right bank cool, and each body gets a small tint/hue break-up because the
  delivered takes share one Mixamo character skin.
- Flags, lighters and airhorns are reparented to `mixamorig_RightHand` with a
  **BoneAttachment3D**, so they ride the real poses instead of hovering beside a body.
- Author future characters facing +Z (Mixamo's default) so they face the arena camera.

Only three of the seven crowd uploads reached this workspace; the four `Crowd female …`
files were not delivered and stay [TODO]. See `AGENTS.md` §9 for the delivery gap.

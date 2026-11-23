# DJ character slot

Delivered 2026-11-23: two animated selectors behind the decks, taken from the owner's Mixamo
crowd upload (`Crowd Male Cheering` and `Crowd Male Rallying`). The 45-file upload contained
**no DJ-specific character**, so these two are decimated copies of the best-fitting delivered
crowd takes rather than invented art. Untouched originals are archived at
`art-source/mixamo/crowd/`.

- 68-bone `mixamorig` rig, one take each, **3 491 triangles** (from 10 220) via
  `godot/tools/decimate_mixamo_blender.py`; textures extracted as `*_0/1/2.png` and imported
  lossless with mipmaps.
- `DJBooth3D` fills both slots in sorted filename order and hides the silhouette DJs.
- The booth state machine crossfades 0.12 s into the shared acting clips:
  `point` / `airhorn` → hype (Rallying), `celebrate` → cheer (Cheering),
  `disbelief` → Angry Gesture, `idle` / `fader` → the selector's own loop.
- The airhorn prop is parented to `mixamorig_RightHand` with a **BoneAttachment3D**, so it
  lifts with the real hype poses.
- Every surface uses the toon shader + ink outline with the booth's gold rim.
- Author future DJ characters facing +Z (Mixamo's default) and keep them ≤3 500 triangles.

Dedicated DJ art remains [TODO]; replacing these two files needs no code change.

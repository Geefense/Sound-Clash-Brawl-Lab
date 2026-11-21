# 3D fighter models — inventory and import contract

Moved here from the `stage/sound-clash-sand` repository root on 2026-11-21. The originals are
immutable owner uploads; nothing in this folder is re-authored art.

| File | Source upload | Bytes | Mesh | Rig | Clip | Texture |
| --- | --- | --- | --- | --- | --- | --- |
| `feedback_fighting_idle_rigged.fbx` | `Fighting Idle (1).fbx` | 4,788,128 | 40,000 triangles / 26,215 vertices | Mixamo skeleton, **25 bones** (`mixamorig_Hips` … `mixamorig_RightToe_End`) | `mixamo_com`, **3.30 s**, 21 bone tracks | embedded 4096² atlas, skipped (see below) |
| `lickshot_placeholder_static.fbx` | `c534c936-46ff-4878-8dc5-e96053704264 (2).zip` → `output.fbx` | 4,142,476 | 40,000 triangles / 26,215 vertices | **none** | **none** | `feedback_fitted_jacket_albedo.jpg` (shared) — **archived, not assigned** |
| `feedback_fitted_jacket_albedo.jpg` | same zip → `textured_mesh.jpg` | 2,550,454 | — | — | — | 4096² source, imported at 2048² with mipmaps |

**Important:** both uploads are the *same Feedback mesh*. The vertex count, AABB
(`0.013823 × 0.019946 × 0.004597` authored units) and material name are identical; one export
keeps the Mixamo rig and its single idle clip, the other is a static bake with the texture.
There is no second character in this upload, and no Walk/Attack/Block/Hit/Knockdown clips yet.

## Wiring

- **Feedback** uses the rigged upload. The baked idle clip plays as the base; the eight fight
  states are layered additively on the skeleton by `FighterModel3D.gd` (guard arms, strike
  lunge/arm, spine recoil, walk leg swing, crouch, taunt, celebration), because no per-state
  Mixamo tracks exist yet.
- **Both P1 and P2 Feedback** use the rigged upload. `MatchSetup` defaults to FEEDBACK vs
  FEEDBACK, and in a mirror match `FighterModel3D.set_mirror_variant(true)` gives **P2** a cool
  jacket tint (`0.80, 0.90, 1.10`), a small hue shift and a gold rim (`1.0, 0.70, 0.26`) while
  P1 keeps the warm cream rim (`1.0, 0.88, 0.62`). This is presentation only.
- **Lickshot** no longer uses the static mesh. `FighterModel3D.MODEL_SOURCES` has no
  `lickshot` entry, so he renders as a camera-facing `Sprite3D` billboard from his approved
  2D sprites until his own rigged model is uploaded. `lickshot_placeholder_static.fbx` is
  **archived for reference only** and must not be assigned to a fighter again.
- **L!kkle Moore** has no 3D upload and keeps his approved 2D art as a camera-facing
  `Sprite3D` billboard on the same 3D plane.

## Import contract

- `fbx/embedded_image_handling=0` for both FBX files: the embedded 4096² images are skipped,
  and the material override uses the shared 2048² albedo (memory and WebGL2 texture unit
  budget). `materials/extract=0`.
- The albedo import is capped with `process/size_limit=2048`, `mipmaps/generate=true` and
  `detect_3d/compress_to=0`. The Web export keeps `import_etc2_astc=false`.
- Runtime normalisation measures the model's own skeleton/AABB and scales it to 1.55 m
  (Feedback) / 1.58 m (Lickshot), seating the feet at world y 0. Do not hand-scale the FBX.
- The roughness PNG from the zip is provenance only, not a game asset:
  `artifacts/sound-clash/art-source/models/feedback_upload_roughness.png`
  (SHA-256 `6ff0a46db38931c43f53175f407a26a5727f49de8682fcafedcb65ae9f9dd163`).

## Checksums (SHA-256)

```
c590259b64edca1789e6166bcb6f04b2780ad9e0854a123c92fdcc43e273d2c6  feedback_fighting_idle_rigged.fbx
8ea6acb8537dfaa66ba49d39c3cc7b559b044b805fd8f2061bb202e4ca606322  lickshot_placeholder_static.fbx
c4cb0ff407806b37efacd49e485b8c33211fc08a3e9bb26068bbe4af30c1cb7c  feedback_fitted_jacket_albedo.jpg
```

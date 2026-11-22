# 3D fighter models — inventory and import contract

Updated 2026-11-22 with the owner's three uploaded fighter models. The originals are immutable
owner uploads; nothing in this folder is re-authored art. The first two Feedback-era uploads stay
here as archived provenance only.

## Playable uploads (2026-11-22)

| File | Original upload | Bytes | Mesh | Rig | Face (+axis) | Albedo |
| --- | --- | --- | --- | --- | --- | --- |
| `feedback_v2.fbx` | `feedbackglb2-v1.fbx` | 2,675,148 | **29,025 tris** / 23,612 verts | **none** (static) | **+Z** | embedded 1024² PNG, **RGBA** |
| `lickshot.fbx` | `Lickshotglb1-v1.fbx` | 9,699,116 | **270,074 tris** / 151,028 verts | **none** (static) | **+X** | embedded 1024² PNG, RGB |
| `likkle_moore.fbx` | `LikkleMooreglb1-v1.fbx` | 8,859,244 | **246,654 tris** / 139,168 verts | **none** (static) | **+X** | embedded 1024² PNG, RGB |

Each file is **FBX 7.4 binary** written by ImageToStl (GLB→FBX) and contains exactly one mesh
surface, one Phong material and no skeleton, skin or animation stack. The root node carries a ×1000
`Lcl Scaling` and `UnitScaleFactor = 0.1`; the assembled model is **1.0 m tall** before the game's
normalisation.

### Texture status — no WebP in these uploads

The embedded `Video/Content` blobs were inspected byte-by-byte: all of them are standard PNG
(`\x89PNG\r\n\x1a\n`), 1024 × 1024, 8-bit, colour type 6 (RGBA, Feedback) or 2 (RGB, the other two).
There is **no WebP or RIFF data**, so the earlier WebP-compression concern does not apply to this
upload set.

Feedback also embeds two 1024² greyscale channel maps (`image0_g`, `image0_b`) linked to
shininess/metalness. They are provenance only; the toon shader does not read them. Godot's FBX
import skips **all** embedded images (`fbx/embedded_image_handling=0`) so the PCK does not carry a
duplicate atlas; the albedo is loaded from the extracted file below.

Extracted, normalised albedos (alpha forced to fully opaque RGBA8 so every upload imports the same
way):

| File | Size | Format |
| --- | --- | --- |
| `feedback_v2_albedo.png` | 1,578,238 B | 1024² RGBA8 |
| `lickshot_albedo.png` | 1,575,391 B | 1024² RGBA8 |
| `likkle_moore_albedo.png` | 1,428,867 B | 1024² RGBA8 |

Import: `compress/mode=0` (lossless), `mipmaps/generate=true`,
`detect_3d/compress_to=0` — Godot keeps standard RGBA instead of swapping in a VRAM-compressed
ETC2/ASTC texture that would muddy the baked colours on the WebGL2 target.

## Wiring

- `FighterModel3D.MODEL_SOURCES` maps the roster keys to the files:
  `feedback → feedback_v2.fbx`, `lickshot → lickshot.fbx`,
  `young_selecta → likkle_moore.fbx` (L!kkle Moore keeps his roster key and sprite folder).
- **All three render as real 3D geometry.** L!ckshot and L!kkle Moore no longer use a
  `Sprite3D` billboard; `Arena3D._make_fighter()` finds a `MODEL_SOURCES` entry for every slot and
  only falls back to `FighterBillboard3D` if a future upload is missing.
- Heights: Feedback 1.55 m, L!ckshot 1.58 m, L!kkle Moore 1.27 m (82 % kid proportion).
- Facing: Feedback is authored facing +Z and gets `yaw_offset = 0`; the two Tripo exports face +X
  and get `-90°`, so `yaw_offset + facing × 90°` turns every model onto the 2.5D fighting axis.
- Because the uploads have no skeleton, the fight motion is the whole-body procedural layer:
  idle bob, walk lean, strike lunge, hit recoil, crouch squash, throw spin and the knockdown/KO
  tip. `_animate_rig()` remains for a future rigged upload but idles out on these three.
- Materials are the Spatial Toon cel shader plus the inverted-hull ink `next_pass` (dark outline,
  directional rim band) on every surface. P2 in a mirror match gets the cool jacket tint
  (`0.80, 0.90, 1.10`), a small hue shift and the gold rim (`1.0, 0.70, 0.26`); P1 keeps white and
  its warm cream rim.
- `FighterModel3D._normalize()` measures the AABB **through each node's transform**, then scales
  the assembled model to its authored height and seats its lowest bound on world y 0. Measuring
  the raw mesh AABB would have normalised the ×1000 root scale 1000× too large.

## Archived (not assigned to any fighter)

| File | Bytes | Contents | Status |
| --- | --- | --- | --- |
| `feedback_fighting_idle_rigged.fbx` | 4,788,128 | 40,000 tris, 25-bone Mixamo rig, 3.30 s `mixamo_com` idle | Archived reference |
| `lickshot_placeholder_static.fbx` | 4,142,476 | 40,000 tris, static bake of the old Feedback mesh | Archived, never re-assign |
| `feedback_fitted_jacket_albedo.jpg` | 2,550,454 | 4096² JPEG albedo for the old mesh | Archived |

## Mixamo-ready copies

`models-for-mixamo/` (repository root, outside the game build) holds
`feedback_mixamo_ready.fbx`, `lickshot_mixamo_ready.fbx` and `likkle_moore_mixamo_ready.fbx`.
They are byte-for-byte the upload geometry with the embedded PNG atlas untouched; only the root
`Lcl Scaling` and `UnitScaleFactor` were rewritten so the adults import at **180 cm** and the kid
at **128 cm** with 1 unit = 1 cm. See that folder's `README.md` for checksums and the reason.

## Verification

- `godot --headless --path godot --import` imports all three with only the known ufbx
  "Bad UTF-8 string" warnings from the ImageToStl writer (non-fatal, no missing resources).
- `godot --headless --path godot --script res://tools/headless_roster_check.gd` — **255 PASS /
  0 FAIL**, including: each file + albedo exists, each loads as a `FighterModel3D` with the
  expected triangle count, each albedo is 1024² RGBA8, each model is seated feet-down at its
  authored height, each material carries the ink `next_pass`, the procedural lunge follows facing
  and the knockdown tips the mesh, and L!ckshot/L!kkle Moore are no longer billboards.

**Not verified:** there is no GPU or display in the authoring environment, so the rendered cel
look, ink width, rim strength, texture orientation on screen, mirror tint and the actual frame rate
of the 270k/247k-triangle meshes have not been seen. The 29k/270k/247k triangle budgets are as
uploaded; the Web build enables Godot's generated LODs, but a real Chromebook measurement is still
needed before these are treated as shipping-cost-free.

## Checksums (SHA-256)

```
041bdab296547f33316cfabc595b923e90158e363236df7ad08885235a73e24e  feedback_v2.fbx
23f172828505fb87a308c2164ac565b9534a030417cbb323da4226815ef750ae  lickshot.fbx
b9ffd4b60f8e27a5516f4cade806d346a1e8265b0b58feea405551282c9588c3  likkle_moore.fbx
9a48b85aa52524d7d6f3b57061d8e7e1d5f2afbb791226099d7c4111834f3650  feedback_v2_albedo.png
8cbfd386157299bd6511d4463f4ce48078d4a3e8f96ce61d9f931487723b126b  lickshot_albedo.png
62003cd25d880935b7de6442f0e750affe89a626f1fd1b5f578183f78141396d  likkle_moore_albedo.png
c590259b64edca1789e6166bcb6f04b2780ad9e0854a123c92fdcc43e273d2c6  feedback_fighting_idle_rigged.fbx
8ea6acb8537dfaa66ba49d39c3cc7b559b044b805fd8f2061bb202e4ca606322  lickshot_placeholder_static.fbx
c4cb0ff407806b37efacd49e485b8c33211fc08a3e9bb26068bbe4af30c1cb7c  feedback_fitted_jacket_albedo.jpg
```

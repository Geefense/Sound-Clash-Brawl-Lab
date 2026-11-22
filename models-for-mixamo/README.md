# Mixamo-ready FBX copies — Sound Clash Brawl

Clean copies of the three uploaded 3D fighters for uploading to Adobe Mixamo (auto-rigger / later
baked combat poses). They are **not loaded by the game**; the game uses
`godot/assets/models/fighters/*.fbx`.

| File | Geometry / texture | Scale on import |
| --- | --- | --- |
| `feedback_mixamo_ready.fbx` | 29,025 tris, 1024² RGBA PNG albedo | 180 cm |
| `lickshot_mixamo_ready.fbx` | 270,074 tris, 1024² RGB PNG albedo | 180 cm |
| `likkle_moore_mixamo_ready.fbx` | 246,654 tris, 1024² RGB PNG albedo | 128 cm |

## What was changed

The owner uploads are FBX 7.4 binaries from ImageToStl. They already contain a **standard PNG
albedo embedded in the FBX** (`Video/Content`, 1024 × 1024, 8-bit) with a `DiffuseColor` /
`Maya|baseColor` connection to the material — no WebP, no external image dependency. Mixamo shows
the full colour from the embedded image.

Only two scale records were rewritten, in place, without touching geometry, UVs, normals or the
embedded texture bytes:

- root model `Lcl Scaling`: `1000` → `180` (adults) / `128` (L!kkle Moore)
- `GlobalSettings → UnitScaleFactor`: `0.1` → `1.0` (1 unit = 1 cm)

The original hierarchy would have imported as a 1000-unit-tall object; these copies arrive as
1.8 m and 1.28 m characters, which is what Mixamo expects when placing a rig. Mixamo can still
override character height in the upload dialog.

## Uploading

1. Upload one `.fbx` at <https://www.mixamo.com/> → *Upload Character*.
2. Confirm the texture/colour is visible (it is embedded; do not upload a separate image).
3. Place the auto-rig markers (these are A-pose meshes with no skeleton, which is expected).
4. Download the rigged character, then the desired animation FBX for the game pipeline.

The two adults are 1.8 m; L!kkle Moore is a 1.28 m kid. Keep them on separate Mixamo characters so
their heights are not normalised to each other.

## Checksums (SHA-256)

```
b9d9e7551f5397e37262e521cb02eb5991005bceefef689fac0abe1daac83f29  feedback_mixamo_ready.fbx
2d9dee22d8adfade920397bca9138440066d5f8a5d60ab6758b428e233042542  lickshot_mixamo_ready.fbx
ceafe85a49bf56be9e9dbfe5ec558a64f8b7ffa02ce319843176fd7c88ae99cd  likkle_moore_mixamo_ready.fbx
```

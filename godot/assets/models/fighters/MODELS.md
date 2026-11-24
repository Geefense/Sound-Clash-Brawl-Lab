# 3D fighter models — inventory and import contract

Updated 2026-11-22 (second pass): the three owner uploads are playable, and L!ckshot and
L!kkle Moore have been decimated to a 28,000-triangle game budget. The originals were immutable
owner uploads; the decimation only rebuilds the mesh geometry and keeps every other FBX node,
including the embedded atlas. The first two Feedback-era uploads stay here as archived
provenance only.

## Playable uploads (2026-11-22)

| File | Original upload | Bytes | Mesh | Rig | Face (+axis) | Albedo |
| --- | --- | --- | --- | --- | --- | --- |
| `feedback_v2.fbx` | `feedbackglb2-v1.fbx` | 2,675,148 | **29,025 tris** / 23,612 verts | **none** (static) | **+Z** | embedded 1024² PNG, **RGBA** |
| `lickshot.fbx` | `Lickshotglb1-v1.fbx` | 3,003,222 | **28,000 tris** / 20,797 verts (was 270,074 / 151,028) | **none** (static) | **+X** | embedded 1024² PNG, RGB |
| `likkle_moore.fbx` | `LikkleMooreglb1-v1.fbx` | 2,888,610 | **28,000 tris** / 20,825 verts (was 246,654 / 139,168) | **none** (static) | **+X** | embedded 1024² PNG, RGB |

Each file is **FBX 7.4 binary** written by ImageToStl (GLB→FBX) and contains exactly one mesh
surface, one Phong material and no skeleton, skin or animation stack. The root node carries a ×1000
`Lcl Scaling` and `UnitScaleFactor = 0.1`; the assembled model is **1.0 m tall** before the game's
normalisation. The rebuilt L!ckshot / L!kkle Moore files keep the same header, node tree, material,
texture, video blob and connections; only the `Geometry` children were replaced.

### Decimation (2026-11-22)

Both large uploads were reduced to exactly **28,000 triangles** to match Feedback's smooth 29k
budget and keep WebGL2 load/frame cost predictable on Chromebook and iPhone Safari.

- Tool: `godot/tools/decimate_fbx.py`. It parses the FBX geometry, round-trips the control points
  and per-corner UVs through a temporary OBJ, runs pymeshlab's
  `meshing_decimation_quadric_edge_collapse_with_texture`, and serialises the decimated arrays back
  into the original FBX node tree.
- Settings: target 28,000 faces, `qualitythr 0.8`, `extratcoordw 0.35`, `optimalplacement`,
  `preservenormal`, `planarquadric`, **no boundary lock** (locking every UV-island border plateaued
  at ~31.8k triangles). The UV atlas is preserved per wedge, so the baked 1024² albedo still maps;
  no texture is resampled, re-encoded or replaced.
- The embedded `Video/Content` PNG is byte-identical (1,418,402 B for L!ckshot, 1,299,084 B for
  L!kkle Moore). The root scale and every non-geometry node are untouched, so the game's
  `_normalize()` still measures **1.58 m** and **1.27 m** in Godot.
- Re-running the tool needs pymeshlab and `libOpenGL.so.0`:
  `LD_LIBRARY_PATH=$PWD/.local-libs/root/usr/lib/x86_64-linux-gnu .venv/bin/python godot/tools/decimate_fbx.py <src> <dst> --target 28000`.
  The local `.venv` and `.local-libs` are build scaffolding and are not part of the game.

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
- **Per-move 3D profiles** (`FighterModel3D.MOVE_STYLES`, 2026-11-22): each fighter has its own
  startup coil and contact drive per attack, using lean, forward lunge, vertical lift, depth pitch
  and yaw twist. Feedback's high Clarks kick lifts and twists; L!ckshot's sonic clap rises behind
  the wave; the kid's home-run swing turns 1.15 rad while the sweep spins the other way at 80 %
  height. The grab gets a forward collar lunge, and the three taunts use different leans/bounce.
  None of these values are read by a hitbox, hurtbox or timing.
- **Signature effects** — `BaseFighter` emits `attack_became_active` and `projectile_spawned`.
  `TestArena` maps those cues to `Arena3D` set pieces: the 3D dubplate/dictionary prop, sand
  bursts, Rasta note trails, speaker-cone punches and the gold/black vinyl Record Static Parry.
  The actual special hit is a `ProjectileWave` node: it travels, tests the defender's live
  hurtbox and calls the shared `receive_strike`, so guard, parry, damage, knockback and KO rules
  still resolve in one place.
- Materials are the Spatial Toon cel shader plus the inverted-hull ink `next_pass` (dark outline,
  directional rim band) on every surface. P2 in a mirror match gets the cool jacket tint
  (`0.80, 0.90, 1.10`), a small hue shift and the gold rim (`1.0, 0.70, 0.26`); P1 keeps white and
  its warm cream rim. The parry lights a gold rim for eight ticks.
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
They contain the same geometry, UVs and embedded 1024² PNG atlas as the game files — for the two
new fighters that means the **28,000-triangle decimated mesh**, not the original upload. Only the
root `Lcl Scaling` and `UnitScaleFactor` were rewritten, so the adults open at **180 cm** and the
kid at **128 cm** with 1 unit = 1 cm. See that folder's `README.md` for checksums and the reason.

## Crowd & DJ Mixamo uploads (2026-11-23)

The owner pushed 45 Mixamo `.fbx` files to the root of `feature/3d-cel-shaded` (commit
`a46be08`): 10 Feedback clips, 11 L!ckshot clips, 17 L!kkle Moore clips and 7 `Crowd …`
characters. All are With Skin exports — a 68-bone `mixamorig` rig, one take and embedded
textures — and the set contains **no DJ-specific character**.

**Delivered 2026-11-24.** The owner published all 45 binaries to the GitHub Release
`mixamo-pack`; the 42 that never reached the workspace were downloaded from the release's
`browser_download_url`s and are now wired in. The root-level placeholders were removed. See
"Mixamo pack — fighter rigs and takes" below.

| Game file | Role | Tris | Bones | Take |
| --- | --- | --- | --- | --- |
| `crowd/Crowd Male Angry Gesture.fbx` | crowd disbelief | **3 491** (from 10 220) | 68 | `mixamo_com`, 3.267 s |
| `crowd/Crowd Male Cheering.fbx` | crowd cheer / booth celebrate | **3 491** | 68 | `mixamo_com`, 2.900 s |
| `crowd/Crowd Male Rallying.fbx` | crowd hype / booth point + airhorn | **3 491** | 68 | `mixamo_com`, 6.200 s |

`dj/` holds the Cheering and Rallying copies (same bytes) for the two selector slots, because
the upload has no DJ character. The untouched owner originals are archived at
`art-source/mixamo/crowd/`; the root copies were removed.

### Decimation

`godot/tools/decimate_mixamo_blender.py` runs headless Blender's COLLAPSE Decimate, which
interpolates vertex groups, so the armature, skin weights, materials, embedded textures and
take all survive. The older `decimate_fbx.py` only rebuilds static geometry and would silently
drop the skin clusters. Settings: ratio `3500 / 10220`, triangulate, images packed, FBX export
with `FBX_SCALE_ALL`, `embed_textures`, all actions baked. Output: 1 909 verts / 3 491 tris.
Godot extracts the embedded images to `*_0/1/2.png`, imported lossless
(`compress/mode=0`) with mipmaps.

### Wiring

- **Crowd** — `CrowdController3D.MODEL_ROWS = 1`: the ringside row (8 bodies, 4 per bank)
  gets the real characters, while the back rows keep the 2-triangle painted silhouettes.
  That keeps the yard at **36 310** measured atmosphere triangles (crowd 28 448 + booth
  7 862) under the revised **40 000** cap, with each character checked at ≤3 500.
- **Acting** — `CharacterModelSlots` reads the role from the uploaded filename, builds one
  shared `Animation` per act and installs it on every character (identical track paths:
  `Armature/Skeleton3D:mixamorig_*`). `CrowdController3D` and `DJBooth3D` crossfade 0.12 s
  into cheer / disbelief / hype on their own event cues; neutral plays each character's own
  take. Missing acts fall back to that base loop.
- **Cel** — every surface gets `toon_cel.gdshader` with the upload's own albedo plus the
  `toon_outline.gdshader` inverted hull. Left bank warm, right bank cool, booth gold; the
  three delivered takes share one character skin, so each ringside body also gets a small
  tint/hue break-up (presentation only).
- **BoneAttachment3D** — crowd flags, lighters and airhorns and the booth airhorn are
  reparented under `mixamorig_RightHand`, so props follow the real poses. The DJs' procedural
  bob is disabled when a clip owns the body.
- **DJs** — `DJBooth3D` fills both slots and adds a `disbelief` reaction (the second selector
  answers a knockdown) on top of the existing point / airhorn / celebrate states.

## Verification

- `godot --headless --path godot --import` imports all three with only the known ufbx
  "Bad UTF-8 string" warnings from the ImageToStl writer (non-fatal, no missing resources).
- `godot --headless --path godot --script res://tools/headless_roster_check.gd` — **276 PASS /
  0 FAIL**, including: each file + albedo exists, each loads as a `FighterModel3D` under the
  35,000-triangle budget (29,025 / 28,000 / 28,000), each albedo is 1024² RGBA8, each model is
  seated feet-down at its authored height (1.55 / 1.58 / 1.27 m), each material carries the ink
  `next_pass`, the procedural lunge follows facing and the knockdown tips the mesh, signature
  moves produce separate 3D poses, the dubplate wave spawns its prop and lands through
  `receive_strike`, the sweep's live hurtbox ducks a standing jab, and L!ckshot/L!kkle Moore are
  no longer billboards.
**Crowd/DJ additions to the same run (2026-11-23):** **341 PASS / 0 FAIL**. The new checks
assert that all 10 delivered characters load with a real `mixamorig` skeleton (>20 bones), each
is ≤3 500 triangles (3 491 measured on the character meshes, hand props excluded from the
budget), each carries acting clips with real `AnimationPlayer` tracks (4 clips / 79–89 tracks),
every surface has the toon + ink pass, 6 crowd props and 1 booth airhorn ride a
`BoneAttachment3D` on `mixamorig_RightHand`, the left bank crossfades to `mixamo_cheer` while
the right bank plays `mixamo_disbelief` on a heavy hit, the selectors crossfade to the hype
take when they point, and a settled yard returns to each character's own loop.

**Not verified:** there is no GPU or display in the authoring environment, so the rendered cel
look, ink width, rim strength, texture orientation on screen, mirror tint, the new animated poses,
the 3D disc/book meshes and the actual frame rate have not been seen. The triangle budgets are
verified (28k each, 29k Feedback); a real Chromebook/iPhone Safari frame-time and Safari playback
measurement is still required before calling the 60 FPS target proven. The delivered crowd
characters were also never viewed, the three takes share one Mixamo skin (so the ringside row is
one character with hue break-up), and no fighter Mixamo retarget exists because 42 of the 45
uploaded binaries never reached this workspace.

## Checksums (SHA-256)

```
041bdab296547f33316cfabc595b923e90158e363236df7ad08885235a73e24e  feedback_v2.fbx
2d4a53029323e0c7321f8e34414460a70dbeddbeca92bcea0b319f11e14eca8b  lickshot.fbx
9ef2c6293c5d57066c2e4ac16e55cd0d3fa733c39138f31a01c68c2410ed4681  likkle_moore.fbx
9a48b85aa52524d7d6f3b57061d8e7e1d5f2afbb791226099d7c4111834f3650  feedback_v2_albedo.png
8cbfd386157299bd6511d4463f4ce48078d4a3e8f96ce61d9f931487723b126b  lickshot_albedo.png
62003cd25d880935b7de6442f0e750affe89a626f1fd1b5f578183f78141396d  likkle_moore_albedo.png
c590259b64edca1789e6166bcb6f04b2780ad9e0854a123c92fdcc43e273d2c6  feedback_fighting_idle_rigged.fbx
8ea6acb8537dfaa66ba49d39c3cc7b559b044b805fd8f2061bb202e4ca606322  lickshot_placeholder_static.fbx
c4cb0ff407806b37efacd49e485b8c33211fc08a3e9bb26068bbe4af30c1cb7c  feedback_fitted_jacket_albedo.jpg
```

## Mixamo pack — fighter rigs and takes (2026-11-24)

All 45 release binaries were fetched (622 MB). The key discovery: **every fighter take is not a
bare animation — it is our own fighter mesh skinned to a 65-bone `mixamorig` rig**, so Mixamo's own
skinning is reused instead of auto-binding the static Tripo meshes.

| Game body | Built from | Tris | Bones | Atlas |
| --- | --- | --- | --- | --- |
| `feedback_rigged.fbx` | `Feedback.Fighting.Idle.3.fbx` (29 025 tris already at budget) | 29 025 | 65 | embedded 1024² |
| `lickshot_rigged.fbx` | `Lickshot.Fight.Idle.fbx`, decimated 270 060 → 28 000 | 28 000 | 65 | embedded 1024² |
| `likkle_moore_rigged.fbx` | `LikklleMoore.Idle.fbx`, decimated 246 641 → 28 000 | 28 000 | 65 | embedded 1024² |

`feedback_v2.fbx`, `lickshot.fbx`, `likkle_moore.fbx` stay on disk as the owner's original static
uploads (provenance only; `MODEL_SOURCES` no longer points at them).

### Takes: `godot/assets/models/mixamo/clips/<roster key>/`

Each file is armature + one take only (meshes and textures stripped), ~0.45 MB instead of ~4 MB:

- `feedback/` (10): bencao, body-jab-cross, drunk-walk, elbow-uppercut-combo, fighting-idle-3,
  getting-up, jab-cross, knocked-out-1, right-hook, warrior-idle.
- `lickshot/` (11): bouncing-fight-idle, center-block, falling-back-death, fight-idle, getting-up,
  hook-punch, lead-jab, medium-step-forward, strut-walking, surprise-uppercut, zombie-kicking.
- `young_selecta/` (17): 2hand-idle, back-flip-to-uppercut(-1), crouched-walking,
  flying-knee-punch-combo, idle, jab-to-elbow-punch, kicking, punch-combo, quad-punch, right-hook,
  standing-block-react-large, standing-melee-kick, stumble-backwards(-1), stunned, walking.

`MixamoClips.ROLE_FILES` is the single role → file table (idle, walk, crouch_walk, light, strong,
tump, upper_box, kick, special, block, hit, stun, stumble, knockdown, getup, taunt, victory).
Missing roles walk a fallback chain, so a partial set still animates. Crossfade is 0.10 s.
Track paths are re-pointed at each fighter's measured skeleton path — Feedback's body nests its
skeleton at `Skeleton3D`, the other two at `Armature/Skeleton3D`.

### Hand props

`FighterProps` builds the props at run time (cel shader + inverted-hull ink) and parents them to a
`BoneAttachment3D` on the right-hand bone:

| Fighter | Props |
| --- | --- |
| Feedback | wireless stage microphone |
| L!ckshot | wireless stage microphone |
| L!kkle Moore | microphone stand **and** the dictionary |

The bone is resolved by suffix (`…RightHand`), because two of the decimated female rigs kept an
exporter tag such as `mixamorig8_RightHand`.

### Female crowd models

| File | Source | Tris | Bones | Atlas |
| --- | --- | --- | --- | --- |
| `Crowd female Dancing Twerk.fbx` | 52 838 → decimated | 3 393 | 65 | 512² |
| `Crowd female Hip Hop Dancing.fbx` | 54 961 → decimated | 3 484 | 65 | 512² |
| `Crowd female Moonwalk.fbx` | 28 106 → decimated | 3 399 | 65 | 512² |
| `Crowd female Snake Hip Hop Dance.fbx` | 54 961 → decimated | 3 484 | 65 | 512² |

They sit beside the three male spectators, so `CrowdController3D`'s ringside row now cycles
male / male / male / female / female / female / female and mixes both banks. Building them:
`decimate_mixamo_blender.py <src> <dst> 3400 512` (the fourth argument downscales the 4 096²
atlases to 512² — without it each model added ~50 MB to the web export).

### Reproducing

```bash
blender --background --factory-startup --python godot/tools/strip_anim.py -- <clip.fbx> <dst.fbx>
blender --background --factory-startup --python godot/tools/decimate_mixamo_blender.py -- \
    <src.fbx> <dst.fbx> 28000 1024        # fighter body
    <src.fbx> <dst.fbx> 3400 512          # female crowd
```

`retarget_mixamo_blender.py` is still shipped for a future upload that arrives as an unrigged
mesh; the delivered pack did not need it.

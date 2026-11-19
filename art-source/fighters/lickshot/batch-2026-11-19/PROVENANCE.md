# L!ckshot animation batch — 2026-11-19

Creator-approved animation sources uploaded by Garfield Connell to the root of
`stage/sound-clash-sand` in commit `838495caa` ("Add files via upload"), moved here
unchanged so the repository root stays clean. Originals are immutable; the game-ready
frames are generated from them by `art-source/fighters/prep_lickshot_poses.py --batch
2026-11-19` into `godot/assets/sprites/lickshot/`.

| File | What it is | Wired to |
| --- | --- | --- |
| `16_walk-sheet-clean_original.png` | 1792 × 2390, **2 rows × 2 poses on pure `#FFFFFF`**: full Kangol cap crowns, complete Clarks Wallabee toes and generous white margin on all four sides. Uploaded later to the root of `stage/sound-clash-sand` as `IMG_6654.jpeg` (commit `db85686`) and stored here as PNG (lossless decode; no pixel retouching). Reading order top-left → top-right → bottom-left → bottom-right. | `walk` — the 4-frame stride cycle at 9 fps, looping (replaces the clipped phone-video frames) |
| `lickshot_bossy_walk_phone.mov` | 3.0 s, 30 fps, 694 × 928 signature selector walk (a held-pose cycle; 15 distinct drawings). **Superseded as the walk source:** the phone crop cuts the hat crown and one boot in every frame. | Archived provenance only; no longer referenced by the roster |
| `IMG_6636.jpeg` | 8-pose lean-back / skank sheet, 2 rows × 4, pure `#FFFFFF` | `skank_1` … `skank_8` — the full T skank/taunt groove |
| `IMG_6643.jpeg` | 12-pose hit / launch / knockdown sheet, 3 rows × 4, pure `#FFFFFF` | see below |
| `IMG_6644.jpeg` | single airborne C-recoil launch pose, same build and palette as the 12-pose sheet | `launched` frame 1 |

12-pose sheet wiring (row-major):

* top row 1–4 → `hitstun` (standing recoil)
* middle row 5–6 → `launched` (with the single C-recoil as frame 1); 7–8 → `tumble`
* bottom row 9–10 → `knockdown`; 11–12 → `ko`

## Preparation rules

* **Background:** pure white means "every channel ≥ 236 and saturation ≤ 14". Treating the
  white as background wherever it sits removes the flat backdrop *and* the white pocket
  sealed inside the mic-cable loop, without a flood fill. The black mic cord, cream Clarks
  soles, silver mic grille and gold chain are all far below the threshold, so they survive.
* **Cap:** longest side of every processed frame ≤ 512 px (the project import cap).
* **Floor:** every standing, airborne and grounded frame is placed in a canvas whose lowest
  alpha row sits on world **y = 592** (`BaseFighter.REACTION_FLOOR_Y`) once the roster's
  `anim_offset`/`anim_scale` are applied — on the sand, never through it.
* **Scale:** `anim_scale = 121.75 / reference standing height` in the source's own pixels,
  so L!ckshot stays the same on-screen size from idle through a knockdown. The single
  C-recoil upload is rendered about 1.98× larger than the 12-pose sheet (measured on the
  silver mic grille, 37 × 33 px vs 19 × 14 px), so it is resampled into the sheet's pixel
  scale before joining `launched`.
* **Walk sheet:** sliced by connected drawing, not a straight 2 × 2 crop — the top row's
  boots pass below the vertical midpoint and neighbouring bounding boxes overlap, so a
  quadrant cut would chop a Wallabee. The four drawings are composed onto **one 454 × 512
  shared canvas**: every sole on row 510, measured spread **[510, 510] → 0 px vertical
  sole bobbing**, then capped at 512 px. The black cord loop, silver mic grille and cream
  Wallabee soles survive the white key. Wired at **9 fps**, looping.
* **Walk frames (superseded):** the previous pass took 6 of the phone video's distinct held
  poses with clipped frames rejected. Those outputs (`walk/05.png`, `walk/06.png`) and
  their import sidecars are removed; the video itself stays archived above as provenance.

## Status

Processed and wired as presentation-only animation. Combat timings, hitboxes, damage and
the FSM are unchanged. Owner visual approval of the wired result is still pending; the
manifest of measured offsets/scales lives in `art-source/fighters/lickshot/prep-report.json`.

# L!ckshot animation batch — 2026-11-19

Creator-approved animation sources uploaded by Garfield Connell to the root of
`stage/sound-clash-sand` in commit `838495caa` ("Add files via upload"), moved here
unchanged so the repository root stays clean. Originals are immutable; the game-ready
frames are generated from them by `art-source/fighters/prep_lickshot_poses.py --batch
2026-11-19` into `godot/assets/sprites/lickshot/`.

| File | What it is | Wired to |
| --- | --- | --- |
| `lickshot_bossy_walk_phone.mov` | 3.0 s, 30 fps, 694 × 928 signature selector walk (a held-pose cycle; 15 distinct drawings) | `walk` — the 6 extracted stride frames replace the recycled idle walk |
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
* **Walk frames:** 6 of the video's distinct held poses, evenly spaced over the cycle, with
  frames clipped by the phone-video crop rejected. The video contains no in-between
  drawings, so no frames are invented.

## Status

Processed and wired as presentation-only animation. Combat timings, hitboxes, damage and
the FSM are unchanged. Owner visual approval of the wired result is still pending; the
manifest of measured offsets/scales lives in `art-source/fighters/lickshot/prep-report.json`.

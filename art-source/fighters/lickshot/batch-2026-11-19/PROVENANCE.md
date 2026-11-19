# L!ckshot — 2026-11-19 upload batch

Four creator-approved L!ckshot animation uploads, moved off the repository root with `git mv`
(byte-identical) into this folder. Preparation: `art-source/fighters/prep_lickshot_poses.py
--batch 2026-11-19`; its measurements live in `../prep-report-2026-11-19.json`.

| Upload (as delivered) | Stored here as | Role |
| --- | --- | --- |
| `lickshot_bossy_walk_phone.mov` | `15_bossy-walk_original.mov` | 2.97 s / 89-frame / 30 fps HEVC walk video (694 × 928) |
| `IMG_6636.jpeg` | `12_skank-leanback-sheet_original.jpeg` | 2 × 4 lean-back / skank dodge sheet (1440 × 720) on pure `#FFFFFF` |
| `IMG_6643.jpeg` | `13_hitstun-launch-knockdown-sheet_original.jpeg` | 3 × 4 hitstun / airborne launch / knockdown sheet (1264 × 843) on pure `#FFFFFF` |
| `IMG_6644.jpeg` | `14_c-recoil-launch_original.jpeg` | single airborne C-recoil launch pose (1264 × 843) on pure `#FFFFFF` |

Originals are untouched. The owner's upload filenames are recorded here, and the processed
outputs are new files — no extractor overwrites an approved asset.

## Pipeline

1. Border-connected and large enclosed near-white regions are keyed out, so the white pocket
   sealed inside the mic-cable loop goes transparent while the silver grille, the chain and the
   cream Wallabee soles stay.
2. Each drawing is a connected blob: the biggest `rows × cols` blobs are clustered by centre and
   every smaller fragment joins its nearest pose, which keeps the thin black mic cord attached to
   the hand that holds it. (A straight row/column projection cut the drawings — the sheet rows
   touch.)
3. 1 px erosion, 0.5 px feather, sole line re-cut after the blur, crop to the alpha bbox.
4. Every pose in one animation group is composed onto a **shared canvas**, placed so its sole row
   and stance centre line up, then the group is downscaled once to the 512 px cap. `FighterRoster`
   stores one offset/scale per animation name, so a shared canvas is what stops the walk/reaction
   loops from bobbing or sinking frame to frame.
5. The floor rule: the drawn alpha bottom lands on world **y 592** (`BaseFighter.REACTION_FLOOR_Y`),
   the same 8 px above the y 600 origin line the earlier L!ckshot poses use. Measured sole spread
   inside every group is **0 px**.

## Art-scale calibration

The sheets and the standalone C-recoil were drawn at different sizes: the single pose fills a
whole canvas, a sheet pose fills a quarter of one. The mic grille is the only rigid prop that
appears in every drawing, so its measured disk-equivalent diameter calibrates the standalone pose
onto the sheet's scale (measured ratio **2.682**, recorded as `art_scale_match`). Without it the
C-recoil frame would render ~2.7× larger than the airborne poses it sits beside.

## Walk video — processed but NOT wired

The walk upload is a phone-framed close-up, not a full-body export. Measured across all 89 frames:

- the **hat crown is cut by the top edge in every frame** (row 0 already carries a 112–124 px wide
  hat cross-section that keeps widening below it);
- **every frame clips one boot** at the left or right edge (edge-column pixel counts in the batch
  report), and the clean-right window of each 22-frame stride period contains only half a step.

So no 4–6 frame loop can be extracted without chopped art. The four best (least-clipped) frames are
keyed, capped and floor-aligned into `walk-frames/` with `review/walk-strip.png` for the owner to
check, and `FighterRoster` keeps the mic stance on `walk`. A re-export with the full figure inside
the frame, with margin on all four sides, is what unblocks it.

## Review sheets

`review/skank-strip.png`, `review/hitstun-strip.png`, `review/airborne-strip.png`,
`review/ground-strip.png` and `review/walk-strip.png` — every frame drawn on the sand colour and
bottom-aligned, so a sole that is off the line is visible at a glance.

## Ownership

The owner is the final creative approver. Nothing here is a claim of visual approval: the frames are
prepared, aligned and verified headlessly (no GPU in this environment, so nobody has seen them run).

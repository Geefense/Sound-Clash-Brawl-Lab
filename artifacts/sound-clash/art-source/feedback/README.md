# Feedback source artwork — required uploads

**Status: nothing has been uploaded yet. This folder is empty on purpose.**

`tools/sprite-lab` can render, align, palette-swap and preview sprites, but it
cannot invent Feedback. No Feedback reference art exists anywhere in this
repository (verified across all history: the only image file ever committed is
`public/favicon.svg`), and issue #6's attachments are not reachable from this
workspace. Do not draw a stand-in and call it Feedback.

Drop the files below into this folder, then run `node tools/sprite-lab/generate.mjs`
once the rig has been pointed at them.

## Required files

| # | File | What it must show | Minimum |
|---|------|-------------------|---------|
| 1 | `feedback-turnaround.png` | Front, 3/4, side and back views. Full body, head to sole, arms held clear of the torso. Flat neutral background, even lighting, no cast shadow. | 2048 px tall |
| 2 | `feedback-head-34.png` | Head close-up in 3/4: Kangol brim shadow across the eyes, one gold tooth, jawline, hair at the nape. | 1024 × 1024 |
| 3 | `feedback-costume-details.png` | Maroon/charcoal jacket (collar, zip, cuffs), olive shirt, black cargo pockets, tan Clarks Wallabees, mic in the right hand, cable wrapped on the left forearm. Detail crops are better than one wide shot. | 1024 × 1024 |
| 4 | `feedback-pose-refs.png` | One row per pose: skanking idle (both weight shifts), bent-elbow jab, body shot, sweeping backhand BOX, block, hit reaction. | 2048 px wide |
| 5 | `feedback-palette.png` | Flat colour swatches with hex values: jacket maroon, jacket charcoal, olive, black, tan crepe sole, gold tooth, skin base/shade, mic metal, cable. | 1024 px wide |
| 6 | `feedback-silhouette.png` | Solid black silhouette of the idle pose, used to check limb lengths and hat shape. | 1024 px tall |

Optional but strongly preferred: the layered working file (`.psd`, `.aseprite`,
`.ai` or `.svg`) for the same character. Raster references alone mean every
pose has to be traced; a layered source lets the rig reuse the actual shapes.

## Upload rules

- One consistent subject scale across every file, so proportions can be measured.
- Identical light direction (upper left) and the same flat background in all images.
- No baked drop shadows, no watermark, no compression artefacts around the gold tooth.
- Confirm the art is original or licensed for the game, and name the artist for
  the in-game credit.

## What happens next

The rig in `tools/sprite-lab/rig.mjs` already defines the skeleton from the
game's own hurtbox numbers (`HIP_FROM_FLOOR`, `HIP_TO_SHOULDER`,
`SHOULDER_TO_HEAD`, `HEAD_RADIUS`, per-attack `reach`). With the files above,
the work is palette extraction plus redrawing the rig's body parts — no
skeleton or animation-timing changes — so the sprite keeps matching collision.

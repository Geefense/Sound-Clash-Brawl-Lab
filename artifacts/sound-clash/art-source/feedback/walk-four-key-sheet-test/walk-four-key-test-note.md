# Feedback — four-key sheet walk test: status and findings

**Status: blocked on the source pixels. No frames, no MP4, no commit of fake
panels.** The four-key sheet was attached to the chat, but chat images are not
written into this workspace, so the sandbox has no file to cut, align or
measure. Everything below the "Provisional reading" heading is therefore from
looking at the rendered image, **not** from pixel measurement, and is marked as
such.

Date: 2026-11-13
Source requested: four-panel sheet, `01 CONTACT A / 02 PASS A / 03 CONTACT B /
04 PASS B`, 2×2, dark backdrop, white labels, ruler lines.
Expected path: `artifacts/sound-clash/art-source/feedback/walk-four-key-sheet-test/source-sheet.png`

## What is already built and tested

`build_four_key_loop.py` implements the whole requested pipeline and was run
end to end against a stand-in sheet built from the earlier preview's keys (that
stand-in output was deleted, so nothing fabricated can be mistaken for this
sheet):

1. **Panel detection** — background keyed from the border, the four character
   components found by area, sorted into reading order 01…04.
2. **Label and ruler removal** — each crop stops one row above the detected
   ruler line, so the label under it is never included; the line itself is
   light and neutral while the Clarks are saturated tan, so any line pixels that
   creep into the crop are excluded by colour without touching the shoes.
3. **No mirror, no morph, no inbetweens** — each key is a straight crop of the
   supplied drawing.
4. **Consistent scale** — one uniform factor for all four keys, from the median
   figure height; the scale is recorded per key so an inconsistent drawing shows
   up as a size outlier instead of being silently corrected.
5. **Supporting-foot baseline** — each key's support-foot sole is pinned to the
   same row, so the body height differences between keys remain as bounce.
   Horizontal anchor is the support foot, so the stance does not slide.
6. **Alternation measurement** — an ankle-band pass finds the leg columns
   independently of the shoes (which merge when the feet touch): two columns =
   feet apart, and the forward column is the leading foot. Reported per key as
   `leadingFootSide`, `ankleXs`, `ankleSpreadPx`.
7. **Evidence images** — pairwise silhouette IoU and mean difference, plus
   `diff-01-vs-03.png` and `diff-01-vs-02.png` so "01 and 03 are the same pose"
   is inspectable rather than asserted.
8. **Stepped loop** — order 01 → 02 → 03 → 04, each key held 6 frames at 24 fps,
   6 repetitions (144 frames, 6 s), encoded H.264/yuv420p. The per-cycle frames
   are written to `frames/loop-00…23.png`; the four transparent keys to `keys/`.

Validation run: 4 panels found, ruler rows found for all four, 144-frame MP4
produced at 544×720, no interpolation used.

## Provisional reading of the attached sheet (visual only)

These are observations from the rendered image. The numbers that would confirm
or refute them come from the script and are listed in the next section.

1. **01 and 03 do not appear to alternate the leading leg.** Both contact
   panels show the same screen-right leg forward and the same screen-left leg
   trailing; the body faces screen-right in both, so this is the same anatomical
   leg leading twice. Likewise 02 and 04 both lift the screen-right leg.
   If that holds, 01 → 02 → 03 → 04 is a contact/pass/contact/pass built on one
   leg — a skip or limp, not a two-step walk — and 01 ≈ 03 makes the loop seam
   deceptively small, because the cycle returns to the same pose halfway
   through.
2. **The mic appears to have changed hands relative to the saved walk test.**
   In this sheet the mic sits at the screen-left of the chest with its forearm
   coming from the screen-left shoulder, and the free arm hangs on the
   screen-right. In `feedback-walk-flow-test.mp4` and the approved idle the mic
   is on the far arm (screen-right of the torso), which reads as his anatomical
   left. This sheet reads as a near-arm/right-hand carry — the opposite side.
   That is a continuity break for the character, not a cosmetic difference.
3. **Cable** looks continuous from mic to a visible plug near the knee in all
   four keys; the plug height and the hanging length look slightly different per
   key, which the measurement will quantify.
4. **Hat, dreadlocks, jacket, trousers and Clarks** look consistent across the
   four; no obvious proportion drift.

## Expected measurements once the sheet is available

Per key: figure height, support-foot bottom/x/span, lifted-foot lift, ankle
columns and spread, leading-foot side, mic offset from body centre.
Cross-key: silhouette IoU and mean difference for all six pairs, with 01–03
compared against 01–02 as the alternation evidence.

The specific claim to settle: **does 01's leading foot sit on the same screen
side as 03's?** If yes, the four keys cannot form a two-step cycle without two
new drawings (contact B with the opposite leg leading, and pass B with the
opposite leg swinging). The existing 02/04 pair would be re-used, only the
lead/swing leg swapped.

## How to finish in one pass

```bash
cd artifacts/sound-clash/art-source/feedback/walk-four-key-sheet-test
# put the sheet here as source-sheet.png (or: SHEET=/path/to/sheet.png)
FFMPEG=/path/to/ffmpeg python3 build_four_key_loop.py analyze   # prints per-key feet/ankles/mic
FFMPEG=/path/to/ffmpeg python3 build_four_key_loop.py build      # keys, frames, MP4, sheets, manifest
```

The build writes `keys/`, `frames/`, `alignment-check.png`,
`feedback-walk-four-key-stepped.mp4`, `four-key-manifest.json` and the diff
images. The note above then gets the measured numbers appended and the results
are committed.

## Not done

- No gameplay integration, no animation controller, no world code touched.
- No paid or model-based generation, no mirroring, no morphing, no added
  inbetweens.
- No existing asset modified; the earlier preview and the walk video are
  untouched.

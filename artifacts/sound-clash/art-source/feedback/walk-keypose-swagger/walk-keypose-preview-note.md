# Feedback — rough 8-key swagger walk preview

**Status: rough preview for review. Not approved, not integrated into gameplay, no
paid generation, no model-generated frames.** Every pose below is a cleaned crop
of an existing frame from the saved walk test. The source clip and the six
action/taunt poses are untouched.

Built: 2026-11-13
Source: `artifacts/sound-clash/art-source/feedback/feedback-walk-flow-test.mp4`
SHA-256 `7c644df616db66b7a3bd7747ddf27f65479e156cf2a869bd11598f74e8794011`
(verified unchanged before and after this pass).

## 1. What walking assets actually exist

| Asset | What it is | Used here |
| --- | --- | --- |
| `feedback-walk-flow-test.mp4` | 910×512, 30 fps, 238 frames. Idle to f061, transition f062–070, walk-in-place f071–238. | **Only** source of walk poses. |
| `walk-cycle-preview/` | Earlier 35-frame smooth loop (f153–195), still unapproved. | Left untouched; not reused. |
| `feedback-idle-1600x1280.png` | Approved crossed-arms idle. | Reference for the mic carry only. |
| `imported-poses/01…06` | Action/taunt set (point, swagger step, skank bounce, swagger challenge, skank point, come-here). | **Kept separate — none used in this walk.** |

There is **no existing set of drawn walk key poses** in the repository. The walk
exists only as video; the six imported poses are action/taunt poses, not walk
keys. So the keys here are *extracted frames*, not new drawings, and the sheet
says so on its face.

## 2. The cycle and the eight keys

Measured from the clip, not assumed: a two-step cycle runs **f148 → f193**
(46 frames, 1.533 s at 30 fps, ≈78 steps/min). The wide stances are f148, f165
and f171 (widest, 234 px ankle span); f160 and f182 are the leg passes. Frame 193
closes on the next wide stance (218 px), so the sampled loop does not end mid-air.

| # | Phase (measured) | Src frame | Time | Ankle span | Height vs loop median | Shoulder−hip offset |
| --- | --- | --- | --- | --- | --- | --- |
| 01 | wide stance | f148 | 4.90 s | 203 px | −2 px | +26.4 px |
| 02 | mid-stride | f154 | 5.10 s | 161 px | 0 px | +26.1 px |
| 03 | legs passing | f160 | 5.30 s | 111 px | +7 px | +17.5 px |
| 04 | wide stance | f165 | 5.47 s | 205 px | +5 px | +14.3 px |
| 05 | wide stance | f171 | 5.67 s | 234 px | −2 px | +11.4 px |
| 06 | wide stance | f177 | 5.87 s | 194 px | −3 px | +12.7 px |
| 07 | legs passing | f182 | 6.03 s | 126 px | +1 px | +17.2 px |
| 08 | wide stance | f188 | 6.23 s | 195 px | −2 px | +25.4 px |

The labels are measured descriptors (ankle span in thirds of the cycle's range;
height against the loop median). They are **deliberately not** called
contact/down/pass/up: the source has no designed key poses, and the extreme
frames do not line up into a canonical eight-beat set.

Existing swagger that is genuinely in the source and therefore survives:
lateral body-centre swing of 21 px, body height variation of 10 px, and a
shoulder−hip offset that runs from +11.4 to +26.4 px (the torso counter-rotates
against the hips through the stride).

## 3. Mic hand — checked, and no mirroring was needed

The mic is in his **anatomical left hand**, and it already was:

- The approved idle is a front view with the mic on the viewer's right, which is
  the character's left hand.
- In the 3/4 walk, the **near** arm is the free one (hangs at the near hip) and
  the mic + cable coil come across from the **far** arm — also his left.
- All 8 keys show the same hand; the mic never swaps sides and is never drawn
  twice.

`feedback-idle-spec.json` labels that approved pose "mic in right hand". The
drawing contradicts that label (front view, mic at viewer-right = his left), and
the earlier inspection report treated the text label as authoritative. On the
artwork itself, the idle, the action pack and the walk are consistent with a
left-hand carry. No whole-character mirror was applied to force this.

## 4. Preparation

1. Decode f148–f193 with ffmpeg (no re-encode of the source; no content edits).
2. Key the flat neutral 238 backdrop: a pixel is backdrop only when it is both
   very light **and** neutral, so the cream soles, jacket stripes and teeth survive.
3. Remove light scraps: drop alpha components under 40 px, then delete
   near-backdrop pixels sitting inside one pixel of the silhouette edge (spill),
   then feather and pull edge colour from the nearest fully opaque pixel.
   That is what removes the white fringe that the earlier preview showed around
   the shoes and the cable.
4. **One uniform scale** (0.9892) for every key, from the median figure height,
   so the Clarks stay the same size key to key.
5. **Fixed floor**: each key's lowest sole is pinned to y = 560 on a 460×620
   panel. Verified: all eight keys have their alpha bottom at exactly row 560.
   Head height still varies, so the natural bounce is preserved rather than
   normalised away.
6. **One constant horizontal offset** for the whole stride (the stride's mean
   body centre), so the side-to-side weight shift is kept instead of being
   centred away frame by frame.
7. Played step-and-hold at 30 fps, 5 frames per key, 4 cycles (160 frames,
   5.33 s). No inbetweens, no crossfade, no blended frames.

## 5. Loop seam — measured, not hidden

The player cuts from key 08 straight to key 01.

| Measure | Value |
| --- | --- |
| Changed pixels at the seam | 10.86 % of the panel |
| Mean difference on changed pixels | 46.4 |
| Median ordinary key-to-key step | 15.83 % |
| Largest key-to-key step | 16.72 % |
| Seam ÷ median key step | **0.69×** |

The seam is *smaller* than a typical key step, because f188 → f148 is one
eighth of the cycle like every other key gap. It is still not an exact loop: the
difference sits on the silhouette edge, the leading foot, the free hand and the
cable loop (`seam-diff.png`). Eight stepped keys over 1.53 s read as a rough
snap, not a finished walk — that is the point of a key-pose preview.

## 6. What extraction cannot deliver (the honest limitation)

Extraction can re-time, re-scale and re-place existing drawings. It cannot
change anatomy without cutting the artwork, and cutting the artwork would break
the silhouette and the cable. Specifically:

| Brief item | Status | Why |
| --- | --- | --- |
| Chin higher + confident lean | **partial** | Only the lean already in the drawing. Raising the chin means redrawing head, neck and collar. |
| More shoulder + hip bounce | **not present** | Body height moves 10 px. Pushing it further would float or sink the planted sole unless both legs are redrawn. |
| Clear free-arm swing | **not present** | The free (near) arm is near-static through the stride; no swing poses exist in the clip. |
| Exaggerated heel lift / deliberate plants | **partial** | Toe-off shapes exist in some frames; a higher heel and a harder plant need new feet. |
| Mic in anatomical left hand | **pass** | 8/8 keys, matches the idle, no mirror. |
| Continuous cable | **partial** | Cable is continuous from mic to coil to leg, but the free end is drawn as a plug in some frames and a bare strand in others, and the source encode leaves a light fringe. |

### Exact new drawings needed (6 sets)

1. **Head/neck, 8 keys** — chin up ~8–10°, jaw and collar redrawn; bucket hat,
   hidden eyes, dreadlock mass and smile unchanged. Keep the head pivot behind
   the jaw so the neck does not stretch.
2. **Torso, 8 keys** — shoulder line counter-rotated ~6–8° against the hips,
   +6–8 px vertical bounce per key over the current 10 px, 3/4 lean held.
3. **Free (near/right) arm, 4 keys** — swing back, low, forward, high; soft
   elbow, open hand, no contact with the jacket pocket.
4. **Feet, 4 keys** — two heel-lift toe-off poses and two flat, deliberate
   plants. Same Clarks last and sole length in every key (measure one sole and
   reuse it; do not rescale per pose).
5. **Cable, 8 keys** — one continuous path from mic, over the coil, down the
   outside of the leg to a plug at a fixed height; redraw where the coil meets
   the wrist.
6. **Edge cleanup** — draw shoe and cable edges on a transparent canvas
   instead of keying an H.264 encode, which is the only source of the remaining
   soft edge.

If those six sets are drawn, the same `build_keypose_preview.py` can re-time and
re-assemble them; its panel, floor, scale and seam reporting stay valid.

## 7. Files

| File | What |
| --- | --- |
| `pose-sheet-walk-keys.png` | **Labeled pose sheet**, 8 keys with source frame, measured span/height/offset. |
| `swagger-gap-sheet.png` | Brief vs. reality, plus the six redraw sets. |
| `feedback-walk-keypose-swagger-preview.mp4` | 460×620, 30 fps, 160 frames, 4 stepped cycles, fixed floor line. |
| `keys/key-00…07.png` | The eight keys as transparent PNGs on the shared panel spec. |
| `seam-diff.png` | Difference map for the key 08 → key 01 cut. |
| `keyposes-manifest.json` | Machine-readable frame map, scale, floor, cleanup counts, seam metrics. |
| `checks/` | 3× mic-carry crops and 2× white-background edge checks. |
| `build_keypose_preview.py` | The reproducible build (`analyze` or `build`). |

## 8. Reproduce

```bash
FFMPEG=/path/to/ffmpeg python3 build_keypose_preview.py analyze   # prints foot/height metrics + closure scores
FFMPEG=/path/to/ffmpeg python3 build_keypose_preview.py build      # rewrites everything above
```

Requires ffmpeg, Pillow, numpy and scipy. `analyze` reads the committed MP4 and
writes nothing.

## 9. Not done, by instruction

- No paid or model-based image generation.
- No gameplay integration, animation controller or world code touched.
- No edits to the source MP4, the approved idle, or the six action/taunt poses.

## 10. Limitations

- Mic-hand anatomy is read from a 3/4 drawing plus the front-facing idle; the
  observable facts (near arm free, mic on the far arm, same hand in 8/8) are
  independent of that read, but the repository's own spec text still says
  "right hand" and should be corrected or annotated.
- The eight keys are evenly sampled, not a designed contact/down/pass/up set.
- Foot contact is aligned to a drawn floor line, not to real ground contact; the
  source has no ground plane, so sliding is not measurable.
- Only the eight keys were inspected at full resolution; the rest of the
  analysis used per-frame numeric measurements.

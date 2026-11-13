# Feedback walk-cycle preview — source range and open issues

**Status: movement test — not approved.** Not integrated into gameplay, no
branches merged, no new media generated. The source clip is untouched.

Built from the deliverables in commit `a2cd256`:
`artifacts/sound-clash/art-source/feedback/feedback-walk-flow-test.mp4`
(SHA-256 `7c644df616db66b7a3bd7747ddf27f65479e156cf2a869bd11598f74e8794011`,
3,695,350 bytes).

## Source frame range

| Item | Value |
| --- | --- |
| Stride | **source frames 153–195** (1-based), 43 frames @ 30 fps |
| Pulldown duplicates removed | 8 — source f157, f162, f167, f172, f177, f182, f187, f192 |
| Preview frames | **35 PNGs at 24 fps** (`frames/cycle-00.png` … `cycle-34.png`) |
| Loop length | **1.458 s** (≈41 strides/min, ≈82 steps/min) |
| Uniform scale | 0.985 (source figure median height 467 px → 460 px) |
| Floor baseline | sole pinned to y = 566 in a 460×620 panel |

**Why this range.** Candidate spans were scored *after* scale and floor
alignment, i.e. on the composite that actually loops, and only spans containing
two passing poses were considered (a complete two-step stride, not one step).
`f153 → f196` was the best such closure (aligned mean difference 0.063); the
loop ends at `f195` so the wrap plays as one ordinary frame step rather than
repeating the opening pose.

## How the frames were prepared

1. Extracted frames 153–195 from the saved MP4 with ffmpeg (no re-encode of the
   whole clip, no colour or content edits).
2. Removed the 24 → 30 fps pulldown duplicates. Duplicates measure ≈0.02 mean
   per-pixel difference from their predecessor; every real pose change measures
   ≥0.86. Threshold 0.25.
3. Keyed the flat neutral backdrop (removal requires both near-backdrop colour
   **and** neutrality, so the cream shirt, stripes and soles survive), including
   the pockets of background enclosed between arm and torso.
4. Applied **one uniform scale** to every frame and pinned each frame's lowest
   sole pixel to the floor line. Per-frame height normalisation was deliberately
   avoided: bbox height variation inside this stride is under 2%, and normalising
   it would flatten the body's bounce.
5. Horizontally, each frame uses the stride's mean body centre (not per-frame
   centring), so the natural side-to-side weight shift stays.

## Loop seam — shown, not disguised

The player cuts straight from the last frame to the first; there is no crossfade
and no blended frame.

| Measure | Value |
| --- | --- |
| Changed pixels at the seam | 7.19% of the panel |
| Ordinary consecutive-frame step (median) | 4.52% |
| Largest ordinary step in the loop | 8.10% |
| Seam ÷ median step | 1.59× |
| Mean difference on changed pixels | 69.4 |
| Max channel difference | 255 |

Interpretation: the seam is larger than a median frame step but inside the range
of the loop's own largest steps. It reads as a thin edge offset around the whole
silhouette, heaviest at the feet, the swinging leg, the free hand and the cable
loop. It is **not** an exact loop — the source contains no frame pair that closes
exactly, and the visible hitch at the cut is real. `seam-diff.png` is the honest
difference map.

## Remaining issues in the source (not fixed here)

1. **Mic is in the wrong hand.** The carry matches the approved crossed-arms
   idle, which `feedback-idle-spec.json` records as **"mic in right hand"**. The
   mic belongs in Feedback's **left** hand. The clip has not been mirrored or
   flipped, and neither reference panel has been altered.
2. **Cable terminal is inconsistent.** The run from mic to forearm coil to leg is
   continuous in every frame, but the free end is drawn as a plug at mid-thigh in
   some poses and as a bare strand at the shin in others.
3. **No arm counter-swing.** The mic arm is effectively locked at the chest for
   the whole stride and the free arm barely moves, so the gait reads as a carry.
4. **Source has no clean cycle.** This range is the best closure available, not a
   designed loop.
5. **No ground or shadow in the source.** Foot contact and sliding cannot be
   judged from the clip; floor alignment here is a review aid, not evidence of
   contact.

## Reproduce

```bash
FFMPEG=/path/to/ffmpeg python3 build_preview.py
```

Requires ffmpeg, Pillow, numpy and scipy. The script rewrites `frames/`,
`refs/`, `seam-diff.png`, `frames-manifest.json` and `frames-data.js` from the
committed MP4; `index.html` is the static player.

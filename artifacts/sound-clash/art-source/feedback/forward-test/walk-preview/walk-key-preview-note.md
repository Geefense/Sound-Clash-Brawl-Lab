# Feedback — rough 8-key walk preview

**Status: rough animatic for review. Not approved, not integrated, nothing paid.**
Built entirely from assets already in the repository; no generation, no credits
spent (balance still **470**), and no committed artwork was modified.

## What actually exists (checked before building)

| Asset | Where | What it is | Used here? |
| --- | --- | --- | --- |
| `feedback-walk-flow-test.mp4` | commit `a2cd256`, `art-source/feedback/` | 7.93 s, 910×512, 30 fps studio clip of Feedback walking; mic in **right** hand | **yes — the only real walk motion in the repo** |
| 35-frame cycle (`frames/cycle-00..34.png`) | commit `cf4450e`, prior preview | the stride re-timed to 24 fps, keyed onto a dark plate | no — rebuilt from the clip at higher resolution with true alpha |
| `walk-loop-unapproved-6x.mp4` | commit `cf4450e` | six repeats of that loop | no — derivative of the same frames |
| 6 swagger poses `01..06` | `imported-poses/`, cleaned copy in `pack/93f5aa5e-cleaned/` | point / step / skank bounce / challenge / point / come-here | **no — action/taunt set, deliberately kept out of the walk** |
| `feedback-idle-1600x1280.png` | `art-source/feedback/` | approved crossed-arms idle | no — reference only |

There is **no drawn walk cycle** anywhere in the repository, and no drawing tool
that can produce one. Everything below is a re-cutting of the one clip that
exists.

## The eight keys

Chosen from the 35 unique poses by two measured signals — the gap between the
feet in the lowest 10% of the figure (widest = contact, zero = passing) and the
head-top row (lowest = down, highest = up) — then sorted into stride order. Each
key is a pose that was actually drawn; nothing is interpolated.

| Key | Phase | Step | Source frame | Foot gap |
| --- | --- | --- | --- | --- |
| K1 | contact | 1 | f153 | 18 px |
| K2 | down | 1 | f158 | 0 px (feet together) |
| K3 | pass | 1 | f164 | 0 px |
| K4 | up | 1 | f169 | 40 px |
| K5 | contact | 2 | f175 | 46 px |
| K6 | down | 2 | f180 | 0 px |
| K7 | pass | 2 | f185 | 0 px |
| K8 | up | 2 | f191 | 23 px |

Held for the source frames each key owns — 4, 5, 4, 5, 4, 4, 5, 4 = 35 frames —
so the animatic runs at the clip's own cadence (1.458 s per two-step stride,
24 fps) instead of an invented beat.

## Preparation

- **Alpha.** The studio backdrop is keyed to a true cutout: the wall, floor and
  the open gaps between limbs are found by connected-component analysis of
  bright, colourless pixels, and sealed pockets below the waist are removed as
  well.
- **White scraps.** The source clip has a baked white matte around the shoes and
  the cable. It is removed by growing from transparency through near-white
  pixels (the dark ink contour stops the growth), by dropping sealed neutral
  regions, and by a fleck pass below the waist. Cream shirt and the 255-white
  sleeve stripes are protected by colour separations that were measured, not
  guessed: the matte reads (237,233,232) with G−B ≈ 1, the shirt reads
  (237,235,231) with G−B ≈ 4. `white-scrap-audit.png` is every key on magenta.
- **Floor.** One uniform scale (1.111 on a 472 px median figure → 520 px) and one
  fixed baseline: the lowest sole pixel of every key sits on y = 560. No
  per-frame height normalisation, so the body's own bounce survives.
- **Bounce, measured not added.** Head-top row across the eight keys: 16–25 px,
  a range of 9 px (1.7% of figure height). That is all the bounce the source
  drawing contains.

## Loop seam — measured, not disguised

The MP4 plays four two-step cycles and cuts from K8 straight to K1. No crossfade,
no blended frame.

| Measure | Value |
| --- | --- |
| Changed pixels at the cut | **19.48%** of the frame |
| Median key-to-key step in the cycle | 20.20% |
| Largest / smallest step | 21.74% / 17.07% |
| Seam ÷ median step | **0.96×** |

So the loop closes slightly *better* than an ordinary key-to-key step — but it is
not an exact loop, and `seam-diff.png` shows where the change concentrates
(silhouette edge, swinging leg, cable). An eight-key stepped animatic cannot close
perfectly; only a drawn cycle with matched first and last poses can.

## What the swagger brief asked for, and what this preview can show

| Brief | Present in the source clip? | Evidence |
| --- | --- | --- |
| Chin higher, confident lean | **no** — chin level, gaze down | no chin lift is drawn in any pose |
| More shoulder + hip bounce | **barely** — 9 px head range | measured above |
| Clear free-arm swing | **no** — free arm hangs almost still | it barely travels across the cycle |
| Exaggerated heel lift, deliberate plants | **no** — both soles stay flat | sole row identical in every key |
| Mic in the anatomical **LEFT** hand | **no** — it is in the **right** hand | matches `feedback-idle-spec.json`, which records "mic in right hand" |
| Continuous cable | **yes** — within each key | mic → wrist coil → down the leg, unbroken |
| Lease build, bucket hat, hidden eyes, dreads, fitted pants, Clarks | **yes** | preserved, untouched |

**Not mirrored.** Mirroring the whole figure would flip the walk direction, the
sleeve-stripe placement and the Clarks silhouette, and would still not put the
mic in the *left* hand with a correct grip and cable. The preview is left in its
true orientation and the gap is reported instead.

## Exact drawings needed (no shortcuts left)

The existing art cannot be re-anatomised: the mic hand is baked into every pose,
the free arm does not swing, and both soles are drawn flat. To hit the brief:

1. **Eight new walk key drawings** — contact / down / pass / up, twice — each with
   the mic in the **left** hand, the cable coil on the left forearm and the cable
   leaving the mic base toward the waist pocket (the locked P0 anchor path).
2. **Chin +6–10°** on every key, with the brim shadow kept across the eyes.
3. **Shoulder counter-rotation** of 6–10 px against the hips (mic shoulder leads on
   the contact of its own side).
4. **Free-arm swing** at roughly double the current amplitude, elbow bent ~20°.
5. **Heel lift 18–25 px** at push-off; the planted sole must stay on the fixed
   baseline while the body rises.
6. **One redrawn neutral idle** in the same left-hand grip, or the idle and the
   walk will disagree about which hand holds the mic. The six swagger poses need
   the same correction if they stay in the set.
7. If the cable is to be animated (P2), the eight keys also need the cable on its
   own layer rather than baked, or the current per-key cable path will snap.

Minimum: **8 walk keys + 1 idle**, plus cable separation if the reel is wanted.
That is a drawing job, not a generation job — and it is why this preview stops at
"rough".

## Files

| File | What it is |
| --- | --- |
| `walk-keys-8-sheet.png` | labelled pose sheet, 4×2, fixed floor, gap list at the bottom |
| `feedback-walk-keys-8.mp4` | 340×600, 24 fps, H.264, 5.83 s — four cycles |
| `keys/key-01..08.png` | individual keys on the light card with the floor line |
| `keys/key-01..08-alpha.png` | the same poses as true-alpha cutouts for an engine |
| `white-scrap-audit.png` | all eight keys on magenta, where leftovers show |
| `seam-diff.png` | last frame dimmed, the seam's differences in red |
| `keys.json` | key indices, holds, seam statistics, scale and floor |
| `build_walk_keys.py` | rebuilds all of the above |

## Reproduce

```bash
git show a2cd256:artifacts/sound-clash/art-source/feedback/feedback-walk-flow-test.mp4 \
  > ref/walkflow.mp4
FFMPEG=/path/to/ffmpeg python3 build_walk_keys.py --video ref/walkflow.mp4
```

Requires Pillow, numpy and scipy. `ref/`, `source/` and `work/` are working
copies of committed files and are git-ignored.

## Known limits

- The source clip has no ground contact or shadow, so foot sliding cannot be
  judged from it; the floor line is a review aid.
- The cable's free end varies between frames (plug at mid-thigh in some, bare
  strand at the shin in others) — it is continuous, not consistent.
- The keying removes a few 1–3 px anti-aliasing specks; no garment or cable pixel
  was altered.
- Eight keys are an animatic, not animation. The 35-frame cycle is the closest
  thing to a real cadence that exists today.

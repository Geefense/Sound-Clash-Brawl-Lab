# Feedback four-key walk loop — extraction, alignment, leg trace, checks

**Status: movement test — not approved. Not integrated into gameplay.** No world,
combat or simulation code touched. The sheet is untouched; everything below is
derived from it.

Built from `source-sheet.jpeg` (SHA-256
`fb5194830d77bfa89aacbd914da6bb2ad4b994d9dffd6823513768a6a06ec0d5`, 1,199 ×
1,312 px). The mic-hand rule for these keys is in `four-key-note.md`.

## What was built

| Path | What it is |
| --- | --- |
| `poses/01_contact_a.png` … `04_pass_b.png` | the four keys, 460 × 620 RGBA, one uniform scale, support sole on y = 566 |
| `index.html` | looping preview player: play/pause, key step, 4/6/10-frame holds, 0.5×/1×/2× speed, onion skin, clickable key strip |
| `keys-aligned.png` | the four aligned keys with boot markers on the floor line |
| `leg-trace.png` | hip → knee → ankle traced on every key |
| `crossing-6x.png` | the crotch/crossing at 6× for the two contact keys |
| `extract_keys.py`, `trace_legs.py` | cut-out, alignment, contact sheet; leg trace and gait numbers |
| `loop-check.json`, `leg-trace.json` | the numbers |

## Alignment

**One uniform scale for all four keys.** As drawn the figures measure 510, 502,
521 and 510 px tall — a 3.7% spread. The only rigid ruler available is the flat
boot, and its own measurement noise is 5% (bbox width) to 25% (area), so the
sheet cannot be shown to use different scales. Per-key normalisation was
therefore wrong: it would have flattened the walk's rise and dip to hide a
difference that is inside the noise.

**Vertical: the support sole is pinned, the pose height is not normalised.**
Pinning the planted foot to the floor lets the body rise and dip naturally. The
result keeps the bob:

| Key | Drawn | In panel | Head top |
| --- | --- | --- | --- |
| 01 CONTACT A | 510 px | 460 px | y 112 |
| 02 PASS A | 502 px | 453 px | y 120 |
| 03 CONTACT B | 521 px | 470 px | y 102 |
| 04 PASS B | 510 px | 460 px | y 111 |

That is an 18 px rise and dip across the four keys, preserved rather than
cancelled.

**Horizontal: the torso is centred, not the bounding box.** Bounding-box
centring shifts a key by however far the arms and legs stick out, inventing
lateral drift; centring the torso puts all four at x 229.6–230.4.

Cut-out notes: background keyed at a tolerance of 8 (the near-black hat sits
inside a looser threshold and lost its crown), labels dropped by keeping the
largest component, and the ground line stripped as a thin-run stroke so it does
not bridge the boots.

## Leg trace — hip → knee → boot

`leg-trace.png` draws each leg's centreline, its knee (strongest change of
direction between hip and ankle) and its ankle, per key.

| Key | Hip | Left leg: knee → ankle | Right leg: knee → ankle |
| --- | --- | --- | --- |
| 01 CONTACT A | x 215.5, y 333 | (236, 392) → (315, 534) | (310, 502) → (317, 545) |
| 02 PASS A | x 221.5, y 345 | (286, 419) → (213, 532) | (266, 487) → (215, 531) |
| 03 CONTACT B | x 209.8, y 324 | unresolved (far leg drawn near-black) | (346, 497) → (330, 543) |
| 04 PASS B | x 219.2, y 334 | (249, 386) → (155, 539) | (220, 450) → (170, 529) |

## Checks

### A/B leg alternation — they do alternate (earlier verdict retracted)

An earlier version of this note said alternation was "not evidenced". That
verdict compared **foot plots**, which cannot answer the question: in a side
view an alternating stride puts the boots in *the same screen places* — only the
leg identity swaps. The evidence that does answer it:

1. **Near/far at the crossing.** The leg whose hip/seat fabric runs unbroken
   into the leg is the near one; the far leg's top disappears behind it. At 6×
   (`crossing-6x.png`) the near leg is the **screen-left** leg in CONTACT A and
   the **screen-right** leg in CONTACT B. The near leg swaps sides.
2. **Occlusion gaps.** Tracing where each leg's fabric is interrupted gives the
   same swap in three of the four keys: near **R** in the A half (01, 02), near
   **L** in the B half (04). Key 03's far leg is drawn almost black and produces
   no usable gap, so it is excluded rather than guessed.
3. **The leading leg never changes.** The front boot is on the right in all four
   keys (front x 361 / 245 / 372 / 189 against hip x 216 / 222 / 210 / 219), so
   the near leg is forward in one contact and trailing in the other.

Conclusion: **the legs alternate**, and the contact keys do not need redrawing
for that.

### The two pass keys are at different sub-phases — needs correcting

The support foot sits **24 px in front of the hip** in PASS A and **30 px behind
it** in PASS B — a 54 px phase difference between the two halves of the cycle.

| Interval | Stance foot travel (body-relative) |
| --- | --- |
| CONTACT A → PASS A | −117 px |
| CONTACT B → PASS B | −185 px |

A planted foot moving backwards through the frame is **forward travel, not
sliding**: in body-centred coordinates that is exactly how far the body has to
move in the interval. What is wrong is that the two halves disagree by **68 px
(37%)**.

**Read that 68 px as a diagnostic, not as a slide amount.** It says the two
halves of the cycle cover different ground at one uniform scale. How much a foot
actually appears to skate depends on the cadence the loop is played at and on
the forward speed the game drives the character at, neither of which these four
still frames contain. At a slow cycle over a fast world speed the skate is
larger; over a matched speed it is zero whatever the numbers say. The honest
claim is "the halves disagree by about this much", not "the foot slides 68 px".

Fixing PASS B to PASS A's sub-phase removes the disagreement itself, which is
the part the art owns.

### Arms do not counter-swing — needs correcting

The free (left) arm is forward in all four keys. With the legs alternating, the
free arm must be back in whichever key has the left leg forward, so at least one
key has the wrong arm swing. This is the same stiffness the Flow-test review
measured, and it will read as a carry rather than a walk even after the legs and
pass phase are fixed.

### Duplicates — none

Pairwise mean RGB difference over the union: A/PASS A 62.1, A/B **37.9**,
A/PASS B 57.9, PASS A/B 64.0, PASS A/PASS B 56.3, B/PASS B 59.7. The contact
pair is the closest, and its difference map is concentrated on the boots, the
head and the leg seams — it is a redraw, not a copy.

### Mic hand — passes

One mic, one cable, right hand in all four keys; details in `four-key-note.md`.

## What needs correcting before a redraw

1. **PASS B** — re-cut to PASS A's sub-phase (support foot ~24 px ahead of the
   hip, not 30 px behind, swing leg ~81 px behind the support, same lift). A
   prepared key and a side-by-side comparison are in `compare.html`; see
   *Prepared correction* below for what it does and does not settle.
2. **Arm swing** — add counter-swing so the free arm trails in the key where the
   left leg leads; currently it leads in all four.
3. **CONTACT A / CONTACT B** — no redraw needed for alternation, but which leg
   leads in each should be confirmed by the artist: the masks cannot resolve key
   03, and the two keys share a foot plot by construction.

## Prepared correction — `comparison/pass-b-prepared.png`

Built by `build_corrected_pass_b.py` for the side-by-side in `compare.html`, and
kept outside `poses/` deliberately. It is a **comparison image, not a walk key
and not a candidate asset**: PASS B's jacket, mic arm and free-arm
swagger stay exactly as drawn, and the trousers below the waistband come from
PASS A, joined at each pose's own waistband line. PASS A's free hand is removed
and refilled from the surrounding cloth before B's own hand is laid back on top,
because A's hand overlaps its own thigh.

Measured after the join, against a hip at x 220:

| | original PASS B | prepared | PASS A |
| --- | --- | --- | --- |
| support foot vs hip | −31 px | **+23 px** | +24 px |
| swing foot vs support | +41 px | **−81 px** | −81 px |
| swing lift | 47 px | 43 px | 43 px |
| stance travel from the contact key | 185 px | **130 px** | 117 px |

The half-to-half difference falls from 68 px to 13 px. The remaining 13 px is
not a pose error that this technique can fix: PASS A's pass has the feet 81 px
apart and PASS B's has them 41 px apart, so the stride length itself differs.

A warp was tried first and rejected: pulling the boots ~40 px further apart than
the sheet draws them folds one smooth displacement field into itself and the
legs collapse into a single column (`git log` on this file's first version).
Two rigidly rotated leg layers tear at the crotch instead. Both are recorded
here so the redraw is not attempted as an image trick.

**Not settled by the proxy:** the near leg is still PASS A's, so which leg is
near in the fourth key is exactly the question the redraw has to answer. The
free arm is also left leading, as instructed, so the comparison isolates the
pass phase rather than mixing two corrections.

**Status: stops here.** No further splicing or warping. PASS B needs a real
redraw at the matching phase of the opposite step — same proportions, same
swagger, mic in the right hand, one continuous cable — and that is drawing
work, not image work. The four original keys in `poses/` are untouched by any
of this and remain the only keys in the folder.

## Playback

Four poses and nothing else: each key is held (6 frames at 24 fps by default =
1.0 s per cycle) and the cuts are hard. Nothing is interpolated or crossfaded.
Verified in the browser: 1× advances a key every 250 ms, 2× every ~117 ms, 0.5×
every 500 ms, pause holds the frame, onion shows the previous key at 0.34
opacity, and the key step and strip highlight follow.

## Reproduce

```bash
python3 extract_keys.py             # poses/, keys-aligned.png, loop-check.json
python3 trace_legs.py               # leg-trace.png, leg-trace.json
python3 build_corrected_pass_b.py   # comparison/pass-b-prepared.png, corrected-pass-b.json
```

Requires Pillow, numpy and scipy. `index.html` and `compare.html` read `poses/`
directly.

## Limitations

- Four static drawings: no timing, no in-betweens, no shadow, so cadence and
  contact quality are inferred, not measured.
- The near/far reading at the crossing is a visual judgement made at 6×; the
  automated gap test agrees on the swap in three keys and cannot resolve the
  fourth, so the alternation conclusion rests on both together.
- Boot identification is by colour and floor proximity; the mic hand is the same
  tan and is excluded by height, not shape.
- Sliding is not claimed anywhere: only body-relative travel is measured, and
  the defect reported is the mismatch between the two halves. The 68 px is a
  timing diagnostic and depends on cadence and world speed.
- The prepared PASS B is a splice, so a seam exists under the waistband and the
  trousers are A's rather than newly drawn. It is fit for judging pass phase and
  timing, not for shipping or for judging cloth detail.

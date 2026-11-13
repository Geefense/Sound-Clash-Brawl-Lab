# PASS B redraw v1 — review (unapproved)

Reviewed against `pass-b-redraw-v1.md`: opposite-leg anatomy, phase, proportions,
right-hand mic, cable. Evidence: `candidate-v1-trace.json`,
`candidate-v1-measure.json`, `candidate-v1-trace.png`,
`candidate-v1-crossing-4x.png`, `compare-redraw-v1.html`.
Scripts: `build_candidate_loop.py`, `trace_candidate_v1.py`.

## File

Repaired and complete as of `0eb3816`: 1079 × 1457, **1457 of 1457 rows decode**,
`IEND` present, decompressed length exact (6,289,869 bytes). The earlier
truncation note no longer applies.

## Verdict: the character work passes, the pose does not

| Check | Result |
| --- | --- |
| One mic | **pass** — one neutral-metal blob, 72.5 px diagonal, x 471–534, y 348–381 |
| Right-hand mic | **pass** — the mic arm carries the three cream stripes on its outer surface and is drawn over the jacket; the free hand is now visible and carries none. Same grip evidence `verify_four_keys.py` uses on the sheet |
| Cable | **pass** — one cord from the mic base, coiled at the wrist, hanging to a single plug at hip height, no break visible |
| Boots and floor | **pass** — two boots, one flat on the sole line, so the pose is legible as a stride |
| Phase vs PASS A | **fail** — see below |
| Opposite-leg identity | **fail (visual)** — see below |
| Proportions | **fail** — body ~27% too long for the mic |
| View angle | **warn** — three-quarter, where the keys are side profiles |

## Phase — the stride is roughly three times PASS A's

Panel-scale distances, the candidate scaled to the drawn figure's height
(454 px) with its support sole on the floor line:

| | candidate v1 | PASS A | drawn PASS B | drawn contact |
| --- | --- | --- | --- | --- |
| support foot from hip | **+81 px** | +24 px | −30 px | +147 px |
| swing foot from support | **−180 px** | −81 px | +41 px | −247 px |
| swing lift | **56 px** | 46 px | 47 px | 0 px |

A pass pose has the support foot under or just ahead of the hip with the other
foot close behind. The candidate has the planted foot well forward and the
lifted foot far behind: it is a mid-stride frame, not the mid-stance PASS A is
drawn at. Dropped into slot 4 it would not continue the cycle at PASS A's point.

Measured in the source and divided by the mic diagonal, so no scale assumption
enters: support 3.36 mic-units (PASS A 0.75), swing −7.45 mic-units (PASS A
−2.60), lift 2.30 (PASS A 1.48).

## Opposite-leg identity — it repeats PASS A's arrangement

The lifted leg is the one drawn **over** the planted leg at the thigh crossing
(near leg, screen-left, behind). That is exactly PASS A's arrangement: in
`02_pass_a.png` the near leg is the lifted one and the far leg is planted. So the
candidate reads as another pass on the same leg, not the opposite step.

This is a 2× visual reading of the crossing, not a mask verdict — the drawn key
03 already showed that colour thresholds cannot settle leg identity on their own.
Ask the artist to confirm which leg is near before the next pass.

## Proportions — the mic is small for the body

Normalised by the mic diagonal (a rigid prop in every drawing):

| | candidate v1 | drawn keys |
| --- | --- | --- |
| figure height | **18.8** mic-units | 14.6–15.1 |
| chest width | **6.29** mic-units | 4.76–5.29 |

At the mic's own scale the candidate would be 585 px tall in a 460 px key panel
— 29% over, and taller than the panel itself once the sole is on the floor. Fitted
to the drawn height instead, the mic reads 24.2 px against the drawn 31.1 px, so
the prop is ~22% small relative to the body.

The view differs too: the candidate shows both shoulders and the chest front,
where the four keys are strict side views. That affects silhouettes and should be
brought back toward profile before the figure is judged as a walk key.

## To continue

Re-cut with the support foot back to ~+24 px of the hip (0.75 mic-units), the
swing foot ~81 px behind it, and lift ~46 px; lift the far leg rather than the
near one; bring the mic back up to the drawn size (or the body down); and turn the
torso toward profile. Then run `build_candidate_loop.py` and
`trace_candidate_v1.py` again and reopen `compare-redraw-v1.html`.

The original sheet and `poses/` remain untouched, and nothing here is in gameplay.

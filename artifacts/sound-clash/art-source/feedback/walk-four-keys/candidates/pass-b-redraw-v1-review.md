# PASS B redraw v1 — review (unapproved)

Reviewed as delivered against `pass-b-redraw-v1.md`: opposite-leg anatomy,
proportions, right-hand mic, cable. Evidence: `candidate-v1-measure.json`,
`compare-redraw-v1.html`, `pass-b-redraw-v1-aligned.png`,
`pass-b-redraw-v1-salvaged.png`.

## Headline: the delivered file is incomplete

`pass-b-redraw-v1.png` declares 1079 × 1457, but its IDAT stream is **764,511
bytes of 843,877 declared**, there is **no IEND chunk**, and only **555 rows
(38.1%) decode**. The remaining 902 rows — 62% of the image — are not in the
repository. A strict decoder (Pillow without `LOAD_TRUNCATED_IMAGES`) refuses the
file outright. Chrome does not: it reports 1079 × 1457 as loaded and renders the
missing rows as empty, so in a browser the fault looks like a bust that was
drawn short rather than a file that arrived short. That is why the test loop
marks the cut with a dashed line instead of letting the blank space read as art.

`pass-b-redraw-v1-salvaged.png` is the decodable part, cropped at the last
complete row. Nothing was invented to fill the gap.

**This is a transport problem, not an art verdict.** Nothing here says the
drawing is wrong; it says the drawing did not arrive.

## What could be measured, on the readable rows only

| Check | Result |
| --- | --- |
| One mic | **pass** — a single neutral-metal blob, 72.5 px diagonal, x 471–534, y 348–381 |
| Mic hand | **reads as right, unconfirmed** — the mic arm shows the cream sleeve stripes on its outer surface and is drawn over the jacket; the far arm is outside the readable rows, so the two hands cannot be compared |
| Cable | **cannot be checked** — the cord leaves the mic, loops at the wrist and runs into the truncation edge; no plug lies inside the readable rows |
| Legs, boots, floor | **cannot be checked** — the drawing stops at the chest |
| Opposite-leg phase | **cannot be checked** — no hip, knee, ankle or boot pixel exists to trace |
| Proportions | **view mismatch** — mic-diagonal scale 0.43, chest width implies 0.30; the candidate is nearer a three-quarter view than the side-view keys, so width cannot grade proportion |

Panel placement for the test loop: scaled 0.43 by the mic (the only rigid prop
present in both), head top aligned to PASS B's y 111, torso centred on x 230.
The art then runs y 118–350 in a 460 × 620 panel whose floor is y 566 — it does
not reach the floor, so it cannot stand in the cycle.

## What the readable part does say

- The bust is **nearer three-quarter** than the strict side view of the four
  keys: both shoulders are visible and the chest faces the viewer. A walk key
  read from the side would need the torso turned back toward profile.
- The hat, dreads, jaw, smile, jacket, zip and sleeve stripes read as the same
  character; the mic is held in front of the chest rather than at the hip.
- The mic arm's stripes are on its outer surface as in the drawn keys, which is
  the same grip evidence the four-key check uses.

## To continue

Re-export and re-commit the image, then run
`python3 candidates/build_candidate_loop.py` and reopen
`candidates/compare-redraw-v1.html`. With the full 1457 rows present, the
review can measure the hip/knee/boot trace, the support-foot phase against
PASS A (+23 px ahead of the hip), the swing foot (−81 px behind the support,
43 px lift) and cable continuity to the plug.

The original sheet, `poses/`, and every drawn key are untouched by this review.

# Feedback four-key walk loop — extraction, alignment, checks

**Status: movement test — not approved. Not integrated into gameplay.** No world,
combat or simulation code touched, no experimental branch merged. The sheet is
untouched; everything below is derived from it.

Built from `source-sheet.jpeg` (SHA-256
`fb5194830d77bfa89aacbd914da6bb2ad4b994d9dffd6823513768a6a06ec0d5`, 1,199 ×
1,312 px). The mic-hand rule for these keys is in `four-key-note.md`.

## What was built

| Path | What it is |
| --- | --- |
| `poses/01_contact_a.png` … `04_pass_b.png` | the four keys, 460 × 620 RGBA, transparent, one shared figure height, soles on y = 566 |
| `index.html` | looping preview player: play/pause, key step, 4/6/10-frame holds, 0.5×/1×/2× speed, onion skin, clickable key strip |
| `keys-aligned.png` | the four aligned keys side by side with boot markers on the floor line |
| `extract_keys.py` | does the cut-out, alignment, contact sheet and every measurement below |
| `loop-check.json` | the numbers |

## How the poses were cut and aligned

1. **Background keyed at a tolerance of 8.** The field is flat near-black (JPEG
   noise std 0.6, max distance 3.6) and the bucket hat is drawn almost as dark.
   A looser threshold eats the crown: at 26 the top-row figures lost ~45 px of
   hat and every height and scale came out wrong. This was caught by looking at
   the cut-out, not by trusting the numbers.
2. The **largest connected component** is kept, so the key labels are dropped,
   and thin horizontal strokes are stripped afterwards — the white ground line
   survives beside the soles as a stub that otherwise bridges the two boots.
3. **Scale.** The sheet's figures are drawn **502, 510, 521 and 510 px** tall, so
   each key is normalised to a 460 px figure (scales 0.902, 0.916, 0.883, 0.902).
   One shared scale would have left the keys up to 4% out of step.
4. **Floor contact.** Each key's soles are pinned to y = 566 in a 460 × 620 panel
   and horizontally centred on the mean body centre of the four keys, so the
   per-key weight shift survives instead of being flattened.
5. Resampling premultiplies alpha before LANCZOS, so no dark fringes.

## Playback

Four poses and nothing else: each key is held (default 6 frames at 24 fps =
1.0 s per cycle) and the cuts are hard. Nothing is interpolated or crossfaded —
the pops are the sheet's, and hiding them would misrepresent the asset. The wrap
from 04 PASS B back to 01 CONTACT A is one more hard cut.

## Checks

| Key | Drawn height | Scale | Front boot | Rear boot |
| --- | --- | --- | --- | --- |
| 01 CONTACT A | 510 px | 0.902 | x 367, tilt −0.49, on floor | x 122, tilt +0.08, on floor |
| 02 PASS A | 502 px | 0.916 | x 218, tilt +0.01, on floor | x 137, lifted 51 px |
| 03 CONTACT B | 521 px | 0.883 | x 377, tilt −0.59, on floor | x 120, tilt +0.05, on floor |
| 04 PASS B | 510 px | 0.902 | x 209, lifted 49 px | x 168, tilt +0.08, on floor |

Body centre in the panel is x ≈ 230.

### A/B leg alternation — flagged, not evidenced

CONTACT A and CONTACT B put the boots in the same places at the same angles:
front boot **x 367 vs 377** (10 px apart), rear boot **x 122 vs 120** (2 px),
front sole tilt **−0.49 vs −0.59**, rear sole tilt **+0.08 vs +0.05**. Both keys
plant both feet. That is the same foot plot twice.

A two-step cycle needs the legs swapped between contact keys — near leg forward
in one, trailing in the other. Nothing in the drawing does that, and the pair is
also the closest of the six (mean diff **30.9**, against 46.8–63.9 for every
other pair), with the differences sitting in the torso, arms and head rather
than the legs.

The pass keys do not rescue it. They are not the same sub-phase mirrored:
PASS A supports **under** the body (x 218, centre 230) with the swing foot 81 px
behind, while PASS B supports **62 px behind** the body (x 168) with the swing
foot passing 41 px ahead of the support (x 209). So the cycle has one contact
pose twice and two pass poses at different phases.

**Consequence:** as supplied, the four keys read as one step repeated, not a
stride. One contact key needs redrawing with the opposite leg forward, and the
pass keys need to be cut to the same sub-phase, before this can be called a
two-step cycle.

### Duplicates — none

No two keys are copies. Pairwise mean RGB difference over the union of the
figures: A/PASS A 63.2, A/B **30.9**, A/PASS B 60.9, PASS A/B 63.9, PASS A/PASS B
46.8, B/PASS B 61.9. Even the closest pair differs across the upper body, so
these are distinct drawings, not reuses.

### Foot sliding — inherent to a four-key loop

Between a contact key and the pass that follows it the stance foot travels
**−149 px** (A→PASS A) and **−209 px** (B→PASS B). The two halves disagree by
60 px, so the cycle also limps.

The step itself — the distance between the feet at contact — is **245 px**
(CONTACT A) and **257 px** (CONTACT B). Two separate things are needed before
this reads as a walk:

- the character must travel one step (≈250 px) per step so the stance foot holds
  its ground, and
- in-betweens, so the stance foot does not teleport between keys.

At 460 px ≈ 1.8 m, a 251 px step is ≈0.98 m. At the preview's 1.0 s cycle that
is ≈2.0 m/s — brisker than the art reads; a 2 s cycle lands near 1.0 m/s.

### Mic hand — passes

One mic, one cable, right hand in all four keys; details and evidence in
`four-key-note.md`.

## What would make this approvable

1. Redraw CONTACT B (or CONTACT A) with the opposite leg forward so the two-step
   cycle actually alternates, and cut both pass keys to the same sub-phase.
2. Decide the cadence and the root-motion distance (≈250 px per step is what the
   art implies) and add in-betweens, at least one per quarter cycle.
3. Add a ground contact shadow so planted feet can be judged.

## Reproduce

```bash
python3 extract_keys.py     # rewrites poses/, keys-aligned.png and loop-check.json
```

Requires Pillow, numpy and scipy. `index.html` is the static player and reads
`poses/` directly.

## Limitations

- The sheet is four static drawings: no timing, no in-betweens, no shadow, so
  cadence and contact quality are inferred, not measured.
- Boot identification is by colour and floor proximity; the mic hand is the same
  tan as the boots and is excluded by its height, not its shape.
- Alternation cannot be proven from screen positions in a 2D side view; the
  verdict rests on the boots landing in identical places with identical sole
  angles and on the pass keys supporting at different points, which is the
  observable evidence available.

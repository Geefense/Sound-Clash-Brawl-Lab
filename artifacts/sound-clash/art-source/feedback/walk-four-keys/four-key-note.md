# Feedback four walk keys — identity, layout, and the mic-hand rule

**Status:** reference sheet accepted as the walk key source. The four keys are
right-handed as drawn; no redraw is required for the mic hand. Cut-out poses and
a looping player live alongside this note — see `four-key-loop-note.md`
(**unapproved movement test, not in gameplay**).

## Sheet

| Property | Value |
| --- | --- |
| File | `source-sheet.jpeg` |
| Size | 1,199 × 1,312 px, RGB JPEG, 285,760 bytes |
| SHA-256 | `fb5194830d77bfa89aacbd914da6bb2ad4b994d9dffd6823513768a6a06ec0d5` |

Four posed figures on a 2 × 2 grid, each on a thin white ground line with the
key name beneath it, on a near-black field:

| Key | Cell (x0, y0, x1, y1) | Pose |
| --- | --- | --- |
| 01 CONTACT A | 0, 0, 600, 656 | stride extended, legs scissored, free arm swung back |
| 02 PASS A | 599, 0, 1199, 656 | passing pose, near knee lifted, support leg under the body |
| 03 CONTACT B | 0, 656, 600, 1312 | contact on the opposite step |
| 04 PASS B | 599, 656, 1199, 1312 | passing pose on the opposite leg |

## The rule

The microphone is held in Feedback's **anatomical right hand** in all four keys
and in every animation frame. There is **one mic** and **one cable**, and the
cable is a single continuous run from the mic to its plug.

This supersedes the earlier left-hand instruction. The documents that recorded
that instruction — `feedback-idle-spec.json`, `walk-cycle-preview-note.md`,
`walk-cycle-preview/index.html` and `feedback-walk-inspection-report.md` — have
been corrected to match.

## How the hand was read (not from screen position)

The mic sits on the **screen-left of the torso** in every key, which is what the
earlier review read as the left hand. Screen position is not handedness. On a
figure facing screen-right the viewer sees the right flank, so the near arm is
the right arm, and it crosses the chest to carry the mic at that screen-left
point. Three cues in the pixels agree:

1. **Sleeve.** The mic arm's three white stripes are on its outer surface, and
   that sleeve is drawn over the jacket rather than behind it — the near arm.
   The far arm's sleeve is plain where it shows.
2. **Grip.** The back of the hand faces the camera, the thumb sits on the body's
   rear side of the grip and the fingers wrap to the front. That is a right
   hand holding a mic in front of the chest; a left hand in the same place would
   show its thumb on the front side.
3. **Free arm.** The stripe-free hand hangs at the hip and swings beyond the
   body silhouette, so it is the far arm — the left.

Evidence: `grip-thumb-side-5x.png` (5× crop of the key 01 grip).

## Per-key check

Measured on the sheet by `verify_four_keys.py`; boxes are cell-local pixels.

| Key | Mics | Plug | Cord |
| --- | --- | --- | --- |
| 01 CONTACT A | 1 `[285,181,305,207]` | 1 `[222,362,225,373]` | coils twice on the right wrist, one run to the plug |
| 02 PASS A | 1 `[261,207,283,222]` | 1 `[191,375,193,381]` | as above |
| 03 CONTACT B | 1 `[294,128,315,154]` | 1 `[240,308,243,319]` | as above |
| 04 PASS B | 1 `[261,142,283,168]` | 1 `[191,320,193,327]` | as above |

Result: **one mic and one plug per key** — no duplicated mic, no second cable
end, the same hand in all four.

**Cable continuity is a visual finding, not a measured one.** The cord leaves the
mic, is hidden behind the hand, reappears in the wrist coil, crosses the cream
waistband and ends in the plug. A colour mask splits it at exactly those
crossings (2–4 segments per key, listed in `four-key-check.json`), which is
occlusion rather than a break: the segments meet end to end and there is no
loose strand or orphaned piece. Evidence: `cable-per-key.png`.

## Animation

The walk frames behind the preview carry the mic the same way — back of the near
hand to camera, thumb on the body side, coil on that wrist — so the animation is
right-handed and needs no mirror. `walk-cycle-preview/frames/cycle-00.png` and
`cycle-17.png` were inspected at 8×; the video review measured 238/238 frames
with no hand swap, so the carry does not change mid-clip.

The rule holds for any future walk rebuild: mic in the right hand, one mic, one
unbroken cable to one plug.

## Reproduce

```bash
python3 verify_four_keys.py
```

Rewrites `grip-thumb-side-5x.png`, `cable-per-key.png` and
`four-key-check.json`. Requires Pillow, numpy and scipy.

## Limitations

- Static keys only: this check says nothing about loop timing or arm
  counter-swing, both still open in the walk review.
- The sheet has no ground shadow, so foot contact cannot be judged from it.
- Handedness rests on the drawing conventions above (outer sleeve surface, grip
  thumb side) rather than on a 3D model; the observable facts — one mic, one
  plug, same hand in every key — do not depend on that reading.

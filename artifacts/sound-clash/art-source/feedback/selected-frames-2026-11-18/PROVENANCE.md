# Feedback — selected frames 2026-11-18 (provenance)

Source: six pose illustrations uploaded by the owner (Garfield Connell) to
`stage/sound-clash-sand` on 2026-11-18, delivered as commit `7c7ab6a` ("Add files via upload")
at the repository root. They were moved here byte-identically with `git mv`; the filenames
below are the original upload names and are kept so the source can be traced. **These originals
are immutable** — the preparation script reads them and never writes back.

They were uploaded alongside seven L!ckshot frames, which live untouched in
`art-source/fighters/lickshot/` and are prepared by `prep_lickshot_poses.py`.

| Original upload | Pose | Game frame | Wired to |
| --- | --- | --- | --- |
| `feedback_palm_push_approved.png` | Double-palm forward shove | `01_double-palm-shove.png` | Throw break + forward-throw release |
| `feedback_hit_reaction_leanback.png` | Deep lean-back groove | `02_lean-back-groove.png` | Taunt (T) first half, then the skank loop |
| `feedback_open_hand_strike.png` | Extended open-palm slap | `03_open-palm-slap.png` | Jab (J) |
| `feedback_front_kick.png` | High Clarks boot kick | `04_clarks-kick.png` | Sparta kick (L / tump) active frame |
| `feedback_extended_shove.png` | Fist raised skyward | `05_sky-fist.png` | Upper box (I) + round win / Hype Surge |
| `feedback_high_uppercut_anti_air.png` | Wide-stance forward hand reach | `06_hand-reach.png` | Collar grab (U) startup |

Two filenames describe an earlier intent rather than the drawing (`feedback_extended_shove` is
the raised fist; `feedback_high_uppercut_anti_air` is the wide hand reach). The mapping above is
by the artwork, and the processed frame names follow the artwork.

Processing: `prep_feedback_poses_2026-11-18.py` in the parent directory. It removes
border-connected near-white background while keeping enclosed highlights, protects the thin mic
cord and the cream Clarks soles from the edge erosion, crops to the alpha bbox, caps the longest
side at 512 px and writes game frames to
`godot/assets/sprites/feedback/selected-frames-2026-11-18/`.

Floor rule: each frame's measured drawn alpha bottom is placed on world **y 592**
(`BaseFighter.REACTION_FLOOR_Y`), 8 px above the y 600 origin line, at an adult crown-to-sole of
121.75 px before `BaseFighter.FIGHTER_ART_SCALE`. `prep-report.json` records every measured row,
offset and scale used by `BaseFighter` / `FighterRoster`.

All six are pose illustrations, not interpolated animation. Approving an upload was permission to
use it, not approval of how a sequence reads in motion.

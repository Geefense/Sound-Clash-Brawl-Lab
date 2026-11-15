# Sound Clash Sand Stage — source art

Owner-supplied stage background for the Godot Sound Clash venues. Source art is kept here
immutable; the game reads only the derived export in `/godot`.

| File | Size | Purpose |
| --- | --- | --- |
| `sound-clash-sand-stage-1672x941.png` | 1672 × 941, RGB | **Original, untouched.** Uploaded by Garfield on 2026-11-15 as `3DFAD58B-2779-4DA7-B37E-9CF15C480341.png` at the repository root; moved here unchanged (same bytes) so the root stays a drop zone. |
| `godot/assets/stages/sound_clash_sand_stage_1280x720.png` | 1280 × 720, RGB | Game-ready export (Lanczos resize of the original, no crop, no retouch). |

## What the art contains

Two towering sound-system stacks — left in green/yellow/black with a Jamaican-flag chevron, right in
red/yellow/green with lion-cone cabs — either side of a Jamaican beach yard: palms, jungle, surf,
a blue sky with cumulus, and a wide sand floor in the lower third. The centre of the frame is open
sky and sand, which is what keeps the fighting lane readable without editing the illustration.

## Measurements that drive the level

Measured on the 1672 × 941 original with a sand-colour mask (`r>200, g 140–235, b<160, r−b>90`),
sampled across the centre 28–72 % of the width:

- sand yard begins at **row 660** (centre coverage jumps 0.64 → 0.99 between rows 660 and 670);
- full-width sand coverage is 1.0 by row 680 and stays 1.0 to the bottom edge.

Scaled to the 1280 × 720 export (`720 / 941 = 0.76514`):

- sand yard top edge → **world y ≈ 505**;
- bottom edge → **world y = 720**;
- so the sand band is 505 → 720 and the agreed fighting floor line **y = 600** sits ~95 px into the
  yard, with sand behind and in front of the fighters. No offset or crop was needed.

Speaker pulse centres for the beat thump were taken from the dark-pixel centroid of each stack's
low-frequency cabs: left **(169, 411)**, right **(1099, 425)** in the 1280 × 720 export.

## Export recipe

```bash
python3 - <<'PY'
from PIL import Image
im = Image.open('art-source/stages/sound-clash-sand/sound-clash-sand-stage-1672x941.png')
im.convert('RGB').resize((1280, 720), Image.LANCZOS).save(
    'godot/assets/stages/sound_clash_sand_stage_1280x720.png', optimize=True)
PY
```

The source is 1672 × 941 (1.7768) against 16:9 (1.7778), so the export is very slightly squeezed
(≈0.06 %); no pixels are cropped and nothing is painted in. Artwork was not edited, re-drawn or
upscaled at any point.

## Status

Source art available and wired as the arena background. Stage mechanics and polish built on top of
it are UNAPPROVED pending an on-screen playtest — see `AGENTS.md` §9 and `godot/README.md`.

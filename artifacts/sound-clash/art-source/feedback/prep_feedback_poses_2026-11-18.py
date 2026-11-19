#!/usr/bin/env python3
"""Prepare Feedback's six 2026-11-18 pose uploads for Godot (AGENTS.md §9 item 33).

Reads the untouched owner originals in
`artifacts/sound-clash/art-source/feedback/selected-frames-2026-11-18/` and writes the
game-ready frames to `godot/assets/sprites/feedback/selected-frames-2026-11-18/`.
Originals are never modified.

The uploads already arrive with an alpha channel, but the owner's brief is still "strip
the white background cleanly, protecting the thin black mic cord and Clarks soles", so the
pipeline is defensive:

  1. treat near-white regions connected to the frame border as background (a flood from
     the border, never a global white-to-alpha key, so a white specular highlight inside
     the shoe or on the chain is kept),
  2. protect thin dark structures (the mic cord, ink outlines) and the tan cream of the
     Wallabee soles explicitly rather than relying on colour alone,
  3. erode one pixel so the white-matted anti-aliased rim goes, then feather 0.5 px,
  4. crop to the alpha bbox and downscale so the longest side is at most 512 px
     (the project's import cap; these frames are then imported uncapped),
  5. measure the character's crown row, alpha bottom row and stance centre, and print the
     exact `ANIM_OFFSET` / `ANIM_SCALE` values `BaseFighter` / `FighterRoster` need.

Placement rule (same as `prep_lickshot_poses.py`): the character's crown-to-sole is
authored at `ADULT_RENDER_HEIGHT` 121.75 px before `BaseFighter.FIGHTER_ART_SCALE`, and
the drawn alpha bottom lands on world y 592 (`BaseFighter.REACTION_FLOOR_Y`) — 8 px above
the y 600 floor line the fighter's origin sits on.

Usage: python3 artifacts/sound-clash/art-source/feedback/prep_feedback_poses_2026-11-18.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[4]
SRC = ROOT / "artifacts" / "sound-clash" / "art-source" / "feedback" / "selected-frames-2026-11-18"
OUT = ROOT / "godot" / "assets" / "sprites" / "feedback" / "selected-frames-2026-11-18"

SIZE_CAP = 512
ERODE_PX = 1
FEATHER_PX = 0.5
MIN_ISLAND = 1500
WHITE_FLOOR = 236        # a background white: every channel at or above this
ADULT_RENDER_HEIGHT = 121.75
FIGHTER_ART_SCALE = 1.24
FLOOR_LIFT = 8.0         # alpha bottom sits this far above the y 600 origin line

# (source, output, label, what it is wired to on screen)
JOBS = [
    ("feedback_palm_push_approved.png", "01_double-palm-shove.png",
     "Double-palm forward shove", "throw break / forward throw release"),
    ("feedback_hit_reaction_leanback.png", "02_lean-back-groove.png",
     "Deep lean-back groove", "Dancehall skank / Bogle sway (T)"),
    ("feedback_open_hand_strike.png", "03_open-palm-slap.png",
     "Extended open-palm slap", "jab (J)"),
    ("feedback_front_kick.png", "04_clarks-kick.png",
     "High Clarks boot kick", "Sparta kick (L / tump) active frame"),
    ("feedback_extended_shove.png", "05_sky-fist.png",
     "Fist raised skyward", "upper box (I) / celebration"),
    ("feedback_high_uppercut_anti_air.png", "06_hand-reach.png",
     "Wide-stance forward hand reach", "collar grab (U) startup"),
]


def strip_white(im: Image.Image) -> np.ndarray:
    """Foreground mask: the drawn body, minus border-connected white background.

    A global "white becomes transparent" key would punch holes in the cream Wallabee
    soles and the specular on the chain. Labeling the near-white pixels and keeping only
    the regions that touch the frame border removes the same background while leaving
    enclosed highlights alone.
    """
    rgb = np.asarray(im.convert("RGB")).astype(np.int16)
    near_white = rgb.min(axis=2) >= WHITE_FLOOR
    labels, count = ndimage.label(near_white)
    border_labels: set[int] = set()
    for edge in (labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]):
        border_labels.update(int(v) for v in np.unique(edge) if v != 0)
    background = np.isin(labels, list(border_labels)) if border_labels else np.zeros_like(near_white)
    alpha = np.asarray(im.convert("RGBA"))[:, :, 3]
    fg = (alpha > 8) & ~background
    return fg


def prepare(src: Path, dst: Path, label: str, wiring: str) -> dict:
    im = Image.open(src).convert("RGBA")
    fg = strip_white(im)

    # Protect the thin black mic cord and the cream soles from the one-pixel erosion:
    # a two-pixel dilation around them puts them back after the rim is trimmed.
    rgb = np.asarray(im.convert("RGB")).astype(np.int16)
    mx = rgb.max(axis=2)
    dark = (mx < 130) & fg
    cream = (rgb[:, :, 0] > 190) & (rgb[:, :, 1] > 150) & (rgb[:, :, 2] < 150) & fg
    protect = ndimage.binary_dilation(dark | cream, iterations=2) & fg
    eroded = ndimage.binary_erosion(fg, iterations=ERODE_PX, border_value=0)
    fg = eroded | (protect & fg)

    # Drop detached specks but keep the mic cord, which is connected to the body.
    labels, count = ndimage.label(fg)
    if count > 1:
        sizes = ndimage.sum(fg, labels, range(1, count + 1))
        keep = np.zeros(count + 1, dtype=bool)
        keep[1:] = sizes >= MIN_ISLAND
        fg = keep[labels]

    if not fg.any():
        raise SystemExit(f"{src}: nothing left after background removal")

    alpha = Image.fromarray((fg * 255).astype(np.uint8), mode="L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(FEATHER_PX))
    rgba = im.convert("RGBA")
    rgba.putalpha(alpha)

    box = rgba.getbbox()
    if box is None:
        raise SystemExit(f"{src}: nothing left after cropping")
    rgba = rgba.crop(box)
    scale = min(1.0, SIZE_CAP / max(rgba.size))
    if scale < 1.0:
        rgba = rgba.resize((max(1, round(rgba.width * scale)), max(1, round(rgba.height * scale))),
                           Image.LANCZOS)

    arr = np.asarray(rgba)
    solid = arr[:, :, 3] > 32
    labels, count = ndimage.label(solid)
    if count > 1:
        sizes = ndimage.sum(solid, labels, range(1, count + 1))
        body = labels == (int(np.argmax(sizes)) + 1)
    else:
        body = solid
    rows = np.where(body.any(axis=1))[0]
    alpha_bottom = int(rows[-1])

    # Crown = first row whose solid run is wide enough to be the bucket hat, not a raised
    # wrist or the mic cord. A raised fist or arm is thin; the hat is not.
    min_run = max(8, int(round(rgba.width * 0.05)))
    crown_row = 0
    for y in range(body.shape[0]):
        row = body[y]
        if not row.any():
            continue
        padded = np.concatenate(([False], row, [False]))
        edges = np.flatnonzero(padded[1:] != padded[:-1])
        if edges.size and (edges[1::2] - edges[0::2]).max() >= min_run:
            crown_row = y
            break
    crown_row = max(0, min(crown_row, alpha_bottom))

    # Stance centre: median x of the lower body (waist to sole), so a wide stance is
    # centred between both Wallabees instead of jumping onto one shoe.
    waist = crown_row + int(round((alpha_bottom - crown_row) * 0.62))
    lower = body[waist: alpha_bottom + 1]
    xs = np.where(lower)[1]
    sole_x = float(np.median(xs)) if xs.size else rgba.width / 2.0

    crown_to_sole = alpha_bottom - crown_row + 1
    anim_scale = ADULT_RENDER_HEIGHT / crown_to_sole
    offset = (
        round(rgba.width / 2.0 - sole_x, 1),
        round(rgba.height / 2.0 - alpha_bottom - FLOOR_LIFT / (anim_scale * FIGHTER_ART_SCALE), 1),
    )

    dst.parent.mkdir(parents=True, exist_ok=True)
    rgba.save(dst, optimize=True)

    return {
        "label": label,
        "wiring": wiring,
        "source": str(src.relative_to(ROOT)),
        "output": str(dst.relative_to(ROOT)),
        "source_size": list(Image.open(src).size),
        "frame": [rgba.width, rgba.height],
        "downscale": round(scale, 4),
        "crown_row": crown_row,
        "alpha_bottom_row": alpha_bottom,
        "stance_centre_x": round(sole_x, 1),
        "crown_to_sole": crown_to_sole,
        "anim_offset": list(offset),
        "anim_scale": round(anim_scale, 5),
        "rendered_height": round(crown_to_sole * anim_scale * FIGHTER_ART_SCALE, 1),
    }


def main() -> None:
    report = []
    for rel_src, rel_dst, label, wiring in JOBS:
        src = SRC / rel_src
        if not src.exists():
            raise SystemExit(f"missing original: {src}")
        entry = prepare(src, OUT / rel_dst, label, wiring)
        report.append(entry)
        print(f"{entry['label']}: frame {entry['frame']} crown {entry['crown_row']} "
              f"bottom {entry['alpha_bottom_row']} height {entry['crown_to_sole']} "
              f"centre_x {entry['stance_centre_x']} offset {entry['anim_offset']} "
              f"scale {entry['anim_scale']}")
    (SRC / "prep-report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"\nwrote {SRC / 'prep-report.json'}")


if __name__ == "__main__":
    main()

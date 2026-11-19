#!/usr/bin/env python3
"""Prepare Lickshot's four new pose uploads for Godot (AGENTS.md §9 item 27).

Reads the untouched owner originals in `art-source/fighters/lickshot/` and writes the
game-ready frames to `godot/assets/sprites/lickshot/`. Originals are never modified.

2026-11-19: the seven owner frames added on 2026-11-18 are **pure white** backgrounds,
not the dark plum studio. They are processed by the same script through a separate
`white` keying mode (border flood of near-white plus an erosion pass), while the four
original studio jobs keep their `studio` path untouched. `--only` re-runs just the new
frames so the four approved outputs are not rewritten.

Why this is a separate script from `prep_fighter_art.py`: the first four share one studio
setup (dark plum backdrop, lit sand floor, soft cast shadow) and one placement rule —
character crown-to-sole is authored at 121.75 px before `BaseFighter.FIGHTER_ART_SCALE`,
and the alpha bottom sits on world y 592 (`BaseFighter.REACTION_FLOOR_Y`). The older
script's jobs are tuned to the Dubplate portrait and the Young Selecta sheets.

Pipeline per image:
  1. flood-fill the flat backdrop in from a dense border seed ring,
  2. drop large backdrop-coloured blobs the fill could not reach (the soft cast shadow,
     the vignette pocket sealed off by the mic cable),
  3. remove the lit sand floor and the ground shadow, while protecting thin dark
     structures (the mic cable, ink outlines) and the tan Wallabee leather,
  4. cut everything below the lowest leather pixel,
  5. drop specks, erode one pixel (no pale rim), feather the edge,
  6. crop to the alpha bbox and downscale so the longest side is at most 512 px,
  7. measure the crown row (flat cap), the sole row and the sole centre, then print the
     offset/scale `FighterRoster.gd` needs.

Usage: python3 art-source/fighters/prep_lickshot_poses.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art-source" / "fighters" / "lickshot"
OUT = ROOT / "godot" / "assets" / "sprites" / "lickshot"

SIZE_CAP = 512          # project import cap: longest side of the processed frame
ERODE_PX = 1
FEATHER_PX = 0.5
MIN_ISLAND = 1500      # keeps the idle motion arc, drops sand crumbs

MAGENTA = (255, 0, 255)

# `crown_window` is the x range that holds the flat cap and nothing else: it is how the
# crown is measured without the idle motion arc or the Sonic Clap shockwave being mistaken
# for the top of the character.
JOBS = [
    ("01_mic-stance-idle_original.png", "idle.png", {
        "label": "Lickshot mic stance / idle",
        "crown_window": (300, 560),
    }),
    ("02_high-kick_original.png", "high_kick.png", {
        "label": "Lickshot high kick",
        "crown_window": (140, 380),
    }),
    ("03_sonic-clap-windup_original.png", "sonic_clap_windup.png", {
        "label": "Lickshot Sonic Clap windup",
        "crown_window": (430, 650),
    }),
    ("04_sonic-clap-impact_original.png", "sonic_clap_impact.png", {
        "label": "Lickshot Sonic Clap impact",
        "crown_window": (380, 620),
    }),
    # ---- 2026-11-18 uploads: pure white background, no studio floor or shadow ----
    ("05_left-jab_original.png", "jab.png", {
        "label": "Lickshot left-hand straight jab",
        "background": "white",
        "wiring": "jab (J) — retires the placeholder strike smear",
    }),
    ("06_mic-cross_original.png", "upper_box.png", {
        "label": "Lickshot heavy right-hand mic cross",
        "background": "white",
        "wiring": "upper box (I) heavy strike",
    }),
    ("07_guard-stance_original.png", "guard_stance.png", {
        "label": "Lickshot defensive mic and open-palm guard",
        "background": "white",
        "wiring": "guard entry / held block / blockstun / guard release (S)",
    }),
    ("08_hitstun-recoil_original.png", "hitstun_recoil.png", {
        "label": "Lickshot chin-snap hitstun recoil",
        "background": "white",
        "wiring": "hitstun reaction",
    }),
    ("09_head-back-recoil_original.png", "launched_recoil.png", {
        "label": "Lickshot head-back groove / heavy recoil",
        "background": "white",
        "wiring": "launched / heavy recoil pose",
    }),
    ("10_skank-point_original.png", "skank_point.png", {
        "label": "Lickshot wide gun-finger / mic-point lean",
        "background": "white",
        "wiring": "Dancehall skank / taunt (T)",
    }),
    ("11_arms-open_celebration_original.png", "celebration.png", {
        "label": "Lickshot wide-open arms celebration (mic in cargo pocket)",
        "background": "white",
        "wiring": "collar grab (U) and round victory / Hype Surge",
    }),
]


def key_backdrop(im: Image.Image, thresh: int = 34) -> np.ndarray:
    """Flood-fill the studio backdrop from a dense border seed ring."""
    work = im.convert("RGB").copy()
    w, h = work.size
    seeds: list[tuple[int, int]] = []
    for x in range(0, w, 16):
        seeds += [(x, 0), (x, h - 1)]
    for y in range(0, h, 16):
        seeds += [(0, y), (w - 1, y)]
    for seed in seeds:
        if work.getpixel(seed) == MAGENTA:
            continue
        ImageDraw.floodfill(work, seed, MAGENTA, thresh=thresh)
    arr = np.asarray(work)
    return ~((arr[:, :, 0] == 255) & (arr[:, :, 1] == 0) & (arr[:, :, 2] == 255))


def key_white(im: Image.Image) -> np.ndarray:
    """Foreground mask for the 2026-11-18 pure-white uploads.

    Background is near-white that either touches the frame border or is a large interior
    region: a loop of mic cable seals a white pocket behind the legs in several poses,
    exactly like the studio vignette pocket the older jobs drop. Size separates those
    from legitimate small white highlights (the chain, the mic grille); the cream
    Wallabee soles sit well below the white floor and are never part of the mask.
    """
    rgb = np.asarray(im.convert("RGB")).astype(np.int16)
    near_white = rgb.min(axis=2) >= 236
    labels, count = ndimage.label(near_white)
    if count == 0:
        return np.ones(near_white.shape, dtype=bool)
    border_labels: set[int] = set()
    for edge in (labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]):
        border_labels.update(int(v) for v in np.unique(edge) if v != 0)
    sizes = ndimage.sum(near_white, labels, range(1, count + 1))
    big = {i for i in range(1, count + 1) if sizes[i - 1] >= 1000}
    background = np.isin(labels, list(border_labels | big))
    return ~background


def drop_backdrop_blobs(mask: np.ndarray, rgb: np.ndarray, min_area: int = 3000) -> np.ndarray:
    """Remove large regions that are still backdrop-coloured after the fill.

    The cast shadow and the vignette pocket behind the cable are backdrop colour, but the
    border fill never reaches them (the cable and the body seal them off). The character
    has no large flat backdrop-coloured area, so a size threshold separates them cleanly.
    """
    border_cols = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border_cols, axis=0)
    close = (np.abs(rgb - bg).max(axis=2) <= 13) & mask
    labels, count = ndimage.label(close)
    if count == 0:
        return mask
    sizes = ndimage.sum(close, labels, range(1, count + 1))
    big = np.zeros(count + 1, dtype=bool)
    big[1:] = sizes >= min_area
    return mask & ~big[labels]


def cut_ground(mask: np.ndarray, rgb: np.ndarray) -> tuple[np.ndarray, int]:
    """Remove the lit sand floor and ground shadow; return (mask, sole row).

    Three cues keep the fighter intact:
      * tan Wallabee leather is much brighter and greener than the sand,
      * the mic cable and ink outlines are thin dark structures, so they are protected,
      * the sand itself is warm with a lifted blue channel (B > 48) while the olive cargo
        trousers sit near B 20–45, which is what stops the cut eating the trousers.
    """
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    mx = rgb.max(axis=2)

    leather = (red > 195) & (green > 160) & (blue < 125) & mask
    ys = np.where(leather)[0]
    sole = int(ys.max()) if ys.size else mask.shape[0] - 1

    # Thin dark structures (cable, ink lines) are protected from the ground cut.
    dark = (mx < 120) & (blue >= green - 12) & mask
    dark_labels, dark_count = ndimage.label(dark)
    if dark_count:
        edt = ndimage.distance_transform_edt(dark)
        peaks = ndimage.maximum(edt, dark_labels, range(1, dark_count + 1))
        thin = np.zeros(dark_count + 1, dtype=bool)
        for index, peak in enumerate(peaks, start=1):
            if peak <= 6.0:
                thin[index] = True
        protect = thin[dark_labels]
    else:
        protect = np.zeros_like(mask)
    protect |= ndimage.binary_dilation(leather, iterations=6)

    sand = (blue > 48) & (red > 70) & (green < 110) & ((red - blue) > 25)
    sand_rows = sand.sum(axis=1)
    wide = np.where(sand_rows > mask.shape[1] * 0.25)[0]
    sand_top = int(wide.min()) if wide.size else mask.shape[0]

    ground = np.zeros_like(mask)
    ground[sand_top:] = True
    shade = ground & (sand | ((mx < 120) & (blue >= green - 12))) & ~protect
    out = mask & ~shade
    out[sole + 3:, :] = False
    return out, sole


def restore_small_holes(mask: np.ndarray, max_area: int = 600) -> np.ndarray:
    filled = ndimage.binary_fill_holes(mask)
    holes = filled & ~mask
    if not holes.any():
        return mask
    labels, count = ndimage.label(holes)
    sizes = ndimage.sum(holes, labels, range(1, count + 1))
    out = mask.copy()
    for index in range(1, count + 1):
        if sizes[index - 1] <= max_area:
            out |= labels == index
    return out


def measure_crown(solid: np.ndarray, window: tuple[int, int], min_run: int) -> int:
    """First row in `window` that holds a solid horizontal run — the top of the cap.

    A stray glow pixel or shockwave ray is a couple of pixels wide; the flat cap is not,
    so a minimum run length is what makes this measurement stable across the four poses.
    """
    x0, x1 = window
    x0 = max(0, min(x0, solid.shape[1] - 1))
    x1 = max(x0 + 1, min(x1, solid.shape[1]))
    for y in range(solid.shape[0]):
        row = solid[y, x0:x1]
        if not row.any():
            continue
        # Longest contiguous run in this row.
        padded = np.concatenate(([False], row, [False]))
        edges = np.flatnonzero(padded[1:] != padded[:-1])
        if edges.size and (edges[1::2] - edges[0::2]).max() >= min_run:
            return y
    return 0


def prepare(src: Path, dst: Path, job: dict) -> dict:
    white = job.get("background") == "white"
    im = Image.open(src).convert("RGB")
    rgb = np.asarray(im).astype(np.int16)
    if white:
        # No painted floor or cast shadow to remove: the upload is on plain white.
        fg = key_white(im)
        sole_before_crop = -1
    else:
        fg = key_backdrop(im)
        fg = drop_backdrop_blobs(fg, rgb)
        fg, sole_before_crop = cut_ground(fg, rgb)
    fg = restore_small_holes(fg, 600)

    # Drop detached specks but keep the idle motion arc (a real, larger drawing element).
    labels, count = ndimage.label(fg)
    if count > 1:
        sizes = ndimage.sum(fg, labels, range(1, count + 1))
        keep = np.zeros(count + 1, dtype=bool)
        keep[1:] = sizes >= MIN_ISLAND
        fg = keep[labels]

    # Trim to the fighter's own sole line. Sand crumbs that survive the ground cut hug the
    # Wallabees and would otherwise set a lower alpha bottom than the shoes, so the sprite
    # would be planted a few pixels under the sand line. Everything below the body's lowest
    # row goes, which guarantees alpha bottom == measured sole row.
    labels, count = ndimage.label(fg)
    if count > 1:
        sizes = ndimage.sum(fg, labels, range(1, count + 1))
        body_src = labels == (int(np.argmax(sizes)) + 1)
    else:
        body_src = fg
    sole_body = int(np.where(body_src.any(axis=1))[0][-1])
    fg[sole_body + 1:, :] = False

    eroded = ndimage.binary_erosion(fg, iterations=ERODE_PX, border_value=0)
    if eroded.sum() > fg.sum() * 0.5:
        fg = eroded
    alpha = Image.fromarray((fg * 255).astype(np.uint8), mode="L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(FEATHER_PX))
    rgba = im.convert("RGBA")
    rgba.putalpha(alpha)

    box = rgba.getbbox()
    if box is None:
        raise SystemExit(f"{src}: nothing left after background removal")
    rgba = rgba.crop(box)
    left, top = box[0], box[1]
    scale = min(1.0, SIZE_CAP / max(rgba.size))
    if scale < 1.0:
        rgba = rgba.resize((max(1, round(rgba.width * scale)), max(1, round(rgba.height * scale))),
                           Image.LANCZOS)

    arr = np.asarray(rgba)
    solid = arr[:, :, 3] > 32
    # Placement is measured on the character itself, never on a surviving sand crumb:
    # a stray spec at the frame edge would otherwise set the sole row and sink the fighter.
    labels, count = ndimage.label(solid)
    if count > 1:
        sizes = ndimage.sum(solid, labels, range(1, count + 1))
        body = labels == (int(np.argmax(sizes)) + 1)
    else:
        body = solid
    rows = np.where(body.any(axis=1))[0]
    sole_row = int(rows[-1])
    # Stance centre: the lower body's centre of mass (waist to sole), not one shoe. A wide
    # lunge is centred between both Wallabees, and a high kick keeps its origin under the
    # hips instead of jumping a body-width sideways with the planted support foot.
    if "crown_window" in job:
        wx0, wx1 = job["crown_window"]
        crown_window = (int(round((wx0 - left) * scale)), int(round((wx1 - left) * scale)))
    else:
        # The 2026-11-18 frames have no motion arc or shockwave: the hat is the widest
        # solid run at the top, and a raised wrist is too thin to trip the run test.
        crown_window = (0, rgba.width)
    crown_row = measure_crown(
        body,
        crown_window,
        max(8, int(round(rgba.width * 0.04))),
    )
    crown_row = max(0, min(crown_row, sole_row))

    waist = crown_row + int(round((sole_row - crown_row) * 0.62))
    lower = body[waist: sole_row + 1]
    xs = np.where(lower)[1]
    sole_x = float(np.median(xs)) if xs.size else rgba.width / 2.0
    crown_to_sole = sole_row - crown_row + 1

    dst.parent.mkdir(parents=True, exist_ok=True)
    rgba.save(dst, optimize=True)

    return {
        "label": job["label"],
        "wiring": job.get("wiring", ""),
        "background": job.get("background", "studio"),
        "source": str(src.relative_to(ROOT)),
        "output": str(dst.relative_to(ROOT)),
        "source_size": list(Image.open(src).size),
        "crop_box": list(box),
        "frame": [rgba.width, rgba.height],
        "downscale": round(scale, 4),
        "crown_row": crown_row,
        "sole_row": sole_row,
        "sole_centre_x": round(sole_x, 1),
        "crown_to_sole": crown_to_sole,
        "sole_row_source": sole_before_crop,
    }


def main() -> None:
    # `--only jab.png upper_box.png` re-runs a subset; without it every job runs. The four
    # 2026-11-17 outputs were approved as-is, so the new pass is invoked with --only and
    # the report keeps their original entries.
    wanted = set(sys.argv[sys.argv.index("--only") + 1:]) if "--only" in sys.argv else set()
    report_path = SRC / "prep-report.json"
    report = json.loads(report_path.read_text()) if report_path.exists() else []
    by_output = {entry["output"]: i for i, entry in enumerate(report)}
    for rel_src, rel_dst, job in JOBS:
        if wanted and rel_dst not in wanted:
            continue
        src = SRC / rel_src
        if not src.exists():
            raise SystemExit(f"missing original: {src}")
        entry = prepare(src, OUT / rel_dst, job)
        if entry["output"] in by_output:
            report[by_output[entry["output"]]] = entry
        else:
            by_output[entry["output"]] = len(report)
            report.append(entry)
        print(f"{entry['label']}: frame {entry['frame']} crown {entry['crown_row']} "
              f"sole {entry['sole_row']} height {entry['crown_to_sole']} "
              f"sole_x {entry['sole_centre_x']} downscale {entry['downscale']}")
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"\nwrote {report_path}")


if __name__ == "__main__":
    main()

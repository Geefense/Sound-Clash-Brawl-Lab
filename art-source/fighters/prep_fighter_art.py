#!/usr/bin/env python3
"""Prepare the Fighter #2 / #3 uploads for Godot (AGENTS.md §9).

Reads the untouched originals in art-source/fighters/ and writes game-ready PNGs to
godot/assets/sprites/<fighter>/. The originals are never modified.

What it does per image:
  1. flood-fills the flat studio background from every border corner,
  2. drops tiny disconnected specks (pencil marks, JPEG crumbs) that survive the fill,
  3. feathers the alpha edge by one pixel so there is no white halo,
  4. crops to the alpha bounding box,
  5. downscales so the longest side is at most 512 px (the project import cap),
  6. prints the sole row / sole centre / figure height that FighterRoster.gd needs
     for its offset and scale compensation.

Usage: python3 art-source/fighters/prep_fighter_art.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art-source" / "fighters"
OUT = ROOT / "godot" / "assets" / "sprites"

SIZE_CAP = 512          # import cap: longest side of the processed frame
ERODE_PX = 1            # bite one pixel in, so the antialiased studio rim never shows
FEATHER_PX = 0.5
MIN_ISLAND = 400        # px area a detached blob needs to be kept

# (source, destination, floodfill tolerance, hole settings, label).
#   tolerance  = per-channel distance from each corner seed colour. The white
#                backdrops are flat; the Dubplate studio vignette plus its lit floor
#                needs a much wider net.
#   hole       = (min_area, colour tolerance) for enclosed background pockets the
#                border fill cannot reach (between the arm and the stand, between the
#                legs). None disables the pass.
JOBS = [
    # The Dubplate portrait is the one image whose backdrop is a painted vignette with
    # a cast shadow. The mic cable seals that shadow into a pocket the border fill can
    # never enter, so it is cleared by a smooth-area growth seeded inside the pocket
    # ("pocket_seeds"), then any remaining uniform-backdrop fragment is dropped and the
    # art's own enclosed flecks are restored. See the options block below.
    # The 2026-11-17 placeholder portrait, superseded by Lickshot's four-pose set (§9 item 27)
    # and kept only as archived provenance. Its output path follows the archive so a rerun can
    # never resurrect a `dubplate/` sprite folder in the game tree.
    ("dubplate/dubplate-selector-portrait_original.png",
     "lickshot/_archive/portrait_2026-11-17_placeholder.png", (40, 170), None,
     "Lickshot placeholder portrait (archived)",
     {"keep_frac": 0.15, "ground_cut": 1395, "shadow_cut": (0.55, 1.35, 90),
      "pocket_seeds": [(200, 900), (250, 1050), (150, 1100), (350, 1150),
                       (300, 950), (400, 1000), (540, 1100), (520, 1050),
                       (560, 1180), (500, 1000), (500, 1150)],
      "pocket_gradient": 12,
      "uniform_pockets": (400, 20, 14),   # (min_area, backdrop tolerance, max std)
      "fill_holes_max": 2000}),
    ("young-selecta/01_idle-backpack_original.png",
     "young-selecta/idle.png", (16, 255), (240, 6), "Young Selecta idle",
     {"big_holes": (3000, 10), "rim": (4, 232)}),
    ("young-selecta/02_boom-mic-thrust_original.png",
     "young-selecta/thrust.png", (16, 255), (240, 6), "Young Selecta boom-mic thrust",
     {"big_holes": (3000, 10), "rim": (4, 232)}),
    ("young-selecta/03_mic-stand-slam_original.jpeg",
     "young-selecta/slam.png", (18, 255), (240, 6), "Young Selecta mic-stand slam",
     {"big_holes": (900, 10), "rim": (6, 230)}),
]

MAGENTA = (255, 0, 255)


def strip_background(im: Image.Image, tolerance: tuple[int, int] | int) -> np.ndarray:
    """Return a boolean background mask, grown in from every edge seed.

    `tolerance` is either one number or `(thresh, bright_guard)`. Seeding the whole
    border (not just four corners) is what clears a studio floor gradient: each seed
    only has to bridge its own neighbourhood. `bright_guard` skips bright edge pixels
    so a lit shoe that touches an edge is never used as a background seed.
    """
    thresh, bright_guard = tolerance if isinstance(tolerance, tuple) else (tolerance, 255)
    rgb = im.convert("RGB")
    work = rgb.copy()
    w, h = work.size
    seeds: list[tuple[int, int]] = []
    for x in range(0, w, 24):
        seeds.append((x, 0))
        seeds.append((x, h - 1))
    for y in range(0, h, 24):
        seeds.append((0, y))
        seeds.append((w - 1, y))
    for seed in seeds:
        pixel = work.getpixel(seed)
        if pixel == MAGENTA or max(pixel) > bright_guard:
            continue
        ImageDraw.floodfill(work, seed, MAGENTA, thresh=thresh)
    arr = np.asarray(work)
    return (arr[:, :, 0] == 255) & (arr[:, :, 1] == 0) & (arr[:, :, 2] == 255)


def drop_islands(mask: np.ndarray, min_area: int) -> np.ndarray:
    """Remove small detached foreground blobs (the slam source has a pencil mark)."""
    from scipy import ndimage
    labels, count = ndimage.label(mask)
    if count <= 1:
        return mask
    sizes = ndimage.sum(mask, labels, range(1, count + 1))
    keep = np.zeros(count + 1, dtype=bool)
    keep[1:] = sizes >= min_area
    return keep[labels]


def fill_holes(mask: np.ndarray, rgb: np.ndarray, min_area: int, tol: int) -> np.ndarray:
    """Clear flat background pockets the border flood fill cannot reach.

    Only enclosed regions whose mean colour matches the studio backdrop within `tol`
    are removed, and only above `min_area`, so shoe highlights and shirt creases that
    happen to be bright stay part of the character.
    """
    from scipy import ndimage
    background = ~mask
    labels, count = ndimage.label(background)
    if count <= 1:
        return mask
    touches_border = set(labels[0, :]) | set(labels[-1, :]) \
        | set(labels[:, 0]) | set(labels[:, -1])
    border_cols = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    bg_colour = np.median(border_cols, axis=0)
    sizes = ndimage.sum(background, labels, range(1, count + 1))
    out = mask.copy()
    for index in range(1, count + 1):
        if index in touches_border or sizes[index - 1] < min_area:
            continue
        region = labels == index
        mean = rgb[region].mean(axis=0)
        if np.abs(mean - bg_colour).max() <= tol:
            out[region] = False
    return out


def clear_smooth_pocket(mask: np.ndarray, rgb: np.ndarray, seeds, gradient: int) -> np.ndarray:
    """Clear a background pocket that the border fill cannot reach.

    The Dubplate backdrop is a painted vignette with a cast shadow, and the mic cable
    closes a loop around part of it. A plain colour fill leaks across the artwork's own
    soft shading, so the growth is limited to low-gradient pixels: it travels the flat
    backdrop and the flat shadow, then stops at the drawing's ink outlines. `seeds` are
    points inside the pocket (source pixels).
    """
    from scipy import ndimage
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    grad = np.hypot(ndimage.sobel(lum, 0), ndimage.sobel(lum, 1))
    allowed = (grad < gradient) & mask
    grown = np.zeros_like(mask)
    for x, y in seeds:
        if 0 <= y < grown.shape[0] and 0 <= x < grown.shape[1]:
            grown[y, x] = True
    structure = ndimage.generate_binary_structure(2, 1)
    for _ in range(800):
        nxt = ndimage.binary_dilation(grown, structure, 1) & allowed
        if nxt.sum() == grown.sum():
            break
        grown = nxt
    return mask & ~grown


def drop_uniform_pockets(mask: np.ndarray, rgb: np.ndarray, min_area: int, tol: int,
                         max_std: float) -> np.ndarray:
    """Drop detached components that are flat studio backdrop.

    A cast shadow's leftovers and the gaps between the legs are uniform backdrop with a
    near-zero deviation, while the trousers and shoes are textured. Requiring both a
    backdrop-matching median colour and a low deviation is what keeps this from punching
    holes in the character, so never replace it with a per-pixel colour test.
    """
    from scipy import ndimage
    labels, count = ndimage.label(mask)
    if count <= 1:
        return mask
    sizes = ndimage.sum(mask, labels, range(1, count + 1))
    border_cols = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    bg_colour = np.median(border_cols, axis=0)
    out = mask.copy()
    for index in range(1, count + 1):
        if sizes[index - 1] < min_area:
            continue
        component = labels == index
        pixels = rgb[component]
        median = np.median(pixels, axis=0)
        if np.abs(median - bg_colour).max() <= tol and pixels.std(axis=0).max() < max_std:
            out[component] = False
    return out


def restore_small_holes(mask: np.ndarray, max_area: int) -> np.ndarray:
    """Re-seal the art's own tiny enclosed flecks after the pocket passes.

    The border flood fill and the pocket growth both leave pinprick holes inside the
    trousers' texture. Anything enclosed and smaller than `max_area` is drawing, not
    backdrop, so it goes back to opaque.
    """
    from scipy import ndimage
    filled = ndimage.binary_fill_holes(mask)
    holes = filled & ~mask
    if not holes.any():
        return mask
    labels, count = ndimage.label(holes)
    sizes = ndimage.sum(holes, labels, range(1, count + 1))
    out = mask.copy()
    for index in range(1, count + 1):
        if sizes[index - 1] < max_area:
            out |= labels == index
    return out


def keep_largest(mask: np.ndarray, fraction: float) -> np.ndarray:
    """Keep only the character: the biggest blob, plus anything close to its size."""
    from scipy import ndimage
    labels, count = ndimage.label(mask)
    if count <= 1:
        return mask
    sizes = ndimage.sum(mask, labels, range(1, count + 1))
    biggest = float(sizes.max())
    keep = np.zeros(count + 1, dtype=bool)
    keep[1:] = sizes >= biggest * fraction
    return keep[labels]


def clear_big_pockets(fg: np.ndarray, rgb: np.ndarray, min_area: int, tol: int) -> np.ndarray:
    """Remove backdrop pockets too big for the silhouette to hide and too enclosed for
    the border fill to reach (the gap between a limb and the mic stand). Shoe highlights
    are the same colour, so anything under `min_area` is left alone."""
    from scipy import ndimage
    border_cols = np.concatenate([rgb[0, :], rgb[-1, :], rgb[:, 0], rgb[:, -1]])
    bg_colour = np.median(border_cols, axis=0)
    near_bg = np.abs(rgb - bg_colour).max(axis=2) <= tol
    labels, count = ndimage.label(near_bg)
    touches_border = set(labels[0, :]) | set(labels[-1, :]) \
        | set(labels[:, 0]) | set(labels[:, -1])
    sizes = ndimage.sum(near_bg, labels, range(1, count + 1))
    out = fg.copy()
    for index in range(1, count + 1):
        if index in touches_border or sizes[index - 1] < min_area:
            continue
        out[labels == index] = False
    return out


def prepare(src: Path, dst: Path, tolerance, hole, options) -> dict:
    im = Image.open(src)
    bg = strip_background(im, tolerance)
    fg = ~bg
    rgb = np.asarray(im.convert("RGB")).astype(np.int16)
    if hole is not None:
        fg = fill_holes(fg, rgb, hole[0], hole[1])
    if options.get("pocket_seeds"):
        fg = clear_smooth_pocket(fg, rgb, options["pocket_seeds"],
                                 int(options.get("pocket_gradient", 12)))
    if options.get("big_holes"):
        fg = clear_big_pockets(fg, rgb, options["big_holes"][0], options["big_holes"][1])
    if options.get("keep_frac"):
        fg = keep_largest(fg, options["keep_frac"])
    fg = drop_islands(fg, MIN_ISLAND)
    if options.get("ground_cut") is not None:
        fg[options["ground_cut"]:] = False
    if options.get("rim"):
        # The kid art carries a white keyline. Trim the near-white pixels that hug the
        # transparent edge (the shirt and the sneakers are not within a few px of it).
        from scipy import ndimage
        reach, white_min = options["rim"]
        near_edge = ndimage.binary_dilation(~fg, iterations=reach)
        white = rgb.min(axis=2) >= white_min
        fg &= ~(white & near_edge)
    if options.get("shadow_cut"):
        # Painted floor shadows are a much redder maroon than the olive trousers or the
        # yellow Wallabees, so a red-dominance test below the waist removes the smudges
        # without touching the character.
        y_frac, ratio, min_red = options["shadow_cut"]
        start = int(fg.shape[0] * y_frac)
        band = fg[start:].copy()
        red = rgb[start:, :, 0]
        green = rgb[start:, :, 1]
        reddish = (red > min_red) & (red > green * ratio)
        band &= ~reddish
        fg[start:] = band
    if options.get("uniform_pockets"):
        fg = drop_uniform_pockets(fg, rgb, *options["uniform_pockets"])
    if options.get("fill_holes_max"):
        fg = restore_small_holes(fg, int(options["fill_holes_max"]))

    # Bite one pixel in (no white rim from the antialiased studio edge), then feather.
    from scipy import ndimage
    eroded = ndimage.binary_erosion(fg, iterations=ERODE_PX, border_value=0)
    if eroded.sum() > fg.sum() * 0.5:      # never let erosion eat a thin silhouette
        fg = eroded
    alpha = Image.fromarray((fg * 255).astype(np.uint8), mode="L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(FEATHER_PX))
    rgba = im.convert("RGBA")
    rgba.putalpha(alpha)

    box = rgba.getbbox()
    if box is None:
        raise SystemExit(f"{src}: nothing left after background removal")
    rgba = rgba.crop(box)

    scale = min(1.0, SIZE_CAP / max(rgba.size))
    if scale < 1.0:
        rgba = rgba.resize(
            (max(1, round(rgba.width * scale)), max(1, round(rgba.height * scale))),
            Image.LANCZOS,
        )

    arr = np.asarray(rgba)
    solid = arr[:, :, 3] > 32
    rows = np.where(solid.any(axis=1))[0]
    sole_row = int(rows[-1])
    foot = solid[max(0, sole_row - 3): sole_row + 1]
    cols = np.where(foot.any(axis=0))[0]
    sole_x = float(cols.mean()) if cols.size else rgba.width / 2.0

    dst.parent.mkdir(parents=True, exist_ok=True)
    rgba.save(dst, optimize=True)

    return {
        "source": str(src.relative_to(ROOT)),
        "output": str(dst.relative_to(ROOT)),
        "source_size": list(Image.open(src).size),
        "crop_box": list(box),
        "frame": [rgba.width, rgba.height],
        "downscale": round(scale, 4),
        "sole_row": sole_row,
        "sole_centre_x": round(sole_x, 1),
        # Offsets are authored in the processed frame's pixels, like the Feedback pack.
        "offset": [round(rgba.width / 2.0 - sole_x, 1), round(rgba.height / 2.0 - sole_row, 1)],
        "figure_height": int(rows[-1] - rows[0] + 1),
    }


def main() -> None:
    report = []
    for rel_src, rel_dst, tol, hole, label, options in JOBS:
        src = SRC / rel_src
        if not src.exists():
            raise SystemExit(f"missing original: {src}")
        entry = prepare(src, OUT / rel_dst, tol, hole, options)
        entry["label"] = label
        report.append(entry)
        print(f"{label}: {entry['frame']} sole_y={entry['sole_row']} "
              f"sole_x={entry['sole_centre_x']} h={entry['figure_height']} "
              f"offset={entry['offset']} downscale={entry['downscale']}")
    (SRC / "prep-report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"\nwrote {SRC / 'prep-report.json'}")


if __name__ == "__main__":
    main()

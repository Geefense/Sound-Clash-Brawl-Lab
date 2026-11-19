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
import math
import os
import shutil
import subprocess
import sys
import tempfile
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


# =========================================================================
# 2026-11-19 creator-approved animation batch
# =========================================================================
## The owner approved and uploaded four L!ckshot animation sources on 2026-11-19. They are
## different renders from the four approved studio poses and the 2026-11-18 white set, so
## they get their own pass instead of being forced through either older job table:
##
##   lickshot_bossy_walk_phone.mov  3.0 s / 30 fps signature selector walk
##   IMG_6636.jpeg                 8-pose lean-back / skank sheet, 2 rows x 4
##   IMG_6643.jpeg                 12-pose hit / launch / knockdown sheet, 3 rows x 4
##   IMG_6644.jpeg                 single airborne C-recoil launch pose
##
## Every source is on pure white, so the key is "not near-white" (minimum channel at least
## 236 with less than 14 of saturation): that removes the flat white *and* the white pocket
## sealed inside the mic-cable loop without a flood fill, while the black mic cord, cream
## Clarks soles and silver mic grille all sit far below the threshold.
##
## Floor rule: every processed frame is composed into a canvas whose lowest alpha row is
## `H - 1`, and `anim_offset.y` is derived from world y 592 (`REACTION_FLOOR_Y`) and the
## 600 floor line the fighter origin stands on. The canvas is symmetric around the pose's
## stance centre, which is why every offset in this batch has x = 0.
##
## Scale rule: `anim_scale = 121.75 / reference standing height` in that source's own
## pixels. Airborne and lying frames keep the standing frames' pixel scale, so L!ckshot
## never changes size when he is launched, and every animation in a group shares one scale.

BATCH_DIR = SRC / "batch-2026-11-19"
WALK_VIDEO = BATCH_DIR / "lickshot_bossy_walk_phone.mov"
WALK_RAW = BATCH_DIR / "walk-frames"
SKANK_SHEET = BATCH_DIR / "IMG_6636.jpeg"
HIT_SHEET = BATCH_DIR / "IMG_6643.jpeg"
C_RECOIL_IMAGE = BATCH_DIR / "IMG_6644.jpeg"

ADULT_AUTHORED_HEIGHT = 121.75   # same crown-to-sole the approved poses use
ART_SCALE = 1.24                 # BaseFighter.FIGHTER_ART_SCALE
ORIGIN_FLOOR_Y = 600.0           # fighter origin / sprite sole line before the lift
REACTION_FLOOR_Y = 592.0         # BaseFighter.REACTION_FLOOR_Y
CANVAS_TOP_MARGIN = 2            # keeps the cap from touching row 0
WALK_FRAME_TARGET = 6            # owner asked for 4 to 6 stride frames
# The C-recoil upload is drawn about 1.98x larger than the 12-pose sheet: the silver mic
# cap measures 159 px wide there versus ~71 px in the sheet (2.3x). Resampling by that ratio
# puts it back into the sheet's pixel scale before it joins the `launched` sequence.
C_RECOIL_SCALE_MATCH = 2.32


def _white_key(rgb: np.ndarray) -> np.ndarray:
    """Foreground mask for a pure-white upload (see the background rule above)."""
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    fg = ~((mn >= 236) & ((mx - mn) <= 14))
    # JPEG ringing can puncture a dark area with one- or two-pixel white specks; fill only
    # those pinpricks so the silver grille keeps its shading without becoming a sieve.
    filled = ndimage.binary_fill_holes(fg)
    holes = filled & ~fg
    labels, count = ndimage.label(holes)
    if count:
        sizes = ndimage.sum(holes, labels, range(1, count + 1))
        tiny = np.zeros(count + 1, dtype=bool)
        tiny[1:] = sizes <= 30
        fg |= tiny[labels]
    labels, count = ndimage.label(fg, structure=np.ones((3, 3)))
    if count:
        sizes = ndimage.sum(fg, labels, range(1, count + 1))
        keep = np.zeros(count + 1, dtype=bool)
        keep[1:] = sizes >= 120
        fg = keep[labels]
    return fg


def _runs(flags: np.ndarray) -> list[tuple[int, int]]:
    out: list[tuple[int, int]] = []
    start = None
    for index, value in enumerate(flags):
        if value and start is None:
            start = index
        if not value and start is not None:
            out.append((start, index - 1))
            start = None
    if start is not None:
        out.append((start, len(flags) - 1))
    return out


def slice_white_sheet(path: Path, expected_rows: int) -> tuple[Image.Image, list[dict]]:
    """Split a white-background sheet into its row of four poses per row band.

    Rows are found from the foreground projection (the sheet leaves a white gutter between
    rows); inside each row band the four figures are separate connected components, which is
    what keeps the airborne row apart even where two poses overlap in x.
    """
    im = Image.open(path).convert("RGB")
    rgb = np.asarray(im).astype(np.int16)
    fg = _white_key(rgb)
    bands = [band for band in _runs(fg.sum(axis=1) > 2) if band[1] - band[0] > 40]
    if len(bands) != expected_rows:
        raise SystemExit(f"{path.name}: expected {expected_rows} pose rows, found {len(bands)}")
    poses: list[dict] = []
    for row_index, (y0, y1) in enumerate(bands):
        band = fg[y0:y1 + 1]
        labels, count = ndimage.label(band, structure=np.ones((3, 3)))
        sizes = ndimage.sum(band, labels, range(1, count + 1))
        blobs = []
        for index in range(1, count + 1):
            if sizes[index - 1] < 3000:
                continue
            ys, xs = np.where(labels == index)
            blobs.append((float(xs.mean()), index, int(xs.min()), int(ys.min()) + y0,
                          int(xs.max()) + 1, int(ys.max()) + y0 + 1))
        blobs.sort()
        if len(blobs) != 4:
            raise SystemExit(f"{path.name}: row {row_index + 1} holds {len(blobs)} poses, expected 4")
        for col, (_cx, index, x0, pose_y0, x1, pose_y1) in enumerate(blobs, start=1):
            # The 8-pose upload's bottom row sits on the sheet's last row, so its soles are
            # flush with the edge; that alpha bottom is the sole line the floor rule uses.
            # Clipping on the top/left/right would cut a hat, hand or cable, so only that is
            # an error.
            if x0 <= 0 or pose_y0 <= 0 or x1 >= im.width:
                raise SystemExit(
                    f"{path.name}: pose {row_index + 1}-{col} is clipped sideways or at the top")
            mask = np.zeros_like(fg)
            mask[y0:y1 + 1] = labels == index
            poses.append({
                "sheet": path.name,
                "row": row_index + 1,
                "col": col,
                "mask": mask,
                "bbox": (x0, pose_y0, x1, pose_y1),
            })
    return im, poses


def single_white_pose(path: Path) -> tuple[Image.Image, dict]:
    im = Image.open(path).convert("RGB")
    fg = _white_key(np.asarray(im).astype(np.int16))
    labels, count = ndimage.label(fg, structure=np.ones((3, 3)))
    if count == 0:
        raise SystemExit(f"{path.name}: nothing left after background removal")
    sizes = ndimage.sum(fg, labels, range(1, count + 1))
    index = int(np.argmax(sizes)) + 1
    ys, xs = np.where(labels == index)
    x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
    if x0 <= 0 or y0 <= 0 or x1 >= im.width or y1 >= im.height:
        raise SystemExit(f"{path.name}: the pose is clipped by the image edge")
    return im, {
        "sheet": path.name, "row": 1, "col": 1,
        "mask": labels == index, "bbox": (x0, y0, x1, y1),
    }


def _pose_sprite(im: Image.Image, pose: dict, stance_mode: str) -> dict:
    """Crop one pose, key its alpha, and measure its stance centre and height."""
    x0, y0, x1, y1 = pose["bbox"]
    mask = pose["mask"][y0:y1, x0:x1]
    eroded = ndimage.binary_erosion(mask, iterations=ERODE_PX, border_value=0)
    if eroded.sum() > mask.sum() * 0.5:
        mask = eroded
    alpha = Image.fromarray((mask * 255).astype(np.uint8), mode="L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(FEATHER_PX))
    rgba = im.crop((x0, y0, x1, y1)).convert("RGBA")
    rgba.putalpha(alpha)
    if stance_mode == "lower_body":
        # Waist-to-sole median x: the origin stays between the feet instead of following a
        # swinging arm or a wide lunge across the walk cycle.
        height = mask.shape[0]
        waist = int(round((height - 1) * 0.62))
        xs = np.where(mask[waist:])[1]
    else:
        # Airborne / grounded reaction poses have no planted sole to centre on.
        xs = np.where(mask)[1]
    stance = float(np.median(xs)) if xs.size else rgba.width / 2.0
    return {
        "rgba": rgba,
        "stance": stance,
        "height": float(rgba.height),
        "source": f"{pose['sheet']} row {pose['row']} col {pose['col']}",
    }


def _resample_sprite(sprite: dict, factor: float) -> dict:
    if abs(factor - 1.0) < 1e-6:
        return dict(sprite)
    out = dict(sprite)
    width = max(1, int(round(sprite["rgba"].width * factor)))
    height = max(1, int(round(sprite["rgba"].height * factor)))
    out["rgba"] = sprite["rgba"].resize((width, height), Image.LANCZOS)
    out["stance"] = sprite["stance"] * factor
    out["height"] = sprite["height"] * factor
    return out


def _canvas_size(sprites: list[dict]) -> tuple[int, int]:
    left = max(sprite["stance"] for sprite in sprites)
    right = max(sprite["rgba"].width - sprite["stance"] for sprite in sprites)
    width = int(math.ceil(2.0 * max(left, right)))
    height = max(sprite["rgba"].height for sprite in sprites) + CANVAS_TOP_MARGIN
    return max(width, 2), height


def build_animation(name: str, sprites: list[dict], world_per_px: float, fps: float,
                    label: str, wiring: str) -> dict:
    """Compose one animation's frames on a shared canvas and write them as PNGs.

    Shared canvas + shared scale is what lets a single `anim_offset` keep every frame of a
    loop on the same floor line: the pose's stance centre is the canvas centre and its sole
    row is the canvas's last row.
    """
    factor = 1.0
    width, height = _canvas_size(sprites)
    if max(width, height) > SIZE_CAP:
        factor = SIZE_CAP / float(max(width, height))
        sprites = [_resample_sprite(sprite, factor) for sprite in sprites]
        width, height = _canvas_size(sprites)
        if max(width, height) > SIZE_CAP:
            second = SIZE_CAP / float(max(width, height))
            sprites = [_resample_sprite(sprite, second) for sprite in sprites]
            factor *= second
            width, height = _canvas_size(sprites)
    anim_scale = world_per_px / factor
    offset_y = (1.0 - height / 2.0
                - (ORIGIN_FLOOR_Y - REACTION_FLOOR_Y) / (anim_scale * ART_SCALE))
    paths: list[str] = []
    for frame_index, sprite in enumerate(sprites, start=1):
        frame = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        x = int(round(width / 2.0 - sprite["stance"]))
        y = height - sprite["rgba"].height
        frame.alpha_composite(sprite["rgba"], (x, y))
        suffix = "" if len(sprites) == 1 else f"_{frame_index:02d}"
        path = OUT / f"{name}{suffix}.png"
        frame.save(path, optimize=True)
        paths.append(str(path.relative_to(ROOT)))
    first_frame = f"{name}.png" if len(sprites) == 1 else f"{name}_01.png"
    alpha = np.asarray(Image.open(OUT / first_frame))
    solid = alpha[:, :, 3] > 32
    rows = np.where(solid.any(axis=1))[0]
    crown_row = int(rows[0]) if rows.size else 0
    entry = {
        "batch": "2026-11-19",
        "label": label,
        "wiring": wiring,
        "animation": name,
        "fps": fps,
        "frame_count": len(sprites),
        "sources": [sprite["source"] for sprite in sprites],
        "frames": paths,
        "frame": [width, height],
        "downscale": round(factor, 4),
        "crown_row": crown_row,
        "sole_row": height - 1,
        "stance_centre_x": width / 2.0,
        "anim_scale": round(anim_scale, 5),
        "anim_offset": [0.0, round(offset_y, 2)],
        "anim_source_max": max(width, height),
    }
    print(f"{name}: {len(sprites)} frame(s) {width}x{height} scale {anim_scale:.5f} "
          f"offset {entry['anim_offset']} fps {fps}")
    return entry


def _extract_walk_frames() -> list[Path]:
    """Pick evenly spaced stride frames, rejecting poses clipped by the phone-video crop."""
    if WALK_RAW.exists():
        cached = sorted(WALK_RAW.glob("frame-*.png"))
        if cached:
            return cached
    ffmpeg = os.environ.get("FFMPEG") or shutil.which("ffmpeg")
    if ffmpeg is None:
        raise SystemExit("ffmpeg is required to extract the walk video; set FFMPEG=/path/to/ffmpeg")
    temp = Path(tempfile.mkdtemp(prefix="lickshot-walk-"))
    subprocess.run([ffmpeg, "-v", "error", "-i", str(WALK_VIDEO), "-vsync", "0",
                    str(temp / "raw-%03d.png")], check=True)
    raw = sorted(temp.glob("raw-*.png"))
    if not raw:
        raise SystemExit("ffmpeg produced no walk frames")
    unique: list[tuple[Path, np.ndarray]] = []
    for path in raw:
        im = Image.open(path).convert("RGB")
        fg = _white_key(np.asarray(im).astype(np.int16))
        rows = np.where(fg.any(axis=1))[0]
        cols = np.where(fg.any(axis=0))[0]
        if not rows.size or not cols.size:
            continue
        # The phone video is framed tight (its cap crown and the outer cable loop are
        # already cropped in the source), but a frame whose feet are cut would break the
        # y 592 contact rule, so those are rejected outright.
        if rows[-1] >= im.height - 2:
            continue
        small = np.asarray(im.convert("L").resize((174, 232))).astype(np.int16)
        if unique and np.abs(small - unique[-1][1]).mean() < 2.0:
            continue
        unique.append((path, small))
    if len(unique) < WALK_FRAME_TARGET:
        raise SystemExit(f"only {len(unique)} clean walk poses found")
    picks = [round(i * (len(unique) - 1) / (WALK_FRAME_TARGET - 1))
             for i in range(WALK_FRAME_TARGET)]
    WALK_RAW.mkdir(parents=True, exist_ok=True)
    chosen: list[Path] = []
    manifest = []
    for index, pick in enumerate(picks, start=1):
        source = unique[pick][0]
        destination = WALK_RAW / f"frame-{index:02d}.png"
        shutil.copyfile(source, destination)
        chosen.append(destination)
        manifest.append({"frame": f"frame-{index:02d}.png",
                         "video_frame": int(source.stem.split("-")[1])})
    (WALK_RAW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    shutil.rmtree(temp, ignore_errors=True)
    return chosen


def _preview(entries: list[dict]) -> None:
    """One review sheet: every processed frame with its sole on a common sand line."""
    if not entries:
        return
    cell_w, cell_h = 260, 300
    cols = 6
    rows = (len(entries) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (34, 28, 24))
    draw = ImageDraw.Draw(sheet)
    for index, entry in enumerate(entries):
        x0 = (index % cols) * cell_w
        y0 = (index // cols) * cell_h
        draw.text((x0 + 6, y0 + 4), entry["animation"], fill=(255, 224, 130))
        frame = Image.open(ROOT / entry["frames"][0]).convert("RGBA")
        scale = min(1.0, 200.0 / max(frame.width, frame.height))
        frame = frame.resize((max(1, int(frame.width * scale)),
                              max(1, int(frame.height * scale))), Image.LANCZOS)
        baseline = y0 + cell_h - 40
        draw.line((x0, baseline, x0 + cell_w - 1, baseline), fill=(196, 148, 78), width=2)
        sheet.paste(frame, (x0 + (cell_w - frame.width) // 2, baseline - frame.height), frame)
    out = BATCH_DIR / "preview-batch-2026-11-19.png"
    sheet.save(out, optimize=True)
    print(f"preview: {out.relative_to(ROOT)}")


def prepare_batch() -> None:
    """Run the 2026-11-19 walk / skank / reaction batch."""
    report_path = SRC / "prep-report.json"
    report = json.loads(report_path.read_text()) if report_path.exists() else []
    report = [entry for entry in report if entry.get("batch") != "2026-11-19"]

    # ---- Walk ------------------------------------------------------------
    walk_files = _extract_walk_frames()
    walk_sprites = []
    for path in walk_files:
        im = Image.open(path).convert("RGB")
        pose = {"sheet": f"batch-2026-11-19/walk-frames/{path.name}", "row": 1, "col": 1,
                "mask": _white_key(np.asarray(im).astype(np.int16))}
        fg = pose["mask"]
        rows = np.where(fg.any(axis=1))[0]
        cols = np.where(fg.any(axis=0))[0]
        pose["bbox"] = (int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1)
        walk_sprites.append(_pose_sprite(im, pose, "lower_body"))
    walk_reference = float(np.median([sprite["height"] for sprite in walk_sprites]))
    walk_world = ADULT_AUTHORED_HEIGHT / walk_reference
    entries = [build_animation(
        "walk", walk_sprites, walk_world, WALK_FRAME_TARGET / (2.0 * 60.0 / 132.0),
        "L!ckshot signature selector walk", "walk loop — replaces the recycled idle walk")]

    # ---- 8-pose skank ----------------------------------------------------
    skank_im, skank_poses = slice_white_sheet(SKANK_SHEET, 2)
    skank_sprites = [_pose_sprite(skank_im, pose, "lower_body") for pose in skank_poses]
    skank_world = ADULT_AUTHORED_HEIGHT / skank_sprites[0]["height"]
    for index, sprite in enumerate(skank_sprites, start=1):
        entries.append(build_animation(
            f"skank_{index}", [sprite], skank_world, 1.0,
            f"L!ckshot lean-back / skank groove pose {index}",
            "T skank taunt sequence (one pose per eighth note)"))

    # ---- 12-pose reactions + the single C-recoil -------------------------
    hit_im, hit_poses = slice_white_sheet(HIT_SHEET, 3)
    hit_world = ADULT_AUTHORED_HEIGHT / _pose_sprite(hit_im, hit_poses[0], "lower_body")["height"]
    standing = [_pose_sprite(hit_im, pose, "lower_body") for pose in hit_poses[0:4]]
    airborne = [_pose_sprite(hit_im, pose, "bbox") for pose in hit_poses[4:8]]
    grounded = [_pose_sprite(hit_im, pose, "bbox") for pose in hit_poses[8:12]]
    c_im, c_pose = single_white_pose(C_RECOIL_IMAGE)
    c_recoil = _resample_sprite(_pose_sprite(c_im, c_pose, "bbox"), 1.0 / C_RECOIL_SCALE_MATCH)
    entries.append(build_animation(
        "hitstun", standing, hit_world, 12.0,
        "L!ckshot standing hitstun recoil (4 poses)", "hitstun reaction (4-frame recoil)"))
    entries.append(build_animation(
        "launched", [c_recoil] + airborne[0:2], hit_world, 10.0,
        "L!ckshot C-recoil launch + airborne poses",
        "launched (C-recoil, then the first two airborne poses)"))
    entries.append(build_animation(
        "tumble", airborne[2:4], hit_world, 6.0,
        "L!ckshot airborne tumble poses", "tumble (the last two airborne poses)"))
    entries.append(build_animation(
        "knockdown", grounded[0:2], hit_world, 4.0,
        "L!ckshot grounded knockdown poses", "knockdown (seated floor poses)"))
    entries.append(build_animation(
        "ko", grounded[2:4], hit_world, 2.5,
        "L!ckshot grounded KO poses", "ko (prone floor poses)"))

    report.extend(entries)
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"\nwrote {report_path.relative_to(ROOT)} ({len(entries)} batch entries)")
    _preview(entries)


def main() -> None:
    # `--only jab.png upper_box.png` re-runs a subset; without it every job runs. The four
    # 2026-11-17 outputs were approved as-is, so the new pass is invoked with --only and
    # the report keeps their original entries.
    if "--batch" in sys.argv:
        if sys.argv[sys.argv.index("--batch") + 1] != "2026-11-19":
            raise SystemExit("unknown batch; only 2026-11-19 exists")
        prepare_batch()
        return
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

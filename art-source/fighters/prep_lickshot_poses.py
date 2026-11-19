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

2026-11-19 batch (`--batch 2026-11-19`): the walk video, the 2 x 4 skank/lean-back sheet,
the 3 x 4 hitstun/launch/knockdown sheet and the single C-recoil pose live in
`batch-2026-11-19/`. Those are multi-frame animations, so each animation group is
composed onto a shared canvas — every pose anchored by its sole row and stance centre —
and downscaled once. One offset/scale per animation is all `FighterRoster` stores, so a
shared canvas is what stops a walk loop from bobbing or sinking. Walk frames come out of
the video with ffmpeg (`FFMPEG=/path/to/ffmpeg` if it is not on PATH).

Usage: python3 art-source/fighters/prep_lickshot_poses.py
       python3 art-source/fighters/prep_lickshot_poses.py --batch 2026-11-19
"""

from __future__ import annotations

import json
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


# =============================================================================
# 2026-11-19 batch: the walk video, the 8-pose skank sheet, the 12-pose
# hit/launch/knockdown sheet and the single C-recoil pose.
#
# Everything here is multi-frame art, so it cannot use the one-frame-per-animation
# job list above: `FighterRoster` stores ONE offset/scale per animation name. Each
# animation group is therefore composed onto a shared canvas, every pose placed so
# its sole row and stance centre line up, and the group is downscaled once. That is
# what keeps a walk loop from bobbing or sinking: the offsets never change mid-stride.
# =============================================================================

BATCH = SRC / "batch-2026-11-19"
BATCH_REPORT = SRC / "prep-report-2026-11-19.json"

WALK_VIDEO = BATCH / "15_bossy-walk_original.mov"
SKANK_SHEET = BATCH / "12_skank-leanback-sheet_original.jpeg"
REACTION_SHEET = BATCH / "13_hitstun-launch-knockdown-sheet_original.jpeg"
C_RECOIL = BATCH / "14_c-recoil-launch_original.jpeg"

TARGET_HEIGHT = 121.75     # BaseFighter's adult crown-to-sole before FIGHTER_ART_SCALE
REVIEW = BATCH / "review"


def _body_mask(solid: np.ndarray) -> np.ndarray:
    """Largest connected blob of a boolean mask — the fighter itself, not a cord tail."""
    labels, count = ndimage.label(solid)
    if count <= 1:
        return solid
    sizes = ndimage.sum(solid, labels, range(1, count + 1))
    return labels == (int(np.argmax(sizes)) + 1)


def _metrics(rgba: Image.Image) -> dict:
    arr = np.asarray(rgba)
    solid = arr[:, :, 3] > 32
    body = _body_mask(solid)
    rows = np.where(body.any(axis=1))[0]
    if not rows.size:
        raise SystemExit("empty pose")
    crown, sole = int(rows[0]), int(rows[-1])
    waist = crown + int(round((sole - crown) * 0.62))
    xs = np.where(body[waist:sole + 1])[1]
    stance_x = float(np.median(xs)) if xs.size else rgba.width / 2.0
    return {
        "box": list(rgba.getbbox() or (0, 0, rgba.width, rgba.height)),
        "size": [rgba.width, rgba.height],
        "crown_row": crown,
        "sole_row": sole,
        "stance_x": stance_x,
        "crown_to_sole": sole - crown + 1,
    }


def _finish_pose(im: Image.Image, fg: np.ndarray, label: str) -> Image.Image:
    """Erode, feather, crop to the alpha bbox and return the finished RGBA pose."""
    body = _body_mask(fg)
    sole_body = int(np.where(body.any(axis=1))[0][-1])
    fg = fg.copy()
    fg[sole_body + 1:, :] = False
    eroded = ndimage.binary_erosion(fg, iterations=ERODE_PX, border_value=0)
    if eroded.sum() > fg.sum() * 0.5:
        fg = eroded
    alpha = Image.fromarray((fg * 255).astype(np.uint8), mode="L")
    alpha = alpha.filter(ImageFilter.GaussianBlur(FEATHER_PX))
    # The 0.5 px feather bleeds a faint alpha tail below the sole. Godot's used_rect counts
    # ANY non-zero alpha, so that tail would set a sole row two pixels lower than the drawn
    # one and the whole sprite would sit ~1 px into the sand. Re-cut the sole line after the
    # blur: the feather stays on the silhouette's sides and top.
    tail = np.array(alpha)
    tail[sole_body + 1:, :] = 0
    alpha = Image.fromarray(tail, mode="L")
    rgba = im.convert("RGBA")
    rgba.putalpha(alpha)
    box = rgba.getbbox()
    if box is None:
        raise SystemExit(f"{label}: empty crop")
    return rgba.crop(box)


def clean_pose(im: Image.Image, job: dict) -> Image.Image:
    """White-key one drawing, protect thin dark cord and cream soles, return RGBA."""
    fg = key_white(im)
    fg = restore_small_holes(fg, 900)

    labels, count = ndimage.label(fg)
    if count > 1:
        sizes = ndimage.sum(fg, labels, range(1, count + 1))
        keep = np.zeros(count + 1, dtype=bool)
        keep[1:] = sizes >= MIN_ISLAND
        fg = keep[labels]
    if not fg.any():
        raise SystemExit(f"{job.get('label', '?')}: nothing left after background removal")
    return _finish_pose(im, fg, job.get("label", "pose"))


def _kmeans1d(values: list[float], k: int) -> np.ndarray:
    """1-D k-means cluster ids, ordered from the smallest centre to the largest."""
    v = np.asarray(values, dtype=float)
    order = np.argsort(v)
    centers = np.array([v[order[min(len(v) - 1, int((i + 0.5) * len(v) / k))]] for i in range(k)])
    ids = np.zeros(len(v), dtype=int)
    for _ in range(80):
        ids = np.abs(v[:, None] - centers[None, :]).argmin(axis=1)
        for i in range(k):
            sel = v[ids == i]
            if sel.size:
                centers[i] = float(sel.mean())
    ranked = np.argsort(centers)
    remap = {int(old): new for new, old in enumerate(ranked)}
    return np.array([remap[int(i)] for i in ids], dtype=int)


def slice_grid(im: Image.Image, rows: int, cols: int, label: str) -> list[tuple[Image.Image, dict]]:
    """Slice a hand-laid sheet into rows x cols drawings, left to right, top to bottom.

    The poses in these sheets touch across row and column gutters (a raised boot reaches
    into the row above), so a projection cut chops drawings. Each drawing is instead one
    connected blob: the `rows x cols` biggest blobs are clustered by centre, and every
    smaller fragment (a detached cord tail, a bead of the chain) joins the nearest pose.
    That keeps the thin black mic cord attached to the hand it belongs to.
    """
    fg = key_white(im)
    fg = restore_small_holes(fg, 900)
    labels, count = ndimage.label(fg)
    if count == 0:
        raise SystemExit(f"{label}: nothing left after background removal")
    sizes = ndimage.sum(fg, labels, range(1, count + 1))
    boxes = ndimage.find_objects(labels)

    def bbox(comp: int) -> tuple[int, int, int, int]:
        sl = boxes[comp - 1]
        return sl[0].start, sl[0].stop, sl[1].start, sl[1].stop

    want = rows * cols
    big = [i for i in range(1, count + 1) if sizes[i - 1] >= 4000]
    if len(big) < want:
        big = sorted(range(1, count + 1), key=lambda i: -sizes[i - 1])[:want]
        big.sort()
    if len(big) > want:
        # Keep the `want` largest blobs; the rest are fragments and get assigned below.
        big = sorted(sorted(big, key=lambda i: -sizes[i - 1])[:want])

    centers_y = [sum(bbox(i)[:2]) / 2.0 for i in big]
    row_ids = _kmeans1d(centers_y, rows)
    cells: list[dict] = []
    for r in range(rows):
        members = [big[i] for i in range(len(big)) if row_ids[i] == r]
        centers_x = [sum(bbox(i)[2:]) / 2.0 for i in members]
        col_ids = _kmeans1d(centers_x, cols)
        for c in range(cols):
            comps = [members[i] for i in range(len(members)) if col_ids[i] == c]
            cells.append({"row": r + 1, "col": c + 1, "comps": comps})

    # Fragments: every blob too small to be a drawing joins its nearest pose.
    for i in range(1, count + 1):
        if sizes[i - 1] < MIN_ISLAND or i in big:
            continue
        y0, y1, x0, x1 = bbox(i)
        cy, cx = (y0 + y1) / 2.0, (x0 + x1) / 2.0
        best, best_d = None, None
        for cell in cells:
            ys0 = min(bbox(j)[0] for j in cell["comps"])
            ys1 = max(bbox(j)[1] for j in cell["comps"])
            xs0 = min(bbox(j)[2] for j in cell["comps"])
            xs1 = max(bbox(j)[3] for j in cell["comps"])
            dy = 0.0 if ys0 <= cy <= ys1 else min(abs(cy - ys0), abs(cy - ys1))
            dx = 0.0 if xs0 <= cx <= xs1 else min(abs(cx - xs0), abs(cx - xs1))
            d = dx + dy * 2.0
            if best_d is None or d < best_d:
                best, best_d = cell, d
        if best is not None and best_d is not None and best_d <= 60.0:
            best["comps"].append(i)

    out: list[tuple[Image.Image, dict]] = []
    for cell in cells:
        mask = np.isin(labels, cell["comps"])
        pose = _finish_pose(im, mask, f"{label} r{cell['row']}c{cell['col']}")
        box_of_cell = [min(bbox(j)[2] for j in cell["comps"]),
                       min(bbox(j)[0] for j in cell["comps"]),
                       max(bbox(j)[3] for j in cell["comps"]),
                       max(bbox(j)[1] for j in cell["comps"])]
        out.append((pose, {"row": cell["row"], "col": cell["col"],
                           "components": len(cell["comps"]), "cell": box_of_cell,
                           "metrics": _metrics(pose)}))
    return out


def compose_group(poses: list[Image.Image], label: str) -> tuple[list[Image.Image], dict]:
    """Place every pose of one animation on a shared canvas, anchored by sole and stance.

    Returns the downscaled frames and the placement record: the shared sole row, the
    shared stance centre, and each frame's own crown row (so the caller can pick a
    reference height and derive the single `anim_scale` the animation needs).
    """
    if not poses:
        raise SystemExit(f"{label}: no poses")
    mets = [_metrics(p) for p in poses]
    left = int(np.ceil(max(m["stance_x"] for m in mets))) + 2
    right = int(np.ceil(max(m["size"][0] - m["stance_x"] for m in mets))) + 2
    above = max(m["sole_row"] + 1 for m in mets) + 2
    width, height = left + right, above + 4
    canvas: list[Image.Image] = []
    for pose, m in zip(poses, mets):
        frame = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        x = left - int(round(m["stance_x"]))
        y = above - (m["sole_row"] + 1)
        frame.alpha_composite(pose, (x, y))
        canvas.append(frame)
    scale = min(1.0, SIZE_CAP / max(width, height))
    if scale < 1.0:
        size = (max(1, round(width * scale)), max(1, round(height * scale)))
        canvas = [f.resize(size, Image.LANCZOS) for f in canvas]
    final = [_metrics(f) for f in canvas]
    soles = [m["sole_row"] for m in final]
    stance = [m["stance_x"] for m in final]
    record = {
        "label": label,
        "frame": [canvas[0].width, canvas[0].height],
        "downscale": round(scale, 4),
        "sole_row": int(round(float(np.mean(soles)))),
        "sole_spread": [int(min(soles)), int(max(soles))],
        "stance_centre_x": round(float(np.mean(stance)), 1),
        "stance_spread": [round(min(stance), 1), round(max(stance), 1)],
        "crown_rows": [m["crown_row"] for m in final],
        "crown_to_sole": [m["crown_to_sole"] for m in final],
    }
    return canvas, record


def mic_grille_diameter(im: Image.Image) -> float:
    """Disk-equivalent size of the silver mic grille — the one rigid prop in every pose.

    The standalone C-recoil upload is drawn larger than the sheet poses (one figure filling
    a whole canvas instead of a quarter of one). The grille appears in every drawing at the
    same real-world size, so its measured diameter calibrates the standalone art back onto
    the sheet's drawing scale instead of guessing from a bent silhouette.
    """
    a = np.asarray(im.convert("RGB")).astype(np.int16)
    sat = a.max(axis=2) - a.min(axis=2)
    mean = a.mean(axis=2)
    silver = (sat < 26) & (mean > 120) & (mean < 225)
    labels, count = ndimage.label(silver)
    if count == 0:
        return 0.0
    sizes = ndimage.sum(silver, labels, range(1, count + 1))
    ys, xs = np.where(labels == int(np.argmax(sizes)) + 1)
    return float(np.sqrt((xs.max() - xs.min() + 1) * (ys.max() - ys.min() + 1)))


def _anim_numbers(record: dict, ref_height: int) -> dict:
    """The offset/scale a shared-canvas animation needs, from the measured placement."""
    anim_scale = TARGET_HEIGHT / max(1, ref_height)
    height = record["frame"][1]
    width = record["frame"][0]
    offset_y = height / 2.0 - record["sole_row"] - 8.0 / (anim_scale * 1.24)
    offset_x = width / 2.0 - record["stance_centre_x"]
    return {
        "anim_scale": round(anim_scale, 5),
        "anim_offset": [round(offset_x, 1), round(offset_y, 1)],
        "anim_source_max": float(max(width, height)),
    }


def _save_group(frames: list[Image.Image], folder: Path, names: list[str]) -> None:
    folder.mkdir(parents=True, exist_ok=True)
    for frame, name in zip(frames, names):
        frame.save(folder / name, optimize=True)


def _contact_sheet(frames: list[Image.Image], path: Path, scale: float = 0.5,
                   background: tuple[int, int, int] = (236, 222, 192)) -> None:
    """A review strip on sand-coloured ground so the soles and the floor read at a glance."""
    w = max(f.width for f in frames)
    h = max(f.height for f in frames)
    tw, th = max(1, int(w * scale)), max(1, int(h * scale))
    sheet = Image.new("RGB", (tw * len(frames), th), background)
    for i, frame in enumerate(frames):
        art = frame.resize((max(1, int(frame.width * scale)), max(1, int(frame.height * scale))),
                           Image.LANCZOS)
        cell = Image.new("RGB", (tw, th), background)
        cell.paste(art, ((tw - art.width) // 2, th - art.height), art)
        sheet.paste(cell, (i * tw, 0))
    path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(path)


def extract_walk(count: int = 4) -> tuple[list[Image.Image], dict]:
    """Pull evenly spaced stride frames out of the owner's 3 s walk video.

    The upload is a phone-framed close-up: the hat crown is flush with the top edge in
    every frame and one boot always leaves the left or right edge. Frames are therefore
    chosen by *least* edge clipping inside each stride phase, and the crop is recorded
    in the report rather than hidden — see the batch PROVENANCE.md.
    """
    ffmpeg = os.environ.get("FFMPEG") or shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg not found: set FFMPEG=/path/to/ffmpeg")
    tmp = Path(tempfile.mkdtemp(prefix="lickshot-walk-"))
    subprocess.run([ffmpeg, "-v", "error", "-y", "-i", str(WALK_VIDEO),
                    str(tmp / "f_%03d.png")], check=True)
    files = sorted(tmp.glob("f_*.png"))
    if not files:
        raise SystemExit("no frames decoded from the walk video")

    frames: list[Image.Image] = []
    info: list[dict] = []
    for path in files:
        im = Image.open(path).convert("RGB")
        arr = np.asarray(im).astype(np.int16)
        dark = arr.min(axis=2) < 236
        left_boot = int(dark[620:, :3].sum())
        right_boot = int(dark[620:, -3:].sum())
        crown_cut = int(dark[:2].sum())
        frames.append(im)
        info.append({"left_boot": left_boot, "right_boot": right_boot, "crown_cut": crown_cut})

    # Stride period from silhouette self-similarity (the clip has no metadata for it).
    sig = []
    for im in frames:
        fg = key_white(im)
        ys, xs = np.where(fg)
        sub = fg[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        thumb = Image.fromarray((sub * 255).astype(np.uint8)).resize((48, 64), Image.BILINEAR)
        sig.append(np.asarray(thumb) > 127)
    sig_arr = np.array(sig, dtype=float).reshape(len(sig), -1)
    inter = sig_arr @ sig_arr.T
    tot = sig_arr.sum(axis=1)
    iou = inter / (tot[:, None] + tot[None, :] - inter)
    period, best = 0, -1.0
    for lag in range(12, min(45, len(frames) // 2)):
        score = float(np.mean([iou[i, i + lag] for i in range(len(frames) - lag)]))
        if score > best:
            period, best = lag, score
    period = max(period, count)

    anchor = min(range(len(frames)), key=lambda i: info[i]["left_boot"] + info[i]["right_boot"])
    chosen: list[int] = []
    for k in range(count):
        target = anchor + int(round(k * period / count))
        best_i, best_score = None, None
        for delta in (0, -1, 1, -2, 2):
            i = target + delta
            if i < 0 or i >= len(frames) or i in chosen:
                continue
            score = info[i]["left_boot"] + info[i]["right_boot"]
            if best_score is None or score < best_score:
                best_i, best_score = i, score
        if best_i is not None:
            chosen.append(best_i)
    chosen.sort()

    poses = [clean_pose(frames[i], {"label": f"walk frame {i + 1}"}) for i in chosen]
    meta = {
        "period_frames": period,
        "period_iou": round(best, 3),
        "source_frames": len(frames),
        "chosen": [i + 1 for i in chosen],
        "clipping": [info[i] for i in chosen],
    }
    return poses, meta


def run_batch(only: set[str] | None = None) -> None:
    report: dict = json.loads(BATCH_REPORT.read_text()) if BATCH_REPORT.exists() else {}
    wanted = (lambda key: not only or key in only)

    # ---- 1. The 8-pose lean-back / skank sheet (2 rows x 4) -----------------
    if wanted("skank"):
        sheet = Image.open(SKANK_SHEET)
        cells = slice_grid(sheet, 2, 4, "skank")
        if len(cells) != 8:
            raise SystemExit(f"skank sheet: expected 8 poses, sliced {len(cells)}")
        poses = [c[0] for c in cells]
        frames, record = compose_group(poses, "Lickshot skank / lean-back (8 poses)")
        ref = max(record["crown_to_sole"])
        _save_group(frames, OUT / "skank", [f"{i + 1:02d}.png" for i in range(len(frames))])
        _contact_sheet(frames, REVIEW / "skank-strip.png")
        report["skank"] = {**record, **_anim_numbers(record, ref),
                           "source": str(SKANK_SHEET.relative_to(ROOT)),
                           "outputs": [f"{OUT.name}/skank/{i + 1:02d}.png" for i in range(len(frames))],
                           "cells": [c[1] for c in cells]}
        print(f"skank: {len(frames)} frames {record['frame']} sole {record['sole_row']} "
              f"scale {report['skank']['anim_scale']}")

    # ---- 2. The 12-pose hit / launch / knockdown sheet (3 rows x 4) ---------
    if wanted("reactions"):
        sheet = Image.open(REACTION_SHEET)
        cells = slice_grid(sheet, 3, 4, "reaction")
        if len(cells) != 12:
            raise SystemExit(f"reaction sheet: expected 12 poses, sliced {len(cells)}")
        poses = [c[0] for c in cells]
        standing_src = poses[0]          # row 1, col 1: the upright standing recoil
        standing_h = _metrics(standing_src)["crown_to_sole"]

        # Row 1 = standing recoil. Poses 1-3 are the hitstun snap; pose 4 is already
        # airborne (legs kicked up), so it joins the launch group instead.
        hitstun = poses[0:3]
        frames, record = compose_group(hitstun, "Lickshot hitstun (standing recoil)")
        _save_group(frames, OUT / "hitstun", [f"{i + 1:02d}.png" for i in range(len(frames))])
        _contact_sheet(frames, REVIEW / "hitstun-strip.png")
        report["hitstun"] = {**record, **_anim_numbers(record, standing_h),
                             "source": str(REACTION_SHEET.relative_to(ROOT)),
                             "outputs": [f"{OUT.name}/hitstun/{i + 1:02d}.png" for i in range(len(frames))]}
        print(f"hitstun: {len(frames)} frames {record['frame']} scale {report['hitstun']['anim_scale']}")

        # Airborne: the single C-recoil pose, row 1 pose 4, then the whole middle row.
        c_recoil = clean_pose(Image.open(C_RECOIL), {"label": "Lickshot C-recoil launch"})
        sheet_grille = float(np.median([mic_grille_diameter(p) for p in poses if mic_grille_diameter(p) > 0]))
        recoil_grille = mic_grille_diameter(c_recoil)
        art_ratio = round(recoil_grille / sheet_grille, 3) if sheet_grille > 0 and recoil_grille > 0 else 1.0
        if art_ratio > 1.05:
            c_recoil = c_recoil.resize((max(1, round(c_recoil.width / art_ratio)),
                                        max(1, round(c_recoil.height / art_ratio))), Image.LANCZOS)
        airborne = [c_recoil, poses[3], *poses[4:8]]
        frames, record = compose_group(airborne, "Lickshot launched / tumble (airborne)")
        _save_group(frames, OUT / "airborne", [f"{i + 1:02d}.png" for i in range(len(frames))])
        _contact_sheet(frames, REVIEW / "airborne-strip.png")
        report["airborne"] = {**record, **_anim_numbers(record, standing_h),
                              "art_scale_match": art_ratio,
                              "art_scale_basis": "mic grille diameter: standalone pose / sheet median",
                              "source": f"{C_RECOIL.relative_to(ROOT)} + {REACTION_SHEET.relative_to(ROOT)}",
                              "outputs": [f"{OUT.name}/airborne/{i + 1:02d}.png" for i in range(len(frames))]}
        print(f"airborne: {len(frames)} frames {record['frame']} scale {report['airborne']['anim_scale']}")

        # Row 3 = the sand. Seated -> sprawled is the nonlethal knockdown; the two
        # face-down frames are the KO.
        ground = poses[8:12]
        frames, record = compose_group(ground, "Lickshot knockdown / KO (ground)")
        _save_group(frames, OUT / "ground", [f"{i + 1:02d}.png" for i in range(len(frames))])
        _contact_sheet(frames, REVIEW / "ground-strip.png")
        report["ground"] = {**record, **_anim_numbers(record, standing_h),
                            "source": str(REACTION_SHEET.relative_to(ROOT)),
                            "outputs": [f"{OUT.name}/ground/{i + 1:02d}.png" for i in range(len(frames))],
                            "reference": "row 1 col 1 crown-to-sole (same drawing scale as every row)"}
        print(f"ground: {len(frames)} frames {record['frame']} scale {report['ground']['anim_scale']}")

    # ---- 3. The 3 s walk video -------------------------------------------
    if wanted("walk"):
        poses, meta = extract_walk(4)
        frames, record = compose_group(poses, "Lickshot bossy walk")
        ref = int(np.median(record["crown_to_sole"]))
        # NOT under godot/assets: this walk is not wired. The upload crops the hat crown and
        # one boot in every frame, so the frames are kept with the source for review until a
        # full-body export arrives. Wiring them would put chopped art in the walk loop.
        _save_group(frames, BATCH / "walk-frames", [f"{i + 1:02d}.png" for i in range(len(frames))])
        _contact_sheet(frames, REVIEW / "walk-strip.png")
        report["walk"] = {**record, **meta, **_anim_numbers(record, ref),
                          "wired": False,
                          "blocked": "source crops the hat crown and clips one boot in every frame; "
                                     "needs a full-body re-export before it can join the walk loop",
                          "source": str(WALK_VIDEO.relative_to(ROOT)),
                          "outputs": [f"batch-2026-11-19/walk-frames/{i + 1:02d}.png" for i in range(len(frames))]}
        print(f"walk: {len(frames)} frames {record['frame']} scale {report['walk']['anim_scale']} "
              f"source frames {meta['chosen']} period {meta['period_frames']}")

    BATCH_REPORT.write_text(json.dumps(report, indent=2, default=str) + "\n")
    print(f"\nwrote {BATCH_REPORT}")


def main() -> None:
    # `--only jab.png upper_box.png` re-runs a subset of the single-pose jobs; without it
    # every single-pose job runs. `--batch 2026-11-19` runs only the 2026-11-19 multi-frame
    # batch (walk video, skank sheet, reaction sheet, C-recoil) into its own report, so the
    # approved single-pose outputs are never rewritten by a batch pass.
    if "--batch" in sys.argv:
        # `--batch 2026-11-19` runs the whole batch; trailing group names (walk, skank,
        # reactions) narrow it. The date tag is a label, not a filter.
        groups = {"walk", "skank", "reactions"}
        only = {a for a in sys.argv[sys.argv.index("--batch") + 1:] if a in groups} or None
        run_batch(only)
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

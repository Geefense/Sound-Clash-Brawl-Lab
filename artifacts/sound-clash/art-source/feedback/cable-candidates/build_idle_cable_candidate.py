#!/usr/bin/env python3
"""Build a versioned cable-correction candidate for 01_idle.

Reads the untouched aligned/01_idle.png, removes only the cable tail and floor
loop after the forearm wrap, routes that section into the jacket behind its
lower hem, and writes:

  01_idle-jacket-entry-v1.png   full 1536x1024 RGBA, same canvas and anchor
  diff-original-vs-v1.png       changed-region map
  diff-regions.json             every changed region with bbox and pixel count

The cable hangs free of the body in this pose, so it is removed by silhouette
runs, not by colour thresholds: each row's isolated thin run is cord, and the
body's own pixels are never touched. No cloth is healed, because the cord never
crosses the garment. Everything else (mic, hand, wrist coil, hat, face,
trousers, Clarks, proportions) is the original.

Standard library plus Pillow, numpy and scipy.
"""
from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
PACK = HERE.parents[2] / "public/assets/feedback/aligned/01_idle.png"

W, H = 1536, 1024

CUT_Y = 632          # the cable is a free-hanging run from here down
FLOOR_TOP = 846      # below this the cable lies on the floor
LOOP_MERGED = (874, 880, 676)   # rows where the loop touches the boot's toe

# New run: continues the cord that leaves the wrap, then under the ribbed hem,
# above the cream waistband.
# Starts inside the coil's dark mass so it emerges from the wrap, then slips
# behind the ribbed hem's lower edge (above the cream waistband).
ENTRY_START = (704, 624)
ENTRY_CONTROL = (716, 637)
ENTRY_END = (731, 649)
ENTRY_BOX = (696, 610, 750, 662)    # region redrawn, supersampled
ENTRY_WIDTH = 4.6                   # px, matching the original cord
# The ribbed hem's bottom edge sits at y 646-649 around x 730; restoring from
# there down cuts the cord exactly at the hem, above the cream waistband.
HEM_RESTORE = (722, 645, 742, 658)


def row_runs(mask_row):
    runs, start = [], None
    for i, v in enumerate(mask_row):
        if v and start is None:
            start = i
        elif not v and start is not None:
            runs.append((start, i - 1))
            start = None
    if start is not None:
        runs.append((start, len(mask_row) - 1))
    return runs


def bezier(p0, p1, p2, steps=64):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        pts.append((x, y))
    return pts


def draw_entry(base, colour):
    """Anti-aliased cord stroke drawn at 4x and downsampled."""
    x0, y0, x1, y1 = ENTRY_BOX
    w, h = x1 - x0, y1 - y0
    ss = 4
    layer = Image.new("L", (w * ss, h * ss), 0)
    d = ImageDraw.Draw(layer)
    pts = [((x - x0) * ss, (y - y0) * ss) for x, y in bezier(ENTRY_START, ENTRY_CONTROL, ENTRY_END)]
    d.line(pts, fill=255, width=int(round(ENTRY_WIDTH * ss)), joint="curve")
    # rounded cap at the wrap end
    cx, cy = pts[0]
    r = ENTRY_WIDTH * ss / 2
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    cover = np.asarray(layer.resize((w, h), Image.LANCZOS), dtype=np.float32) / 255.0

    out = base.copy()
    region = out[y0:y1, x0:x1].astype(np.float32)
    a = cover[..., None]
    paint = np.array([*colour, 255], dtype=np.float32)
    blended = region * (1 - a) + paint * a
    out[y0:y1, x0:x1] = np.clip(blended, 0, 255).astype(np.uint8)
    return out


def cable_mask(opaque):
    """Isolated thin run on the left of the figure, plus the loop on the floor."""
    mask = np.zeros((H, W), bool)
    for y in range(CUT_Y, FLOOR_TOP):
        runs = row_runs(opaque[y])
        if len(runs) >= 2:
            x0, x1 = runs[0]
            # cord: thin, left of the body, separated by transparent pixels
            if (x1 - x0 + 1) <= 11 and x0 < 715:
                mask[y, x0:x1 + 1] = True

    # Floor loop: it lies on empty background, so it is the thin structure the
    # boot's solid mass does not explain. The boot (laces and all) survives the
    # opening; the loop does not.
    band = np.zeros((H, W), bool)
    band[FLOOR_TOP:, :] = True
    solid = ndimage.binary_opening(opaque & band, np.ones((13, 13), bool))
    solid = ndimage.binary_fill_holes(solid)
    thin = opaque & band & ~solid
    lab, n = ndimage.label(thin, np.ones((3, 3), bool))
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if xs.size == 0:
            continue
        if xs.mean() < 692 and xs.size > 80 and xs.max() < 700:
            mask[ys, xs] = True

    mask[:CUT_Y, :] = False
    return mask


def main():
    source_img = Image.open(PACK).convert("RGBA")
    if source_img.size != (W, H):
        raise SystemExit(f"unexpected canvas {source_img.size}")
    src = np.array(source_img)
    out = src.copy()

    opaque = src[..., 3] > 24
    cable = cable_mask(opaque)

    # The edit must stay in the lower-left area of the figure.
    allowed = np.zeros((H, W), bool)
    allowed[CUT_Y - 4:, 560:760] = True
    cable &= allowed

    out[cable] = 0  # the cord hangs over empty background: delete those pixels

    # New short run from the wrap into the jacket. Its colour is sampled from
    # the cable pixels just removed, so the stroke matches the original cord.
    # Whole cable body, not just its darkest core, so the stroke sits at the
    # same value as the cord it continues.
    sample = src[cable][:, :3].astype(int)
    if sample.size == 0:
        cord_colour = np.array([30, 32, 38], dtype=np.uint8)
    else:
        sample_lum = sample @ np.array([0.299, 0.587, 0.114])
        body = sample[sample_lum >= np.percentile(sample_lum, 35)]
        cord_colour = np.median(body if body.size else sample, axis=0).astype(np.uint8)

    comp = draw_entry(out, cord_colour)

    # The hem's own edge stays on top, so the cord reads as passing behind the
    # garment's lower edge rather than stopping in mid-air.
    hx0, hy0, hx1, hy1 = HEM_RESTORE
    hem = np.zeros((H, W), bool)
    hem[hy0:hy1, hx0:hx1] = True
    fabric = hem & opaque
    comp[fabric] = src[fabric]

    entry = np.zeros((H, W), bool)
    entry[ENTRY_BOX[1]:ENTRY_BOX[3], ENTRY_BOX[0]:ENTRY_BOX[2]] = True

    # Nothing may change outside the edit region or above the cut.
    region = ndimage.binary_dilation(cable | entry, np.ones((5, 5), bool))
    guard = comp.copy()
    guard[~region] = src[~region]
    # The entry deliberately continues the cord above the cut so it merges with
    # the wrap; nothing above the coil may change.
    if np.any(np.any(guard != src, axis=2)[:610, :]):
        raise SystemExit("change above the allowed band — aborting")

    changed = np.any(guard != src, axis=2)
    Image.fromarray(guard, "RGBA").save(HERE / "01_idle-jacket-entry-v1.png")

    # ---- difference view + region list ----
    lab, n = ndimage.label(changed, structure=np.ones((3, 3), bool))
    regions = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if xs.size < 4:
            continue
        regions.append({
            "id": 0,
            "pixels": int(xs.size),
            "bbox": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
        })
    regions.sort(key=lambda r: -r["pixels"])
    for k, r in enumerate(regions, 1):
        r["id"] = k

    base = (src[..., :3] * 0.26).astype(np.uint8)
    diff_img = base.copy()
    diff_img[opaque] = (base[opaque] + 26).clip(0, 255)
    removed = changed & ((guard[..., 3] < src[..., 3]) | (guard[..., :3].sum(axis=2) < 40))
    added = changed & ~removed
    diff_img[removed] = (255, 72, 190)
    diff_img[added] = (70, 255, 190)

    dimg = Image.fromarray(diff_img)
    dd = ImageDraw.Draw(dimg)
    try:
        font = ImageFont.load_default(size=24)
    except Exception:
        font = None
    for r in regions[:10]:
        rx0, ry0, rx1, ry1 = r["bbox"]
        dd.rectangle([rx0 - 4, ry0 - 4, rx1 + 4, ry1 + 4], outline=(255, 220, 120), width=2)
        dd.text((rx0 + 6, max(0, ry0 - 28)), f"{r['id']}: {r['pixels']}px", fill=(255, 220, 120), font=font)
    dd.text((600, 40), "01_idle — original vs cable candidate v1", fill=(235, 235, 235), font=font)
    dd.text((600, 72), "magenta = cable removed", fill=(255, 150, 220), font=font)
    dd.text((600, 104), "green = jacket entry added", fill=(140, 255, 205), font=font)
    dimg.save(HERE / "diff-original-vs-v1.png")

    (HERE / "diff-regions.json").write_text(json.dumps({
        "source": "artifacts/sound-clash/public/assets/feedback/aligned/01_idle.png",
        "candidate": "01_idle-jacket-entry-v1.png",
        "canvas": [W, H],
        "anchor": [768, 900],
        "origin": [0.5, 900 / 1024],
        "cut_y": CUT_Y,
        "changed_pixels": int(changed.sum()),
        "changed_bbox": [
            int(np.nonzero(changed)[1].min()), int(np.nonzero(changed)[0].min()),
            int(np.nonzero(changed)[1].max()), int(np.nonzero(changed)[0].max()),
        ],
        "regions": regions,
        "entry_curve": [ENTRY_START, ENTRY_CONTROL, ENTRY_END],
        "entry_width_px": ENTRY_WIDTH,
        "entry_colour": [int(v) for v in cord_colour],
    }, indent=2))

    print(f"changed pixels: {int(changed.sum())} in {len(regions)} regions")
    for r in regions[:8]:
        print(f"  region {r['id']}: {r['pixels']} px bbox={r['bbox']}")

    # Leftover audit: thin dark structures still hanging outside the body.
    body = ndimage.binary_opening(guard[..., 3] > 24, np.ones((9, 9), bool))
    residue = (guard[..., 3] > 24) & ~body
    residue[:CUT_Y, :] = False
    rl, rn = ndimage.label(residue, np.ones((3, 3), bool))
    leftovers = []
    lum = guard[..., :3].astype(np.float32) @ np.array([0.299, 0.587, 0.114])
    for i in range(1, rn + 1):
        ys, xs = np.nonzero(rl == i)
        if xs.size >= 12 and lum[ys, xs].mean() < 110:
            leftovers.append({"pixels": int(xs.size),
                              "bbox": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]})
    print("residue candidates:", leftovers if leftovers else "none")


if __name__ == "__main__":
    main()

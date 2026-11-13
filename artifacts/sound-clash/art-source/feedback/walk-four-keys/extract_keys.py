#!/usr/bin/env python3
"""Cut the four walk keys out of the sheet and align them without flattening the bob.

Outputs, all in this directory:

  poses/01_contact_a.png … 04_pass_b.png   460x620 RGBA, transparent, one
                                           uniform scale, support sole on the
                                           floor, torso centred
  keys-aligned.png                         review contact sheet
  loop-check.json                          per-key measurements

Alignment, and why it is done this way:

  * **One scale for all four keys.** The figures measure 502-521 px tall as
    drawn (spread 3.7%). The only rigid object available as a ruler is the flat
    boot, and its own measurement noise is 5% (bbox width) to 25% (area), so the
    sheet cannot be shown to use different scales. A single uniform scale is
    applied and the residual height differences are left alone as the natural
    rise and dip of the walk.
  * **Vertical: the support sole is pinned to the floor, not the pose height.**
    Normalising every pose to the same total height would cancel the bob and
    straighten the walk; pinning the planted foot keeps the body free to rise
    and dip.
  * **Horizontal: the torso is centred, not the bounding box.** Bounding-box
    centring shifts each key by however far the arms and legs extend, which
    would invent horizontal drift; the torso is the body.

Gait analysis (leg trace, alternation, forward travel) lives in trace_legs.py.

Usage:
    python3 extract_keys.py

Requires Pillow, numpy and scipy.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
SHEET = HERE / "source-sheet.jpeg"
POSES = HERE / "poses"
RESULTS = HERE / "loop-check.json"

PANEL_W, PANEL_H = 460, 620
FIGURE_H = 460
FLOOR_Y = 566

# The background is a flat near-black field (JPEG noise std ~0.6, max distance
# 3.6). The bucket hat is drawn almost as dark, so a loose threshold eats the
# crown: at 26 the top row loses ~45 px of hat and every height and scale is
# wrong. 8 keeps the crowns and still rejects the noise.
BG_TOLERANCE = 8

CELLS = [
    ("01_contact_a", "01 CONTACT A", (0, 0, 600, 656)),
    ("02_pass_a", "02 PASS A", (599, 0, 1199, 656)),
    ("03_contact_b", "03 CONTACT B", (0, 656, 600, 1312)),
    ("04_pass_b", "04 PASS B", (599, 656, 1199, 1312)),
]


def _runs(line: np.ndarray) -> np.ndarray:
    """Length of the run each pixel belongs to (0 where the line is False)."""
    out = np.zeros(line.size, np.int16)
    edges = np.flatnonzero(np.diff(np.r_[0, line.astype(np.int8), 0]))
    for start, end in zip(edges[::2], edges[1::2]):
        out[start:end] = end - start
    return out


def thin_strokes(mask: np.ndarray, max_thick: int = 6, min_len: int = 25) -> np.ndarray:
    """Pixels in strokes that are long in one direction and thin in the other."""
    horiz = np.zeros(mask.shape, np.int16)
    for y in range(mask.shape[0]):
        horiz[y] = _runs(mask[y])
    vert = np.zeros(mask.shape, np.int16)
    for x in range(mask.shape[1]):
        vert[:, x] = _runs(mask[:, x])
    return (vert <= max_thick) & (horiz >= min_len)


def solid_bbox(mask: np.ndarray, min_run: int = 10) -> list[int]:
    """Figure bbox from rows/columns that hold a real stroke, not line residue."""
    runs = []
    for row in mask:
        best = cur = 0
        for px in row:
            cur = cur + 1 if px else 0
            best = max(best, cur)
        runs.append(best)
    rows = np.where(np.array(runs) >= min_run)[0]
    kept = mask[rows[0]: rows[-1] + 1]
    cols = np.where(kept.sum(0) > 0)[0]
    return [int(cols[0]), int(rows[0]), int(cols[-1]), int(rows[-1])]


def segment(cell: np.ndarray) -> np.ndarray:
    """Foreground mask of the posed figure; label text and ground line dropped."""
    a = cell.astype(np.float32)
    bg = np.median(a[2:14, 2:14].reshape(-1, 3), axis=0)
    mask = np.sqrt(((a - bg) ** 2).sum(2)) > BG_TOLERANCE
    mask = ndimage.binary_opening(mask, np.ones((2, 2)))

    v = a.max(2) / 255.0
    s = np.where(v > 0, (v - a.min(2) / 255.0) / np.maximum(v, 1e-6), 0.0)
    white = (v > 0.86) & (s < 0.18)
    for y in np.where(white.sum(1) > 0.55 * cell.shape[1])[0]:
        lo, hi = max(0, y - 1), y + 2
        mask[lo:hi, :] &= ~white[lo:hi, :]

    lab, n = ndimage.label(mask)
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    figure = np.isin(lab, [int(np.argmax(sizes)) + 1])

    figure &= ~thin_strokes(figure)
    lab2, n2 = ndimage.label(figure)
    keep = [i for i in range(1, n2 + 1) if (lab2 == i).sum() >= 500]
    figure = np.isin(lab2, keep)

    holes = ndimage.binary_fill_holes(figure) & ~figure
    hl, hn = ndimage.label(holes)
    for i in range(1, hn + 1):
        comp = hl == i
        if comp.sum() < 500:
            figure |= comp
    return figure


def boots(rgba: np.ndarray, floor_y: int) -> list[dict]:
    """The boots that sit near the floor: centroid, lowest point, bbox width."""
    a = rgba[:, :, :3].astype(np.float32) / 255.0
    alpha = rgba[:, :, 3] > 40
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    tan = alpha & (r > 0.52) & (r - b > 0.20) & (g > 0.22) & (r < 0.99)
    tan = ndimage.binary_opening(tan, np.ones((3, 3)))
    tan = ndimage.binary_closing(tan, np.ones((9, 9)))
    lab, n = ndimage.label(tan)
    out = []
    for i in range(1, n + 1):
        ys, xs = np.where(lab == i)
        if xs.size < 900 or ys.max() < floor_y - 130:
            continue
        out.append(
            {
                "area": int(xs.size),
                "cx": round(float(xs.mean()), 1),
                "lowestY": int(ys.max()),
                "width": int(xs.max() - xs.min() + 1),
                "onFloor": bool(floor_y - ys.max() <= 10),
            }
        )
    out.sort(key=lambda d: d["cx"])
    return out


def torso_centre(mask: np.ndarray, bbox: list[int]) -> float:
    """Centre of the body between shoulders and hips, ignoring limbs."""
    y0, y1 = bbox[1], bbox[3]
    lo = int(y0 + 0.35 * (y1 - y0))
    hi = int(y0 + 0.55 * (y1 - y0))
    band = mask[lo:hi, :]
    cols = np.where(band.sum(0) > 0)[0]
    weights = band.sum(0)[cols]
    return float((cols * weights).sum() / weights.sum())


def font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:  # Pillow < 10
        return ImageFont.load_default()


def main() -> int:
    sheet = Image.open(SHEET).convert("RGB")
    cells = []
    for slug, label, box in CELLS:
        cell = np.asarray(sheet.crop(box))
        mask = segment(cell)
        bbox = solid_bbox(mask)
        cells.append(
            {"slug": slug, "label": label, "rgb": cell, "mask": mask, "bbox": bbox}
        )

    heights = [c["bbox"][3] - c["bbox"][1] + 1 for c in cells]
    scale = FIGURE_H / float(np.median(heights))
    print("figure height per key, as drawn on the sheet:")
    for c, h in zip(cells, heights):
        print(f"  {c['label']:14s} {h} px")
    print(f"  spread {min(heights)}..{max(heights)} px "
          f"({100 * (max(heights) - min(heights)) / np.mean(heights):.1f}%), inside the "
          f"5% noise of the only rigid ruler (the flat boot)")
    print(f"  one uniform scale {scale:.4f} -> median figure {FIGURE_H} px")
    print("  the per-key height differences are left in place as the rise and dip\n")

    POSES.mkdir(exist_ok=True)
    report = {
        "panel": [PANEL_W, PANEL_H],
        "figureHeight": FIGURE_H,
        "floorY": FLOOR_Y,
        "scale": round(scale, 4),
        "normalisation": "one uniform scale; support sole pinned to the floor; "
                         "torso centred; pose height NOT normalised",
        "keys": [],
    }
    panels = []

    for c in cells:
        x0, y0, x1, y1 = c["bbox"]
        rgb = c["rgb"][y0:y1 + 1, x0:x1 + 1].astype(np.float32)
        alpha = c["mask"][y0:y1 + 1, x0:x1 + 1].astype(np.float32)
        torso_x = torso_centre(c["mask"], c["bbox"]) - x0

        img = Image.fromarray(
            np.dstack([rgb * alpha[:, :, None], alpha * 255]).astype(np.uint8), "RGBA"
        )
        new_w = max(1, int(round(img.width * scale)))
        new_h = max(1, int(round(img.height * scale)))
        img = img.resize((new_w, new_h), Image.LANCZOS)
        arr = np.asarray(img).astype(np.float32)
        a = arr[:, :, 3:4] / 255.0
        arr[:, :, :3] = np.where(a > 0, arr[:, :, :3] / np.maximum(a, 1e-6), 0)
        flat = np.clip(arr, 0, 255).astype(np.uint8)

        # support boot: widest of the boots near the floor
        pre = boots(np.asarray(Image.fromarray(flat, "RGBA")), new_h)
        support = max(pre, key=lambda b: b["width"]) if pre else None
        py = FLOOR_Y - (support["lowestY"] if support else new_h)
        px = int(round(PANEL_W / 2 - torso_x * scale))

        canvas = Image.new("RGBA", (PANEL_W, PANEL_H), (0, 0, 0, 0))
        canvas.paste(Image.fromarray(flat, "RGBA"), (px, py),
                     Image.fromarray(flat, "RGBA"))
        canvas.save(POSES / f"{c['slug']}.png")
        panels.append((c, np.asarray(canvas)))

        alpha_px = np.asarray(canvas)[:, :, 3] > 40
        ys, xs = np.where(alpha_px)
        boot_list = boots(np.asarray(canvas), FLOOR_Y)
        rear = boot_list[0] if boot_list else None
        front = boot_list[-1] if boot_list else None
        report["keys"].append(
            {
                "key": c["label"],
                "slug": c["slug"],
                "file": f"poses/{c['slug']}.png",
                "drawnHeightPx": int(y1 - y0 + 1),
                "panelHeightPx": int(ys.max() - ys.min() + 1),
                "headTopY": int(ys.min()),
                "torsoX": round(float(torso_x * scale) + px, 1),
                "boots": boot_list,
                "frontBootCx": front["cx"] if front else None,
                "rearBootCx": rear["cx"] if rear else None,
            }
        )
        print(f"{c['label']:14s} drawn {y1 - y0 + 1} px -> panel {int(ys.max() - ys.min() + 1)} px, "
              f"head top y {int(ys.min())}, torso x {round(float(torso_x * scale) + px)}")

    print("\npairwise pose difference (mean RGB over the union; 0 = identical):")
    diffs = []
    for i in range(len(panels)):
        for j in range(i + 1, len(panels)):
            a = panels[i][1].astype(np.float32)
            b = panels[j][1].astype(np.float32)
            union = (a[:, :, 3] > 40) | (b[:, :, 3] > 40)
            d = float(np.abs(a[:, :, :3] - b[:, :, :3])[union].mean())
            diffs.append({"pair": [panels[i][0]["label"], panels[j][0]["label"]],
                          "meanDiff": round(d, 1)})
            print(f"  {panels[i][0]['label']} vs {panels[j][0]['label']}: {d:6.1f}")
    report["pairwiseDiff"] = diffs

    pad = 16
    sheet_out = Image.new("RGB", (PANEL_W * 4 + pad * 5, PANEL_H + pad * 2 + 34), (16, 14, 20))
    draw = ImageDraw.Draw(sheet_out)
    f = font(18)
    for i, k in enumerate(report["keys"]):
        panel = Image.open(POSES / f"{k['slug']}.png").convert("RGBA")
        tile = Image.new("RGB", (PANEL_W, PANEL_H), (20, 17, 26))
        tile.paste(panel, (0, 0), panel)
        td = ImageDraw.Draw(tile)
        td.line([(0, FLOOR_Y), (PANEL_W, FLOOR_Y)], fill=(110, 100, 124))
        for b in k["boots"]:
            col = (90, 220, 140) if b["onFloor"] else (230, 120, 90)
            td.rectangle([b["cx"] - 5, b["lowestY"] - 5, b["cx"] + 5, b["lowestY"] + 5],
                         outline=col, width=2)
            td.text((b["cx"] - 8, b["lowestY"] - 26), str(int(b["cx"])), fill=col, font=f)
        sheet_out.paste(tile, (pad + i * (PANEL_W + pad), pad))
        draw.text((pad + i * (PANEL_W + pad) + 6, pad + PANEL_H + 8), k["key"],
                  fill=(230, 225, 238), font=f)
    sheet_out.save(HERE / "keys-aligned.png")
    print(f"\nwrote keys-aligned.png  {sheet_out.width}x{sheet_out.height}")

    RESULTS.write_text(json.dumps(report, indent=2) + "\n")
    print(f"wrote {len(panels)} poses + {RESULTS.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

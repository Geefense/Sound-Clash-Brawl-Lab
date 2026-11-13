#!/usr/bin/env python3
"""Cut the four walk keys out of the sheet, align them, and measure the cycle.

Outputs, all in this directory:

  poses/01_contact_a.png … 04_pass_b.png   460x620 RGBA, transparent, one
                                           shared figure height, soles pinned
                                           to y = 566
  loop-check.json                          the numbers behind the verdicts

Per key this reports the figure height as drawn, the uniform scale applied, and
the two boots (centroid, lowest point, sole tilt, whether the sole is on the
floor). Across the cycle it reports pairwise pose difference (duplicate check),
the A/B foot-plot comparison (leg alternation), and the stance-foot travel
between a contact key and the pass that follows it (the root motion a game
would need, and the slide a static four-key loop shows).

The sheet's two rows are drawn at different scales, so every key is normalised
to a common figure height before comparison; without that the bottom row would
read ~10% larger and every measurement would be polluted.

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


def segment(cell: np.ndarray) -> np.ndarray:
    """Foreground mask of the posed figure; label text and ground line dropped."""
    a = cell.astype(np.float32)
    bg = np.median(a[2:14, 2:14].reshape(-1, 3), axis=0)
    mask = np.sqrt(((a - bg) ** 2).sum(2)) > BG_TOLERANCE
    mask = ndimage.binary_opening(mask, np.ones((2, 2)))

    # A near-white run spanning most of the cell is the ground line. The figure
    # rests on it, so clear those pixels before taking the largest component.
    v = a.max(2) / 255.0
    s = np.where(v > 0, (v - a.min(2) / 255.0) / np.maximum(v, 1e-6), 0.0)
    white = (v > 0.86) & (s < 0.18)
    for y in np.where(white.sum(1) > 0.55 * cell.shape[1])[0]:
        lo, hi = max(0, y - 1), y + 2
        mask[lo:hi, :] &= ~white[lo:hi, :]

    lab, n = ndimage.label(mask)
    if n == 0:
        return mask
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    figure = np.isin(lab, [int(np.argmax(sizes)) + 1])

    # The ground line survives next to the soles as a thin horizontal stub and
    # bridges the boots. Strip pixels that are long horizontally but too thin
    # vertically to be artwork, then drop any orphaned crumbs.
    figure &= ~thin_strokes(figure)
    lab2, n2 = ndimage.label(figure)
    keep = [i for i in range(1, n2 + 1) if (lab2 == i).sum() >= 500]
    figure = np.isin(lab2, keep)

    # Close pinholes in the artwork but keep real gaps between limbs open.
    holes = ndimage.binary_fill_holes(figure) & ~figure
    hl, hn = ndimage.label(holes)
    for i in range(1, hn + 1):
        comp = hl == i
        if comp.sum() < 500:
            figure |= comp
    return figure


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
    """Figure bbox from rows/columns that hold a real stroke, not line residue.

    The ground line leaves a couple of thin antialiased rows below the soles;
    taking the raw mask bbox would hang the figure 6 px above the floor and
    shorten every other measurement.
    """
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


def boots(rgba: np.ndarray) -> list[dict]:
    """The (at most two) boots: centroid, lowest point, sole tilt, contact."""
    a = rgba[:, :, :3].astype(np.float32) / 255.0
    alpha = rgba[:, :, 3] > 40
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    tan = alpha & (r > 0.52) & (r - b > 0.20) & (g > 0.22) & (r < 0.99)
    tan = ndimage.binary_opening(tan, np.ones((3, 3)))
    tan = ndimage.binary_closing(tan, np.ones((9, 9)))  # sole + upper parts
    lab, n = ndimage.label(tan)
    out = []
    for i in range(1, n + 1):
        ys, xs = np.where(lab == i)
        # boots only: skin and the mic hand are the same tan, but sit far above
        # the floor line
        if xs.size < 900 or ys.max() < FLOOR_Y - 130:
            continue
        edge = []
        for x in range(xs.min(), xs.max() + 1):
            col = np.where(lab[:, x] == i)[0]
            if col.size:
                edge.append((x, col.max()))
        edge = np.array(edge, dtype=np.float32)
        slope = float(np.polyfit(edge[:, 0], edge[:, 1], 1)[0]) if edge.size else 0.0
        out.append(
            {
                "area": int(xs.size),
                "cx": round(float(xs.mean()), 1),
                "lowestY": int(ys.max()),
                "soleSlope": round(slope, 3),
                # the sole's dark bottom edge sits ~6 px below the tan area
                "onFloor": bool(FLOOR_Y - ys.max() <= 10),
                "width": int(xs.max() - xs.min()),
            }
        )
    out.sort(key=lambda d: d["cx"])
    return out


def main() -> int:
    sheet = Image.open(SHEET).convert("RGB")
    cells = []
    for slug, label, box in CELLS:
        cell = np.asarray(sheet.crop(box))
        mask = segment(cell)
        cells.append(
            {
                "slug": slug,
                "label": label,
                "rgb": cell,
                "mask": mask,
                "bbox": solid_bbox(mask),
            }
        )

    heights = [c["bbox"][3] - c["bbox"][1] + 1 for c in cells]
    print("figure height per key, as drawn on the sheet:")
    for c, h in zip(cells, heights):
        print(f"  {c['label']:14s} {h} px")
    print(f"  spread {min(heights)}..{max(heights)} px — the two rows are drawn at "
          f"different scales, so each key is normalised to {FIGURE_H} px\n")

    centre_x = float(np.mean([(c["bbox"][0] + c["bbox"][2]) / 2 for c in cells]))
    POSES.mkdir(exist_ok=True)

    report = {
        "panel": [PANEL_W, PANEL_H],
        "figureHeight": FIGURE_H,
        "floorY": FLOOR_Y,
        "normalisation": "per-key scale to a common figure height, then soles "
                         "pinned to the floor line",
        "keys": [],
    }
    panels = []

    for c in cells:
        x0, y0, x1, y1 = c["bbox"]
        scale = FIGURE_H / float(y1 - y0 + 1)
        rgb = c["rgb"][y0:y1 + 1, x0:x1 + 1].astype(np.float32)
        alpha = c["mask"][y0:y1 + 1, x0:x1 + 1].astype(np.float32)

        # premultiply so LANCZOS does not pull dark background into the edges
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

        canvas = Image.new("RGBA", (PANEL_W, PANEL_H), (0, 0, 0, 0))
        px = int(round(PANEL_W / 2 - new_w / 2 - (centre_x - (x0 + x1) / 2) * scale))
        canvas.paste(Image.fromarray(flat, "RGBA"), (px, FLOOR_Y - new_h),
                     Image.fromarray(flat, "RGBA"))
        canvas.save(POSES / f"{c['slug']}.png")
        panels.append((c, np.asarray(canvas)))

        boot_list = boots(np.asarray(canvas))
        rear = boot_list[0] if boot_list else None
        front = boot_list[-1] if boot_list else None
        report["keys"].append(
            {
                "key": c["label"],
                "slug": c["slug"],
                "file": f"poses/{c['slug']}.png",
                "drawnHeightPx": int(y1 - y0 + 1),
                "scale": round(scale, 4),
                "boots": boot_list,
                "frontBoot": front,
                "rearBoot": rear,
            }
        )
        print(f"{c['label']:14s} scale {scale:.3f}  "
              f"rear x={rear['cx']:.0f} y={rear['lowestY']} tilt={rear['soleSlope']:+.2f}  "
              f"front x={front['cx']:.0f} y={front['lowestY']} "
              f"tilt={front['soleSlope']:+.2f}  onFloor={front['onFloor']}")

    # ---- duplicates -------------------------------------------------------
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

    # ---- A/B leg alternation ---------------------------------------------
    ka, kb = report["keys"][0], report["keys"][2]  # 01 CONTACT A, 03 CONTACT B
    ab = {
        "frontBootCx": [ka["frontBoot"]["cx"], kb["frontBoot"]["cx"]],
        "rearBootCx": [ka["rearBoot"]["cx"], kb["rearBoot"]["cx"]],
        "frontSoleSlope": [ka["frontBoot"]["soleSlope"], kb["frontBoot"]["soleSlope"]],
        "rearSoleSlope": [ka["rearBoot"]["soleSlope"], kb["rearBoot"]["soleSlope"]],
        "frontOnFloor": [ka["frontBoot"]["onFloor"], kb["frontBoot"]["onFloor"]],
        "deltaFrontCx": round(abs(ka["frontBoot"]["cx"] - kb["frontBoot"]["cx"]), 1),
        "deltaRearCx": round(abs(ka["rearBoot"]["cx"] - kb["rearBoot"]["cx"]), 1),
        "verdict": None,
    }
    same_plot = ab["deltaFrontCx"] <= 12 and ab["deltaRearCx"] <= 12
    same_tilt = all(
        abs(a - b) <= 0.25
        for a, b in zip(ab["frontSoleSlope"] + ab["rearSoleSlope"],
                        ab["frontSoleSlope"] + ab["rearSoleSlope"][::-1])
    )
    ab["verdict"] = (
        "A and B share the same foot plot (front boot within "
        f"{max(ab['deltaFrontCx'], ab['deltaRearCx']):.0f} px, same sole tilts): "
        "the drawing does not show the legs swapping, so alternation is NOT "
        "evidenced."
        if same_plot and same_tilt
        else "A and B place the boots differently; the drawing is consistent "
             "with an alternating stride."
    )
    report["alternation"] = ab
    print(f"\nA/B foot plot: front x {ab['frontBootCx']}, rear x {ab['rearBootCx']}")
    print(f"  {ab['verdict']}")

    # ---- stance travel ---------------------------------------------------
    print("\nstance-foot travel per step (contact key -> following pass key):")
    travel = []
    for contact_i, pass_i in ((0, 1), (2, 3)):
        kc, kp = report["keys"][contact_i], report["keys"][pass_i]
        planted_next = kp["rearBoot"] if kp["rearBoot"]["onFloor"] else kp["frontBoot"]
        d = planted_next["cx"] - kc["frontBoot"]["cx"]
        travel.append(
            {
                "step": f"{kc['key']} -> {kp['key']}",
                "px": round(d, 1),
                "plantedInPassKey": "rear" if kp["rearBoot"]["onFloor"] else "front",
            }
        )
        print(f"  {kc['key']} -> {kp['key']:14s} {d:+6.1f} px")
    report["stanceTravel"] = travel
    mean_travel = float(np.mean([abs(t["px"]) for t in travel])) if travel else 0.0
    report["meanStridePx"] = round(mean_travel, 1)
    print(f"  mean stride ≈ {mean_travel:.0f} px at {FIGURE_H} px figure height")

    # ---- review contact sheet ------------------------------------------
    pad = 16
    sheet_out = Image.new("RGB", (PANEL_W * 4 + pad * 5, PANEL_H + pad * 2 + 34), (16, 14, 20))
    draw = ImageDraw.Draw(sheet_out)
    try:
        f = ImageFont.load_default(size=18)
    except TypeError:  # Pillow < 10
        f = ImageFont.load_default()
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
    print(f"wrote keys-aligned.png  {sheet_out.width}x{sheet_out.height}")

    RESULTS.write_text(json.dumps(report, indent=2) + "\n")
    print(f"\nwrote {len(panels)} poses + {RESULTS.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

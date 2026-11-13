#!/usr/bin/env python3
"""Build cable-correction candidate v2 for 01_idle.

v1 removed the cable tail and floor loop correctly but its wrap-to-jacket
segment was a flat, uniform dark stroke. v2 keeps v1's removal **byte for
byte** and redraws only that segment with the cord's real construction:

  * the same silhouette-run removal as v1 (copied, not re-tuned),
  * a 5 px cord: dark outline, mid body, a one-pixel highlight on the lit side,
    matching the cross-section measured on the original cord at y=700,
  * a curved path that leaves the wrap vertically, as the original cord does,
    then bends under the ribbed hem's lower edge,
  * the hem's own edge pasted back over the tip so the jacket occludes it.

Writes:

  01_idle-jacket-entry-v2.png     full 1536x1024 RGBA, same canvas and anchor
  diff-v1-vs-v2.png               v1 vs v2 changed-region map
  diff-v1-vs-v2.json              regions, pixel counts, preservation checks

Standard library plus Pillow, numpy and scipy.
"""
from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
PACK = HERE.parents[2] / "public/assets/feedback/aligned/01_idle.png"
V1 = HERE / "01_idle-jacket-entry-v1.png"

W, H = 1536, 1024

# --- v1 removal constants (unchanged) --------------------------------------
CUT_Y = 632
FLOOR_TOP = 846

# --- v2 entry geometry ------------------------------------------------------
# Cubic bezier. It starts inside the shadow under the coil, leaves the wrap
# vertically like the original cord, then arcs right and drops under the hem.
ENTRY = [(703.5, 622.0), (710.0, 633.0), (720.0, 645.5), (728.5, 650.5)]
ENTRY_BOX = (690, 606, 744, 666)   # redrawn region; nothing outside may change
HEM_RESTORE = (722, 648, 740, 666)  # hem's lower corner over the cord's tip

# Cross-section measured on the original cord (row y=700): 1 px dark outline,
# 3 px body around 35-45, 1 px highlight up to ~70.
OUTLINE_W = 5.4
BODY_W = 3.6
HILITE_W = 1.2
OUTLINE = (8, 8, 9)
BODY = (42, 42, 43)
HILITE = (74, 74, 75)
HILITE_OFFSET = (-1.05, -0.55)   # light comes from the upper left


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


def cable_mask(opaque):
    """v1's removal, copied verbatim: isolated runs plus the floor loop."""
    mask = np.zeros((H, W), bool)
    for y in range(CUT_Y, FLOOR_TOP):
        runs = row_runs(opaque[y])
        if len(runs) >= 2:
            x0, x1 = runs[0]
            if (x1 - x0 + 1) <= 11 and x0 < 715:
                mask[y, x0:x1 + 1] = True

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


def bezier(points, steps=96):
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = points
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        pts.append((
            u ** 3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t ** 3 * x3,
            u ** 3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t ** 3 * y3,
        ))
    return pts


def stroke_alpha(pts, width, box):
    """Supersampled polyline as an anti-aliased coverage map."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    ss = 4
    layer = Image.new("L", (w * ss, h * ss), 0)
    d = ImageDraw.Draw(layer)
    sp = [((x - x0) * ss, (y - y0) * ss) for x, y in pts]
    d.line(sp, fill=255, width=int(round(width * ss)), joint="curve")
    r = width * ss / 2
    for cx, cy in (sp[0], sp[-1]):
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    return np.asarray(layer.resize((w, h), Image.LANCZOS), dtype=np.float32) / 255.0


def blend(base, alpha, colour):
    out = base.copy()
    x0, y0, x1, y1 = ENTRY_BOX
    region = out[y0:y1, x0:x1].astype(np.float32)
    a = alpha[..., None]
    paint = np.array([*colour, 255], dtype=np.float32)
    out[y0:y1, x0:x1] = np.clip(region * (1 - a) + paint * a, 0, 255).astype(np.uint8)
    return out


def draw_cord(base):
    path = bezier(ENTRY)
    hilite = [(x + HILITE_OFFSET[0], y + HILITE_OFFSET[1]) for x, y in path]
    comp = blend(base, stroke_alpha(path, OUTLINE_W, ENTRY_BOX), OUTLINE)
    comp = blend(comp, stroke_alpha(path, BODY_W, ENTRY_BOX), BODY)
    comp = blend(comp, stroke_alpha(hilite, HILITE_W, ENTRY_BOX) * 0.9, HILITE)
    return comp


def write_diff(a_img, b_img, out_png, out_json, title, note_a, note_b, meta):
    a = np.array(a_img)
    b = np.array(b_img)
    changed = np.any(a != b, axis=2)
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

    opaque = a[..., 3] > 24
    base = (a[..., :3] * 0.26).astype(np.uint8)
    diff_img = base.copy()
    diff_img[opaque] = (base[opaque] + 26).clip(0, 255)
    only_a = changed & (b[..., 3] < a[..., 3])
    only_b = changed & ~only_a
    diff_img[only_a] = (255, 72, 190)
    diff_img[only_b] = (70, 255, 190)

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
    dd.text((600, 40), title, fill=(235, 235, 235), font=font)
    dd.text((600, 72), note_a, fill=(255, 150, 220), font=font)
    dd.text((600, 104), note_b, fill=(140, 255, 205), font=font)
    dimg.save(out_png)

    ys, xs = np.nonzero(changed)
    payload = {
        "pair": [title],
        "canvas": [W, H],
        "changed_pixels": int(changed.sum()),
        "changed_bbox": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
        "regions": regions,
    }
    payload.update(meta)
    out_json.write_text(json.dumps(payload, indent=2) + "\n")
    return changed, regions


def main():
    src = np.array(Image.open(PACK).convert("RGBA"))
    if (src.shape[1], src.shape[0]) != (W, H):
        raise SystemExit(f"unexpected canvas {src.shape}")
    v1_img = Image.open(V1).convert("RGBA")
    v1 = np.array(v1_img)

    # --- v1's base: original with the cable removed, no entry stroke yet ---
    opaque = src[..., 3] > 24
    cable = cable_mask(opaque)
    allowed = np.zeros((H, W), bool)
    allowed[CUT_Y - 4:, 560:760] = True
    cable &= allowed
    base = src.copy()
    base[cable] = 0

    # The rebuilt base must match v1 everywhere except inside the entry box,
    # which is what makes "v1's successful removal is preserved" checkable.
    eb = ENTRY_BOX
    outside = np.ones((H, W), bool)
    outside[eb[1]:eb[3], eb[0]:eb[2]] = False
    if np.any(base[outside] != v1[outside]):
        raise SystemExit("rebuilding v1's base does not match v1 outside the entry box — aborting")

    comp = draw_cord(base)

    # The hem's edge and the shadow under it occlude the cord's tip.
    hx0, hy0, hx1, hy1 = HEM_RESTORE
    hem = np.zeros((H, W), bool)
    hem[hy0:hy1, hx0:hx1] = True
    fabric = hem & opaque
    comp[fabric] = src[fabric]

    # Guard: no change outside the entry box.
    if np.any(comp[outside] != base[outside]):
        raise SystemExit("v2 changed pixels outside its entry box — aborting")

    v2_img = Image.fromarray(comp, "RGBA")
    v2_img.save(HERE / "01_idle-jacket-entry-v2.png")

    changed, regions = write_diff(
        v1_img, v2_img,
        HERE / "diff-v1-vs-v2.png",
        HERE / "diff-v1-vs-v2.json",
        "01_idle — cable candidate v1 vs v2 (entry only)",
        "magenta = v1 entry pixels dropped",
        "green = v2 cord pixels",
        {
            "source_original": "artifacts/sound-clash/public/assets/feedback/aligned/01_idle.png",
            "candidate_v1": "01_idle-jacket-entry-v1.png",
            "candidate_v2": "01_idle-jacket-entry-v2.png",
            "entry_box": list(ENTRY_BOX),
            "entry_curve": [list(p) for p in ENTRY],
            "cord_widths_px": {"outline": OUTLINE_W, "body": BODY_W, "highlight": HILITE_W},
            "cord_colours": {"outline": OUTLINE, "body": BODY, "highlight": HILITE},
            "preserved_outside_entry_box": True,
            "removal_identical_to_v1": True,
        },
    )

    print(f"v1 vs v2 changed pixels: {int(changed.sum())} in {len(regions)} regions")
    for r in regions:
        print(f"  region {r['id']}: {r['pixels']} px bbox={r['bbox']}")
    print(f"written: {HERE / '01_idle-jacket-entry-v2.png'}")
    print(f"written: {HERE / 'diff-v1-vs-v2.png'}")
    print(f"written: {HERE / 'diff-v1-vs-v2.json'}")


if __name__ == "__main__":
    main()

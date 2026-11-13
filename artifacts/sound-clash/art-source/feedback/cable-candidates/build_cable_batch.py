#!/usr/bin/env python3
"""Cable-only candidates for the BOX/guard batch, in the approved idle-v1 style.

Owner decision (AGENTS.md, 2026-11-13): v1's clean concealed treatment is the
reference. The cord comes from inside the jacket and does not need to show its
route. So each pose here loses only its unnecessary trailing cable — the part
that hangs free below the garment — and the remaining end stops where the
jacket, leg or boot occludes it. Nothing is drawn, no connector, plug or route
is added, and no pixel outside the removal is touched.

Method per pose:
  * rows below each pose's cut line are scanned for thin isolated runs (the
    free cord), inside a narrow corridor that contains only the cable;
  * the run set is reduced to the single connected component that starts at the
    cut line, so boot laces, stripes and other thin details stay untouched;
  * that component is additionally filtered to cord-dark pixels;
  * the pixels are deleted to transparent, exactly like v1's removal.

Originals are read, never written. Outputs one candidate, one diff and one
region file per pose. Standard library plus Pillow, numpy and scipy.
"""
from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
PACK_DIR = HERE.parents[2] / "public/assets/feedback/aligned"

W, H = 1536, 1024

# pose: cut line, corridor (x0, x1, y0, y1), last contact with the figure
POSES = {
    "08_block": {
        "cut_y": 634, "protect_boxes": [],
        "window": (554, 736),
        "occluder": "jacket hem / left hip",
        "floor_boxes": [],
        "residual_boxes": [],
    },
    "12_backhand_windup": {
        "cut_y": 660,
        "window": (814, 1046),
        "occluder": "right thigh / boot",
        "floor_boxes": [],
        "residual_boxes": [],
    },
    "13_box_palm": {
        "cut_y": 642,
        "window": (488, 736),
        "occluder": "jacket hem / left thigh",
        "floor_boxes": [],
        "residual_boxes": [],
    },
    "14_followthrough": {
        "cut_y": 574, "protect_boxes": [(592, 535, 700, 668)],
        "window": (476, 660),
        "occluder": "jacket hem / left thigh",
        "floor_boxes": [],
        "residual_boxes": [],
    },
}

DARK_LUM = 150.0   # the cord is near-black to mid grey; laces and suede are far brighter
MIN_PX = 15        # smallest cord fragment worth deleting


def row_runs(row, max_w=13):
    runs, start = [], None
    for i in range(len(row) + 1):
        v = row[i] if i < len(row) else False
        if v and start is None:
            start = i
        elif not v and start is not None:
            if i - start <= max_w:
                runs.append((start, i - 1))
            start = None
    return runs


def cord_mask(src, cut_y, window, protect=()):
    """Everything in the corridor below the cut that is neither the figure's
    solid mass nor one of its own thin rims (garment outlines, wrap rings,
    laces). The trailing cable is thin and separate, so it falls out; the
    clothing and shoes keep every pixel, including their edges."""
    x0, x1 = window
    opaque = src[..., 3] > 24
    core = ndimage.binary_opening(opaque, np.ones((13, 13), bool))
    core = ndimage.binary_fill_holes(core)
    rim = opaque & ~core & ndimage.binary_dilation(core, np.ones((7, 7), bool))

    region = np.zeros((H, W), bool)
    region[cut_y:, x0:x1] = True
    cord = opaque & region
    cord &= ~ndimage.binary_dilation(core, np.ones((5, 5), bool))
    cord &= ~ndimage.binary_dilation(rim, np.ones((5, 5), bool))
    for px0, py0, px1, py1 in protect:
        cord[py0:py1, px0:px1] = False
    cord = ndimage.binary_fill_holes(cord)
    cord = ndimage.binary_opening(cord, np.ones((2, 2), bool))
    if not cord.any():
        raise SystemExit(f"no cable found below y={cut_y} in x {x0}-{x1}")
    return cord, int(cord.sum())


def build(name, cfg):
    path = PACK_DIR / f"{name}.png"
    img = Image.open(path).convert("RGBA")
    src = np.array(img)
    mask, n_before = cord_mask(src, cfg["cut_y"], cfg["window"], cfg.get("protect_boxes", []))
    if n_before == 0:
        raise SystemExit(f"{name}: empty cable mask — aborting")

    out = src.copy()
    out[mask] = 0
    lum = src[..., :3].astype(np.float32) @ np.array([0.299, 0.587, 0.114])

    # Anti-aliased fringe: the deleted run leaves a dark rim one pixel out.
    # Only dark pixels are taken, so tan suede and bright cloth edges survive.
    rim = ndimage.binary_dilation(mask, np.ones((3, 3), bool)) & ~mask
    below = np.zeros((H, W), bool)
    below[cfg["cut_y"]:, cfg["window"][0]:cfg["window"][1]] = True
    rim &= below & (src[..., 3] > 24) & (lum < 140)
    out[rim] = 0

    # On the floor the loop drags a soft shadow, and neither the cord nor that
    # shadow is a thin opaque run. Inside each small loop box, keep only the
    # shoe: bright suede plus its dark outline (the outline sits within a few
    # pixels of bright pixels), and drop everything else.
    # The Clarks and the cream sole are warm tan; the cord, its shadow and the
    # floor are neutral. Keep warm pixels and drop the rest inside the boxes.
    warm = (src[..., :3].astype(int)[..., 0] - src[..., :3].astype(int)[..., 2] > 30) & (lum > 85)
    bright = ndimage.binary_dilation(warm, np.ones((5, 5), bool))
    for bx0, by0, bx1, by1 in cfg["floor_boxes"]:
        box = np.zeros((H, W), bool)
        box[by0:by1, bx0:bx1] = True
        out[box & ~bright] = 0

    # The last of the loop is only soft shadow. On the floor band, drop faint
    # pixels that are not attached to a solid surface: the shoe and its
    # antialiased edge are always next to near-opaque pixels, the shadow is not.
    # Last dark specks: tiny cord or shadow bits that survive beside the shoe.
    for bx0, by0, bx1, by1 in cfg.get("residual_boxes", []):
        box = np.zeros((H, W), bool)
        box[by0:by1, bx0:bx1] = True
        out[box & (lum < 105)] = 0

    solid = src[..., 3] > 240
    near_solid = ndimage.binary_dilation(solid, np.ones((7, 7), bool))
    floor_band = np.zeros((H, W), bool)
    floor_band[850:, cfg["window"][0]:cfg["window"][1]] = True
    rest = (out[..., 3] > 24) & (lum < 120) & floor_band & ~near_solid
    lab3, k3 = ndimage.label(rest, np.ones((3, 3), bool))
    sizes3 = ndimage.sum(rest, lab3, range(1, k3 + 1)) if k3 else []
    small3 = np.isin(lab3, [i + 1 for i, s in enumerate(sizes3) if s <= 400]) if k3 else np.zeros((H, W), bool)
    out[small3] = 0

    # Guard: nothing changes above the cut or outside the corridor.
    x0, x1 = cfg["window"]
    allowed = np.zeros((H, W), bool)
    allowed[cfg["cut_y"]:, x0:x1] = True
    changed = np.any(out != src, axis=2)
    if np.any(changed & ~allowed):
        raise SystemExit(f"{name}: change outside the allowed corridor — aborting")
    if np.any(changed[:cfg["cut_y"], :]):
        raise SystemExit(f"{name}: change above the cut — aborting")

    cand = Image.fromarray(out, "RGBA")
    cand.save(HERE / f"{name}-cable-v1.png")

    # ---- diff view + regions, same style as the idle candidate ----
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

    opaque = src[..., 3] > 24
    base = (src[..., :3] * 0.26).astype(np.uint8)
    diff_img = base.copy()
    diff_img[opaque] = (base[opaque] + 26).clip(0, 255)
    diff_img[changed] = (255, 72, 190)

    dimg = Image.fromarray(diff_img)
    dd = ImageDraw.Draw(dimg)
    try:
        font = ImageFont.load_default(size=24)
    except Exception:
        font = None
    ys, xs = np.nonzero(changed)
    dd.rectangle([int(xs.min()) - 6, int(ys.min()) - 6, int(xs.max()) + 6, int(ys.max()) + 6],
                 outline=(255, 220, 120), width=2)
    dd.line([(x0, cfg["cut_y"]), (x1, cfg["cut_y"])], fill=(120, 220, 255), width=2)
    dd.text((560, 40), f"{name} — original vs cable candidate v1", fill=(235, 235, 235), font=font)
    dd.text((560, 72), "magenta = trailing cable removed", fill=(255, 150, 220), font=font)
    dd.text((560, 104), f"blue line = cut at y{cfg['cut_y']} · {cfg['occluder']}", fill=(150, 210, 255), font=font)
    dimg.save(HERE / f"diff-{name}-vs-v1.png")

    meta = {
        "pose": name,
        "source": f"artifacts/sound-clash/public/assets/feedback/aligned/{name}.png",
        "candidate": f"{name}-cable-v1.png",
        "canvas": [W, H],
        "cut_y": cfg["cut_y"],
        "corridor_x": [x0, x1],
        "occluder": cfg["occluder"],
        "changed_pixels": int(changed.sum()),
        "changed_bbox": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
        "regions": regions,
        "anchor": [768, 900],
    }
    (HERE / f"diff-{name}-vs-v1.json").write_text(json.dumps(meta, indent=2) + "\n")
    print(f"{name}: removed {int(changed.sum())} px in {len(regions)} region(s), "
          f"bbox {meta['changed_bbox']}, cut y{cfg['cut_y']}")


def main():
    for name, cfg in POSES.items():
        build(name, cfg)


if __name__ == "__main__":
    main()

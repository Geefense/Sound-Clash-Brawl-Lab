#!/usr/bin/env python3
"""v2 candidates for 12_backhand_windup and 14_followthrough.

v1 removed the floor-tail correctly but left the cable ending in open air.
v2 keeps v1 exactly as it is and adds one short connection from that cut end
back to the nearest real occluder on the same arm:

  12_backhand_windup  — cord end runs up-left and tucks under the sleeve cuff
  14_followthrough    — cord end runs right and tucks behind the open hand

The stroke is drawn at the cord's own section (dark outline, mid body, lit-side
highlight, 4x supersampled) and then the occluder's own pixels are pasted back
over its tip, so the cable disappears behind clothing or a hand rather than
stopping in mid-air. Nothing else is touched: v1's floor-tail removal, the mic,
grip, pose, trousers, Clarks and both anchors stay identical.

Standard library plus Pillow, numpy and scipy.
"""
from pathlib import Path
import json

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
PACK_DIR = HERE.parents[2] / "public/assets/feedback/aligned"

W, H = 1536, 1024

OUTLINE = (2, 2, 2)
BODY = (38, 38, 38)
HILITE = (78, 78, 78)
OUTLINE_W = 6.9
BODY_W = 4.3
HILITE_W = 1.4

# start = v1's cut end; end = inside the occluder; tuck = radius of the occluder
# pixels pasted back over the tip.
JOBS = {
    "12_backhand_windup": {
        "start": (860.0, 664.0),
        "control": (857.0, 646.0),
        "end": (845.0, 636.0),
        "tuck": 6,
        "occluder": "sleeve cuff",
        "tone": ((0, 0, 0), (17, 17, 17), (36, 36, 36), (6.0, 3.6, 0.9)),
        "extra_cut": None,
        "corridor": (814, 1046),
    },
    "14_followthrough": {
        "start": (610.0, 611.0),
        "p1": (604.0, 646.0),
        "p2": (640.0, 634.0),
        "end": (657.0, 586.0),
        "tuck": 10,
        "occluder": "forearm wrap",
        "tone": (OUTLINE, BODY, HILITE, (OUTLINE_W, BODY_W, HILITE_W)),
        "extra_cut": (585, 632, 620, 690),
        "corridor": (476, 660),
    },
}


def bezier(p0, p1, p2, steps=64):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        pts.append((
            u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
            u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1],
        ))
    return pts


def cubic(p0, p1, p2, p3, steps=96):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        pts.append((
            u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
            u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1],
        ))
    return pts


def stroke_alpha(pts, width, box):
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


def blend(base, alpha, colour, box):
    out = base.copy()
    x0, y0, x1, y1 = box
    region = out[y0:y1, x0:x1].astype(np.float32)
    a = alpha[..., None]
    paint = np.array([*colour, 255], dtype=np.float32)
    out[y0:y1, x0:x1] = np.clip(region * (1 - a) + paint * a, 0, 255).astype(np.uint8)
    return out


def build(name, job):
    src_img = Image.open(PACK_DIR / f"{name}.png").convert("RGBA")
    src = np.array(src_img)
    v1_img = Image.open(HERE / f"{name}-cable-v1.png").convert("RGBA")
    v1 = np.array(v1_img)

    tone_o, tone_b, tone_h, tone_w = job["tone"]
    if "p1" in job:
        path = cubic(job["start"], job["p1"], job["p2"], job["end"])
    else:
        path = bezier(job["start"], job["control"], job["end"])
    xs = [p[0] for p in path]
    ys = [p[1] for p in path]
    box = (int(min(xs)) - 8, int(min(ys)) - 8, int(max(xs)) + 9, int(max(ys)) + 9)

    # Draw on v1, so the approved floor-tail removal is carried over untouched.
    comp = v1_img.copy()
    array = np.array(comp)

    # A shorter hang than v1's, when the wrap sits above the old cut point.
    if job["extra_cut"]:
        ex0, ex1, ey0, ey1 = job["extra_cut"]
        strip = array[ey0:ey1, ex0:ex1]
        strip[strip[..., 3] > 0] = 0
        array[ey0:ey1, ex0:ex1] = strip
    array = blend(array, stroke_alpha(path, tone_w[0], box), tone_o, box)
    array = blend(array, stroke_alpha(path, tone_w[1], box), tone_b, box)
    hilite = [(x + 0.7, y - 0.9) for x, y in path]
    array = blend(array, stroke_alpha(hilite, tone_w[2], box) * 0.40, tone_h, box)

    # Occluder over the tip: the original cuff or hand pixels win.
    yy, xx = np.mgrid[0:H, 0:W]
    tuck = (xx - job["end"][0]) ** 2 + (yy - job["end"][1]) ** 2 <= job["tuck"] ** 2
    occl = tuck & (src[..., 3] > 24)
    array[occl] = src[occl]

    # Guard: v1 is respected everywhere outside this small box.
    changed = np.any(array != v1, axis=2)
    allowed = np.zeros((H, W), bool)
    allowed[box[1]:box[3], box[0]:box[2]] = True
    if job["extra_cut"]:
        ex0, ex1, ey0, ey1 = job["extra_cut"]
        allowed[ey0:ey1, ex0:ex1] = True
    if np.any(changed & ~allowed):
        raise SystemExit(f"{name}: change outside the connection box — aborting")

    out_img = Image.fromarray(array, "RGBA")
    out_img.save(HERE / f"{name}-cable-v2.png")

    lab, n = ndimage.label(changed, structure=np.ones((3, 3), bool))
    regions = []
    for i in range(1, n + 1):
        ys_, xs_ = np.nonzero(lab == i)
        if xs_.size < 4:
            continue
        regions.append({
            "id": 0,
            "pixels": int(xs_.size),
            "bbox": [int(xs_.min()), int(ys_.min()), int(xs_.max()), int(ys_.max())],
        })
    regions.sort(key=lambda r: -r["pixels"])
    for k, r in enumerate(regions, 1):
        r["id"] = k

    opaque = v1[..., 3] > 24
    base = (v1[..., :3] * 0.26).astype(np.uint8)
    diff_img = base.copy()
    diff_img[opaque] = (base[opaque] + 26).clip(0, 255)
    diff_img[changed] = (70, 255, 190)
    dimg = Image.fromarray(diff_img)
    dd = ImageDraw.Draw(dimg)
    try:
        font = ImageFont.load_default(size=24)
    except Exception:
        font = None
    ys_, xs_ = np.nonzero(changed)
    dd.rectangle([int(xs_.min()) - 6, int(ys_.min()) - 6, int(xs_.max()) + 6, int(ys_.max()) + 6],
                 outline=(255, 220, 120), width=2)
    dd.text((520, 40), f"{name} — v1 vs v2 (connection into the {job['occluder']})",
            fill=(235, 235, 235), font=font)
    dd.text((520, 72), "green = short connection added over v1", fill=(140, 255, 205), font=font)
    dimg.save(HERE / f"diff-{name}-v1-vs-v2.png")

    meta = {
        "pose": name,
        "base": f"{name}-cable-v1.png",
        "candidate": f"{name}-cable-v2.png",
        "canvas": [W, H],
        "connection": [list(job["start"]), list(job.get("control", job.get("p1"))), list(job.get("p2", job["end"])), list(job["end"])],
        "occluder": job["occluder"],
        "changed_pixels": int(changed.sum()),
        "changed_bbox": [int(xs_.min()), int(ys_.min()), int(xs_.max()), int(ys_.max())],
        "regions": regions,
        "anchor": [768, 900],
        "floor_tail_removal": "identical to v1",
    }
    (HERE / f"diff-{name}-v1-vs-v2.json").write_text(json.dumps(meta, indent=2) + "\n")
    print(f"{name}: +{int(changed.sum())} px changed over v1, bbox {meta['changed_bbox']}, "
          f"tucks behind the {job['occluder']}")


def main():
    for name, job in JOBS.items():
        build(name, job)


if __name__ == "__main__":
    main()

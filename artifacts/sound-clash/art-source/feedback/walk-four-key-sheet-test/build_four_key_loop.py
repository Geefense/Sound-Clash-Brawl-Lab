#!/usr/bin/env python3
"""Extract four walk keys from a labelled sheet and build a stepped loop.

The sheet must contain four character panels on a flat backdrop, in reading
order 01, 02, 03, 04. Labels and floor lines are removed by geometry (the crop
stops at the ruler line) and by colour (the line is light and neutral, the
shoes are not). Nothing is mirrored, morphed or interpolated: the loop is the
four drawings held in order.

Usage:
    FFMPEG=/path/to/ffmpeg python3 build_four_key_loop.py analyze
    FFMPEG=/path/to/ffmpeg python3 build_four_key_loop.py build
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
SHEET = Path(os.environ.get("SHEET", HERE / "source-sheet.png"))
TARGET_HEIGHT = 600          # one uniform scale for all four keys
HOLD_FRAMES = 6              # stepped: each key held
OUT_FPS = 24
CYCLES = 6
MARGIN_X = 40
MARGIN_BOTTOM = 80
MARGIN_TOP = 40


# --------------------------------------------------------------------- basics

def load(path: Path) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int16)


def background(rgb: np.ndarray) -> np.ndarray:
    b = np.concatenate([
        rgb[:8].reshape(-1, 3), rgb[-8:].reshape(-1, 3),
        rgb[:, :8].reshape(-1, 3), rgb[:, -8:].reshape(-1, 3),
    ])
    return np.median(b, axis=0)


def light_ink(rgb: np.ndarray) -> np.ndarray:
    """Labels and ruler lines: bright and close to neutral."""
    spread = rgb.max(2) - rgb.min(2)
    return (rgb.mean(2) > 150) & (spread < 40)


def figure_mask(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    return np.abs(rgb - bg).max(2) > 18


# --------------------------------------------------------------------- panels

def find_panels(rgb: np.ndarray, bg: np.ndarray) -> list[dict]:
    fig = figure_mask(rgb, bg)
    fig = ndimage.binary_closing(fig, iterations=2)
    lab, n = ndimage.label(fig)
    sizes = ndimage.sum(fig, lab, range(1, n + 1))
    min_area = max(2000, int(0.002 * fig.size))
    comps = []
    for i in range(1, n + 1):
        if sizes[i - 1] < min_area:
            continue
        ys, xs = np.nonzero(lab == i)
        comps.append({"x0": int(xs.min()), "x1": int(xs.max()),
                      "y0": int(ys.min()), "y1": int(ys.max()),
                      "area": int(sizes[i - 1])})
    if len(comps) < 4:
        raise SystemExit(f"expected 4 character panels, found {len(comps)}")

    # Keep the four largest, then assign by row and column.
    comps.sort(key=lambda c: c["area"], reverse=True)
    comps = comps[:4]
    comps.sort(key=lambda c: (c["y0"] + c["y1"]) / 2)
    top, bottom = comps[:2], comps[2:]
    top.sort(key=lambda c: c["x0"])
    bottom.sort(key=lambda c: c["x0"])
    ordered = top + bottom
    for i, c in enumerate(ordered, 1):
        c["index"] = i
    return ordered


def floor_line_rows(rgb: np.ndarray, panel: dict) -> list[int]:
    ink = light_ink(rgb)
    x0 = max(0, panel["x0"] - 60)
    x1 = min(rgb.shape[1], panel["x1"] + 60)
    rows = []
    for y in range(max(0, panel["y1"] - 3), min(rgb.shape[0], panel["y1"] + 40)):
        if ink[y, x0:x1].mean() > 0.35:
            rows.append(y)
    return rows


# --------------------------------------------------------------------- keying

def cut_character(rgb: np.ndarray, bg: np.ndarray, panel: dict) -> tuple[np.ndarray, dict]:
    """RGBA crop of one character, no label, no ruler line."""
    lines = floor_line_rows(rgb, panel)
    stop = (min(lines) - 1) if lines else panel["y1"] + 2
    x0 = max(0, panel["x0"] - MARGIN_X)
    x1 = min(rgb.shape[1], panel["x1"] + MARGIN_X)
    y0 = max(0, panel["y0"] - MARGIN_TOP)
    y1 = min(rgb.shape[0], stop)
    sub = rgb[y0:y1, x0:x1]

    d = np.abs(sub - bg).max(2)
    # Soft ramp: dark-on-dark edges (dreadlocks) keep most of their alpha.
    a = np.clip((d - 5.0) / 13.0, 0.0, 1.0)
    a[a < 0.10] = 0.0

    # Drop only isolated specks, never structure: the hair must survive intact.
    lab, n = ndimage.label(a > 0.25)
    if n > 1:
        sizes = ndimage.sum(a > 0.25, lab, range(1, n + 1))
        main = int(np.argmax(sizes)) + 1
        for i in range(1, n + 1):
            if i == main:
                continue
            if sizes[i - 1] < 40:
                a[lab == i] = 0.0

    # Colour decontamination so partial alpha does not carry backdrop navy.
    safe = np.maximum(a, 0.15)[..., None]
    rgbc = np.clip((sub - (1.0 - safe) * bg[None, None, :]) / safe, 0, 255)

    rgba = np.dstack([rgbc.astype(np.uint8), (a * 255).astype(np.uint8)])
    return rgba, {"lineRows": lines, "crop": [x0, y0, x1, y1]}


def measure(rgba: np.ndarray) -> dict:
    a = rgba[:, :, 3]
    solid = a > 128
    ys, xs = np.nonzero(solid)
    sole = int(ys.max())
    top = int(ys.min())
    h = sole - top
    # Shoes: tan/orange, distinct from the grey floor and the dark background.
    rgb = rgba[:, :, :3].astype(np.int16)
    shoe = solid & (rgb[:, :, 0] > 140) & ((rgb[:, :, 0] - rgb[:, :, 2]) > 45)
    # Only the lower legs: the hands are the same tan as the shoes.
    shoe[: int(top + h * 0.70)] = False
    lab, n = ndimage.label(shoe)
    blobs = []
    for i in range(1, n + 1):
        m = lab == i
        if m.sum() < 250:
            continue
        yy, xx = np.nonzero(m)
        blobs.append({"x": float(xx.mean()), "bottom": int(yy.max()),
                      "top": int(yy.min()), "area": int(m.sum()),
                      "x0": int(xx.min()), "x1": int(xx.max())})
    blobs.sort(key=lambda b: b["x"])
    support = max(blobs, key=lambda b: b["bottom"]) if blobs else None
    lifted = min(blobs, key=lambda b: b["bottom"]) if len(blobs) > 1 else None

    # Ankle band: two narrow leg columns when the feet are apart, one when the
    # legs are together. This survives shoes that touch and merge.
    band = solid[max(0, sole - 36): max(1, sole - 8)]
    bl, bn = ndimage.label(band)
    ankles = []
    for i in range(1, bn + 1):
        m = bl == i
        if m.sum() < 40:
            continue
        yy, xx = np.nonzero(m)
        ankles.append({"x": float(xx.mean()), "x0": int(xx.min()), "x1": int(xx.max())})
    ankles.sort(key=lambda a: a["x"])
    # Mic: pale, low-saturation metal, in the upper half of the figure.
    pale = solid & (rgb.mean(2) > 120) & ((rgb.max(2) - rgb.min(2)) < 26)
    pale[: int(top + h * 0.08)] = False
    pale[int(top + h * 0.55):] = False
    ys2, xs2 = np.nonzero(pale)
    mic = {"x": float(xs2.mean()), "y": float(ys2.mean()), "px": int(len(xs2))} if len(xs2) else None
    return {
        "height": h, "soleY": sole, "topY": top,
        "shoeBlobs": blobs, "support": support, "lifted": lifted,
        "ankles": ankles,
        "ankleSpreadPx": (ankles[-1]["x"] - ankles[0]["x"]) if len(ankles) > 1 else 0.0,
        "mic": mic,
        "bodyCx": float((xs.min() + xs.max() + 1) / 2),
        "supportCx": support["x"] if support else float(xs.mean()),
    }


def align(items: list[tuple[int, np.ndarray, dict]]) -> list[tuple[int, Image.Image, dict]]:
    """One uniform scale; support foot pinned to a common baseline."""
    heights = [m["height"] for _, _, m in items]
    scale = TARGET_HEIGHT / float(np.median(heights))
    scaled = []
    for idx, rgba, m in items:
        im = Image.fromarray(rgba)
        im = im.resize((int(round(im.width * scale)), int(round(im.height * scale))), Image.LANCZOS)
        scaled.append((idx, im, m))
    widest = max(im.width for _, im, _ in scaled)
    panel_w = widest + 2 * MARGIN_X
    panel_h = TARGET_HEIGHT + MARGIN_TOP + MARGIN_BOTTOM
    floor_y = panel_h - MARGIN_BOTTOM + 10
    out = []
    for idx, im, m in scaled:
        # Horizontal anchor: the supporting foot, so the stance does not slide.
        foot_x = (m["support"]["x"] if m["support"] else m["bodyCx"]) * scale
        px = panel_w / 2 - foot_x
        py = floor_y - m["soleY"] * scale
        panel = Image.new("RGBA", (panel_w, panel_h), (0, 0, 0, 0))
        panel.alpha_composite(im, (int(round(px)), int(round(py))))
        out.append((idx, panel, {**m, "scale": scale, "offsetX": px,
                                 "panel": [panel_w, panel_h], "floorY": floor_y}))
    return out


# ------------------------------------------------------------------ reporting

def pairwise_diff(panels: list[Image.Image]) -> dict:
    arr = [np.asarray(p).astype(np.int16) for p in panels]
    res = {}
    for i in range(len(arr)):
        for j in range(i + 1, len(arr)):
            a, b = arr[i], arr[j]
            va, vb = a[:, :, 3] > 100, b[:, :, 3] > 100
            union = va | vb
            inter = va & vb
            iou = float(inter.sum() / union.sum()) if union.any() else 0
            d = np.abs(a[:, :, :3] - b[:, :, :3]).max(2)[union]
            res[f"{i + 1}-{j + 1}"] = {
                "iou": round(iou, 3),
                "meanDiff": round(float(d.mean()), 1) if d.size else 0,
                "changedPct": round(float((np.abs(a[:, :, :3] - b[:, :, :3]).max(2) > 12)[union].mean() * 100), 2) if union.any() else 0,
            }
    return res


def font(size: int, bold: bool = False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    cands = [Path("/usr/share/fonts/truetype/dejavu") / name, Path("/usr/share/fonts/TTF") / name]
    try:
        import matplotlib
        cands.append(Path(matplotlib.__file__).parent / "mpl-data" / "fonts" / "ttf" / name)
    except Exception:
        pass
    for c in cands:
        if c.exists():
            return ImageFont.truetype(str(c), size)
    return ImageFont.load_default(size=size)


def wrap(draw, text, fnt, width):
    out, line = [], ""
    for w in text.split():
        probe = (line + " " + w).strip()
        if line and draw.textlength(probe, font=fnt) > width:
            out.append(line)
            line = w
        else:
            line = probe
    if line:
        out.append(line)
    return out


# --------------------------------------------------------------------- build

def run_analysis(sheet_path: Path):
    rgb = load(sheet_path)
    bg = background(rgb)
    panels = find_panels(rgb, bg)
    items = []
    for p in panels:
        rgba, meta = cut_character(rgb, bg, p)
        m = measure(rgba)
        m["crop"] = meta["crop"]
        m["lineRows"] = meta["lineRows"]
        items.append((p["index"], rgba, m))
    aligned = align(items)
    return rgb, bg, panels, items, aligned


def build() -> None:
    rgb, bg, panels, items, aligned = run_analysis(SHEET)
    (HERE / "keys").mkdir(exist_ok=True)
    (HERE / "frames").mkdir(exist_ok=True)

    names = {1: "01-contact-a", 2: "02-pass-a", 3: "03-contact-b", 4: "04-pass-b"}
    entries = []
    for idx, panel, m in aligned:
        path = HERE / "keys" / f"{names[idx]}.png"
        panel.save(path)
        sup = m["support"] or {}
        lead_side = None
        if len(m["ankles"]) >= 2:
            lead = m["ankles"][-1]
            lead_side = "screen-right" if lead["x"] > m["bodyCx"] else "screen-left"
        entries.append({
            "index": idx,
            "file": str(path.relative_to(HERE)),
            "figureHeightPx": m["height"],
            "scale": round(m["scale"], 4),
            "supportFootBottomPx": sup.get("bottom"),
            "supportFootXpx": round(sup.get("x", 0), 1),
            "supportFootSpanPx": (sup.get("x1", 0) - sup.get("x0", 0)) if sup else None,
            "liftedFootLiftPx": (sup["bottom"] - m["lifted"]["bottom"]) if (sup and m["lifted"]) else 0,
            "leadingFootSide": lead_side,
            "ankleSpreadPx": round(m["ankleSpreadPx"], 1),
            "ankleXs": [round(a["x"], 1) for a in m["ankles"]],
            "footCount": len(m["shoeBlobs"]),
            "micXrelativeToBody": round((m["mic"]["x"] - m["bodyCx"]), 1) if m["mic"] else None,
            "micY": round(m["mic"]["y"], 1) if m["mic"] else None,
            "sourceCropPx": m["crop"],
        })

    panels_img = [p for _, p, _ in aligned]
    pw, ph = panels_img[0].size
    bg_rgb = tuple(int(v) for v in bg)
    diffs = pairwise_diff(panels_img)

    # Inspection images for the alternation claim: 01 vs 03 (should differ if
    # the leading leg alternates) against 01 vs 02 (adjacent keys).
    def diff_image(a: Image.Image, b: Image.Image, path: Path) -> None:
        aa, bb = np.asarray(a).astype(np.int16), np.asarray(b).astype(np.int16)
        d = np.abs(aa[:, :, :3] - bb[:, :, :3]).max(2)
        changed = (d > 16) & ((aa[:, :, 3] > 100) | (bb[:, :, 3] > 100))
        base = np.asarray(a).astype(np.float32)
        base[:, :, 3] = base[:, :, 3] * 0.25 + 30
        out = np.zeros((*d.shape, 3), np.uint8)
        out[:] = 18
        vis = out.astype(np.float32)
        vis[..., 0] = np.clip(base[:, :, 3] * 0.35 + changed * 190, 0, 255)
        vis[..., 1] = np.clip(base[:, :, 3] * 0.35 + changed * 40, 0, 255)
        vis[..., 2] = np.clip(base[:, :, 3] * 0.35, 0, 255)
        Image.fromarray(vis.astype(np.uint8)).save(path)

    diff_image(panels_img[0], panels_img[2], HERE / "diff-01-vs-03.png")
    diff_image(panels_img[0], panels_img[1], HERE / "diff-01-vs-02.png")

    # --- alignment review sheet -----------------------------------------
    cols, rows_n = 4, 1
    cell_w = pw + 24
    sheet_w = 60 + cols * cell_w
    sheet = Image.new("RGB", (sheet_w, 190 + ph + 300), (16, 18, 22))
    d = ImageDraw.Draw(sheet)
    d.text((40, 30), "FEEDBACK — four keys extracted, cleaned and aligned", font=font(28, True), fill=(240, 240, 240))
    d.text((40, 70), "Labels and ruler lines removed · one uniform scale · supporting foot pinned to one baseline · no mirror, no morph, no inbetweens",
           font=font(13), fill=(168, 174, 184))
    for i, (idx, panel, m) in enumerate(aligned):
        x = 40 + i * cell_w
        y = 130
        cell = Image.new("RGBA", panel.size, bg_rgb + (255,))
        cell.alpha_composite(panel)
        sheet.paste(cell.convert("RGB"), (x, y))
        d.rectangle([x, y, x + pw - 1, y + ph - 1], outline=(46, 50, 60))
        d.line([(x + 10, y + m["floorY"]), (x + pw - 10, y + m["floorY"])], fill=(70, 76, 88), width=1)
        d.text((x + 6, y + ph + 8), names[idx].upper(), font=font(14, True), fill=(232, 232, 232))
        d.text((x + 6, y + ph + 28), f"height {m['height']}px  scale {m['scale']:.3f}", font=font(11), fill=(150, 156, 166))
        d.text((x + 6, y + ph + 44), f"foot span {entries[i]['supportFootSpanPx']}px  lift {entries[i]['liftedFootLiftPx']}px",
               font=font(11), fill=(150, 156, 166))
        d.text((x + 6, y + ph + 60), f"lead foot: {entries[i]['leadingFootSide']}  (ankles {entries[i]['ankleXs']})", font=font(11), fill=(150, 156, 166))
        d.text((x + 6, y + ph + 76), f"mic x-body {entries[i]['micXrelativeToBody']:+.1f}px", font=font(11), fill=(150, 156, 166))

    y0 = 130 + ph + 110
    d.text((40, y0), "ALTERNATION CHECK", font=font(16, True), fill=(240, 210, 140))
    lines = [
        f"01 leading foot on {entries[0]['leadingFootSide']}; 03 leading foot on {entries[2]['leadingFootSide']}.",
        f"Aligned silhouette overlap 01-03: IoU {diffs['1-3']['iou']:.3f}; 01-02: IoU {diffs['1-2']['iou']:.3f}.",
        f"Mean pixel difference 01-03: {diffs['1-3']['meanDiff']}; 01-02: {diffs['1-2']['meanDiff']}.",
    ]
    for i, ln in enumerate(lines):
        d.text((40, y0 + 28 + i * 20), ln, font=font(12), fill=(206, 212, 222))
    sheet.save(HERE / "alignment-check.png")

    # --- loop: each key held, in order 01 -> 02 -> 03 -> 04 ----------------
    stepped = []
    for _ in range(CYCLES):
        for _, panel, _ in aligned:
            cell = Image.new("RGBA", panel.size, bg_rgb + (255,))
            cell.alpha_composite(panel)
            f = cell.convert("RGB")
            stepped.extend([f] * HOLD_FRAMES)
    for i, f in enumerate(stepped[: len(aligned) * HOLD_FRAMES]):
        f.save(HERE / "frames" / f"loop-{i:02d}.png")

    ffmpeg = os.environ.get("FFMPEG", "ffmpeg")
    tmp = Path("/tmp/feedback-four-key-video")
    if tmp.exists():
        shutil.rmtree(tmp)
    tmp.mkdir(parents=True)
    for i, f in enumerate(stepped):
        f.save(tmp / f"v{i:04d}.png")
    mp4 = HERE / "feedback-walk-four-key-stepped.mp4"
    subprocess.run([
        ffmpeg, "-v", "error", "-y", "-framerate", str(OUT_FPS), "-i", str(tmp / "v%04d.png"),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "16", "-movflags", "+faststart", str(mp4),
    ], check=True)

    manifest = {
        "sourceSheet": SHEET.name,
        "sourceSheetSize": [int(rgb.shape[1]), int(rgb.shape[0])],
        "backdrop": [int(v) for v in bg],
        "order": [1, 2, 3, 4],
        "uniformScale": entries[0]["scale"],
        "panel": [pw, ph],
        "floorY": aligned[0][2]["floorY"],
        "holdFrames": HOLD_FRAMES,
        "outputFps": OUT_FPS,
        "cycles": CYCLES,
        "mp4Frames": len(stepped),
        "mirrored": False,
        "interpolated": False,
        "keys": entries,
        "pairwise": diffs,
    }
    (HERE / "four-key-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({k: v for k, v in manifest.items() if k != "keys"}, indent=2))
    for e in entries:
        print(e)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "analyze"
    if cmd == "analyze":
        rgb, bg, panels, items, aligned = run_analysis(SHEET)
        print("sheet", rgb.shape, "bg", bg)
        for idx, rgba, m in items:
            print(idx, {k: m[k] for k in ("height", "soleY", "bodyCx", "supportCx")},
                  "shoes", [(round(b["x"]), b["bottom"], b["area"]) for b in m["shoeBlobs"]],
                  "mic", m["mic"] and (round(m["mic"]["x"]), round(m["mic"]["y"])))
        if len(panels) == 4:
            print("floor lines", [p.get("index") for p in panels])
    else:
        build()

#!/usr/bin/env python3
"""Rough 8-key walk preview for Feedback, built only from existing assets.

Source: the saved walk reference `feedback-walk-flow-test.mp4` (commit a2cd256,
artifacts/sound-clash/art-source/feedback/). Frames 153-195 are the best-closing
two-step stride in that clip; the 24->30 fps pulldown duplicates are dropped,
leaving 35 authored poses.

This script does NOT draw or regenerate anything. It:

  1. keys the studio backdrop to real alpha (border flood + enclosed light
     pockets, with the warm cream shirt and white stripes protected),
  2. strips the baked white matte scraps around the shoes and the cable,
  3. scales every pose by ONE uniform factor and pins the lowest sole pixel to
     one floor baseline, so body bounce stays visible while the floor is fixed,
  4. picks eight key poses out of the 35 (contact / down / pass / up, twice),
  5. writes the keys, a labelled pose sheet, an 8-key MP4 whose loop seam is
     measured rather than hidden, and a magenta audit of leftover white.

Run:
    FFMPEG=/path/to/ffmpeg python3 build_walk_keys.py --video ref/walkflow.mp4
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

ROOT = Path(__file__).resolve().parent
FIRST, LAST = 153, 195          # 1-based source frames, inclusive
SOURCE_FPS = 30
OUT_FPS = 24                    # authored cadence after pulldown removal
FIGURE_H = 520                  # uniform on-screen figure height for the sheet
FLOOR_Y = 560                   # sole baseline inside a panel (fixed for every key)
PANEL_W, PANEL_H = 340, 600
BG = (236, 231, 222)
FLOOR = (148, 138, 122)
INK = (34, 30, 28)
ACCENT = (150, 34, 44)

PHASES = ["contact", "down", "pass", "up"]
FOOT = ["near foot plants", "weight transfer", "legs pass", "push-off"]


# ---------------------------------------------------------------- small utils

def font(size, bold=True):
    for path in (
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def extract(video: Path) -> list[Path]:
    ff = os.environ.get("FFMPEG", "ffmpeg")
    tmp = Path(tempfile.mkdtemp(prefix="walkkeys-"))
    cmd = [ff, "-hide_banner", "-loglevel", "error", "-i", str(video),
           "-vf", "select='between(n\\,%d\\,%d)'" % (FIRST - 1, LAST - 1),
           "-vsync", "0", str(tmp / "s%03d.png")]
    subprocess.run(cmd, check=True)
    return sorted(tmp.glob("s*.png"))


def dedupe(paths: list[Path], threshold=0.25):
    """Drop 3:2 pulldown duplicates (<=0.02 mean diff) but keep real steps (>=0.86)."""
    kept, dropped = [], []
    for p in paths:
        rgb = np.asarray(Image.open(p).convert("RGB"), dtype=np.int16)
        if kept:
            if float(np.abs(rgb - kept[-1][1]).mean()) < threshold:
                dropped.append(p.name)
                continue
        kept.append((p, rgb))
    return kept, dropped


# ------------------------------------------------------------------- keying

def light_mask(rgb: np.ndarray) -> np.ndarray:
    """Bright, colourless pixels — studio wall, floor and the matte scraps.

    The wall is (239,239,239) but the scraps between the legs measure
    (237,233,232): a 5-unit spread and 5-unit warmth, which is only one unit
    away from the cream shirt (237,235,231). Colour alone cannot separate them,
    so the cutoff is deliberately generous here and the shirt is protected
    geometrically instead: it is sealed inside the jacket and sits above the
    waist (see enclosed_pockets).
    """
    lum = rgb.min(axis=2)
    spread = rgb.max(axis=2) - rgb.min(axis=2)
    warm = rgb[:, :, 0] - rgb[:, :, 2]
    cream = rgb[:, :, 1] - rgb[:, :, 2]        # G-B: wall 0-1, cream cloth 4+
    return (lum > 195) & (spread <= 8) & (warm <= 8) & (cream <= 2)


def reachable_from_border(mask: np.ndarray) -> np.ndarray:
    """Every connected light region that touches the canvas edge."""
    labels, count = ndimage.label(mask)
    if not count:
        return np.zeros_like(mask)
    edge = set(labels[0, :].tolist()) | set(labels[-1, :].tolist()) \
        | set(labels[:, 0].tolist()) | set(labels[:, -1].tolist())
    edge.discard(0)
    if not edge:
        return np.zeros_like(mask)
    return np.isin(labels, list(edge))


def enclosed_pockets(light: np.ndarray, rgb: np.ndarray, below_y: int) -> np.ndarray:
    """Light regions sealed off from the canvas edge (between the legs, behind
    the cable loop). Only regions that start below ``below_y`` are taken: the
    cream shirt hem lives above that line and is never touched. A white sleeve
    stripe is thin and diagonal, so it also fails the fill-ratio test.

    Uses PIL's C flood fill per region, so no scipy is required.
    """
    labels, count = ndimage.label(light)
    if not count:
        return np.zeros_like(light)
    out = np.zeros_like(light)
    for i, sl in enumerate(ndimage.find_objects(labels), start=1):
        if sl is None:
            continue
        region = labels[sl] == i
        area = int(region.sum())
        if area < 250:
            continue
        h = sl[0].stop - sl[0].start
        w = sl[1].stop - sl[1].start
        if not w or not h or h <= w:       # wedges are tall slivers; the shirt is wide
            continue
        if sl[0].start < below_y:          # never reach up into the jacket
            continue
        # Pure-white sleeve stripes (255) survive; the shaded matte between the
        # legs measures ~236, so brightness separates the two.
        if float(rgb[sl][region].min(axis=1).mean()) >= 250:
            continue
        out[sl] |= region
    return out


def key_frame(rgb_img: Image.Image) -> Image.Image:
    rgb = np.asarray(rgb_img.convert("RGB"), dtype=np.int16)
    light = light_mask(rgb)
    bg = reachable_from_border(light)
    body = ~bg
    ys, _ = np.where(body)
    y0, y1 = int(ys.min()), int(ys.max())
    pockets = enclosed_pockets(light, rgb, below_y=int(y0 + 0.40 * (y1 - y0)))
    alpha = np.where(bg | pockets, 0, 255).astype(np.uint8)

    # White matte scraps: near-white pixels that touch transparency are baked
    # edge junk, not art. Grow the hole two pixels so the 1-2 px rim goes too;
    # the dark ink contour around every limb stops the growth.
    edge_junk = (rgb.min(axis=2) > 236) & ((rgb.max(axis=2) - rgb.min(axis=2)) <= 12)
    for _ in range(3):
        clear = (alpha < 16)
        grown = np.zeros_like(clear)
        grown[1:, :] |= clear[:-1, :]
        grown[:-1, :] |= clear[1:, :]
        grown[:, 1:] |= clear[:, :-1]
        grown[:, :-1] |= clear[:, 1:]
        alpha[grown & edge_junk] = 0

    # Residual matte sealed between limbs: neutral (G-B <= 3) and shaded (below
    # the 255 of the sleeve stripes). The cream shirt measures G-B 4 and is out.
    neutral = ((rgb.min(axis=2) > 205) & (rgb.max(axis=2) - rgb.min(axis=2) <= 12)
               & ((rgb[:, :, 1] - rgb[:, :, 2]) <= 3) & (rgb.min(axis=2) < 252))
    sealed = neutral & ~reachable_from_border(neutral)
    lab_s, n_s = ndimage.label(sealed)
    if n_s:
        for i, sz in enumerate(ndimage.sum(sealed, lab_s, range(1, n_s + 1)), start=1):
            if sz >= 60:
                alpha[lab_s == i] = 0

    # Flecks: small bright chips sitting on the silhouette (matte scrap left
    # behind by the source clip). Anything away from the edge — mic highlight,
    # teeth, shirt — is out of range and safe.
    near_edge = ndimage.binary_dilation(alpha < 16, iterations=8)
    waist = np.zeros_like(alpha, dtype=bool)
    waist[int(y0 + 0.55 * (y1 - y0)):, :] = True      # stripes never reach here
    flecks = ((alpha > 40) & (rgb.min(axis=2) > 205)
              & (rgb.max(axis=2) - rgb.min(axis=2) <= 16)
              & ((rgb[:, :, 1] - rgb[:, :, 2]) <= 6) & near_edge & waist)
    lab_f, n_f = ndimage.label(flecks)
    if n_f:
        sizes = ndimage.sum(flecks, lab_f, range(1, n_f + 1))
        for i, sz in enumerate(sizes, start=1):
            if sz < 2500:
                alpha[lab_f == i] = 0

    # Alpha-only feather: softens the cut without thinning the ink outline.
    soft = Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.6))
    rgba = rgb_img.convert("RGB").copy()
    rgba.putalpha(soft)
    return rgba


def geometry(sprite: Image.Image):
    a = np.asarray(sprite)[:, :, 3]
    ys, xs = np.where(a > 8)
    return dict(x0=int(xs.min()), x1=int(xs.max()), y0=int(ys.min()),
                y1=int(ys.max()), h=int(ys.max() - ys.min() + 1),
                cx=float((xs.min() + xs.max()) / 2))


# ------------------------------------------------------------- key selection

def foot_gap(sprite: Image.Image) -> int:
    """Gap between the two feet in the lowest 10% of the figure.

    Wide at a contact pose (both shoes planted apart), zero at the passing pose
    (one shoe lifted, the other crossing the body). This is the gait-phase
    signal; it says nothing about quality, only where the feet are.
    """
    a = np.asarray(sprite)[:, :, 3]
    ys, _ = np.where(a > 8)
    if not len(ys):
        return 0
    band = int(ys.max() - 0.10 * (ys.max() - ys.min()))
    occ = (a[band:, :] > 8).any(axis=0)
    runs, start = [], None
    for x, on in enumerate(occ):
        if on and start is None:
            start = x
        elif not on and start is not None:
            runs.append((start, x - 1))
            start = None
    if start is not None:
        runs.append((start, len(occ) - 1))
    runs = [r for r in runs if r[1] - r[0] >= 6]
    if len(runs) >= 2:
        return int(runs[-1][0] - runs[0][1])
    return 0


def pick_keys(entries):
    """Two-step cycle: contact / down / pass / up, twice.

    Signals: foot gap (widest = contact, zero = passing) and head-top row (lowest
    = down, highest = up). Every key snaps to a pose that was actually drawn.
    Returns [(index, phase, foot-note, step)] sorted by the caller.
    """
    n = len(entries)
    gap = np.array([e["footGap"] for e in entries], dtype=float)
    head = np.array([e["headTopOnFloor"] for e in entries], dtype=float)
    half = n // 2
    out = []
    for step in range(2):
        lo = step * half
        hi = n if step == 1 else half
        contact = lo + int(np.argmax(gap[lo:hi]))
        after = list(range(contact + 1, hi)) or [min(n - 1, contact + 1)]
        passing = min(after, key=lambda i: (gap[i], i))
        down_win = list(range(contact, passing + 1)) or [contact]
        down = max(down_win, key=lambda i: (head[i], -i))
        up_win = list(range(passing, min(hi + 1, n))) or [passing]
        up = min(up_win, key=lambda i: (head[i], i))
        for cand in (down, up):
            pass  # uniqueness enforced below
        if down in (contact, passing):
            down = min(passing - 1, contact + 1) if passing - 1 > contact else contact
        if up in (contact, passing, down):
            up = min(n - 1, passing + 1)
        out += [(contact, "contact", "plant, stance widest", step + 1),
                (down, "down", "weight drops", step + 1),
                (passing, "pass", "legs pass, one shoe down", step + 1),
                (up, "up", "push-off, body highest", step + 1)]
    if len({i for i, *_ in out}) < 8:                 # last resort, never silent
        out = [(int(round(k * n / 8.0)) % n, PHASES[k % 4], FOOT[k % 4], (k // 4) + 1)
               for k in range(8)]
    return out


# ------------------------------------------------------------------ rendering

def panel(background):
    im = Image.new("RGBA", (PANEL_W, PANEL_H), background)
    d = ImageDraw.Draw(im)
    d.line([(16, FLOOR_Y), (PANEL_W - 16, FLOOR_Y)], fill=FLOOR + (255,), width=2)
    return im


def compose(sprite, cx, sole_y):
    canvas = panel(BG + (255,))
    left = int(round(cx - sprite.width / 2))
    top = int(round(sole_y - sprite.height))
    canvas.alpha_composite(sprite, (left, top))
    return canvas


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--video", default=str(ROOT / "ref" / "walkflow.mp4"))
    args = ap.parse_args()
    video = Path(args.video)
    if not video.exists():
        sys.exit("missing %s — restore it with:\n  git show a2cd256:artifacts/"
                 "sound-clash/art-source/feedback/feedback-walk-flow-test.mp4 "
                 "> %s" % (video, video))

    out_keys = ROOT / "keys"
    out_keys.mkdir(exist_ok=True)
    work = ROOT / "work"
    (work / "anim").mkdir(parents=True, exist_ok=True)

    paths = extract(video)
    kept, dropped = dedupe(paths)
    sprites = [key_frame(Image.open(p)) for p, _ in kept]
    geos = [geometry(s) for s in sprites]

    median_h = float(np.median([g["h"] for g in geos]))
    scale = FIGURE_H / median_h
    mean_cx = float(np.mean([g["cx"] for g in geos]))

    entries, placed = [], []
    for i, (sprite, g) in enumerate(zip(sprites, geos)):
        resized = sprite.resize((max(1, round(sprite.width * scale)),
                                 max(1, round(sprite.height * scale))), Image.LANCZOS)
        rg = geometry(resized)
        cx = PANEL_W / 2 + (g["cx"] - mean_cx) * scale
        entries.append(dict(
            index=i, srcFrame=FIRST + int(kept[i][0].stem[1:]) - 1,
            file="s%03d" % (int(kept[i][0].stem[1:])),
            footGap=foot_gap(sprite), headTop=int(g["y0"]),
            figureH=int(g["h"]), cx=round(cx, 1),
        ))
        placed.append((resized, rg, cx))

    # one floor baseline for every pose: sole pixel onto FLOOR_Y, never per-frame
    # height normalisation, so the body's own bounce survives
    for e, (resized, rg, cx) in zip(entries, placed):
        e["headTopOnFloor"] = int(round(FLOOR_Y - resized.height + rg["y0"]))

    raw = sorted(pick_keys(entries), key=lambda t: t[0])
    keys, canvases = [], []
    for k, (idx, phase, foot, step) in enumerate(raw, start=1):
        e = entries[idx]
        resized, rg, cx = placed[idx]
        cell = compose(resized, cx, FLOOR_Y)
        name = "key-%02d.png" % k
        cell.convert("RGB").save(out_keys / name)
        # engine-facing version: the pose alone, true alpha, no panel or floor
        trans = Image.new("RGBA", (PANEL_W, PANEL_H), (0, 0, 0, 0))
        trans.alpha_composite(resized, (int(round(cx - resized.width / 2)),
                                        int(round(FLOOR_Y - resized.height))))
        alpha_name = "key-%02d-alpha.png" % k
        trans.save(out_keys / alpha_name, optimize=True)
        keys.append(dict(key=k, index=idx, srcFrame=e["srcFrame"], phase=phase,
                         foot=foot, step=step, footGap=e["footGap"],
                         headTop=e["headTopOnFloor"], file=name, alphaFile=alpha_name))
        canvases.append(cell)

    # ---- timing: hold each key for the number of source frames it owns, so the
    # preview keeps the clip's cadence instead of inventing a beat
    holds = []
    for k in range(8):
        span = (keys[(k + 1) % 8]["index"] - keys[k]["index"]) % len(entries)
        holds.append(span if span else 4)

    # ---- MP4: four two-step cycles, fixed floor, caption per key
    frame_no = 0
    for cycle in range(4):
        for k, key in enumerate(keys):
            canvas = canvases[k].copy()
            d = ImageDraw.Draw(canvas)
            d.rectangle([10, 10, PANEL_W - 10, 52], fill=(28, 25, 23, 210))
            d.text((20, 18), "K%d  %s" % (key["key"], key["phase"]), font=font(18),
                   fill=(245, 240, 232, 255))
            d.text((PANEL_W - 96, 22), "f%d" % key["srcFrame"], font=font(12, False),
                   fill=(190, 182, 170, 255))
            d.text((20, PANEL_H - 26), "rough animatic - not approved",
                   font=font(11, False), fill=(120, 110, 100, 255))
            rgb = canvas.convert("RGB")
            for _ in range(holds[k]):
                rgb.save(work / "anim" / ("f%04d.png" % frame_no))
                frame_no += 1

    ff = os.environ.get("FFMPEG", "ffmpeg")
    mp4 = ROOT / "feedback-walk-keys-8.mp4"
    subprocess.run([ff, "-y", "-hide_banner", "-loglevel", "error",
                    "-framerate", str(OUT_FPS), "-i", str(work / "anim" / "f%04d.png"),
                    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18",
                    "-movflags", "+faststart", str(mp4)], check=True)

    # ---- honest seam: last rendered frame -> first rendered frame
    def compare(a, b):
        diff = np.abs(a - b)
        hot = diff.sum(axis=2) > 70
        return dict(changedPct=round(float(hot.mean() * 100), 2),
                    meanChanged=round(float(diff[hot].mean()), 1) if hot.any() else 0.0,
                    maxChannel=int(diff.max()))

    panels = [np.asarray(c.convert("RGB"), dtype=np.int16) for c in canvases]
    seam = compare(panels[-1], panels[0])
    steps = [compare(panels[i], panels[i + 1])["changedPct"] for i in range(7)]
    seam["medianStepPct"] = round(float(np.median(steps)), 2)
    seam["maxStepPct"] = round(float(np.max(steps)), 2)
    seam["minStepPct"] = round(float(np.min(steps)), 2)
    seam["seamVsMedian"] = round(seam["changedPct"] / max(1e-6, float(np.median(steps))), 2)
    overlay = panels[-1].astype(np.float32) * 0.45
    hot = np.abs(panels[0] - panels[-1]).sum(axis=2) > 70
    overlay[hot] = [220, 40, 60]
    Image.fromarray(np.clip(overlay, 0, 255).astype(np.uint8)).save(ROOT / "seam-diff.png")

    # ---- pose sheet
    cols, rows = 4, 2
    gutter, header, footer = 14, 150, 330
    sheet_w = cols * PANEL_W + (cols + 1) * gutter
    sheet_h = header + rows * PANEL_H + (rows + 1) * gutter + footer
    sheet = Image.new("RGB", (sheet_w, sheet_h), (24, 22, 21))
    d = ImageDraw.Draw(sheet)
    d.text((gutter + 6, 26), "FEEDBACK - ROUGH 8-KEY WALK PREVIEW", font=font(34),
           fill=(247, 241, 231))
    d.text((gutter + 8, 70),
           "Two-step cycle cut from the saved walk test, not a new animation. Keys held at their source timing.",
           font=font(15, False), fill=(200, 191, 179))
    d.text((gutter + 8, 94),
           "Source: feedback-walk-flow-test.mp4, frames %d-%d @%d fps, 35 unique poses, keys at %d fps, 1.458 s stride."
           % (FIRST, LAST, SOURCE_FPS, OUT_FPS), font=font(15, False), fill=(200, 191, 179))
    d.text((gutter + 8, 118),
           "Floor baseline y=%d fixed for every key. Uniform scale %.3f on a %d px figure." % (FLOOR_Y, scale, FIGURE_H),
           font=font(15, False), fill=(200, 191, 179))

    for k, key in enumerate(keys):
        col, row = k % cols, k // cols
        x = gutter + col * (PANEL_W + gutter)
        y = header + row * (PANEL_H + gutter)
        cell = Image.open(out_keys / key["file"]).convert("RGB")
        sheet.paste(cell, (x, y))
        d.rectangle([x, y, x + PANEL_W - 1, y + PANEL_H - 1], outline=(64, 58, 52))
        d.text((x + 12, y + PANEL_H + 4), "K%d  %s" % (key["key"], key["phase"]),
               font=font(16), fill=(247, 241, 231))
        d.text((x + 12, y + PANEL_H + 24), "step %d - %s - src f%d" % (key["step"], key["foot"], key["srcFrame"]),
               font=font(11, False), fill=(178, 169, 158))

    fy = header + rows * PANEL_H + (rows + 1) * gutter + 66
    d.text((gutter + 4, fy), "WHAT THIS PREVIEW DOES AND DOES NOT PROVE", font=font(17), fill=(247, 241, 231))
    lines = [
        ("REAL", "eight drawn poses, one fixed floor, consistent Clarks footprint, cable unbroken in every key"),
        ("REAL", "white matte scraps stripped from shoes and cable; alpha is a true cutout (audit in white-scrap-audit.png)"),
        ("GAP", "mic is in the RIGHT hand in every source frame; the ask is the LEFT hand - not mirrored, needs a redraw"),
        ("GAP", "mic arm is locked at the chest: no counter-swing, no chin lift, no heel lift, bounce is only what was drawn"),
        ("SEAM", "measured, not disguised: %.2f%% of the frame changes at the cut vs %.2f%% median step (%.2fx)"
         % (seam["changedPct"], seam["medianStepPct"], seam["seamVsMedian"])),
    ]
    for i, (tag, text) in enumerate(lines):
        y = fy + 28 + i * 22
        colour = (232, 92, 96) if tag == "GAP" else ((226, 190, 110) if tag == "SEAM" else (140, 205, 150))
        d.text((gutter + 4, y), tag, font=font(13), fill=colour)
        d.text((gutter + 70, y), text, font=font(13, False), fill=(214, 205, 192))

    sheet.save(ROOT / "walk-keys-8-sheet.png")

    # ---- white-scrap audit: every key on magenta, where leftovers scream
    audit = Image.new("RGBA", (PANEL_W * 4, PANEL_H * 2), (255, 0, 255, 255))
    for k, key in enumerate(keys):
        cell = Image.open(out_keys / key["alphaFile"]).convert("RGBA")
        audit.alpha_composite(cell, ((k % 4) * PANEL_W, (k // 4) * PANEL_H))
    audit.convert("RGB").save(ROOT / "white-scrap-audit.png")

    manifest = dict(
        source="feedback-walk-flow-test.mp4 (commit a2cd256), frames %d-%d" % (FIRST, LAST),
        sourceFps=SOURCE_FPS, outputFps=OUT_FPS, uniquePoses=len(entries),
        duplicatesDropped=len(dropped), medianFigureHeight=median_h,
        uniformScale=round(scale, 4), figureHeight=FIGURE_H, floorY=FLOOR_Y,
        strideSeconds=round(len(entries) / OUT_FPS, 3),
        holds=holds, seam=seam,
        keys=[{k: v for k, v in key.items() if k != "file"} for key in keys],
        note="taunt/action poses (01-06 imported swagger set) are NOT part of this cycle",
    )
    (ROOT / "keys.json").write_text(json.dumps(manifest, indent=2))
    print(json.dumps({k: v for k, v in manifest.items() if k not in ("keys",)}, indent=2))
    for key in keys:
        print("K%d  %-7s step %d  src f%d  foot gap %d px" %
              (key["key"], key["phase"], key["step"], key["srcFrame"], key["footGap"]))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Build the reviewable Feedback walk-cycle preview from the saved walk test.

Source frames 153-195 (0-based 152-194) of feedback-walk-flow-test.mp4 are the
best-closing TWO-STEP stride (both passing poses present) found by scoring
candidates after scale/floor alignment, i.e. on the composite that loops.
Frames are de-duped
(3:2 pulldown duplicates), uniformly scaled, and pinned to a floor baseline so
the body's vertical bounce survives. Nothing in the source video is modified.

Requires ffmpeg (set FFMPEG=/path/to/ffmpeg) and Pillow + numpy.
"""
import base64
import json
import os
import subprocess
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

FFMPEG = os.environ.get("FFMPEG", "ffmpeg")
ROOT = Path(__file__).resolve().parent
SRC = ROOT.parent / "feedback-walk-flow-test.mp4"
REF_IDLE = ROOT.parent / "feedback-idle-1600x1280.png"
REF_POSE = ROOT.parent / "imported-poses" / "01_point_swagger.png"

FIRST, LAST = 153, 195          # 1-based source frames, inclusive (one full stride)
SOURCE_FPS = 30
OUT_FPS = 24                    # authored cadence once pulldown duplicates go
FIGURE_H = 460                  # target figure height in px
PANEL_W, PANEL_H = 460, 620
FLOOR_Y = 566                   # sole baseline inside the panel
BG = (13, 15, 19)
FLOOR = (58, 65, 78)


def extract_frames(tmpdir):
    cmd = [FFMPEG, "-hide_banner", "-v", "error", "-i", str(SRC),
           "-vf", "select='between(n\\,%d\\,%d)'" % (FIRST - 1, LAST - 1),
           "-vsync", "0", os.path.join(tmpdir, "s%03d.png")]
    subprocess.run(cmd, check=True)
    return sorted(Path(tmpdir).glob("s*.png"))


def foreground_mask(rgb):
    a = np.asarray(rgb, dtype=np.int16)
    corners = np.concatenate([a[0:8, 0:8].reshape(-1, 3), a[0:8, -8:].reshape(-1, 3),
                              a[-8:, 0:8].reshape(-1, 3), a[-8:, -8:].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    return (np.abs(a - bg).sum(axis=2) > 40), bg


def key_background(rgb):
    """Key the flat neutral backdrop, including pockets enclosed by the figure.

    Removal requires BOTH near-backdrop colour and neutrality (R-B <= 5). Cream
    shirt, sleeve stripes and soles are warm (R-B 18-40), so enclosed light
    material survives while the grey showing between arm and torso does not.
    """
    arr = np.asarray(rgb.convert("RGB"), dtype=np.int16)
    corners = np.concatenate([arr[0:8, 0:8].reshape(-1, 3), arr[0:8, -8:].reshape(-1, 3),
                              arr[-8:, 0:8].reshape(-1, 3), arr[-8:, -8:].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    dist = np.abs(arr - bg).mean(axis=2)
    neutral = (arr[:, :, 0] - arr[:, :, 2]) <= 5
    bgmask = (dist < 14) & neutral

    alpha = np.where(bgmask, 0, 255).astype(np.uint8)
    # drop isolated compression specks, keep the figure and its cable
    labels, count = ndimage.label(alpha > 0)
    if count:
        sizes = ndimage.sum(np.ones_like(labels), labels, index=np.arange(1, count + 1))
        tiny = np.isin(labels, [i + 1 for i, s in enumerate(sizes) if s < 30])
        alpha[tiny] = 0
    alpha = np.asarray(Image.fromarray(alpha).filter(ImageFilter.MinFilter(3)))  # trim fringe
    rgba = rgb.convert("RGB").copy()
    rgba.putalpha(Image.fromarray(alpha))
    return rgba


def body_geometry(rgb, mask):
    ys, xs = np.where(mask)
    y0, y1 = int(ys.min()), int(ys.max())
    cols = mask.sum(axis=0)
    wide = np.where(cols > 0.25 * cols.max())[0]
    body_cx = float((wide.min() + wide.max()) / 2)
    return dict(x0=int(xs.min()), y0=y0, x1=int(xs.max()), y1=y1,
                h=y1 - y0 + 1, body_cx=body_cx)


def panel(canvas, sprite, cx, sole_y):
    """Paste a scaled sprite with its sole pixel on sole_y and body centre at cx."""
    left = int(round(cx - sprite.width / 2))
    top = int(round(sole_y - sprite.height))
    canvas.alpha_composite(sprite, (left, top))


def new_panel():
    """Dark panel with a soft centre lift so the dark cable and dreads stay legible."""
    ys, xs = np.mgrid[0:PANEL_H, 0:PANEL_W]
    cy, cx = FLOOR_Y - 210, PANEL_W / 2
    r = np.sqrt(((xs - cx) / (PANEL_W * 0.62)) ** 2 + ((ys - cy) / (PANEL_H * 0.62)) ** 2)
    t = np.clip(r, 0, 1)[..., None]
    inner = np.array([32, 38, 47], dtype=np.float32)
    outer = np.array(BG, dtype=np.float32)
    field = inner * (1 - t) + outer * t
    im = Image.fromarray(field.astype(np.uint8), mode="RGB").convert("RGBA")
    d = ImageDraw.Draw(im)
    d.line([(18, FLOOR_Y), (PANEL_W - 18, FLOOR_Y)], fill=FLOOR + (255,), width=2)
    d.line([(18, FLOOR_Y + 4), (PANEL_W - 18, FLOOR_Y + 4)], fill=(31, 35, 43, 255), width=1)
    return im


def unmatte(im):
    """Undo white matting in the approved art so it sits cleanly on a dark panel."""
    arr = np.asarray(im.convert("RGBA"), dtype=np.float32)
    a = arr[:, :, 3:4] / 255.0
    safe = np.where(a < 0.04, 1.0, a)
    rgb = (arr[:, :, :3] - 255.0 * (1.0 - safe)) / safe
    arr[:, :, :3] = np.clip(rgb, 0, 255)
    alpha = np.asarray(Image.fromarray(arr[:, :, 3].astype(np.uint8)).filter(ImageFilter.MinFilter(3)))
    arr[:, :, 3] = alpha
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGBA")


def ref_panel():
    """Approved references sit on a light card so the test stage reads as unapproved."""
    im = Image.new("RGBA", (PANEL_W, PANEL_H), (232, 228, 219, 255))
    d = ImageDraw.Draw(im)
    d.line([(18, FLOOR_Y), (PANEL_W - 18, FLOOR_Y)], fill=(150, 143, 130, 255), width=2)
    return im


def place_reference(path, out):
    im = Image.open(path).convert("RGBA")
    alpha = np.asarray(im)[:, :, 3]
    ys, xs = np.where(alpha > 8)
    y0, y1 = int(ys.min()), int(ys.max())
    scale = FIGURE_H / (y1 - y0 + 1)
    sprite = im.resize((max(1, int(round(im.width * scale))), max(1, int(round(im.height * scale)))),
                       Image.LANCZOS)
    # sole = bottom of the alpha bbox after scaling
    bottom = int(round(y1 * scale))
    canvas = ref_panel()
    left = int(round(PANEL_W / 2 - sprite.width / 2))
    canvas.alpha_composite(sprite, (left, FLOOR_Y - bottom))
    canvas.convert("RGB").save(out)
    return dict(file=out.name, figureHeight=FIGURE_H)


def main():
    frames_dir = ROOT / "frames"
    refs_dir = ROOT / "refs"
    frames_dir.mkdir(exist_ok=True)
    refs_dir.mkdir(exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        paths = extract_frames(tmp)
        raw = []
        for i, p in enumerate(paths):
            rgb = Image.open(p).convert("RGB")
            mask, _ = foreground_mask(rgb)
            g = body_geometry(rgb, mask)
            raw.append(dict(srcFrame=FIRST + i, path=p, rgb=rgb, mask=mask, geo=g))

        # Drop pulldown duplicates. The 24 -> 30 fps conversion repeats one frame in
        # five; compression noise means they are near-identical rather than identical
        # (mean |diff| ~0.02 on duplicates, >=0.86 for every real pose change).
        DUP_THRESHOLD = 0.25
        unique = []
        duplicate_sources = []
        for item in raw:
            if unique:
                delta = float(np.abs(np.asarray(item["rgb"], dtype=np.int16)
                                     - np.asarray(unique[-1]["rgb"], dtype=np.int16)).mean())
                if delta < DUP_THRESHOLD:
                    duplicate_sources.append(item["srcFrame"])
                    continue
            unique.append(item)

        heights = [u["geo"]["h"] for u in unique]
        median_h = float(np.median(heights))
        scale = FIGURE_H / median_h
        mean_cx = float(np.mean([u["geo"]["body_cx"] for u in unique]))

        entries = []
        for idx, u in enumerate(unique):
            keyed = key_background(u["rgb"])
            g = u["geo"]
            sprite = keyed.resize((max(1, int(round(keyed.width * scale))),
                                   max(1, int(round(keyed.height * scale)))), Image.LANCZOS)
            cx = PANEL_W / 2 + (g["body_cx"] - mean_cx) * scale
            canvas = new_panel()
            panel(canvas, sprite, cx, FLOOR_Y)
            name = "cycle-%02d.png" % idx
            canvas.convert("RGB").save(frames_dir / name)
            entries.append(dict(file=name, srcFrame=u["srcFrame"],
                                srcHeight=g["h"], scaledHeight=round(g["h"] * scale, 1),
                                soleY=FLOOR_Y, bodyCx=round(g["body_cx"], 1),
                                durationMs=round(1000 / OUT_FPS, 2)))

    place_reference(REF_IDLE, refs_dir / "approved-idle.png")
    place_reference(REF_POSE, refs_dir / "approved-pose-point-swagger.png")

    # honest seam measurement: last frame vs first frame, same canvas
    panels = [np.asarray(Image.open(frames_dir / e["file"]).convert("RGB"), dtype=np.int16) for e in entries]

    def compare(a, b):
        diff = np.abs(a - b)
        hot = diff.sum(axis=2) > 70
        return dict(meanAbsDiffAllPixels=round(float(diff.mean()), 2),
                    meanAbsDiffChangedPixels=round(float(diff[hot].mean()), 2) if hot.any() else 0.0,
                    changedPixelPct=round(float(hot.mean() * 100), 2),
                    maxChannelDiff=int(diff.max()))

    seam = compare(panels[-1], panels[0])
    # calibration: how big is an ordinary step between consecutive loop frames?
    steps = [compare(panels[i], panels[i + 1])["changedPixelPct"] for i in range(len(panels) - 1)]
    seam["medianConsecutiveChangedPct"] = round(float(np.median(steps)), 2)
    seam["maxConsecutiveChangedPct"] = round(float(np.max(steps)), 2)
    seam["seamVsMedianStepRatio"] = round(seam["changedPixelPct"] / max(1e-6, float(np.median(steps))), 2)
    # visual overlay: last frame dimmed, differences in red
    overlay = panels[-1].astype(np.float32) * 0.45
    hot = np.abs(panels[0] - panels[-1]).sum(axis=2) > 70
    overlay[hot] = [235, 70, 70]
    Image.fromarray(np.clip(overlay, 0, 255).astype(np.uint8)).save(ROOT / "seam-diff.png")

    manifest = dict(
        asset="feedback-walk-flow-test.mp4",
        sha256="7c644df616db66b7a3bd7747ddf27f65479e156cf2a869bd11598f74e8794011",
        sourceFrameRange=[FIRST, LAST],
        sourceFrames=len(raw),
        duplicatesRemoved=len(raw) - len(unique),
        duplicateSourceFrames=duplicate_sources,
        dedupeThresholdMeanAbsDiff=DUP_THRESHOLD,
        frames=len(unique),
        sourceFps=SOURCE_FPS,
        outputFps=OUT_FPS,
        strideSeconds=round(len(unique) / OUT_FPS, 3),
        medianSourceFigureHeight=median_h,
        uniformScale=round(scale, 4),
        seam=seam,
        entries=entries,
    )
    (ROOT / "frames-manifest.json").write_text(json.dumps(manifest, indent=2))
    (ROOT / "frames-data.js").write_text(
        "window.WALK = " + json.dumps({
            "frames": ["frames/" + e["file"] for e in entries],
            "sources": [e["srcFrame"] for e in entries],
            "fps": OUT_FPS,
            "strideSeconds": manifest["strideSeconds"],
            "sourceRange": [FIRST, LAST],
            "duplicatesRemoved": manifest["duplicatesRemoved"],
            "uniformScale": manifest["uniformScale"],
            "medianSourceFigureHeight": manifest["medianSourceFigureHeight"],
            "seam": seam,
            "duplicateFrames": manifest["duplicateSourceFrames"],
        }, indent=2) + ";\n")
    print(json.dumps({k: v for k, v in manifest.items() if k != "entries"}, indent=2))
    return manifest


if __name__ == "__main__":
    main()

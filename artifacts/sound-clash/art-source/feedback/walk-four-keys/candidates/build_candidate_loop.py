#!/usr/bin/env python3
"""Salvage, measure and align the PASS B redraw candidate (v1).

The committed file is truncated: it declares 1079x1457 but its IDAT stream is
short, so only the first rows decode. This script:

  * decodes what exists (Pillow with LOAD_TRUNCATED_IMAGES) and crops to the
    last complete row, so nothing invented is ever shown as art;
  * measures the microphone (a rigid prop, so its size is a scale ruler), the
    grip, the cord, the cream sleeve stripes and the art's own bounding box;
  * scales and places the readable part into a 460x620 key panel, aligned by
    the mic to the drawn keys' scale and by the head top and torso centre, then
    marks where the file stops.

It does not invent, splice, warp or redraw anything: rows that are not in the
file stay empty and the panel says so.

Usage:
    python3 build_candidate_loop.py
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFile
from scipy import ndimage

ImageFile.LOAD_TRUNCATED_IMAGES = True

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
CAND = HERE / "pass-b-redraw-v1.png"
CHECK = ROOT / "four-key-check.json"
SALVAGED = HERE / "pass-b-redraw-v1-salvaged.png"
ALIGNED = HERE / "pass-b-redraw-v1-aligned.png"
REPORT = HERE / "candidate-v1-measure.json"

PANEL = (460, 620)
FLOOR_Y = 566
PANEL_SCALE = 0.902          # the keys' own uniform scale, sheet -> panel
DRAWN_PASS_B_HEAD_TOP = 111  # panel y of PASS B's hat crown
PANEL_TORSO_X = 230.0


def metrics(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    a = rgb.astype(np.float32) / 255.0
    v = a.max(2)
    s = np.where(v > 0, (v - a.min(2)) / np.maximum(v, 1e-6), 0.0)
    return v, s


def blobs(mask: np.ndarray, min_area: int = 1) -> list[dict]:
    lab, n = ndimage.label(mask, structure=np.ones((3, 3)))
    out = []
    for i in range(1, n + 1):
        ys, xs = np.where(lab == i)
        if xs.size < min_area:
            continue
        out.append({"area": int(xs.size),
                    "box": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                    "cx": round(float(xs.mean()), 1), "cy": round(float(ys.mean()), 1)})
    return out


def decoded_rows(path: Path) -> tuple[int, int, int]:
    """(complete rows, declared height, declared width)."""
    raw = path.read_bytes()
    w = int.from_bytes(raw[16:20], "big")
    h = int.from_bytes(raw[20:24], "big")
    pos, idat = 8, b""
    while pos + 8 <= len(raw):
        ln = int.from_bytes(raw[pos:pos + 4], "big")
        typ = raw[pos + 4:pos + 8]
        body = raw[pos + 8:pos + 8 + ln]
        if typ == b"IDAT":
            idat += body
        if typ == b"IEND":
            break
        pos += 12 + ln
    import zlib
    d, out = zlib.decompressobj(), b""
    rowbytes = 1 + w * 4
    for i in range(0, len(idat), 4096):
        try:
            out += d.decompress(idat[i:i + 4096])
        except zlib.error:
            break
    return len(out) // rowbytes, h, w


def main() -> int:
    rows, declared_h, declared_w = decoded_rows(CAND)
    print(f"file declares {declared_w}x{declared_h}; {rows} rows decode "
          f"({rows / declared_h:.1%})")

    img = Image.open(CAND)
    img.load()
    readable = img.crop((0, 0, declared_w, rows)).convert("RGBA")
    readable.save(SALVAGED)
    print(f"wrote {SALVAGED.name}  {readable.width}x{readable.height}")

    rgb = np.asarray(readable.convert("RGB"))
    alpha = np.asarray(readable)[:, :, 3]
    v, s = metrics(rgb)
    content = alpha > 8

    ys, xs = np.where(content)
    art_box = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]

    metal = content & (s < 0.22) & (v > 0.22) & (v < 0.80)
    metal = ndimage.binary_opening(metal, np.ones((3, 3)))
    mic_blobs = sorted(blobs(metal, 150), key=lambda b: -b["area"])
    mic = mic_blobs[0] if mic_blobs else None

    drawn = json.loads(CHECK.read_text())
    drawn_mics = [k["micBox"] for k in drawn["keys"] if k.get("micBox")]
    # diagonal, not height: the candidate's mic is held at a different angle, so
    # its height changes while the prop does not. PASS A's mic is partly behind
    # the hand, so the median of the four is used rather than the mean.
    drawn_diag = float(np.median([
        float(np.hypot(b[2] - b[0] + 1, b[3] - b[1] + 1)) for b in drawn_mics
    ])) if drawn_mics else None
    drawn_mic_h = drawn_diag
    cand_mic_h = (float(np.hypot(mic["box"][2] - mic["box"][0] + 1,
                                mic["box"][3] - mic["box"][1] + 1)) if mic else None)

    plugs = []
    if mic:
        plugs = [b for b in blobs(metal, 15)
                 if b is not mic and b["box"][1] > mic["box"][3] + 25]

    cord = content & (s < 0.21) & (v > 0.22) & (v < 0.99)
    cord = ndimage.binary_opening(cord, np.ones((2, 2)))
    cord = ndimage.binary_closing(cord, np.ones((7, 7)))
    cord_blobs = sorted(blobs(cord, 200), key=lambda b: -b["area"])

    r, g, b_ = rgb[:, :, 0].astype(int), rgb[:, :, 1].astype(int), rgb[:, :, 2].astype(int)
    cream = content & (v > 0.70) & (s > 0.10) & (s < 0.45) & (r >= g) & (g >= b_)
    cream_blobs = sorted(blobs(cream, 150), key=lambda d: -d["area"])

    skin = content & (r > 110) & (r - b_ > 55) & (g > 40)
    skin_blobs = sorted(blobs(skin, 800), key=lambda d: -d["area"])

    # scale: the mic is the same prop in every drawing, so its size is a ruler
    panel_mic_h = drawn_mic_h * PANEL_SCALE if drawn_mic_h else None
    scale = (panel_mic_h / cand_mic_h) if (panel_mic_h and cand_mic_h) else None

    chest_band = content[int(rows * 0.55):int(rows * 0.85), :]
    cy, cx = np.where(chest_band)
    torso_x = float(np.median(cx)) if cx.size else float("nan")
    cand_chest_w = float(np.median(chest_band.sum(1))) if chest_band.any() else None

    drawn_panel = Image.open(ROOT / "poses" / "04_pass_b.png").convert("RGBA")
    d_al = np.asarray(drawn_panel)[:, :, 3] > 40
    d_ys = np.where(d_al.any(1))[0]
    d_lo = int(d_ys.min() + (d_ys.max() - d_ys.min()) * 0.55)
    d_hi = int(d_ys.min() + (d_ys.max() - d_ys.min()) * 0.75)
    drawn_chest_w = float(np.median(d_al[d_lo:d_hi].sum(1)))

    panel = Image.new("RGBA", PANEL, (0, 0, 0, 0))
    note_top = None
    if scale:
        small = readable.resize(
            (max(1, int(readable.width * scale)), max(1, int(readable.height * scale))),
            Image.LANCZOS,
        )
        # head top -> PASS B's head top; torso centre -> the panels' torso x
        ox = int(round(PANEL_TORSO_X - torso_x * scale))
        oy = int(round(DRAWN_PASS_B_HEAD_TOP - art_box[1] * scale))
        panel.alpha_composite(small, (ox, oy))
        note_top = oy + art_box[1]
    panel.save(ALIGNED)

    visible_bottom_in_panel = (note_top + (art_box[3] - art_box[1]) * scale) if scale else None

    width_ratio = (drawn_chest_w / cand_chest_w) if (cand_chest_w and scale) else None
    report = {
        "candidate": CAND.name,
        "truncated": {
            "declaredHeight": declared_h,
            "decodedRows": rows,
            "decodedFraction": round(rows / declared_h, 3),
            "missingRows": declared_h - rows,
            "hasIEND": False,
            "effect": "everything below the last decoded row is absent from the file, "
                      "not absent from the drawing",
        },
        "artBoxInReadablePart": art_box,
        "mic": mic,
        "micPickCount": len(mic_blobs),
        "micHeightPx": cand_mic_h,
        "drawnMicHeightSheetPx": round(drawn_mic_h, 1) if drawn_mic_h else None,
        "drawnMicHeightPanelPx": round(panel_mic_h, 1) if panel_mic_h else None,
        "scaleApplied": round(scale, 4) if scale else None,
        "scaleRuler": "microphone diagonal, median of the four drawn keys, times the panel scale",
        "proportions": {
            "candidateChestWidthPx": cand_chest_w,
            "drawnPassBChestWidthPx": drawn_chest_w,
            "impliedScaleFromChestWidth": round(width_ratio, 3) if width_ratio else None,
            "agreesWithMicScale": (abs(width_ratio - scale) / scale < 0.1) if (width_ratio and scale) else None,
            "caveat": "the candidate is drawn nearer a three-quarter view than the side-view "
                      "keys, so chest width is view-dependent and cannot grade proportion",
        },
        "plugsFound": [b["box"] for b in plugs[:3]],
        "cordSegments": [b["box"] for b in cord_blobs[:4]],
        "creamStripeBlobs": len(cream_blobs),
        "creamBoxes": [b["box"] for b in cream_blobs[:3]],
        "skinBlobs": [{"box": b["box"], "cx": b["cx"], "cy": b["cy"]} for b in skin_blobs[:3]],
        "panel": {
            "size": list(PANEL), "floorY": FLOOR_Y,
            "artTopInPanel": note_top,
            "artBottomInPanel": round(visible_bottom_in_panel) if visible_bottom_in_panel else None,
            "artReachesFloor": bool(visible_bottom_in_panel and visible_bottom_in_panel >= FLOOR_Y - 10),
        },
    }
    if mic and skin_blobs:
        hand = max(skin_blobs, key=lambda d: d["area"])
        report["handNearMic"] = {
            "handBox": hand["box"], "handCx": hand["cx"], "micCx": mic["cx"],
            "handOnScreenLeftOfMic": hand["cx"] < mic["cx"],
        }
    if mic and cream_blobs:
        report["stripesWithin160pxOfMicArm"] = sum(
            1 for c in cream_blobs if abs(c["cx"] - mic["cx"]) < 160
        )

    print(json.dumps(report, indent=2))
    REPORT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"wrote {REPORT.name}")
    print(f"wrote {ALIGNED.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

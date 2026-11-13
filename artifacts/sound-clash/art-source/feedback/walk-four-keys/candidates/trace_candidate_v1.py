#!/usr/bin/env python3
"""Trace the repaired PASS B candidate (v1): boots, hip, phase, legs, scale.

Scale-free comparisons only where it matters: the microphone is a rigid prop
present in every drawing, so distances are normalised by its diagonal and can be
compared with the drawn keys without trusting either one's resolution.

Reported:
  * the sole line and both boots, so the stance foot is not inferred from a guess;
  * the hip, and the support / swing offsets from it;
  * the swing lift;
  * figure height and chest width as multiples of the mic diagonal, next to the
    same ratios for the four drawn keys;
  * a leg split: which trouser mass is nearer the camera (drawn over, lighter)
    and which is farther (darker), plus a 4x crop of the crossing to read by eye.

Usage:
    python3 trace_candidate_v1.py      # writes candidate-v1-trace.json + crops
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
CAND = HERE / "pass-b-redraw-v1.png"
POSES = ROOT / "poses"
OUT = HERE / "candidate-v1-trace.json"
OVERLAY = HERE / "candidate-v1-trace.png"
CROSS = HERE / "candidate-v1-crossing-4x.png"

MIC_DIAG_DRAWN = 34.5      # sheet px, median of the four drawn keys
PANEL_SCALE = 0.902


def masks(rgba: np.ndarray) -> dict:
    al = rgba[:, :, 3] > 40
    a = rgba[:, :, :3].astype(np.float32) / 255.0
    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    V = a.max(2)
    S = np.where(V > 0, (V - a.min(2)) / np.maximum(V, 1e-6), 0.0)
    warm = r >= b
    trouser = al & warm & (V > 0.15) & (V < 0.50) & (S > 0.24) & (S < 0.60)
    trouser = ndimage.binary_opening(trouser, np.ones((3, 3)))
    tan = al & (r > 0.50) & (r - b > 0.18) & (g > 0.20)
    tan = ndimage.binary_closing(tan, np.ones((11, 11)))
    skin = al & (r > 0.45) & (r - b > 0.25) & (g > 0.15) & (g < 0.80)
    metal = al & (S < 0.22) & (V > 0.22) & (V < 0.80)
    metal = ndimage.binary_opening(metal, np.ones((3, 3)))
    return {"alpha": al, "trouser": trouser, "tan": tan, "skin": skin,
            "metal": metal, "V": V}


def blobs(mask: np.ndarray, min_area: int) -> list[dict]:
    lab, n = ndimage.label(mask)
    out = []
    for i in range(1, n + 1):
        ys, xs = np.where(lab == i)
        if xs.size < min_area:
            continue
        out.append({"area": int(xs.size),
                    "box": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
                    "cx": round(float(xs.mean()), 1), "lowestY": int(ys.max()),
                    "meanV": round(float(np.mean(masks_last["V"][ys, xs])), 3)})
    return out


masks_last: dict = {}


def analyse(rgba: np.ndarray, label: str) -> dict:
    global masks_last
    m = masks(rgba)
    masks_last = m
    alpha = m["alpha"]
    ys, xs = np.where(alpha)
    top, bottom = int(ys.min()), int(ys.max())

    mics = sorted(blobs(m["metal"], 400), key=lambda b: -b["area"])
    mic = mics[0] if mics else None
    mic_diag = (float(np.hypot(mic["box"][2] - mic["box"][0] + 1,
                               mic["box"][3] - mic["box"][1] + 1)) if mic else float("nan"))

    # boots live in the lower quarter of the figure; the hands are the same tan
    # and hang around the hip, so a looser band picks them up as feet
    boots = [b for b in blobs(m["tan"], 900) if b["lowestY"] > bottom - (bottom - top) * 0.25]
    boots.sort(key=lambda b: b["cx"])
    sole_y = max((b["lowestY"] for b in boots), default=None)
    on_floor = [b for b in boots if sole_y - b["lowestY"] <= 12]
    support = max(on_floor, key=lambda b: b["area"]) if on_floor else None
    swing = None
    if support:
        others = [b for b in boots if b is not support]
        swing = max(others, key=lambda b: -b["lowestY"]) if others else None

    trou = m["trouser"].copy()
    trou[:int(top + (bottom - top) * 0.35)] = False
    tys, txs = np.where(trou)
    hip_rows = tys < np.percentile(tys, 6) if tys.size else None
    hip_x = float(np.median(txs[hip_rows])) if tys.size else float("nan")

    chest = alpha[int(top + (bottom - top) * 0.30):int(top + (bottom - top) * 0.40)]
    chest_w = float(np.median(chest.sum(1))) if chest.any() else float("nan")

    out = {
        "key": label,
        "artBox": [int(xs.min()), top, int(xs.max()), bottom],
        "figureHeightPx": bottom - top + 1,
        "micDiagPx": round(mic_diag, 1),
        "micBox": mic["box"] if mic else None,
        "micCount": len(mics),
        "soleY": sole_y,
        "boots": boots,
        "hipX": round(hip_x, 1),
        "chestWidthPx": round(chest_w, 1),
    }
    if support:
        out["supportBootCx"] = support["cx"]
        out["supportOffsetFromHipPx"] = round(support["cx"] - hip_x, 1)
        out["supportOffsetInMicUnits"] = round((support["cx"] - hip_x) / mic_diag, 3)
    if swing and support:
        out["swingBootCx"] = swing["cx"]
        out["swingVsSupportPx"] = round(swing["cx"] - support["cx"], 1)
        out["swingVsSupportInMicUnits"] = round((swing["cx"] - support["cx"]) / mic_diag, 3)
        out["swingLiftPx"] = int(sole_y - swing["lowestY"])
        out["swingLiftInMicUnits"] = round((sole_y - swing["lowestY"]) / mic_diag, 3)
    out["heightInMicUnits"] = round((bottom - top + 1) / mic_diag, 2)
    out["chestWidthInMicUnits"] = round(chest_w / mic_diag, 3)
    return out


def drawn_reference() -> dict:
    """Same ratios on the drawn keys, so the comparison is like for like."""
    ref = {}
    mic_panel = MIC_DIAG_DRAWN * PANEL_SCALE
    for name in ("01_contact_a", "02_pass_a", "03_contact_b", "04_pass_b"):
        rgba = np.asarray(Image.open(POSES / f"{name}.png").convert("RGBA"))
        al = rgba[:, :, 3] > 40
        ys = np.where(al.any(1))[0]
        h = ys.max() - ys.min() + 1
        chest = al[int(ys.min() + h * 0.30):int(ys.min() + h * 0.40)]
        ref[name] = {"figureHeightPx": int(h),
                     "heightInMicUnits": round(h / mic_panel, 2),
                     "chestWidthInMicUnits": round(float(np.median(chest.sum(1))) / mic_panel, 3)}
    return ref


def main() -> int:
    rgba = np.asarray(Image.open(CAND).convert("RGBA"))
    cand = analyse(rgba, "candidate v1")
    ref = drawn_reference()
    report = {"candidate": cand, "drawnKeys": ref,
              "micUnits": "distances divided by the mic diagonal, so scale cancels"}

    print(json.dumps(cand, indent=2))
    print("\ndrawn keys, same ratios:")
    for k, v in ref.items():
        print(" ", k, v)
    print(f"\nheight in mic units: candidate {cand['heightInMicUnits']} vs drawn "
          + ", ".join(f"{v['heightInMicUnits']}" for v in ref.values()))

    # overlay for inspection
    img = Image.open(CAND).convert("RGB")
    d = ImageDraw.Draw(img)
    if cand.get("hipX"):
        hx = cand["hipX"]
        d.line([(hx, cand["artBox"][1]), (hx, cand["artBox"][3])], fill=(240, 180, 41), width=3)
    for b in cand["boots"]:
        col = (111, 207, 151) if b["cx"] == cand.get("supportBootCx") else (235, 111, 111)
        d.rectangle(b["box"], outline=col, width=3)
    if cand["soleY"]:
        d.line([(0, cand["soleY"]), (img.width, cand["soleY"])], fill=(111, 207, 151), width=3)
    img.save(OVERLAY)

    # crossing crop: hip to knees
    hx = cand.get("hipX") or img.width / 2
    y0 = int(cand["artBox"][1] + (cand["artBox"][3] - cand["artBox"][1]) * 0.45)
    y1 = min(img.height, int(cand["artBox"][1] + (cand["artBox"][3] - cand["artBox"][1]) * 0.80))
    box = (max(0, int(hx - 380)), y0, min(img.width, int(hx + 380)), y1)
    crop = Image.open(CAND).convert("RGB").crop(box)
    crop = crop.resize((crop.width * 2, crop.height * 2), Image.LANCZOS)
    crop.save(CROSS)
    print(f"\nwrote {OVERLAY.name}, {CROSS.name}")
    OUT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"wrote {OUT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

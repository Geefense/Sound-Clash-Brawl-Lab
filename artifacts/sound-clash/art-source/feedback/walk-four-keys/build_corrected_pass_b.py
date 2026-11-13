#!/usr/bin/env python3
"""Pose PASS B at PASS A's point in the step, for side-by-side review.

Why not a warp: PASS B's feet are 41 px apart and PASS A's are 80.7 px apart, so
matching A's phase means pulling the boots ~40 px further apart than the sheet
draws them. Warping one diffuse field to do that folds the legs into each other
(tried: the legs collapse into a single column). The stride genuinely differs,
which is why the redraw is an art job.

So this is a splice instead, and it is a review proxy, not finished art:

  * below the waistband the trousers come from PASS A (mid-stance);
  * above it, PASS B is untouched - jacket, mic in the right hand, and the
    free-arm swagger are exactly as drawn;
  * PASS A's own free hand would ride along under the seam, so it is removed
    only where B has nothing to put back; B's hand and forearm are pasted
    exactly as drawn on top.

Leg identity is still PASS B's slot, i.e. the near leg is PASS A's. Only a
redraw can change that.

Writes poses/04_pass_b_corrected.png and corrected-pass-b.json.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = Path(__file__).resolve().parent
POSES = HERE / "poses"
OUT = POSES / "04_pass_b_corrected.png"
REPORT = HERE / "corrected-pass-b.json"

FLOOR_Y = 566
FEATHER_ROWS = 4


def skin_mask(rgba: np.ndarray) -> np.ndarray:
    a = rgba[:, :, :3].astype(np.float32) / 255.0
    r, g, b_ = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    return (rgba[:, :, 3] > 40) & (r > 0.45) & (r - b_ > 0.25) & (g > 0.18) & (g < 0.78)


def waistband_bottom(rgba: np.ndarray) -> int:
    """Lowest row of the cream waistband - the natural splice line."""
    a = rgba[:, :, :3].astype(np.float32) / 255.0
    al = rgba[:, :, 3] > 40
    r, g, b_ = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    V = a.max(2)
    S = np.where(V > 0, (V - a.min(2)) / np.maximum(V, 1e-6), 0.0)
    cream = al & (V > 0.70) & (S > 0.10) & (S < 0.45) & (r >= g) & (g >= b_)
    window = np.zeros_like(cream)
    window[275:350, 130:340] = True   # torso only: the sleeve stripes share this cream
    cream &= window
    cream = ndimage.binary_closing(cream, np.ones((5, 5)))
    lab, n = ndimage.label(cream)
    if n == 0:
        return 326
    sizes = ndimage.sum(cream, lab, range(1, n + 1))
    band = lab == (int(np.argmax(sizes)) + 1)
    return int(np.where(band)[0].max())


def hip_and_boots(rgba: np.ndarray) -> dict:
    a = rgba[:, :, :3].astype(np.float32) / 255.0
    al = rgba[:, :, 3] > 40
    V = a.max(2)
    S = np.where(V > 0, (V - a.min(2)) / np.maximum(V, 1e-6), 0.0)
    warm = a[:, :, 0] >= a[:, :, 2]
    trou = al & warm & (V > 0.17) & (V < 0.46) & (S > 0.28) & (S < 0.55)
    trou[:326, :] = False
    trou = ndimage.binary_opening(trou, np.ones((2, 2)))
    ys, xs = np.where(trou)
    hip_x = float(np.median(xs[ys < np.percentile(ys, 8)])) if len(xs) else float("nan")

    r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
    tan = al & (r > 0.52) & (r - b > 0.20) & (g > 0.22)
    tan = ndimage.binary_closing(tan, np.ones((9, 9)))
    lab, n = ndimage.label(tan)
    boots = []
    for i in range(1, n + 1):
        yy, xx = np.where(lab == i)
        if xx.size < 900 or yy.max() < FLOOR_Y - 130:
            continue
        boots.append({"cx": round(float(xx.mean()), 1), "lowestY": int(yy.max())})
    boots.sort(key=lambda d: d["cx"])
    on_floor = [b_ for b_ in boots if FLOOR_Y - b_["lowestY"] <= 10]
    support = max(on_floor, key=lambda d: d["cx"]) if on_floor else None
    swing = None
    if support:
        others = [b_ for b_ in boots if b_ is not support]
        swing = others[0] if others else None
    return {"hipX": round(hip_x, 1), "boots": boots, "support": support, "swing": swing}


def main() -> int:
    a = np.asarray(Image.open(POSES / "02_pass_a.png").convert("RGBA"))
    b = np.asarray(Image.open(POSES / "04_pass_b.png").convert("RGBA"))
    ma, mb = hip_and_boots(a), hip_and_boots(b)
    print("PASS A ", ma)
    print("PASS B ", mb)

    dx = mb["hipX"] - ma["hipX"]
    seam_a = waistband_bottom(a)
    seam_b = waistband_bottom(b)
    print(f"waistband bottom: A y={seam_a}, B y={seam_b}; hip dx {dx:+.1f}")

    legs = np.asarray(
        Image.fromarray(a).transform(
            a.shape[1::-1], Image.AFFINE,
            (1, 0, -dx, 0, 1, -(seam_b - seam_a)), resample=Image.BICUBIC,
        )
    )

    out = b.copy()
    rows = np.arange(out.shape[0])
    below = rows >= seam_b + FEATHER_ROWS
    out[below] = legs[below]
    for i in range(FEATHER_ROWS):
        r = seam_b + i
        w = (i + 1) / (FEATHER_ROWS + 1)
        out[r] = (b[r].astype(np.float32) * (1 - w) + legs[r].astype(np.float32) * w).astype(np.uint8)

    # A's free hand rides under the seam and overlaps its own thigh, so simply
    # erasing it punches a hole. Take the hand's whole silhouette, fill it from
    # the nearest surrounding trouser pixel, then lay B's own hand back on top.
    hand_zone = np.zeros(out.shape[:2], bool)
    hand_zone[seam_b:470, 250:460] = True
    skin_a = skin_mask(legs)
    lab, n = ndimage.label(skin_a & hand_zone)
    hand = np.zeros_like(hand_zone)
    for i in range(1, n + 1):
        blob = lab == i
        if blob.sum() > 3000:
            hand |= blob
    hand = ndimage.binary_dilation(hand, np.ones((9, 9)))
    hand = ndimage.binary_fill_holes(hand) & hand_zone
    if hand.any():
        _, (iy, ix) = ndimage.distance_transform_edt(hand, return_indices=True)
        filled = out.copy()
        for c in range(4):
            filled[:, :, c] = out[iy, ix, c]
        out[hand] = filled[hand]
    out[hand_zone & (b[:, :, 3] > 0)] = b[hand_zone & (b[:, :, 3] > 0)]

    img = Image.fromarray(out, "RGBA")
    img.save(OUT)
    print(f"wrote {OUT.name}")

    m = hip_and_boots(out)
    report = {
        "file": "poses/04_pass_b_corrected.png",
        "method": "waistband splice: PASS B above the join, PASS A's trousers below",
        "notDone": "leg identity is PASS A's, so which leg is near still needs a redraw",
        "hip": {"x": m["hipX"]},
        "measured": m,
    }
    if m["support"]:
        report["supportOffsetFromHip"] = round(m["support"]["cx"] - m["hipX"], 1)
    if m["swing"] and m["support"]:
        report["swingBehindSupport"] = round(m["support"]["cx"] - m["swing"]["cx"], 1)
        report["swingLiftPx"] = int(FLOOR_Y - m["swing"]["lowestY"])

    def support_of(name: str) -> float | None:
        mm = hip_and_boots(np.asarray(Image.open(POSES / name).convert("RGBA")))
        return mm["support"]["cx"] if mm["support"] else None

    a_contact = support_of("01_contact_a.png")
    b_contact = support_of("03_contact_b.png")
    if a_contact is not None and b_contact is not None and ma["support"] and m["support"]:
        first = round(ma["support"]["cx"] - a_contact, 1)
        second = round(m["support"]["cx"] - b_contact, 1)
        report["travel"] = {
            "CONTACT A -> PASS A": first,
            "CONTACT B -> corrected PASS B": second,
            "original mismatch": round(abs(abs(first) - abs(mb["support"]["cx"] - b_contact)), 1),
            "remaining difference": round(abs(abs(first) - abs(second)), 1),
        }
    print(json.dumps({k: v for k, v in report.items() if k != "measured"}, indent=2))
    print("note: these distances are a timing diagnostic. How far a planted foot "
          "appears to slide depends on cadence and forward speed.")
    REPORT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"wrote {REPORT.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

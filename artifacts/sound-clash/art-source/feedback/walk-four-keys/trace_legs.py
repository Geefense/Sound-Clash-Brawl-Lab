#!/usr/bin/env python3
"""Trace each leg from hip to knee to boot and test whether A and B alternate.

Reads the aligned poses from poses/ and writes:

  leg-trace.json    the traced joints, the occlusion gaps, the travel numbers
  leg-trace.png     the same trace drawn over the four keys

Method

  * The trousers are separated from the boots (tan) and the jacket (much more
    saturated) by colour, and the near-black outline is excluded so the two legs
    stay separated by a thin gap where they cross.
  * Each row is split into runs. A row with two runs gives a point for each leg;
    a row with one run means either the legs have merged or one leg is hidden
    behind the other, so that leg gets a gap there.
  * The leg with the *shorter* gap across the crossing is the one drawn in
    front - the near leg. The other is the far leg, and occlusion (not colour)
    is what identifies it.
  * The knee is the point of strongest change of direction along the leg's
    centreline between hip and ankle.

On travel: a planted foot moving backwards relative to the body is forward
travel, not sliding. What is reported here is the foot's offset from the hip,
key by key, and the change between keys - that change is how far the body has to
move in that interval. Sliding is only present if the two halves disagree, or if
a foot moves while it is supposed to be planted.

Usage:
    python3 trace_legs.py

Requires Pillow, numpy and scipy.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
POSES = HERE / "poses"
RESULTS = HERE / "leg-trace.json"
OVERLAY = HERE / "leg-trace.png"

KEYS = [
    ("01 CONTACT A", "01_contact_a"),
    ("02 PASS A", "02_pass_a"),
    ("03 CONTACT B", "03_contact_b"),
    ("04 PASS B", "04_pass_b"),
]
W, H, FLOOR_Y = 460, 620, 566


def runs_of(row: np.ndarray) -> list[tuple[int, int]]:
    edges = np.flatnonzero(np.diff(np.r_[0, row.astype(np.int8), 0]))
    return [(int(a), int(b)) for a, b in zip(edges[::2], edges[1::2])]


def leg_mask(rgba: np.ndarray, y_from: int) -> np.ndarray:
    a = rgba[:, :, :3].astype(np.float32) / 255.0
    al = rgba[:, :, 3] > 40
    V = a.max(2)
    S = np.where(V > 0, (V - a.min(2)) / np.maximum(V, 1e-6), 0.0)
    warm = a[:, :, 0] >= a[:, :, 2]
    mask = al & warm & (V > 0.17) & (V < 0.46) & (S > 0.28) & (S < 0.55)
    mask[:y_from, :] = False
    mask = ndimage.binary_opening(mask, np.ones((2, 2)))
    mask = ndimage.binary_closing(mask, np.ones((3, 3)))
    lab, n = ndimage.label(mask)
    if n:
        big = max(range(1, n + 1), key=lambda i: (lab == i).sum())
        mask = lab == big
    return mask


def trace(mask: np.ndarray) -> dict:
    ys, xs = np.where(mask)
    if not len(ys):
        return {}
    top, bottom = int(ys.min()), int(ys.max())
    rows = range(top, bottom + 1)

    left_pts, right_pts = [], []
    merged_rows = 0
    single_rows = 0
    last = {"L": None, "R": None}

    for y in rows:
        rr = runs_of(mask[y])
        rr = [(a, b) for a, b in rr if b - a >= 6]
        if len(rr) >= 2:
            rr.sort(key=lambda t: t[0] - t[1])
            rr = sorted(rr, key=lambda t: t[0])
            left_pts.append((y, (rr[0][0] + rr[0][1]) / 2))
            right_pts.append((y, (rr[-1][0] + rr[-1][1]) / 2))
            last["L"], last["R"] = left_pts[-1][1], right_pts[-1][1]
        elif len(rr) == 1:
            a, b = rr[0]
            width = b - a
            cx = (a + b) / 2
            single_rows += 1
            # wide single run = the two legs merged at the crossing
            if width > 95:
                merged_rows += 1
                continue
            side = "L" if (last["L"] is not None and
                           abs(cx - last["L"]) < abs(cx - (last["R"] or 1e9))) else "R"
            (left_pts if side == "L" else right_pts).append((y, cx))
            last[side] = cx

    hip_y = top
    hip_x = float(np.median([p[1] for p in left_pts + right_pts if p[0] < top + 12])) \
        if left_pts + right_pts else None

    def summarise(pts: list[tuple[int, float]], name: str) -> dict:
        if not pts:
            return {"leg": name, "points": 0}
        ys_ = np.array([p[0] for p in pts])
        xs_ = np.array([p[1] for p in pts])
        gaps = np.diff(ys_)
        k = 0
        if len(pts) > 25:
            k = int(np.argmax(np.abs(np.gradient(np.gradient(xs_, ys_), ys_))))
        knee_y, knee_x = int(ys_[k]), float(xs_[k])
        return {
            "leg": name,
            "points": int(len(pts)),
            "hip": [round(hip_x, 1), hip_y],
            "knee": [round(knee_x, 1), knee_y],
            "ankle": [round(float(xs_[-1]), 1), int(ys_[-1])],
            "largestGapRows": int(gaps.max()) if len(gaps) else 0,
            "firstRow": int(ys_[0]),
            "lastRow": int(ys_[-1]),
        }

    return {
        "hipY": hip_y,
        "hipX": round(hip_x, 1) if hip_x is not None else None,
        "left": summarise(left_pts, "L (screen-left)"),
        "right": summarise(right_pts, "R (screen-right)"),
        "mergedRows": merged_rows,
        "singleRunRows": single_rows,
    }


def font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def main() -> int:
    report = {"keys": [], "note": "travel measured relative to the hip"}
    traces = []
    for label, slug in KEYS:
        rgba = np.asarray(Image.open(POSES / f"{slug}.png"))
        alpha = rgba[:, :, 3] > 40
        ys, xs = np.where(alpha)
        top = int(ys.min())
        height = int(ys.max() - ys.min() + 1)
        mask = leg_mask(rgba, int(top + 0.36 * height))
        t = trace(mask)
        traces.append((label, rgba, mask, t))

        # boots (tan) for the ankle/boot link and the support foot
        a = rgba[:, :, :3].astype(np.float32) / 255.0
        r, g, b = a[:, :, 0], a[:, :, 1], a[:, :, 2]
        tan = (rgba[:, :, 3] > 40) & (r > 0.52) & (r - b > 0.20) & (g > 0.22)
        tan = ndimage.binary_closing(tan, np.ones((9, 9)))
        lab, n = ndimage.label(tan)
        boots = []
        for i in range(1, n + 1):
            yy, xx = np.where(lab == i)
            if xx.size < 900 or yy.max() < FLOOR_Y - 130:
                continue
            boots.append({"cx": round(float(xx.mean()), 1), "lowestY": int(yy.max()),
                          "onFloor": bool(FLOOR_Y - yy.max() <= 10),
                          "width": int(xx.max() - xx.min() + 1)})
        boots.sort(key=lambda d: d["cx"])
        on_floor = [bt for bt in boots if bt["onFloor"]]
        # With both feet down (contact keys) the foot that carries the body into
        # the next key is the leading one, so take the front-most planted boot.
        support_cx = max(on_floor, key=lambda b: b["cx"])["cx"] if on_floor else None

        entry = {
            "key": label,
            "hipX": t.get("hipX"),
            "left": t.get("left"),
            "right": t.get("right"),
            "mergedRows": t.get("mergedRows"),
            "boots": boots,
            "supportBootCx": support_cx,
            "supportOffsetFromHip": round(support_cx - t["hipX"], 1)
            if support_cx is not None and t.get("hipX") is not None else None,
        }
        report["keys"].append(entry)

        lk, rk = t.get("left", {}), t.get("right", {})
        print(f"\n{label}")
        print(f"  hip x {t.get('hipX')} at y {t.get('hipY')}")
        for leg in (lk, rk):
            if leg.get("points"):
                print(f"  {leg['leg']}: hip {leg['hip']} -> knee {leg['knee']} -> "
                      f"ankle {leg['ankle']}   gap {leg['largestGapRows']} rows")
        print(f"  boots {[(bt['cx'], bt['lowestY'], bt['onFloor']) for bt in boots]}")
        print(f"  support offset from hip {entry['supportOffsetFromHip']} px")

    # ---- alternation -------------------------------------------------------
    print("\nalternation test (near leg = the one with the shorter occlusion gap):")
    verdicts = []
    for label, _, _, t in traces:
        lk, rk = t.get("left", {}), t.get("right", {})
        if not (lk.get("points") and rk.get("points")):
            continue
        near = "L" if lk["largestGapRows"] <= rk["largestGapRows"] else "R"
        forward = "R" if rk["ankle"][0] > lk["ankle"][0] else "L"
        verdicts.append({"key": label, "near": near, "forward": forward,
                         "gaps": {"L": lk["largestGapRows"], "R": rk["largestGapRows"]}})
        print(f"  {label:14s} near leg {near}  forward leg {forward}  "
              f"gaps L {lk['largestGapRows']} / R {rk['largestGapRows']} rows")

    report["alternation"] = verdicts

    # Only keys where one leg is clearly more occluded than the other can say
    # which leg is near. A tie means the mask could not separate the legs there
    # (the far leg can be drawn almost black), and that key is excluded rather
    # than guessed at.
    usable = [v for v in verdicts if abs(v["gaps"]["L"] - v["gaps"]["R"]) > 8]
    report["resolvableKeys"] = [v["key"] for v in usable]
    report["unresolvableKeys"] = [v["key"] for v in verdicts if v not in usable]
    print(f"\n  resolvable by the mask: {[v['key'] for v in usable] or 'none'}")
    if report["unresolvableKeys"]:
        print(f"  not resolvable (legs equally occluded / far leg in deep shadow): "
              f"{report['unresolvableKeys']}")

    a_half = [v for v in usable if v["key"].startswith("0") and v["key"][1] in "12"]
    b_half = [v for v in usable if v["key"][1] in "34"]
    if a_half and b_half:
        near_a = {v["near"] for v in a_half}
        near_b = {v["near"] for v in b_half}
        fwd = {v["forward"] for v in usable}
        swapped = near_a != near_b and len(near_a) == 1 and len(near_b) == 1
        verdict = (
            f"near leg in the A half {sorted(near_a)}, in the B half {sorted(near_b)}; "
            f"the leading leg is {sorted(fwd)} throughout. "
            + ("The near leg swaps sides while the leading side stays the same, i.e. the "
               "near leg is forward in one contact key and trailing in the other: the legs "
               "DO alternate."
               if swapped else
               "The near leg does not swap sides, so both contact keys draw the same leg "
               "forward: the legs do NOT alternate.")
        )
        report["alternationVerdict"] = verdict
        print(f"  {verdict}")

    # ---- travel ------------------------------------------------------------
    print("\nsupport foot, body-relative (a planted foot moving back through the frame "
          "is forward travel, not sliding):")
    steps = []
    for i in (0, 2):
        k1, k2 = report["keys"][i], report["keys"][i + 1]
        if k1["supportBootCx"] is None or k2["supportBootCx"] is None:
            continue
        d = round(k2["supportBootCx"] - k1["supportBootCx"], 1)
        steps.append({"interval": f"{k1['key']} -> {k2['key']}", "px": d})
        print(f"  {k1['key']} -> {k2['key']}: {d:+.1f} px  "
              f"(boot x {k1['supportBootCx']} -> {k2['supportBootCx']})")
    report["stanceTravel"] = steps
    if len(steps) == 2:
        a, b = abs(steps[0]["px"]), abs(steps[1]["px"])
        report["travelMismatchPx"] = round(abs(a - b), 1)
        report["travelMismatchPct"] = round(100 * abs(a - b) / max(a, b), 1)
        print(f"  the two halves differ by {abs(a - b):.0f} px "
              f"({100 * abs(a - b) / max(a, b):.0f}%): at one root-motion speed the longer "
              f"half would slide by that much")

    # ---- overlay -----------------------------------------------------------
    pad = 12
    out = Image.new("RGB", (W * 2 + pad * 3, H * 2 + pad * 3 + 30), (16, 14, 20))
    draw = ImageDraw.Draw(out)
    f = font(16)
    for i, (label, rgba, mask, t) in enumerate(traces):
        tile = Image.new("RGB", (W, H), (20, 17, 26))
        tile.paste(Image.fromarray(rgba), (0, 0), Image.fromarray(rgba))
        td = ImageDraw.Draw(tile)
        td.line([(0, FLOOR_Y), (W, FLOOR_Y)], fill=(96, 88, 108))
        for leg, col in ((t.get("left", {}), (110, 200, 255)), (t.get("right", {}), (255, 170, 90))):
            if not leg.get("points"):
                continue
            td.line([tuple(leg["hip"]), tuple(leg["knee"]), tuple(leg["ankle"])],
                    fill=col, width=2)
            for pt, rad in ((leg["hip"], 4), (leg["knee"], 5), (leg["ankle"], 4)):
                td.ellipse([pt[0] - rad, pt[1] - rad, pt[0] + rad, pt[1] + rad], outline=col, width=2)
            td.text((leg["knee"][0] + 7, leg["knee"][1] - 6), "knee", fill=col, font=f)
        x = pad + (i % 2) * (W + pad)
        y = pad + (i // 2) * (H + pad + 18)
        out.paste(tile, (x, y))
        draw.text((x + 4, y + H + 2), label, fill=(230, 225, 238), font=f)
    out.save(OVERLAY)
    print(f"\nwrote leg-trace.png  {out.width}x{out.height}")

    RESULTS.write_text(json.dumps(report, indent=2) + "\n")
    print(f"wrote {RESULTS.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

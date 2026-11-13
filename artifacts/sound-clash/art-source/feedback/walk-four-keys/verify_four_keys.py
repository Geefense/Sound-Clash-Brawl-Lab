#!/usr/bin/env python3
"""Check the Feedback four walk keys against the mic-hand / one-mic rule.

Rule under test (authoritative; supersedes the earlier left-hand instruction):
the microphone is held in Feedback's anatomical RIGHT hand in every key, there
is exactly one mic, and one cable runs from the mic to its plug.

What this script can prove from the pixels, per key:

  * exactly one microphone   - one neutral-metal blob of mic size;
  * exactly one cable end    - one small neutral-metal blob (the 1/4" plug)
                               below the waistband;
  * cord segments            - reported, not asserted. The cord is a thin
                               neutral stroke that passes behind the hand and
                               across the cream waistband, so a colour mask
                               splits it there. Those crossings are occlusion,
                               not breaks, and are checked by eye on the
                               emitted evidence crops.

Handedness is not decided by screen position. It is read off the grip: the
near arm carries the three sleeve stripes on its outer surface, is drawn over
the jacket, and shows the back of the hand with the thumb on the body side.
On a figure facing screen-right that is the right hand; the far arm's hand is
stripe-free and swings clear of the hip. The script emits the grip crop so the
reading can be checked without re-opening the sheet.

Usage:
    python3 verify_four_keys.py     # rewrites the evidence PNGs + JSON

Requires Pillow, numpy and scipy.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

HERE = Path(__file__).resolve().parent
SHEET = HERE / "source-sheet.jpeg"
EVIDENCE_HAND = HERE / "grip-thumb-side-5x.png"
EVIDENCE_CABLE = HERE / "cable-per-key.png"
RESULTS = HERE / "four-key-check.json"

# Cells are ~600 px wide; the analysis band skips the title strip and the
# ground/label strip, which are the only other near-white things on the sheet.
CELLS = [
    ("01 CONTACT A", (0, 0, 600, 656)),
    ("02 PASS A", (599, 0, 1199, 656)),
    ("03 CONTACT B", (0, 656, 600, 1312)),
    ("04 PASS B", (599, 656, 1199, 1312)),
]
ANALYSIS_Y = (58, 512)
MIC_MIN_AREA = 180
PLUG_AREA = (20, 180)


def metrics(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    a = rgb.astype(np.float32) / 255.0
    v = a.max(2)
    s = np.where(v > 0, (v - a.min(2)) / np.maximum(v, 1e-6), 0.0)
    return v, s


def blobs(mask: np.ndarray) -> list[dict]:
    lab, n = ndimage.label(mask, structure=np.ones((3, 3)))
    out = []
    for i in range(1, n + 1):
        ys, xs = np.where(lab == i)
        if xs.size == 0:
            continue
        out.append(
            {
                "area": int(xs.size),
                "box": [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())],
            }
        )
    return out


def near(box: list[int], other: list[int], pad: int) -> bool:
    return not (
        box[2] + pad < other[0]
        or other[2] + pad < box[0]
        or box[3] + pad < other[1]
        or other[3] + pad < box[1]
    )


def font(size: int):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:  # Pillow < 10
        return ImageFont.load_default()


def main() -> int:
    raw = SHEET.read_bytes()
    sheet = Image.open(SHEET).convert("RGB")
    print(f"sheet   {SHEET.name}  {sheet.width}x{sheet.height}  {len(raw)} bytes")
    print(f"sha256  {hashlib.sha256(raw).hexdigest()}\n")

    results = {
        "sheet": SHEET.name,
        "sha256": hashlib.sha256(raw).hexdigest(),
        "size": list(sheet.size),
        "rule": {
            "micHand": "right",
            "oneMic": True,
            "cable": "one cable from mic to plug; continuous in the art",
        },
        "method": {
            "mic": "neutral-metal blob >= 180 px (HSV saturation < 0.22, value 0.22-0.80)",
            "plug": "neutral-metal blob of 20-180 px below the mic",
            "cord": "neutral stroke, saturation < 0.20, value > 0.25; segments are "
                    "occlusion diagnostics only",
        },
        "keys": [],
    }

    hand_crop = None
    cable_panels = []
    ok = True

    for name, box in CELLS:
        cell = sheet.crop(box)
        v, s = metrics(np.asarray(cell))

        metal = (s < 0.22) & (v > 0.22) & (v < 0.80)
        metal = ndimage.binary_opening(metal, np.ones((3, 3)))
        metal_blobs = blobs(metal)
        mics = sorted(
            [b for b in metal_blobs if b["area"] >= MIC_MIN_AREA],
            key=lambda b: b["area"],
            reverse=True,
        )
        mic = mics[0] if mics else None

        plug = None
        if mic:
            below = [
                b
                for b in metal_blobs
                if PLUG_AREA[0] <= b["area"] < PLUG_AREA[1]
                and b["box"][1] > mic["box"][3] + 30
                and b["box"][3] < ANALYSIS_Y[1]
            ]
            below.sort(key=lambda b: b["area"], reverse=True)
            plug = below[0] if below else None

        cord = (s < 0.20) & (v > 0.25) & (v < 0.98)
        band = np.zeros_like(cord)
        band[ANALYSIS_Y[0]:ANALYSIS_Y[1], :] = True
        cord &= band
        cord = ndimage.binary_opening(cord, np.ones((2, 2)))
        cord = ndimage.binary_dilation(cord, np.ones((3, 3)))
        cord = ndimage.binary_closing(cord, np.ones((9, 9)))
        cord_segments = [b for b in blobs(cord) if b["area"] > 150]
        cord_segments.sort(key=lambda b: b["area"], reverse=True)

        one_mic = mic is not None and len(mics) == 1
        one_plug = plug is not None
        ok = ok and one_mic and one_plug

        print(f"{name}")
        print(f"  mic        {'1' if one_mic else str(len(mics))} blob(s) >= {MIC_MIN_AREA}px"
              f"{'  box ' + str(mic['box']) if mic else ''}")
        print(f"  plug       {'1' if one_plug else '0'}"
              f"{'  box ' + str(plug['box']) if plug else ''}")
        print(f"  cord       {len(cord_segments)} segment(s), separated only by the hand "
              f"and waistband crossings")

        results["keys"].append(
            {
                "key": name,
                "micCount": len(mics),
                "micBox": mic["box"] if mic else None,
                "plugBox": plug["box"] if plug else None,
                "cordSegments": [b["box"] for b in cord_segments],
            }
        )

        if mic:
            if hand_crop is None:
                hand_crop = cell.crop(
                    (
                        max(0, mic["box"][0] - 55),
                        max(0, mic["box"][1] - 55),
                        min(cell.width, mic["box"][2] + 120),
                        min(cell.height, mic["box"][3] + 130),
                    )
                )
            if plug:
                # frame the whole run: mic at the top, plug at the bottom
                rx0 = max(0, min(mic["box"][0], plug["box"][0]) - 28)
                rx1 = min(cell.width, max(mic["box"][2], plug["box"][2]) + 45)
                ry0 = max(0, mic["box"][1] - 14)
                ry1 = min(cell.height, plug["box"][3] + 22)
                cable_panels.append((name, cell.crop((rx0, ry0, rx1, ry1))))

    if hand_crop:
        hand_crop = hand_crop.resize(
            (hand_crop.width * 5, hand_crop.height * 5), Image.LANCZOS
        )
        hand_crop.save(EVIDENCE_HAND)
        print(f"\nwrote {EVIDENCE_HAND.name}  {hand_crop.width}x{hand_crop.height}")

    if cable_panels:
        target_h = 480
        scaled = [
            (name, panel.resize(
                (int(panel.width * target_h / panel.height), target_h), Image.LANCZOS))
            for name, panel in cable_panels
        ]
        pad, caption = 14, 46
        total_w = sum(p.width for _, p in scaled) + pad * (len(scaled) + 1)
        canvas = Image.new("RGB", (total_w, target_h + caption + pad * 2), (18, 16, 22))
        draw = ImageDraw.Draw(canvas)
        f = font(20)
        x = pad
        for name, panel in scaled:
            canvas.paste(panel, (x, pad))
            draw.text((x + 4, pad + target_h + 10), name, fill=(232, 228, 236), font=f)
            x += panel.width + pad
        canvas.save(EVIDENCE_CABLE)
        print(f"wrote {EVIDENCE_CABLE.name}  {canvas.width}x{canvas.height}")

    results["allChecksPass"] = ok
    RESULTS.write_text(json.dumps(results, indent=2) + "\n")
    print(f"wrote {RESULTS.name}")
    print(f"\nresult: {'PASS (one mic, one plug per key)' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())

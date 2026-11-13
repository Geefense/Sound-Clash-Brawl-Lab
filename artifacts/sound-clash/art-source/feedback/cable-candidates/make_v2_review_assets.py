#!/usr/bin/env python3
"""Review assets for the v2 BOX candidates (12 and 14).

Builds, into public/review/appearance/cable/batch/v2/:
  close-<pose>.png            detail crop, original | v1 | v2
  gameplay-<pose>.png         gameplay size (0.44), original | v1 | v2
  gameplay-12-13-14.png       stacked BOX sequence at gameplay size
  box-sequence-v2.gif         same frames as an animation
  diff-<pose>-v1-vs-v2.png    copied from the candidate folder
"""
from pathlib import Path
import shutil

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
PACK = HERE.parents[2] / "public/assets/feedback/aligned"
PUB = HERE.parents[2] / "public/review/appearance/cable/batch/v2"
PUB.mkdir(parents=True, exist_ok=True)

BG = (30, 30, 38)
LABEL = (232, 232, 238)
BOX = "12_backhand_windup  ·  13_box_palm  ·  14_followthrough"

CROPS = {
    "12_backhand_windup": (808, 612, 900, 678),
    "14_followthrough": (582, 552, 702, 668),
}
SCALE = {"12_backhand_windup": 7, "14_followthrough": 5}
GAME = 0.44


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except Exception:
        return None


def on_bg(path, crop=None):
    im = Image.open(path).convert("RGBA")
    if crop:
        im = im.crop(crop)
    out = Image.new("RGB", im.size, BG)
    out.paste(im, (0, 0), im)
    return out


def content_box(path, margin=10):
    im = Image.open(path).convert("RGBA")
    box = im.getchannel("A").getbbox()
    x0, y0, x1, y1 = box
    return (max(0, x0 - margin), max(0, y0 - margin),
            min(im.width, x1 + margin), min(im.height, y1 + margin))


def row(paths, labels, crop, scale, size=17):
    tiles = [on_bg(p, crop) for p in paths]
    tiles = [t.resize((round(t.width * scale), round(t.height * scale)), Image.LANCZOS) for t in tiles]
    pad = 10
    head = 26
    w = sum(t.width for t in tiles) + pad * (len(tiles) + 1)
    h = tiles[0].height + head + pad
    sheet = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(sheet)
    f = font(size)
    x = pad
    for t, lab in zip(tiles, labels):
        sheet.paste(t, (x, head))
        d.text((x + 2, 6), lab, fill=LABEL, font=f)
        x += t.width + pad
    return sheet


def main():
    for pose, crop in CROPS.items():
        o = PACK / f"{pose}.png"
        v1 = HERE / f"{pose}-cable-v1.png"
        v2 = HERE / f"{pose}-cable-v2.png"

        row([o, v1, v2], ["ORIGINAL", "v1", "v2 — short connection"],
            crop, SCALE[pose]).save(PUB / f"close-{pose}.png")

        row([o, v1, v2], ["ORIGINAL", "v1", "v2"],
            content_box(o), GAME, size=15).save(PUB / f"gameplay-{pose}.png")

        shutil.copyfile(HERE / f"diff-{pose}-v1-vs-v2.png", PUB / f"diff-{pose}-v1-vs-v2.png")

    # BOX sequence at gameplay size: 12 and 14 use v2, 13 stays on its v1 candidate.
    frames = []
    entries = [
        ("12_backhand_windup", HERE / "12_backhand_windup-cable-v2.png"),
        ("13_box_palm", HERE / "13_box_palm-cable-v1.png"),
        ("14_followthrough", HERE / "14_followthrough-cable-v2.png"),
    ]
    tiles = []
    for pose, cand in entries:
        sheet = row([PACK / f"{pose}.png", cand], ["ORIGINAL", "CANDIDATE"],
                    content_box(PACK / f"{pose}.png"), GAME, size=14)
        foot = Image.new("RGB", (sheet.width, sheet.height + 22), BG)
        foot.paste(sheet, (0, 0))
        ImageDraw.Draw(foot).text((12, sheet.height + 4), pose, fill=(255, 220, 180), font=font(14))
        tiles.append(foot)
        frames.append(foot)
    w = max(t.width for t in tiles) + 20
    head = 34
    stack = Image.new("RGB", (w, sum(t.height for t in tiles) + 10 * (len(tiles) - 1) + head), BG)
    y = head
    for t in tiles:
        stack.paste(t, (10, y))
        y += t.height + 10
    d = ImageDraw.Draw(stack)
    d.text((12, 10), "BOX sequence at gameplay size (0.44) — original left, candidate right",
           fill=(255, 255, 255), font=font(16))
    stack.save(PUB / "gameplay-12-13-14.png")
    frames[0].save(PUB / "box-sequence-v2.gif", save_all=True, append_images=frames[1:],
                   duration=340, loop=0)
    print("wrote", PUB, "->", sorted(p.name for p in PUB.iterdir()))


if __name__ == "__main__":
    main()

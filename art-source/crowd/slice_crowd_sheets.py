"""Slice the Dancehall crowd sheets into individual game sprites.

Run from the repository root:  python3 art-source/crowd/slice_crowd_sheets.py

Pipeline (unchanged since the first crowd batch):
  1. Key the magenta background with a flood fill from the borders, so a character's own
     pink/magenta clothing is only removed when it is genuinely background-coloured and
     connected to the outside.
  2. Also clear enclosed pure magenta (the gaps inside arm loops, between legs).
  3. Cut a 2 px fringe around the key so no magenta halo survives, then write RGBA at 1:1.
     Pixels are never resampled, recoloured or scaled; only alpha changes.
  4. Split the sheet by connected component (not by column), so characters that overlap in
     projection stay whole. The one touching crate pair is split at its emptiest column.

Outputs: godot/assets/sprites/crowd/<name>.png and godot/assets/sprites/crates/*.png
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

CROWD_OUT = 'godot/assets/sprites/crowd'
CRATE_OUT = 'godot/assets/sprites/crates'

SHEETS = [
    dict(path='art-source/crowd/crowd-sheet-a-queen-flag-hypeman-crates.png', crates=True,
         names=['crowd_01_dancehall_queen', 'crowd_02_flag_waver',
                'crowd_03_hypeman_bucket_hat']),
    dict(path='art-source/crowd/crowd-sheet-b-three-spectators.png',
         names=['crowd_04_cheer_woman', 'crowd_05_arms_crossed_man', 'crowd_06_elder_clap']),
    dict(path='art-source/crowd/crowd-sheet-c-four-spectators.png',
         names=['crowd_07_cap_pointing_elder', 'crowd_08_cup_jersey_youth',
                'crowd_09_airhorn_hypeman', 'crowd_10_headscarf_clapper']),
    dict(path='art-source/crowd/crowd-sheet-d-mane-queen.png',
         names=['crowd_11_mane_queen']),
    dict(path='art-source/crowd/crowd-sheet-e-four-spectators.png',
         names=['crowd_12_towel_waver', 'crowd_13_floral_skanker',
                'crowd_14_rasta_elder', 'crowd_15_hype_woman']),
]


def keyed(path):
    a = np.asarray(Image.open(path).convert('RGB'))
    r, g, b = [a[:, :, i].astype(np.int16) for i in range(3)]
    mx, mn = np.maximum(r, b), np.minimum(r, b)
    bg_like = (mn > 130) & (g < 110) & ((mx - mn) < 70)
    lbl, _ = ndimage.label(bg_like)
    edge = set(np.unique(np.r_[lbl[0, :], lbl[-1, :], lbl[:, 0], lbl[:, -1]])) - {0}
    bg = np.isin(lbl, list(edge)) | (bg_like & (r > 225) & (b > 225) & (g < 65))
    alpha = np.where(bg, 0, 255).astype(np.uint8)
    near = ndimage.binary_dilation(bg, iterations=2) & ~bg
    score = (np.clip((mn - 90) / 90.0, 0, 1) * np.clip((120 - g) / 120.0, 0, 1)
             * np.clip(1 - (mx - mn) / 80.0, 0, 1))[near]
    alpha[near] = np.where(score > 0.35, 0, 255).astype(np.uint8)
    return np.dstack([a[:, :, :3], alpha])


def components(arr, minarea=3000):
    lbl, _ = ndimage.label(arr[:, :, 3] > 0, structure=np.ones((3, 3)))
    out = []
    for i, sl in enumerate(ndimage.find_objects(lbl), start=1):
        if sl is None:
            continue
        m = (lbl[sl] == i)
        if m.sum() < minarea:
            continue
        ys, xs = sl
        out.append(dict(x0=xs.start, x1=xs.stop - 1, y0=ys.start, y1=ys.stop - 1, label=i))
    out.sort(key=lambda c: c['x0'])
    return lbl, out


def cut(arr, lbl, c):
    sub = arr[c['y0']:c['y1'] + 1, c['x0']:c['x1'] + 1].copy()
    sub[:, :, 3] = np.where(lbl[c['y0']:c['y1'] + 1, c['x0']:c['x1'] + 1] == c['label'],
                            sub[:, :, 3], 0)
    return sub


def split_columns(sub):
    """Crates touch: split at the emptiest column in the middle third."""
    cols = (sub[:, :, 3] > 0).sum(axis=0)
    lo, hi = len(cols) // 3, 2 * len(cols) // 3
    mid = lo + int(np.argmin(cols[lo:hi]))
    left = sub.copy()
    left[:, :, 3] = np.where(np.arange(sub.shape[1]) < mid, sub[:, :, 3], 0)
    right = sub.copy()
    right[:, :, 3] = np.where(np.arange(sub.shape[1]) >= mid, sub[:, :, 3], 0)
    return left, right


def trim(a):
    ys, xs = np.where(a[:, :, 3] > 0)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def main():
    os.makedirs(CROWD_OUT, exist_ok=True)
    os.makedirs(CRATE_OUT, exist_ok=True)
    for sheet in SHEETS:
        arr = keyed(sheet['path'])
        lbl, comps = components(arr)
        bodies = comps[:len(sheet['names'])]
        if len(bodies) != len(sheet['names']):
            raise SystemExit('%s: expected %d characters, found %d' %
                             (sheet['path'], len(sheet['names']), len(bodies)))
        for c, name in zip(bodies, sheet['names']):
            Image.fromarray(trim(cut(arr, lbl, c))).save('%s/%s.png' % (CROWD_OUT, name))
            print('%-34s %4dx%d' % (name, c['x1'] - c['x0'] + 1, c['y1'] - c['y0'] + 1))
        if sheet.get('crates'):
            red, black = split_columns(trim(cut(arr, lbl, comps[len(sheet['names'])])))
            Image.fromarray(trim(red)).save('%s/crate_01_red.png' % CRATE_OUT)
            Image.fromarray(trim(black)).save('%s/crate_02_black.png' % CRATE_OUT)
            print('crates                              both split')


if __name__ == '__main__':
    main()

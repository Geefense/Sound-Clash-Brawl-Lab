"""Slice the two Dancehall crowd sheets: key the magenta background and cut
6 characters + 2 vinyl crates. Run from the repository root."""
import sys, numpy as np
from PIL import Image
from scipy import ndimage

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
    sub[:, :, 3] = np.where(lbl[c['y0']:c['y1'] + 1, c['x0']:c['x1'] + 1] == c['label'], sub[:, :, 3], 0)
    return sub

def split_columns(sub, gap_min=3):
    """Crates touch: split at the emptiest column in the middle third."""
    cols = (sub[:, :, 3] > 0).sum(axis=0)
    lo, hi = len(cols) // 3, 2 * len(cols) // 3
    mid = lo + int(np.argmin(cols[lo:hi]))
    left = sub.copy();  left[:, :, 3]  = np.where(np.arange(sub.shape[1]) < mid, sub[:, :, 3], 0)
    right = sub.copy(); right[:, :, 3] = np.where(np.arange(sub.shape[1]) >= mid, sub[:, :, 3], 0)
    return left, right, mid

def trim(a):
    ys, xs = np.where(a[:, :, 3] > 0)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]

if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '/tmp/crowd'
    import os; os.makedirs(out, exist_ok=True)
    A = keyed('B6BD1902-2297-4484-AF0A-1EE824147F4B.png')
    B = keyed('DFBF74CC-0D06-417C-8DBA-E2A10DEAD891.png')
    lblA, cA = components(A); lblB, cB = components(B)
    namesA = ['crowd_01_dancehall_queen', 'crowd_02_flag_waver', 'crowd_03_hypeman_bucket_hat']
    namesB = ['crowd_04_cheer_woman', 'crowd_05_arms_crossed_man', 'crowd_06_elder_clap']
    for c, nm in zip(cA[:3], namesA):
        Image.fromarray(trim(cut(A, lblA, c))).save('%s/%s.png' % (out, nm))
    for c, nm in zip(cB[:3], namesB):
        Image.fromarray(trim(cut(B, lblB, c))).save('%s/%s.png' % (out, nm))
    crates = trim(cut(A, lblA, cA[3]))
    red, black, mid = split_columns(crates)
    Image.fromarray(trim(red)).save('%s/crate_01_red.png' % out)
    Image.fromarray(trim(black)).save('%s/crate_02_black.png' % out)
    for f in namesA + namesB + ['crate_01_red', 'crate_02_black']:
        im = Image.open('%s/%s.png' % (out, f))
        print('%-30s %4dx%-4d alpha0=%d' % (f, im.width, im.height,
              int((np.asarray(im)[:, :, 3] == 0).sum())))

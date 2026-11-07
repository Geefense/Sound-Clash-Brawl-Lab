/**
 * A tiny supersampled rasterizer.
 *
 * Every primitive is authored in *logical* sprite units (the same units the
 * game uses for its hurtboxes) and is rendered at `scale * ss` samples per
 * unit, then box-filtered down. That gives clean antialiased edges without any
 * native dependency.
 */
import { encodePng } from './png.mjs';

export class Raster {
  constructor({ width, height, scale = 1, ss = 3 }) {
    this.width = Math.round(width * scale);
    this.height = Math.round(height * scale);
    this.scale = scale;
    this.ss = ss;
    this.sw = this.width * ss;
    this.sh = this.height * ss;
    /** Premultiplied RGBA at sample resolution. */
    this.buf = new Uint8ClampedArray(this.sw * this.sh * 4);
    /** Logical units per sample. */
    this.unit = 1 / (scale * ss);
  }

  /** Sample range covering a logical-space bounding box. */
  _bounds(x0, y0, x1, y1) {
    const s = this.scale * this.ss;
    return {
      ix0: Math.max(0, Math.floor(x0 * s)),
      ix1: Math.min(this.sw - 1, Math.ceil(x1 * s)),
      iy0: Math.max(0, Math.floor(y0 * s)),
      iy1: Math.min(this.sh - 1, Math.ceil(y1 * s)),
    };
  }

  _blend(index, r, g, b, a) {
    if (a <= 0) return;
    const ia = 1 - a;
    const buf = this.buf;
    buf[index] = r * a + buf[index] * ia;
    buf[index + 1] = g * a + buf[index + 1] * ia;
    buf[index + 2] = b * a + buf[index + 2] * ia;
    buf[index + 3] = a * 255 + buf[index + 3] * ia;
  }

  _paint(bounds, inside, color, alpha = 1) {
    const r = (color >> 16) & 0xff;
    const g = (color >> 8) & 0xff;
    const b = color & 0xff;
    const s = this.scale * this.ss;
    const u = this.unit;
    for (let iy = bounds.iy0; iy <= bounds.iy1; iy++) {
      const ly = (iy + 0.5) * u;
      let index = (iy * this.sw + bounds.ix0) * 4;
      for (let ix = bounds.ix0; ix <= bounds.ix1; ix++) {
        if (inside((ix + 0.5) * u, ly)) this._blend(index, r, g, b, alpha);
        index += 4;
      }
    }
    void s;
  }

  fillCircle(cx, cy, radius, color, alpha = 1) {
    if (radius <= 0) return;
    const r2 = radius * radius;
    this._paint(
      this._bounds(cx - radius, cy - radius, cx + radius, cy + radius),
      (x, y) => {
        const dx = x - cx;
        const dy = y - cy;
        return dx * dx + dy * dy <= r2;
      },
      color,
      alpha,
    );
  }

  fillEllipse(cx, cy, rx, ry, rotation, color, alpha = 1) {
    const cos = Math.cos(-rotation);
    const sin = Math.sin(-rotation);
    const reach = Math.max(rx, ry);
    this._paint(
      this._bounds(cx - reach, cy - reach, cx + reach, cy + reach),
      (x, y) => {
        const dx = x - cx;
        const dy = y - cy;
        const lx = dx * cos - dy * sin;
        const ly = dx * sin + dy * cos;
        return (lx * lx) / (rx * rx) + (ly * ly) / (ry * ry) <= 1;
      },
      color,
      alpha,
    );
  }

  fillRoundRect(x, y, w, h, radius, color, alpha = 1) {
    const r = Math.max(0, Math.min(radius, Math.min(w, h) / 2));
    this._paint(
      this._bounds(x, y, x + w, y + h),
      (px, py) => {
        if (px < x || px > x + w || py < y || py > y + h) return false;
        if (px >= x + r && px <= x + w - r) return true;
        if (py >= y + r && py <= y + h - r) return true;
        const qx = Math.max(x + r, Math.min(px, x + w - r));
        const qy = Math.max(y + r, Math.min(py, y + h - r));
        const dx = px - qx;
        const dy = py - qy;
        return dx * dx + dy * dy <= r * r;
      },
      color,
      alpha,
    );
  }

  fillRect(x, y, w, h, color, alpha = 1) {
    this.fillRoundRect(x, y, w, h, 0, color, alpha);
  }

  /** Capsule from a to b with the given stroke width. */
  line(x1, y1, x2, y2, width, color, alpha = 1) {
    const half = width / 2;
    const dx = x2 - x1;
    const dy = y2 - y1;
    const lengthSq = dx * dx + dy * dy;
    const pad = half + 0.5;
    this._paint(
      this._bounds(
        Math.min(x1, x2) - pad,
        Math.min(y1, y2) - pad,
        Math.max(x1, x2) + pad,
        Math.max(y1, y2) + pad,
      ),
      (x, y) => {
        let t = 0;
        if (lengthSq > 0) {
          t = ((x - x1) * dx + (y - y1) * dy) / lengthSq;
          t = t < 0 ? 0 : t > 1 ? 1 : t;
        }
        const px = x1 + dx * t - x;
        const py = y1 + dy * t - y;
        return px * px + py * py <= half * half;
      },
      color,
      alpha,
    );
  }

  fillPolygon(points, color, alpha = 1) {
    let x0 = Infinity;
    let y0 = Infinity;
    let x1 = -Infinity;
    let y1 = -Infinity;
    for (const [x, y] of points) {
      x0 = Math.min(x0, x);
      y0 = Math.min(y0, y);
      x1 = Math.max(x1, x);
      y1 = Math.max(y1, y);
    }
    this._paint(
      this._bounds(x0, y0, x1, y1),
      (x, y) => {
        let inside = false;
        for (let i = 0, j = points.length - 1; i < points.length; j = i++) {
          const [xi, yi] = points[i];
          const [xj, yj] = points[j];
          if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
        }
        return inside;
      },
      color,
      alpha,
    );
  }

  /** Box-filter the supersampled buffer down to straight RGBA. */
  toRGBA() {
    const { width, height, ss, sw, buf } = this;
    const out = new Uint8ClampedArray(width * height * 4);
    const samples = ss * ss;
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        let r = 0;
        let g = 0;
        let b = 0;
        let a = 0;
        for (let sy = 0; sy < ss; sy++) {
          let index = ((y * ss + sy) * sw + x * ss) * 4;
          for (let sx = 0; sx < ss; sx++) {
            r += buf[index];
            g += buf[index + 1];
            b += buf[index + 2];
            a += buf[index + 3];
            index += 4;
          }
        }
        const o = (y * width + x) * 4;
        if (a === 0) continue;
        out[o] = (r * 255) / a;
        out[o + 1] = (g * 255) / a;
        out[o + 2] = (b * 255) / a;
        out[o + 3] = a / samples;
      }
    }
    return out;
  }

  toPng() {
    return encodePng(this.width, this.height, this.toRGBA());
  }
}

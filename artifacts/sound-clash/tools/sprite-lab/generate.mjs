/**
 * Sprite sheet generator.
 *
 *   node tools/sprite-lab/generate.mjs
 *
 * Writes, for each palette, a transparent atlas plus a JSON sidecar, and
 * checks that every frame shares one sole line so the fighter can never float
 * or sink when the atlas is played back.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Raster } from './raster.mjs';
import { encodePng } from './png.mjs';
import { CLIPS, FRAME, PALETTES, SCALE, drawFrame, frameList } from './rig.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.resolve(here, '../../public/sprites');
const COLS = 4;
const SS = 3;

const frames = frameList();
const rows = Math.ceil(frames.length / COLS);
const frameW = Math.round(FRAME.width * SCALE);
const frameH = Math.round(FRAME.height * SCALE);
const atlasW = frameW * COLS;
const atlasH = frameH * rows;

/** Lowest row with visible pixels, used to prove the sole line is shared. */
function bottomOpaqueRow(rgba, width, height) {
  for (let y = height - 1; y >= 0; y--) {
    for (let x = 0; x < width; x++) {
      if (rgba[(y * width + x) * 4 + 3] > 12) return y;
    }
  }
  return -1;
}

for (const [paletteName, palette] of Object.entries(PALETTES)) {
  const atlas = new Uint8ClampedArray(atlasW * atlasH * 4);
  const metadata = [];
  const baselines = new Set();

  frames.forEach((frame, index) => {
    const raster = new Raster({ width: FRAME.width, height: FRAME.height, scale: SCALE, ss: SS });
    drawFrame(raster, frame, palette);
    const rgba = raster.toRGBA();
    baselines.add(bottomOpaqueRow(rgba, frameW, frameH));

    const col = index % COLS;
    const row = Math.floor(index / COLS);
    const ox = col * frameW;
    const oy = row * frameH;
    for (let y = 0; y < frameH; y++) {
      const src = y * frameW * 4;
      const dest = ((oy + y) * atlasW + ox) * 4;
      atlas.set(rgba.subarray(src, src + frameW * 4), dest);
    }

    metadata.push({
      index,
      clip: frame.clip,
      clipFrame: frame.clipFrame,
      pose: frame.pose,
      x: ox,
      y: oy,
      w: frameW,
      h: frameH,
    });
  });

  const suffix = paletteName === 'sidewinder' ? '' : '-alt';
  const pngPath = path.join(outDir, `rig-sample${suffix}.png`);
  fs.writeFileSync(pngPath, encodePng(atlasW, atlasH, atlas));

  const baselinesList = [...baselines];
  const aligned = baselinesList.length === 1;
  console.log(
    `${path.basename(pngPath)}: ${atlasW}x${atlasH}, ${frames.length} frames, ` +
      `baselines=${baselinesList.join(',')} ${aligned ? 'ALIGNED' : 'MISALIGNED'}`,
  );
  if (!aligned) process.exitCode = 1;

  const sheet = {
    schema: 1,
    kind: 'pipeline-sample',
    character: 'NOT Feedback — placeholder rig from src/game/GameScene.ts',
    note:
      'No Feedback reference artwork exists in this repository. This sheet proves the sprite ' +
      'pipeline, proportions and animation timing only. Do not ship it as Feedback.',
    generatedBy: 'tools/sprite-lab/generate.mjs',
    palette: paletteName,
    paletteLabel: palette.label,
    colors: palette,
    scale: SCALE,
    logical: { width: FRAME.width, height: FRAME.height, groundY: FRAME.groundY },
    anchor: { x: frameW / 2, y: FRAME.groundY * SCALE },
    image: `rig-sample${suffix}.png`,
    frameWidth: frameW,
    frameHeight: frameH,
    columns: COLS,
    rows,
    soleRow: baselinesList[0],
    clips: CLIPS.map((clip) => ({
      name: clip.name,
      label: clip.label,
      frameMs: clip.frameMs,
      loop: !!clip.loop,
      frames: frames
        .map((frame, index) => ({ frame, index }))
        .filter(({ frame }) => frame.clip === clip.name)
        .map(({ index }) => index),
    })),
    frames: metadata,
  };
  fs.writeFileSync(
    path.join(outDir, `rig-sample${suffix}.json`),
    JSON.stringify(sheet, null, 2) + '\n',
  );
}

console.log('wrote atlas + metadata to public/sprites/');

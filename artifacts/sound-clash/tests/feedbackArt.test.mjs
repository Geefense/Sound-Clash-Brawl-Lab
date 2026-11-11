import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  FEEDBACK_POSES,
  FEEDBACK_POSE_IDS,
  FEEDBACK_SCALE,
  feedbackAssetUrl,
  feedbackTextureKey,
  selectFeedbackPose,
  shouldMirrorPose,
} from '../src/game/feedbackArt.ts';
import { createMatchState } from '../src/game/simulation/initialState.ts';

const root = path.dirname(fileURLToPath(import.meta.url));
const assetDir = path.resolve(root, '../public/assets/feedback');
const manifest = JSON.parse(fs.readFileSync(path.join(assetDir, 'feedback.poses.json'), 'utf8'));

const view = { knockedDown: false, fallProgress: 0, koResting: false };
const base = createMatchState(1234).player;
const fighter = overrides => ({ ...base, ...overrides });

test('the pose table matches the shipped manifest exactly', () => {
  assert.equal(manifest.version, 1);
  assert.deepEqual(manifest.canvas, [1536, 1024]);
  assert.deepEqual(Object.keys(manifest.poses).sort(), FEEDBACK_POSE_IDS.slice().sort());
  assert.equal(FEEDBACK_POSE_IDS.length, 17);

  for (const id of FEEDBACK_POSE_IDS) {
    const meta = FEEDBACK_POSES[id];
    const entry = manifest.poses[id];
    assert.ok(entry, `${id} is missing from feedback.poses.json`);
    assert.equal(meta.file, entry.file, `${id} file drifted`);
    assert.deepEqual(meta.origin, entry.origin, `${id} origin drifted`);
    assert.equal(meta.facing, entry.facing, `${id} facing drifted`);
    assert.equal(meta.placement, entry.placement, `${id} placement drifted`);
    assert.ok(fs.existsSync(path.join(assetDir, meta.file)), `${id} png is missing`);
  }
});

test('all 17 aligned PNGs are present and addressed uniquely', () => {
  const pngs = fs.readdirSync(path.join(assetDir, 'aligned')).filter(name => name.endsWith('.png'));
  assert.equal(pngs.length, 17);
  assert.equal(new Set(FEEDBACK_POSE_IDS.map(feedbackAssetUrl)).size, 17);
  assert.equal(new Set(FEEDBACK_POSE_IDS.map(feedbackTextureKey)).size, 17);
  assert.ok(feedbackAssetUrl('01_idle').startsWith('/assets/feedback/aligned/'));
});

test('one uniform scale keeps the painted figure at the vector fighter height', () => {
  // Idle ink runs y 411 -> 900 in the 1024 tall canvas.
  const paintedHeight = 900 - 411;
  const rendered = paintedHeight * FEEDBACK_SCALE;
  assert.ok(rendered > 195 && rendered < 260, `rendered height ${rendered} leaves the skeletal proportions`);
});

test('states select the pose the pack documents', () => {
  assert.equal(selectFeedbackPose(fighter({}), view), '01_idle');
  assert.equal(selectFeedbackPose(fighter({ blocking: true }), view), '08_block');
  assert.equal(selectFeedbackPose(fighter({ action: 'hit' }), view), '16_gut_punch');
  assert.equal(
    selectFeedbackPose(fighter({ action: 'head', attackStage: 'head', attackElapsed: 0.05 }), view),
    '12_backhand_windup',
  );
  assert.equal(
    selectFeedbackPose(fighter({ action: 'head', attackStage: 'head', attackElapsed: 0.2 }), view),
    '13_box_palm',
  );
  assert.equal(
    selectFeedbackPose(fighter({ action: 'head', attackStage: 'head', attackElapsed: 0.4 }), view),
    '14_followthrough',
  );
  assert.equal(
    selectFeedbackPose(fighter({ action: 'upper', attackStage: 'upper', attackElapsed: 0.05 }), view),
    '07_crouch',
  );
  assert.equal(
    selectFeedbackPose(fighter({ action: 'light', attackStage: 'jab1', attackElapsed: 0.1 }), view),
    '13_box_palm',
  );
  assert.equal(
    selectFeedbackPose(fighter({ action: 'heavy', attackStage: 'power', attackElapsed: 0.2 }), view),
    '16_gut_punch',
  );
});

test('knockdowns walk launch, tumble, landing and KO poses', () => {
  const down = progress =>
    selectFeedbackPose(fighter({}), { knockedDown: true, fallProgress: progress, koResting: false });
  assert.equal(down(0.1), '03_c_recoil');
  assert.equal(down(0.7), '04_inverted_c');
  assert.equal(down(0.97), '17_seated_landing');
  assert.equal(
    selectFeedbackPose(fighter({ health: 0 }), { knockedDown: true, fallProgress: 1, koResting: true }),
    '02_knockout',
  );
});

test('mirroring follows painted facing and never flips the rear view', () => {
  assert.equal(shouldMirrorPose('right', -1), true);
  assert.equal(shouldMirrorPose('right', 1), false);
  assert.equal(shouldMirrorPose('left', 1), true);
  assert.equal(shouldMirrorPose('left', -1), false);
  assert.equal(shouldMirrorPose('away', -1), false);
  assert.equal(shouldMirrorPose('away', 1), false);
});

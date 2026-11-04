import assert from 'node:assert/strict';
import test from 'node:test';
import { InputBuffer } from '../src/game/input/InputBuffer.ts';

test('a touch tap that starts and ends between ticks is delivered exactly once', () => {
  const buffer = new InputBuffer();
  buffer.press('light');
  buffer.release('light');

  const first = buffer.sample();
  assert.equal(first.light, true, 'the tap must survive until the next tick');
  assert.equal(buffer.queuedEdges, 0);
  assert.equal(buffer.sample().light, false, 'the tap must not repeat');
});

test('one press never repeats across several simulation ticks in one frame', () => {
  const buffer = new InputBuffer();
  buffer.press('heavy');
  const samples = Array.from({ length: 5 }, () => buffer.sample());
  assert.deepEqual(
    samples.map(sample => sample.heavy),
    [true, false, false, false, false],
  );
});

test('each queued press is consumed by exactly one tick, in press order', () => {
  const buffer = new InputBuffer();
  buffer.press('light');
  buffer.press('upper');
  buffer.press('jump');

  assert.equal(buffer.sample().light, true);
  assert.equal(buffer.sample().upper, true);
  assert.equal(buffer.sample().jump, true);
  const after = buffer.sample();
  assert.deepEqual(
    [after.light, after.upper, after.jump],
    [false, false, false],
    'no press may leak into a later tick',
  );
});

test('held movement and block persist across ticks, presses do not', () => {
  const buffer = new InputBuffer();
  buffer.press('left');
  buffer.press('block');
  buffer.press('light');

  const first = buffer.sample();
  const second = buffer.sample();
  assert.equal(first.left, true);
  assert.equal(first.block, true);
  assert.equal(first.light, true);
  assert.equal(second.left, true, 'held movement must survive the tick');
  assert.equal(second.block, true, 'held block must survive the tick');
  assert.equal(second.light, false);
});

test('release stops held state without dropping a queued attack', () => {
  const buffer = new InputBuffer();
  buffer.press('right');
  buffer.press('upper');
  buffer.release('right');

  const sample = buffer.sample();
  assert.equal(sample.right, false);
  assert.equal(sample.upper, true);
});

test('a burst of presses is bounded and keeps the most recent inputs', () => {
  const buffer = new InputBuffer();
  for (let i = 0; i < 12; i++) buffer.press('light');
  assert.equal(buffer.queuedEdges, 8, 'the queue must stay bounded');
  let presses = 0;
  while (buffer.sample().light) presses++;
  assert.equal(presses, 8);
});

test('an untouched buffer samples neutral and clear resets everything', () => {
  const buffer = new InputBuffer();
  assert.deepEqual(buffer.sample(), {
    left: false,
    right: false,
    jump: false,
    block: false,
    light: false,
    heavy: false,
    head: false,
    upper: false,
  });

  buffer.press('left');
  buffer.press('light');
  buffer.clear();
  const cleared = buffer.sample();
  assert.equal(cleared.left, false);
  assert.equal(cleared.light, false);
});

test('setHeld carries keyboard holding without synthesising presses', () => {
  const buffer = new InputBuffer();
  buffer.setHeld('left', true);
  assert.equal(buffer.sample().left, true);
  buffer.setHeld('left', false);
  assert.equal(buffer.sample().left, false);
});

import assert from 'node:assert/strict';
import test from 'node:test';
import { getHitReactionPose, getKnockdownPose } from '../src/game/visualReactions.ts';

const hit = (overrides = {}) => ({ kind: 'light', region: 'head', direction: 1, age: 0, ...overrides });
const fall = (tick, direction = 1, heavy = true) => getKnockdownPose(tick, 9, 36, direction, heavy);

test('clean hits recoil the shoulders and head, with distinct light/heavy strength and duration', () => {
  const light = getHitReactionPose(hit());
  const heavy = getHitReactionPose(hit({ kind: 'heavy' }));
  assert.ok(light.shoulderX > 0);
  assert.ok(light.headX > light.shoulderX);
  assert.ok(heavy.shoulderX > light.shoulderX);
  assert.ok(heavy.headTilt > light.headTilt);
  assert.equal(getHitReactionPose(hit({ age: 11 })).shoulderX, 0);
  assert.ok(getHitReactionPose(hit({ kind: 'heavy', age: 11 })).shoulderX > 0);
  assert.deepEqual(getHitReactionPose(hit({ kind: 'heavy', age: 17 })), getHitReactionPose(null));
});

test('heavy body shots compress and shake the torso, then recover fully', () => {
  const body = getHitReactionPose(hit({ kind: 'heavy', region: 'body', age: 1 }));
  const head = getHitReactionPose(hit({ kind: 'heavy', age: 1 }));
  const light = getHitReactionPose(hit({ region: 'body', age: 1 }));
  assert.ok(body.compression > light.compression);
  assert.equal(head.compression, 0);
  assert.notEqual(body.shakeX, 0);
  assert.equal(light.shakeX, 0);
  assert.ok(getHitReactionPose(hit({ kind: 'heavy', region: 'body', age: 16 })).compression < body.compression);
});

test('hit recoil mirrors the strike direction and never mutates reaction metadata', () => {
  const input = hit({ kind: 'heavy', region: 'body', age: 3 });
  const copy = structuredClone(input);
  const right = getHitReactionPose(input);
  const left = getHitReactionPose({ ...input, direction: -1 });
  assert.equal(left.shoulderX, -right.shoulderX);
  assert.equal(left.headX, -right.headX);
  assert.equal(left.headTilt, -right.headTilt);
  assert.deepEqual(input, copy);
  assert.deepEqual(getHitReactionPose(input), right);
});

test('KO launches backward with an airborne arc and a stronger heavy trajectory', () => {
  assert.equal(fall(0).x, 0);
  assert.equal(fall(8).angle, 0);
  const early = fall(18);
  const light = fall(18, 1, false);
  assert.ok(early.x > light.x);
  assert.ok(early.y < light.y);
  assert.ok(early.angle > 0.4);
  assert.equal(fall(18, -1).x, -early.x);
  assert.equal(fall(18, -1).angle, -early.angle);
  assert.equal(fall(18, -1).y, early.y);
});

test('ground impact happens at tick 45, rebounds briefly, and holds a flat resting pose', () => {
  assert.equal(fall(44).impact, 0);
  assert.equal(fall(45).impact, 1);
  assert.equal(fall(45).angle, Math.PI / 2);
  assert.ok(fall(48).y < fall(45).y);
  assert.deepEqual(fall(55), fall(117));
  assert.deepEqual(fall(117), fall(400));
  assert.equal(fall(117).impact, 0);
});

test('heavy body recoil emphasizes the torso with minimal head tilt', () => {
  const body = getHitReactionPose(hit({ kind: 'heavy', region: 'body' }));
  const head = getHitReactionPose(hit({ kind: 'heavy' }));
  assert.ok(body.shoulderX > head.shoulderX);
  assert.ok(body.compression >= 0.3);
  assert.ok(Math.abs(body.headTilt) <= 0.05);
  assert.ok(body.headTilt < head.headTilt / 4);
});

test('Upper Box snaps the head and staggers the feet without changing the knockdown curve', () => {
  const slap = getHitReactionPose(hit({ kind: 'upper', age: 1 }));
  const punch = getHitReactionPose(hit({ kind: 'head', age: 1 }));
  assert.ok(slap.headTilt > punch.headTilt);
  assert.notEqual(slap.stumble, 0);
  assert.equal(punch.stumble, 0);
  assert.deepEqual(getHitReactionPose(hit({ kind: 'upper', age: 17 })), getHitReactionPose(null));
});

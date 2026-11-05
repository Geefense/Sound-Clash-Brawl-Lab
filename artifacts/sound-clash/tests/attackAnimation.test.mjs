import assert from 'node:assert/strict';
import test from 'node:test';
import { ARM_LENGTH, ARM_SEGMENTS, getAttackArmPose } from '../src/game/attackAnimation.ts';
import { STAGE_PROFILES } from '../src/game/combatConfig.ts';

const pose = (action, elapsed, overrides = {}) => getAttackArmPose({
  action,
  centerX: 500,
  shoulderY: 470,
  hipY: 512,
  facing: 1,
  elapsed,
  ...overrides,
});

test('both hand strikes keep one anatomical arm length in every pose', () => {
  assert.equal(ARM_SEGMENTS.upperArm + ARM_SEGMENTS.forearm, ARM_LENGTH);
  for (const action of ['head', 'upper']) {
    const { duration } = STAGE_PROFILES[action];
    for (let time = 0; time <= duration + 1e-9; time += 0.02) {
      const arm = pose(action, time);
      const upperArm = Math.hypot(arm.elbow.x - arm.shoulder.x, arm.elbow.y - arm.shoulder.y);
      const forearm = Math.hypot(arm.hand.x - arm.elbow.x, arm.hand.y - arm.elbow.y);
      assert.ok(Math.abs(upperArm - ARM_SEGMENTS.upperArm) < 1e-6, `${action}@${time} upper arm`);
      assert.ok(Math.abs(forearm - ARM_SEGMENTS.forearm) < 1e-6, `${action}@${time} forearm`);
      assert.ok(
        Math.hypot(arm.hand.x - arm.shoulder.x, arm.hand.y - arm.shoulder.y) <= ARM_LENGTH + 1e-6,
      );
    }
  }
});

test('the backhand coils across the body and whips out through the head line', () => {
  const { start, end, reach, yOffset } = STAGE_PROFILES.head;
  const coil = pose('head', start * 0.6);
  const impact = pose('head', start);
  assert.ok(coil.hand.x < 500, 'wind-up hand sits on the opposite side of the body');
  assert.ok(coil.twist < 0, 'torso coils away from the target');
  assert.ok(impact.hand.x > coil.hand.x + 60, 'the swing travels across the body');
  assert.ok(impact.twist > 0, 'shoulders rotate into the swing on impact');

  // Active frames keep the visible hand on the collision pose.
  const strike = { x: 500 + reach, y: 470 + yOffset };
  for (let time = start; time <= end + 1e-9; time += 0.01) {
    const arm = pose('head', time);
    assert.ok(Math.hypot(arm.hand.x - strike.x, arm.hand.y - strike.y) <= 13, `ghost hand at ${time}`);
  }

  const follow = pose('head', end + (STAGE_PROFILES.head.duration - end) * 0.25);
  assert.ok(follow.hand.x > strike.x, 'follow-through carries past the contact point');
});

test('the Upper Box loads below the hip and rises overhead', () => {
  const { start, end, duration, reach } = STAGE_PROFILES.upper;
  const load = pose('upper', start * 0.6);
  assert.ok(load.hand.y > 470 + 20, 'the hand loads low before the swing');
  assert.ok(load.hand.x < 500, 'the hand loads behind the fighter');

  let previous = Infinity;
  for (let time = start; time <= end + 1e-9; time += 0.02) {
    const arm = pose('upper', time);
    assert.ok(arm.hand.y < previous + 1e-6, `the hand only rises through the active window (${time})`);
    previous = arm.hand.y;
  }
  const strikeStart = { x: 500 + reach, y: 470 };
  assert.ok(Math.hypot(pose('upper', start).hand.x - strikeStart.x, pose('upper', start).hand.y - strikeStart.y) < 60);

  const followTime = end + (duration - end) * 0.3;
  const standalone = pose('upper', followTime);
  const finisher = pose('upper', followTime, { finisher: true });
  assert.ok(finisher.hand.y < standalone.hand.y, 'the Three Piece finisher finishes higher');
});

test('both poses mirror exactly around the fighter centre', () => {
  for (const action of ['head', 'upper']) {
    for (const time of [0.05, 0.16, 0.24, 0.34]) {
      const right = pose(action, time);
      const left = pose(action, time, { facing: -1 });
      assert.ok(Math.abs(left.hand.x - 500 + (right.hand.x - 500)) < 1e-6, `${action}@${time} x`);
      assert.ok(Math.abs(left.hand.y - right.hand.y) < 1e-6, `${action}@${time} y`);
      assert.ok(Math.abs(left.twist + right.twist) < 1e-6, `${action}@${time} twist`);
      assert.ok(Math.abs(Math.sin(left.handAngle) + Math.sin(right.handAngle)) < 1e-6);
      assert.ok(Math.abs(Math.cos(left.handAngle) - Math.cos(right.handAngle)) < 1e-6);
    }
  }
});

test('the torso twist never exceeds a readable shoulder turn', () => {
  for (const action of ['head', 'upper']) {
    const { duration } = STAGE_PROFILES[action];
    for (let time = 0; time <= duration + 1e-9; time += 0.02) {
      assert.ok(Math.abs(pose(action, time).twist) <= 0.31, `${action}@${time} twist`);
    }
  }
});

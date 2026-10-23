import assert from 'node:assert/strict';
import test from 'node:test';
import {
  attackDamage,
  canAttackHit,
  decideWinner,
  isBlockingHit,
} from '../src/game/combatRules.ts';

const attack = overrides => ({
  x: 100,
  y: 0,
  grounded: true,
  attackFacing: 1,
  attackElapsed: 0.12,
  hitRegistered: false,
  kind: 'light',
  ...overrides,
});

const target = overrides => ({
  x: 200,
  y: 0,
  grounded: true,
  ...overrides,
});

test('a jab connects once while active and in its forward range', () => {
  assert.equal(canAttackHit(attack(), target({ x: 212 })), true);
  assert.equal(canAttackHit(attack({ hitRegistered: true }), target()), false);
});

test('attacks miss behind the locked attack direction and outside their range', () => {
  assert.equal(canAttackHit(attack({ attackFacing: -1 }), target()), false);
  assert.equal(canAttackHit(attack(), target({ x: 213 })), false);
  assert.equal(canAttackHit(attack({ kind: 'heavy', attackElapsed: 0.15 }), target()), false);
});

test('attacks only connect during their active frames', () => {
  assert.equal(canAttackHit(attack({ attackElapsed: 0.07 }), target()), false);
  assert.equal(canAttackHit(attack({ attackElapsed: 0.22 }), target()), false);
  assert.equal(canAttackHit(attack({ kind: 'heavy', attackElapsed: 0.2 }), target()), true);
});

test('a grounded attack cannot hit a jumping fighter crossing overhead', () => {
  assert.equal(canAttackHit(attack(), target({ y: -40, grounded: false })), false);
});

test('blocking only reduces damage when grounded and facing the attacker', () => {
  const frontBlock = { x: 200, facing: -1, blocking: true, grounded: true };
  assert.equal(isBlockingHit(100, frontBlock), true);
  assert.equal(isBlockingHit(100, { ...frontBlock, facing: 1 }), false);
  assert.equal(isBlockingHit(100, { ...frontBlock, grounded: false }), false);
  assert.deepEqual(
    [attackDamage('light', false), attackDamage('light', true), attackDamage('heavy', false), attackDamage('heavy', true)],
    [8, 2, 15, 4],
  );
});

test('round winner follows health, including a tied timeout', () => {
  assert.equal(decideWinner(76, 53), 'player');
  assert.equal(decideWinner(0, 15), 'rival');
  assert.equal(decideWinner(64, 64), 'draw');
});

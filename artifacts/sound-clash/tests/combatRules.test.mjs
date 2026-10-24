import assert from 'node:assert/strict';
import test from 'node:test';
import {
  attackDamage,
  decideWinner,
  findPunchContact,
  getStrikePose,
  isBlockingHit,
} from '../src/game/combatRules.ts';

const attack = overrides => ({
  centerX: 100,
  attackFacing: 1,
  attackElapsed: 0.12,
  hitRegistered: false,
  kind: 'light',
  ...overrides,
});

const fist = overrides => ({
  x: 145,
  y: 500,
  radius: 13,
  ...overrides,
});

const hurtbox = overrides => ({
  centerX: 172,
  body: { left: 145, right: 200, top: 470, bottom: 540 },
  head: { x: 175, y: 440, radius: 22 },
  ...overrides,
});

test('the drawn fist reaches the hurtbox symmetrically in either direction', () => {
  const rightStrike = getStrikePose('light', 100, 498, 1);
  const rightContact = findPunchContact(attack(), rightStrike, hurtbox());
  assert.deepEqual(rightContact, { x: 145, y: 500 });

  const leftStrike = getStrikePose('light', 200, 498, -1);
  const leftContact = findPunchContact(
    attack({ centerX: 200, attackFacing: -1 }),
    leftStrike,
    hurtbox({
      centerX: 128,
      body: { left: 100, right: 155, top: 470, bottom: 540 },
      head: { x: 125, y: 440, radius: 22 },
    }),
  );
  assert.deepEqual(leftContact, { x: 155, y: 500 });
});

test('a punch misses when the fist does not touch the head or torso', () => {
  const contact = findPunchContact(
    attack(),
    fist(),
    hurtbox({
      centerX: 260,
      body: { left: 233, right: 288, top: 470, bottom: 540 },
      head: { x: 263, y: 440, radius: 22 },
    }),
  );
  assert.equal(contact, null);
});

test('a punch cannot hit an opponent behind its locked facing direction', () => {
  assert.equal(findPunchContact(
    attack(),
    fist(),
    hurtbox({
      centerX: 70,
      body: { left: 42, right: 97, top: 470, bottom: 540 },
      head: { x: 67, y: 440, radius: 22 },
    }),
  ), null);
});

test('punches only connect during active frames and register once', () => {
  const active = attack();
  assert.equal(findPunchContact(active, fist(), hurtbox()) !== null, true);
  assert.equal(findPunchContact({ ...active, attackElapsed: 0.07 }, fist(), hurtbox()), null);
  assert.equal(findPunchContact({ ...active, attackElapsed: 0.22 }, fist(), hurtbox()), null);
  assert.equal(findPunchContact({ ...active, hitRegistered: true }, fist(), hurtbox()), null);
  assert.equal(findPunchContact(
    { ...active, kind: 'heavy', attackElapsed: 0.2 },
    getStrikePose('heavy', 100, 498, 1),
    hurtbox(),
  ) !== null, true);
});

test('ground punches miss a jumping hurtbox, while a visible jump punch can connect', () => {
  const raised = hurtbox({
    body: { left: 145, right: 200, top: 385, bottom: 450 },
    head: { x: 175, y: 355, radius: 22 },
  });
  assert.equal(findPunchContact(attack(), fist(), raised), null);

  const jumpStrike = getStrikePose('light', 100, 405, 1);
  assert.notEqual(findPunchContact(attack(), jumpStrike, raised), null);
});

test('impact is placed at the opponent head surface when the fist reaches the head', () => {
  const contact = findPunchContact(
    attack(),
    fist({ x: 145, y: 444 }),
    hurtbox({ head: { x: 172, y: 450, radius: 22 } }),
  );
  assert.notEqual(contact, null);
  assert.ok(Math.abs(Math.hypot(contact.x - 172, contact.y - 450) - 22) < 0.001);
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

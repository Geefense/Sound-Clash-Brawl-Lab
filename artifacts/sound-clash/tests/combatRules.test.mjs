import assert from 'node:assert/strict';
import test from 'node:test';
import {
  attackDamage,
  canBufferComboInput,
  COMBO_BUFFER_OPEN_AT,
  decideWinner,
  getAttackDuration,
  getAttackStage,
  getComboStepAfterAttack,
  findPunchContact,
  getStrikePose,
  isComboFollowup,
  isBlockingHit,
} from '../src/game/combatRules.ts';

const attack = (overrides = {}) => {
  const attempt = {
    centerX: 100,
    attackFacing: 1,
    attackElapsed: 0.12,
    hitRegistered: false,
    kind: 'light',
    ...overrides,
  };
  return {
    ...attempt,
    stage: overrides.stage ?? (attempt.kind === 'heavy' ? 'power' : 'jab1'),
  };
};

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

test('combo input is limited to the jab-jab-power path and a late input window', () => {
  let comboStep = 0;
  const firstJab = getAttackStage(comboStep, 'light', false);
  comboStep = getComboStepAfterAttack(firstJab);
  assert.equal(firstJab, 'jab1');
  assert.equal(canBufferComboInput(comboStep, 'light', COMBO_BUFFER_OPEN_AT, 0.4), true);
  assert.equal(isComboFollowup(comboStep, 'light', true), true);

  const secondJab = getAttackStage(comboStep, 'light', true);
  comboStep = getComboStepAfterAttack(secondJab);
  assert.equal(secondJab, 'jab2');
  assert.equal(canBufferComboInput(comboStep, 'heavy', COMBO_BUFFER_OPEN_AT, 0.4), true);
  assert.equal(isComboFollowup(comboStep, 'heavy', true), true);

  const finisher = getAttackStage(comboStep, 'heavy', true);
  comboStep = getComboStepAfterAttack(finisher);
  assert.equal(finisher, 'power');
  assert.equal(comboStep, 0);
  assert.equal(isComboFollowup(comboStep, 'light', false), false);

  assert.equal(isComboFollowup(1, 'heavy', true), false);
  assert.equal(isComboFollowup(2, 'light', true), false);
  assert.equal(isComboFollowup(1, 'light', false), false);

  assert.equal(canBufferComboInput(1, 'light', COMBO_BUFFER_OPEN_AT - 0.01, 0.4), false);
  assert.equal(canBufferComboInput(1, 'light', 0.2, 0), false);
  assert.equal(canBufferComboInput(1, 'heavy', 0.2, 0.4), false);
  assert.equal(getAttackStage(1, 'light', false), 'jab1');
  assert.equal(getAttackStage(0, 'heavy', false), 'power');
});

test('jab stages have distinct timing and pose while power keeps its longer reach', () => {
  const firstJab = getStrikePose('light', 100, 498, 1, 'jab1');
  const secondJab = getStrikePose('light', 100, 498, 1, 'jab2');
  const power = getStrikePose('heavy', 100, 498, 1, 'power');

  assert.equal(getAttackDuration('jab1'), 0.29);
  assert.equal(getAttackDuration('jab2'), 0.25);
  assert.equal(getAttackDuration('power'), 0.48);
  assert.ok(secondJab.x > firstJab.x);
  assert.ok(secondJab.y < firstJab.y);
  assert.ok(power.x > secondJab.x);
  assert.deepEqual(attackDamage('light', false), 8);
  assert.deepEqual(attackDamage('heavy', false), 15);

  const secondJabContact = findPunchContact(
    attack({ stage: 'jab2', attackElapsed: 0.07 }),
    secondJab,
    hurtbox(),
  );
  assert.notEqual(secondJabContact, null);
  assert.equal(findPunchContact(
    attack({ stage: 'jab2', attackElapsed: 0.2 }),
    secondJab,
    hurtbox(),
  ), null);
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

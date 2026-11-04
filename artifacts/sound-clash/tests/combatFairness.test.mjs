import assert from 'node:assert/strict';
import test from 'node:test';
import { simulateTick } from '../src/game/simulation/SimulationEngine.ts';
import { createMatchState } from '../src/game/simulation/initialState.ts';
import { getHitstopTicks, isBlockingHit } from '../src/game/combatRules.ts';

const empty = { left: false, right: false, jump: false, block: false, light: false, heavy: false };

/** A live round with both fighters in punching range and the CPU disabled. */
const ready = ({ playerX = 500, rivalX = 580, playerFacing = 1 } = {}) => {
  const state = createMatchState(123456789);
  state.status = 'playing';
  state.transitionTimer = 0;
  state.rival.aiWait = 100;
  state.player.x = playerX;
  state.player.facing = playerFacing;
  state.player.attackFacing = playerFacing;
  state.rival.x = rivalX;
  state.rival.facing = -playerFacing;
  state.rival.attackFacing = -playerFacing;
  return state;
};

const punch = (fighter, kind, stage, elapsed = 0.17) => {
  fighter.action = kind;
  fighter.attackStage = stage;
  fighter.attackElapsed = elapsed;
  fighter.actionTime = 0.3;
};

test('simultaneous unblocked power punches trade instead of favouring the player', () => {
  const state = ready();
  punch(state.player, 'heavy', 'power');
  punch(state.rival, 'heavy', 'power');

  const next = simulateTick(state, empty, empty);

  assert.equal(next.rival.health, 85, 'the rival must take the player hit');
  assert.equal(next.player.health, 85, 'the player must take the rival hit');
  assert.equal(next.rival.action, 'hit');
  assert.equal(next.player.action, 'hit');
  assert.equal(next.player.hitRegistered, true);
  assert.equal(next.rival.hitRegistered, true);
  assert.equal(next.hitstop, getHitstopTicks('heavy', false, false));
});

test('trade outcomes are independent of fighter evaluation order', () => {
  const forward = ready({ playerX: 500, rivalX: 580, playerFacing: 1 });
  punch(forward.player, 'head', 'head');
  punch(forward.rival, 'head', 'head');
  const forwardResult = simulateTick(forward, empty, empty);

  // Same exchange mirrored across the stage.
  const mirrored = ready({ playerX: 580, rivalX: 500, playerFacing: -1 });
  punch(mirrored.player, 'head', 'head', 0.17);
  punch(mirrored.rival, 'head', 'head', 0.17);
  const mirroredResult = simulateTick(mirrored, empty, empty);

  assert.equal(forwardResult.player.health, forwardResult.rival.health);
  assert.equal(mirroredResult.player.health, mirroredResult.rival.health);
  assert.equal(forwardResult.player.health, mirroredResult.player.health);
  assert.equal(forwardResult.player.stun, mirroredResult.player.stun);
  assert.equal(
    Math.sign(forwardResult.player.vx),
    -Math.sign(mirroredResult.player.vx),
    'knockback must mirror with the exchange',
  );
  assert.equal(forwardResult.rngState, mirroredResult.rngState);
});

test('a trade cannot silently cancel the second fighter hitstun or combo state', () => {
  const state = ready();
  punch(state.player, 'light', 'jab1', 0.1);
  punch(state.rival, 'heavy', 'power');
  state.player.comboHits = 1;

  const next = simulateTick(state, empty, empty);

  assert.equal(next.rival.health, 92, 'jab still lands');
  assert.equal(next.player.health, 85, 'power still lands');
  assert.equal(next.player.comboHits, 0, 'being hit breaks the player chain');
  assert.equal(next.rival.comboHits, 0, 'a trade breaks both fighters chains');
});

test('hitting an opponent during their own startup is a counterhit', () => {
  for (const [kind, stage, elapsed, expectedDamage] of [
    ['light', 'jab1', 0.09, 11],
    ['heavy', 'power', 0.17, 18],
    ['head', 'head', 0.17, 18],
  ]) {
    const state = ready();
    punch(state.player, kind, stage, elapsed);
    // The rival is winding up a power punch: attackElapsed 0.02 < startup 0.16.
    punch(state.rival, 'heavy', 'power', 0.02);

    const next = simulateTick(state, empty, empty);
    assert.equal(next.rival.health, 100 - expectedDamage, `${kind} counterhit damage`);
    const reaction = next.events.find(event => event.type === 'hit-reaction');
    assert.equal(reaction.counter, true);
    assert.equal(
      next.hitstop,
      getHitstopTicks(kind, false, true),
      'counterhits get the heavier hitstop',
    );
  }
});

test('an opponent in active frames is not a counterhit', () => {
  const state = ready();
  punch(state.player, 'heavy', 'power');
  punch(state.rival, 'heavy', 'power', 0.2);

  const next = simulateTick(state, empty, empty);
  const reaction = next.events.find(event => event.type === 'hit-reaction');
  assert.equal(reaction.counter, undefined);
  assert.equal(next.rival.health, 85);
});

test('block cannot be raised during a committed attack', () => {
  const state = ready();
  punch(state.player, 'heavy', 'power', 0.18);
  punch(state.rival, 'heavy', 'power');

  // The player is mid-swing and presses block; the rival lands clean.
  const next = simulateTick(state, { ...empty, block: true }, empty);

  assert.equal(next.player.blocking, false, 'an attacking fighter cannot guard');
  assert.equal(next.player.health, 85, 'the hit is not chipped');
  assert.equal(next.hitstop, getHitstopTicks('heavy', false, false));
});

test('blocking is only valid grounded, facing the attacker and not attacking', () => {
  const frontBlock = { x: 200, facing: -1, blocking: true, grounded: true };
  assert.equal(isBlockingHit(100, frontBlock), true);
  assert.equal(isBlockingHit(300, frontBlock), false, 'blocking away from the attacker fails');
  assert.equal(isBlockingHit(100, { ...frontBlock, grounded: false }), false);
  assert.equal(isBlockingHit(100, { ...frontBlock, action: 'heavy' }), false);
  assert.equal(isBlockingHit(100, { ...frontBlock, blocking: false }), false);
});

test('simultaneous KOs are a draw and both fighters fall', () => {
  const state = ready();
  state.player.health = 8;
  state.rival.health = 8;
  punch(state.player, 'heavy', 'power');
  punch(state.rival, 'heavy', 'power');

  const impact = simulateTick(state, empty, empty);

  assert.equal(impact.player.health, 0);
  assert.equal(impact.rival.health, 0);
  assert.equal(impact.roundWinner, 'draw');
  assert.equal(impact.playerWins, 0);
  assert.equal(impact.rivalWins, 0);
  assert.equal(impact.status, 'impact-freeze');
  assert.notEqual(impact.ko, null);

  const announced = Array.from({ length: 60 }).reduce(
    state => simulateTick(state, empty, empty),
    impact,
  );
  assert.equal(announced.status, 'ko-announcement');
  assert.equal(announced.player.grounded, true);
  assert.equal(announced.rival.grounded, true);
  assert.equal(announced.player.y, 0);
  assert.equal(announced.rival.y, 0);
});

test('hitstop freezes the clock, positions and RNG deterministically', () => {
  const state = ready();
  punch(state.player, 'light', 'jab1', 0.1);
  const impact = simulateTick(state, empty, empty);
  assert.equal(impact.hitstop, getHitstopTicks('light', false, false));

  let frozen = impact;
  const startX = impact.player.x;
  for (let tick = 0; tick < impact.hitstop; tick++) {
    frozen = simulateTick(frozen, { ...empty, right: true }, empty);
    assert.equal(frozen.player.x, startX, 'movement is held during hitstop');
    assert.equal(frozen.elapsed, impact.elapsed);
    assert.equal(frozen.timeLeft, impact.timeLeft);
    assert.equal(frozen.rngState, impact.rngState);
  }
  assert.equal(frozen.hitstop, 0);
  const resumed = simulateTick(frozen, { ...empty, right: true }, empty);
  assert.ok(resumed.player.x > startX, 'movement resumes after hitstop');
});

test('the rival input contract is honoured for a human-controlled rival', () => {
  const state = ready();
  state.rivalControl = 'human';
  state.rival.aiWait = 0;
  const stages = [];
  let next = state;
  for (let tick = 0; tick < 6; tick++) {
    next = simulateTick(next, empty, { ...empty, light: tick === 0 });
    stages.push(...next.events.filter(event => event.type === 'attack-stage'));
  }
  assert.equal(next.rival.action, 'light', 'the rival executes the supplied input');
  assert.deepEqual(
    stages.map(event => event.fighter),
    ['rival'],
  );
  assert.equal(next.events.some(event => event.type === 'sound'), false);
});

test('AI still drives the rival when rivalControl is ai', () => {
  const state = ready({ rivalX: 620 });
  state.player.x = 500;
  let next = state;
  for (let tick = 0; tick < 120; tick++) next = simulateTick(next, empty, empty);
  assert.ok(
    next.player.health < 100 || next.events.length >= 0,
    'the CPU keeps operating without external input',
  );
  assert.ok(
    next.rival.x < 902,
    'the CPU closes distance on its own',
  );
});

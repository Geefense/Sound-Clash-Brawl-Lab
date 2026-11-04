import assert from 'node:assert/strict';
import test from 'node:test';
import { createFighterState, createMatchState, FIGHTER_IDENTITY, resetFighterForRound } from '../src/game/simulation/initialState.ts';
import { cloneState, simulateTick } from '../src/game/simulation/SimulationEngine.ts';
import {
  ATTACK_SPECS,
  COMBO_RULES,
  MATCH_RULES,
  STAGE_PROFILES,
} from '../src/game/combatConfig.ts';
import { getChainContinuation } from '../src/game/combatRules.ts';

const empty = { left: false, right: false, jump: false, block: false, light: false, heavy: false };

test('every attack kind has a complete typed spec', () => {
  const kinds = ['light', 'heavy', 'head', 'upper'];
  for (const kind of kinds) {
    const spec = ATTACK_SPECS[kind];
    assert.ok(spec, `${kind} must have a spec`);
    assert.ok(spec.damage > 0);
    assert.ok(spec.chipDamage > 0 && spec.chipDamage < spec.damage);
    assert.ok(spec.hitstopTicks > 0);
    assert.ok(spec.cooldown > 0);
    assert.ok(spec.hitstun > 0);
    assert.ok(spec.hitReactionTicks > 0);
  }
});

test('stages stay wired to their attack kinds and keep their frame data', () => {
  const expected = {
    jab1: 'light',
    jab2: 'light',
    power: 'heavy',
    head: 'head',
    upper: 'upper',
  };
  for (const [stage, kind] of Object.entries(expected)) {
    assert.equal(STAGE_PROFILES[stage].attack, kind, `${stage} belongs to ${kind}`);
    assert.ok(STAGE_PROFILES[stage].start < STAGE_PROFILES[stage].end);
    assert.ok(STAGE_PROFILES[stage].end < STAGE_PROFILES[stage].duration);
  }
});

test('the unified chain rules preserve both valid combos', () => {
  assert.deepEqual(getChainContinuation(1, 'light', true), { chain: 'straight', stage: 'jab2' });
  assert.deepEqual(getChainContinuation(1, 'heavy', true), { chain: 'three-piece', stage: 'power' });
  assert.deepEqual(getChainContinuation(2, 'heavy', true), { chain: 'straight', stage: 'power' });
  assert.deepEqual(getChainContinuation(2, 'head', true), { chain: 'straight', stage: 'head' });
  assert.deepEqual(getChainContinuation(2, 'upper', true), { chain: 'three-piece', stage: 'upper' });
  assert.equal(getChainContinuation(0, 'light', true), null);
  assert.equal(getChainContinuation(1, 'light', false), null, 'a closed window cannot chain');
  assert.equal(getChainContinuation(1, 'upper', true), null);
});

test('every combo rule points at a real stage and chain', () => {
  const chains = new Set(['straight', 'three-piece']);
  for (const rule of COMBO_RULES) {
    assert.ok(chains.has(rule.chain));
    assert.ok(rule.step === 1 || rule.step === 2);
    for (const [kind, stage] of Object.entries(rule.kindStages)) {
      assert.ok(ATTACK_SPECS[kind], `${kind} must be a real attack`);
      assert.equal(STAGE_PROFILES[stage].attack, kind, `${stage} must belong to ${kind}`);
    }
  }
});

test('the fighter factory is the single definition of a fresh fighter', () => {
  const fresh = createFighterState();
  assert.equal(fresh.health, 100);
  assert.equal(fresh.action, 'idle');
  assert.equal(fresh.comboChain, null);
  assert.equal(fresh.comboStep, 0);
  assert.equal(fresh.bufferedAttack, null);
  assert.equal(fresh.hitReaction, null);
  assert.equal(fresh.knockdown, null);

  const identityOnly = resetFighterForRound(
    createFighterState({ ...FIGHTER_IDENTITY.player, name: 'SIDEWINDER' }),
    { x: MATCH_RULES.playerStartX, facing: 1 },
  );
  assert.deepEqual(identityOnly, {
    ...createFighterState(),
    ...FIGHTER_IDENTITY.player,
    x: MATCH_RULES.playerStartX,
    facing: 1,
  });
});

test('round reset clears every transient field instead of duplicating them', () => {
  const dirty = createFighterState({
    ...FIGHTER_IDENTITY.player,
    x: 111,
    health: 3,
    action: 'heavy',
    attackStage: 'power',
    actionTime: 0.4,
    stun: 0.3,
    cooldown: 0.6,
    hitRegistered: true,
    comboChain: 'three-piece',
    comboStep: 2,
    comboWindow: 0.5,
    comboHits: 3,
    comboFeedback: 'THREE PIECE!',
    comboFeedbackTime: 1,
    bufferedAttack: 'upper',
    bufferedAttackTimer: 0.3,
    knockdown: { ticks: 12, x: 100, y: -20, direction: 1, heavy: true },
    hitReaction: { kind: 'heavy', region: 'body', direction: 1, age: 4 },
  });
  const reset = resetFighterForRound(dirty, { x: MATCH_RULES.playerStartX, facing: 1 });
  const expected = {
    ...createFighterState(),
    ...FIGHTER_IDENTITY.player,
    x: MATCH_RULES.playerStartX,
    facing: 1,
  };
  assert.deepEqual(reset, expected);
});

test('a finished match resets fighters through the factory, keeping identity and wins', () => {
  const state = createMatchState(42);
  state.status = 'round-transition';
  state.transitionTimer = 0.01;
  state.playerWins = 1;
  state.roundWinner = 'player';
  state.player.health = 4;
  state.player.comboChain = 'straight';
  state.player.comboStep = 2;

  const next = simulateTick(state, empty, empty);
  assert.equal(next.status, 'pre-round');
  assert.equal(next.round, 2);
  assert.equal(next.playerWins, 1);
  assert.equal(next.player.health, 100);
  assert.equal(next.player.name, 'SIDEWINDER');
  assert.equal(next.player.comboChain, null);
  assert.equal(next.player.comboStep, 0);
  assert.equal(next.transitionTimer, MATCH_RULES.preRoundSeconds);
});

test('cloneState deep-copies nested animation state', () => {
  const state = createMatchState(7);
  state.status = 'playing';
  state.rival.aiWait = 100;
  state.player.x = 500;
  state.player.facing = 1;
  state.player.attackFacing = 1;
  state.rival.x = 580;
  state.rival.facing = -1;
  state.rival.health = 20;
  state.player.action = 'heavy';
  state.player.attackStage = 'power';
  state.player.attackElapsed = 0.17;
  state.player.actionTime = 0.3;
  const hit = simulateTick(state, empty, empty);

  const clone = cloneState(hit);
  assert.notEqual(clone.rival.hitReaction, hit.rival.hitReaction);
  clone.rival.hitReaction.age = 99;
  assert.notEqual(hit.rival.hitReaction.age, 99);

  const knocked = cloneState({
    ...hit,
    rival: {
      ...hit.rival,
      knockdown: { ticks: 1, x: 0, y: 0, direction: 1, heavy: true },
    },
  });
  knocked.rival.knockdown.ticks = 5;
  assert.notEqual(knocked.rival.knockdown, hit.rival.knockdown);
});

test('a full best-of-three match still completes with resets and KO announcements', () => {
  let state = createMatchState(2024);
  const roundsSeen = new Set();
  const statusesSeen = new Set();
  let koAnnouncements = 0;
  let healthResets = 0;
  let previousStatus = state.status;

  for (let tick = 0; tick < 40000; tick++) {
    // Keep the pressure on so rounds actually resolve.
    const input = { ...empty, light: tick % 9 === 0, heavy: tick % 23 === 0 };
    state = simulateTick(state, input, empty);
    roundsSeen.add(state.round);
    statusesSeen.add(state.status);
    if (previousStatus !== 'ko-announcement' && state.status === 'ko-announcement') koAnnouncements++;
    if (previousStatus === 'round-transition' && state.status === 'pre-round') {
      if (state.player.health === 100 && state.rival.health === 100) healthResets++;
    }
    previousStatus = state.status;
    if (state.status === 'finished') break;
  }

  assert.equal(state.status, 'finished');
  assert.ok(state.matchWinner === 'player' || state.matchWinner === 'rival');
  assert.equal(Math.max(state.playerWins, state.rivalWins), 2);
  assert.ok(state.playerWins <= 2 && state.rivalWins <= 2);
  assert.ok(roundsSeen.size >= 2, 'the match spans multiple rounds');
  assert.ok(healthResets >= 1, 'health is restored between rounds');
  assert.ok(statusesSeen.has('pre-round'));
  assert.ok(statusesSeen.has('playing'));
  assert.ok(koAnnouncements >= 0);
});

test('seeded randomness is part of the state, not the clock', () => {
  const a = createMatchState(123);
  const b = createMatchState(123);
  const c = createMatchState(124);
  assert.equal(a.rngState, b.rngState);
  assert.notEqual(a.rngState, c.rngState);

  a.status = 'playing';
  b.status = 'playing';
  a.rival.aiWait = 0;
  b.rival.aiWait = 0;
  let nextA = a;
  let nextB = b;
  for (let tick = 0; tick < 30; tick++) {
    nextA = simulateTick(nextA, empty, empty);
    nextB = simulateTick(nextB, empty, empty);
  }
  assert.deepEqual(nextA, nextB);
});

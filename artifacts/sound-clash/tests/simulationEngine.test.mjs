import assert from 'node:assert/strict';
import test from 'node:test';
import { simulateTick } from '../src/game/simulation/SimulationEngine.ts';

const emptyInput = { left: false, right: false, jump: false, block: false, light: false, heavy: false };

const createInitialState = () => ({
  player: {
    x: 378, y: 0, health: 100, facing: 1, color: 0, accent: 0, skin: 0, name: 'P1',
    vx: 0, vy: 0, grounded: true, blocking: false, action: 'idle', actionTime: 0,
    cooldown: 0, stun: 0, aiWait: 0, anim: 0, attackElapsed: 0, hitRegistered: false,
    attackFacing: 1, attackStage: 'jab1', comboStep: 0, comboWindow: 0, bufferedAttack: null,
    comboHits: 0, comboFeedback: '', comboFeedbackTime: 0, walkAroundCooldown: 0
  },
  rival: {
    x: 902, y: 0, health: 100, facing: -1, color: 0, accent: 0, skin: 0, name: 'P2',
    vx: 0, vy: 0, grounded: true, blocking: false, action: 'idle', actionTime: 0,
    cooldown: 0, stun: 0, aiWait: 0.5, anim: 0, attackElapsed: 0, hitRegistered: false,
    attackFacing: -1, attackStage: 'jab1', comboStep: 0, comboWindow: 0, bufferedAttack: null,
    comboHits: 0, comboFeedback: '', comboFeedbackTime: 0, walkAroundCooldown: 0
  },
  timeLeft: 90,
  elapsed: 0,
  status: 'playing',
  winner: null,
  matchWinner: null,
  roundWinner: null,
  round: 1,
  playerWins: 0,
  rivalWins: 0,
  transitionTimer: 0,
  rngState: 123456789,
  events: []
});

test('simulateTick updates position based on input', () => {
  const state = createInitialState();
  const nextState = simulateTick(state, { ...emptyInput, right: true }, emptyInput);

  // FIXED_TIMESTEP is 1/60. Base velocity is 270. Expected dx = 270/60 = 4.5
  assert.ok(nextState.player.vx > 0, 'player should have positive x velocity');
  assert.ok(nextState.player.x > state.player.x, 'player should move right');
  assert.equal(nextState.events.length, 0, 'no events should be emitted for walking');
});

test('simulateTick initiates jump and emits sound event', () => {
  const state = createInitialState();
  const nextState = simulateTick(state, { ...emptyInput, jump: true }, emptyInput);

  assert.equal(nextState.player.grounded, false, 'player should not be grounded');
  assert.ok(nextState.player.vy < 0, 'player should have negative y velocity');
  assert.equal(nextState.events.length, 1, 'should emit one event');
  assert.equal(nextState.events[0].type, 'sound', 'should emit sound event');
  // @ts-ignore - we know it's a sound event
  assert.equal(nextState.events[0].kind, 'jump', 'should emit jump sound');
});

test('simulateTick is deterministic', () => {
  const state = createInitialState();

  // Advance 10 ticks with identical inputs
  let stateA = { ...state, player: { ...state.player }, rival: { ...state.rival } };
  let stateB = { ...state, player: { ...state.player }, rival: { ...state.rival } };

  for (let i = 0; i < 10; i++) {
    stateA = simulateTick(stateA, { ...emptyInput, right: true }, emptyInput);
    stateB = simulateTick(stateB, { ...emptyInput, right: true }, emptyInput);
  }

  // We can't use deepEqual directly because Math.random() is still used in updateRival logic.
  // We check player deterministic state for now.
  assert.equal(stateA.player.x, stateB.player.x, 'player x should be identical');
  assert.equal(stateA.player.vx, stateB.player.vx, 'player vx should be identical');
});


test('simulateTick triggers round transition when health drops to 0', () => {
  const state = createInitialState();
  state.player.health = 5;
  state.rival.health = 100;

  // A heavy attack from rival could instantly end the round
  state.player.health = 0;
  const nextState = simulateTick(state, emptyInput, emptyInput);

  assert.equal(nextState.status, 'round-transition', 'Should transition to wait state');
  assert.equal(nextState.roundWinner, 'rival', 'Rival should win the round');
  assert.equal(nextState.rivalWins, 1, 'Rival wins incremented');
});

test('simulateTick triggers match over when best of 3 is met', () => {
  const state = createInitialState();
  state.player.health = 0;
  state.rival.health = 100;
  state.rivalWins = 1; // already has one win

  const nextState = simulateTick(state, emptyInput, emptyInput);

  assert.equal(nextState.status, 'finished', 'Match should finish');
  assert.equal(nextState.matchWinner, 'rival', 'Rival should win the match');
  assert.equal(nextState.rivalWins, 2, 'Rival gets the final win');
});

test('simulateTick processes round transitions correctly and keeps wins', () => {
  const state = createInitialState();
  state.status = 'round-transition';
  state.transitionTimer = 0.01;
  state.playerWins = 1;
  state.roundWinner = 'player';

  const nextState = simulateTick(state, emptyInput, emptyInput); // transitionTimer becomes < 0 -> resets round

  assert.equal(nextState.status, 'pre-round', 'Should enter pre-round state');
  assert.equal(nextState.playerWins, 1, 'Wins should be preserved');
  assert.equal(nextState.round, 2, 'Round should increment');
  assert.equal(nextState.player.health, 100, 'Health restored');
  assert.equal(nextState.roundWinner, null, 'Round winner cleared');
});

test('draw does not award wins but restarts round', () => {
  const state = createInitialState();
  state.elapsed = 90; // timeout
  state.player.health = 50;
  state.rival.health = 50; // exact same health

  const nextState = simulateTick(state, emptyInput, emptyInput);

  assert.equal(nextState.status, 'round-transition');
  assert.equal(nextState.roundWinner, 'draw');
  assert.equal(nextState.playerWins, 0);
  assert.equal(nextState.rivalWins, 0);
});

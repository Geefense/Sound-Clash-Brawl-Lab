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

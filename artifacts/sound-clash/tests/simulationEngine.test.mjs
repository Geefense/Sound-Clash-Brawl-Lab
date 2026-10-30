import assert from 'node:assert/strict';
import test from 'node:test';
import { simulateTick, IMPACT_FREEZE_TICKS, KNOCKDOWN_TICKS, KO_ANNOUNCEMENT_TICKS } from '../src/game/simulation/SimulationEngine.ts';

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
  roundEndReason: null,
  ko: null,
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

  assert.deepEqual(stateA, stateB);
});


test('simulateTick triggers round transition when health drops to 0', () => {
  const state = createInitialState();
  state.player.health = 5;
  state.rival.health = 100;

  // A heavy attack from rival could instantly end the round
  state.player.health = 0;
  const nextState = simulateTick(state, emptyInput, emptyInput);

  assert.equal(nextState.status, 'impact-freeze', 'Should hold the finishing impact');
  assert.equal(nextState.roundWinner, 'rival', 'Rival should win the round');
  assert.equal(nextState.rivalWins, 1, 'Rival wins incremented');
});

test('simulateTick triggers match over when best of 3 is met', () => {
  const state = createInitialState();
  state.player.health = 0;
  state.rival.health = 100;
  state.rivalWins = 1; // already has one win

  const nextState = simulateTick(state, emptyInput, emptyInput);

  assert.equal(nextState.status, 'impact-freeze', 'Final round also holds the impact');
  const finished = advance(nextState, 117);
  assert.equal(finished.status, 'finished');
  assert.equal(finished.matchWinner, 'rival');
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

function advance(state, ticks, input = emptyInput) {
  for (let i = 0; i < ticks; i++) state = simulateTick(state, input, emptyInput);
  return state;
}

function lethalHit({ final = false, airborne = false, blocked = false } = {}) {
  const state = createInitialState();
  state.player.x = 500;
  state.rival.x = 580;
  state.playerWins = final ? 1 : 0;
  state.player.action = 'heavy';
  state.player.attackStage = 'power';
  state.player.attackElapsed = 0.17;
  state.player.actionTime = 0.3;
  state.rival.health = blocked ? 4 : 15;
  if (airborne) {
    state.rival.y = -12;
    state.rival.grounded = false;
  }
  if (blocked) {
    state.rival.action = 'block';
    state.rival.actionTime = 0.5;
  }
  return simulateTick(state, emptyInput, emptyInput);
}

test('a real lethal hit freezes impact for 9 ticks and disables combat and AI', () => {
  const impact = lethalHit();
  assert.equal(impact.status, 'impact-freeze');
  assert.equal(impact.rival.health, 0);
  assert.equal(impact.playerWins, 1);
  assert.equal(impact.roundEndReason, 'ko');
  assert.equal(impact.events.filter(e => e.kind === 'hit').length, 1);
  assert.equal(impact.events.filter(e => e.kind === 'ko').length, 0);
  const heldInput = { left: true, right: false, jump: true, block: true, light: true, heavy: true };
  const frozen = advance(impact, IMPACT_FREEZE_TICKS - 1, heldInput);
  assert.equal(frozen.status, 'impact-freeze');
  assert.deepEqual(frozen.player, impact.player);
  assert.deepEqual(frozen.rival, impact.rival);
  assert.equal(frozen.elapsed, impact.elapsed);
  assert.equal(frozen.timeLeft, impact.timeLeft);
  assert.equal(frozen.rngState, impact.rngState);
  assert.deepEqual(frozen.events, []);
  assert.equal(advance(frozen, 1).status, 'knockdown');
});

test('knockdown recoils, lands in 36 ticks and stays down through a 72-tick announcement', () => {
  const impact = lethalHit({ airborne: true });
  const falling = advance(impact, IMPACT_FREEZE_TICKS + 18);
  assert.equal(falling.status, 'knockdown');
  assert.ok(falling.rival.x > impact.rival.x);
  assert.ok(falling.rival.y < 0);
  assert.equal(falling.rival.grounded, false);
  const beforeLanding = advance(impact, IMPACT_FREEZE_TICKS + KNOCKDOWN_TICKS - 1);
  assert.equal(beforeLanding.status, 'knockdown');
  const landed = advance(beforeLanding, 1);
  assert.equal(landed.status, 'ko-announcement');
  assert.equal(landed.rival.y, 0);
  assert.equal(landed.rival.grounded, true);
  assert.equal(landed.rival.vx, 0);
  assert.equal(landed.rival.vy, 0);
  assert.deepEqual(landed.events, [{ type: 'sound', kind: 'ko' }]);
  const announcing = advance(landed, KO_ANNOUNCEMENT_TICKS - 1);
  assert.equal(announcing.status, 'ko-announcement');
  assert.deepEqual(announcing.rival, landed.rival);
  assert.deepEqual(announcing.events, []);
  const transition = advance(announcing, 1);
  assert.equal(transition.status, 'round-transition');
  assert.equal(transition.playerWins, 1);
  const reset = advance(transition, 181);
  assert.equal(reset.status, 'pre-round');
  assert.equal(reset.round, 2);
  assert.equal(reset.playerWins, 1);
  assert.equal(reset.rival.health, 100);
  assert.equal(reset.ko, null);
  assert.equal(reset.roundEndReason, null);
});

test('match-winning KO announces before results and never scores twice', () => {
  let state = lethalHit({ final: true });
  let sounds = 0;
  for (let tick = 1; tick <= 117; tick++) {
    state = simulateTick(state, emptyInput, emptyInput);
    sounds += state.events.filter(e => e.kind === 'ko').length;
    assert.equal(state.playerWins, 2);
    if (tick < 117) {
      assert.notEqual(state.status, 'finished');
      assert.equal(state.matchWinner, null);
    }
  }
  assert.equal(sounds, 1);
  assert.equal(state.status, 'finished');
  assert.equal(state.matchWinner, 'player');
  assert.equal(state.winner, 'player');
  assert.equal(advance(state, 100).playerWins, 2);
  assert.equal(advance(state, 100).rival.grounded, true);
});

test('timeouts including draws and match wins skip KO phases and sound', () => {
  for (const [health, wins, status] of [[50, 0, 'round-transition'], [100, 0, 'round-transition'], [100, 1, 'finished']]) {
    const state = createInitialState();
    state.elapsed = 90;
    state.player.health = health;
    state.rival.health = 50;
    state.playerWins = wins;
    const ended = simulateTick(state, emptyInput, emptyInput);
    assert.equal(ended.status, status);
    assert.equal(ended.roundEndReason, 'timeout');
    assert.equal(ended.ko, null);
    assert.equal(ended.events.some(e => e.kind === 'ko'), false);
    if (health === 50) {
      assert.equal(ended.roundWinner, 'draw');
      assert.equal(advance(ended, 181).round, 1);
    }
  }
});

test('blocked chip damage can KO and double KO remains a drawn replay', () => {
  assert.equal(lethalHit({ blocked: true }).status, 'impact-freeze');
  const state = createInitialState();
  state.player.health = 0;
  state.rival.health = 0;
  const impact = simulateTick(state, emptyInput, emptyInput);
  assert.equal(impact.roundWinner, 'draw');
  const transition = advance(impact, 117);
  assert.equal(transition.playerWins, 0);
  assert.equal(transition.rivalWins, 0);
  assert.equal(transition.player.grounded, true);
  assert.equal(transition.rival.grounded, true);
  assert.equal(advance(transition, 181).round, 1);
});

test('full KO sequence is deterministic and does not mutate its input', () => {
  const impact = lethalHit();
  const original = structuredClone(impact);
  let a = impact;
  let b = structuredClone(impact);
  for (let tick = 0; tick < 400; tick++) {
    a = simulateTick(a, emptyInput, emptyInput);
    b = simulateTick(b, emptyInput, emptyInput);
    assert.deepEqual(a, b);
  }
  assert.deepEqual(impact, original);
});


test('nonlethal hits preserve the normal combat flow without a finish sequence', () => {
  const state = createInitialState();
  state.player.x = 500;
  state.rival.x = 580;
  state.player.action = 'heavy';
  state.player.attackStage = 'power';
  state.player.attackElapsed = 0.17;
  state.player.actionTime = 0.3;
  const hit = simulateTick(state, emptyInput, emptyInput);
  assert.equal(hit.status, 'playing');
  assert.equal(hit.rival.health, 85);
  assert.equal(hit.rival.action, 'hit');
  assert.equal(hit.rival.vx, 420);
  assert.equal(hit.ko, null);
  assert.equal(hit.roundEndReason, null);
});

test('a defeated player recoils left and KO timing leaves the clock and RNG unchanged', () => {
  const state = createInitialState();
  state.player.health = 0;
  const impact = simulateTick(state, emptyInput, emptyInput);
  const landed = advance(impact, 45);
  assert.ok(landed.player.x < impact.player.x);
  assert.equal(landed.player.y, 0);
  assert.equal(landed.player.grounded, true);
  const ended = advance(landed, 72);
  assert.equal(ended.elapsed, impact.elapsed);
  assert.equal(ended.timeLeft, impact.timeLeft);
  assert.equal(ended.rngState, impact.rngState);
});

test('clean hits publish cosmetic metadata without changing damage or hit mechanics', () => {
  for (const kind of ['light', 'heavy']) {
    for (const head of [false, true]) {
      const state = createInitialState();
      state.player.x = 500;
      state.rival.x = 580;
      state.player.action = kind;
      state.player.attackStage = kind === 'light' ? 'jab1' : 'power';
      state.player.attackElapsed = 0.17;
      state.player.actionTime = 0.3;
      if (head) {
        state.player.y = -40;
        state.player.grounded = false;
      }
      const next = simulateTick(state, emptyInput, emptyInput);
      const reaction = next.events.find(e => e.type === 'hit-reaction');
      assert.deepEqual(reaction, { type: 'hit-reaction', fighter: 'rival', kind, region: head ? 'head' : 'body', direction: 1 });
      assert.equal(next.rival.health, kind === 'light' ? 92 : 85);
      assert.equal(next.rival.stun, 0.28);
      assert.equal(next.player.hitRegistered, true);
      assert.equal(next.status, 'playing');
    }
  }
  assert.equal(lethalHit({ blocked: true }).events.some(e => e.type === 'hit-reaction'), false);
});

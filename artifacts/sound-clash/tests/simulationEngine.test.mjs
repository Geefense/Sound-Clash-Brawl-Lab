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
    comboHits: 0, comboFeedback: '', comboFeedbackTime: 0, walkAroundCooldown: 0,
    threePieceStep: 0, threePieceWindow: 0, knockdown: null
  },
  rival: {
    x: 902, y: 0, health: 100, facing: -1, color: 0, accent: 0, skin: 0, name: 'P2',
    vx: 0, vy: 0, grounded: true, blocking: false, action: 'idle', actionTime: 0,
    cooldown: 0, stun: 0, aiWait: 0.5, anim: 0, attackElapsed: 0, hitRegistered: false,
    attackFacing: -1, attackStage: 'jab1', comboStep: 0, comboWindow: 0, bufferedAttack: null,
    comboHits: 0, comboFeedback: '', comboFeedbackTime: 0, walkAroundCooldown: 0,
    threePieceStep: 0, threePieceWindow: 0, knockdown: null
  },
  timeLeft: 90,
  elapsed: 0,
  status: 'playing',
  winner: null,
  matchWinner: null,
  roundWinner: null,
  roundEndReason: null,
  threePieceKO: false,
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
        state.player.y = kind === 'heavy' ? -64 : -40;
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

test('heavy midsection hits mirror correctly and preserve blocking and combat values', () => {
  for (const direction of [1, -1]) {
    for (const blocked of [false, true]) {
      const state = createInitialState();
      state.player.x = direction === 1 ? 500 : 580;
      state.rival.x = direction === 1 ? 580 : 500;
      state.player.facing = state.player.attackFacing = direction;
      state.rival.facing = -direction;
      Object.assign(state.player, { action: 'heavy', attackStage: 'power', attackElapsed: 0.17, actionTime: 0.3 });
      if (blocked) Object.assign(state.rival, { action: 'block', actionTime: 0.5 });
      const next = simulateTick(state, emptyInput, emptyInput);
      assert.equal(next.rival.health, blocked ? 96 : 85);
      assert.equal(next.rival.stun, blocked ? 0.12 : 0.28);
      assert.equal(next.rival.actionTime, blocked ? 0.16 : 0.29);
      assert.equal(next.rival.vx, direction * (blocked ? 145 : 420));
      const spark = next.events.find(e => e.type === 'spark');
      const shake = next.events.find(e => e.type === 'shake');
      assert.equal(spark.count, blocked ? 8 : 25);
      assert.equal(shake.intensity, blocked ? 65 : 160);
      if (!blocked) assert.equal(next.events.find(e => e.type === 'hit-reaction').region, 'body');
      assert.deepEqual(next, simulateTick(structuredClone(state), emptyInput, emptyInput));
    }
  }
});

test('lower heavy punch misses a raised opponent but connects when both are airborne', () => {
  for (const followsJump of [false, true]) {
    const state = createInitialState();
    state.player.x = 500;
    state.rival.x = 580;
    Object.assign(state.player, { action: 'heavy', attackStage: 'power', attackElapsed: 0.17, actionTime: 0.3 });
    Object.assign(state.rival, { y: -100, grounded: false });
    if (followsJump) Object.assign(state.player, { y: -100, grounded: false });
    const next = simulateTick(state, emptyInput, emptyInput);
    assert.equal(next.rival.health, followsJump ? 85 : 100);
    assert.equal(next.player.hitRegistered, followsJump);
    if (followsJump) assert.equal(next.events.find(e => e.type === 'hit-reaction').region, 'body');
  }
});

test('buffered jab-jab-heavy combo still advances into a midsection power finisher', () => {
  let state = createInitialState();
  // Keep CPU out of range to isolate the existing attack buffer and stage timings.
  state.rival.aiWait = 100;
  state = simulateTick(state, { ...emptyInput, light: true }, emptyInput);
  assert.equal(state.player.attackStage, 'jab1');
  state = advance(state, 9);
  state = simulateTick(state, { ...emptyInput, light: true }, emptyInput);
  assert.equal(state.player.bufferedAttack, 'light');
  while (state.player.attackStage === 'jab1') state = advance(state, 1);
  assert.equal(state.player.attackStage, 'jab2');
  state = advance(state, 9);
  state = simulateTick(state, { ...emptyInput, heavy: true }, emptyInput);
  assert.equal(state.player.bufferedAttack, 'heavy');
  while (state.player.attackStage === 'jab2') state = advance(state, 1);
  assert.equal(state.player.attackStage, 'power');
  assert.equal(state.player.action, 'heavy');
  assert.equal(state.player.actionTime, 0.48);
  assert.equal(state.player.comboStep, 0);
});

test('animated first and buffered second jab both land once with unchanged damage', () => {
  let state = createInitialState();
  state.player.x = 500;
  state.rival.x = 580;
  state.rival.aiWait = 100;
  const stages = [];
  let hitSounds = 0;
  for (let tick = 0; tick < 40; tick++) {
    state = simulateTick(state, { ...emptyInput, light: tick === 0 || tick === 10 }, emptyInput);
    for (const event of state.events) {
      if (event.type === 'attack-stage' && event.fighter === 'player') stages.push(event.stage);
      if (event.type === 'sound' && event.kind === 'hit') hitSounds++;
    }
  }
  assert.deepEqual(stages, ['jab1', 'jab2']);
  assert.equal(hitSounds, 2);
  assert.equal(state.rival.health, 84);
  assert.equal(state.player.comboHits, 2);
});

function playThreePiece({ health = 100, direction = 1, blockStage = null, middle = 'heavy' } = {}) {
  let state = createInitialState();
  state.player.x = direction === 1 ? 500 : 580;
  state.rival.x = direction === 1 ? 580 : 500;
  state.player.facing = state.player.attackFacing = direction;
  state.rival.facing = -direction;
  state.rival.health = health;
  state.rival.aiWait = 100;
  let sentMiddle = false;
  let sentUpper = false;
  const events = [];
  for (let tick = 0; tick < 130; tick++) {
    const input = { ...emptyInput, light: tick === 0 };
    if (!sentMiddle && state.player.action === 'light' && state.player.attackElapsed >= 0.15) {
      input[middle] = true;
      sentMiddle = true;
    }
    if (!sentUpper && state.player.action === middle && state.player.attackElapsed >= 0.2) {
      input.upper = true;
      sentUpper = true;
    }
    if (state.player.action === blockStage) {
      state.rival.action = 'block';
      state.rival.actionTime = 0.5;
      state.rival.stun = 0;
    }
    state = simulateTick(state, input, emptyInput);
    events.push(...state.events);
    if (state.events.some(e => e.type === 'three-piece')) return { state, events };
  }
  return { state, events };
}

test('connected J-L-I launches a living opponent without KO or scoring, in either direction', () => {
  for (const direction of [1, -1]) {
    const { state, events } = playThreePiece({ direction });
    assert.equal(state.rival.health, 62);
    assert.equal(state.status, 'playing');
    assert.equal(state.playerWins, 0);
    assert.equal(state.rivalWins, 0);
    assert.equal(state.threePieceKO, false);
    assert.equal(state.player.comboFeedback, 'THREE PIECE!');
    assert.deepEqual(events.filter(e => e.type === 'attack-stage').map(e => e.stage), ['jab1', 'power', 'upper']);
    assert.deepEqual(events.filter(e => e.type === 'three-piece'), [{ type: 'three-piece', fighter: 'player', ko: false }]);
    assert.equal(state.rival.knockdown.direction, direction);
    const airborne = advance(state, 18);
    assert.ok(airborne.rival.y < -70);
    assert.equal(airborne.rival.grounded, false);
    assert.ok((airborne.rival.x - state.rival.x) * direction > 0);
    const landed = advance(state, 36);
    assert.equal(landed.rival.y, 0);
    assert.equal(landed.rival.grounded, true);
    assert.equal(landed.rival.action, 'down');
    assert.equal(landed.events.filter(e => e.type === 'shake').length, 1);
    assert.equal(advance(state, 37).events.filter(e => e.type === 'shake').length, 0);
    const recovered = advance(state, 48);
    assert.equal(recovered.rival.knockdown, null);
    assert.equal(recovered.rival.action, 'idle');
    assert.equal(recovered.rival.health, 62);
  }
});

test('standalone Upper Box staggers and snaps the head but never launches a living fighter', () => {
  const state = createInitialState();
  state.player.x = 500;
  state.rival.x = 580;
  state.rival.aiWait = 100;
  let next = simulateTick(state, { ...emptyInput, upper: true }, emptyInput);
  for (let tick = 0; tick < 18 && next.rival.health === 100; tick++) next = advance(next, 1);
  assert.equal(next.rival.health, 85);
  assert.equal(next.rival.action, 'hit');
  assert.equal(next.rival.stun, 0.34);
  assert.equal(next.rival.knockdown, null);
  assert.equal(next.events.find(e => e.type === 'hit-reaction').region, 'head');
  assert.equal(next.events.some(e => e.type === 'three-piece'), false);
  assert.equal(advance(next, 30).rival.knockdown, null);
  assert.equal(next.player.comboFeedback.includes('HIM DUN'), false);
});

test('blocking any part of Three Piece prevents the launch and special announcement', () => {
  for (const blockStage of ['light', 'heavy', 'upper']) {
    const { state, events } = playThreePiece({ blockStage });
    assert.equal(events.some(e => e.type === 'three-piece'), false);
    assert.equal(state.rival.knockdown, null);
    assert.equal(state.threePieceKO, false);
    assert.notEqual(state.player.comboFeedback, 'HIM DUN!');
  }
});

test('a head-heavy in place of the body shot does not qualify for Three Piece', () => {
  const { state, events } = playThreePiece({ middle: 'head' });
  assert.equal(events.some(e => e.type === 'three-piece'), false);
  assert.equal(state.rival.knockdown, null);
});

test('lethal Three Piece announces HIM DUN only after real KO, preserving all KO ticks and first-to-two', () => {
  const { state: impact, events } = playThreePiece({ health: 38 });
  assert.equal(impact.rival.health, 0);
  assert.equal(impact.threePieceKO, true);
  assert.equal(impact.player.comboFeedback, 'HIM DUN!');
  assert.equal(impact.status, 'impact-freeze');
  assert.equal(impact.playerWins, 1);
  assert.equal(events.filter(e => e.type === 'three-piece' && e.ko).length, 1);
  assert.equal(advance(impact, 8).status, 'impact-freeze');
  assert.equal(advance(impact, 9).status, 'knockdown');
  assert.equal(advance(impact, 45).status, 'ko-announcement');
  assert.equal(advance(impact, 116).status, 'ko-announcement');
  assert.equal(advance(impact, 117).status, 'round-transition');
  const final = structuredClone(impact);
  final.playerWins = 2;
  assert.equal(advance(final, 116).matchWinner, null);
  assert.equal(advance(final, 117).matchWinner, 'player');
  const reset = advance(impact, 298);
  assert.equal(reset.threePieceKO, false);
  assert.equal(reset.player.threePieceStep, 0);
  assert.equal(reset.rival.knockdown, null);
});

test('misses, wrong intervening attacks, and expired windows cannot produce a Three Piece', () => {
  for (const failure of ['miss', 'expired', 'wrong', 'interrupted']) {
    const state = createInitialState();
    state.player.x = 500;
    state.rival.x = 580;
    state.rival.aiWait = 100;
    state.player.threePieceStep = 2;
    state.player.threePieceWindow = failure === 'expired' ? 0.001 : 0.72;
    if (failure === 'miss') state.rival.x = 850;
    const input = failure === 'wrong' ? { ...emptyInput, head: true } : { ...emptyInput, upper: true };
    if (failure === 'interrupted') {
      state.player.action = 'hit';
      state.player.actionTime = state.player.stun = 0.3;
      state.player.threePieceStep = 0;
    }
    let next = simulateTick(state, input, emptyInput);
    let launch = false;
    for (let tick = 0; tick < 55; tick++) {
      next = advance(next, 1);
      launch ||= next.events.some(e => e.type === 'three-piece');
    }
    assert.equal(launch, false, failure);
    assert.equal(next.rival.knockdown, null);
  }
});

test('Three Piece knockdown replay is deterministic and ignores attacks while down', () => {
  const { state } = playThreePiece();
  const original = structuredClone(state);
  let a = state;
  let b = structuredClone(state);
  for (let tick = 0; tick < 48; tick++) {
    const input = { ...emptyInput, heavy: true, upper: true, light: true };
    a = simulateTick(a, input, emptyInput);
    b = simulateTick(b, input, emptyInput);
    assert.deepEqual(a, b);
    if (tick < 47) assert.equal(a.rival.health, 62);
  }
  assert.deepEqual(state, original);
});

test('head-heavy input connects with the head, preserving heavy damage and blocking', () => {
  for (const direction of [1, -1]) {
    for (const blocked of [false, true]) {
      let state = createInitialState();
      state.player.x = direction === 1 ? 500 : 580;
      state.rival.x = direction === 1 ? 580 : 500;
      state.player.facing = state.player.attackFacing = direction;
      state.rival.facing = -direction;
      state.rival.aiWait = 100;
      if (blocked) Object.assign(state.rival, { action: 'block', actionTime: 0.6 });
      state = simulateTick(state, { ...emptyInput, head: true }, emptyInput);
      assert.equal(state.player.attackStage, 'head');
      for (let tick = 0; tick < 20 && state.rival.health === 100; tick++) state = advance(state, 1);
      assert.equal(state.rival.health, blocked ? 96 : 85);
      assert.equal(state.rival.vx, direction * (blocked ? 145 : 420));
      assert.equal(state.rival.stun, blocked ? 0.12 : 0.28);
      if (!blocked) assert.equal(state.events.find(e => e.type === 'hit-reaction').region, 'head');
      assert.equal(state.rival.knockdown, null);
    }
  }
});

test('an actual incoming hit interrupts Three Piece confirmation', () => {
  const state = createInitialState();
  state.player.x = 500;
  state.rival.x = 580;
  state.player.threePieceStep = 2;
  state.player.threePieceWindow = 0.72;
  Object.assign(state.rival, { action: 'heavy', attackStage: 'power', attackFacing: -1, attackElapsed: 0.17, actionTime: 0.3, aiWait: 100 });
  const next = simulateTick(state, emptyInput, emptyInput);
  assert.equal(next.player.health, 85);
  assert.equal(next.player.threePieceStep, 0);
  assert.equal(next.player.threePieceWindow, 0);
  assert.equal(next.player.action, 'hit');
});

test('the legacy two-jab combo can still buffer K as a heavy head finisher', () => {
  let state = createInitialState();
  state.player.x = 500;
  state.rival.x = 580;
  state.rival.aiWait = 100;
  let second = false;
  let finisher = false;
  const stages = [];
  for (let tick = 0; tick < 80; tick++) {
    const input = { ...emptyInput, light: tick === 0 };
    if (!second && state.player.attackStage === 'jab1' && state.player.attackElapsed >= 0.15) {
      input.light = true;
      second = true;
    }
    if (!finisher && state.player.attackStage === 'jab2' && state.player.attackElapsed >= 0.15) {
      input.head = true;
      finisher = true;
    }
    state = simulateTick(state, input, emptyInput);
    stages.push(...state.events.filter(e => e.type === 'attack-stage').map(e => e.stage));
  }
  assert.deepEqual(stages, ['jab1', 'jab2', 'head']);
  assert.equal(state.rival.health, 69);
  assert.equal(state.rival.knockdown, null);
  assert.equal(state.playerWins, 0);
});

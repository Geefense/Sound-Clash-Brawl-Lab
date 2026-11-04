import assert from 'node:assert/strict';
import test from 'node:test';
import {
  IMPACT_FREEZE_TICKS,
  KNOCKDOWN_TICKS,
  simulateTick,
} from '../src/game/simulation/SimulationEngine.ts';
import { createMatchState } from '../src/game/simulation/initialState.ts';
import { ATTACK_SPECS } from '../src/game/combatConfig.ts';
import { getKnockdownPose as geometryKnockdownPose } from '../src/game/fighterGeometry.ts';
import { getKnockdownPose as visualKnockdownPose } from '../src/game/visualReactions.ts';
import { getHitReactionPose } from '../src/game/visualReactions.ts';

const empty = { left: false, right: false, jump: false, block: false, light: false, heavy: false };

const ready = () => {
  const state = createMatchState(424242);
  state.status = 'playing';
  state.transitionTimer = 0;
  state.rival.aiWait = 100;
  state.player.x = 500;
  state.player.facing = 1;
  state.player.attackFacing = 1;
  state.rival.x = 580;
  state.rival.facing = -1;
  state.rival.attackFacing = -1;
  return state;
};

const attackWith = (kind, stage, elapsed) => {
  const state = ready();
  state.player.action = kind;
  state.player.attackStage = stage;
  state.player.attackElapsed = elapsed;
  state.player.actionTime = 0.3;
  return state;
};

const advance = (state, ticks) => {
  let next = state;
  for (let tick = 0; tick < ticks; tick++) next = simulateTick(next, empty, empty);
  return next;
};

test('every attack weight freezes the world for its own hitstop', () => {
  const cases = [
    ['light', 'jab1', 0.1, 3],
    ['heavy', 'power', 0.17, 5],
    ['head', 'head', 0.17, 6],
    ['upper', 'upper', 0.2, 7],
  ];
  const stops = [];
  for (const [kind, stage, elapsed, expected] of cases) {
    const impact = simulateTick(attackWith(kind, stage, elapsed), empty, empty);
    assert.equal(impact.hitstop, expected, `${kind} hitstop`);
    assert.equal(impact.hitstop, ATTACK_SPECS[kind].hitstopTicks);
    stops.push(impact.hitstop);
  }
  assert.deepEqual(stops, [3, 5, 6, 7], 'jab < TUMP < BOX < Upper Box by impact weight');
});

test('a blocked hit gets a shorter freeze and chip damage', () => {
  const state = attackWith('heavy', 'power', 0.17);
  state.rival.action = 'block';
  state.rival.actionTime = 0.5;
  state.rival.blocking = true;

  const impact = simulateTick(state, empty, empty);
  assert.equal(impact.hitstop, ATTACK_SPECS.heavy.blockedHitstopTicks);
  assert.equal(impact.rival.health, 96);
  assert.equal(impact.rival.hitReaction, null, 'blocked hits do not recoil');
});

test('hitstop holds the hit reaction pose until combat resumes', () => {
  const impact = simulateTick(attackWith('heavy', 'power', 0.17), empty, empty);
  assert.equal(impact.player.hitReaction, null);
  assert.ok(impact.rival.hitReaction, 'the defender owns a reaction in state');
  assert.equal(impact.rival.hitReaction.age, 0);
  assert.equal(getHitReactionPose(impact.rival.hitReaction).shoulderX !== 0, true);

  let held = impact;
  for (let tick = 0; tick < impact.hitstop; tick++) {
    held = simulateTick(held, empty, empty);
    assert.equal(held.rival.hitReaction.age, 0, 'the recoil pose is frozen during hitstop');
  }
  const resumed = simulateTick(held, empty, empty);
  assert.equal(resumed.rival.hitReaction.age, 1);
  const expired = advance(resumed, ATTACK_SPECS.heavy.hitReactionTicks);
  assert.equal(expired.rival.hitReaction, null);
});

test('attack recovery is differentiated per move', () => {
  assert.ok(
    ATTACK_SPECS.light.cooldown < ATTACK_SPECS.heavy.cooldown,
    'the jab recovers faster than the TUMP',
  );
  assert.ok(
    ATTACK_SPECS.upper.cooldown > ATTACK_SPECS.head.cooldown,
    'Upper Box has the longest recovery',
  );
  const jabStart = simulateTick(ready(), { ...empty, light: true }, empty);
  const tumpStart = simulateTick(ready(), { ...empty, heavy: true }, empty);
  assert.equal(jabStart.player.action, 'light');
  assert.equal(tumpStart.player.action, 'heavy');
  assert.ok(
    jabStart.player.cooldown < tumpStart.player.cooldown,
    'the jab commits for less recovery than the TUMP',
  );
});

/** Drive a real jab -> TUMP -> Upper Box sequence through inputs. */
function playThreePiece({ health = 100 } = {}) {
  let state = ready();
  state.player.x = 500;
  state.rival.x = 580;
  state.rival.health = health;
  state.rival.aiWait = 100;
  let sentMiddle = false;
  let sentUpper = false;
  const events = [];
  for (let tick = 0; tick < 180; tick++) {
    const input = { ...empty, light: tick === 0 };
    if (!sentMiddle && state.player.action === 'light' && state.player.attackElapsed >= 0.15) {
      input.heavy = true;
      sentMiddle = true;
    }
    if (!sentUpper && state.player.action === 'heavy' && state.player.attackElapsed >= 0.2) {
      input.upper = true;
      sentUpper = true;
    }
    state = simulateTick(state, input, empty);
    events.push(...state.events);
    if (state.events.some(event => event.type === 'three-piece')) return { state, events };
  }
  return { state, events };
}

test('Upper Box alone never launches, while the jab -> TUMP -> Upper Box finisher does', () => {
  // Standalone Upper Box: no chain state, no launch.
  let standalone = ready();
  standalone = simulateTick(standalone, { ...empty, upper: true }, empty);
  let standaloneHit = standalone;
  for (let tick = 0; tick < 30 && standaloneHit.rival.health === 100; tick++) {
    standaloneHit = advance(standaloneHit, 1);
  }
  assert.equal(standaloneHit.rival.health, 85);
  assert.equal(standaloneHit.rival.knockdown, null);
  assert.equal(standaloneHit.player.comboFeedback.includes('DUN'), false);

  // Full chain: launches a living opponent with a dramatic arc.
  const { state, events } = playThreePiece();
  assert.equal(state.rival.health, 62);
  assert.equal(state.status, 'playing');
  assert.equal(state.player.comboFeedback, 'THREE PIECE!');
  assert.equal(state.player.comboHits, 3);
  assert.deepEqual(
    events.filter(event => event.type === 'attack-stage').map(event => event.stage),
    ['jab1', 'power', 'upper'],
  );
  assert.notEqual(state.rival.knockdown, null);

  const airborne = advance(state, state.hitstop + 18);
  assert.ok(airborne.rival.y < -70, 'the finisher launches the body');
  assert.equal(airborne.rival.grounded, false);
  const landed = advance(state, state.hitstop + 36);
  assert.equal(landed.rival.y, 0);
  assert.equal(landed.rival.grounded, true);
  assert.equal(landed.rival.action, 'down');
});

test('HIM DUN only appears when the finisher actually knocks out', () => {
  const { state } = playThreePiece({ health: 38 });
  assert.equal(state.rival.health, 0);
  assert.equal(state.threePieceKO, true);
  assert.equal(state.player.comboFeedback, 'HIM DUN!');
  assert.equal(state.status, 'impact-freeze');
  assert.equal(state.playerWins, 1);
});

test('the KO survivor reacts instead of freezing mid-punch', () => {
  const state = ready();
  state.rival.health = 15;
  state.player.action = 'heavy';
  state.player.attackStage = 'power';
  state.player.attackElapsed = 0.17;
  state.player.actionTime = 0.3;

  const impact = simulateTick(state, empty, empty);
  assert.equal(impact.status, 'impact-freeze');
  assert.equal(impact.player.action, 'heavy', 'the impact freeze itself still holds the pose');

  const relaxed = advance(impact, IMPACT_FREEZE_TICKS + 1);
  assert.equal(relaxed.player.action, 'idle');
  assert.equal(relaxed.player.actionTime, 0);
  assert.equal(relaxed.player.attackElapsed, impact.player.attackElapsed, 'the frozen attack timeline stays put');

  const duringCinematic = advance(relaxed, 20);
  assert.equal(duringCinematic.player.action, 'idle');
  assert.ok(duringCinematic.player.anim > relaxed.player.anim, 'the survivor keeps breathing');
});

test('KO displacement has exactly one owner: the simulation', () => {
  assert.equal(
    visualKnockdownPose,
    geometryKnockdownPose,
    'the renderer and the simulation share one curve implementation',
  );

  const state = ready();
  state.rival.health = 15;
  state.player.action = 'heavy';
  state.player.attackStage = 'power';
  state.player.attackElapsed = 0.17;
  state.player.actionTime = 0.3;
  const impact = simulateTick(state, empty, empty);
  const start = impact.ko.rival;

  for (const ticks of [12, 25, IMPACT_FREEZE_TICKS + KNOCKDOWN_TICKS]) {
    const progressed = advance(impact, ticks);
    const pose = geometryKnockdownPose(
      ticks,
      IMPACT_FREEZE_TICKS,
      KNOCKDOWN_TICKS,
      start.direction,
      start.heavy,
    );
    assert.ok(
      Math.abs(progressed.rival.x - (start.x + pose.x)) < 1e-9,
      `x is driven by the shared curve at tick ${ticks}`,
    );
    assert.ok(Math.abs(progressed.rival.y - pose.y) < 1e-9, `y is driven by the shared curve at tick ${ticks}`);
  }
});

test('a press during hitstop is buffered instead of swallowed', () => {
  const impact = simulateTick(attackWith('heavy', 'power', 0.17), empty, empty);
  assert.ok(impact.hitstop > 0);

  const pressed = simulateTick(impact, { ...empty, upper: true }, empty);
  assert.equal(pressed.player.bufferedAttack, 'upper');
  assert.equal(pressed.player.action, 'heavy', 'the freeze still holds the pose');

  let next = pressed;
  for (let tick = 0; tick < 40; tick++) next = simulateTick(next, empty, empty);
  assert.equal(next.player.action, 'upper', 'the buffered press fires after recovery');
});

test('knockdown trajectory uses the same curve for living fighters', () => {
  const { state } = playThreePiece();
  const start = state.rival.knockdown;
  const progressed = advance(state, state.hitstop + 18);
  const pose = geometryKnockdownPose(
    progressed.rival.knockdown.ticks,
    0,
    KNOCKDOWN_TICKS,
    start.direction,
    start.heavy,
  );
  assert.ok(Math.abs(progressed.rival.x - (start.x + pose.x)) < 1e-9);
  assert.ok(Math.abs(progressed.rival.y - pose.y) < 1e-9);
});

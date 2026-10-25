import {
  attackDamage,
  canBufferComboInput,
  COMBO_WINDOW_SECONDS,
  decideWinner,
  findPunchContact,
  getAttackDuration,
  getAttackStage,
  getComboStepAfterAttack,
  getStrikePose,
  isBlockingHit,
  isComboFollowup
} from '../combatRules';
import { FIXED_TIMESTEP, type GameState, type FighterState, type FighterInput, type GameEvent } from './types';

// Constants from GameScene.ts
export const FLOOR = 574;
export const LEFT_BOUND = 92;
export const RIGHT_BOUND = 1188;
export const MIN_FIGHTER_GAP = 76;
export const RIVAL_ENGAGE_RANGE = 108;
export const AIR_PASS_CLEARANCE = 52;
export const WALK_AROUND_RANGE = MIN_FIGHTER_GAP + 8;
export const WALK_AROUND_JUMP = -570;
export const TORSO_LEFT = -27;
export const TORSO_RIGHT = 28;
export const TORSO_HEIGHT = 65;
export const HEAD_OFFSET = 3;
export const HEAD_RADIUS = 22;

export function simulateTick(state: GameState, playerInput: FighterInput, rivalInput: FighterInput): GameState {
  // We perform deep copy to ensure immutability
  const nextState: GameState = JSON.parse(JSON.stringify(state));
  nextState.events = []; // clear events for this tick

  if (nextState.status !== 'playing') {
    nextState.player.anim += FIXED_TIMESTEP * 2.2;
    nextState.rival.anim += FIXED_TIMESTEP * 2.2;
    return nextState;
  }

  nextState.elapsed += FIXED_TIMESTEP;
  nextState.timeLeft = Math.max(0, 90 - Math.floor(nextState.elapsed));

  updatePlayer(nextState.player, nextState.rival, playerInput, nextState.events);
  updateRival(nextState.rival, nextState.player, nextState.events); // AI logic uses nextState for current positions

  separateFighters(nextState.player, nextState.rival);
  faceOpponents(nextState.player, nextState.rival);

  updateFighterTimers(nextState.player, nextState.events, 'player');
  updateFighterTimers(nextState.rival, nextState.events, 'rival');

  resolveCombat(nextState.player, nextState.rival, nextState.events);

  if (nextState.player.health <= 0 || nextState.rival.health <= 0 || nextState.timeLeft <= 0) {
    nextState.status = 'finished';
    nextState.winner = decideWinner(nextState.player.health, nextState.rival.health);
  }

  return nextState;
}

function updatePlayer(p: FighterState, rival: FighterState, input: FighterInput, events: GameEvent[]) {
  const canAct = p.stun <= 0;
  p.blocking = canAct && input.block && p.grounded;

  if (canAct) {
    p.vx = ((input.right ? 1 : 0) - (input.left ? 1 : 0)) * 270;
    if (p.blocking) p.vx *= 0.38;

    if (input.jump && p.grounded) {
      p.vy = -665;
      p.grounded = false;
      events.push({ type: 'sound', kind: 'jump' });
    }

    if (input.light) attack(p, 'light', events, 'player');
    if (input.heavy) attack(p, 'heavy', events, 'player');
    tryWalkAround(p, rival, events);
  } else {
    p.vx = 0;
  }
  moveFighter(p);
}

// Very simple AI logic - extracted from GameScene
function updateRival(e: FighterState, player: FighterState, events: GameEvent[]) {
  const distance = player.x - e.x;
  const distanceToPlayer = Math.abs(distance);
  const inAttackRange = distanceToPlayer <= RIVAL_ENGAGE_RANGE;

  e.aiWait = Math.max(0, e.aiWait - FIXED_TIMESTEP);
  e.blocking = e.action === 'block' && e.actionTime > 0 && e.stun <= 0 && e.grounded;

  if (inAttackRange && e.aiWait < 0.25 && e.action === 'idle') {
      e.aiWait = Math.max(e.aiWait, 0.25);
  }

  if (e.stun <= 0) {
    if (!inAttackRange) {
      e.blocking = false;
      e.vx = Math.sign(distance) * 145;
    } else {
      e.vx = 0;
      if (!e.blocking && e.aiWait <= 0 && e.cooldown <= 0) {
        // Determinism Note: Math.random() makes this non-deterministic.
        // For Phase 1, we accept this as we aren't doing rollback yet.
        // In Phase 2, we will pass a seeded RNG or move AI to server entirely.
        const roll = Math.random();
        if (roll < 0.22 && player.action === 'heavy') {
          e.blocking = true;
          e.action = 'block';
          e.actionTime = 0.48;
        } else {
          attack(e, roll > 0.72 ? 'heavy' : 'light', events, 'rival');
        }
        e.aiWait = 0.55 + Math.random() * 0.45;
      }
    }
    if (distanceToPlayer > 310 && e.grounded && Math.random() < 0.008) {
      e.vy = -590;
      events.push({ type: 'sound', kind: 'jump' });
    }
  } else {
    e.vx = 0;
  }
  moveFighter(e);
}

function updateFighterTimers(f: FighterState, events: GameEvent[], id: 'player' | 'rival') {
  f.anim += FIXED_TIMESTEP * (Math.abs(f.vx) > 0 ? 8 : 2.2);
  f.cooldown = Math.max(0, f.cooldown - FIXED_TIMESTEP);
  f.stun = Math.max(0, f.stun - FIXED_TIMESTEP);
  f.walkAroundCooldown = Math.max(0, f.walkAroundCooldown - FIXED_TIMESTEP);
  f.comboWindow = Math.max(0, f.comboWindow - FIXED_TIMESTEP);
  f.comboFeedbackTime = Math.max(0, f.comboFeedbackTime - FIXED_TIMESTEP);

  if (f.comboFeedbackTime === 0) f.comboFeedback = '';

  if (f.comboWindow === 0 && f.comboStep !== 0) {
    f.comboStep = 0;
    f.comboHits = 0;
    f.bufferedAttack = null;
  }

  f.actionTime = Math.max(0, f.actionTime - FIXED_TIMESTEP);
  if (f.action === 'light' || f.action === 'heavy') {
    f.attackElapsed += FIXED_TIMESTEP;
  }

  if (f.actionTime === 0 && f.action !== 'idle') {
    const attackFinished = f.action === 'light' || f.action === 'heavy';
    if (attackFinished && !f.hitRegistered) f.comboHits = 0;
    f.action = f.blocking ? 'block' : 'idle';
    if (attackFinished && f.bufferedAttack) {
      const nextAttack = f.bufferedAttack;
      f.bufferedAttack = null;
      attack(f, nextAttack, events, id);
    }
  }

  if (f.stun <= 0 && f.action === 'hit') f.action = 'idle';
}

function moveFighter(f: FighterState) {
  if (f.stun > 0) f.vx *= Math.exp(-6 * FIXED_TIMESTEP);
  // Math.max/min to clamp
  f.x = Math.max(LEFT_BOUND, Math.min(RIGHT_BOUND, f.x + f.vx * FIXED_TIMESTEP));

  if (!f.grounded) {
    f.vy += 1580 * FIXED_TIMESTEP;
    f.y += f.vy * FIXED_TIMESTEP;
    if (f.y >= 0) {
      f.y = 0;
      f.vy = 0;
      f.grounded = true;
    }
  }
}

function separateFighters(player: FighterState, rival: FighterState) {
  if (Math.abs(player.y - rival.y) > AIR_PASS_CLEARANCE) return;

  const gap = Math.abs(rival.x - player.x);
  if (gap < MIN_FIGHTER_GAP) {
    const midpoint = Math.max(
      LEFT_BOUND + MIN_FIGHTER_GAP / 2,
      Math.min(RIGHT_BOUND - MIN_FIGHTER_GAP / 2, (player.x + rival.x) / 2)
    );
    const relativeDirection =
      Math.sign(rival.x - player.x) ||
      -Math.sign(player.vx - rival.vx) ||
      player.facing ||
      1;
    player.x = midpoint - relativeDirection * MIN_FIGHTER_GAP / 2;
    rival.x = midpoint + relativeDirection * MIN_FIGHTER_GAP / 2;
  }
}

function faceOpponents(player: FighterState, rival: FighterState) {
  const direction = Math.sign(rival.x - player.x) || player.facing || 1;
  player.facing = direction;
  rival.facing = -direction;
}

function tryWalkAround(player: FighterState, rival: FighterState, events: GameEvent[]) {
  const directionToRival = Math.sign(rival.x - player.x);
  const movingTowardRival = directionToRival !== 0 && Math.sign(player.vx) === directionToRival;
  const isAttacking = player.action === 'light' || player.action === 'heavy';

  if (
    !movingTowardRival ||
    Math.abs(rival.x - player.x) > WALK_AROUND_RANGE ||
    !player.grounded ||
    player.blocking ||
    player.stun > 0 ||
    player.walkAroundCooldown > 0 ||
    isAttacking
  ) return;

  player.vy = WALK_AROUND_JUMP;
  player.grounded = false;
  player.walkAroundCooldown = 0.9;
  events.push({ type: 'sound', kind: 'jump' });
}

function attack(attacker: FighterState, kind: 'light' | 'heavy', events: GameEvent[], id: 'player' | 'rival') {
  if (attacker.stun > 0 || attacker.blocking) return;
  const attackInProgress = attacker.action === 'light' || attacker.action === 'heavy';

  if (attackInProgress) {
    if (!attacker.bufferedAttack && canBufferComboInput(
      attacker.comboStep,
      kind,
      attacker.attackElapsed,
      attacker.comboWindow,
    )) {
      attacker.bufferedAttack = kind;
    }
    return;
  }

  if (attacker.action === 'hit' && attacker.actionTime > 0) return;

  const chained = isComboFollowup(attacker.comboStep, kind, attacker.comboWindow > 0);
  if (attacker.cooldown > 0 && !chained) return;

  const stage = getAttackStage(attacker.comboStep, kind, chained);
  if (!chained) attacker.comboHits = 0;

  attacker.action = kind;
  attacker.attackStage = stage;
  attacker.actionTime = getAttackDuration(stage);
  attacker.cooldown = kind === 'light' ? 0.38 : 0.72;
  attacker.attackElapsed = 0;
  attacker.hitRegistered = false;
  attacker.attackFacing = attacker.facing;
  attacker.comboStep = getComboStepAfterAttack(stage);
  attacker.comboWindow = stage === 'power' ? 0 : COMBO_WINDOW_SECONDS;

  events.push({ type: 'attack-stage', fighter: id, kind, stage });
}

function getFighterPose(f: FighterState) {
  const baseY = FLOOR + 2 + f.y;
  const moving = Math.abs(f.vx) > 8 && f.grounded;
  const bob = f.grounded ? Math.sin(f.anim) * (moving ? 5 : 2) : 0;
  const crouch = f.blocking ? 19 : 0;
  const hipY = baseY - 68 - crouch + bob;
  const shoulderY = hipY - 42;
  return { baseY, moving, bob, crouch, hipY, shoulderY, headY: shoulderY - 30 };
}

function resolveCombat(player: FighterState, rival: FighterState, events: GameEvent[]) {
  const fighters = [player, rival];

  for (const attacker of fighters) {
    const defender = attacker === player ? rival : player;
    if (attacker.action !== 'light' && attacker.action !== 'heavy') continue;

    const attackerPose = getFighterPose(attacker);
    const defenderPose = getFighterPose(defender);

    const fist = getStrikePose(
      attacker.action,
      attacker.x,
      attackerPose.shoulderY,
      attacker.attackFacing,
      attacker.attackStage,
    );

    const impact = findPunchContact({
      centerX: attacker.x,
      attackFacing: attacker.attackFacing,
      attackElapsed: attacker.attackElapsed,
      hitRegistered: attacker.hitRegistered,
      kind: attacker.action,
      stage: attacker.attackStage,
    }, fist, {
      centerX: defender.x,
      body: {
        left: defender.x + TORSO_LEFT,
        right: defender.x + TORSO_RIGHT,
        top: defenderPose.shoulderY,
        bottom: defenderPose.shoulderY + TORSO_HEIGHT + (defender.blocking ? 19 : 0),
      },
      head: {
        x: defender.x + defender.facing * HEAD_OFFSET,
        y: defenderPose.headY,
        radius: HEAD_RADIUS,
      },
    });

    if (!impact) continue;

    attacker.hitRegistered = true;
    const blocked = isBlockingHit(attacker.x, {
      x: defender.x,
      facing: defender.facing,
      blocking: defender.blocking,
      grounded: defender.grounded,
    });

    const damage = attackDamage(attacker.action, blocked);
    defender.health = Math.max(0, defender.health - damage);
    defender.stun = blocked ? 0.12 : 0.28;
    defender.action = blocked ? 'block' : 'hit';
    defender.actionTime = blocked ? 0.16 : 0.29;
    const knockback = blocked ? 145 : attacker.attackStage === 'power' ? 420 : 60;
    defender.vx = Math.sign(defender.x - attacker.x) * knockback;
    defender.comboStep = 0;
    defender.comboWindow = 0;
    defender.bufferedAttack = null;
    defender.comboHits = 0;
    defender.comboFeedback = '';
    defender.comboFeedbackTime = 0;

    if (blocked) {
      attacker.comboHits = 0;
    } else {
      attacker.comboHits = Math.min(3, attacker.comboHits + 1);
      if (attacker.comboHits >= 2) {
        attacker.comboFeedback = attacker.attackStage === 'power'
          ? `${attacker.comboHits}-HIT FINISH`
          : `${attacker.comboHits}-HIT COMBO`;
        attacker.comboFeedbackTime = 0.68;
      }
    }

    events.push({ type: 'shake', duration: blocked ? 0.07 : 0.16, intensity: blocked ? 65 : 110, speed: blocked ? 0.002 : 0.004 });
    events.push({ type: 'spark', x: impact.x, y: impact.y, color: blocked ? 0xf3cf67 : 0xffe7ad, count: blocked ? 8 : 15 });
    events.push({ type: 'sound', kind: blocked ? 'block' : 'hit' });
  }
}

/**
 * Deterministic 60 Hz combat simulation.
 *
 * Determinism contract:
 *  - `simulateTick` is a pure function of (state, playerInput, rivalInput).
 *  - No wall clock, no Math.random, no DOM. The only randomness is `rngState`.
 *  - Hits are resolved from pre-hit snapshots and applied in two passes, so the
 *    result never depends on which fighter is evaluated first and genuine
 *    trades are possible.
 */
import {
  AI_TUNING,
  ATTACK_SPECS,
  COMBO_BUFFER_OPEN_AT,
  COMBO_FEEDBACK,
  COMBO_WINDOW_SECONDS,
  INPUT_BUFFER_SECONDS,
  KO_SEQUENCE,
  MATCH_RULES,
  MOVEMENT,
} from '../combatConfig.ts';
import type { AttackKind, AttackStage, ComboChainId } from '../combatConfig.ts';
import {
  attackDamage,
  decideWinner,
  findPunchContact,
  getAttackDuration,
  getAttackStage,
  getChainContinuation,
  getChainStepAfterStage,
  getCounterDamage,
  getHitstun,
  getHitstopTicks,
  getReactionTime,
  getStrikePose,
  isAttackAction,
  isBlockingHit,
  isCounterHit,
} from '../combatRules.ts';
import {
  FLOOR,
  LEFT_BOUND,
  RIGHT_BOUND,
  getFighterPose,
  getHurtbox,
  getKnockdownPose,
} from '../fighterGeometry.ts';
import { resetFighterForRound } from './initialState.ts';
import {
  FIXED_TIMESTEP,
  type FighterInput,
  type FighterState,
  type GameEvent,
  type GameState,
} from './types.ts';

export const IMPACT_FREEZE_TICKS = KO_SEQUENCE.impactFreezeTicks;
export const KNOCKDOWN_TICKS = KO_SEQUENCE.knockdownTicks;
export const KO_ANNOUNCEMENT_TICKS = KO_SEQUENCE.announcementTicks;

/* --------------------------------------------------------------- cloning */

function cloneFighter(fighter: FighterState): FighterState {
  return {
    ...fighter,
    knockdown: fighter.knockdown ? { ...fighter.knockdown } : null,
    hitReaction: fighter.hitReaction ? { ...fighter.hitReaction } : null,
  };
}

/**
 * Explicit structural copy. Much cheaper than JSON round-tripping at 60 Hz and
 * it cannot silently drop non-JSON values the way JSON does.
 */
export function cloneState(state: GameState): GameState {
  return {
    ...state,
    player: cloneFighter(state.player),
    rival: cloneFighter(state.rival),
    ko: state.ko
      ? { ticks: state.ko.ticks, player: { ...state.ko.player }, rival: { ...state.ko.rival } }
      : null,
    events: [],
  };
}

/* ------------------------------------------------------------------ tick */

export function simulateTick(
  state: GameState,
  playerInput: FighterInput,
  rivalInput: FighterInput,
): GameState {
  const next = cloneState(state);

  if (
    next.ko &&
    (next.status === 'impact-freeze' ||
      next.status === 'knockdown' ||
      next.status === 'ko-announcement')
  ) {
    return tickKoSequence(next);
  }

  if (next.status === 'pre-round') {
    next.transitionTimer = Math.max(0, next.transitionTimer - FIXED_TIMESTEP);
    next.player.anim += FIXED_TIMESTEP * 2.2;
    next.rival.anim += FIXED_TIMESTEP * 2.2;
    if (next.transitionTimer <= 0) {
      next.status = 'playing';
      next.events.push({ type: 'sound', kind: 'round' });
    }
    return next;
  }

  if (next.status === 'round-transition') {
    next.transitionTimer = Math.max(0, next.transitionTimer - FIXED_TIMESTEP);
    next.player.anim += FIXED_TIMESTEP * 2.2;
    next.rival.anim += FIXED_TIMESTEP * 2.2;
    if (next.transitionTimer <= 0) resetRoundForNext(next);
    return next;
  }

  if (next.status === 'finished') {
    next.player.anim += FIXED_TIMESTEP * 2.2;
    next.rival.anim += FIXED_TIMESTEP * 2.2;
    return next;
  }

  // status === 'playing'
  if (next.hitstop > 0) {
    // Deterministic per-hit hitstop: the whole world holds for N ticks.
    next.hitstop -= 1;
    // A press during the freeze must not be swallowed: remember it (the buffer
    // timer does not tick while the world is frozen).
    rememberFrozenPresses(next.player, playerInput);
    if (next.rivalControl === 'human') rememberFrozenPresses(next.rival, rivalInput);
    return next;
  }

  next.elapsed += FIXED_TIMESTEP;
  next.timeLeft = Math.max(0, MATCH_RULES.roundSeconds - Math.floor(next.elapsed));

  updateFromInput(next.player, next.rival, playerInput, next.events, 'player');
  if (next.rivalControl === 'human') {
    updateFromInput(next.rival, next.player, rivalInput, next.events, 'rival');
  } else {
    updateRivalAi(next.rival, next.player, next);
  }

  separateFighters(next.player, next.rival);
  faceOpponents(next.player, next.rival);

  updateFighterTimers(next.player, next.events, 'player');
  updateFighterTimers(next.rival, next.events, 'rival');

  resolveCombat(next.player, next.rival, next);

  if (next.player.health <= 0 || next.rival.health <= 0 || next.timeLeft <= 0) {
    const roundWinner = decideWinner(next.player.health, next.rival.health);
    next.roundWinner = roundWinner;
    if (roundWinner === 'player') next.playerWins++;
    if (roundWinner === 'rival') next.rivalWins++;

    const knockout = next.player.health <= 0 || next.rival.health <= 0;
    next.roundEndReason = knockout ? 'ko' : 'timeout';
    if (knockout) {
      next.threePieceKO = next.events.some(event => event.type === 'three-piece' && event.ko);
      next.status = 'impact-freeze';
      next.hitstop = 0;
      next.ko = {
        ticks: 0,
        player: {
          x: next.player.x,
          y: next.player.y,
          direction: -next.player.facing,
          heavy: finishingBlowWasHeavy(next, 'player'),
        },
        rival: {
          x: next.rival.x,
          y: next.rival.y,
          direction: -next.rival.facing,
          heavy: finishingBlowWasHeavy(next, 'rival'),
        },
      };
    } else {
      finishRound(next);
    }
  }

  return next;
}

function finishingBlowWasHeavy(state: GameState, id: 'player' | 'rival'): boolean {
  for (let i = state.events.length - 1; i >= 0; i--) {
    const event = state.events[i];
    if (event.type === 'hit-reaction' && event.fighter === id) return event.kind !== 'light';
    if (event.type === 'three-piece' && event.fighter === id) return true;
  }
  return false;
}

/* -------------------------------------------------------------- KO phase */

function tickKoSequence(next: GameState): GameState {
  const ko = next.ko!;
  ko.ticks += 1;
  const ticks = ko.ticks;

  if (ticks < IMPACT_FREEZE_TICKS) return next;

  for (const id of ['player', 'rival'] as const) {
    const fighter = next[id];
    const start = ko[id];
    if (fighter.health > 0) {
      // The survivor settles into an idle stance and keeps breathing instead of
      // being frozen mid-punch for the entire cinematic.
      if (fighter.action !== 'idle') {
        fighter.action = 'idle';
        fighter.actionTime = 0;
        fighter.blocking = false;
      }
      fighter.anim += FIXED_TIMESTEP * 2.2;
      moveFighter(fighter);
      continue;
    }
    const pose = getKnockdownPose(
      ticks,
      IMPACT_FREEZE_TICKS,
      KNOCKDOWN_TICKS,
      start.direction,
      start.heavy,
    );
    fighter.x = clamp(start.x + pose.x, LEFT_BOUND, RIGHT_BOUND);
    fighter.y = pose.y;
    fighter.grounded = pose.progress === 1;
    fighter.vx = 0;
    fighter.vy = 0;
    fighter.blocking = false;
    fighter.action = 'down';
    fighter.actionTime = 0;
  }

  if (ticks < IMPACT_FREEZE_TICKS + KNOCKDOWN_TICKS) {
    next.status = 'knockdown';
  } else {
    if (next.status !== 'ko-announcement') next.events.push({ type: 'sound', kind: 'ko' });
    next.status = 'ko-announcement';
  }

  if (ticks >= IMPACT_FREEZE_TICKS + KNOCKDOWN_TICKS + KO_ANNOUNCEMENT_TICKS) finishRound(next);
  return next;
}

function finishRound(state: GameState) {
  state.hitstop = 0;
  if (state.playerWins >= MATCH_RULES.roundsToWin || state.rivalWins >= MATCH_RULES.roundsToWin) {
    state.status = 'finished';
    state.matchWinner = state.playerWins >= MATCH_RULES.roundsToWin ? 'player' : 'rival';
    state.winner = state.matchWinner;
  } else {
    state.status = 'round-transition';
    state.transitionTimer = MATCH_RULES.roundTransitionSeconds;
  }
}

function resetRoundForNext(state: GameState) {
  state.ko = null;
  state.roundEndReason = null;
  state.threePieceKO = false;
  state.hitstop = 0;
  if (state.roundWinner !== 'draw') state.round++;
  state.roundWinner = null;
  state.status = 'pre-round';
  state.transitionTimer = MATCH_RULES.preRoundSeconds;
  state.elapsed = 0;
  state.timeLeft = MATCH_RULES.roundSeconds;

  resetFighterForRound(state.player, { x: MATCH_RULES.playerStartX, facing: 1 });
  resetFighterForRound(state.rival, {
    x: MATCH_RULES.rivalStartX,
    facing: -1,
    aiWait: AI_TUNING.initialWait,
  });
}

/* ----------------------------------------------------------------- input */

function updateFromInput(
  fighter: FighterState,
  opponent: FighterState,
  input: FighterInput,
  events: GameEvent[],
  id: 'player' | 'rival',
) {
  if (fighter.knockdown) {
    updateKnockdown(fighter, events);
    return;
  }
  const canAct = fighter.stun <= 0;
  // Blocking is a committed stance: never during your own attack.
  fighter.blocking =
    canAct && !isAttackAction(fighter.action) && input.block && fighter.grounded;

  if (canAct) {
    fighter.vx = ((input.right ? 1 : 0) - (input.left ? 1 : 0)) * MOVEMENT.walkSpeed;
    if (fighter.blocking) fighter.vx *= MOVEMENT.blockWalkMultiplier;

    if (input.jump && fighter.grounded) {
      fighter.vy = MOVEMENT.jumpVelocity;
      fighter.grounded = false;
      events.push({ type: 'sound', kind: 'jump' });
    }

    if (input.light) attack(fighter, 'light', events, id);
    if (input.heavy) attack(fighter, 'heavy', events, id);
    if (input.head) attack(fighter, 'head', events, id);
    if (input.upper) attack(fighter, 'upper', events, id);
    tryWalkAround(fighter, opponent, events);
  } else {
    fighter.vx = 0;
  }
  moveFighter(fighter);
}

/**
 * Simple 32-bit PRNG (Mulberry32). Mutates state.rngState so the entire match
 * is reproducible from a single seed.
 */
function nextRandom(state: GameState): number {
  let t = (state.rngState += 0x6d2b79f5);
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

function updateRivalAi(rival: FighterState, player: FighterState, state: GameState) {
  if (rival.knockdown) {
    updateKnockdown(rival, state.events);
    return;
  }
  const distance = player.x - rival.x;
  const distanceToPlayer = Math.abs(distance);
  const inAttackRange = distanceToPlayer <= AI_TUNING.engageRange;

  rival.aiWait = Math.max(0, rival.aiWait - FIXED_TIMESTEP);
  rival.blocking =
    rival.action === 'block' && rival.actionTime > 0 && rival.stun <= 0 && rival.grounded;

  if (rival.stun <= 0) {
    if (!inAttackRange) {
      rival.blocking = false;
      rival.vx = Math.sign(distance) * AI_TUNING.walkSpeed;
    } else {
      rival.vx = 0;
      if (!rival.blocking && rival.aiWait <= 0 && rival.cooldown <= 0) {
        const roll = nextRandom(state);
        if (
          roll < AI_TUNING.blockChance &&
          isAttackAction(player.action) &&
          player.action !== 'light'
        ) {
          rival.blocking = true;
          rival.action = 'block';
          rival.actionTime = 0.48;
        } else {
          attack(
            rival,
            roll > 1 - AI_TUNING.heavyChance ? 'heavy' : 'light',
            state.events,
            'rival',
          );
        }
        rival.aiWait = AI_TUNING.waitMin + nextRandom(state) * AI_TUNING.waitJitter;
      }
    }
    if (
      distanceToPlayer > AI_TUNING.jumpRange &&
      rival.grounded &&
      nextRandom(state) < AI_TUNING.jumpChance
    ) {
      rival.vy = AI_TUNING.jumpVelocity;
      state.events.push({ type: 'sound', kind: 'jump' });
    }
  } else {
    rival.vx = 0;
  }
  moveFighter(rival);
}

/* --------------------------------------------------------------- attacks */

function chainContinuation(fighter: FighterState, kind: AttackKind) {
  return getChainContinuation(fighter.comboStep, kind, fighter.comboWindow > 0);
}

function rememberFrozenPresses(fighter: FighterState, input: FighterInput) {
  if (input.light) rememberPress(fighter, 'light');
  if (input.heavy) rememberPress(fighter, 'heavy');
  if (input.head) rememberPress(fighter, 'head');
  if (input.upper) rememberPress(fighter, 'upper');
}

function rememberPress(fighter: FighterState, kind: AttackKind) {
  if (fighter.bufferedAttack) return;
  fighter.bufferedAttack = kind;
  fighter.bufferedAttackTimer = INPUT_BUFFER_SECONDS;
}

function attack(
  attacker: FighterState,
  kind: AttackKind,
  events: GameEvent[],
  id: 'player' | 'rival',
) {
  if (attacker.knockdown) return;

  if (isAttackAction(attacker.action)) {
    // Buffering a follow-up is only allowed once the current stage is past its
    // input lock and the press is a valid chain continuation.
    const continuation = chainContinuation(attacker, kind);
    if (continuation && attacker.attackElapsed >= COMBO_BUFFER_OPEN_AT) {
      rememberPress(attacker, kind);
    }
    return;
  }

  if (
    attacker.stun > 0 ||
    attacker.blocking ||
    (attacker.action === 'hit' && attacker.actionTime > 0)
  ) {
    rememberPress(attacker, kind);
    return;
  }

  const continuation = chainContinuation(attacker, kind);
  if (attacker.cooldown > 0 && !continuation) {
    rememberPress(attacker, kind);
    return;
  }

  startAttack(attacker, kind, continuation, events, id);
}

function startAttack(
  attacker: FighterState,
  kind: AttackKind,
  continuation: ReturnType<typeof chainContinuation>,
  events: GameEvent[],
  id: 'player' | 'rival',
) {
  const stage = continuation?.stage ?? getAttackStage(0, kind, false);
  const spec = ATTACK_SPECS[kind];

  attacker.action = kind;
  attacker.attackStage = stage;
  attacker.actionTime = getAttackDuration(stage);
  attacker.cooldown = spec.cooldown;
  attacker.attackElapsed = 0;
  attacker.hitRegistered = false;
  attacker.attackFacing = attacker.facing;
  attacker.bufferedAttack = null;
  attacker.bufferedAttackTimer = 0;
  attacker.comboChain = continuation ? continuation.chain : null;
  attacker.comboStep = getChainStepAfterStage(stage, attacker.comboChain);
  attacker.comboWindow = continuation || attacker.comboStep !== 0 ? COMBO_WINDOW_SECONDS : 0;
  if (!continuation) attacker.comboHits = 0;

  events.push({ type: 'attack-stage', fighter: id, kind, stage });
}

function consumeBufferedAttack(
  fighter: FighterState,
  events: GameEvent[],
  id: 'player' | 'rival',
) {
  const kind = fighter.bufferedAttack;
  if (!kind || fighter.bufferedAttackTimer <= 0) {
    fighter.bufferedAttack = null;
    fighter.bufferedAttackTimer = 0;
    return;
  }
  fighter.bufferedAttack = null;
  fighter.bufferedAttackTimer = 0;
  attack(fighter, kind, events, id);
}

/* --------------------------------------------------------------- timers */

function updateFighterTimers(
  fighter: FighterState,
  events: GameEvent[],
  id: 'player' | 'rival',
) {
  fighter.anim += FIXED_TIMESTEP * (Math.abs(fighter.vx) > 0 ? 8 : 2.2);
  advanceHitReaction(fighter);
  fighter.cooldown = Math.max(0, fighter.cooldown - FIXED_TIMESTEP);
  fighter.stun = Math.max(0, fighter.stun - FIXED_TIMESTEP);
  fighter.walkAroundCooldown = Math.max(0, fighter.walkAroundCooldown - FIXED_TIMESTEP);
  fighter.comboWindow = Math.max(0, fighter.comboWindow - FIXED_TIMESTEP);
  fighter.comboFeedbackTime = Math.max(0, fighter.comboFeedbackTime - FIXED_TIMESTEP);
  fighter.bufferedAttackTimer = Math.max(0, fighter.bufferedAttackTimer - FIXED_TIMESTEP);

  if (fighter.bufferedAttackTimer === 0) fighter.bufferedAttack = null;
  if (fighter.comboFeedbackTime === 0) fighter.comboFeedback = '';
  if (fighter.comboWindow === 0 && fighter.comboStep !== 0) clearChain(fighter);

  if (fighter.knockdown) return;

  fighter.actionTime = Math.max(0, fighter.actionTime - FIXED_TIMESTEP);
  if (isAttackAction(fighter.action)) fighter.attackElapsed += FIXED_TIMESTEP;

  if (fighter.actionTime === 0 && fighter.action !== 'idle') {
    const attackFinished = isAttackAction(fighter.action);
    if (attackFinished && !fighter.hitRegistered) fighter.comboHits = 0;
    fighter.action = fighter.blocking ? 'block' : 'idle';
    if (attackFinished && fighter.bufferedAttack) {
      consumeBufferedAttack(fighter, events, id);
    }
  }

  if (fighter.stun <= 0 && fighter.action === 'hit') fighter.action = 'idle';

  // Wake-up / recovery buffer: an attack pressed during hitstun fires as soon
  // as the fighter can act again, within the buffer window.
  if (
    fighter.stun <= 0 &&
    !fighter.blocking &&
    !fighter.knockdown &&
    fighter.action !== 'hit' &&
    fighter.action !== 'down' &&
    !isAttackAction(fighter.action) &&
    fighter.bufferedAttack
  ) {
    consumeBufferedAttack(fighter, events, id);
  }
}

function advanceHitReaction(fighter: FighterState) {
  if (!fighter.hitReaction) return;
  fighter.hitReaction.age += 1;
  if (fighter.hitReaction.age >= ATTACK_SPECS[fighter.hitReaction.kind].hitReactionTicks) {
    fighter.hitReaction = null;
  }
}

function clearChain(fighter: FighterState) {
  fighter.comboStep = 0;
  fighter.comboChain = null;
  fighter.comboWindow = 0;
  fighter.comboHits = 0;
  fighter.bufferedAttack = null;
  fighter.bufferedAttackTimer = 0;
}

/* ------------------------------------------------------------ locomotion */

function moveFighter(fighter: FighterState) {
  if (fighter.stun > 0) fighter.vx *= Math.exp(-6 * FIXED_TIMESTEP);
  fighter.x = Math.max(
    LEFT_BOUND,
    Math.min(RIGHT_BOUND, fighter.x + fighter.vx * FIXED_TIMESTEP),
  );

  if (!fighter.grounded) {
    fighter.vy += MOVEMENT.gravity * FIXED_TIMESTEP;
    fighter.y += fighter.vy * FIXED_TIMESTEP;
    if (fighter.y >= 0) {
      fighter.y = 0;
      fighter.vy = 0;
      fighter.grounded = true;
    }
  }
}

function separateFighters(player: FighterState, rival: FighterState) {
  if (player.knockdown || rival.knockdown) return;
  if (Math.abs(player.y - rival.y) > MOVEMENT.airPassClearance) return;

  const gap = Math.abs(rival.x - player.x);
  if (gap < MOVEMENT.minFighterGap) {
    const midpoint = Math.max(
      LEFT_BOUND + MOVEMENT.minFighterGap / 2,
      Math.min(RIGHT_BOUND - MOVEMENT.minFighterGap / 2, (player.x + rival.x) / 2),
    );
    const relativeDirection =
      Math.sign(rival.x - player.x) ||
      -Math.sign(player.vx - rival.vx) ||
      player.facing ||
      1;
    player.x = midpoint - (relativeDirection * MOVEMENT.minFighterGap) / 2;
    rival.x = midpoint + (relativeDirection * MOVEMENT.minFighterGap) / 2;
  }
}

function faceOpponents(player: FighterState, rival: FighterState) {
  const direction = Math.sign(rival.x - player.x) || player.facing || 1;
  if (!player.knockdown) player.facing = direction;
  if (!rival.knockdown) rival.facing = -direction;
}

function tryWalkAround(player: FighterState, rival: FighterState, events: GameEvent[]) {
  const directionToRival = Math.sign(rival.x - player.x);
  const movingTowardRival = directionToRival !== 0 && Math.sign(player.vx) === directionToRival;
  const isAttacking = isAttackAction(player.action);

  if (
    !movingTowardRival ||
    Math.abs(rival.x - player.x) > MOVEMENT.minFighterGap + 8 ||
    !player.grounded ||
    player.blocking ||
    player.stun > 0 ||
    player.walkAroundCooldown > 0 ||
    isAttacking
  ) {
    return;
  }

  player.vy = MOVEMENT.walkAroundJump;
  player.grounded = false;
  player.walkAroundCooldown = MOVEMENT.walkAroundCooldown;
  events.push({ type: 'sound', kind: 'jump' });
}

/* --------------------------------------------------------------- combat */

type HitCandidate = {
  attacker: FighterState;
  defender: FighterState;
  impact: { x: number; y: number };
  region: 'head' | 'body';
  blocked: boolean;
  counter: boolean;
  damage: number;
  hitstop: number;
  hitstun: number;
  reactionTime: number;
  knockback: number;
  stage: AttackStage;
  kind: AttackKind;
  direction: number;
  comboHitsBefore: number;
  comboChainBefore: ComboChainId | null;
};

function buildCandidate(
  attacker: FighterState,
  defender: FighterState,
): HitCandidate | null {
  if (!isAttackAction(attacker.action) || attacker.knockdown || defender.knockdown) return null;

  const attackerPose = getFighterPose(attacker);
  const defenderPose = getFighterPose(defender);
  const kind = attacker.action;

  const impact = findPunchContact(
    {
      centerX: attacker.x,
      attackFacing: attacker.attackFacing,
      attackElapsed: attacker.attackElapsed,
      hitRegistered: attacker.hitRegistered,
      kind,
      stage: attacker.attackStage,
    },
    getStrikePose(
      kind,
      attacker.x,
      attackerPose.shoulderY,
      attacker.attackFacing,
      attacker.attackStage,
      attacker.attackElapsed,
    ),
    getHurtbox(defender, defenderPose),
  );
  if (!impact) return null;

  // Everything below is derived from the pre-hit snapshot, so applying the
  // candidate can never change what the other candidate sees.
  const blocked = isBlockingHit(attacker.x, {
    x: defender.x,
    facing: defender.facing,
    blocking: defender.blocking,
    grounded: defender.grounded,
    action: defender.action,
  });
  const counter = !blocked && isCounterHit(defender);
  const spec = ATTACK_SPECS[kind];

  return {
    attacker,
    defender,
    impact,
    region: impact.y < defenderPose.shoulderY ? 'head' : 'body',
    blocked,
    counter,
    damage: blocked
      ? attackDamage(kind, true)
      : counter
        ? getCounterDamage(kind)
        : attackDamage(kind, false),
    hitstop: getHitstopTicks(kind, blocked, counter),
    hitstun: getHitstun(kind, blocked, counter),
    reactionTime: getReactionTime(kind, blocked, counter),
    knockback: blocked ? spec.blockedKnockback : spec.knockback,
    stage: attacker.attackStage,
    kind,
    direction: attacker.attackFacing,
    comboHitsBefore: attacker.comboHits,
    comboChainBefore: attacker.comboChain,
  };
}

/**
 * Resolve both attacks from pre-hit snapshots in two passes: first every
 * defender reaction, then every attacker's combo bookkeeping. Because no
 * candidate reads state written by another, the outcome is independent of
 * evaluation order and genuine trades are possible.
 */
function resolveCombat(player: FighterState, rival: FighterState, state: GameState) {
  const candidates: HitCandidate[] = [];
  for (const attacker of [player, rival]) {
    const defender = attacker === player ? rival : player;
    const candidate = buildCandidate(attacker, defender);
    if (candidate) candidates.push(candidate);
  }
  if (candidates.length === 0) return;

  const hitThisTick = new Set<FighterState>();
  for (const candidate of candidates) hitThisTick.add(candidate.defender);

  let hitstop = 0;
  for (const candidate of candidates) {
    hitstop = Math.max(hitstop, applyDefenderHit(candidate, state));
  }
  for (const candidate of candidates) {
    applyAttackerEffects(candidate, state, hitThisTick);
  }
  state.hitstop = hitstop;
}

function applyDefenderHit(candidate: HitCandidate, state: GameState): number {
  const events = state.events;
  const { attacker, defender, kind } = candidate;
  const spec = ATTACK_SPECS[kind];

  attacker.hitRegistered = true;

  defender.health = Math.max(0, defender.health - candidate.damage);
  defender.stun = candidate.hitstun;
  defender.action = candidate.blocked ? 'block' : 'hit';
  defender.actionTime = candidate.reactionTime;
  const knockbackDirection = Math.sign(defender.x - attacker.x) || candidate.direction;
  defender.vx = knockbackDirection * candidate.knockback;
  clearChain(defender);

  const defenderId = defender === state.player ? 'player' : 'rival';
  if (!candidate.blocked) {
    defender.hitReaction = {
      kind,
      region: candidate.region,
      direction: candidate.direction,
      age: 0,
      ...(candidate.counter ? { counter: true as const } : {}),
    };
    events.push({
      type: 'hit-reaction',
      fighter: defenderId,
      kind,
      region: candidate.region,
      direction: candidate.direction,
      ...(candidate.counter ? { counter: true as const } : {}),
    });
  } else {
    defender.hitReaction = null;
  }

  const shake = candidate.blocked ? spec.blockedShake : spec.shake;
  events.push({
    type: 'shake',
    duration: shake.duration,
    intensity: shake.intensity,
    speed: shake.speed,
  });
  events.push({
    type: 'spark',
    x: candidate.impact.x,
    y: candidate.impact.y,
    color: candidate.blocked ? 0xf3cf67 : 0xffe7ad,
    count: candidate.blocked ? spec.blockedSparks : spec.sparks,
  });
  events.push({ type: 'sound', kind: candidate.blocked ? 'block' : 'hit' });

  return candidate.hitstop;
}

function applyAttackerEffects(
  candidate: HitCandidate,
  state: GameState,
  hitThisTick: ReadonlySet<FighterState>,
) {
  const { attacker, defender, stage } = candidate;
  const threePiece =
    !candidate.blocked &&
    candidate.comboChainBefore === 'three-piece' &&
    stage === 'upper' &&
    candidate.comboHitsBefore >= 2;
  const lethal = defender.health <= 0;

  // A fighter who was hit this tick loses the chain they were building; that is
  // symmetric, so a trade never rewards only one side.
  if (!hitThisTick.has(attacker)) {
    if (candidate.blocked) {
      attacker.comboHits = 0;
      attacker.comboChain = null;
    } else {
      attacker.comboHits = Math.min(3, candidate.comboHitsBefore + 1);
      if (threePiece) {
        attacker.comboFeedback = lethal
          ? COMBO_FEEDBACK.threePieceKO
          : COMBO_FEEDBACK.threePiece;
        attacker.comboFeedbackTime = COMBO_FEEDBACK.threePieceDuration;
      } else if (attacker.comboHits >= 2) {
        attacker.comboFeedback =
          stage === 'power'
            ? COMBO_FEEDBACK.finisher(attacker.comboHits)
            : COMBO_FEEDBACK.combo(attacker.comboHits);
        attacker.comboFeedbackTime = COMBO_FEEDBACK.duration;
      }
    }
  }

  if (threePiece) {
    state.events.push({
      type: 'three-piece',
      fighter: attacker === state.player ? 'player' : 'rival',
      ko: lethal,
    });
    if (!lethal) {
      defender.knockdown = {
        ticks: 0,
        x: defender.x,
        y: defender.y,
        direction: candidate.direction,
        heavy: true,
      };
      defender.action = 'down';
      defender.grounded = false;
      defender.blocking = false;
      defender.vx = 0;
      defender.vy = 0;
      clearChain(defender);
    }
  }
}

/* ------------------------------------------------------------ knockdown */

function updateKnockdown(fighter: FighterState, events: GameEvent[]) {
  const down = fighter.knockdown!;
  down.ticks += 1;
  const pose = getKnockdownPose(down.ticks, 0, KNOCKDOWN_TICKS, down.direction, down.heavy);

  fighter.x = clamp(down.x + pose.x, LEFT_BOUND, RIGHT_BOUND);
  fighter.y = pose.y;
  fighter.grounded = pose.progress === 1;
  fighter.vx = 0;
  fighter.vy = 0;
  fighter.blocking = false;
  fighter.action = 'down';
  fighter.actionTime = 0;

  if (down.ticks === KNOCKDOWN_TICKS) {
    events.push({ type: 'spark', x: fighter.x, y: FLOOR, color: 0xc9b38c, count: 24 });
    events.push({ type: 'shake', duration: 0.13, intensity: 130, speed: 0.007 });
    events.push({ type: 'sound', kind: 'hit' });
  }
  if (down.ticks >= KNOCKDOWN_TICKS + KO_SEQUENCE.knockdownRecoveryTicks) {
    fighter.knockdown = null;
    fighter.action = 'idle';
  }
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

/**
 * Pure combat rules: frame data lookup, strike poses, collision, blocking,
 * damage, combo-chain resolution.
 *
 * All tuning numbers come from combatConfig.ts; this module only decides how
 * they combine.
 */
import {
  ATTACK_SPECS,
  BLOCK_RULES,
  COMBO_BUFFER_OPEN_AT,
  COMBO_RULES,
  COMBO_WINDOW_SECONDS,
  COUNTER_HIT,
  STAGE_PROFILES,
} from './combatConfig.ts';
import type { AttackKind, AttackStage, ComboChainId, ComboStep, Winner } from './combatConfig.ts';

export type { AttackKind, AttackStage, ComboChainId, ComboStep, Winner } from './combatConfig.ts';
export { COMBO_BUFFER_OPEN_AT, COMBO_WINDOW_SECONDS } from './combatConfig.ts';

export type PunchAttempt = {
  centerX: number;
  attackFacing: number;
  attackElapsed: number;
  hitRegistered: boolean;
  kind: AttackKind;
  stage: AttackStage;
};

export type Point = { x: number; y: number };
export type Rect = { left: number; right: number; top: number; bottom: number };
export type Circle = { x: number; y: number; radius: number };
export type StrikePose = Point & { radius: number };
export type FighterHurtbox = {
  centerX: number;
  body: Rect;
  head: Circle;
};

export type BlockingState = {
  x: number;
  facing: number;
  blocking: boolean;
  grounded: boolean;
  /** Optional: an attack in progress can never block. */
  action?: string;
};

export function isAttackAction(action: string): action is AttackKind {
  return action === 'light' || action === 'heavy' || action === 'head' || action === 'upper';
}

/* ------------------------------------------------------------------ combo */

export type ChainContinuation = { chain: ComboChainId; stage: AttackStage };

/**
 * The unified chain query: given the committed step and a new attack press,
 * return the chain and stage it continues into, if the window is open.
 * Rules live in COMBO_RULES so adding a chain is a data change.
 */
export function getChainContinuation(
  comboStep: ComboStep,
  kind: AttackKind,
  windowOpen: boolean,
): ChainContinuation | null {
  if (!windowOpen) return null;
  for (const rule of COMBO_RULES) {
    if (rule.step !== comboStep) continue;
    const stage = rule.kindStages[kind];
    if (stage) return { chain: rule.chain, stage };
  }
  return null;
}

/** Legacy straight-chain predicate (kept for the jab -> jab -> finisher path). */
export function isComboFollowup(
  comboStep: ComboStep,
  kind: AttackKind,
  windowOpen: boolean,
): boolean {
  const continuation = getChainContinuation(comboStep, kind, windowOpen);
  return continuation !== null && continuation.chain === 'straight';
}

export function canBufferComboInput(
  comboStep: ComboStep,
  kind: AttackKind,
  attackElapsed: number,
  comboWindow: number,
): boolean {
  return (
    comboWindow > 0 &&
    attackElapsed >= COMBO_BUFFER_OPEN_AT &&
    isComboFollowup(comboStep, kind, true)
  );
}

/** Step committed by a stage, aware of which chain the stage belongs to. */
export function getChainStepAfterStage(stage: AttackStage, chain: ComboChainId | null): ComboStep {
  if (stage === 'jab1') return 1;
  if (stage === 'jab2') return 2;
  if (stage === 'power') return chain === 'three-piece' ? 2 : 0;
  return 0;
}

/** Legacy stage-to-step mapping (finishers always close the chain). */
export function getComboStepAfterAttack(stage: AttackStage): ComboStep {
  if (stage === 'jab1') return 1;
  if (stage === 'jab2') return 2;
  return 0;
}

export function getAttackStage(
  comboStep: ComboStep,
  kind: AttackKind,
  chained: boolean,
): AttackStage {
  if (chained && comboStep === 1 && kind === 'light') return 'jab2';
  if (kind === 'head' || kind === 'upper') return kind;
  if (kind === 'heavy') return 'power';
  return 'jab1';
}

export function getAttackDuration(stage: AttackStage): number {
  return STAGE_PROFILES[stage].duration;
}

export function getStageStartup(stage: AttackStage): number {
  return STAGE_PROFILES[stage].start;
}

/* ------------------------------------------------------------------ poses */

export function getStrikePose(
  kind: AttackKind,
  centerX: number,
  shoulderY: number,
  facing: number,
  stage: AttackStage = kind === 'head' || kind === 'upper' ? kind : kind === 'heavy' ? 'power' : 'jab1',
  attackElapsed?: number,
): StrikePose {
  const profile = STAGE_PROFILES[stage];
  if (kind === 'upper') {
    const elapsed = attackElapsed ?? 0.18;
    const rise = clamp(elapsed / 0.24, 0, 1);
    const retract = clamp((elapsed - 0.24) / 0.1, 0, 1);
    return {
      x: centerX + facing * (28 + (profile.reach - 28) * Math.min(1, rise * 2) * (1 - retract)),
      y: shoulderY + (30 - 80 * rise) * (1 - retract) + 29 * retract,
      radius: 13,
    };
  }
  if (kind === 'light' && attackElapsed !== undefined) {
    // Snap outward early, keep the exact reach through every active frame,
    // then pull back to guard in three ticks without shortening recovery.
    const extension =
      attackElapsed < profile.start
        ? 1 - Math.pow(1 - clamp(attackElapsed / profile.start, 0, 1), 3)
        : 1 - clamp((attackElapsed - profile.end) / 0.05, 0, 1);
    return {
      x: centerX + facing * (24 + (profile.reach - 24) * extension),
      y: shoulderY + 29 + (profile.yOffset - 29) * extension,
      radius: 13,
    };
  }
  return {
    x: centerX + facing * profile.reach,
    y: shoulderY + profile.yOffset,
    radius: 13,
  };
}

/* -------------------------------------------------------------- collision */

export function findPunchContact(
  attacker: PunchAttempt,
  fist: StrikePose,
  defender: FighterHurtbox,
): Point | null {
  if (attacker.hitRegistered) return null;

  const timing = STAGE_PROFILES[attacker.stage];
  if (attacker.attackElapsed < timing.start || attacker.attackElapsed > timing.end) return null;
  if (Math.sign(defender.centerX - attacker.centerX) !== attacker.attackFacing) return null;

  const bodyContact = contactWithRect(fist, defender.body, attacker.attackFacing);
  const headContact = contactWithCircle(fist, defender.head, attacker.attackFacing);
  const contacts = [bodyContact, headContact].filter((point): point is Point => point !== null);

  if (contacts.length === 0) return null;
  return contacts.reduce((closest, point) => {
    const closestDistance = Math.hypot(closest.x - fist.x, closest.y - fist.y);
    const pointDistance = Math.hypot(point.x - fist.x, point.y - fist.y);
    return pointDistance < closestDistance ? point : closest;
  });
}

function contactWithRect(fist: StrikePose, body: Rect, attackFacing: number): Point | null {
  const point = {
    x: clamp(fist.x, body.left, body.right),
    y: clamp(fist.y, body.top, body.bottom),
  };
  const overlaps = Math.hypot(point.x - fist.x, point.y - fist.y) <= fist.radius;
  if (!overlaps) return null;

  const fistInsideBody =
    fist.x >= body.left && fist.x <= body.right && fist.y >= body.top && fist.y <= body.bottom;
  if (!fistInsideBody) return point;

  return {
    x: attackFacing > 0 ? body.left : body.right,
    y: clamp(fist.y, body.top, body.bottom),
  };
}

function contactWithCircle(fist: StrikePose, head: Circle, attackFacing: number): Point | null {
  const dx = fist.x - head.x;
  const dy = fist.y - head.y;
  const distance = Math.hypot(dx, dy);
  if (distance > fist.radius + head.radius) return null;

  const direction = distance > 0 ? 1 / distance : 0;
  return {
    x: head.x + (distance > 0 ? dx * direction : -attackFacing) * head.radius,
    y: head.y + (distance > 0 ? dy * direction : 0) * head.radius,
  };
}

/* ---------------------------------------------------------------- combat */

/**
 * Blocking is a committed stance: grounded, facing the attacker, and never
 * while your own attack is in progress (that was the "instant block cancel"
 * exploit).
 */
export function isBlockingHit(attackerX: number, defender: BlockingState): boolean {
  if (!defender.blocking) return false;
  if (!BLOCK_RULES.allowedWhileAttacking && defender.action && isAttackAction(defender.action)) {
    return false;
  }
  if (BLOCK_RULES.requiresGround && !defender.grounded) return false;
  if (BLOCK_RULES.requiresFacing && defender.facing !== Math.sign(attackerX - defender.x)) {
    return false;
  }
  return true;
}

export function attackDamage(kind: AttackKind, blocked: boolean): number {
  return blocked ? ATTACK_SPECS[kind].chipDamage : ATTACK_SPECS[kind].damage;
}

export function getHitstopTicks(kind: AttackKind, blocked: boolean, counter: boolean): number {
  const spec = ATTACK_SPECS[kind];
  const base = blocked ? spec.blockedHitstopTicks : spec.hitstopTicks;
  return blocked || !counter ? base : base + COUNTER_HIT.extraHitstopTicks;
}

export function getHitstun(kind: AttackKind, blocked: boolean, counter: boolean): number {
  const spec = ATTACK_SPECS[kind];
  const base = blocked ? spec.blockedHitstun : spec.hitstun;
  return blocked || !counter ? base : base + COUNTER_HIT.extraHitstun;
}

export function getReactionTime(kind: AttackKind, blocked: boolean, counter: boolean): number {
  const spec = ATTACK_SPECS[kind];
  const base = blocked ? spec.blockedReactionTime : spec.reactionTime;
  return blocked || !counter ? base : base + COUNTER_HIT.extraReactionTime;
}

export function getHitReactionTicks(kind: AttackKind, blocked: boolean): number {
  return blocked ? ATTACK_SPECS[kind].blockedReactionTicks : ATTACK_SPECS[kind].hitReactionTicks;
}

/** Hitting an opponent during the startup of their own attack is a counterhit. */
export function isCounterHit(defender: {
  action: string;
  attackElapsed: number;
  attackStage: AttackStage;
}): boolean {
  if (!isAttackAction(defender.action)) return false;
  return defender.attackElapsed < STAGE_PROFILES[defender.attackStage].start;
}

export function getCounterDamage(kind: AttackKind): number {
  return ATTACK_SPECS[kind].damage + COUNTER_HIT.bonusDamage;
}

export function decideWinner(playerHealth: number, rivalHealth: number): Winner {
  if (playerHealth === rivalHealth) return 'draw';
  return playerHealth > rivalHealth ? 'player' : 'rival';
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

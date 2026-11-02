export type AttackKind = 'light' | 'heavy' | 'head' | 'upper';
export type AttackStage = 'jab1' | 'jab2' | 'power' | 'head' | 'upper';
export type Winner = 'player' | 'rival' | 'draw';
export type ComboStep = 0 | 1 | 2;

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

type BlockingState = {
  x: number;
  facing: number;
  blocking: boolean;
  grounded: boolean;
};

const ATTACK_PROFILES: Record<AttackStage, {
  start: number;
  end: number;
  duration: number;
  reach: number;
  yOffset: number;
}> = {
  jab1: { start: 0.08, end: 0.21, duration: 0.29, reach: 62 * 0.72 * 1.12, yOffset: 2 },
  jab2: { start: 0.06, end: 0.18, duration: 0.25, reach: 49 * 1.12, yOffset: -4 },
  head: { start: 0.16, end: 0.34, duration: 0.48, reach: 83, yOffset: -24 },
  upper: { start: 0.12, end: 0.24, duration: 0.4, reach: 80, yOffset: -30 },
  power: { start: 0.16, end: 0.34, duration: 0.48, reach: 83, yOffset: 32 },
};

export const COMBO_WINDOW_SECONDS = 0.72;
export const COMBO_BUFFER_OPEN_AT = 0.14;

export function isComboFollowup(
  comboStep: ComboStep,
  kind: AttackKind,
  windowOpen: boolean,
): boolean {
  if (!windowOpen) return false;
  return (comboStep === 1 && kind === 'light') ||
    (comboStep === 2 && (kind === 'heavy' || kind === 'head'));
}

export function canBufferComboInput(
  comboStep: ComboStep,
  kind: AttackKind,
  attackElapsed: number,
  comboWindow: number,
): boolean {
  return comboWindow > 0 &&
    attackElapsed >= COMBO_BUFFER_OPEN_AT &&
    isComboFollowup(comboStep, kind, true);
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

export function getComboStepAfterAttack(stage: AttackStage): ComboStep {
  if (stage === 'jab1') return 1;
  if (stage === 'jab2') return 2;
  return 0;
}

export function getAttackDuration(stage: AttackStage): number {
  return ATTACK_PROFILES[stage].duration;
}

export function getStrikePose(
  kind: AttackKind,
  centerX: number,
  shoulderY: number,
  facing: number,
  stage: AttackStage = kind === 'head' || kind === 'upper' ? kind : kind === 'heavy' ? 'power' : 'jab1',
  attackElapsed?: number,
): StrikePose {
  const profile = ATTACK_PROFILES[stage];
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
    // Snap outward early, keep the exact existing reach through every active frame,
    // then pull back to guard in three ticks without shortening recovery/buffering.
    const extension = attackElapsed < profile.start
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

export function findPunchContact(
  attacker: PunchAttempt,
  fist: StrikePose,
  defender: FighterHurtbox,
): Point | null {
  if (attacker.hitRegistered) return null;

  const timing = ATTACK_PROFILES[attacker.stage];
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
    fist.x >= body.left && fist.x <= body.right &&
    fist.y >= body.top && fist.y <= body.bottom;
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

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export function isBlockingHit(attackerX: number, defender: BlockingState): boolean {
  return defender.blocking &&
    defender.grounded &&
    defender.facing === Math.sign(attackerX - defender.x);
}

export function attackDamage(kind: AttackKind, blocked: boolean): number {
  if (kind !== 'light') return blocked ? 4 : 15;
  return blocked ? 2 : 8;
}

export function decideWinner(playerHealth: number, rivalHealth: number): Winner {
  if (playerHealth === rivalHealth) return 'draw';
  return playerHealth > rivalHealth ? 'player' : 'rival';
}

export function isAttackAction(action: string): action is AttackKind {
  return action === 'light' || action === 'heavy' || action === 'head' || action === 'upper';
}

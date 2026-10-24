export type AttackKind = 'light' | 'heavy';
export type AttackStage = 'jab1' | 'jab2' | 'power';
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
  jab1: { start: 0.08, end: 0.21, duration: 0.29, reach: 62 * 0.72, yOffset: 2 },
  jab2: { start: 0.06, end: 0.18, duration: 0.25, reach: 49, yOffset: -4 },
  power: { start: 0.16, end: 0.34, duration: 0.48, reach: 83, yOffset: 8 },
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
    (comboStep === 2 && kind === 'heavy');
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
  stage: AttackStage = kind === 'heavy' ? 'power' : 'jab1',
): StrikePose {
  const profile = ATTACK_PROFILES[stage];
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
  if (kind === 'heavy') return blocked ? 4 : 15;
  return blocked ? 2 : 8;
}

export function decideWinner(playerHealth: number, rivalHealth: number): Winner {
  if (playerHealth === rivalHealth) return 'draw';
  return playerHealth > rivalHealth ? 'player' : 'rival';
}

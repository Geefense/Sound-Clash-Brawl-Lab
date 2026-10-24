export type AttackKind = 'light' | 'heavy';
export type Winner = 'player' | 'rival' | 'draw';

export type PunchAttempt = {
  centerX: number;
  attackFacing: number;
  attackElapsed: number;
  hitRegistered: boolean;
  kind: AttackKind;
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

const ATTACK_TIMING: Record<AttackKind, { start: number; end: number; reach: number }> = {
  light: { start: 0.08, end: 0.21, reach: 62 * 0.72 },
  heavy: { start: 0.16, end: 0.34, reach: 83 },
};

export function getStrikePose(
  kind: AttackKind,
  centerX: number,
  shoulderY: number,
  facing: number,
): StrikePose {
  const reach = ATTACK_TIMING[kind].reach;
  const yOffset = kind === 'heavy' ? 8 : 2;
  return {
    x: centerX + facing * reach,
    y: shoulderY + yOffset,
    radius: 13,
  };
}

export function findPunchContact(
  attacker: PunchAttempt,
  fist: StrikePose,
  defender: FighterHurtbox,
): Point | null {
  if (attacker.hitRegistered) return null;

  const timing = ATTACK_TIMING[attacker.kind];
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

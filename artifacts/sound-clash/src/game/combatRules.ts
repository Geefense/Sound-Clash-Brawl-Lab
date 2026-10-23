export type AttackKind = 'light' | 'heavy';
export type Winner = 'player' | 'rival' | 'draw';

export type AttackState = {
  x: number;
  y: number;
  grounded: boolean;
  attackFacing: number;
  attackElapsed: number;
  hitRegistered: boolean;
  kind: AttackKind;
};

export type TargetState = {
  x: number;
  y: number;
  grounded: boolean;
};

type BlockingState = {
  x: number;
  facing: number;
  blocking: boolean;
  grounded: boolean;
};

const ATTACK_TIMING: Record<AttackKind, { start: number; end: number; reach: number }> = {
  light: { start: 0.08, end: 0.21, reach: 112 },
  heavy: { start: 0.16, end: 0.34, reach: 147 },
};

const ATTACK_VERTICAL_RANGE = 62;

export function canAttackHit(attacker: AttackState, defender: TargetState): boolean {
  if (attacker.hitRegistered) return false;

  const timing = ATTACK_TIMING[attacker.kind];
  if (attacker.attackElapsed < timing.start || attacker.attackElapsed > timing.end) return false;
  if (Math.sign(defender.x - attacker.x) !== attacker.attackFacing) return false;
  if (Math.abs(defender.x - attacker.x) > timing.reach) return false;
  if (Math.abs(defender.y - attacker.y) > ATTACK_VERTICAL_RANGE) return false;

  // Ground attacks must not tag a fighter who is passing over them.
  if (attacker.grounded && !defender.grounded) return false;

  return true;
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

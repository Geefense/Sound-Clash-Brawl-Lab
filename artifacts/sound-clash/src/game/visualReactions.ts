import type { AttackKind } from './combatRules.ts';

export type HitReaction = {
  kind: AttackKind;
  region: 'head' | 'body';
  direction: number;
  age: number;
};

// Pure presentation curves. These offsets never feed collision poses or fighter physics.
export function getHitReactionPose(hit: HitReaction | null) {
  const zero = { shoulderX: 0, headX: 0, headTilt: 0, compression: 0, shakeX: 0 };
  if (!hit) return zero;
  const duration = hit.kind === 'heavy' ? 17 : 11;
  if (hit.age >= duration) return zero;
  const strength = Math.pow(1 - Math.max(0, hit.age) / duration, 2);
  const heavy = hit.kind === 'heavy';
  const body = hit.region === 'body';
  return {
    shoulderX: hit.direction * (heavy ? 19 : 9) * strength,
    headX: hit.direction * (body ? 5 : heavy ? 18 : 12) * strength,
    headTilt: hit.direction * (heavy ? 0.32 : 0.2) * strength,
    compression: body ? (heavy ? 0.27 : 0.08) * strength : 0,
    shakeX: heavy && body ? Math.sin(hit.age * 2.7) * 5 * strength : 0,
  };
}

export function getKnockdownPose(ticks: number, freezeTicks: number, fallTicks: number, direction: number, heavy: boolean) {
  const progress = Math.max(0, Math.min(1, (ticks - freezeTicks) / fallTicks));
  const launch = Math.sin(Math.PI * progress);
  const impactAge = ticks - freezeTicks - fallTicks;
  // A short rebound follows contact, then the body stays flat for the announcement/results.
  const rebound = impactAge > 0 && impactAge < 7 ? Math.sin(impactAge / 7 * Math.PI) * 7 : 0;
  return {
    x: direction * (heavy ? 64 : 38) * (1 - Math.pow(1 - progress, 3)),
    y: -(heavy ? 64 : 43) * launch - 22 * progress - rebound,
    angle: direction * Math.PI / 2 * Math.pow(progress, 0.68),
    progress,
    impact: impactAge >= 0 && impactAge < 10 ? 1 - impactAge / 10 : 0,
  };
}

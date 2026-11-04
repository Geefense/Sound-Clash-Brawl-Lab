import type { HitReaction } from './simulation/types.ts';

export type { HitReaction } from './simulation/types.ts';
export { getKnockdownPose } from './fighterGeometry.ts';
export type { KnockdownPose } from './fighterGeometry.ts';

/**
 * Pure presentation curves for hit recoil. These offsets never feed collision
 * poses or fighter physics; the simulation owns everything that can be hit.
 */
export function getHitReactionPose(hit: HitReaction | null | undefined) {
  const zero = { shoulderX: 0, headX: 0, headTilt: 0, compression: 0, shakeX: 0, stumble: 0 };
  if (!hit) return zero;
  const duration = hit.kind !== 'light' ? 17 : 11;
  if (hit.age >= duration) return zero;
  const strength = Math.pow(1 - Math.max(0, hit.age) / duration, 2);
  const heavy = hit.kind !== 'light';
  const body = hit.region === 'body';
  const heavyBody = heavy && body;
  return {
    shoulderX: hit.direction * (heavyBody ? 27 : heavy ? 19 : 9) * strength,
    headX: hit.direction * (body ? 5 : heavy ? 18 : 12) * strength,
    headTilt: hit.direction * (hit.kind === 'upper' ? 0.48 : body ? 0.04 : heavy ? 0.32 : 0.2) * strength,
    compression: body ? (heavy ? 0.34 : 0.08) * strength : 0,
    stumble: hit.kind === 'upper' ? Math.sin(hit.age * 0.8) * 8 * strength : 0,
    shakeX: heavy && body ? Math.sin(hit.age * 2.7) * 7 * strength : 0,
  };
}

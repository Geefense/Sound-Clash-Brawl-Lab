import type { HitReaction } from './simulation/types.ts';

export type { HitReaction } from './simulation/types.ts';
export { getKnockdownPose } from './fighterGeometry.ts';
export type { KnockdownPose } from './fighterGeometry.ts';

/**
 * Pure presentation curves for hit recoil. These offsets never feed collision
 * poses or fighter physics; the simulation owns everything that can be hit.
 */
export type HitReactionPose = {
  shoulderX: number;
  headX: number;
  headTilt: number;
  /** Rotation of the whole upper body around the hip. */
  torsoTwist: number;
  /** Visual pop off the floor (Upper Box only). */
  lift: number;
  compression: number;
  shakeX: number;
  stumble: number;
};

const NEUTRAL: HitReactionPose = {
  shoulderX: 0,
  headX: 0,
  headTilt: 0,
  torsoTwist: 0,
  lift: 0,
  compression: 0,
  shakeX: 0,
  stumble: 0,
};

export function getHitReactionPose(hit: HitReaction | null | undefined): HitReactionPose {
  if (!hit) return { ...NEUTRAL };
  const duration = hit.kind !== 'light' ? 17 : 11;
  if (hit.age >= duration) return { ...NEUTRAL };

  // Snappier than a linear decay: the first frames carry most of the motion.
  const strength = Math.pow(1 - Math.max(0, hit.age) / duration, 1.8);
  const heavy = hit.kind !== 'light';
  const body = hit.region === 'body';
  const heavyBody = heavy && body;

  const shoulder = heavyBody
    ? 30
    : hit.kind === 'head'
      ? 25
      : hit.kind === 'upper'
        ? 22
        : heavy
          ? 21
          : 11;
  const headSnap = body
    ? 6
    : hit.kind === 'head'
      ? 30
      : hit.kind === 'upper'
        ? 28
        : heavy
          ? 26
          : 14;
  const tilt = hit.kind === 'upper'
    ? 0.62
    : hit.kind === 'head'
      ? 0.46
      : body
        ? 0.04
        : heavy
          ? 0.4
          : 0.24;
  const twist = body
    ? 0.05
    : hit.kind === 'upper'
      ? 0.28
      : hit.kind === 'head'
        ? 0.16
        : heavy
          ? 0.11
          : 0.06;

  return {
    shoulderX: hit.direction * shoulder * strength,
    headX: hit.direction * headSnap * strength,
    headTilt: hit.direction * tilt * strength,
    torsoTwist: hit.direction * twist * strength,
    lift: hit.kind === 'upper' ? 5 * strength : 0,
    compression: body ? (heavy ? 0.38 : 0.08) * strength : 0,
    stumble: hit.kind === 'upper' ? Math.sin(hit.age * 0.8) * 9 * strength : 0,
    shakeX: heavyBody ? Math.sin(hit.age * 2.7) * 8 * strength : 0,
  };
}

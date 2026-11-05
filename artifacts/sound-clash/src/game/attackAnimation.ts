/**
 * Presentation poses for the two hand strikes: the K backhand BOX and the
 * I Upper Box.
 *
 * These are the only attacks drawn as real limbs (shoulder -> elbow -> hand)
 * instead of a fist on a straight line, so both share one anatomical arm
 * length and one two-bone solver. Frame data still comes from
 * `combatConfig.ts`: during active frames the hand is placed on the collision
 * pose, and the wind-up / follow-through live outside that window.
 *
 * Nothing here mutates state or imports Phaser.
 */
import { STAGE_PROFILES } from './combatConfig.ts';
import { getStrikePose } from './combatRules.ts';
import type { Point } from './combatRules.ts';

export type AttackAnimationKind = 'head' | 'upper';

export type AttackArmParams = {
  action: AttackAnimationKind;
  centerX: number;
  shoulderY: number;
  /** Hip line: the torso, shoulders and head all rotate around it. */
  hipY: number;
  facing: number;
  /** Seconds since the stage started (the scene's `attackElapsed`). */
  elapsed: number;
  /** The Upper Box that closes the Three Piece gets a taller finish. */
  finisher?: boolean;
};

export type SwipeTrail = {
  cx: number;
  cy: number;
  radius: number;
  from: number;
  to: number;
  anticlockwise: boolean;
  alpha: number;
};

export type ArmPose = {
  /** Shoulder joint, already rotated with the torso. */
  shoulder: Point;
  elbow: Point;
  hand: Point;
  /** Rotation that points the open hand along the forearm. */
  handAngle: number;
  /** Torso rotation about the hip, radians, canvas space. */
  twist: number;
  trail: SwipeTrail | null;
};

/**
 * One arm, one length. The hand cannot be drawn further from the shoulder
 * than this, so no pose can look like a stretched rubber arm.
 */
export const ARM_SEGMENTS = { upperArm: 42, forearm: 40 } as const;
export const ARM_LENGTH = ARM_SEGMENTS.upperArm + ARM_SEGMENTS.forearm;

const SHOULDER_X = 17;
const SHOULDER_Y = 11;

export function getAttackArmPose(params: AttackArmParams): ArmPose {
  const { action, centerX, shoulderY, hipY, facing, elapsed } = params;
  const finisher = params.finisher ?? false;
  const profile = STAGE_PROFILES[action];
  const { start, end, duration } = profile;
  const guard: Point = { x: centerX + facing * 28, y: shoulderY + 29 };

  let target: Point;
  let twistValue: number;
  let trailFrom: Point | null = null;
  let trailAlpha = 0;

  if (action === 'head') {
    // A backhand: the hand coils across the body on the far shoulder, whips
    // out through the head line, then keeps travelling on the follow-through.
    const strike: Point = { x: centerX + facing * profile.reach, y: shoulderY + profile.yOffset };
    const coil: Point = { x: centerX - facing * 24, y: shoulderY - 20 };

    if (elapsed < start) {
      const p = clamp01(elapsed / start);
      if (p < 0.62) {
        target = mixPoint(guard, coil, easeOut(p / 0.62));
        twistValue = lerp(-0.05, -0.17, easeOut(p / 0.62));
      } else {
        const q = easeInOut((p - 0.62) / 0.38);
        target = quadratic(
          coil,
          { x: (coil.x + strike.x) / 2, y: Math.min(coil.y, strike.y) - 6 },
          strike,
          q,
        );
        twistValue = lerp(-0.17, 0.06, q);
      }
      trailFrom = coil;
      trailAlpha = p > 0.7 ? ((p - 0.7) / 0.3) * 0.2 : 0;
    } else if (elapsed <= end) {
      // Active frames: sweep across the face, staying inside the fist radius.
      const u = clamp01((elapsed - start) / Math.max(0.001, end - start));
      target = { x: strike.x - facing * 7 * (1 - u), y: strike.y - 9 * (1 - u) };
      twistValue = lerp(0.06, 0.12, easeInOut(u));
      trailFrom = coil;
      trailAlpha = 0.3;
    } else {
      const v = clamp01((elapsed - end) / Math.max(0.001, duration - end));
      const follow: Point = { x: centerX + facing * (profile.reach + 14), y: shoulderY + 8 };
      if (v < 0.5) {
        const q = easeOut(v / 0.5);
        target = quadratic(strike, { x: strike.x + facing * 8, y: strike.y - 2 }, follow, q);
        twistValue = lerp(0.12, 0.24, q);
        trailAlpha = 0.3 * (1 - v / 0.55);
      } else {
        const q = smoothstep((v - 0.5) / 0.5);
        target = mixPoint(follow, guard, q);
        twistValue = lerp(0.24, 0, q);
        trailAlpha = 0;
      }
      trailFrom = coil;
    }
  } else {
    // An uppercut swung like a bat: load low and behind the hip, drive the
    // hand up through the head line, finish overhead.
    const low: Point = { x: centerX - facing * 10, y: shoulderY + 52 };
    const strikeAt = (t: number) => getStrikePose('upper', centerX, shoulderY, facing, 'upper', t);

    if (elapsed < start) {
      const p = clamp01(elapsed / start);
      if (p < 0.7) {
        target = mixPoint(guard, low, easeOut(p / 0.7));
        twistValue = lerp(0, -0.15, easeOut(p / 0.7));
      } else {
        const q = easeInOut((p - 0.7) / 0.3);
        target = quadratic(
          low,
          { x: centerX + facing * 10, y: shoulderY + 26 },
          strikeAt(start),
          q,
        );
        twistValue = lerp(-0.15, -0.11, q);
      }
      trailFrom = low;
      trailAlpha = p > 0.75 ? ((p - 0.75) / 0.25) * 0.18 : 0;
    } else if (elapsed <= end) {
      const u = clamp01((elapsed - start) / Math.max(0.001, end - start));
      target = strikeAt(elapsed);
      twistValue = lerp(-0.11, 0.12, easeInOut(u));
      trailFrom = low;
      trailAlpha = 0.34;
    } else {
      const v = clamp01((elapsed - end) / Math.max(0.001, duration - end));
      const overhead: Point = {
        x: centerX + facing * profile.reach * (finisher ? 0.6 : 0.72),
        y: shoulderY - (finisher ? 96 : 78),
      };
      const peak = finisher ? 0.3 : 0.22;
      if (v < 0.55) {
        const q = easeOut(v / 0.55);
        target = quadratic(
          strikeAt(end),
          { x: centerX + facing * profile.reach * 0.9, y: shoulderY - (finisher ? 84 : 68) },
          overhead,
          q,
        );
        twistValue = lerp(0.12, peak, q);
        trailAlpha = 0.34 * (1 - v / 0.6);
      } else {
        const q = smoothstep((v - 0.55) / 0.45);
        target = mixPoint(overhead, guard, q);
        twistValue = lerp(peak, 0, q);
        trailAlpha = 0;
      }
      trailFrom = { x: centerX + facing * 6, y: shoulderY + 34 };
    }
  }

  const pivot: Point = { x: centerX, y: hipY };
  const twist = facing * twistValue;
  const shoulder = rotatePoint(
    { x: centerX + facing * SHOULDER_X, y: shoulderY + SHOULDER_Y },
    pivot,
    twist,
  );
  const { elbow, hand } = solveElbow(shoulder, target);
  const forearmAngle = Math.atan2(hand.y - elbow.y, hand.x - elbow.x);
  const trail =
    trailFrom && trailAlpha > 0.01
      ? buildTrail(shoulder, rotatePoint(trailFrom, pivot, twist), hand, trailAlpha)
      : null;

  return {
    shoulder,
    elbow,
    hand,
    // The hand art points along its own -y, so aligning it with the forearm
    // keeps the palm open and correctly oriented through the whole swing.
    handAngle: forearmAngle + Math.PI / 2,
    twist,
    trail,
  };
}

/** Rotate a point around a pivot, matching canvas rotation (y grows down). */
export function rotatePoint(point: Point, pivot: Point, angle: number): Point {
  if (!angle) return { x: point.x, y: point.y };
  const cos = Math.cos(angle);
  const sin = Math.sin(angle);
  const dx = point.x - pivot.x;
  const dy = point.y - pivot.y;
  return {
    x: pivot.x + dx * cos - dy * sin,
    y: pivot.y + dx * sin + dy * cos,
  };
}

/**
 * Two-bone IK. The elbow hangs below the shoulder-to-hand line, which reads as
 * a real joint in every pose and never stretches either segment.
 */
function solveElbow(shoulder: Point, target: Point): { elbow: Point; hand: Point } {
  const dx = target.x - shoulder.x;
  const dy = target.y - shoulder.y;
  const raw = Math.hypot(dx, dy) || 1;
  const distance = Math.max(1, Math.min(raw, ARM_LENGTH - 0.001));
  const ux = dx / raw;
  const uy = dy / raw;
  const hand: Point = { x: shoulder.x + ux * distance, y: shoulder.y + uy * distance };

  const a = ARM_SEGMENTS.upperArm;
  const b = ARM_SEGMENTS.forearm;
  const along = (a * a - b * b + distance * distance) / (2 * distance);
  const height = Math.sqrt(Math.max(0, a * a - along * along));
  let perp = { x: -uy, y: ux };
  if (perp.y < 0) perp = { x: uy, y: -ux };

  return {
    elbow: {
      x: shoulder.x + ux * along + perp.x * height,
      y: shoulder.y + uy * along + perp.y * height,
    },
    hand,
  };
}

function buildTrail(shoulder: Point, from: Point, hand: Point, alpha: number): SwipeTrail {
  const radius = Math.max(18, Math.hypot(hand.x - shoulder.x, hand.y - shoulder.y) * 0.94);
  const fromAngle = Math.atan2(from.y - shoulder.y, from.x - shoulder.x);
  const toAngle = Math.atan2(hand.y - shoulder.y, hand.x - shoulder.x);
  return {
    cx: shoulder.x,
    cy: shoulder.y,
    radius,
    from: fromAngle,
    to: toAngle,
    // Canvas y grows down, so a clockwise screen sweep is a negative delta.
    anticlockwise: Math.sin(toAngle - fromAngle) < 0,
    alpha,
  };
}

function mixPoint(from: Point, to: Point, t: number): Point {
  return { x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t };
}

function quadratic(from: Point, control: Point, to: Point, t: number): Point {
  const inverse = 1 - t;
  return {
    x: inverse * inverse * from.x + 2 * inverse * t * control.x + t * t * to.x,
    y: inverse * inverse * from.y + 2 * inverse * t * control.y + t * t * to.y,
  };
}

function lerp(from: number, to: number, t: number): number {
  return from + (to - from) * t;
}

function clamp01(value: number): number {
  return Math.max(0, Math.min(1, value));
}

function easeOut(t: number): number {
  return 1 - Math.pow(1 - t, 3);
}

function easeInOut(t: number): number {
  return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
}

function smoothstep(t: number): number {
  return t * t * (3 - 2 * t);
}

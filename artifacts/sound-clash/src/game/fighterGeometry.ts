/**
 * One authoritative movement/pose model.
 *
 * The simulation resolves collisions with these numbers and the renderer draws
 * with the exact same numbers, so a visible fist is the fist that hits.
 * Nothing here depends on Phaser.
 */
import type { FighterState } from './simulation/types.ts';
import { KO_SEQUENCE } from './combatConfig.ts';

export const FLOOR = 574;
export const LEFT_BOUND = 92;
export const RIGHT_BOUND = 1188;
export const BASE_Y_OFFSET = 2;

/** Torso hurtbox, relative to the fighter centre and shoulder line. */
export const TORSO_LEFT = -27;
export const TORSO_RIGHT = 28;
export const TORSO_HEIGHT = 65;
export const HEAD_OFFSET = 3;
export const HEAD_RADIUS = 22;

/** Body proportions used by both the pose and the drawing code. */
export const HIP_FROM_FLOOR = 68;
export const HIP_TO_SHOULDER = 42;
export const SHOULDER_TO_HEAD = 30;
export const BLOCK_CROUCH = 19;
export const BOB_WALK = 5;
export const BOB_IDLE = 2;

export type FighterPose = {
  baseY: number;
  moving: boolean;
  bob: number;
  crouch: number;
  hipY: number;
  shoulderY: number;
  headY: number;
};

export type Rect = { left: number; right: number; top: number; bottom: number };
export type Circle = { x: number; y: number; radius: number };
export type FighterHurtbox = { centerX: number; body: Rect; head: Circle };

/**
 * The pose of a fighter in world space. `blocking` raises the torso by
 * `BLOCK_CROUCH`; the hurtbox below applies the same offset downwards so a
 * crouching guard does not silently shrink or stretch the target.
 */
export function getFighterPose(f: FighterState): FighterPose {
  const baseY = FLOOR + BASE_Y_OFFSET + f.y;
  const moving = Math.abs(f.vx) > 8 && f.grounded;
  const bob = f.grounded ? Math.sin(f.anim) * (moving ? BOB_WALK : BOB_IDLE) : 0;
  const crouch = f.blocking ? BLOCK_CROUCH : 0;
  const hipY = baseY - HIP_FROM_FLOOR - crouch + bob;
  const shoulderY = hipY - HIP_TO_SHOULDER;
  return { baseY, moving, bob, crouch, hipY, shoulderY, headY: shoulderY - SHOULDER_TO_HEAD };
}

export function getHurtbox(f: FighterState, pose: FighterPose = getFighterPose(f)): FighterHurtbox {
  return {
    centerX: f.x,
    body: {
      left: f.x + TORSO_LEFT,
      right: f.x + TORSO_RIGHT,
      top: pose.shoulderY,
      bottom: pose.shoulderY + TORSO_HEIGHT + pose.crouch,
    },
    head: {
      x: f.x + f.facing * HEAD_OFFSET,
      y: pose.headY,
      radius: HEAD_RADIUS,
    },
  };
}

export type KnockdownPose = {
  x: number;
  y: number;
  angle: number;
  progress: number;
  impact: number;
  /** 1 on the landing frame, easing to 0; drives the landing squash. */
  squash: number;
};

/**
 * The one and only knockdown/KO trajectory. The simulation applies these
 * offsets to the fighter's position; the renderer only rotates by `angle`.
 * y is 0 at rest (the fighter's y convention: negative means airborne).
 */
export function getKnockdownPose(
  ticks: number,
  freezeTicks: number,
  fallTicks: number,
  direction: number,
  heavy: boolean,
): KnockdownPose {
  const raw = Math.max(0, Math.min(1, (ticks - freezeTicks) / fallTicks));
  // Snap the endpoints so a resting body sits at exactly y = 0.
  const progress = raw >= 1 ? 1 : raw;
  const launch = progress >= 1 ? 0 : Math.sin(Math.PI * progress);
  const impactAge = ticks - freezeTicks - fallTicks;
  const rebound = impactAge > 0 && impactAge < 7 ? Math.sin((impactAge / 7) * Math.PI) * 6 : 0;
  const slide = heavy ? KO_SEQUENCE.knockdownSlide : KO_SEQUENCE.knockdownSlideLight;
  const height = heavy ? KO_SEQUENCE.knockdownLaunch : KO_SEQUENCE.knockdownLaunchLight;
  // Fly first, then skid: almost no sideways drift while airborne, most of the
  // distance covered on the floor. That kills the old floating slide.
  const travel = Math.pow(progress, 2.4);
  const squash = impactAge >= 0 && impactAge < 8 ? 1 - impactAge / 8 : 0;
  const y = -height * launch - rebound;
  return {
    x: direction * slide * travel,
    // Normalise negative zero so a resting body compares equal to 0.
    y: y === 0 ? 0 : y,
    angle: (direction * Math.PI * Math.pow(progress, 0.68)) / 2,
    progress,
    impact: impactAge >= 0 && impactAge < 10 ? 1 - impactAge / 10 : 0,
    squash,
  };
}

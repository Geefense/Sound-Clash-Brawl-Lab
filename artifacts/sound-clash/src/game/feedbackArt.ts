/**
 * Feedback's painted pose pack, wired to the game's *rendering* only.
 *
 * The 17 transparent poses are illustrations, not a rig: nothing here drives
 * timing, damage, collision or the deterministic simulation. These helpers
 * answer two questions — which picture matches the simulation state, and where
 * its anchor sits — so `GameScene` can draw a sprite instead of the vector
 * fighter without changing a single frame of combat.
 *
 * Origins, facings and placements mirror `public/assets/feedback/feedback.poses.json`
 * exactly; `tests/feedbackArt.test.mjs` fails if the two ever drift apart.
 */
import type { FighterState } from './simulation/types.ts';
import { STAGE_PROFILES } from './combatConfig.ts';

export type FeedbackPoseId =
  | '01_idle'
  | '02_knockout'
  | '03_c_recoil'
  | '04_inverted_c'
  | '05_dizzy_bogle'
  | '06_rear_salute'
  | '07_crouch'
  | '08_block'
  | '09_point'
  | '10_fire_airborne'
  | '11_fire_grounded'
  | '12_backhand_windup'
  | '13_box_palm'
  | '14_followthrough'
  | '15_skank'
  | '16_gut_punch'
  | '17_seated_landing';

export type FeedbackPoseMeta = {
  /** Path relative to `/assets/feedback/`. */
  file: string;
  /** Normalised anchor inside the 1536x1024 canvas. */
  origin: readonly [number, number];
  /** Direction the art was painted facing. */
  facing: 'left' | 'right' | 'away';
  /** Which anatomical point `origin` marks. */
  placement: 'feet' | 'pelvis' | 'ground_contact';
};

export const FEEDBACK_TEXTURE_PREFIX = 'feedback-';
export const FEEDBACK_CANVAS = { width: 1536, height: 1024 } as const;
/**
 * One scale for every pose, so the character never grows or shrinks between
 * pictures. The painted figure is ~488 px tall inside the canvas; 0.44 renders
 * it ~215 px, which matches the arena's readable fighter height (the vector
 * figure was ~170 px but has a much larger head, so it read bigger).
 * Anchoring is unaffected by scale: the origin stays on the feet or pelvis.
 */
export const FEEDBACK_SCALE = 0.44;

export const FEEDBACK_POSES: Record<FeedbackPoseId, FeedbackPoseMeta> = {
  '01_idle': { file: 'aligned/01_idle.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '02_knockout': { file: 'aligned/02_knockout.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'ground_contact' },
  '03_c_recoil': { file: 'aligned/03_c_recoil.png', origin: [0.5, 0.595703125], facing: 'right', placement: 'pelvis' },
  '04_inverted_c': { file: 'aligned/04_inverted_c.png', origin: [0.5, 0.595703125], facing: 'right', placement: 'pelvis' },
  '05_dizzy_bogle': { file: 'aligned/05_dizzy_bogle.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '06_rear_salute': { file: 'aligned/06_rear_salute.png', origin: [0.5, 0.595703125], facing: 'away', placement: 'pelvis' },
  '07_crouch': { file: 'aligned/07_crouch.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '08_block': { file: 'aligned/08_block.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '09_point': { file: 'aligned/09_point.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '10_fire_airborne': { file: 'aligned/10_fire_airborne.png', origin: [0.5, 0.595703125], facing: 'right', placement: 'pelvis' },
  '11_fire_grounded': { file: 'aligned/11_fire_grounded.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '12_backhand_windup': { file: 'aligned/12_backhand_windup.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '13_box_palm': { file: 'aligned/13_box_palm.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '14_followthrough': { file: 'aligned/14_followthrough.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'feet' },
  '15_skank': { file: 'aligned/15_skank.png', origin: [0.5, 0.595703125], facing: 'right', placement: 'pelvis' },
  '16_gut_punch': { file: 'aligned/16_gut_punch.png', origin: [0.5, 0.595703125], facing: 'left', placement: 'pelvis' },
  '17_seated_landing': { file: 'aligned/17_seated_landing.png', origin: [0.5, 0.87890625], facing: 'right', placement: 'ground_contact' },
};

export const FEEDBACK_POSE_IDS = Object.keys(FEEDBACK_POSES) as FeedbackPoseId[];

export function feedbackTextureKey(pose: FeedbackPoseId): string {
  return `${FEEDBACK_TEXTURE_PREFIX}${pose}`;
}

export function feedbackAssetUrl(pose: FeedbackPoseId): string {
  return `/assets/feedback/${FEEDBACK_POSES[pose].file}`;
}

/** Rendering-only view of the simulation, so this stays a pure function. */
export type FeedbackView = {
  knockedDown: boolean;
  /** Knockdown/KO progress, 0 at launch, 1 at rest. */
  fallProgress: number;
  /** The KO body has finished falling and is lying still. */
  koResting: boolean;
};

/**
 * Maps the simulation's action to one of the painted poses.
 * The pack's own state table (idle/guard/box windup-contact-recovery/hurt)
 * is honoured; upper and TUMP borrow the closest painted pose because the pack
 * has no dedicated frame for them.
 */
export function selectFeedbackPose(f: FighterState, view: FeedbackView): FeedbackPoseId {
  if (view.knockedDown) {
    if (view.koResting) return '02_knockout';
    if (view.fallProgress < 0.42) return '03_c_recoil';
    if (view.fallProgress < 0.94) return '04_inverted_c';
    return '17_seated_landing';
  }
  if (f.action === 'hit') return '16_gut_punch';
  if (f.blocking) return '08_block';
  if (f.action === 'head' || f.action === 'upper' || f.action === 'light' || f.action === 'heavy') {
    const profile = STAGE_PROFILES[f.attackStage];
    if (f.attackElapsed < profile.start) {
      if (f.action === 'head') return '12_backhand_windup';
      if (f.action === 'upper') return '07_crouch';
      return '09_point';
    }
    if (f.attackElapsed <= profile.end) {
      return f.action === 'heavy' ? '16_gut_punch' : '13_box_palm';
    }
    return '14_followthrough';
  }
  return '01_idle';
}

/** Mirror only when the painted facing disagrees with the fighter's; never flip the rear view. */
export function shouldMirrorPose(poseFacing: FeedbackPoseMeta['facing'], facing: number): boolean {
  if (poseFacing === 'away') return false;
  return poseFacing === 'left' ? facing > 0 : facing < 0;
}

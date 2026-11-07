/**
 * Sprite rig for the Sound Clash fighter silhouette.
 *
 * IMPORTANT: this rig is NOT Feedback. No Feedback source artwork exists in
 * this repository (see art-source/feedback/README.md), so the sample sheet is
 * rendered from the only character artwork the repo actually owns: the
 * procedural fighter drawn in src/game/GameScene.ts.
 *
 * Skeleton numbers are imported from the game's own modules, never copied, so
 * a sprite can not silently drift away from the hurtbox it will sit on:
 *   - fighterGeometry.ts  -> hip/shoulder/head heights, torso box, head radius
 *   - combatConfig.ts     -> per-attack reach and fist height
 *   - visualReactions.ts  -> recoil offsets for the hit frames
 *
 * Coordinate space is the game's: y grows downwards, the floor is 0 and the
 * fighter stands with `groundY` under the shoes. Sprites face +x (right) by
 * default; flip on x for a left-facing fighter.
 */
import {
  HEAD_OFFSET,
  HEAD_RADIUS,
  HIP_FROM_FLOOR,
  HIP_TO_SHOULDER,
  SHOULDER_TO_HEAD,
  TORSO_HEIGHT,
  TORSO_LEFT,
  TORSO_RIGHT,
} from '../../src/game/fighterGeometry.ts';
import { STAGE_PROFILES } from '../../src/game/combatConfig.ts';
import { getHitReactionPose } from '../../src/game/visualReactions.ts';

/** Output multiplier over the game's logical units. */
export const SCALE = 2;

/**
 * One frame box for every pose. The head, the extended fist and the raised
 * foot all have to fit, so the box is sized once and never per pose: that is
 * what keeps the atlas free of jitter.
 */
export const FRAME = {
  width: 220,
  height: 200,
  centerX: 110,
  /** Sole line. Identical in every frame so the feet never float or sink. */
  groundY: 188,
};

export const PALETTES = {
  'sidewinder': {
    label: 'Sidewinder (existing in-game palette)',
    jacket: 0x247c72,
    accent: 0xf0c64c,
    skin: 0x9d6545,
    skinShade: 0x84523a,
    shoeBack: 0xe7dfc9,
    sole: 0xcfc1a3,
    hatBrim: 0x182d32,
    hatCrown: 0xf0c64c,
    hair: 0x1b2729,
    detail: 0x553a30,
    eye: 0x1b2729,
    flash: 0xffe4a8,
  },
  'sidewinder-alt': {
    label: 'Sidewinder alternate (two-player test)',
    jacket: 0x3d4d8f,
    accent: 0xe0563c,
    skin: 0x9d6545,
    skinShade: 0x84523a,
    shoeBack: 0xf2eee1,
    sole: 0xd8cbb0,
    hatBrim: 0x1c2136,
    hatCrown: 0xe0563c,
    hair: 0x1b2729,
    detail: 0x5a3b34,
    eye: 0x1b2729,
    flash: 0xffe4a8,
  },
};

/**
 * Skanking idle: four frames of a one-foot bounce. The hip drops on the
 * off-beat, weight shifts side to side and exactly one heel leaves the floor.
 * `front`/`back` are lift amounts (0..1), never poses of their own, so the
 * planted foot stays welded to the sole line.
 */
const IDLE_PHASES = [
  { hip: 0, weight: 0, front: 0, back: 0, roll: 0 },
  { hip: -3.5, weight: -1, front: 0, back: 1, roll: -1.5 },
  { hip: -1, weight: 0, front: 0.3, back: 0, roll: 0 },
  { hip: -4.5, weight: 1, front: 1, back: 0, roll: 1.5 },
];

const lerp = (a, b, t) => a + (b - a) * t;
const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);
const easeOut = (t) => 1 - Math.pow(1 - clamp01(t), 3);

/** Samples per frame plus per-frame duration, consumed by the preview page. */
export const CLIPS = [
  {
    name: 'idle-skank',
    label: 'Idle — skanking, one-foot bounce',
    frameMs: 130,
    loop: true,
    frames: [0, 1, 2, 3].map((phase) => ({ pose: 'idle', phase })),
  },
  {
    name: 'jab',
    label: 'Jab — bent elbow, snaps straight',
    frameMs: 80,
    frames: [{ pose: 'jab', t: 0.05 }, { pose: 'jab', t: 0.14 }, { pose: 'jab', t: 0.27 }],
  },
  {
    name: 'tump',
    label: 'BOOM — body shot (TUMP)',
    frameMs: 110,
    frames: [{ pose: 'tump', t: 0.1 }, { pose: 'tump', t: 0.24 }, { pose: 'tump', t: 0.43 }],
  },
  {
    name: 'box',
    label: 'BOX — sweeping backhand to the head',
    frameMs: 110,
    frames: [{ pose: 'box', t: 0.1 }, { pose: 'box', t: 0.24 }, { pose: 'box', t: 0.44 }],
  },
  {
    name: 'block',
    label: 'Block — high guard',
    frameMs: 160,
    frames: [{ pose: 'block' }],
  },
  {
    name: 'hit',
    label: 'Hit reactions',
    frameMs: 120,
    frames: [
      { pose: 'hit', region: 'head', age: 2 },
      { pose: 'hit', region: 'body', age: 3 },
    ],
  },
];

export function frameList() {
  const list = [];
  for (const clip of CLIPS) {
    clip.frames.forEach((frame, index) => {
      list.push({ ...frame, clip: clip.name, clipFrame: index });
    });
  }
  return list;
}

/**
 * Where the fist sits for each attack, in the same numbers the collision code
 * uses. `t` is seconds into the attack.
 */
function strikePoint(pose, t, cx, shoulderY, facing) {
  if (pose === 'jab') {
    const p = STAGE_PROFILES.jab1;
    const extension =
      t < p.start
        ? easeOut(t / p.start)
        : 1 - clamp01((t - p.end) / 0.05);
    return {
      x: cx + facing * lerp(24, p.reach, extension),
      y: shoulderY + lerp(29, p.yOffset, extension),
      extension,
      shoulder: { x: cx + facing * 18, y: shoulderY + 9 },
    };
  }
  if (pose === 'tump') {
    const p = STAGE_PROFILES.power;
    const extension =
      t < p.start ? easeOut((t - 0.04) / (p.start - 0.04)) : 1 - clamp01((t - p.end) / 0.12) * 0.35;
    return {
      x: cx + facing * lerp(26, p.reach, extension),
      y: shoulderY + lerp(29, p.yOffset, extension),
      extension,
      shoulder: { x: cx + facing * 18, y: shoulderY + 9 },
    };
  }
  // Backhand BOX: the fist travels up and across at head height.
  const p = STAGE_PROFILES.head;
  const extension =
    t < p.start ? easeOut((t - 0.04) / (p.start - 0.04)) : 1 - clamp01((t - p.end) / 0.12) * 0.4;
  return {
    x: cx + facing * lerp(24, p.reach, extension),
    y: shoulderY + lerp(29, p.yOffset, extension),
    extension,
    shoulder: { x: cx + facing * 18, y: shoulderY + 9 },
  };
}

/** Sweep trail: a fading arc of discs behind the backhand fist. */
function sweepTrail(ctx, cx, cy, radius, from, to, color, strength) {
  const steps = 14;
  for (let i = 0; i < steps; i++) {
    const t = i / (steps - 1);
    const angle = lerp(from, to, t);
    const alpha = 0.26 * strength * (0.35 + 0.65 * t);
    ctx.fillCircle(
      cx + Math.cos(angle) * radius,
      cy + Math.sin(angle) * radius,
      3.2 + 2.6 * t,
      color,
      alpha,
    );
  }
}

export function drawFrame(ctx, frame, palette) {
  const P = palette;
  const facing = frame.facing ?? 1;
  const f = facing;
  const cxBase = FRAME.centerX;
  const ground = FRAME.groundY;

  let hipDelta = 0;
  let roll = 0;
  let weight = 0;
  let frontLift = 0;
  let backLift = 0;
  let bodyX = 0;
  let headExtraX = 0;
  let headTilt = 0;
  let compression = 0;
  let lean = 0;

  if (frame.pose === 'idle') {
    const phase = IDLE_PHASES[frame.phase % IDLE_PHASES.length];
    hipDelta = phase.hip;
    weight = phase.weight;
    frontLift = phase.front;
    backLift = phase.back;
    roll = phase.roll;
  } else if (frame.pose === 'block') {
    hipDelta = -8;
    roll = 1.5;
  } else if (frame.pose === 'hit') {
    const reaction = getHitReactionPose({
      kind: frame.region === 'body' ? 'heavy' : 'head',
      region: frame.region ?? 'head',
      direction: -f,
      age: frame.age ?? 2,
    });
    bodyX = reaction.shoulderX;
    headExtraX = reaction.headX - reaction.shoulderX;
    headTilt = reaction.headTilt;
    compression = reaction.compression;
    hipDelta = -reaction.compression * 6;
    roll = -reaction.compression * 8;
  } else if (frame.pose === 'tump' || frame.pose === 'box' || frame.pose === 'jab') {
    const t = frame.t ?? 0.1;
    const strike = strikePoint(frame.pose, t, cxBase, 0, 1);
    lean = (strike.extension - 0.35) * 5;
  }

  const cx = cxBase + bodyX * 0.6 + lean * 0.4;
  const hipY = ground - HIP_FROM_FLOOR + hipDelta;
  const shoulderY = hipY - HIP_TO_SHOULDER + compression * 6;
  const headY = shoulderY - SHOULDER_TO_HEAD;
  const shoulderShift = roll * 0.8;

  /* ------------------------------------------------------------- legs */
  const backHip = { x: cx - 8 + weight * 1.5, y: hipY };
  const frontHip = { x: cx + 8 + weight * 1.5, y: hipY };
  const backAnkle = { x: cx - 20 + weight * 2, y: ground - 15 - backLift * 12 };
  const frontAnkle = { x: cx + 22 + weight * 2, y: ground - 15 - frontLift * 13 };
  const backKnee = {
    x: (backHip.x + backAnkle.x) / 2 - 4 + f * 1,
    y: (backHip.y + backAnkle.y) / 2 + 2 - backLift * 4,
  };
  const frontKnee = {
    x: (frontHip.x + frontAnkle.x) / 2 + 4 + f * 1,
    y: (frontHip.y + frontAnkle.y) / 2 + 2 - frontLift * 5,
  };

  const shoe = (ankle, color) => {
    const left = f > 0 ? ankle.x - 15 : ankle.x - 19;
    ctx.fillRoundRect(left, ankle.y + 1, 34, 13, 5, color);
    ctx.fillRoundRect(left, ankle.y + 11, 34, 4, 2, P.sole);
  };

  // Soles land on exactly the same row in every frame: that is the anchor.
  const leg = (hip, knee, ankle, thighWidth, shinWidth) => {
    ctx.line(hip.x, hip.y, knee.x, knee.y, thighWidth, P.jacket);
    ctx.line(knee.x, knee.y, ankle.x, ankle.y - 1, shinWidth, P.jacket);
    // A short sock line; a long one reads as bare toes over the shoe.
    ctx.line(ankle.x, ankle.y - 6, ankle.x + f * 2, ankle.y - 1, 12, P.skin);
  };

  // Back leg (behind the torso).
  leg(backHip, backKnee, backAnkle, 17, 15);
  shoe(backAnkle, P.shoeBack);

  // Front leg.
  leg(frontHip, frontKnee, frontAnkle, 19, 16);
  shoe(frontAnkle, P.accent);

  /* -------------------------------------------------------------- arms */
  // Jacketed upper arm, bare forearm, gloved fist. Using one helper everywhere
  // is what keeps limb lengths identical across every pose.
  const arm = (shoulder, elbow, hand, options = {}) => {
    const sleeveColor = options.sleeve ?? P.jacket;
    const skinColor = options.skin ?? P.skin;
    const gloveColor = options.glove ?? P.accent;
    const sleeveWidth = options.sleeveWidth ?? 17;
    const forearmWidth = options.forearmWidth ?? 15;
    const fist = options.fist ?? 8.5;
    ctx.line(shoulder.x, shoulder.y, elbow.x, elbow.y, sleeveWidth, sleeveColor);
    ctx.line(elbow.x, elbow.y, hand.x, hand.y, forearmWidth, skinColor);
    ctx.fillCircle(elbow.x, elbow.y, forearmWidth / 2, skinColor);
    ctx.fillCircle(hand.x, hand.y, fist, gloveColor);
  };

  // Far arm sits behind the torso, so only the forearm and hand clear the
  // body. Shaded skin sells the depth without a floating mitt.
  const farShoulder = { x: cx - f * 16, y: shoulderY + 14 };
  const farElbow = { x: cx - f * 27, y: shoulderY + 35 };
  const farHand = { x: cx - f * 30, y: shoulderY + 50 };
  arm(farShoulder, farElbow, farHand, {
    skin: P.skinShade,
    glove: P.skinShade,
    sleeveWidth: 16,
    fist: 7.5,
  });

  /* ------------------------------------------------------------ torso */
  const torsoX = cx + TORSO_LEFT;
  const torsoW = TORSO_RIGHT - TORSO_LEFT;
  const torsoH = TORSO_HEIGHT - compression * 10;
  // Neck first, so the jacket collar covers its base.
  ctx.fillRect(cx - 9 + shoulderShift, shoulderY - 9, 18, 20, P.skinShade);
  ctx.fillRoundRect(torsoX, shoulderY, torsoW, torsoH, 13, P.jacket);
  // Jacket opening and shirt strip.
  ctx.fillRoundRect(torsoX + 2, shoulderY + 39, torsoW - 4, 10, 4, P.accent, 0.95);
  ctx.fillRect(torsoX + 6, shoulderY + 52, torsoW - 12, 6, P.jacket, 1);
  // Collar.
  ctx.fillRoundRect(torsoX + 6, shoulderY - 1, torsoW - 12, 7, 3, P.jacket, 1);

  // Near arm: pose driven.
  if (frame.pose === 'jab' || frame.pose === 'tump' || frame.pose === 'box') {
    const strike = strikePoint(frame.pose, frame.t ?? 0.1, cxBase, shoulderY, f);
    const shoulder = { x: cxBase + f * 18, y: shoulderY + 9 };
    const extension = strike.extension;

    if (frame.pose === 'box') {
      sweepTrail(
        ctx,
        shoulder.x,
        shoulder.y - 4,
        strike.x - shoulder.x - 6,
        -0.55,
        -0.08,
        P.accent,
        Math.max(0, extension),
      );
    }

    // Elbow stays bent in the guard and straightens only at full extension,
    // which is what makes the jab read as a punch rather than a stick.
    const bend = 1 - extension;
    const elbow = {
      x: (shoulder.x + strike.x) / 2 - f * (frame.pose === 'jab' ? 8 : 4) * bend,
      y:
        (shoulder.y + strike.y) / 2 +
        (frame.pose === 'jab' ? 17 : frame.pose === 'tump' ? 13 : 15) * bend,
    };
    arm(shoulder, elbow, strike, {
      forearmWidth: frame.pose === 'box' ? 16 : 15,
      fist: 10.5,
    });
  } else if (frame.pose === 'block') {
    arm(
      { x: cx + f * 18, y: shoulderY + 9 },
      { x: cx + f * 22, y: shoulderY + 22 },
      { x: cx + f * 33, y: shoulderY - 5 },
      { fist: 9.5 },
    );
  } else {
    // Idle/hit: loose guard, fist up near the chin.
    arm(
      { x: cx + f * 18, y: shoulderY + 9 },
      { x: cx + f * 26, y: shoulderY + 33 },
      { x: cx + f * 30, y: shoulderY + 16 },
      { fist: 8.5 },
    );
  }

  /* --------------------------------------------------------------- head */
  const headX = cx + f * HEAD_OFFSET + shoulderShift + headExtraX;
  const hy = headY + headTilt * 6;
  // Ear behind the skull, then the skull itself.
  ctx.fillCircle(headX - f * 19, hy + 1, 5.5, P.skinShade);
  ctx.fillCircle(headX, hy, HEAD_RADIUS, P.skin);
  // Cheek shading, kept inside the skull.
  ctx.fillEllipse(headX + f * 8, hy + 9, 10, 6.5, 0, P.skinShade, 0.3);
  // Nose.
  ctx.fillPolygon(
    [
      [headX + f * 15, hy + 1],
      [headX + f * 23, hy + 7],
      [headX + f * 15, hy + 10],
    ],
    P.skin,
  );
  // Eye inside the brim's shadow.
  ctx.fillRoundRect(headX - 21, hy - 9, 43, 13, 5, P.hatBrim, 0.18);
  ctx.fillCircle(headX + f * 13, hy + 1, 2.6, P.eye);
  // Mouth.
  ctx.line(headX + f * 8, hy + 14, headX + f * 16, hy + 13, 2, P.detail);
  // Kangol-style cap: long brim over the eyes, taller crown.
  ctx.fillRoundRect(headX - 24, hy - 19, 49, 11, 5, P.hatBrim);
  ctx.fillRoundRect(headX - 17, hy - 27, 41, 10, 5, P.hatCrown);
  ctx.fillRoundRect(headX - 19, hy - 23, 45, 3, 1.5, P.hatBrim, 0.85);

  // Artist tag, clear of the crown.
  ctx.fillPolygon(
    [
      [headX - 5, hy - 30],
      [headX + 5, hy - 30],
      [headX, hy - 38],
    ],
    P.accent,
  );
}

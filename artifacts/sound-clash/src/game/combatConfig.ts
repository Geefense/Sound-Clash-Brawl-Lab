/**
 * Single source of truth for combat tuning.
 *
 * Everything that a designer would want to tweak lives here: the attack
 * vocabulary, frame data, damage, hitstop weight, stun, knockback, recovery,
 * camera shake, spark counts, combo chains, movement, AI and match flow.
 *
 * Nothing in this file imports anything: it is safe for the simulation, the
 * renderer and the tests to import from it without creating cycles.
 */

export type AttackKind = 'light' | 'heavy' | 'head' | 'upper';
export type AttackStage = 'jab1' | 'jab2' | 'power' | 'head' | 'upper';
export type Winner = 'player' | 'rival' | 'draw';
export type ComboStep = 0 | 1 | 2;
export type ComboChainId = 'straight' | 'three-piece';
export type FighterId = 'player' | 'rival';

/**
 * Player-facing names for the four attacks the lab exposes today.
 * `light` = Jab, `heavy` = TUMP body shot (L), `head` = backhand BOX (K),
 * `upper` = Upper Box / reverse BOX (I) which doubles as the Three Piece
 * finisher when it closes jab -> TUMP -> Upper Box.
 */
export const ATTACK_LABELS: Record<AttackKind, string> = {
  light: 'Jab',
  heavy: 'TUMP',
  head: 'BOX',
  upper: 'Upper Box',
};

/** Per-stage frame data. These exact numbers feed both collision and drawing. */
export type StageProfile = {
  attack: AttackKind;
  /** Seconds until the strike pose becomes able to hit. */
  start: number;
  /** Seconds after which the strike can no longer hit. */
  end: number;
  /** Total committed duration of the stage. */
  duration: number;
  /** Distance from the fighter centre to the fist at full extension. */
  reach: number;
  /** Vertical offset of the fist from the shoulder line. */
  yOffset: number;
};

export const STAGE_PROFILES: Record<AttackStage, StageProfile> = {
  jab1: { attack: 'light', start: 0.08, end: 0.21, duration: 0.29, reach: 62 * 0.72 * 1.12, yOffset: 2 },
  jab2: { attack: 'light', start: 0.06, end: 0.18, duration: 0.25, reach: 49 * 1.12, yOffset: -4 },
  power: { attack: 'heavy', start: 0.16, end: 0.34, duration: 0.48, reach: 83, yOffset: 32 },
  head: { attack: 'head', start: 0.16, end: 0.34, duration: 0.48, reach: 83, yOffset: -24 },
  upper: { attack: 'upper', start: 0.12, end: 0.24, duration: 0.4, reach: 80, yOffset: -30 },
};

export type ShakeSpec = { duration: number; intensity: number; speed: number };

/**
 * Per-attack feel and recovery. `hitstopTicks` is the number of 60 Hz ticks
 * both fighters freeze for on impact (the single biggest weight cue), while
 * `cooldown` is the committed recovery after the stage finishes.
 */
export type AttackSpec = {
  label: string;
  damage: number;
  chipDamage: number;
  hitstopTicks: number;
  blockedHitstopTicks: number;
  hitstun: number;
  blockedHitstun: number;
  /** Physics reaction forced on the defender. */
  reactionTime: number;
  blockedReactionTime: number;
  /** Ticks the recoil pose is held for (renderer reads this through state). */
  hitReactionTicks: number;
  blockedReactionTicks: number;
  knockback: number;
  blockedKnockback: number;
  cooldown: number;
  shake: ShakeSpec;
  blockedShake: ShakeSpec;
  sparks: number;
  blockedSparks: number;
};

export const ATTACK_SPECS: Record<AttackKind, AttackSpec> = {
  light: {
    label: ATTACK_LABELS.light,
    damage: 8,
    chipDamage: 2,
    hitstopTicks: 3,
    blockedHitstopTicks: 2,
    hitstun: 0.28,
    blockedHitstun: 0.12,
    reactionTime: 0.29,
    blockedReactionTime: 0.16,
    hitReactionTicks: 11,
    blockedReactionTicks: 6,
    knockback: 60,
    blockedKnockback: 145,
    cooldown: 0.38,
    shake: { duration: 0.16, intensity: 110, speed: 0.004 },
    blockedShake: { duration: 0.07, intensity: 65, speed: 0.002 },
    sparks: 15,
    blockedSparks: 8,
  },
  heavy: {
    label: ATTACK_LABELS.heavy,
    damage: 15,
    chipDamage: 4,
    hitstopTicks: 5,
    blockedHitstopTicks: 2,
    hitstun: 0.28,
    blockedHitstun: 0.12,
    reactionTime: 0.29,
    blockedReactionTime: 0.16,
    hitReactionTicks: 17,
    blockedReactionTicks: 6,
    knockback: 420,
    blockedKnockback: 145,
    cooldown: 0.72,
    shake: { duration: 0.21, intensity: 160, speed: 0.006 },
    blockedShake: { duration: 0.07, intensity: 65, speed: 0.002 },
    sparks: 25,
    blockedSparks: 8,
  },
  head: {
    label: ATTACK_LABELS.head,
    damage: 15,
    chipDamage: 4,
    hitstopTicks: 6,
    blockedHitstopTicks: 2,
    hitstun: 0.28,
    blockedHitstun: 0.12,
    reactionTime: 0.29,
    blockedReactionTime: 0.16,
    hitReactionTicks: 17,
    blockedReactionTicks: 6,
    knockback: 420,
    blockedKnockback: 145,
    cooldown: 0.72,
    shake: { duration: 0.18, intensity: 130, speed: 0.005 },
    blockedShake: { duration: 0.07, intensity: 65, speed: 0.002 },
    sparks: 15,
    blockedSparks: 8,
  },
  upper: {
    label: ATTACK_LABELS.upper,
    damage: 15,
    chipDamage: 4,
    hitstopTicks: 7,
    blockedHitstopTicks: 2,
    hitstun: 0.34,
    blockedHitstun: 0.12,
    reactionTime: 0.35,
    blockedReactionTime: 0.16,
    hitReactionTicks: 17,
    blockedReactionTicks: 6,
    knockback: 180,
    blockedKnockback: 145,
    cooldown: 0.9,
    shake: { duration: 0.19, intensity: 140, speed: 0.005 },
    blockedShake: { duration: 0.07, intensity: 65, speed: 0.002 },
    sparks: 18,
    blockedSparks: 8,
  },
};

/** Being hit during the startup of your own attack is a counterhit. */
export const COUNTER_HIT = {
  bonusDamage: 3,
  extraHitstun: 0.06,
  extraReactionTime: 0.04,
  extraHitstopTicks: 2,
} as const;

export const BLOCK_RULES = {
  /** Blocking requires both feet on the floor. */
  requiresGround: true,
  /** Blocking requires facing the attacker. */
  requiresFacing: true,
  /** A committed attack cannot be cancelled into a block. */
  allowedWhileAttacking: false,
  /** Walk speed multiplier while guarding. */
  walkMultiplier: 0.38,
} as const;

/** Input / combo windows, expressed in seconds. */
export const COMBO_WINDOW_SECONDS = 0.72;
export const COMBO_BUFFER_OPEN_AT = 0.14;
/**
 * How long a single attack press is remembered while the fighter cannot act
 * (hitstun, blockstun, recovery). Long enough to cover the longest stun plus
 * recovery tail, short enough that a mashed early input is not a free hit.
 */
export const INPUT_BUFFER_SECONDS = 0.35;

/**
 * Combo chains. A chain is a sequence of attack inputs; each rule names the
 * step that is open, the chain it belongs to and the stage each kind maps to.
 * Step is the number of links already committed.
 */
export type ComboRule = {
  chain: ComboChainId;
  step: ComboStep;
  kindStages: Partial<Record<AttackKind, AttackStage>>;
};

export const COMBO_RULES: readonly ComboRule[] = [
  { chain: 'straight', step: 1, kindStages: { light: 'jab2' } },
  { chain: 'three-piece', step: 1, kindStages: { heavy: 'power' } },
  { chain: 'straight', step: 2, kindStages: { heavy: 'power', head: 'head' } },
  { chain: 'three-piece', step: 2, kindStages: { upper: 'upper' } },
];

/** Labels shown above the fighter once a chain reaches two or more hits. */
export const COMBO_FEEDBACK = {
  combo: (hits: number) => `${hits}-HIT COMBO`,
  finisher: (hits: number) => `${hits}-HIT FINISH`,
  threePiece: 'THREE PIECE!',
  threePieceKO: 'HIM DUN!',
  duration: 0.68,
  threePieceDuration: 1.2,
} as const;

/** Knockdown / KO cinematic timeline, in 60 Hz ticks. */
export const KO_SEQUENCE = {
  impactFreezeTicks: 9,
  knockdownTicks: 36,
  announcementTicks: 72,
  /** Extra ticks a knocked-down (but living) fighter stays on the floor. */
  knockdownRecoveryTicks: 12,
  /** How long the loser's body slides horizontally. */
  knockdownSlide: 64,
  knockdownSlideLight: 38,
  knockdownLaunch: 88,
  knockdownLaunchLight: 58,
} as const;

export const MOVEMENT = {
  walkSpeed: 270,
  blockWalkMultiplier: BLOCK_RULES.walkMultiplier,
  jumpVelocity: -665,
  gravity: 1580,
  /** Automatic short hop when walking into the opponent. */
  walkAroundJump: -570,
  walkAroundCooldown: 0.9,
  /** Airborne gap above which fighters pass through each other. */
  airPassClearance: 52,
  minFighterGap: 76,
} as const;

export const AI_TUNING = {
  walkSpeed: 145,
  engageRange: 108,
  blockChance: 0.22,
  heavyChance: 0.28,
  waitMin: 0.55,
  waitJitter: 0.45,
  initialWait: 0.5,
  jumpChance: 0.008,
  jumpRange: 310,
  jumpVelocity: -590,
} as const;

export const MATCH_RULES = {
  roundSeconds: 90,
  roundsToWin: 2,
  initialPreRoundSeconds: 2,
  preRoundSeconds: 1.5,
  roundTransitionSeconds: 3,
  playerStartX: 378,
  rivalStartX: 902,
} as const;

/** Small helper so callers never reach for a literal limit. */
export function isAttackKind(value: string): value is AttackKind {
  return value === 'light' || value === 'heavy' || value === 'head' || value === 'upper';
}

import type { AttackKind, AttackStage, ComboChainId, ComboStep, Winner } from '../combatConfig.ts';
import type { MatchStatus } from '../types.ts';

/**
 * A single hit reaction, owned by the simulation so it advances with the tick
 * and is part of the deterministic state (previously it lived in the scene and
 * drifted from the simulation).
 */
export type HitReaction = {
  kind: AttackKind;
  region: 'head' | 'body';
  direction: number;
  age: number;
  counter?: true;
};

export type FighterInput = {
  left: boolean;
  right: boolean;
  jump: boolean;
  block: boolean;
  /** Jab (J). */
  light: boolean;
  /** TUMP body shot (L). */
  heavy: boolean;
  /** Backhand BOX to the head (K). */
  head?: boolean;
  /** Upper Box (I). */
  upper?: boolean;
};

export type KnockdownState = {
  ticks: number;
  x: number;
  y: number;
  direction: number;
  /** Whether the launch used the heavy trajectory (also drives the renderer). */
  heavy: boolean;
};

export type FighterState = {
  x: number;
  y: number;
  health: number;
  facing: number;
  color: number;
  accent: number;
  skin: number;
  name: string;
  vx: number;
  vy: number;
  grounded: boolean;
  blocking: boolean;
  action: 'idle' | AttackKind | 'hit' | 'block' | 'down';
  actionTime: number;
  cooldown: number;
  stun: number;
  /** Kept for AI pacing; ignored for a human-controlled fighter. */
  aiWait: number;
  anim: number;
  attackElapsed: number;
  hitRegistered: boolean;
  attackFacing: number;
  attackStage: AttackStage;
  /** Which chain the committed attack belongs to, if any. */
  comboChain: ComboChainId | null;
  comboStep: ComboStep;
  comboWindow: number;
  /** Attack press remembered while the fighter cannot act. */
  bufferedAttack: AttackKind | null;
  bufferedAttackTimer: number;
  comboHits: number;
  comboFeedback: string;
  comboFeedbackTime: number;
  walkAroundCooldown: number;
  knockdown: KnockdownState | null;
  hitReaction: HitReaction | null;
};

export type GameEvent =
  | { type: 'three-piece'; fighter: 'player' | 'rival'; ko: boolean }
  | { type: 'sound'; kind: 'hit' | 'block' | 'jump' | 'round' | 'ko' }
  | { type: 'spark'; x: number; y: number; color: number; count: number }
  | { type: 'shake'; duration: number; intensity: number; speed: number }
  | {
      type: 'hit-reaction';
      fighter: 'player' | 'rival';
      kind: AttackKind;
      region: 'head' | 'body';
      direction: number;
      counter?: true;
    }
  | { type: 'attack-stage'; fighter: 'player' | 'rival'; kind: AttackKind; stage: AttackStage };

export type GameState = {
  player: FighterState;
  rival: FighterState;
  timeLeft: number;
  elapsed: number;
  status: MatchStatus;
  winner: Winner | null;
  matchWinner: Winner | null;
  roundWinner: Winner | null;
  round: number;
  playerWins: number;
  rivalWins: number;
  transitionTimer: number;
  threePieceKO: boolean;
  roundEndReason: 'ko' | 'timeout' | null;
  ko: {
    ticks: number;
    player: { x: number; y: number; direction: number; heavy: boolean };
    rival: { x: number; y: number; direction: number; heavy: boolean };
  } | null;
  /** Deterministic random seed state. */
  rngState: number;
  /** Ticks both fighters freeze for after a clean impact. */
  hitstop: number;
  /** Who drives the rival: the built-in CPU or an external input client. */
  rivalControl: 'ai' | 'human';
  /** Events dispatched during a tick, for rendering/sound (not for gameplay). */
  events: GameEvent[];
};

export const TICK_RATE = 60;
export const FIXED_TIMESTEP = 1 / TICK_RATE;

import type { AttackStage, ComboStep, AttackKind, Winner } from '../combatRules';
import type { MatchStatus } from '../types';

export type FighterInput = {
  left: boolean;
  right: boolean;
  jump: boolean;
  block: boolean;
  light: boolean;
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
  action: 'idle' | 'light' | 'heavy' | 'hit' | 'block';
  actionTime: number;
  cooldown: number;
  stun: number;
  aiWait: number; // Keep for now, maybe move out later if AI runs as an external client
  anim: number;
  attackElapsed: number;
  hitRegistered: boolean;
  attackFacing: number;
  attackStage: AttackStage;
  comboStep: ComboStep;
  comboWindow: number;
  bufferedAttack: AttackKind | null;
  comboHits: number;
  comboFeedback: string;
  comboFeedbackTime: number;
  walkAroundCooldown: number;
};

export type GameState = {
  player: FighterState;
  rival: FighterState;
  timeLeft: number;
  elapsed: number;
  status: MatchStatus;
  winner: Winner | null;
  // Events dispatched during a tick, for rendering/sound (not for gameplay logic)
  events: GameEvent[];
};

export type GameEvent =
  | { type: 'sound'; kind: 'hit' | 'block' | 'jump' | 'round' }
  | { type: 'spark'; x: number; y: number; color: number; count: number }
  | { type: 'shake'; duration: number; intensity: number; speed: number }
  | { type: 'attack-stage'; fighter: 'player' | 'rival'; kind: AttackKind; stage: AttackStage };

export const TICK_RATE = 60;
export const FIXED_TIMESTEP = 1 / TICK_RATE;

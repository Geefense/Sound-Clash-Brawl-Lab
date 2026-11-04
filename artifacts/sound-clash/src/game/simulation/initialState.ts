import { MATCH_RULES, AI_TUNING } from '../combatConfig.ts';
import type { FighterState, GameState } from './types.ts';

export type FighterIdentity = { color: number; accent: number; skin: number; name: string };

export const FIGHTER_IDENTITY: Record<'player' | 'rival', FighterIdentity> = {
  player: { color: 0x247c72, accent: 0xf0c64c, skin: 0x9d6545, name: 'SIDEWINDER' },
  rival: { color: 0xd75f3e, accent: 0xedd9b5, skin: 0x754936, name: 'BASSLINE' },
};

/**
 * The single definition of a fighter's initial state. Round resets are derived
 * from this factory instead of a hand-written 40-field list, so adding a field
 * can never desync the reset path.
 */
export function createFighterState(overrides: Partial<FighterState> = {}): FighterState {
  return {
    x: 0,
    y: 0,
    health: 100,
    facing: 1,
    color: 0,
    accent: 0,
    skin: 0,
    name: '',
    vx: 0,
    vy: 0,
    grounded: true,
    blocking: false,
    action: 'idle',
    actionTime: 0,
    cooldown: 0,
    stun: 0,
    aiWait: 0,
    anim: 0,
    attackElapsed: 0,
    hitRegistered: false,
    attackFacing: 1,
    attackStage: 'jab1',
    comboChain: null,
    comboStep: 0,
    comboWindow: 0,
    bufferedAttack: null,
    bufferedAttackTimer: 0,
    comboHits: 0,
    comboFeedback: '',
    comboFeedbackTime: 0,
    walkAroundCooldown: 0,
    knockdown: null,
    hitReaction: null,
    ...overrides,
  };
}

/** Reset a fighter in place, keeping its identity unless overridden. */
export function resetFighterForRound(
  fighter: FighterState,
  overrides: Partial<FighterState> = {},
): FighterState {
  const identity: FighterIdentity = {
    color: fighter.color,
    accent: fighter.accent,
    skin: fighter.skin,
    name: fighter.name,
  };
  return Object.assign(fighter, createFighterState({ ...identity, ...overrides }));
}

export function createMatchState(seed: number): GameState {
  return {
    player: createFighterState({
      ...FIGHTER_IDENTITY.player,
      x: MATCH_RULES.playerStartX,
      facing: 1,
    }),
    rival: createFighterState({
      ...FIGHTER_IDENTITY.rival,
      x: MATCH_RULES.rivalStartX,
      facing: -1,
      aiWait: AI_TUNING.initialWait,
    }),
    timeLeft: MATCH_RULES.roundSeconds,
    elapsed: 0,
    status: 'pre-round',
    winner: null,
    matchWinner: null,
    roundWinner: null,
    roundEndReason: null,
    threePieceKO: false,
    ko: null,
    round: 1,
    playerWins: 0,
    rivalWins: 0,
    transitionTimer: MATCH_RULES.initialPreRoundSeconds,
    hitstop: 0,
    rivalControl: 'ai',
    rngState: seed >>> 0,
    events: [],
  };
}

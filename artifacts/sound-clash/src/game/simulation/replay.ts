import { simulateTick } from './SimulationEngine.ts';
import type { FighterInput, GameState } from './types.ts';

export type InputFrame = { player: FighterInput; rival: FighterInput };

export function emptyInput(): FighterInput {
  return { left: false, right: false, jump: false, block: false, light: false, heavy: false };
}

export type ReplayLog = {
  seed: number;
  frames: InputFrame[];
};

/**
 * Canonical JSON: object keys are sorted recursively and transient render
 * events are excluded, so a state hash depends only on simulated values.
 */
export function canonicalize(value: unknown): string {
  if (value === null || typeof value !== 'object') return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(canonicalize).join(',')}]`;
  const record = value as Record<string, unknown>;
  const keys = Object.keys(record).filter(key => key !== 'events').sort();
  return `{${keys.map(key => `${JSON.stringify(key)}:${canonicalize(record[key])}`).join(',')}}`;
}

/** 32-bit FNV-1a hash, hex encoded. Stable across Node and browsers. */
export function hashState(state: GameState): string {
  const text = canonicalize(state);
  let hash = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  return hash.toString(16).padStart(8, '0');
}

/**
 * Replay recorded per-tick inputs from an initial state. Because the
 * simulation is a pure function of (state, inputs), the exact same frames must
 * produce the exact same hashes.
 */
export function runReplay(
  initial: GameState,
  frames: readonly InputFrame[],
): { state: GameState; hashes: string[] } {
  let state = initial;
  const hashes: string[] = [];
  for (const frame of frames) {
    state = simulateTick(state, frame.player, frame.rival);
    hashes.push(hashState(state));
  }
  return { state, hashes };
}

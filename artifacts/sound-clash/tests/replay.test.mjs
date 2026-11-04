import assert from 'node:assert/strict';
import test from 'node:test';
import { simulateTick } from '../src/game/simulation/SimulationEngine.ts';
import { createMatchState } from '../src/game/simulation/initialState.ts';
import { canonicalize, emptyInput, hashState, runReplay } from '../src/game/simulation/replay.ts';

const seed = 987654321;

const liveState = (matchSeed = seed) => {
  const state = createMatchState(matchSeed);
  state.status = 'playing';
  state.transitionTimer = 0;
  return state;
};

/** Deterministic pseudo-scripted input frames (no Math.random). */
function buildFrames(count) {
  const frames = [];
  let noise = 0x12345678;
  for (let tick = 0; tick < count; tick++) {
    noise = (Math.imul(noise, 1664525) + 1013904223) >>> 0;
    const roll = noise / 4294967296;
    const player = emptyInput();
    if (tick % 17 === 0) player.light = true;
    if (tick % 37 === 0) player.heavy = true;
    if (tick % 53 === 0) player.upper = true;
    if (roll < 0.2) player.right = true;
    if (roll > 0.85) player.left = true;
    if (roll > 0.7 && roll < 0.74) player.block = true;
    frames.push({ player, rival: emptyInput() });
  }
  return frames;
}

test('identical recorded inputs replay to identical state hashes', () => {
  const frames = buildFrames(240);
  const first = runReplay(liveState(), frames);
  const second = runReplay(liveState(), frames);

  assert.equal(first.hashes.length, frames.length);
  assert.deepEqual(first.hashes, second.hashes);
  assert.deepEqual(first.state, second.state);
  assert.equal(hashState(first.state), hashState(second.state));
});

test('replaying from the same seed reproduces the final state exactly', () => {
  const frames = buildFrames(180);
  const recorded = runReplay(liveState(), frames);
  let replayed = liveState();
  for (const frame of frames) replayed = simulateTick(replayed, frame.player, frame.rival);

  assert.equal(hashState(replayed), hashState(recorded.state));
  assert.deepEqual(replayed, recorded.state);
});

test('a single changed input frame changes the replay hash', () => {
  const frames = Array.from({ length: 60 }, () => ({ player: emptyInput(), rival: emptyInput() }));
  const original = runReplay(liveState(), frames);

  const tampered = frames.map(frame => ({
    player: { ...frame.player },
    rival: { ...frame.rival },
  }));
  tampered[30].player.right = true;

  const replayed = runReplay(liveState(), tampered);
  assert.notEqual(replayed.hashes[30], original.hashes[30], 'the tampered tick diverges');
  assert.equal(replayed.hashes[29], original.hashes[29], 'earlier ticks stay identical');
  assert.notEqual(hashState(replayed.state), hashState(original.state));
});

test('state hashes ignore transient render events but include fighter state', () => {
  const state = liveState();
  const withEvents = {
    ...state,
    events: [{ type: 'sound', kind: 'hit' }, { type: 'shake', duration: 0.1, intensity: 100, speed: 0.005 }],
  };
  assert.equal(hashState(state), hashState(withEvents));

  const nudged = { ...state, player: { ...state.player, health: 99 } };
  assert.notEqual(hashState(state), hashState(nudged));

  const moved = { ...state, player: { ...state.player, x: state.player.x + 0.5 } };
  assert.notEqual(hashState(state), hashState(moved));
});

test('different seeds produce different AI-driven timelines', () => {
  const frames = buildFrames(180);
  const a = runReplay(liveState(1), frames);
  const b = runReplay(liveState(999999), frames);
  assert.notEqual(hashState(a.state), hashState(b.state));
});

test('canonicalize is key-order independent', () => {
  const a = { b: 1, a: { d: 2, c: [1, 2] } };
  const b = { a: { c: [1, 2], d: 2 }, b: 1 };
  assert.equal(canonicalize(a), canonicalize(b));
});

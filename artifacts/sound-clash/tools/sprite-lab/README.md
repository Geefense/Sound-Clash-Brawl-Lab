# Sprite lab

Dependency-free tooling that turns a fighter rig into transparent, game-ready
sprite atlases with consistent proportions and one shared sole line.

## Run

```bash
cd artifacts/sound-clash
node tools/sprite-lab/generate.mjs     # writes public/sprites/*.png + *.json
node tools/sprite-lab/serve.mjs        # http://localhost:3001/sprites/preview.html
```

The project's Vite dev server serves `public/` too, so
`http://localhost:5173/sprites/preview.html` works without the tiny server.

## What it produces

| File | Contents |
| --- | --- |
| `public/sprites/rig-sample.png` | 4×4 transparent atlas, 16 frames, 440×400 per cell at `scale: 2` |
| `public/sprites/rig-sample-alt.png` | Same frames, alternate palette for two-player testing |
| `public/sprites/rig-sample*.json` | Frame rects, clip timings, anchor, palette, sole row |
| `public/sprites/preview.html` | Playback preview with ground/anchor guides |

## Why the numbers can't drift

`rig.mjs` imports its skeleton from the game rather than copying it:

- `fighterGeometry.ts` — hip, shoulder and head heights, torso box, head radius
- `combatConfig.ts` — reach and fist height per attack
- `visualReactions.ts` — hit recoil offsets

Node 26 strips TypeScript types, so the rig reads the same constants the
collision code does. If the hurtbox changes, the next `generate.mjs` run
follows it.

## Verified invariants

`generate.mjs` measures the lowest opaque row in every frame and fails with a
non-zero exit code if they differ. That is the "consistent foot alignment"
requirement expressed as a check instead of a promise.

## Scope

This is a pipeline sample. It is **not** Feedback: no Feedback reference art
exists in this repository. See `../../art-source/feedback/README.md` for the
exact reference files that must be uploaded before Feedback can be drawn.

Nothing here is wired into `GameScene.ts` — the combat engine, controls, tests
and existing procedural rendering are untouched.

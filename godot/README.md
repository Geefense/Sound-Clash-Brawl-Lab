# `/godot` — Sound Clash Brawl Godot project

Setup folder for the engine port described in the repository-root `AGENTS.md` (§5). The pin to one
Godot 4.x release, the renderer, and Chromebook run/export steps are still **[TODO]** in the
blueprint, so this folder holds the project file, the folder layout, and a verified copy of the
art that exists today. Nothing here is committed as approved gameplay content.

## Layout

```
godot/
  AGENTS.md          exact copy of the repository-root AGENTS.md (that file stays authoritative)
  project.godot      minimal project file; config/features is added on first open
  scenes/            empty, ready for BaseFighter/match/hazard scenes
  scripts/           empty, ready for combat/fsm/rhythm/crowd scripts
  assets/
    sprites/feedback/aligned/           the 17-pose RGBA pack + manifest + README
    sprites/feedback/imported-poses/    six imported pose studies
    sprites/feedback/walk-four-keys/    four walk keys (unapproved movement test)
    flow_exports/walk/                  walk video exports
    audio/                              inventory placeholder — no audio files exist yet
```

## What was copied, and from where

| Destination | Source | Contents |
| --- | --- | --- |
| `assets/sprites/feedback/aligned/` | `artifacts/sound-clash/public/assets/feedback/` | 17 pose PNGs (1536×1024), `feedback.poses.json` |
| `assets/sprites/feedback/imported-poses/` | `artifacts/sound-clash/art-source/feedback/imported-poses/` | 6 study PNGs |
| `assets/sprites/feedback/walk-four-keys/poses/` | `artifacts/sound-clash/art-source/feedback/walk-four-keys/poses/` | 4 walk keys — **unapproved movement test** |
| `assets/flow_exports/walk/` | `art-source/feedback/` and `chat-movement-transfer-2026-11-13/movement-reference/` | walk flow test, approved 132 BPM reference |

Copies were verified by file count and per-file SHA-256 against the sources. Original filenames,
frames and anchors are preserved; no PNG or audio file is ignored by `godot/.gitignore`.

Deliberately **not** copied: candidate and comparison-only art (`cable-candidates/`,
`walk-four-keys/candidates/`, `box-handoff-2026-11-13/` concept images and review videos, review
overlays), which stays distinguishable in `art-source/` and must not read as approved assets.

## Still missing ([TODO] in the blueprint)

- **Audio**: no sound, music, voice or SFX files exist anywhere in the repository yet.
- **Spriteriffic sprite sheets**: no exported sheets or grid layouts exist yet.
- **Interference props**: no bottle, folding-chair or fire-extinguisher art exists yet, so
  `assets/sprites/` has no `bottles/`, `chairs/` or `fire_extinguishers/` folder to fill.
- **Godot version, renderer and export path**: unpinned; not verified on any target device.

No scene, script, engine setting or gameplay rule has been created or changed here.

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

## Fighter wiring — UNAPPROVED, no Godot checks run

Claude's audited files are saved as given: `scripts/BaseFighter.gd`, `scripts/rhythm/BeatService.gd`
and `scenes/BaseFighter.tscn`. Physics runs at 60 Hz (`project.godot`). Nothing here has been opened,
run or tested in Godot; the engine is not installed in this environment, so **checks run: none in
Godot**.

`BaseFighter.tscn`'s `AnimatedSprite2D` carries all 17 aligned poses and the 4 walk keys as 18
animations, using the manifest's own state names where they exist. No original art file was edited.

| Animation | Frame(s) | Origin (manifest anchor) |
| --- | --- | --- |
| `idle` | `01_idle` | feet, y 900 |
| `walk` | 4 walk keys (`01_contact_a` … `04_pass_b`) | pinned sole, y 566 in the 460×620 keys |
| `crouch` / `block` | `07_crouch` / `08_block` | feet, y 900 |
| `jab` | `09_point` (poke — placeholder for a jab) | feet, y 900 |
| `box_startup` / `box_active` / `box_recovery` | `12` / `13` / `14` | feet, y 900 |
| `hitstun` | `16_gut_punch` | pelvis, y 610 |
| `knockdown` | `17_seated_landing` | ground contact, y 900 |
| `ko` | `02_knockout` | feet, y 900 |
| `launched` / `tumble` | `03_c_recoil` / `04_inverted_c` | pelvis, y 610 |
| `dizzy` / `salute` / `skank` | `05`, `06`, `15` | 900 / 610 / 610 |
| `fire_air` / `fire_ground` | `10` / `11` | 610 / 900 |

Because the pack has two anchors and the walk keys have their own canvas, `BaseFighter.gd` sets
`sprite.offset` per animation from the manifest (`ANIM_OFFSET`); the offset is a texture-space value
before the node's 0.25 display scale. The last six animations are not driven by any FSM state yet —
they are mapped so the data is present, not because a state plays them.

Open **[TODO]** items, unchanged from the handoff and the blueprint: `beat_offset_sec`, the judgement
window (placeholder 70 ms — no approved window exists), latency calibration, the on-beat reward
policy, the walk playback rate (4.4 fps assumes two keys per beat at 132 BPM), the walk display scale
matched by eye against the pose frames, attack/movement numbers marked `[TODO] port from TS`, and
the canonical mic hand. `jump` has no pose, so the animation is skipped rather than faked.

## Still missing ([TODO] in the blueprint)

- **Audio**: no sound, music, voice or SFX files exist anywhere in the repository yet.
- **Spriteriffic sprite sheets**: no exported sheets or grid layouts exist yet.
- **Interference props**: no bottle, folding-chair or fire-extinguisher art exists yet, so
  `assets/sprites/` has no `bottles/`, `chairs/` or `fire_extinguishers/` folder to fill.
- **Godot version, renderer and export path**: unpinned; not verified on any target device.

No scene, script, engine setting or gameplay rule has been created or changed here.

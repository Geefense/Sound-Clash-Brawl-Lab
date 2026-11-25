# CONSOLE_READINESS

Console scaling and platform-readiness record for **Sound Clash Brawl**.
Created 2026-11-25. Owner and final approver: Garfield Connell.

Companion documents:

- `AGENTS.md` — the authoritative project blueprint, decisions and verified work log.
- `INDUSTRY_REFERENCE_ANALYSIS.md` — the citable industry reference analysis behind the
  visual techniques, with the source list and the "OWNER TO FILL" footage prompts.

**Status in one line:** the game is a **Web / Compatibility** build. Nothing here is a
console port, a certification submission or a promise of one. This file records what the
current build costs, what a console tier would change, and what is still unknown.

## 1. What ships today (verified)

| Item | Value | How it was verified |
| --- | --- | --- |
| Renderer | Godot 4.5 `gl_compatibility` (WebGL 2) | `project.godot`; the Web export runs headless |
| Target | 1280 × 720, 60 FPS, Chromebook + iPhone Safari | Owner's stated targets; frame rate on real hardware **not measured by an agent** |
| Lights per object | **7** (sun + fill + omni rim + 4 stage spots) | `Arena3D.light_count()` asserted ≤ `max_lights_per_object()` (8) in `headless_roster_check` |
| Directional lights | 2 (sun + fill) | asserted ≤ 4 |
| Screen-space effects | **off**: no SSAO, SSIL, SDFGI or volumetric fog | asserted in `headless_roster_check` |
| Tonemap / glow | ACES + additive glow (low intensity) | asserted in `headless_roster_check` |
| Fighter meshes | 29 025 / 270 074 / 246 654 tris | `FighterModel3D.MODEL_SOURCES` + headless inventory |
| Crowd | 22 rigs, ≤ 3 500 tris each; atmosphere < 90 000 tris | asserted in `headless_roster_check` |
| Pose grid | 18 FPS attacks, 12 FPS idle/walk | `AnimationFeel.STEPPED_FPS`, `step_fps_idle` |
| Web export | `docs/` ≈ 103 MB (`index.pck` ≈ 68.7 MB, `index.wasm` ≈ 38.1 MB) | `--export-release "Web"` run, 2026-11-25 |
| Per-frame allocation | 0 new nodes / 0 new resources over 600 frames | `animation_feel_audit` allocation run |

The **8-lights-per-object** figure is the Compatibility renderer's default and the reason the
Night rig is four stage spots plus a moon key, not a dozen beams. Every new light has to be
paid for by removing one.

## 2. What a console tier would unlock

Ordered by visual gain per unit of risk. None of these is implemented; all of them are
renderer features the Web target cannot do.

| Tier | Feature | Why it is not in the Web build | Reference |
| --- | --- | --- | --- |
| 2 | Real-time shadow cascades / a second shadowed light | Compatibility has one directional shadow and no cascades | Tekken 8's lighting is the reached source's own hard problem (`INDUSTRY_REFERENCE_ANALYSIS.md` §3, S7) |
| 2 | Screen-space ambient occlusion / contact shadows | Not available in Compatibility | same |
| 2 | Depth-of-field on Special/KO accents | Post-process pass; the Web build uses a clamped FOV/angle accent instead | SF6 Super Art lighting (§4, S4) |
| 2 | More than 8 lights per object | Renderer limit | — |
| 3 | 24–30 FPS pose grid + longer per-bone lag chains | Per-frame budget only | Xrd limited animation (§1/§2, S1) |
| 3 | Full-screen per-character impact overlays | Fill-rate and memory | Fatal Fury CotW comic overlays (§5, S9/S10) |
| 3 | Cloth/hair secondary motion, a real projection foreshortening cheat | Solver + GPU budget | Makoto foreshortening (§7) |

**Rule:** a console feature must be a **tier flag over the same data**, never a fork of the
animation or combat code. `BaseFighter`, the frame data, the 132 BPM clock and the 31 Patois
entries are shared across every tier.

## 3. What must be true before a console build is attempted

- [ ] **Platform chosen and SDK access confirmed** (owner decision). No console SDK, devkit
      or certification contact exists in this repository.
- [ ] **Engine version pinned for the console branch.** The Web build is Godot 4.5 stable;
      a console export may require a vendor-supported fork. [TODO] confirm.
- [ ] **Controller input map** — the current `InputMap` is keyboard/touch. Gamepad
      deadzones, remapping and the on-screen prompts are not authored.
- [ ] **Save data / profiles** — none implemented. Round state is in-memory only.
- [ ] **Frame budget measured on target hardware.** No agent in this project has a GPU; all
      performance claims here are structural (node counts, allocations, light counts), not
      measured frame times.
- [ ] **Certification requirements** (suspend/resume, user sign-out, storage-full, parental
      controls, accessibility) reviewed against the chosen platform.
- [ ] **Export pipeline** — the Web export command is documented and reproducible; a console
      export pipeline is not.
- [ ] **Audio** — the Sound Clash audio engine runs, but platform mixing/ducking rules and
      any licensed music are unresolved. No audio file exists in the repository.

## 4. Known risks that a console tier would expose

1. **The 270 k-tri fighter meshes.** L!ckshot and L!kkle Moore are far heavier than
   Feedback. Fine on a desktop GPU, a real question on a low-end Chromebook and on any
   tier that wants two fighters plus 22 crowd rigs plus a full stage in one frame.
2. **Two fighters × two skeletons × per-frame bone writes.** The feel layer writes bones
   every frame (no allocation, but real CPU). A tier-3 secondary-motion layer multiplies
   that.
3. **The 8-light ceiling is load-bearing.** The Night preset's look depends on four coloured
   spots; raising the ceiling changes the art direction, not just the cost.
4. **Web memory.** `docs/` is ~103 MB and GitHub already warns about the 65 MB `.pck`. A
   console build would ship differently, but the asset weight is the same.

## 5. Open questions for the owner

- [ ] Which platform(s) are actually being considered, and in what order?
- [ ] Is 60 FPS locked, or is a 30 FPS quality mode acceptable for a tier-2 build?
- [ ] Does the console tier need to match the Web build's content exactly, or can it add
      modes/venues the Web build cannot afford?
- [ ] Is a physical release (disc/cartridge) in scope, or download-only?

## 6. Cross-references

- Visual techniques and their sources: `INDUSTRY_REFERENCE_ANALYSIS.md` §1–§8.
- The implemented visual layer, its counts and its decisions: `AGENTS.md`
  ("2026-11-25 — PART 1" section) and the headless suites
  (`headless_roster_check`, `live_match_check`, `facing_audit`, `animation_feel_audit`).
- The permanent creative direction: `artifacts/sound-clash/SOUND_CLASH_CULTURE.md`.

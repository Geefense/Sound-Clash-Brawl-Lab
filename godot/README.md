# `/godot` — Sound Clash Brawl Godot project

Setup folder for the engine port described in the repository-root `AGENTS.md` (§5). The pin to one
Godot 4.x release, the renderer, and Chromebook run/export steps are still **[TODO]** in the
blueprint, so this folder holds the project file, the folder layout, and a verified copy of the
art that exists today. The 20 selected frames adopted on 2026-11-15 are owner-approved working art;
everything else here (arena, fighters, wiring) is still unapproved and unverified.

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
    sprites/feedback/selected-frames-2026-11-15/  20 selected 512×512 frames (owner-approved working art)
    sprites/feedback/box-footoff-ground-2026-11-15/  foot-off-ground BOX contact frame (1024×1536, owner-approved)
    flow_exports/walk/                  walk video exports
    audio/                              inventory placeholder — no audio files exist yet
```

## What was copied, and from where

| Destination | Source | Contents |
| --- | --- | --- |
| `assets/sprites/feedback/aligned/` | `artifacts/sound-clash/public/assets/feedback/` | 17 pose PNGs (1536×1024), `feedback.poses.json` |
| `assets/sprites/feedback/imported-poses/` | `artifacts/sound-clash/art-source/feedback/imported-poses/` | 6 study PNGs |
| `assets/sprites/feedback/walk-four-keys/poses/` | `artifacts/sound-clash/art-source/feedback/walk-four-keys/poses/` | 4 walk keys — **unapproved movement test** |
| `assets/sprites/feedback/selected-frames-2026-11-15/` | `artifacts/sound-clash/art-source/feedback/selected-frames-2026-11-15/` | 20 selected 512×512 frames + `inventory.json` — owner-approved working art, originals untouched |
| `assets/sprites/feedback/box-footoff-ground-2026-11-15/` | repository root `Feedback_Baseball_Pitch_BOX_Foot_Off_Ground.png` | foot-off-ground BOX contact frame — owner-approved, byte-identical copy |
| `assets/flow_exports/walk/` | `art-source/feedback/` and `chat-movement-transfer-2026-11-13/movement-reference/` | walk flow test, approved 132 BPM reference |

Copies were verified by file count and per-file SHA-256 against the sources. Original filenames,
frames and anchors are preserved; no PNG or audio file is ignored by `godot/.gitignore`.

Deliberately **not** copied: candidate and comparison-only art (`cable-candidates/`,
`walk-four-keys/candidates/`, `box-handoff-2026-11-13/` concept images and review videos, review
overlays), which stays distinguishable in `art-source/` and must not read as approved assets.

## Sound Clash Sand Stage — UNAPPROVED, headless checks only

`assets/stages/sound_clash_sand_stage_1280x720.png` is the owner's beach sound-yard background
(original 1672 × 941 kept untouched in `art-source/stages/sound-clash-sand/`), wired as the
`Stage` sprite in `TestArena.tscn` at **z_index −10**. The sand yard begins at world y ≈ 505 in this
export, so the fighting floor line stays at **y = 600**: both fighters stand ~95 px into the sand
with sand in front and behind them. Nothing was cropped, repainted or offset.

| Layer | Node | z_index |
| --- | --- | --- |
| Stage art (1280 × 720) | `Stage` | −10 |
| Warm-sun / cool-shade gradient + sun bloom | `Atmosphere`, `SunGlow` | −9 |
| 132 BPM speaker rings | `SpeakerRings` (`SpeakerPulse.gd`) | −8 |
| Sand splats (dodged bird drops) | runtime `StageSplat` children | −6 |
| Coastal wind motes (CPUParticles2D) | `WindMotes` | −5 |
| Dancehall crowd, back row | `CrowdLine` children | −6 |
| Dancehall crowd, front row | `CrowdLine` children | −5 |
| Low yard barrier (`YardBarrier.gd`) | `YardBarrier` | −4 |
| Fighter contact shadows | `Shadow` in `BaseFighter.tscn` | −2 |
| Sand foot dust (CPUParticles2D) | `Dust` in `BaseFighter.tscn` | −1 |
| Fighters | `P1`, `P2` | 0 |
| Near-camera spectator (`ForegroundSpectator.gd`) | `Foreground/Spectator` (CanvasLayer 1) | 10 |
| Splatter on a hit fighter | runtime `StageSplat` child | 6 |
| Bird fly-by | `BirdHazard` | 20 |

Because the background is a single 1280 × 720 layer, the camera now clamps its zoom to **1.0–1.6**
and its position to the stage rectangle (`TestArena.STAGE_SIZE`). Zooming in only ever shrinks the
visible area, so the art always covers the view and the sand line never drifts.

**Crowd staging and impact juice (2026-11-16, `AGENTS.md` §9 item 21).** Three presentation-only
additions on top of the 15-character crowd: `YardBarrier.gd` draws a low wooden/zinc barrier across
y 524–558 at z −4 (primitives, no texture) so the front row stands behind something instead of being
cut off onto the sand; `ForegroundSpectator.gd` puts one cropped shoulder/bucket-hat silhouette in a
`Foreground` CanvasLayer below the HUD at z +10, bottom-left, alpha 0.85, for the fifth depth plane
screen-space (the camera never drags it); and `CrowdLine` now runs a per-member ambient sway
(0.15–0.29 Hz, ±2.6 px, `position.x` only, so the beat bounce and surge tweens are untouched) plus a
proximity `flinch()` that pulls spectators within 240 px away from a body that is thrown, knocked down
or moving at ≥ 320 px/s. Impact presentation: `BaseFighter.flash_impact(on_beat)` brightens the struck
sprite for 2 physics ticks, and `ParrySpark` gained `hit` (white/gold) and `hit_onbeat` (green/gold)
contact bursts alongside the existing electric parry static. Headless 4.5 check: 18/18 assertions
passed (barrier z −4, spectator z +10, crowd 15/5/6/4, sway moved 9 of 11, flinch reached 7, flash
cleared after 2 ticks, on-beat burst + green flash, spark cap still 4). **Not looked at on screen —
no GPU in the authoring environment**, so colour, occlusion and feel are unverified.

Stage mechanics, all presentation-only (no combat rule, hit registry or round state was changed):

- **Sand underfoot** — `Dust` (`CPUParticles2D`, `local_coords = false`, one-shot) puffs on walking
  footfalls (every 8 ticks), jump takeoff, landings above 260 px/s fall speed, and heavy knockdown
  (`17_seated_landing`). Driven by `BaseFighter._puff()`.
- **Contact shadows** — `GroundShadow.gd`, `top_level` so it stays glued to the sand at y = 600 while
  the fighter is airborne; it shrinks to 0.6 and fades to 0.35 over the ~178 px jump apex.
- **Wind motes** — `WindMotes` drifts 34 slow specks across the sky/upper stage.
- **Bird hazard** — `BirdHazard.gd`: 5 % chance every 15 s, or **B** on demand. The bird crosses the
  upper screen relative to the camera view, drops one splatter on a fighter's lane; a standing
  fighter takes a 12-tick comedic flinch via `BaseFighter.receive_splatter()` (no damage, camera
  shake only), a dodged drop becomes a sand decal. Both the bird and the splats are drawn with
  primitives — no new art assets were invented.
- **132 BPM thump** — `BeatService.beat` → `SpeakerPulse.pulse()` (soft ring at 169, 411 and
  1099, 425) plus a 0.8 % camera zoom micro-pulse that decays in ~0.14 s.
- **Round lighting** — `TimeOfDay` (`CanvasModulate`) tints the world canvas; the HUD is in a
  `CanvasLayer` so it stays readable. `TestArena.set_time_of_day(phase, duration = 3.0)` cross-fades
  the tint, the `Floodlight` (warm additive gradient over the centre lane, night only) and the
  `SunGlow` alpha with one 3 s sine tween. Phase 0 Afternoon Sun `(1.0, 0.98, 0.94)` · phase 1 Golden
  Hour `(1.0, 0.78, 0.58)` · phase 2 Late-Night `(0.48, 0.55, 0.80)` with floodlight 0.34. **N**
  cycles the phases; Round 1 is applied instantly on load. [TODO] Nothing calls it per round yet —
  the arena has no round lifecycle, so the round controller must drive `set_time_of_day(round - 1)`.

**Checks actually run** (Godot 4.3.stable.official headless, Linux, temp harness deleted afterwards):
`--import` then a physics run of `TestArena.tscn`. Results: project imports with no script or
resource errors; `Stage` loads `1280 × 720` at z −10; `Atmosphere` gradient loads at z −9; the bird
spawns, flies and drops — one run splattered the standing dummy (splat parented to `P2` at head
height, both healths still 100), another was dodged and became a sand decal at (820, 600); walking
emitted dust (`amount` 11, `emitting` true); a scripted beat set `thump = 1` and started the speaker
rings; the shadow tracked the fighter at y = 600; camera zoom clamped at 1.6 and the fighter stayed
on the floor. Time of day: phase 0 reported tint `(1, 0.98, 0.94)` with floodlight 0 and sun 1; an
instant `set_time_of_day(2, 0)` reached `(0.48, 0.55, 0.8)` / 0.34 / 0.22; a 0.25 s tween to phase 1
landed exactly on `(1, 0.78, 0.58)` / 0.1 / 0.6; `cycle_time_of_day()` advanced 1 → 2. The `.tscn`
writer needs 4-component `Color(...)` values — a 3-component one is a scene parse error, not a warning.

**Not verified:** nothing has been looked at on screen — no GPU render, no colour/readability
judgement, no feel check of the thump, dust density, mote density, gradient strength, or bird
frequency. Those are owner calls at playtest. The thump amount, 5 %/15 s rate, 12-tick flinch,
speaker-ring centres and dust rates are hand-set defaults, not approved values.

## Workshop arena — UNAPPROVED, no Godot checks run

`scenes/TestArena.tscn` is the main scene: 1280×720, floor and side walls, Player 1 against a
standing dummy, one `BeatService` at 132 BPM wired to both fighters, a tracking/zooming `Camera2D`
that shakes on impact, a primitive HUD (health bars, P1 hype, beat pulse) and a generated 10 s click
loop (`assets/audio/dev/click_132bpm.wav`, 22 beats) because no approved music exists. Sprites are
mapped but the fighters also keep debug collision shapes visible.

Workshop keys: R reset · G dummy guard · M mute · J/K/L/I attacks · T taunt · C crouch · WASD/arrows.

The owner-approved behaviour recorded in AGENTS.md §9 is implemented here: on-beat reward (+15 hype,
1.15× damage, judged at input, hype only on connect unless `hype_requires_connect` is off), the
no-mirroring mic-hand rule (`<anim>_left`, falling back to right-facing frames), and the skank taunt.
Hitstop is 4 ticks for the jab, 7 for the heavies and 9 on KO. `tump` (L) and `upper_box` (I) are
moves: `tump` now plays the selected Sparta kick frames, `upper_box` is still a placeholder reusing jab
art with no ported frame data.

**Checks run: none in Godot.** No engine is available in the authoring environment, so this scene has
never been opened, imported or played, and no hitbox, guard, beat-window or HUD behaviour is verified.

### Playtest pass 1 fixes (2026-11-16, Garfield's Godot session)

- **Missed hits.** Strike detection now tests rectangles in world space against each opponent's
  `hurt_rect()` and polls immediately when `ATTACK_ACTIVE` is entered, instead of waiting for the
  next physics frame's `Area2D` overlap refresh. The hitbox `Area2D` stays in the scene for debug
  display only. Jab reach grew to 84×38 at x 84, BOX to 108×54 at x 96, tump and upper_box widened
  to match. Hitstop, pushback and `camera_shake_requested` are emitted for every resolved contact
  and skipped only when the target ignores the strike (already KO/downed).
- **Jump.** A `jump` animation now exists, using `10_fire_airborne` at the pelvis offset (0, −98),
  and the arc was retuned to `jump_velocity −1000`, `gravity 2800` (≈0.71 s airtime, ≈178 px apex).
- **Skank taunt.** Offset −379 puts the pose's lowest opaque row on the floor, so the pelvis-anchored
  art no longer lifts him off the stage during a grounded taunt.
- **Knockdown / KO.** −399 (`17_seated_landing`) and −426 (`02_knockout`) put the seated and downed
  bodies on the floor line instead of sinking below it.
- **Untouched on purpose:** walk speed (220) and the walk animation/speed (4.4 fps).

**Still pending owner approval:** the heavier BOX concepts beyond the contact frame — the multi-loop
knee-lift clip in `art-source/feedback/box-handoff-2026-11-13/` and its review videos — remain
unapproved concepts and were not copied. The approved foot-off-ground contact frame is the only one
wired; the Baseball-pitch lean comparison video stays at the repository root as a reference only.

## Fighter wiring — UNAPPROVED, no Godot checks run

Claude's audited files are saved as given: `scripts/BaseFighter.gd`, `scripts/rhythm/BeatService.gd`
and `scenes/BaseFighter.tscn`. Physics runs at 60 Hz (`project.godot`). Nothing here has been opened,
run or tested in Godot; the engine is not installed in this environment, so **checks run: none in
Godot**.

`BaseFighter.tscn`'s `AnimatedSprite2D` carries all 17 aligned poses, the 4 walk keys and the selected
frames as 25 animations, using the manifest's own state names where they exist. No original art file
was edited.

| Animation | Frame(s) | Origin (manifest anchor) |
| --- | --- | --- |
| `idle` | `01_idle` | feet, y 900 |
| `walk` | 4 walk keys (`01_contact_a` … `04_pass_b`) | pinned sole, y 566 in the 460×620 keys |
| `crouch` | `07_crouch` | feet, y 900 |
| `jab` | `09_point` (poke — placeholder for a jab) | feet, y 900 |
| `box_startup` / `box_active` / `box_recovery` | `12` / **root `Feedback_Baseball_Pitch_BOX_Foot_Off_Ground.png`** / `14` | feet, y 900 / planted sole row 1406 of 1536 / feet, y 900 |
| `hitstun` | `16_gut_punch` | pelvis, y 610 |
| `knockdown` | `17_seated_landing` | ground contact, y 900 |
| `ko` | `02_knockout` | feet, y 900 |
| `launched` / `tumble` | `03_c_recoil` / `04_inverted_c` | pelvis, y 610 |
| `dizzy` / `salute` | `05`, `06` | 900 / 610 |
| `guard_entry` / `block` / `guard_recovery` | selected `mic-defence/01–02` / `03–04` / `05–06` | 512×512, sole rows 491–492 |
| `sparta_startup` / `sparta_active` / `sparta_recovery` | selected `sparta-kick/01–03` / `04` / `05–06` | 512×512, sole rows 488–490 |
| `skank` | selected `skank/01–05` (5-frame loop; `06` duplicates `01`) | 512×512, sole rows 492–494 |
| `lightah` | selected `lightah/03–04` — **prototype, not wired to a state** | 512×512, airborne (sole 423–425) |
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

### Selected-frame group (owner-approved 2026-11-15)

The 20 frames in `assets/sprites/feedback/selected-frames-2026-11-15/` are a **separate animation group**
from the 1536×1024 pack: they are 512×512 crops whose soles sit at rows 488–494. Each animation owns its
baseline in `ANIM_OFFSET` (`offset.y = 256 − median sole row`) and its display scale in `ANIM_SCALE`
(0.257, so a 477 px standing figure renders at the pack's 122.5 px). No art file was edited, upscaled or
regenerated; `skank/06.png` is copied for provenance but not animated. Wiring:

- **Skank taunt.** `State.TAUNT` now plays `skank/01–05` as a 5-frame loop at 4.4 fps (2.5 beats at
  132 BPM, one pose per eighth note) and `TAUNT_TICKS` is 68 so one full cycle plays before the
  on-beat hype check. [TODO] the 2.3 s→1.13 s commitment change is not feel-tested.
- **Guard.** `guard_entry` (01–02) plays for 8 ticks, then `block` loops on 03–04 while the guard is
  held, and releasing it plays `guard_recovery` (05–06) for 8 ticks. Blockstun hitstun also uses
  `block`. Presentation only — the guard rule itself (directional, from the pre-resolution snapshot)
  is unchanged.
- **Tump (L) is the Sparta kick.** `sparta_startup` (01–03, 12 ticks) → `sparta_active` (04, 4 ticks) →
  `sparta_recovery` (05–06, 12 ticks), with the contact box at stomach height (104×52 at x 88, y −78).
- **Lightah** (`lightah/03–04`) is in `SpriteFrames` as a 2-frame prototype only, flagged **[TODO]**
  for unclipped art (`03.png` touches x = 0) and separate flame VFX; no state plays it yet.
- **BOX (K) contact is the new foot-off-ground frame.** `box_active` now plays
  `Feedback_Baseball_Pitch_BOX_Foot_Off_Ground.png` (1024×1536, baseball-pitch lean, right knee lifted,
  left support foot planted) between `12` startup and `14` recovery. Its own placement is
  `offset (479, −638)` at `scale 0.1013`: sole row 1406 → `768 − 1406 = −638` puts the planted foot on
  the floor line, and 1202 px crown-to-sole × 0.1013 = 121.9 px on screen, against the pack idle's
  121.75 px. The x offset reproduces the planted-foot screen position the pack's 12/13/14 share
  (+34…+40 px forward of the origin, here +37.4 px). No pixel was resampled in the source file; the
  copy is byte-identical. [TODO] The contact box is still the old 108×54 at x 96 — the new frame's
  raised-palm silhouette has no forward extension, so the reach needs a playtest. Pose
  `13_box_palm` stays in the pack but is no longer animated.

## Still missing ([TODO] in the blueprint)

- **Audio**: no sound, music, voice or SFX files exist anywhere in the repository yet.
- **Spriteriffic sprite sheets**: no exported sheets or grid layouts exist yet.
- **Interference props**: no bottle, folding-chair or fire-extinguisher art exists yet, so
  `assets/sprites/` has no `bottles/`, `chairs/` or `fire_extinguishers/` folder to fill.
- **Godot version, renderer and export path**: unpinned; not verified on any target device.

No scene, script, engine setting or gameplay rule has been created or changed here.

# Sound Clash Brawl — Master Blueprint

Last updated: 2026-11-13. Owner and final creative approver: Garfield Connell.

This is the project instruction and handoff document for all agents. It records verified repository work, recovered design decisions, and the owner's Godot migration direction. **Implemented**, **asset available**, **planned**, and **[TODO]** are different statuses. Never present a concept, imported illustration, successful upload, or old test report as a working or approved feature.

Working repository for this blueprint: `Geefense/Sound-Clash-Brawl-Lab`, root `AGENTS.md`. Original development repository: `Geefense/Sound-Clash-Brawl`. Keep both histories intact. [TODO] Explicitly choose the long-term production repository before migration merges across repositories. This document does not authorize deleting or replacing either project.

## 1. Project Overview & Creative Vision

**Sound Clash Brawl** is a 2D *Street Fighter II*-style rhythm-fighting game rooted in Jamaican **sound system culture**. Sound clash is the competitive side of that culture: selectors, DJs, MCs, dubplates, crews, towering speaker stacks, dances, musical rivalry, and crowd response. Combine Dancehall-inspired fighting stances, rhythm-synced strikes, DJ selectors, towering sound systems, and slapstick party comedy.

The fighters must feel like personalities at a dance, not interchangeable boxers. Skanking, a rude-boy swagger, exaggerated footwork, head held high, mic beef, taunts, sudden head snaps, body folds, and ridiculous knockdowns define the feel. Comedy comes from performance, timing, impact, Patois, and reactions. Preserve responsive arcade control underneath the exaggeration.

### Curated reference direction

- *Street Fighter II*: immediate 2D readability, distinct silhouettes, readable attacks, spacing, and character identity. Analyze principles; do not copy proprietary assets.
- Realistic fight inspiration previously discussed: Bruce Lee versus Kareem and Tyson versus Ali; weight transfer, hip/shoulder rotation, convincing contact and stagger.
- Saved venue/animation reference: `https://www.instagram.com/techiebysa/`. The owner's described examples include Muhammad Ali versus Mike Tyson, Bruce Lee, Jean-Claude Van Damme versus Chuck Norris, John Wick versus 007, and Mr Bean; connected environments such as a bar into a car. These are visual references, not reusable animation frames.
- Later stylization direction: Calvin & Hobbes-like exaggeration, including a slap hand as big as the body. Preserve Feedback's identity while exploring expressive squash, stretch, recoil, and comic silhouettes. [TODO] Consolidate the final style sheet and exact reference clips/timecodes.
- Future connected venue ideas: dance floor, bar, speaker stacks, tables, parked cars, and crowd reactions. These remain backlog until the core fighter works.

### Fighter identity

**Feedback is Fighter #1.** Lean/slim build; burgundy/maroon bucket hat and track jacket, cream sleeve stripes, original dreadlock texture/colour under the hat, fitted trousers, consistent Clarks Wallabees, concealed eyes/face, and a single gold tooth when visible. No extra thumbs, unexplained white hair streaks, braids replacing the locks, oversized boots, or unwanted back pockets. Separate shadows and effects from source art.

**Mic continuity requires version-specific care.** Earlier pose work used the left hand; the later four-key walk study explicitly uses the right hand. Never silently flip or normalize one set into the other. Each sequence must keep one mic in its declared anatomical hand and one continuous cable, including forearm wraps. A mic cannot disappear while adjusting the hat or reappear in another hand. [TODO] Owner resolves the canonical cross-set hand before final fighter integration. Mirroring art changes apparent handedness and is provisional only.

**Other concepts:** Lickshot is retained; Sky Juice is a tall-fighter concept. Lickshot / Disc Jock Lickshot / Booyaka Lickshot are recorded name options, with final naming [TODO]. Do not build Fighter #2 before the Godot migration gate.

## 2. Multi-Agent Team & Zero-Cost Workflow

| Role/tool | Responsibility | Handoff boundary |
| --- | --- | --- |
| **ChatGPT (Creative Director & Reference Analyst)** | Organize design, analyze visual inspiration/references, maintain this blueprint and the Patois/comedy lexicon, review visual continuity. | Supply concrete references, acceptance criteria, and honest approval status. Garfield retains final creative approval. |
| **Freebuff (Local Repo Builder & Heavy Lifter)** | Work directly in the local GitHub folder; write scripts, wire up exported Flow animations, organize/verify files, run checks, and handle commits. | Inspect the actual branch and files first; preserve combat work and source art. Wiring exports is not permission to spend animation credits. |
| **Claude (Lead Systems & Godot Architect)** | Join immediately after Fighter #1's basic TypeScript prototype is wrapped up. Lead the Godot migration, translate the TypeScript FSM behavior into GDScript, and architect reusable multi-fighter systems and crowd interference. | Port the accepted reference behavior before expanding the game. This is the intended team assignment, not a claim that Claude is already connected or has completed work. |
| **Flow** | Character animation tests and visual sequence ideation. | Outputs are candidates until checked. Flow does not define combat timing, collision truth, or final voice lines. |

### Zero-cost operating rules

1. No new spending: use Godot, local Git, existing assets, free tools, and available free allowances. AI assistants, Flow, Codespaces, hosting, and storage are not inherently unlimited/free. If an allowance is exhausted, continue with local scripts/placeholders and queued work; do not purchase credits, upgrade plans, or enable billable services automatically.
2. GitHub is the shared production record. Prefer direct repository delivery for Freebuff; do not make Garfield repeatedly download and re-upload assets that are already accessible.
3. One owner per task and one clear branch/commit handoff. Specialist work can be split when the active task authorizes delegation. Avoid simultaneous edits to the same file and avoid multiple agents rebuilding the same system.
4. Each handoff states repository, branch, commit, changed paths, what works, checks actually run, approval status, and next blocker. Never say an upload, build, or integration succeeded without evidence.
5. Log design, reference analysis, art preparation, animation review, coding, and testing as Sound Clash development time. [TODO] Maintain a consolidated session-hours ledger; do not invent totals or promise a fixed percentage reduction.
6. Make narrow, reviewable changes. Preserve originals; keep rejected art and candidates distinguishable from approved production assets.

## 3. Current TypeScript Prototype & Asset Inventory

### Verified web baseline and branch boundaries

Inspected Lab `main` at `993d7bfda627bd5018401f2b4d0d7e4ee6d84e2e`. Phaser 3 (`^3.90.0`), TypeScript, React/TSX, Vite, HTML, CSS/Tailwind, and pnpm workspaces form the web prototype. Canvas: 1280 × 720. This is a preservation inventory, not a fresh test certification.

| Location | Existing work / migration treatment |
| --- | --- |
| `artifacts/sound-clash/src/game/simulation/SimulationEngine.ts` | Fixed-step combat, fighter updates, AI, separation/facing, attacks, damage/blocking, combos, knockdown, rounds/KO handling, event generation, seeded randomness. Port rules independently from visuals. |
| `artifacts/sound-clash/src/game/simulation/types.ts` | Serializable fighter/game/input/event shapes; 60 Hz, `FIXED_TIMESTEP = 1 / 60`. Preserve a comparable replay/state contract. |
| `artifacts/sound-clash/src/game/combatRules.ts` | Attack profiles, startup/active windows, reach, strike geometry, rectangle/circle contact, directional blocking, combo helpers, damage, winner decision. |
| `artifacts/sound-clash/src/game/GameScene.ts` | Phaser input adapter, fixed-step accumulator, procedural/vector fighter rendering, arena/background, combo labels, sparks, shake, and simulation-to-presentation bridge. |
| `artifacts/sound-clash/src/game/visualReactions.ts` | Presentation-only jab/head/body recoil and knockdown curves. These offsets must not feed gameplay collisions. |
| `artifacts/sound-clash/src/game/SoundEffects.ts` | Web Audio oscillator effects for hit, block, jump, round, KO; user-enabled sound. Placeholder tones, not a finished music/voice library. |
| `artifacts/sound-clash/src/game/types.ts` | Match/UI snapshot, touch actions, dimensions. |
| `artifacts/sound-clash/src/App.tsx` | Phaser mounting, health bars, clock, round-win indicators, intro/KO/result overlays, rematch, sound toggle, keyboard guide and pointer-based touch controls. SIDEWINDER/BASSLINE are existing placeholder UI names, not a replacement roster decision. |
| `artifacts/sound-clash/src/index.css`, `index.html`, `src/main.tsx` | Responsive web shell, styling and bootstrap; retain as reference rather than translating DOM/CSS literally into Godot. |
| `artifacts/sound-clash/tests/*.test.mjs` | Combat, simulation and visual-reaction tests. Preserve regression cases and expected behavior during port. |
| `artifacts/sound-clash/art-source/feedback/` | Source art, imported pose studies, walk tests, review reports, extraction/alignment scripts and comparison players. Keep source and derived assets distinct. |
| `artifacts/api-server/`, `lib/`, `scripts/`, `artifacts/mockup-sandbox/` | Existing workspace scaffolding. Retain; do not make backend/database infrastructure a requirement for the local Godot fighter. |

### Controls and combat already represented

- Move: A/D or left/right arrows. Jump: W/up. Block: S/down. Touch equivalents exist. **S currently means block; CROUCH is a planned distinct state and must not silently replace it.**
- J: jab (`light`), including extended reach; L: heavy body TUMP (`heavy` internally); K: heavy head/backhand BOX (`head` internally); I: rising Upper Box (`upper`). UI/touch action labels differ from some internal names: map deliberately.
- Current geometry includes a body rectangle, head circle, fist/strike circle, forward-facing checks, active windows and one hit per attack. Current damage: jab 8 / blocked 2; other attacks 15 / blocked 4.
- Mixed combo helpers and the **Three Piece J → L → I** are present. Three Piece requires connected, unblocked hits inside its windows, launches/knocks down on completion, and uses **HIM DUN! only when that finisher causes KO**. Ordinary KO uses **KO!**. [TODO] Audit head/body alias acceptance in Three Piece before declaring the L-specific sequence exact.
- Current Lab `main` combat constants: combo window 0.72 s; buffer opens at 0.14 s. Older reports mention other values: do not overwrite current values from memory.
- Match: first to two round wins; 90-second rounds, KO/timeout/draw handling, round reset and rematch. KO sequence constants: 9 impact-freeze ticks, 36 knockdown/fall ticks, 72 announcement ticks. Preserve the grounded KO presentation.
- Historical hardening work includes snapshot-based simultaneous hit resolution/trades, counterhits, committed blocking and explicit state cloning. **Branch-specific:** `lab/combat-engine-hardening` at `3e663efda6a8c9203a4823f4395ae30fd62567d9` differs from Lab `main`, which still shows JSON cloning and a different resolution path. [TODO] Compare and select the accepted combat baseline before porting; do not assume every historical improvement is merged.

### Rhythm/audio status — important distinction

Combat timing windows and input buffers exist. They are **not yet evidence of music-synced beat judgement**. No BPM chart, authoritative beat clock, input-to-beat grading, calibration, or beat-synced damage/hype logic was verified in the inspected baseline. The UI's rhythm wording does not establish implementation.

**[TODO] Before the TypeScript exit milestone:** implement or locate a minimal beat clock and demonstrate the basic three-hit rhythm combo against it. Record BPM, beat offset, early/late window, latency handling, pause/restart behavior, and what on-beat versus off-beat means. Use a local generated click track if no approved music exists. Keep attacks responsive; do not make inputs wait for a beat without an explicit design decision.

### Feedback asset pack — available on a separate branch

Verified branch `assets/feedback-transparent-poses`, commit `ed34fa6fa581e9414bfbe2327339a13ab2eeb854`; also present on inspected `feat/combat-animation-refinement` at `6d091754ec9702376854f9df2e39280d6ba9da70`. Path: `artifacts/sound-clash/public/assets/feedback/`. **Not present on inspected Lab `main`.**

Support files: `README.md`, `feedback.poses.json`, `feedbackPose.ts`, `pose-preview.html`. The 17 RGBA PNGs under `aligned/` are:

| # | Filename | Intended content |
| --- | --- | --- |
| 01 | `01_idle.png` | Idle |
| 02 | `02_knockout.png` | KO |
| 03 | `03_c_recoil.png` | C-shaped recoil/launch |
| 04 | `04_inverted_c.png` | Inverted tumble |
| 05 | `05_dizzy_bogle.png` | Bogle dizzy |
| 06 | `06_rear_salute.png` | Rear salute |
| 07 | `07_crouch.png` | Crouch/low attack |
| 08 | `08_block.png` | Guard |
| 09 | `09_point.png` | Point/poke |
| 10 | `10_fire_airborne.png` | Airborne fire pose |
| 11 | `11_fire_grounded.png` | Grounded fire pose |
| 12 | `12_backhand_windup.png` | BOX startup |
| 13 | `13_box_palm.png` | BOX contact |
| 14 | `14_followthrough.png` | BOX recovery |
| 15 | `15_skank.png` | Skank |
| 16 | `16_gut_punch.png` | Body-hit reaction |
| 17 | `17_seated_landing.png` | Seated landing |

Manifest canvas: 1536 × 1024; common grounded anchor `(768, 900)`, airborne pelvis anchor `(768, 610)`, with per-pose metadata and exceptions. Anchors are visually estimated and require gameplay tuning. These are **pose illustrations, not finished interpolated animation clips**. Render origins are not hitboxes. Preserve separate procedural shadows/effects and source references.

Six additional imported studies under `art-source/feedback/imported-poses/`: `01_point_swagger.png`, `02_swagger_step.png`, `03_skank_bounce.png`, `04_swagger_challenge.png`, `05_skank_point.png`, `06_come_here_swagger.png`. Transparent-background cleanup and gameplay comparisons exist; preserve them.

### Walk work and immediate next task

- `art-source/feedback/feedback-walk-flow-test.mp4` and `walk-video-review/`: original motion test and inspection reports. Known continuity failures in generated clips include two mics, hand switching, disconnected cord and disappearing props; no automatic approval.
- `walk-cycle-preview/`: extracted frame studies, manifest, JS data, HTML player, seam comparison and `feedback-walk-loop-unapproved-6x.mp4`.
- `walk-four-keys/`: original `source-sheet.jpeg`, four `poses/` keys, `extract_keys.py`, `trace_legs.py`, `verify_four_keys.py`, JSON measurements, crossing/grip/cable review images, HTML loops and notes. Prepared splices and rejected/redrawn candidates remain comparison material.
- Latest isolated candidate: `walk-four-keys/candidates/targeted-pass-b-test.html`, committed on Lab `main` as `993d7bf`. Self-contained player keeps original CONTACT A, PASS A, CONTACT B and replaces **only PASS B**. Original files under `poses/` remain untouched.
- New PASS B has a straighter support leg and lifted boot behind. At the existing 0.902 scale/floor alignment: lift B ≈42 px versus A ≈43 px; boot-centroid spacing B ≈93 px versus A ≈81 px. These are image measurements, not a completed gait/phase verdict. Opposite leg identity at hip/knee overlap remains unresolved.
- **Status: unapproved movement test.** Upload approval was permission to save it, not animation approval. Next: step through the full loop with Freebuff, trace anatomical near/far legs across contacts and passes, check phase/bop/arm counter-swing/mic/cable/floor contact. Correct only failed details, then seek creative approval and test at gameplay scale.
- Align by support sole, use one justified scale, preserve natural bob; never normalize each pose's total height to hide phase errors. Similar screen-space boot positions do not prove the same anatomical leg is leading. Report uncertainty rather than guessing.

### Interference and audio inventory gaps

The owner identifies bottles, chairs, fire extinguishers and Flow sprite/audio exports as migration inventory. No matching bottle/chair/extinguisher directories or finished soundtrack/voice asset tree was found on inspected Lab `main`, pose, animation-refinement, sprite-pipeline or combat-hardening snapshots. **[TODO] Freebuff locates any local/unmerged files and records exact paths, filenames, status and source before copying.** Do not claim missing files exist or replace them with silently invented assets.

Historical reports include 98 and later 109 passing tests plus typecheck/build success. These apply to their historical branches/runs. [TODO] Run and record the current selected baseline checks; no fresh test run is certified by this documentation milestone.

## 4. Godot Engine Migration & Repo Setup Strategy

### Why Godot

Godot is 100% free/open-source under the MIT license, with no engine license fee or royalty. Its plain-text `.gd` scripts, `.tscn` scenes, `.tres` resources and `project.godot` work well with GitHub and local agent edits. Git works externally without an editor plugin; Git inside the editor uses a plugin.

Reusable Fighter scenes, visual collision-shape placement over Flow-derived sprites, animation tools, Camera2D plus small shake/impact scripts, and scene composition should cut repetitive work versus a fully manual pipeline. **Beating the earlier 190-hour manual estimate is a goal, not a validated schedule or guarantee.** [TODO] Re-estimate after the first Godot parity slice. Godot does not repair bad source animation or synchronize gameplay to music automatically.

Official references:

- License: `https://godotengine.org/license/`
- Git/ignore guidance: `https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html`
- Audio timing: `https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html`

Pin one Godot 4.x version at project creation and use its matching documentation; [TODO] record version, renderer, installation steps and Chromebook execution/export feasibility. Do not silently depend on paid remote machines. Include engine attribution/license information in release documentation.

### Transition milestone and order

1. Finish **Fighter #1 core movement and a basic three-hit rhythm combo in TypeScript** as a playable reference. Approve the walk and demonstrate beat judgement; preserve jump, guard, collision, hit reactions, grounded KO and rematch behavior.
2. Capture the exact baseline commit, controls, numeric tuning, short reference recordings, accepted art/anchors, deterministic input traces, expected state/events and test results. Resolve branch-only combat improvements deliberately.
3. Claude leads the direct port into Godot with Freebuff implementing locally. First target: Feedback versus a Feedback dummy/self-match in one simple arena, preserving movement/combo feel.
4. Validate TypeScript/Godot behavior parity. **Then** build Fighter #2, stage production, match-party transitions and full crowd mechanics. Do not finish the whole game twice in different engines.

### Quick Tip & Mandatory Repo Setup When Starting Godot

When creating a Godot project or adding `/godot` inside the existing GitHub repository, ask Freebuff to do all of the following:

1. **Generate a standard Godot `.gitignore`**, preserving the existing web rules. Ignore the project's `.godot/` cache and imported `*.translation` outputs according to the pinned engine version. Generate `.gitattributes` for consistent text line endings. Never broadly ignore original PNG/audio files or required resource sidecars/UIDs.
2. **Copy this `AGENTS.md` and the organized sprite/audio folders directly into the Godot project directory**, including located bottles, chairs, fire extinguishers and Flow exports, so Freebuff and Claude see them immediately. Preserve approved originals, filenames, anchors, licensing/source notes and manifests. Verify copies by count/hash. Missing assets remain `[TODO]`; do not copy broken candidate files as approved art.
3. Keep repository-root `AGENTS.md` authoritative. The `/godot/AGENTS.md` copy must match it after milestones; do not create conflicting nested instructions.
4. Commit `project.godot`, source scenes/scripts/resources and required Godot metadata; exclude generated cache, temporary renders and exported builds. Inspect `git status` before committing. No nested Git repository inside `/godot`.
5. Retain the TypeScript prototype as a runnable reference throughout the port. This request creates the blueprint; it does **not** start the engine migration now.

Proposed layout, **not yet created**: `godot/project.godot`; `godot/AGENTS.md`; `godot/scenes/fighters/Fighter.tscn`; `godot/scenes/match/`; `godot/scenes/hazards/ThrowableHazard.tscn`; `godot/scripts/{combat,fsm,rhythm,crowd}/`; `godot/data/{fighters,moves,hazards}/`; `godot/assets/{sprites,audio,flow_exports}/`. Under sprites, organize `feedback/`, `bottles/`, `chairs/`, `fire_extinguishers/`. [TODO] Final paths after inventory and actual engine setup.

## 5. Finite State Machine (FSM) Architecture (TypeScript -> GDScript Blueprint)

These explicit FSMs are the **target architecture**. Current TypeScript behavior is distributed across action fields, timers, flags and match statuses; it is not already a one-to-one implementation of every state below.

### Fighter States

| State | Responsibilities / transitions |
| --- | --- |
| `IDLE` | Dancehall bounce stance. Accept movement, jump, crouch, guard, attacks and taunt when allowed. |
| `WALK` | Preserve acceleration/speed/spacing/facing feel; select forward/back animation without changing leg/mic identity. Return to idle when released. |
| `JUMP` | Deterministic airborne motion and landing; explicit rules for air attacks and side switches. [TODO] Final air move set. |
| `CROUCH` | Separate low posture/hurtbox and low-move rules. [TODO] Input distinct from existing S guard. |
| `ATTACK_STARTUP` | Latch move and attack-facing, run startup ticks, record eligible buffered inputs. Hitbox disabled. |
| `ATTACK_ACTIVE` | Enable authored visual hitbox frames, perform collision plus rhythm beat-window judgement, prevent repeated contact from the same strike. Collision and beat quality are separate results. |
| `ATTACK_RECOVERY` | Disable hitbox, run recovery/cancel/buffer rules, then idle/next allowed action. |
| `TAUNT` | Risk/reward crowd hype builder; beat-synced rewards, interruptibility and exposure. [TODO] Exact values/cancel policy. |
| `HITSTUN` | Apply accepted hit/block response; clear incompatible attack buffers; return when stun ends. |
| `KNOCKDOWN` | Launch/fall/ground contact/get-up path. Nonlethal knockdowns recover; lethal ones proceed to KO. |
| `KO` | No fighter control; freeze/fall/grounded announcement/result sequence, then round/match orchestration. |

**Guard/block is still mandatory.** The requested fighter-state list has no `BLOCK`: model guard as an explicit defensive substate/flag with directional/grounded rules and blockstun, or add a clearly documented state during implementation. Never remove blocking to fit the enum. Use one transition authority and legal-transition rules; no scattered scene scripts assigning conflicting states.

### Match Phase States

| State | Party behavior |
| --- | --- |
| `PARTY_INTRO` | Crowded dance floor, selectors, dancing and mic beef; combat disabled. |
| `CROWD_SCATTER` | Crowd clears into a circle; establish safe fight bounds and opening cue. |
| `RHYTHM_BRAWL` | Active fight, rhythm judgement and scheduled thrown hazards. |
| `DANCE_FLOOR_RETURN` | Winner celebration; combat/hazards stop and crowd floods back. |

These phases sit above the preserved round lifecycle (`pre-round`, `playing`, `impact-freeze`, `knockdown`, `ko-announcement`, `round-transition`, `finished`). A party phase is not a substitute for round scoring. [TODO] Define whether each new round repeats the crowd-clear sequence or remains inside the circle; celebration after match versus round must be explicit.

### Port contracts and scene ownership

| TypeScript concern | Godot target |
| --- | --- |
| `FighterInput` / keyboard/touch | Input adapter producing one frame/tick command; configurable InputMap and touch UI. |
| Fighter state/timers | Typed GDScript state model and fighter FSM; integer tick deadlines where practical. |
| `simulateTick`, collision/combo rules | Engine-independent combat rules stepped at 60 Hz. Preserve snapshot simultaneous resolution where accepted. |
| Attack profiles | Data-driven move resources: startup/active/recovery, damage, reach, hitstun, knockback, cancel windows, beat rules, hitbox tracks. |
| `GameScene` / pose renderer | Reusable `Fighter.tscn` with Sprite2D/AnimatedSprite2D or AnimationPlayer, separate hurt/hit/push boxes and debug visualization. |
| Game events | Signals/event queue for UI, audio, sparks, camera shake and crowd reactions; presentation never changes collision outcomes. |
| Match snapshot / React overlays | Match controller plus Control/CanvasLayer HUD and results UI. |
| Web Audio tones | AudioStreamPlayer/SFX adapter; approved local audio assets later. |

Use a common Fighter scene plus fighter-specific data/assets, not copied combat scripts for each character. Visual hitbox tools author data; the simulation owns when it is active. Do not let variable render FPS, animation callbacks, camera shake, or Godot physics callback order decide who hits first. Ordinary Godot physics is not automatically bit-for-bit deterministic across platforms.

**Beat service:** provide BPM/offset, nearest-beat error, judgement window and latency calibration. Timestamp inputs against the audio clock and pass recorded judgement/input data into the combat tick; keep rendering separate. [TODO] Decide whether the beat window judges input time, active-frame contact, or both; define on-beat reward/off-beat behavior and hitstop/music behavior. No guessed BPM or invented timing windows. Do not drive a long song with a drifting visual timer.

Replay parity must preserve seeded RNG explicitly; Godot's default RNG is not a drop-in replacement for the current seeded algorithm. [TODO] Port the algorithm with matching unsigned behavior or document a deliberate replay-version break. Test same inputs/seed and mirrored fighter-order scenarios.

## 6. Crowd Interference & Party Mechanics

**Planned after Godot fighter parity.** Shared `ThrowableHazard` design: one reusable scene/controller with type-specific data, not three unrelated systems.

| Hazard | Motion/impact personality | Planned consequence |
| --- | --- | --- |
| Bottle | Fast throw; quick shatter | Brief hit response and shatter visual/audio; [TODO] damage and whether fragments are cosmetic. |
| Folding chair | Heavy readable arc; metallic clang | Strong impact/knockdown; [TODO] trajectory, telegraph and recovery values. |
| Fire extinguisher | Canister throw/activation; foam burst | Foam cloud and slip hazard; [TODO] cloud duration, area, movement effect and cleanup. |

Proposed shared fields: hazard ID/type, source crowd member, target/aim, spawn tick, position/velocity/gravity, collision mask, hitbox, damage/knockback, lifetime, impact effect/audio, remaining hit count and spawned floor-effect data. States: queued/telegraphed → airborne → impact → spent; extinguisher may create a separate timed floor area. Keep arcs and contacts in the authoritative simulation if they affect combat; use scene visuals for presentation.

Crowd hype or successful beat-synced taunts enqueue throws through a crowd director. Use seeded choices, bounded frequency, readable warnings and recorded events. The crowd can have funny, unpredictable preferences without making every throw unavoidable. [TODO] Hype thresholds, target bias, cooldowns, simultaneous hazard cap, player avoidance/blocking rules, and exact taunt risk/reward. No spawn during intro/transition/KO unless explicitly authored as harmless presentation.

Keep crowd visuals, navigation, hype calculation, throw scheduling and hazard resolution modular. Clean hazards/foam at round reset and stop new gameplay hits when the round ends. First prototype one bottle and one readable warning before adding the chair/extinguisher. Future bar/speaker/car interactions remain backlog.

**Music interruption gag:** Lickshot steals the playing record and the tune stops. [TODO] Define beat-clock pause/rebase/new-track policy before making this affect rhythm judgement; continue deliberate combat/SFX behavior during the gap. A gag must not accidentally desynchronize input timing.

## 7. Authentic Patois & Comedy Lexicon

**STRICT RULE FOR ALL AGENTS: Preserve all Patois spellings, slang, capitalization variants and comedic phrasing verbatim. Never rewrite or “correct” them into standard English.** English glosses belong in a separate field. These spellings encode pronunciation and comic timing. Do not silently merge variants, substitute a dictionary spelling, invent a translation, or turn an assistant suggestion into an owner-approved line.

This register includes all phrases recoverable from the visible conversation, supplied project history and retrieved project notes. [TODO] Audit older unavailable conversations/voice notes for additional entries; completeness beyond accessible records is not certified. `[TODO]` means the owner's exact gloss or intended usage still needs recovery.

### Owner-taught phrases, pronunciation and cultural context

| Exact phrase / recorded variant | Meaning / cultural note |
| --- | --- |
| `Outta Awduh` | Out of Order. |
| `Klawk ah Strike` | Clock is striking. [TODO] Exact game trigger. |
| `Wah mi seh` | What did I say? |
| `Ghett Tup` | Get up. |
| `Stop-pit!` | Stop it. |
| `Yam dat` | Eat that. |
| `Hole Lawn deh` | Hold on there. |
| `Shut-Tup!` | Shut Up! |
| `Shut-Tup Mon!` | Shut Up, Man; preserve exact wording. |
| `Shut tup Mon!` | Separately recorded variant; do not normalize automatically. |
| `Mon` | Man. |
| `Levll` | Level; turn down the sound so the performer can talk on the mic. Owner also described it as a sneaky/polite way to say shut up. |
| `Bruk Awf him foot!` | “break off his foot”; intended meaning: break his leg. Cartoon combat phrase. |
| `Genaral` | General; a good friend or someone you respect. |
| `Wrispek` | Respect. Pronunciation matters. |
| `everyting` | Everything. |
| `Zeen` | Scene; conversational “Cool?” / acknowledgement. |
| `Brudda` | Brother, friend, or broadly any male. |
| `My Yout` | My Youth; child, kid, or someone much younger. |
| `Wrispek Brudda Zeen?` | Owner's corrected phrase order. Preserve it. |
| `Wawk Good` | Walk Good; be safe; can replace goodbye. |
| `Eat good` | Taste good. |
| `Tase` | Taste. |
| `Heeeyaut!` | Idiot. |
| `Likkle` | Little. |
| `Heeed` | Pronunciation component; owner specified silent D. |
| `Yaut` | Pronounced like the boat “yacht”; retain the owner's spelling. |
| `Heeed and Yaut like the boat` | Exact pronunciation explanation. More e's help, “but not too long”. |
| `Likkle Heeeyaut` | Owner's comic combination. |
| `Likkle heeeyaut sound!` | Exact recorded sound-clash jab. |
| `Yuh likkle heeeyaut!` | Accepted taunt recovered from prior conversation. |
| `Mash` | Owner's gloss: Mosh. [TODO] Recover full use/context. |
| `Cum mout ta mi vishaun` | Come out of my vision. |
| `Gweh!` | Go away! |
| `Tump` / `TUMP` | Hard fist punch/strike; heavy body-shot vocabulary. Preserve variants by context. |
| `BOX` | Project move label for heavy backhand/open-hand head strike. [TODO] Owner's full cultural gloss. |
| `Upper Box` | Rising open-hand strike; exact move name. |
| `Butt weight` | But wait; surprise when something did not happen as expected. Owner's example: promised chocolate bar, returned with rotisserie chicken. |
| `Cum Again` | Abbreviated from “wheel and cum again”: rewind/spin the tune back and start over. |
| `wheel and cum again` | Recorded cultural explanation; preserve wording/case in its original context. |
| `Beg You Won Stop Drivuh` | Saved phrase; [TODO] Recover exact translation/context. Do not guess it from spelling. |
| `Beg You Won Stop` | Ground-hand/pleading gag variant; [TODO] Exact owner gloss. |
| `See it Deh` | Saved phrase; [TODO] Exact owner gloss. |
| `Woy!` | Saved exclamation; [TODO] Exact owner usage. |
| `Give Tanks` | Saved phrase; [TODO] Exact owner gloss. |
| `Mossive` | Saved crowd/announcer phrase; [TODO] Exact owner gloss. |
| `Nuh Bodda wit Dot!` | Saved phrase; [TODO] Exact owner gloss. |
| `CHAMPION SOUND!` | Saved announcer/crowd callout. [TODO] Trigger/recording. |
| `More Fiya!` | Saved hype callout. [TODO] Exact gloss/trigger. |
| `Fiya fi Dat!` | Saved hype callout. [TODO] Exact gloss/trigger. |
| `HIM DUN!` | Implemented Three Piece KO callout; only when the finisher causes KO. |
| `THREE PIECE!` | Implemented successful nonlethal Three Piece feedback. |
| `KO!` | Implemented ordinary KO overlay. |
| `Lighter!` | Requested lighter taunt shout. |
| `Feedbackhand` | Proposed backhand pun. |

### Comedy, taunt and move register

- Skanking fight-opening stance; lighter raised with `Lighter!`; two-finger forehead poke; skanking point/rear view; mic swing; mic-cord throw; “hand off and slap” using the mic cord; `Feedbackhand` pun.
- Dizzy/Bogle reaction; gut-punch fold; seated bounce/landing; upside-down airborne, C-shape, upside-down J, E, Superman and slanted I silhouettes; shoe almost off; face-slide knockdown/slide mark; hat-cover KO variation. Availability varies: the manifest contains some illustrated poses, while others remain ideas. [TODO] Approve animation timing and missing sequences separately.
- Ground-hand `Beg You Won Stop` idea. Do not replace the Patois with a generic pleading line.
- Oversized slap hand and exaggerated recoil must preserve readable contact and the lean Feedback silhouette. A front-facing salute was rejected; a stance with the front of the shoe off the ground was also rejected.
- Lickshot's proposed vinyl projectiles: casually reach off-screen while watching the opponent, steal records from the unseen selecta, escalate to stealing the entire crate, and occasionally remove the currently playing record so music cuts out. Keep the selecta unseen; reveal the gag through a hand, stolen objects and an annoyed off-screen voice.
- Owner's exact selecta dialogue: `A my record dat?` and `No, no, no, no—stop it!`. Source: `Lickshot-Offscreen-Selecta-Gag.md`, saved 2026-11-09; proposed, not implemented. [TODO] Final performance/trigger without silently rewriting the lines.
- Earlier concept speaker gags: belt speaker, concealed jacket speaker and rear speaker, recorded label `Talking Out Your Ass Gag`; retractable mic cord for `Performance / Taunt / Special`. [TODO] Confirm which concepts survive into Feedback's final move set.
- Contextual commentary may remember prior-round embarrassment/comebacks; pullback, crowd roar and bass return after major hits remain ideas, not implemented audio logic.

### Recovered assistant suggestions — keep separate from approved owner wording

| Suggestion | Status |
| --- | --- |
| `Heeed-yaut!` | Derived pronunciation form from prior assistant context; [TODO] Confirm canonical use. |
| `BUTT WEIGHT!` | Suggested surprise-recovery/contradiction callout; [TODO] Owner approval. |
| `BUTT WEIGHT! Mi thought yuh seh yuh a buy chocolate!` | Prior assistant example, not established dialogue. |
| `CUM AGAIN!` / `Wheel and Cum Again!` | Suggested rewind cues, including vinyl rewind/alternate-angle KO replay; [TODO] Owner approval and scope. |
| `Lick him again!` | Prior contrast example meaning strike again; do not confuse with rewinding the tune. |
| `Put down mi box!` | Optional assistant suggestion for the stolen crate gag; not confirmed owner dialogue. |

Generated Flow speech such as `yo, check this out`, `I'm bringing it to the stage`, and `You know how we do, ha ha ha` was rejected. Do not recycle it as approved dialogue. Visual animation tests should not invent voice performances; use controlled audio later.

## 8. Coding & Project Guardrails

### Mandatory behavior

1. Read this file at task start; inspect repository/branch/current code before editing. Preserve the distinction between Lab and original development repo, and between `main`, combat-hardening and asset branches.
2. Keep scripts modular: input, combat rules, FSM, fighter data, beat service, renderer, audio, crowd director, hazards and UI have clear ownership. Avoid a single all-purpose scene script or fighter-specific copies of shared combat.
3. Never break core movement feel, input buffering, beat-sync responsiveness, directional guard, simultaneous contact rules or grounded KO presentation to simplify a port. Match behavior first; rebalance only as an explicit change.
4. Do not confuse combat active windows with rhythm windows, pose origins with hitboxes, screen-left with anatomical left, imported poses with animation, or save approval with creative approval.
5. Preserve verbatim Patois. Append new owner phrases with exact spelling, separate gloss/context, source and approval status. Keep rejected lines and assistant suggestions distinguishable.
6. Validate art at full size and gameplay size: one mic, correct declared hand, continuous cable, consistent face concealment/gold tooth/hair/hat/build/clothing/boots; no extra digits, trapped backgrounds, broken transparency, or cut-off PNG rows. Check anchors, foot contact, leg identity, walk phase and animation seam. Never hide an error with per-frame scale changes or mark uncertain details passed.
7. Keep original sources immutable where practical; put comparison splices, redraws and generated candidates in clearly labeled locations. Do not overwrite approved assets as a side effect of running an extractor.
8. No paid dependencies/services or automatic credit spending. No speculative multiplayer/backend expansion before the local fighter and Godot parity gate. Keep large temporary exports/caches out of Git; avoid duplicate binary/base64 transfer packs when normal local Git can carry verified bytes.
9. Use small commits with concrete messages. No force-push, destructive history rewrite, deletion of old prototypes, or broad branch merging as routine cleanup. Reconcile upstream changes before writing; preserve unrelated work.
10. **Update `AGENTS.md` after every completed milestone.** Record date, commit/path, status, validation, creative decisions, resolved `[TODO]` items and next task; synchronize the Godot copy once it exists. Keep factual inventory current rather than accumulating contradictory “done” claims.

### Verification commands and acceptance evidence

Existing web package commands from the repository root:

```bash
pnpm --filter @workspace/sound-clash run dev
pnpm --filter @workspace/sound-clash run test
pnpm --filter @workspace/sound-clash run typecheck
pnpm --filter @workspace/sound-clash run build
```

Workspace checks, when relevant: `pnpm run typecheck` and `pnpm run build`. Use the existing pnpm lockfile and required Node version; the tests use Node's TypeScript stripping. Do not run database schema-push commands for fighter work.

For gameplay changes: meaningful regression checks for attacks/guard/combos/trades, round/KO/rematch, fixed-seed replay and latency/beat cases; then a short playable check on the actual target device. Test reports must identify branch/commit and actual results. Documentation-only changes require Markdown/path/status review, not fabricated runtime tests.

For Godot, once created: [TODO] pin exact import/headless launch/test/export commands and local prerequisites. At minimum verify scene/resource parsing, imports, missing-resource errors, one-fighter parity, input/beat latency, audio restart/pause, and frame-rate-independent simulation. Port critical TypeScript regression cases before expanding content.

### Milestone ledger and next handoff

| Milestone | Status / next action |
| --- | --- |
| TypeScript combat and match prototype | Existing; reconcile accepted hardened branch before freezing reference. |
| Feedback pose pack | Available on named asset branches; verify/import without replacing main blindly. |
| Targeted PASS B comparison | Saved at `993d7bf`; unapproved. Leg identity/phase and full-loop continuity are next. |
| Basic three-hit rhythm combo reference | Combat chain exists; authoritative music beat judgement/demo `[TODO]`. |
| Master Godot blueprint | This root file, 2026-11-13. Documentation milestone only. |
| Godot setup and parity port | Planned after Fighter #1 reference gate; Claude leads, Freebuff builds locally. |
| Fighter #2, stages, party FSM and full interference | Backlog after Godot parity. |

Next agent: finish the isolated walk review, reconcile asset/engine branches, close the minimal rhythm reference gap, and freeze the TypeScript baseline. Keep costs at zero and scope narrow. Do not start crowd systems or additional fighters ahead of that gate.

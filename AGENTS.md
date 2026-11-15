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

### Owner clarification — cross-animation consistency (2026-11-13)

Garfield is the visual lead and final visual approver. The same slim Feedback, fitted trousers, Clarks Wallabee construction/size, hat/hair, face concealment, one gold tooth, microphone and cable setup must carry through idle, walking, attacks, defence, hit reactions, falling and KO. Approving a movement rhythm does not approve appearance drift or automatically approve other frames.

**Cable origin: inside the jacket.** This owner instruction supersedes earlier pocket-origin concept descriptions for the current continuity pass. Maintain a connected route from the microphone, through any established forearm wrap, into the jacket; an entry can be occluded by clothing, but it must be spatially plausible. No dangling disconnected plug, unexplained endpoint, duplicated cable, hand switch, disappearing mic, or topology change when walking transitions into attacks/guard/falling. Retraction and slack must follow the same setup. Do not treat the current dangling-connector walking candidate as final. Cross-set anatomical mic handedness still needs reconciliation against the approved source pack; do not solve this by silently mirroring art.

**Idle cable approval — November 13, 2026:** Garfield approved `cable-candidates/01_idle-jacket-entry-v1.png`, preferring its clean concealed treatment over v2's more explicit visible route. The source remains inside the jacket, but the cord does not need to visibly show where it goes unless the action requires it. Do not add exposed cable merely to demonstrate topology. Use v1, not v2, as the approved idle-cable reference; this does not approve every other character detail or pose. Keep original files and both candidates. Next narrow batch: cable-only candidates for 08_block and 12_backhand_windup/13_box_palm/14_followthrough, then review against v1 before propagation. Preserve mic hand, pose, clothing, shoes and anchors; record existing hand/design failures separately rather than silently fixing them in the cable pass.

**BOX cable approval — November 13, 2026:** Garfield approved `12_backhand_windup-cable-v2.png` with the lead entering the sleeve and `14_followthrough-cable-v2.png` with the return around the arm. This approves those cable treatments only; existing cross-pose handedness and character-detail issues remain separate. Do not replace these approved routes with the earlier open-air cut endpoints.

**Optional BOX leg-lift concept — November 13, 2026:** Owner proposed borrowing the right-knee lift/weight transfer of a left-handed pitcher, not the actual baseball throwing-arm motion, to heighten the BOX windup and follow-through. Test one isolated pose first (right knee raised, left support foot planted), preserving the established mic/cord and attack identity. Do not overwrite the current windup, change combat timing or add a full sequence automatically. This is a candidate idea, not an approved replacement or committed launch-scope expansion.

**Clarks: match approved artwork, not a new shoe design.** Tan suede Wallabees must retain their approved moccasin/apron seam, toe shape, lacing, crepe sole, size and proportions through all poses. An isolated improved shoe redraw is only a candidate until compared with the existing pack. Do not bulk-regenerate the approved pose pack or replace files to match an unapproved new candidate.

**Preserve work and audit before replacement.** The existing 17-pose asset pack was re-located on `assets/feedback-transparent-poses`; manifest and README inspected, not a fresh full pixel audit. Its README explicitly says the cable is baked into poses and acknowledges detail drift. Imported assets are recoverable/versioned, but this does not make correction automatic or free of rework. Keep originals and anchors, make a comparison inventory by pose, and apply only necessary local repairs. Recheck idle → walk → BOX windup/contact/recovery → guard → hurt/landing/KO as transitions, not only isolated illustrations.

**Current walk approval:** owner approved the four-pose swing–bop movement reference at approximately 132 BPM with the rear free-arm swing. Added neutral-arm return pose was rejected for limp-looking arm and rushed timing. Appearance consistency remains open: cable origin/continuity, unified slim proportions, Wallabee matching and exactly one gold tooth. Recent generated tooth edits still show excess gold and are not approved. Review videos/candidates created in this chat have not been transferred into this repository by this update. No runtime or asset correction is claimed.

## 2. Target Milestone & Production Roadmap (Goal: April 21, 2027 Launch / May Jamaica Trip)

### Commitment and release target

**Target launch: April 21, 2027 — Garfield's birthday launch, ahead of the May 2027 trip to Jamaica.** Minimum commitment: **10 hours/week**, planned as **~225+ total hours over ~22.5 weeks**. Deliver **6 playable DJ selectors**; **8 fighters is a stretch goal**, never a reason to destabilize the six-fighter build or move the target date. This commitment supersedes earlier weekly-hour/countdown assumptions.

Calendar clarification: November 13, 2026 to April 21, 2027 is 159 days (~22.7 weeks), or roughly 227 hours at 10 hours/week. The owner's date ranges below are authoritative; the final “Weeks 21–22” block is actually 20 days and includes the closing partial week. Keep the requested phase labels, but schedule against the explicit dates. These are capacity estimates, not completed hours or a guaranteed effort estimate.

| Phase | Dates | Planned work | Exit evidence |
| --- | --- | --- | --- |
| **Weeks 1–2** | **Nov 13 – Nov 26, 2026** | Lock `AGENTS.md`; finish Fighter #1's basic TypeScript 3-hit rhythm combo; install Godot, set up `.gitignore`, and port Fighter #1. Claude joins as soon as the TypeScript reference is wrapped, including during this phase. | Pinned web reference; Godot opens/imports cleanly; Feedback moves, jumps, guards and demonstrates the combo in the port. Record remaining parity gaps explicitly. |
| **Weeks 3–6** | **Nov 27 – Dec 24, 2026** | Claude leads the GDScript FSM, visual hitboxes/hurtboxes, rhythm beat-sync window, risk/reward taunts, four-stage party crowd loop and crowd interference: bottles, folding chairs, fire extinguisher. | One small playable systems slice with working beat judgement, all four party phases, and minimal versions of all three hazards. Use simple crowd/art placeholders to keep scope feasible. |
| **Weeks 7–9** | **Dec 25, 2026 – Jan 14, 2027** | Stabilize Fighter #1 as the reusable `BaseFighter`; build Fighter #2 from shared logic; add basic CPU AI and Crowd Hype / Dubplate meters. | Playable two-fighter demo; shared code confirmed; AI can complete rounds; meters have visible, documented rules. **Core mechanics lock: Jan 14.** |
| **Weeks 10–17** | **Jan 15 – Mar 11, 2027** | Roster assembly line: ~two weeks each for Fighters #3–#6, using Flow animations/exports, unique Dancehall stances, special moves and Patois voice lines. | Four additional approved playable selectors, each integrated and checked through the same content pipeline. No copied movement/rhythm systems. |
| **Weeks 18–20** | **Mar 12 – Apr 1, 2027** | Build 2–3 distinct Sound Clash venues, Character Select and Arcade mode. Add stretch Fighters #7–#8 only if genuinely ahead. | Six-fighter roster selectable; Arcade run completes and restarts; venues work with hazards/party transitions. Stretch scope cannot consume final QA time. |
| **Weeks 21–22 / closing partial week** | **Apr 2 – Apr 21, 2027** | Final balance, audio mixing, input/beat responsiveness checks, regression fixes, clean export and birthday launch. | Versioned release build tested on the chosen target; no critical blocker; credits/controls included; reproducible export instructions. |

Roster slots: #1 Feedback; #2–#6 **[TODO]** assign final names/order. Lickshot and Sky Juice remain candidate concepts; do not silently assign them slots or finalize their designs. #7–#8 remain optional.

Suggested content slots within the supplied eight-week roster block: #3 Jan 15–28; #4 Jan 29–Feb 11; #5 Feb 12–25; #6 Feb 26–Mar 11. Each slot covers stance/move definition, approved exports, data/hitboxes, voices, integration and a playable check. Templates and placeholders should be prepared before the slot, not used to claim finished art.

### Production rules that protect the date

- Establish the `BaseFighter` skeleton **during the first port**; Weeks 7–9 harden it and validate reuse with Fighter #2. Do not build throwaway fighter-specific movement/rhythm code and refactor it only in January.
- Freeze shared core mechanics by **January 14, 2027**. After that, fix defects and tune existing data; defer new universal systems unless essential to release. Content variation belongs in fighter resources and animations.
- The Weeks 3–6 systems list is ambitious within ~40 minimum hours. Build the smallest complete versions, not production crowds/cinematics. Flag any slip promptly with remaining work and hours; the roadmap is a target, not proof that work fits.
- At each session/milestone, record estimated versus observed time, completed exit criteria, remaining hours and the next date gate. Track useful debugging as development; distinguish avoidable tool/setup churn. Never subtract unverifiable hours or count the same session twice. Maintain the ledger without requiring manual data entry when activity is visible; ask only for missing session duration.
- Protect April 2–21 for stabilization. If behind, remove #7–#8 first, target two venues within the 2–3 range, and defer elaborate cinematics/extra polish. If six complete fighters or another committed feature is still at risk, present the concrete tradeoff to Garfield; do not silently reduce the six-fighter target, mislabel unfinished content, or move the date.
- **[TODO]** Pin launch platform(s), distribution location, minimum target hardware, export format and release acceptance checklist during Weeks 1–2. The Chromebook/phone workflow needs a verified zero-cost way to run and export Godot; do not assume desktop/mobile/web parity.
- **[TODO]** Record exact May trip dates if they affect post-launch availability. No travel dates beyond May 2027 are established here.
- **[TODO]** Define the minimum unique move/animation/voice set per selector and confirm free Flow allowance/export throughput before promising six fully animated rosters. Batch approved outputs; generation failure must not consume unbounded time or credits.

## 3. Multi-Agent Team & Zero-Cost Workflow

| Role/tool | Responsibility | Handoff boundary |
| --- | --- | --- |
| **ChatGPT (Creative Director & Reference Analyst)** | Organize design, analyze visual inspiration/references, maintain this blueprint and the Patois/comedy lexicon, review visual continuity. | Supply concrete references, acceptance criteria, and honest approval status. Garfield retains final creative approval. |
| **Freebuff (Local Repo Builder & Heavy Lifter)** | Work directly in the local GitHub folder; write scripts, wire up exported Flow animations, organize/verify files, run checks, and handle commits. | Inspect the actual branch and files first; preserve combat work and source art. Wiring exports is not permission to spend animation credits. |
| **Claude (Lead Systems & Godot Architect)** | Join immediately after Fighter #1's basic TypeScript prototype is wrapped up. Lead the Godot migration, translate the TypeScript FSM behavior into GDScript, and architect the reusable `BaseFighter` template, multi-fighter systems and crowd interference. | Port the accepted reference behavior before expanding the game. This is the intended team assignment, not a claim that Claude is already connected or has completed work. |
| **Flow** | Character animation testing, visual sequence ideation and batching sprite exports. | Outputs are candidates until checked. Flow does not define combat timing, collision truth, or final voice lines. |
| **Spriteriffic (2D Sprite & Sheet Artist)** | Generates and formats game-ready character sprite sheets, Dancehall combat frames, background crowd animations, and hazard sprites—including bottles, chairs and fire extinguishers—with consistent grid framing for direct import into Godot’s `AnimatedSprite2D` nodes. Paired with **Flow** for motion testing. | Garfield approves visual consistency. Freebuff verifies sheet dimensions, transparency, frame order and import behavior before integration. Outputs remain candidates until reviewed. |

### Spriterrific role clarification — November 13, 2026

Spriterrific was omitted from the initial team table, not deliberately rejected. Retain it alongside manual keyframes and Flow as a candidate source of animation frames. Proposed workflow: approved Feedback appearance reference → one short animation test → visual consistency review → Freebuff preparation/testing → playable integration. This does not establish support for arbitrary in-between frames, per-part controls, rigging, blending or transparency.

Finish the current appearance/cable review first. Then choose one bounded walk or attack test with the owner and verify current input/export capabilities before generation. Preserve the approved slim proportions, Wallabees, one gold tooth, mic hand and jacket-origin cable. No generation, purchases or credit spending are authorized by this documentation update. Spriterrific supplies candidate visuals; Freebuff implements/tests; Godot runs the game. Keep the April 21 target and existing work intact.

### Zero-cost operating rules

1. No new spending: use Godot, local Git, existing assets, free tools, and available free allowances. AI assistants, Flow, Codespaces, hosting, and storage are not inherently unlimited/free. If an allowance is exhausted, continue with local scripts/placeholders and queued work; do not purchase credits, upgrade plans, or enable billable services automatically.
2. GitHub is the shared production record. Prefer direct repository delivery for Freebuff; do not make Garfield repeatedly download and re-upload assets that are already accessible.
3. One owner per task and one clear branch/commit handoff. Specialist work can be split when the active task authorizes delegation. Avoid simultaneous edits to the same file and avoid multiple agents rebuilding the same system.
4. Each handoff states repository, branch, commit, changed paths, what works, checks actually run, approval status, and next blocker. Never say an upload, build, or integration succeeded without evidence.
5. Log design, reference analysis, art preparation, animation review, coding, and testing as Sound Clash development time. [TODO] Maintain a consolidated session-hours ledger; do not invent totals or promise a fixed percentage reduction.
6. Make narrow, reviewable changes. Preserve originals; keep rejected art and candidates distinguishable from approved production assets.

## 4. Current TypeScript Prototype & Asset Inventory

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


### Appearance audit checkpoint — November 13, 2026

All 17 aligned PNGs on `assets/feedback-transparent-poses` were retrieved, decoded and inspected in a comparison sheet; idle, block, BOX startup/contact/recovery and KO received enlarged inspection. Multiple stored poses have floor-trailing cables that conflict with the owner’s jacket-origin requirement. This is not only a walk issue. No original PNGs or runtime files changed. See `artifacts/sound-clash/art-source/feedback/APPEARANCE-CONSISTENCY-AUDIT-2026-11-13.md` for evidence, open checks and Freebuff’s next task. Build the appearance comparison before further broad generation or integration. The stored idle is a proposed working appearance reference; owner approval remains required for any replacement art.

### Interference and audio inventory gaps

The owner identifies bottles, chairs, fire extinguishers and Flow sprite/audio exports as migration inventory. No matching bottle/chair/extinguisher directories or finished soundtrack/voice asset tree was found on inspected Lab `main`, pose, animation-refinement, sprite-pipeline or combat-hardening snapshots. **[TODO] Freebuff locates any local/unmerged files and records exact paths, filenames, status and source before copying.** Do not claim missing files exist or replace them with silently invented assets.

Historical reports include 98 and later 109 passing tests plus typecheck/build success. These apply to their historical branches/runs. [TODO] Run and record the current selected baseline checks; no fresh test run is certified by this documentation milestone.

## 5. Godot Engine Migration & Repo Setup Strategy

### Why Godot

Godot is 100% free/open-source under the MIT license, with no engine license fee or royalty. Its plain-text `.gd` scripts, `.tscn` scenes, `.tres` resources and `project.godot` work well with GitHub and local agent edits. Git works externally without an editor plugin; Git inside the editor uses a plugin.

Reusable `BaseFighter` scenes, visual collision-shape placement over Flow-derived sprites, animation tools, Camera2D plus small shake/impact scripts, and scene composition should cut repetitive work versus a fully manual pipeline. **Beating the earlier 190-hour manual estimate is a goal, not a validated schedule or guarantee.** [TODO] Re-estimate after the first Godot parity slice. Godot does not repair bad source animation or synchronize gameplay to music automatically.

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
2. **Copy this `AGENTS.md` and the organized sprite/audio folders directly into the Godot project directory**, including **Spriteriffic sprite sheets**, located bottles, chairs, fire extinguishers and Flow exports, so Freebuff and Claude see them immediately. Preserve approved originals, filenames, anchors, licensing/source notes and manifests. Verify copies by count/hash. Missing assets remain `[TODO]`; do not copy broken candidate files as approved art.
3. Keep repository-root `AGENTS.md` authoritative. The `/godot/AGENTS.md` copy must match it after milestones; do not create conflicting nested instructions.
4. Commit `project.godot`, source scenes/scripts/resources and required Godot metadata; exclude generated cache, temporary renders and exported builds. Inspect `git status` before committing. No nested Git repository inside `/godot`.
5. Retain the TypeScript prototype as a runnable reference throughout the port. This request creates the blueprint; it does **not** start the engine migration now.

Proposed layout, **not yet created**: `godot/project.godot`; `godot/AGENTS.md`; `godot/scenes/fighters/BaseFighter.tscn`; `godot/scenes/match/`; `godot/scenes/hazards/ThrowableHazard.tscn`; `godot/scripts/{combat,fsm,rhythm,crowd}/`; `godot/data/{fighters,moves,hazards}/`; `godot/assets/{sprites,audio,flow_exports}/`. Under sprites, organize `feedback/`, `bottles/`, `chairs/`, `fire_extinguishers/`. [TODO] Final paths after inventory and actual engine setup.

## 6. Finite State Machine (FSM) Architecture (TypeScript -> GDScript Blueprint)

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
| `GameScene` / pose renderer | Reusable `BaseFighter.tscn` with Sprite2D/AnimatedSprite2D or AnimationPlayer, separate hurt/hit/push boxes and debug visualization. |
| Game events | Signals/event queue for UI, audio, sparks, camera shake and crowd reactions; presentation never changes collision outcomes. |
| Match snapshot / React overlays | Match controller plus Control/CanvasLayer HUD and results UI. |
| Web Audio tones | AudioStreamPlayer/SFX adapter; approved local audio assets later. |

Use one common `BaseFighter` scene plus fighter-specific data/assets, not copied combat scripts for each character. Visual hitbox tools author data; the simulation owns when it is active. Do not let variable render FPS, animation callbacks, camera shake, or Godot physics callback order decide who hits first. Ordinary Godot physics is not automatically bit-for-bit deterministic across platforms.

**Beat service:** provide BPM/offset, nearest-beat error, judgement window and latency calibration. Timestamp inputs against the audio clock and pass recorded judgement/input data into the combat tick; keep rendering separate. [TODO] Decide whether the beat window judges input time, active-frame contact, or both; define on-beat reward/off-beat behavior and hitstop/music behavior. No guessed BPM or invented timing windows. Do not drive a long song with a drifting visual timer.

Replay parity must preserve seeded RNG explicitly; Godot's default RNG is not a drop-in replacement for the current seeded algorithm. [TODO] Port the algorithm with matching unsigned behavior or document a deliberate replay-version break. Test same inputs/seed and mirrored fighter-order scenarios.

## 7. Crowd Interference & Party Mechanics

**Planned after Godot fighter parity.** Shared `ThrowableHazard` design: one reusable scene/controller with type-specific data, not three unrelated systems.

| Hazard | Motion/impact personality | Planned consequence |
| --- | --- | --- |
| Bottle | Fast throw; quick shatter | Brief hit response and shatter visual/audio; [TODO] damage and whether fragments are cosmetic. |
| Folding chair | Heavy readable arc; metallic clang | Strong impact/knockdown; [TODO] trajectory, telegraph and recovery values. |
| Fire extinguisher | Canister throw/activation; foam burst | Foam cloud and slip hazard; [TODO] cloud duration, area, movement effect and cleanup. |

Proposed shared fields: hazard ID/type, source crowd member, target/aim, spawn tick, position/velocity/gravity, collision mask, hitbox, damage/knockback, lifetime, impact effect/audio, remaining hit count and spawned floor-effect data. States: queued/telegraphed → airborne → impact → spent; extinguisher may create a separate timed floor area. Keep arcs and contacts in the authoritative simulation if they affect combat; use scene visuals for presentation.

Crowd hype or successful beat-synced taunts enqueue throws through a crowd director. Use seeded choices, bounded frequency, readable warnings and recorded events. Crowd hostility may arise for no good or fair reason, independently of skill or performance; bias and unpredictable dislike are part of the intended feel. One bottle may trigger a cascade of more bottles. Do not require every throw to be earned by hype or a taunt. Telegraphing, frequency limits and avoidance rules are implementation proposals to tune in playtesting, not settled restrictions on the cultural concept. [TODO] Hype thresholds, target bias, cooldowns, simultaneous hazard cap, player avoidance/blocking rules, and exact taunt risk/reward. No spawn during intro/transition/KO unless explicitly authored as harmless presentation.

Keep crowd visuals, navigation, hype calculation, throw scheduling and hazard resolution modular. Clean hazards/foam at round reset and stop new gameplay hits when the round ends. First prototype one bottle and one readable warning before adding the chair/extinguisher. Future bar/speaker/car interactions remain backlog.

**Music interruption gag:** Lickshot steals the playing record and the tune stops. [TODO] Define beat-clock pause/rebase/new-track policy before making this affect rhythm judgement; continue deliberate combat/SFX behavior during the gap. A gag must not accidentally desynchronize input timing.

### Additional owner-requested interference objects — November 13, 2026

The owner added a **crate of records** and a **big pot of `Cawn soup` (corn soup)** as objects thrown for crowd interference. These are distinct additions to the interference backlog; they are not implemented assets or new mandatory work in the initial bottle/chair/extinguisher slice. Keep the April 21 target unchanged. The throwable crate is separate from Lickshot's existing record/crate-stealing gag, although they may share an eventual prop design. [TODO] Define visual design, trajectory, impact, contents/reaction, cleanup and gameplay effects with the owner; do not invent damage, stun or spill/slip rules as settled decisions.

### Crowd Hype / Dubplate meters — planned two-fighter demo scope

Use shared match/fighter data and HUD bindings; no per-fighter copies of meter code. Crowd Hype represents crowd response and can influence taunt rewards and interference scheduling, while preserving independent biased hostility. The Dubplate meter is a requested mechanic whose gameplay meaning is not yet specified. **[TODO]** Define whether it is per-fighter or shared, gain/spend rules, maximum, persistence across rounds, special-move relationship, HUD feedback and reset behavior. Do not invent a super-move economy as settled design. Wire and document both meters for the Dec 25–Jan 14 demo gate.

## 8. Authentic Patois & Comedy Lexicon

**STRICT RULE FOR ALL AGENTS: Preserve all Patois spellings, slang, capitalization variants and comedic phrasing verbatim. Never rewrite or “correct” them into standard English.** English glosses belong in a separate field. These spellings encode pronunciation and comic timing. The owner reiterated that phonetic spelling is pronunciation help; keep the English meaning separate rather than correcting the spoken spelling. Do not silently merge variants, substitute a dictionary spelling, invent a translation, or turn an assistant suggestion into an owner-approved line.

This register includes all phrases recoverable from the visible conversation, supplied project history and retrieved project notes. [TODO] Audit older unavailable conversations/voice notes for additional entries; completeness beyond accessible records is not certified. `[TODO]` means the owner's exact gloss or intended usage still needs recovery.

### Owner-taught phrases, pronunciation and cultural context

| Exact phrase / recorded variant | Meaning / cultural note |
| --- | --- |
| `Yuh too Bod Mine!!` | Owner's gloss: “You're to Bad Mind”; intended meaning: “you're evil.” Preserve the phonetic spelling. Trigger/performance not yet specified. |
| `Yuh Betta stop-pit` | You better stop it. Owner-supplied wording; preserve exact spelling and capitalization. |
| `Cawn soup` | Corn soup. Owner's spelling guides pronunciation; retain it in performance notes/dialogue. A big pot is also a proposed crowd-interference throwable. |
| `Outta Awduh` | Out of Order. |
| `Klawk ah Strike` | Clock is striking. [TODO] Exact game trigger. |
| `Wah mi seh` | What did I say? |
| `Ghett Tup` | Get up. |
| `Stop-pit!` | Stop it. |
| `Yam dat` | Eat that. |
| `Hole Lawn deh` | Hold on there. |
| `Shut-Tup!` | Shut Up! Owner's favourite phrase to sprinkle throughout: flexible recurring crowd/announcer/fighter interjection, without overusing it. |
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
| `Mash` | Written form with owner-directed spoken pronunciation `Mosh`; do not confuse spelling with performance. |
| `Mash up him geometry!` | Perform as `Mosh up him geometry!`; exaggerated combat callout. |
| `Mosh up him geometry!` | Owner's phonetic performance direction for the preceding line. |
| `Stay one place!` | Stay in one place; owner specifies pronunciation `Stay wun place!`. |
| `Stay wun place!` | Exact phonetic direction for `Stay one place!`; fighter taunt/callout. |
| `Keep still!` | Owner-supplied taunt/callout; original message also records `keep Still!`. Preserve context-specific capitalization. |
| `LEAD OUT!` | Take charge, step forward, dominate, act as leader; potential momentum callout. [TODO] Confirm pronunciation. |
| `Cum mout ta mi vishaun` | Come out of my vision. |
| `Gweh!` | Go away! |
| `Tump` / `TUMP` | Hard fist punch/strike; heavy body-shot vocabulary. Preserve variants by context. |
| `BOX` | Jamaican box/slap language; project heavy backhand/open-hand head strike, not a fist punch. |
| `Upper Box` | Rising backhand/open-hand slap, not a fist uppercut. Standalone causes head snap/stumble without automatic knockdown; Three Piece finisher launches. |
| `Butt weight` | But wait; surprise when something did not happen as expected. Owner's example: promised chocolate bar, returned with rotisserie chicken. |
| `Cum Again` | Abbreviated from “wheel and cum again”: rewind/spin the tune back and start over. |
| `wheel and cum again` | Recorded cultural explanation; preserve wording/case in its original context. |
| `Beg You Won Stop Drivuh` | Next stop, driver, please. Comedic dizzy/disoriented reaction after a hit; candidate voice line, not implemented. |
| `Beg You Won Stop` | Ground-hand/pleading gag variant; [TODO] Exact owner gloss. |
| `See it Deh` | See it there. Candidate fighter/announcer reaction. |
| `Woy!` | Whoa! Exclamation of hurt, surprise or shock; preserve all meanings. |
| `Give Tanks` | Give Thanks / You're lucky. Taunt or reaction according to context. |
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

- **`cricket box`**: owner-proposed name for a cricket-bowling-inspired BOX/slap, potentially for another character. No fighter assigned; concept/backlog only, not an implemented move or added launch requirement. Preserve the owner's name. Keep separate from Feedback's current BOX direction: original rear three-quarter camera, right-knee lift, plant/turn into the existing slap/follow-through. The earlier raised-knee illustration changed the camera/build and is not approved production art.

- `Rum Punch`: candidate fighter name, powerful move/hit name, or both; Caribbean punch/fighting wordplay. Keep options open, not finalized.
- Later Three Piece polish: launched opponent lands comically on their head (stylized, non-graphic), with hard landing/dust/shake; defer until the working baseline is stable.
- Mr. Bean versus Mike Tyson reference backlog: exaggerated recoil/stagger, humorous personality contrast and venue knockdowns such as stumbling into a speaker stack. Not immediate implementation.
- UI feedback: avoid oversized `ROUND OVER` lettering; it was called out as too huge/weird. Preserve readable, restrained overlays.
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

## 9. Coding & Project Guardrails

### Mandatory behavior

1. Read this file at task start; inspect repository/branch/current code before editing. Preserve the distinction between Lab and original development repo, and between `main`, combat-hardening and asset branches.
2. Build one reusable `BaseFighter` scene with shared movement, rhythm, input/combat rules and FSM code. Fighter-specific data/resources/animations provide variety; duplication means instancing/inheriting the template, never copying the systems. **Lock core mechanics by Jan 14, 2027** so Jan 15–Mar 11 is content assembly. Keep scripts modular: input, combat rules, FSM, fighter data, beat service, renderer, audio, crowd director, hazards and UI have clear ownership. Avoid a single all-purpose scene script or fighter-specific copies of shared combat.
3. Never break core movement feel, input buffering, beat-sync responsiveness, directional guard, simultaneous contact rules or grounded KO presentation to simplify a port. Match behavior first; rebalance only as an explicit change.
4. Do not confuse combat active windows with rhythm windows, pose origins with hitboxes, screen-left with anatomical left, imported poses with animation, or save approval with creative approval.
5. Preserve verbatim Patois. Append new owner phrases with exact spelling, separate gloss/context, source and approval status. Keep rejected lines and assistant suggestions distinguishable.
6. Validate art at full size and gameplay size: one mic, correct declared hand, continuous cable, consistent face concealment/gold tooth/hair/hat/build/clothing/boots; no extra digits, trapped backgrounds, broken transparency, or cut-off PNG rows. Check anchors, foot contact, leg identity, walk phase and animation seam. Never hide an error with per-frame scale changes or mark uncertain details passed.
7. Keep original sources immutable where practical; put comparison splices, redraws and generated candidates in clearly labeled locations. Do not overwrite approved assets as a side effect of running an extractor.
8. No paid dependencies/services or automatic credit spending. No speculative multiplayer/backend expansion before the local fighter and Godot parity gate. Keep large temporary exports/caches out of Git; avoid duplicate binary/base64 transfer packs when normal local Git can carry verified bytes.
9. Use small commits with concrete messages. No force-push, destructive history rewrite, deletion of old prototypes, or broad branch merging as routine cleanup. Reconcile upstream changes before writing; preserve unrelated work.
10. **Update `AGENTS.md` after every completed milestone.** Record date, commit/path, status, validation, creative decisions, resolved `[TODO]` items and next task; synchronize the Godot copy once it exists. Keep factual inventory current rather than accumulating contradictory “done” claims.

11. **Keep Spriteriffic sprite sheet grid dimensions consistent across all fighters for fast Godot slicing.** Use a shared cell width/height, consistent margins and spacing, and documented row/column layouts. Preserve each fighter’s intended proportions and frame anchors within that grid. Record frame order and animation timing for import into `AnimatedSprite2D`/`SpriteFrames`; do not stretch characters to fit cells.

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
| Master Godot blueprint | Initial root document at `259833b`; expanded 2026-11-13 with nine sections, launch roadmap and recovered lexicon. Documentation milestone only. |
| Godot setup and parity port | Planned after Fighter #1 reference gate; Claude leads, Freebuff builds locally. |
| Party FSM, taunts, beat window and hazard slice | Scheduled Nov 27–Dec 24 after initial Godot port; prototype scope first. |
| Reusable BaseFighter / two-fighter demo / meters | Due Jan 14, 2027; core mechanics lock. |
| Fighters #3–#6 | Scheduled Jan 15–Mar 11; two weeks each. |
| Venues, Character Select and Arcade | Scheduled Mar 12–Apr 1; stretch #7–#8 only if ahead. |
| Birthday release / May Jamaica trip | Launch target Apr 21, 2027; final QA Apr 2–21; trip May 2027. |

Next agent: finish the isolated walk review, reconcile asset/engine branches, close the minimal rhythm reference gap, freeze the TypeScript baseline and complete the first Godot port inside Nov 13–26. Then follow Section 2 date gates. Keep costs at zero; preserve the April 21, 2027 target and six-selector commitment while reporting scope risks promptly.


### Newer knee-lift BOX in main handoff — November 14, 2026 (Toronto)

Garfield requested Feedback’s newer foot-off-the-ground BOX enter the GitHub flow. Root `FREEBUFF-HANDOFF.md` and ten exact source/reference media blobs from review commit `9eaeae74144e8a453034aa3ff2cf33014dd63511` are now delivered on main under `artifacts/sound-clash/art-source/feedback/box-handoff-2026-11-13/`. Selected movement: LEFT lean comparison, knee lift → stride → planted windup → BOX → follow-through. Freebuff owns corrections, preparation, verification and integration; return a preview for Garfield. First/last-frame appearance, mic-hand and cable continuity remain open; latest two-loop clip is UNAPPROVED. Verified repository source paths and exact blob reuse; no runtime change or gameplay tests. No broad merge of the review branch. Next: Freebuff fetches main and follows the root handoff while preserving local work.


### Additional Feedback animation requests — November 14, 2026 (Toronto)

Garfield requested `lightah` frames, skank frames, reverse back hand BOX, and a Sparta kick to the stomach, all with the same Feedback character. See `FREEBUFF-HANDOFF.md` → Additional Feedback frame requests for preparation/continuity criteria. Freebuff inventories/reuses existing sources, prepares missing candidate frames and returns previews. Preserve character identity, declared mic hand, continuous jacket-origin cable, Wallabees, frame anchors and shared grid. Reverse BOX stays distinct from Upper Box; do not mirror art to create it. Kick gameplay parameters are unspecified. Status: recorded request only, no new frames or runtime implementation; no gameplay tests applicable. Existing knee-lift BOX handoff remains active.


### Five-move review studies created — November 14, 2026 (Toronto)

Owner assigned ChatGPT creation and added a microphone `squeeeek` defence. Five six-keyframe animated studies now exist: Lightah, skank, reverse backhand BOX, Sparta stomach push kick, and mic-squeak guard. Root `FREEBUFF-HANDOFF.md` at `187c284` records exact owner-access video/player/source-pack links, reference identity, checks and limitations. Status: UNAPPROVED review previews, not smooth final animations or gameplay assets. H.264/AAC export and player syntax verified; no runtime tests. Same right-hand mic setup across this batch; cross-pack canonical hand remains open. Next: Garfield reviews, ChatGPT corrects art/motion and prepares in-betweens; Freebuff handles approved repo preparation/integration. No receipt or implementation by Freebuff is claimed.


### Owner move corrections — November 15, 2026 (Toronto)

Lightah must use existing massive-flame reference and jump-skank; reverse backhand BOX means spinning around into an open-hand backhand, superseding the stationary v1 interpretation. Garfield likes the Sparta kick direction; keep its drawings. Rear-facing two-finger skank original recovered for Freebuff (`libfile_95d3f14281248191821f8825ae8ef570`); preserve original but do not propagate obsolete back pockets/floor cable. Same Feedback appearance and mic/cable continuity mandatory. Root `FREEBUFF-HANDOFF.md` details source identities, screenshot identification and v2 status. V2 Lightah/spinning BOX are new six-keyframe review studies, not final approved animations; other three studies unchanged. No gameplay changes or runtime tests. Next: owner reviews v2, then targeted continuity fixes/in-betweens and Freebuff preparation.

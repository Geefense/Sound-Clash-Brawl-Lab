# Sound Clash Brawl — Master Blueprint

Last updated: 2026-11-16. Owner and final creative approver: Garfield Connell.

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

**Other concepts:** **Lickshot is now Fighter #2's display name** (renamed from Dubplate, 2026-11-17 — §9 item 26); `Disc Jock Lickshot` and `Booyaka Lickshot` stay recorded alternates and the owner says the name may still evolve. The off-screen selecta record-theft gag belongs to Fighter #2 accordingly. The Godot migration gate for Fighter #2 is passed — he is in the roster with his own four-pose set since 2026-11-17 (§9 item 27): mic stance, high kick, Sonic Clap windup and Sonic Clap impact. **Working name pool for Fighters #4–#6 (owner, 2026-11-17): Fling Stone, Rum Punch, Sky Juice** — working names only, with no slot assigned and no design implied (§2, §9 item 26).

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

Roster slots: #1 Feedback; #2 **Lickshot** (renamed from Dubplate on 2026-11-17, §9 item 26 — the name may still evolve); #3 Young Selecta (§9 items 22–25); #4–#6 **[TODO]** assign final names/order from the owner's working **name pool: Fling Stone, Rum Punch, Sky Juice** (2026-11-17). Those three are working names, not assignments: nothing says #4 is Fling Stone, and a name is not a design — do not build a fighter from a name alone or treat the pool as final. The owner named #1–#3 explicitly; #4–#6 remain open. #7–#8 remain optional.

Suggested content slots within the supplied eight-week roster block: #3 Jan 15–28; #4 Jan 29–Feb 11; #5 Feb 12–25; #6 Feb 26–Mar 11. Each slot covers stance/move definition, approved exports, data/hitboxes, voices, integration and a playable check. Templates and placeholders should be prepared before the slot, not used to claim finished art.

### Production rules that protect the date

- Establish the `BaseFighter` skeleton **during the first port**; Weeks 7–9 harden it and validate reuse with Fighter #2. Do not build throwaway fighter-specific movement/rhythm code and refactor it only in January.
- Freeze shared core mechanics by **January 14, 2027**. After that, fix defects and tune existing data; defer new universal systems unless essential to release. Content variation belongs in fighter resources and animations.
- The Weeks 3–6 systems list is ambitious within ~40 minimum hours. Build the smallest complete versions, not production crowds/cinematics. Flag any slip promptly with remaining work and hours; the roadmap is a target, not proof that work fits.
- At each session/milestone, record estimated versus observed time, completed exit criteria, remaining hours and the next date gate. Track useful debugging as development; distinguish avoidable tool/setup churn. Never subtract unverifiable hours or count the same session twice. Maintain the ledger without requiring manual data entry when activity is visible; ask only for missing session duration.
- Protect April 2–21 for stabilization. If behind, remove #7–#8 first, target two venues within the 2–3 range, and defer elaborate cinematics/extra polish. If six complete fighters or another committed feature is still at risk, present the concrete tradeoff to Garfield; do not silently reduce the six-fighter target, mislabel unfinished content, or move the date.
- **[TODO]** Pin launch platform(s), distribution location, minimum target hardware, export format and release acceptance checklist during Weeks 1–2. The Chromebook/phone workflow needs a verified zero-cost way to run and export Godot; do not assume desktop/mobile/web parity. *(Partly resolved 2026-11-15: the committed Web export in §9 item 16 builds headless and runs in a plain browser tab with no paid service — see its verification section for what is still unverified.)*
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

**Godot folder created — November 15, 2026.** `/godot` now exists with `project.godot` (minimal; `config/features` is added the first time the project is opened), `.gitignore` (`.godot/`, `*.translation`, exports, no art ignored), `.gitattributes`, a byte-identical `AGENTS.md` copy, empty `scenes/` and `scripts/`, and `assets/` holding the verified art copies: `sprites/feedback/aligned/` (17 pose PNGs + `feedback.poses.json`), `sprites/feedback/imported-poses/` (6 studies), `sprites/feedback/walk-four-keys/poses/` (4 keys, still an unapproved movement test) and `flow_exports/walk/` (walk flow test and the approved 132 BPM reference). All 30 copies verified byte-identical by `cmp`/SHA-256; candidate and comparison-only art was deliberately left in `art-source/`. Still **[TODO]**: no audio file exists anywhere in the repository, no Spriteriffic sprite sheets, and no bottle/chair/fire-extinguisher art — so `assets/sprites/{bottles,chairs,fire_extinguishers}/` and real audio content are not created yet. Engine version, renderer and Chromebook export path remain unpinned and unverified; no scene, script or gameplay rule exists in `/godot`.

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
| `Yuh too Bod Mine!!` | Owner's gloss: “You're to Bad Mind”; intended meaning: “you're evil.” Preserve the phonetic spelling. Trigger/performance not yet specified. **Approved as a playful, family-friendly comedic voice taunt (2026-11-15).** |
| `Yuh Betta stop-pit` | You better stop it. Owner-supplied wording; preserve exact spelling and capitalization. |
| `Cawn soup` | Corn soup. Owner's spelling guides pronunciation; retain it in performance notes/dialogue. A big pot is also a proposed crowd-interference throwable. |
| `Outta Awduh` | Out of Order. |
| `Klawk ah Strike` | Clock is striking. [TODO] Exact game trigger. |
| `Wah mi seh` | What did I say? |
| `Ghett Tup` | Get up. |
| `Stop-pit!` | Stop it. |
| `Yam dat` | Eat that. |
| `Hole Lawn deh` | Hold on there. |
| `Shut-Tup!` | Shut Up! Owner's favourite phrase to sprinkle throughout: flexible recurring crowd/announcer/fighter interjection, without overusing it. **Approved as a playful, family-friendly comedic voice taunt (2026-11-15).** |
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
| `Heeeyaut!` | Idiot. **Approved as a playful, family-friendly comedic voice taunt (2026-11-15).** |
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
| `LIGHTAH!` | Shouted form of the existing `Lighter!` request; one of the owner's family-friendly callouts (2026-11-15). |
| `FORWARD!` | Owner's family-friendly hype callout; the implemented 100 % Hype Surge banner (§9 item 10). |
| `WHEEL AND COME AGAIN!` | Shouted banner/voice form of the existing `wheel and cum again`. A separately recorded capitalization variant — do not normalise the two into one. |
| `BIG TUNE!` | Owner's family-friendly crowd/hype callout. [TODO] Trigger and delivery are unset. |
| `Feedbackhand` | Proposed backhand pun. |

### Comedy, taunt and move register

- **`cricket box`**: owner-proposed name for a cricket-bowling-inspired BOX/slap, potentially for another character. No fighter assigned; concept/backlog only, not an implemented move or added launch requirement. Preserve the owner's name. Keep separate from Feedback's current BOX direction: original rear three-quarter camera, right-knee lift, plant/turn into the existing slap/follow-through. The earlier raised-knee illustration changed the camera/build and is not approved production art.

- `Rum Punch`: candidate fighter name, powerful move/hit name, or both; Caribbean punch/fighting wordplay. Now one of the three names in the owner's working pool for Fighters #4–#6 alongside `Fling Stone` and `Sky Juice` (§2, §9 item 26). Keep options open, not finalized.
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

12. **Ask about reasoning effort before heavy multi-file work.** Before starting a multi-file combat state change, a physics refactor, or a new fighter integration that would benefit from Max reasoning effort, tell the owner **“Recommend switching to Max for this step”** first, so they can flip the reasoning-effort selector manually if needed.

### §9 Owner Decisions Log

Decisions the owner approved on 2026-11-16, recorded so the port stops re-litigating them. Nothing
here is gameplay-verified; implementation status is stated per item.

1. **On-beat reward policy — approved.** Judged on the attack *input* inside the judgement window:
   **+15 Crowd Hype** (0–100) and **1.15× damage**. Contact is judged separately. Hype is awarded
   only when the on-beat attack **connects** (hit or block), so mashing cannot farm it; the export
   flag `hype_requires_connect` flips it to award on trigger instead. The 1.15× applies to chip
   damage too, blocked hits still get hitstop, and a taunt that completes on-beat awards the same
   +15. [TODO] The ±70 ms window, both +15 amounts, taunt length and risk/reward rules remain
   placeholders; blocked chip multiplier and taunt amount are owner-visible defaults.
2. **Canonical mic hand — approved; display turnaround amended 2026-11-17.** The pack stays
   right-handed and its cross-set handedness is still [TODO]. A left-facing fighter still looks for
   `<anim>_left` first. **Changed by the 2026-11-17 playtest** (item 23): with no left-facing art the
   sprite is now mirrored at run time, because both fighters were drawn facing right while the CPU was
   logically facing left — the owner called that out as a fight-breaking defect. Mirroring stays
   provisional and presentation-only: it flips the *rendered* mic hand and cable, it never mirrors or
   rewrites a PNG, and a real `<anim>_left` sheet switches the mirror off automatically.
3. **Skank taunt — approved.** `State.TAUNT` plays the `skank` pose (`15_skank`) and an on-beat
   completion awards hype. This resolves the §5 taunt-animation TODO.
4. **Move keys as wired in the workshop arena:** J jab, K box, L tump, I upper box, T taunt,
   C crouch, guard on S/Down, move on WASD/arrows. `tump` and `upper_box` are runnable placeholders
   with no art and no ported frame data.

5. **Selected 512×512 frames adopted as working gameplay art — approved (2026-11-15).** The 20
   frames in `art-source/feedback/selected-frames-2026-11-15/` are copied unchanged into
   `godot/assets/sprites/feedback/selected-frames-2026-11-15/` and treated as their own animation
   group: every animation keeps its natural sole baseline (rows 488–494) through its own
   `ANIM_OFFSET` entry and renders at 0.257, which matches the pose pack's on-screen height without
   resampling the pixels. The 17-pose pack, the walk keys and everything in `art-source/` stay
   untouched. Wiring: `skank/01–05` replaces the single-frame taunt as a beat-timed loop (`06`
   duplicates `01` and is not animated); `mic-defence/01–02` is guard entry, `03–04` the held block
   and blockstun, `05–06` guard release; `sparta-kick/01–06` is the `tump` (L) sequence with the
   contact box at stomach height; `lightah/03–04` sit in `SpriteFrames` as a flagged prototype only.
   BOX (K) stays on poses 12/13/14 at that point, superseded by item 6 for its contact frame.
   [TODO] The 0.257 scale, the guard phase lengths (8/8 ticks),
   the tump timing (12/4/12), the 1.13 s taunt length, and the unclipped-lightah and separate-flame
   VFX work are all hand-set defaults awaiting a Godot playtest.

6. **Foot-off-ground BOX contact frame — approved and wired (2026-11-15).**
   `Feedback_Baseball_Pitch_BOX_Foot_Off_Ground.png` at the repository root (1024×1536; rear
   three-quarter view, right knee lifted, left support foot planted, microphone in the right hand) is
   copied byte-identically into `godot/assets/sprites/feedback/box-footoff-ground-2026-11-15/` and is
   now the `box_active` frame of BOX (K), between the `12_backhand_windup` startup and the
   `14_followthrough` recovery. It gets its own placement instead of being resampled: `ANIM_OFFSET`
   (479, −638) with `ANIM_SCALE` 0.1013, derived from a planted-sole row of 1406 in a 1536-tall canvas
   (`768 − 1406 = −638`) and a 1202 px crown-to-sole height, which renders 121.9 px against the pack
   idle's 121.75 px at 0.25. The x offset puts the planted foot at +37.4 px forward of the origin, the
   same screen position the pack's 12/13/14 feet already occupy (+34…+40 px), so the K sequence does
   not slide sideways. Pose `13_box_palm` stays in the pack untouched but is no longer animated. The
   Baseball-pitch lean comparison video stays at the repository root as a reference only: it was not
   decoded here (no ffmpeg available) and no gameplay decision rests on it. [TODO] The BOX contact
   rectangle is still the old 108×54 at x 96; the new frame's raised-palm silhouette has no forward
   extension, so its reach is unverified and needs a playtest.

7. **Sound Clash Sand Stage direction — approved (2026-11-15).** The owner's 1672 × 941 beach
   sound-yard background (uploaded to the repository root as
   `3DFAD58B-2779-4DA7-B37E-9CF15C480341.png`) is the arena: two sound-system stacks framing an open
   sand yard, surf and sky. The untouched original now lives at
   `art-source/stages/sound-clash-sand/sound-clash-sand-stage-1672x941.png` (same bytes; the root copy
   was removed so the root stays a drop zone) and the game reads a 1280 × 720 Lanczos export at
   `godot/assets/stages/sound_clash_sand_stage_1280x720.png`. It is the `Stage` sprite in
   `TestArena.tscn` at **z_index −10**. The fighting floor line stays **y = 600**: the sand yard starts
   at world y ≈ 505 in that export, so both fighters stand inside the sand lane with sand front and
   back, and no crop, offset or repaint was needed. **Direction approved:** sand foot particles,
   ground contact shadows, gentle coastal wind, a warm-sun/cool-shade gradient and a 132 BPM speaker
   thump are wanted, but subtle — the centre fighting lane must stay crisp and readable, and nothing
   may wash out the fighters (the atmosphere layer sits behind them). **No crowd sprites yet**; the
   crowd/party work stays on its own §7 milestone. **Rare bird interference approved as a stage
   gag:** ~5 % chance every 15 s plus the **B** workshop key, a fly-by across the upper screen dropping
   one splatter that gives a standing fighter a brief comedic flinch (no damage) or lands on the sand
   when dodged. Values (5 %/15 s, 12-tick flinch, thump amount, particle rates, speaker-ring centres)
   are hand-set defaults awaiting a playtest, not approved tuning.

8. **Round-based day → sunset → night progression — approved (2026-11-15).** Match lighting follows
   the round: **Round 1 — Afternoon Sun** (`Color(1.0, 0.98, 0.94)`), **Round 2 — Golden Hour /
   Sunset Clash** (`Color(1.0, 0.78, 0.58)`), **Round 3 / final — Late-Night Sound Clash**
   (`Color(0.48, 0.55, 0.80)`). The late round pairs the night tint with a subtle warm arena
   floodlight over the **centre fighting lane** so both fighters stay crisp and readable against the
   night sky. Implemented with Godot's built-in modulation and **zero new art**: a `CanvasModulate`
   over the world canvas (the HUD lives in a `CanvasLayer`, so it is never tinted), a warm additive
   `Floodlight` gradient sprite over the lane that only rises at night, and the existing `SunGlow`
   dimmed with it. Transitions cross-fade with a 3 s sine tween via
   **`TestArena.set_time_of_day(phase, duration = 3.0)`**; **N** cycles Afternoon → Sunset → Night for
   playtesting and the HUD legend lists it. Round 1 is applied instantly on load.
   [TODO] The phase-to-round mapping is an **API, not a driven rule**: the workshop arena still has no
   round lifecycle, so the future round controller must call `set_time_of_day(round - 1)`. The night
   tint and floodlight strength are hand-set defaults awaiting a playtest.

9. **Smart Sparring AI modes for P2 — owner-requested workshop tool, implemented (2026-11-15).**
   `godot/scripts/ai/SparringController.gd` drives the sparring dummy by writing
   `BaseFighter.Command` only. It never assigns FSM state, calls `change_state`, moves a hitbox or
   skips frame data, so every AI attack takes the same startup/active/recovery path, input buffer
   and input-time beat judgement as a human press. `TestArena.gd` cycles the modes with **Y** and
   `TestHud.gd` draws the active mode in a banner under the beat pulse. **0 Workshop Dummy** is the
   old behaviour exactly: no input at all, guard while **G** is toggled. **1 Counter-Puncher** holds
   the mic-defence guard inside 190 px and punishes P1's recovery — a whiff and a blocked hit both
   end there — with Jab (≤150 px) or Sparta Kick (≤166 px). **2 Riddim Rusher** takes a beat-step in
   on every 132 BPM beat and throws a two-bar on-beat string (Jab → Sparta Kick → BOX) from
   `RUSH_PATTERN`, stepping instead of swinging when out of reach. **3 Spacing & Skank Baiter** runs
   two-beats-in / two-beats-out footsies, skank taunts above 330 px and throws the heavy BOX on a P1
   dash-in. **G stays an instant manual guard override in every mode** (ORed into the command).
   [TODO] Every range, cooldown, punish window and `RUSH_PATTERN` itself are hand-set lab defaults
   with no playtest; the controller is a test partner, not shipping opponent AI.

10. **Dancehall crowd line + 100% Crowd Hype Surge — owner request, implemented (2026-11-15).**
    The two owner uploads (`B6BD1902-…` = 3 characters + both crates, `DFBF74CC-…` = 3 more
    characters) are moved unchanged out of the repository root into `art-source/crowd/` and keyed
    with `art-source/crowd/slice_crowd_sheets.py` into six 1:1 character PNGs in
    `godot/assets/sprites/crowd/` plus `crate_01_red.png` / `crate_02_black.png` in
    `godot/assets/sprites/crates/`. The key is a magenta flood fill plus a tight fringe cut (the
    queen's pink shorts survive; no pixel is recoloured or resampled), the two men that overlap in
    projection are split by connected component rather than a column cut, and the touching crates
    are split at their emptiest column. `CrowdLine` in `TestArena.tscn` sits at **z_index −5** with
    the **Dancehall Queen at centre (640, feet 556)** flanked by the flag-waver, bucket-hat hypeman,
    cheering woman, arms-crossed man and clapping elder along the crowd line; the crates stand at
    (300, 592) and (1025, 592) beside the left and right speaker stacks. Nothing crosses the
    foreground sand lane below y = 600. Each 132 BPM beat bobs the line ~4 px with a 20 ms stagger;
    when a fighter's meter reaches 100 %, `BaseFighter.hype_surge_started` fires, the crowd jumps on
    a 0.16 s loop, `TestHud` flashes a **FORWARD! / PULL UP!** banner, and that fighter gets
    **1.20× damage and 25 % faster attack recovery for 300 ticks (5 s)**; the meter holds at 100 and
    resets to 0 when the boost ends. The surge multiplier applies before the on-beat 1.15×.
    [TODO] Crowd scales/positions, bob depth, the 1.20 / 0.75 multipliers and the 5 s length are
    hand-set defaults; none of this has been seen on screen or played.

11. **15-character rotating crowd: two rows, real depth, contact shadows — implemented (2026-11-15).**
    Nine further owner uploads (`02FCC31C-…`, `D1EB3EF0-…`, `E5C3A8F8-…`) are moved unchanged into
    `art-source/crowd/` as crowd-sheet-c/d/e and keyed with the same committed script
    (`slice_crowd_sheets.py`, now manifest-driven) into `crowd_07`…`crowd_15`, bringing the pool to
    **15 characters**. The mane-queen sheet proves the key is safe on genuine magenta clothing: her
    hair and shorts sit at |r−b| ≈ 136 while the backdrop is |r−b| ≈ 2, so nothing is eaten, and no
    pixel is recoloured or resampled. `CrowdLine` now runs two rows — a **Front Rope Row at y 556
    (scale 1.0, untinted)** and a **Back Crowd Row at y 516 (scale 0.85, tinted 0.80/0.84/0.94)** —
    five front and six back, with the other four off-stage in the pool. The **Dancehall Queen stays
    pinned to the centre front slot** and is never swapped out. Every 12–18 s, on 50 % hype (a new
    `hype_milestone_reached` signal on `BaseFighter`) and on the 100 % surge, one to two members fade
    out and are replaced by pooled characters, so the line keeps reshuffling. Row z-indexes keep the
    back row behind the front row, and every crowd member plus both crates carries a `GroundShadow`
    at its own feet (crowd shadows are created by `CrowdLine` from sprite width and re-grounded per
    row). [TODO] Row spacing, the 12–18 s cadence, the 0.85 depth scale/tint and the shadow radii are
    unplayed defaults; the full 15-character pool has not been seen on screen.

    **Owner creative direction — crowd (recorded 2026-11-15, not implemented):** classic **Dancehall
    dances** should feed the fighters' movesets (the skank already does), and **breakout crowd
    characters can be promoted to playable fighters**. The crowd pool is a casting bench as well as
    decoration. [TODO] Which dances map to which fighter or move, and what "breakout" means before a
    crowd member is promoted, are undecided; the §2 six-selector commitment, the Jan 14 mechanics
    lock and the April 21, 2027 target are unchanged.

12. **Family-friendly Patois & crowd policy — approved (2026-11-15).** Every shipped voice callout,
    HUD banner and arena line must stay strictly clean and family-friendly — the owner's examples are
    `LIGHTAH!`, `FORWARD!`, `WHEEL AND COME AGAIN!` and `BIG TUNE!` — and no offensive profanity may
    ship. The policy governs performance: §8 keeps every Patois line verbatim, and no existing entry
    is deleted, softened or "corrected". `FORWARD!` already ships in the 100 % Hype banner (item 10).
    **Resolved 2026-11-15:** `Heeeyaut!`, `Shut-Tup!` and `Yuh too Bod Mine!!` are **approved as
    playful, family-friendly comedic voice taunts**. Any explicit spelling variants of those lines
    stay **text-archive only** — never spoken and never displayed in the HUD or arena copy.

13. **Locked-in combat & sound-system roster — approved starting names, not implemented
    (2026-11-15).** Approved starting Dancehall moves: **The Bogle**, **Log On**,
    **Signal Di Plane**. Approved sound-system mechanics: **Pull-Up / Rewind Finisher**,
    **Needle Skip Dash**, **Mic Feedback / Dub Echo Shockwave**, **Record Static Parry**. With them
    the owner restates the direction to **promote standout crowd characters into playable fighters**
    (item 11). These are names and creative intent only: no startup/active/recovery frames, hitboxes,
    damage, meter cost, input motion, animation or audio exists for any of them and none is wired in
    `/godot`. [TODO] Frame data, input motions, which fighter owns which move, how the four mechanics
    spend Hype/Dubplate, and the promotion criteria all remain open. Nothing here moves the Jan 14,
    2027 core-mechanics lock or the April 21, 2027 six-selector target, and none of it authorises new
    art or audio spend.

14. **Record Static Parry — implemented (2026-11-15).** Guard pressed inside `BeatService`'s ±70 ms
    judgement window arms a 10-tick parry window; if the opponent's strike connects inside it the hit
    is negated entirely — no chip damage and no blockstun for the defender. The defender gains **+20
    Crowd Hype**, `static_parry_triggered(defender, attacker)` fires, `TestArena` spawns an electric
    vinyl-static `ParrySpark` between the fighters, and the attacker is stunned for 18 ticks so the
    defender can punish. The guard's beat quality is judged at the press (`_guard_beat`) and the parry
    resolves inside `receive_strike`, so it never bypasses the strike pipeline. [TODO] The ±70 ms
    window, +20 hype and 18-tick stun are unplayed values, and the parry has no art or audio yet.

15. **Best-of-3 round lifecycle — implemented (2026-11-15).** `RoundController` (active by default;
    `enabled` export) runs announce → fight → K.O. → next round → result, best of three. Round 1 is
    **Afternoon Sun** (`set_time_of_day(0)`), Round 2 **Golden Hour** (`set_time_of_day(1, 3.0)`),
    Round 3 / final **Late-Night Sound Clash** (`set_time_of_day(2, 3.0)`). Banners are
    `ROUND 1 — AFTERNOON CLASH`, `ROUND 2 — SUNSET HEAT`, `FINAL ROUND — LATE-NIGHT DUBPLATE`,
    `K.O.!` and `WHEEL AND COME AGAIN!` — all clean under item 12. Between rounds both fighters reset
    through `BaseFighter.reset_for_round()` (health, hype, state, buffered inputs, hitstop, position
    420 / 860), and input is locked during announce and result phases. After the rematch banner the
    match restarts from Round 1. **R** still reloads the scene for a clean match and **N** still
    overrides the lighting by hand (the next round start sets it back). [TODO] There is no round
    timer, time-out or draw path — the TypeScript 90 s rule is not ported — and the HUD banner boxes
    and round-win pips are unplayed.

16. **Chromebook Web export — implemented (2026-11-15).** `godot/export_presets.cfg` is now committed
    (it used to be git-ignored) and holds one **Web** preset: GL Compatibility via
    `renderer/rendering_method.web="gl_compatibility"` (the desktop renderer is unchanged), **single
    threaded** (`variant/thread_support=false`, so no COOP/COEP headers and it runs on plain static
    hosts such as GitHub Pages), **VRAM compression off** (`vram_texture_compression/*=false` plus
    `textures/vram_compression/import_etc2_astc=false`) so it never needs ETC2/ASTC support on Intel
    Chromebook GPUs, and extension support off. It exports to the repository-root **`/docs`** folder —
    `index.html`, `index.js`, `index.wasm`, `index.pck` and icons — which is the ready-to-publish
    GitHub Pages source; the full build is ~53 MB (38.1 MB wasm + 17.1 MB pck). Rebuild without an
    editor: `godot --headless --path godot --import && godot --headless --path godot --export-release
    "Web" docs/index.html` (needs the 4.5.stable web export templates). Nothing under `art-source/`
    changed and no art was resized: `exclude_filter` leaves the nine PNGs no scene references out of
    the packed build (the six `imported-poses` studies, `aligned/08_block`, `aligned/15_skank` and
    `selected-frames-2026-11-15/skank/06`), which holds the `.pck` at **17.1 MB instead of 20.9 MB**.
    [TODO] A plain static host serves the 38 MB `.wasm` uncompressed with no loading progress or
    compression polish; GitHub Pages is not enabled; and the build has not been run on the actual 4 GB
    Dell Chromebook.

17. **Chromebook crash/freeze safeguards — implemented (2026-11-15).** Three guards for long demo
    sessions in a browser tab on a 4 GB Chromebook. None of them touches art bytes.
    **Import-cache cap:** every texture larger than 512 px now carries `process/size_limit=512` in
    its **committed** `.import` file (those files are tracked from this milestone on), so a
    1536 × 1024 fighter frame decodes at 512 × 341 instead of 6.29 MB of RGBA. Measured from the real
    scene graph, the textures the arena loads dropped from **149.6 MB to 50.0 MB (−67 %)** and the
    `.pck` from 17.1 MB to 10.3 MB; the source PNGs are byte-identical and `art-source/` is untouched.
    Sprites stay sharp because a 512 px frame still renders ~4× oversampled at the ~122 px on-screen
    height. Because the cap changes the decoded pixel size, `BaseFighter` (`ANIM_SOURCE_MAX`) and
    `CrowdLine` (`ART_MAX_SIDE`) compensate by dividing `offset` and multiplying `scale` with
    (original side ÷ decoded side); without that the fighters and the crowd line render at a third of
    their size. Verified: P1's idle draws 255.8 world px tall and the pinned Queen 123.6 px, exactly
    the pre-cap sizes.
    **Pre-warm:** `TestArena._prewarm_effects()` spawns an invisible (alpha 0) off-screen
    (`x = −4000`) `ParrySpark` and `CPUParticles2D` puff during `_ready`, behind the round announce
    banner, so the driver compiles the effect shaders and allocates the particle buffers there rather
    than on the first footstep, hit or parry; both free themselves.
    **Hard caps:** `MAX_ACTIVE_BIRDS` = 1 (enforced in `_spawn_bird()` through
    `BirdHazard.is_flying()`), `MAX_PARRY_SPARKS` = 4 (the oldest spark is recycled) and
    `MAX_PARTICLE_AMOUNT` = 16, applied at start-up to every `CPUParticles2D` in the arena (the wind
    motes drop from 34 to 16).
    [TODO] **50.0 MB is short of the 40 MB goal:** the 19 hand-selected frames are already 512² and
    account for ~20 MB of the total, so only a smaller cap on those frames (or downscaled copies)
    goes lower. The stall that the pre-warm targets has not been measured on the real Chromebook, and
    the two ratio tables must be extended whenever a new art group is added.

18. **Grab / directional throw / throw break / Speaker-Stack Bounce — implemented (2026-11-15).**
    Def Jam-inspired close-range chain with **no new art**: the victim is thrown into the existing
    `launched` → `tumble` → `knockdown` (17_seated_landing) poses. New FSM states `GRAB`, `GRABBED`
    and `THROWN` are in the single transition table; `BaseFighter.Command.grab` is bound to **U**
    (`p1_grab`) and joins the HUD legend as `U grab/tech`.
    **Grab:** inside 96 px and in front, a 5-tick reaching grab holds the defender for 16 ticks. It
    never enters `receive_strike`, so a held guard (S) has no answer. **Throw Break ('Tech'):** the
    defender pressing Grab inside an **8-tick** window shoves both fighters apart for zero damage and
    fires `throw_broken`; `TestArena` answers it with the shared spark flash.
    **Directional throws:** forward/neutral hurls the victim across the sand for **14 damage and +15
    Crowd Hype**, and holding back spins them behind the attacker for **12 damage and +18 Hype** plus a
    `crowd.celebrate()` cheer pop. Both fire `throw_connected(attacker, defender, &"forward"|&"back")`.
    **Speaker-Stack Bounce:** an airborne forward-thrown fighter that reaches a stack (the 40-wide
    walls at x 20 / 1260, so a 60-wide body stops at centre 70 / 1210) takes **+4 bonus damage**,
    emits `speaker_slam_triggered(victim, side)`, gets a heavy camera shake and bounces back onto the
    sand. The bounce is driven off *which side* was hit, because the wall collision has already zeroed
    `velocity.x` by the time the check runs.
    **AI:** `SparringController` now grabs a turtling (guarding or crouching) P1 in Mode 1 and Mode 2,
    and presses Grab inside the defender's window on ~55 % of the grabs it takes (measured 5–6 of 10
    in the harness).
    [TODO] All values (96 px, 5/16/12/8 ticks, 14/12/+4 damage, 15/18 Hype, the 55 % tech rate, the
    55 % forward-throw arc and the 220 px/s minimum bounce) are hand-set defaults awaiting a playtest;
    there is no throw animation art (the grab uses the jab frames and the held victim the hitstun pose),
    no air grab, no grab invulnerability and no throw whiff punish window beyond the 12-tick recovery.

19. **Arcade typography + Patois callout subtitles — implemented (2026-11-15).** Four genuine SIL
    Open Font License faces live in `godot/assets/fonts/` beside their licence texts
    (`OFL-bungee.txt`, `OFL-bungeeshade.txt`, `OFL-chakrapetch.txt`): `Bungee-Regular.ttf`,
    `BungeeInline-Regular.ttf`, `BungeeShade-Regular.ttf` and `ChakraPetch-Bold.ttf`. `TestHud.gd`
    no longer touches `ThemeDB.fallback_font`; every label goes through one `_text()` helper that
    draws a drop shadow, a dark outline (`max(2, 16 % of the size)`) and then the crisp face.
    **Face map:** Bungee **Shade** for the huge `K.O.!` banner, Bungee **Inline** for the Hype Surge
    (`FORWARD!` / `PULL UP!`) and rematch (`WHEEL AND COME AGAIN!`) banners, Bungee for the fighter
    tags inside the health bars, the round announce headers and the Patois shouts, and Chakra Petch
    Bold for the deadpan translations, the Hype readout, the AI-mode banner and the key legend.
    Bungee is a very wide face, so `_fit_size()` shrinks a string to its box instead of letting it run
    off the viewport.
    **Callouts:** big moments only — an **on-beat** skank taunt (`BaseFighter.taunt_finished(true)`,
    so an off-beat taunt stays silent) shows `YUH TOO BOD MINE!!` / `(Translation: You're way too
    jealous!)`; `speaker_slam_triggered` shows `HOLD DAT!` / `(Translation: Take that to the
    speakers!)`; `static_parry_triggered` shows `BIG TUNE!` / `(Translation: Cleanest block in the
    dance!)`; and `hype_surge_started` shows `WHEEL AND COME AGAIN!` / `(Translation: Rewind the
    track — rematch!)`. They render in a translucent pill at bottom centre (y 655, under the sand
    lane), fade out over the last 0.45 s of a 1.8 s life, share a **4.0 s cooldown** and hold **one
    line at a time** — a trigger inside the cooldown is dropped, never queued. **V** toggles the
    subtitles (`TestArena._unhandled_input` → `TestHud.toggle_subtitles()`) and joins the legend as
    `V subtitles`. Patois is preserved verbatim, in the uppercase shout form the owner specified.
    [TODO] All sizes, the 1.8 s / 4.0 s values and the pill geometry are hand-set defaults awaiting a
    look on the real Chromebook; there is no queue (a second callout inside 4 s is simply lost) and
    the rematch line reuses the round-banner slot rather than its own animation.

20. **60-second round clock — approved (2026-11-16).** Owner decision: a round lasts **60 seconds**
    of live play, not the TypeScript prototype's 90 s — shorter rounds keep the clashes intense and
    cycle faster. The clock drains only in `RoundController.Phase.FIGHTING`, so the announce, the K.O.
    banner, the rematch banner and a future pause never consume it. At zero the higher remaining health
    wins the round under a `TIME!` banner; an **exact HP tie** replays the round with the
    `WHEEL AND COME AGAIN!` banner and awards **no** win pip (`round_ended(round, -1)`), keeping the
    same round number and lighting with a fresh clock. Implementation and evidence: backlog item B6 and
    its verification section below. [TODO] The `TIME!` wording, the red-under-10 s styling and the
    tie-replay length are agent defaults; only the 60 s length and the time-out/tie rules are owner
    decisions.

21. **Crowd staging + impact juice from the screen-recording review — implemented (2026-11-16).**
    Owner direction: apply the 2026-11-16 reference findings directly to the live Godot build, on top
    of the existing 15 sliced Dancehall crowd characters and 2 vinyl milk crates, without touching the
    approved Feedback art. Everything below is presentation-only.

    - **Reference relocation.** The three screen recordings moved out of the repository root into
      `artifacts/sound-clash/art-source/references/2026-11-16-scr-review/` beside
      `CROWD-AND-MOVEMENT-REVIEW-2026-11-16.md` and five evidence stills, under their real names
      (`ScreenRecording_11-15-2026-{17-34-45,23-25-15,23-26-04}_1.mov`; byte-identical to the root
      blobs from `596ae3a`). They live outside `/godot` and `/docs`, so the Web pack never carries
      them: `docs/index.pck` is **10,648,048 B (10.16 MiB)** after this build, still under the 11 MB
      budget, and `index.wasm` is unchanged at 38,057,390 B.
    - **`YardBarrier.gd`** draws a low wooden/zinc yard barrier with primitives across y **524–558**
      at **z −4** — over the crowd rows (−5 front, −6 back), under the fighters (0) — so the 15
      sprites stand behind something instead of being cut off onto the sand. No texture, no export
      weight. The pinned Dancehall Queen and both milk crates are untouched and stay crisp; the crates
      sit at y 592, in front of and below the barrier band.
    - **`ForegroundSpectator.gd`** puts one cropped shoulder/bucket-hat silhouette in its own
      `Foreground` **CanvasLayer (layer 1, below the HUD's)** at **z +10**, bottom-left, alpha 0.85.
      It is screen-space, so the tracking camera never drags or scales it, and it sits below the
      fighters' feet band so it cannot hide the lane. This is the fifth depth plane the arena was
      missing.
    - **`CrowdLine` ambient sway + proximity ebb.** Each member gets its own phase and rate
      (0.15–0.29 Hz, ±2.6 px, 1.3° tilt) written into `position.x` only, so the existing beat bounce,
      surge hop and 12–18 s reshuffle keep owning `position.y`/`rotation` unchanged. `flinch(at_x,
      strength)` pulls spectators within **240 px** away from a body (9 px, 6°, 0.55 s decay);
      `TestArena` fires it when a fighter is **THROWN / KNOCKDOWN** (strength 1.25) or moving at
      **≥ 320 px/s** (0.55 — walking is 220, so walking never triggers it), rate-limited to one per
      fighter per **0.85 s**. This is the live-action yard-brawl beat: they lean out of the way and
      close back in.
    - **Impact juice (closes backlog item B4).** `BaseFighter.flash_impact(on_beat)` brightens the
      struck `Sprite` for **2 physics ticks** — `(2.10, 1.94, 1.52)` off the beat, `(1.55, 1.92,
      1.30)` on it — counted before the hitstop early-return so a frozen contact still releases it,
      and cleared in `reset_for_round()`. `ParrySpark` gained `parry` / `hit` / `hit_onbeat` styles:
      the existing electric static plus a crisp four-point contact burst (white/gold, or vibrant
      green/gold when the **input** was judged on-beat), primitives only, 0.24 s life. `TestArena`
      spawns the burst from `_on_strike_resolved`, and the speaker-stack slam uses the `hit` style.
      Caps unchanged: **4 sparks, 16 particles**, no per-hit allocation, no new texture group.
    - **Checks actually run** (Godot 4.5.stable, headless, temporary harness created then deleted):
      `--import` clean; an 18-check run of `TestArena.tscn` passed **18/18** — barrier present at
      z −4, `Foreground` CanvasLayer with the spectator at z +10, crowd 15 / front 5 / back 6 /
      pooled 4, crowd line y 556, ambient sway moved **9 of 11** visible members off their home x,
      flinch reached **7** members and set a visible lean, the flash tinted `(2.1, 1.94, 1.52)` and
      cleared to white after 2 ticks, an on-beat contact produced a `hit_onbeat` burst **and** the
      green flash `(1.55, 1.92, 1.3)`, and six forced sparks still capped at **4**.
      `--export-release "Web"` rebuilt `docs/` successfully.
    - **Looked at on screen (one still, Web build).** The rebuilt `docs/` export was served and
      captured in a browser: `artifacts/sound-clash/art-source/references/2026-11-16-scr-review/frames/06-godot-build-after-upgrade.png`.
      It confirms the five-plane composition, the barrier occluding the crowd's ankles along the
      whole line, the front/back rows at the right scale, and the corner silhouette sitting below
      both fighters' feet. The first capture also showed the barrier reading as a bright straw band
      that pulled the eye, so every plank/rail value was dropped roughly 30 % and the bright rail
      highlight removed; the shipped plank is **rgb(77, 50, 31)** against **rgb(234, 167, 78)** sand,
      the zinc cap **rgb(58, 54, 48)**. That is a sampled pixel measurement, not an impression.
    - **[TODO] Still unverified:** motion and feel — the sway, the proximity flinch, the two-tick
      flash and the on-beat burst cannot be judged from one still, and the crowd/flash colours have
      not been seen under the Round 2 sunset or Round 3 night tint. Sway, flinch, speed threshold,
      cooldown, flash colours and burst life remain hand-set agent defaults for Garfield's eye on the
      Chromebook build.

22. **Framing + visual-polish pass — implemented (2026-11-16).** Second owner-directed pass on the
    sand arena after the first screenshot. Zero new art credits: everything is code, primitives and
    existing sprites. Presentation only — no combat rule, hitbox, hurtbox or movement value changed.

    - **Camera framing.** `CAMERA_FIT_DISTANCE = 820` replaces the inline `1100`: at the neutral
      440 px fighter spacing the zoom is now **1.041** (was ~1.39) and the visible world is
      **x 25…1255**, so the left flag stack (82–204) and the right lion stack (1075–1201) both sit
      fully inside the frame. The 1.0 floor is unchanged, so the single-layer stage art still always
      covers the view.
    - **Milk crates.** Both scaled to **55 %** (0.22 and 0.209 from 0.4/0.38) and tucked against the
      inner speaker bases at **(215, 568)** and **(1065, 568)**; the `offset` values were already
      exactly half the texture height, so the base still sits on the sand with no re-authoring. Their
      `GroundShadow`s follow (radius 19 / 18 at ground y 568).
    - **Anchored leaning member.** `crowd_05_arms_crossed_man` (`ArmsCrossed`) now owns a dedicated
      **edge slot** at **x 1032, slot −1**, with a permanent **7° lean**, and is excluded from
      `_random_visible()`, so no rotation can ever drop him mid-line leaning on air. `YardBarrier`
      grew a **corner post** at the same x (top y 492) for him to lean on. The front line is
      therefore **6 bodies** (5 slots + the post) and the pool holds 3; the crowd is still 15.
    - **Key legend** moved out of the sky to `LEGEND_Y = 698`, below the subtitle pill (630–680).
    - **Depth and fighter pop.** New `CrowdHaze.gd` lays a cool wash (12 strips, sine falloff, peak
      alpha 0.26) over **y 404–566** at **z −4**: the crowd and midground lose a value step while the
      fighters keep full contrast. Fighter contact shadows widened to **radius 46** and
      **strength 1.35** (from the 32 default), so both leads sit on a heavier grounded shadow.
    - **Foreground corner.** The flat hat-and-shoulders primitive is gone: the corner is now an
      **existing illustrated spectator** (`crowd_03_hypeman_bucket_hat`) at 0.34 scale, darkened to
      `(0.26, 0.28, 0.36, 0.92)`, in the screen-space `Foreground` CanvasLayer at **z +10**, with
      `ForegroundCorner.gd` drawing a soft radial wash behind it. The card's top sits at screen y
      ≈ 620, below the fighters' feet band (576–600 at every zoom), so it still cannot cover the lane.
    - **Idle groove and squash/stretch.** `BaseFighter` gains a presentation-only `_process` polish
      layer that composes on `_anim_base_scale`: IDLE/CROUCH pop **2 px** up with **1.8 % squash** on
      every **eighth note at 132 BPM** (exponential settle, so it breathes on the grid instead of
      drifting); attacks get a **0.93 squash + 2.5 px** wind-up during startup, a **1.055 stretch +
      6 px** micro-lunge at the active frame and an eased return through recovery; JUMP stretches on
      the way up and compresses on the way down. `BeatService.beat_phase()` was added for the grid
      position only — judgement still reads the input, per item 1.
    - **Checks actually run** (Godot 4.5.stable headless, temporary harness deleted after the run):
      **25/25** — zoom 1.041 with the view at 25…1255 (both stacks inside), crates at (215,568) and
      (1065,568) at 55 % with matching shadows, the leaner on row 0 / slot −1 / x 1032 / 0.122 rad
      lean, front line 6 of 15, eight forced rotations never moved him, haze and corner post present,
      foreground card using the real texture at z +10 and darkened, legend at 698, idle groove bobbing
      **1.86 px** with a **3.4 %** squash ratio. `--export-release "Web"` rebuilt `docs/` at
      **10,651,400 B**.
    - **Looked at on screen:** `…/frames/07-godot-build-framing-polish.png` — both full stacks framed,
      knee-high crates beside them, clear sky, bottom-edge legend, illustrated corner spectator and
      heavier fighter shadows all confirmed in the running Web build.
    - **[TODO] Still unverified / open:** motion at speed (groove snap, lunge, squash on a real
      exchange), whether a sixth front-line body crowds the right end once the stack is in frame, and
      none of this has been seen under the Round 2 sunset or Round 3 night tint. The 820 fit
      distance, 6 px lunge, 2 px groove, 0.26 haze and card tint are agent defaults for Garfield's eye.

23. **Owner playtest pass — facing, visible strikes, crowd acting, lighting, framing — implemented
    (2026-11-17).** Owner feedback from the Chromebook build, worked in the order the owner asked for.
    Presentation only: no combat rule, hitbox, hurtbox, frame data, beat window or movement value was
    changed, and **no new art was generated, purchased or mirrored on disk**.

    - **Fighter facing (fixed first).** `BaseFighter` gained `duel_opponent` and `_face_opponent()`;
      `TestArena` wires P1 to P2 at start-up. Both fighters turn toward each other on every neutral,
      crouch and airborne tick, an attack keeps the facing latched by `_configure_hitbox()`, and
      walking away backs up instead of turning your back. `face_toward()` now also accepts JUMP, so a
      cross-up lands facing the opponent. With no `<anim>_left` sheet the sprite is mirrored
      (`flip_h`) — see the item 2 amendment; that mirror is the port's only deviation from the old
      "no flip_h" rule and it is provisional.
    - **Invisible CPU attacks (fixed second).** Root cause was the roster, not the FSM: the CPU
      defaults to **Dubplate** (now **Lickshot**, item 26), whose art at the time was one portrait, so every attack state played no frame
      at all while the hitbox still resolved damage. Three changes: `_play_state_anim()` falls back
      through `idle/walk/jump/block` instead of silently keeping the previous frame; attack states lean
      the body through the swing (`LEAN_WINDUP` 0.055 rad back, `LEAN_STRIKE` 0.115 rad through
      contact) on top of the existing wind-up, lunge and squash; and every `ATTACK_ACTIVE` entry spawns
      a `StrikeTell` smear (`StrikeTell.gd`, primitives, z 3, capped at 4 like the sparks) drawn over
      exactly the rect `BaseFighter.attack_volume()` resolves contact with — same shape, same tick.
      **Resolved 2026-11-17 (§9 item 27):** Lickshot now has drawn attack poses — the high kick on L
      and the Sonic Clap windup/impact on K — so those two attacks suppress the smear and play their own
      art. His jab still has no drawing and still uses the smear. Each move is one held pose, not an
      interpolated startup/contact/recovery sheet.
    - **Stray bottom-left character (removed).** The `Foreground` CanvasLayer, its `CornerWash` radial
      wash and the cropped `BottomCard` spectator are gone, together with `ForegroundCorner.gd`/`.uid`.
    - **Unsupported leaning spectator (removed).** `ArmsCrossed`'s only drawing is a lean and there is
      nothing at the crowd line to lean on, so he is retired from the line (`CrowdLine.RETIRED_NAMES`:
      never placed, never rotated, never returned by the pool) and the `YardBarrier` corner post that
      existed only for him was deleted. His sprite, texture and scene node stay in the repo. Rows are
      still 5 front / 6 back. [TODO] A redrawn standing pose would let him return.
    - **Crowd acts instead of unison bouncing.** Each member is cast into an act from its node name —
      `FlagWaver` waves the flag, `TowelWaver` waves the rag, `AirhornHypeman` raises and blows,
      skankers skank, the queen and hypemen dance, the rest cheer — and performs it from its own seeded
      phase and rate (0.20–1.05 Hz per act). The beat only drops a small accent on each member's own
      beat of the bar (`beat_div` 1–3, `beat_offset` 0–2), so the line no longer hops in lockstep.
      Motion is whole-sprite lift, tilt and volume-preserving squash, because each character is one
      frozen drawing. [TODO] Real waving, a raised horn and dance cycles need **multi-frame crowd
      sheets** (2–4 frames per active character) — art preparation, not code.
    - **Time of day is a scene change, not a filter.** Added `SunsetWash` and `NightWash` (1280×720
      vertical gradients at z −9), a directional `SunShaft` at z −8 and a per-phase sun bloom position
      and scale. **Afternoon:** clean daylight, no washes, compact 0.95× shadows. **Sunset:** 0.62
      orange wash, sun down at y 300 and 3.1×, 0.36 shaft, long 1.95× shadows cast to the right.
      **Night:** 0.74 deep-blue wash over sky, clouds and surf, floodlight 0.46 over the centre lane, no
      sun, crowd at a 0.85 silhouette through `CrowdLine.set_night()` (written on `self_modulate`, so it
      never fights the swap fades). `GroundShadow` gained `light_dir`/`stretch`, applied to fighters and
      crowd together, so the cast direction can never disagree.
    - **Scale, framing and props.** `BaseFighter.FIGHTER_ART_SCALE = 1.24` renders every fighter about
      24 % larger (~151 px against 121.75 px) with the feet still planted, since the sprite offset is in
      texture pixels. The camera ceiling dropped **1.6 → 1.12** and the minimum follow distance rose
      420 → 620, so close-range fights keep the yard in frame; the neutral zoom stays ~1.04 and both
      speaker stacks stay inside the view at 1.12. Both record crates shrank to 0.128/0.124, moved onto
      the sand line at (192, 606) / (1090, 606), z −3, with matching shadows.
    - **Sand interaction.** Beside walking footfalls, takeoff, landings and knockdowns, a body skidding
      on the sand (blockstun shove, hitstun, thrown landing, knockdown) now trails sand puffs through
      `BaseFighter._slide_puff()`, rate-limited to one every 7 ticks.
    - **Checks actually run** (Godot 4.5.stable headless, Linux: `--import`, then
      `--script res://tools/headless_roster_check.gd`): **47/47** — P1 facing right and the CPU facing
      left and mirrored, both turn after a forced side swap, Dubplate at the enlarged adult scale,
      Feedback's figure over 140 px, each phase's washes / floodlight / sun, 1.95× sunset and 0.95×
      afternoon shadows, crowd silhouette 0.85 at night, crates at 0.128 / y 606, front 5 / back 6 with
      the leaner invisible, flag/rag/horn acts assigned, 11 distinct crowd phases, and a real jab
      reaching `ATTACK_ACTIVE` with a live `StrikeTell` in the tree.
    - **Not verified:** there is no GPU renderer in the authoring environment, so **nothing in this
      pass has been looked at on screen** — colour and contrast per phase, the mirrored mic hand,
      whether the acts read as dancing at speed, and the strike smear at full frame rate all need
      Garfield's eye on the Chromebook build.
    - **Still needs art (Sprite Arific / Flow prep):** left-facing Feedback, so the mirror can be
      retired; Lickshot attack frames; a standing replacement for `ArcsCrossed`; multi-frame
      flag/rag/horn/dance crowd loops; and a dedicated night sky/cloud plate if the gradient wash is
      not enough.

24. **Default matchup is Feedback vs Feedback; reaction poses aligned to the sand — owner decision,
    implemented (2026-11-17).** Two follow-ups from the same playtest, landed before this branch merges
    into `stage/sound-clash-sand`.

    - **Default matchup.** `MatchSetup.p2_fighter` now defaults to `feedback`, so the game opens on
      **Feedback vs Feedback**; Lickshot (named that since item 26) and Young Selecta stay fully selectable on the title screen and
      `FighterRoster.ORDER` is unchanged. Owner rationale: refine combat, visible blocks, hit reactions
      and the upcoming Dancehall move set — **The Bogle**, **Log On**, **Signal Di Plane** — with full
      animation on both sides before building the other fighters' unique movesets. This supersedes item
      23's note that the CPU defaults to Dubplate; the portrait-fighter problem found there (missing
      attack frames) is unchanged and still needs art.
    - **Ground alignment.** `16_gut_punch` (hitstun) is a folded body whose art ends at row 835, far
      above the pack's 900 sole row, so the old pelvis anchor (-98) pushed Feedback ~70 px below the
      sand; `04_inverted_c` (tumble) and `03_c_recoil` (launch) had the same problem. Hit-reaction,
      launch, tumble, knockdown and KO offsets are now derived from each pose's own measured
      alpha-bottom row and place it at `BaseFighter.REACTION_FLOOR_Y = 592` — on the sand, never
      through it (8 px above the fighter origin / floor line at y 600). Idle keeps its authored sole
      anchor and still measures 600.2 on the floor.
    - **Checks actually run** (Godot 4.5.stable headless, same harness): **49/49** — P2 default and the
      three-cycle wrap are Feedback, idle sole at 600.2, and the lowest of
      hitstun/launched/tumble/knockdown/ko measured at **591.2** (above the 592 line) from the real
      texture alpha bounds rather than from the offset table.
    - **Still not verified:** none of the reaction alignment has been seen on screen. The check proves
      the art cannot cross the sand line; it does not prove the poses look planted in motion.

25. **Fighter #3 — Young Selecta's signature moveset, designed by the owner's son — recorded, not built
    (2026-11-17).** Documentation only: **no code, scene, input action, frame data, hitbox, SFX cue or art
    was added for this entry.** It exists so the design survives the current combat work, not as a claim
    that any of it runs. The owner's production order puts it behind Feedback: refine Feedback's combat,
    blocking and hit reactions and build his **Dancehall dance-move attacks — The Bogle, Log On, Signal
    Di Plane** — first, then Young Selecta's projectiles and bat swings, then Lickshot's unique moveset.

    - **Attribution.** The moveset was designed directly by the owner's **10-year-old son**, a named
      co-designer of Fighter #3. Preserve his move names and props (`Mic Toss`, the microphone-stand
      baseball swing, the school backpack). Do not silently rename, merge or reassign one of his moves to
      another fighter when implementing.
    - **1. Mic Toss (`J`) — fast projectile.** Throws a microphone horizontally across the arena: a fast
      straight shot with a short cooldown. Open: cooldown length, travel speed, whether an on-beat throw
      earns a rhythm bonus, and **mic continuity** — §1 requires one mic in one declared hand on one
      continuous cable, so a thrown mic needs either a tether/recovery or a written exception (the cable
      unplugs and a fresh mic is drawn). `/godot` has **no player projectile system** yet — crowd hazards
      and the bird are stage-side — so this is new code, not a data row.
    - **2. Microphone-stand bat swing (`K`) — heavy line drive.** Swings the mic stand horizontally like a
      baseball bat, knocking the opponent back with heavy hitstop and a metallic bat clang. `Sfx` already
      synthesises a `clank` cue (backlog B8) that can be reused or retuned; hitstop and knockback are
      unset and must be deliberate written values, not a copy of the jab's.
    - **3. Uppercut mic-stand swing (`I`) — anti-air pop-fly.** Swings the stand upward in a steep rising
      arc to launch airborne or close-range opponents skyward. Needs two hit volumes (a close-range scoop
      plus a rising column), an explicit decision on whether it genuinely beats a jump-in, and a launch
      arc that comes back down to the sand — any new launch art must honour item 24's floor alignment.
    - **4. Textbook & dictionary backpack throw (`L`) — arcing heavy projectile.** Reaches into his blue
      backpack and lobs an oversized hardcover dictionary or textbook in a high arc across the sand, with
      heavy impact and fluttering page particles. Open: which book (the design allows either), arc and
      flight time, whether it is a real thrown object with a landing hazard or a single impact, and a
      particle budget for the pages — the existing Chromebook caps (4 sparks, 16 particles, item 17)
      were sized for contact bursts, so page flutter needs its own measured allowance.
    - **Key collision to settle before coding.** `J`, `K`, `L` and `I` are already the live attack keys in
      `BaseFighter.KEY_LAYOUT`: `light`/jab (J), `heavy`/BOX (K), `tump` (L) and `upper_box` (I). The design
      above reassigns all four on Young Selecta. Decide explicitly whether these four moves **replace** his
      normals, are **held-modifier or stance** variants, or take new keys; do not silently overwrite the
      shared layout, because P1, P2 and the CPU all read it.
    - **Art and audio needed.** Young Selecta ships **three frames today** — `idle.png`, `thrust.png` and
      `slam.png` in `assets/sprites/young-selecta/` — so none of these moves has a frame. Required art:
      the mic stand in both swing arcs (startup/contact/recovery), a mic projectile with a readable spin,
      an oversized hardcover book, page-flutter frames or a particle, and the backpack reach. Nothing here
      is drawn, generated or purchased yet, and every open value above stays **[TODO]** until the owner
      approves art.
    - **Design intent worth keeping.** All four moves share one identity: a schoolyard kid using what a
      young selecta actually carries — a mic, a mic stand and a school bag — so he reads as comically
      dangerous without a martial-arts sheet. Keep the props literal and the arcs exaggerated.
    - **Production order (owner, 2026-11-17).** 1) Feedback's combat, blocking and Dancehall move attacks
      (The Bogle, Log On, Signal Di Plane). 2) Young Selecta's projectiles and bat swings. 3) Lickshot's
      unique moveset. This is the owner's sequence, not a build order of convenience.
    - **Status:** design recorded, **nothing implemented, nothing verified**; no headless or on-screen
      check exists for any of it.

26. **Fighter #2 renamed Dubplate → Lickshot, and the roster name pool recorded — owner decision,
    implemented (2026-11-17).** Unlike item 25, this one reaches code, so it was carried through the
    roster table, the UI and the checks rather than only the docs.

    - **What changed.** Roster key `dubplate` → **`lickshot`** and display name `DUBPLATE` →
      **`LICKSHOT`** in `FighterRoster.ORDER` and `FighterRoster.FIGHTERS`, so nothing stale can resolve to a
      dead key; the art folder moved `assets/sprites/dubplate/` → `assets/sprites/lickshot/` (`git mv`,
      `.import` `source_file` updated, texture UID unchanged, `process/size_limit=512` and his per-frame
      offset untouched); the title-screen line now reads **FEEDBACK · LICKSHOT · YOUNG SELECTA**;
      `project.godot`'s description and the comments in `MatchSetup.gd`, `BaseFighter.gd`, `StrikeTell.gd`
      and `FighterRoster.gd` follow. `TestHud.gd` needed no edit — it draws `display_name()`, so the name
      plate follows the table by itself.
    - **The name may still evolve.** The owner records it with that caveat; `Disc Jock Lickshot` and
      `Booyaka Lickshot` stay recorded alternates. If it changes again, change the key, display name, art
      folder and guards together — a display-name-only rename leaves saved keys pointing at a fighter that
      no longer exists.
    - **Deliberately not renamed: the music term.** "Dubplate" the record/mechanic survives in §7's
      **Dubplate meter** and in `RoundController.gd`'s `FINAL ROUND — LATE-NIGHT DUBPLATE` banner. Those are
      about an exclusive dub, not the fighter; that banner is not a missed rename. Changing it would be a
      separate decision.
    - **Provenance kept.** `art-source/fighters/dubplate/…` and the 2026-11-16 cut-out notes keep the old
      name: they record the uploaded file's original identity and are cited by the asset-inventory table.
      The game asset moved; the art's source trail did not.
    - **Checks actually run** (Godot 4.5.stable headless: `--import`, then
      `--script res://tools/headless_roster_check.gd`): **50/50 assertions, exit 0**, including a new rename
      guard that fails if `dubplate` returns to `FIGHTERS` or `ORDER`, P2 resolving to `LICKSHOT` with his
      frames built, and his enlarged adult render height intact (0.2992 = 0.2378 × 1.24). Counts here are
      measured by counting `PASS` lines: the figures recorded in items 23 and 24 (45 and 47) were undercounts
      by two, and those same runs print **47** and **49** — corrected in place.
    - **Roster name pool for Fighters #4–#6 (owner, 2026-11-17): Fling Stone, Rum Punch, Sky Juice.**
      Working names for the open slots, recorded in §2 and cross-referenced in §8. They are **not
      assignments** — nothing says #4 is Fling Stone, #5 Rum Punch or #6 Sky Juice — and not designs: no
      silhouette, stance, move set, height, voice or art exists behind any of the three. `Rum Punch` also
      stays a possible move/hit name. Do not start a fighter from a name, and do not promote one of them into
      a slot without the owner.
    - **Still unverified:** there is no GPU here, so the renamed lettering has never been seen on screen. The
      checks prove the table, the frames and the HUD name plate resolve; they cannot prove the longer word
      fits the title layout without clipping, and nobody has looked.

27. **Lickshot's four-pose set: mic stance, high kick and the Sonic Clap — owner upload, prepared and
    wired (2026-11-17).** This supersedes the single-portrait placeholder and the "no attack art" TODO in
    item 23's strike-smear note.

    - **The uploads.** Four new owner images arrived with UUID filenames and are now stored with descriptive
      names under `art-source/fighters/lickshot/`: `01_mic-stance-idle_original.png`,
      `02_high-kick_original.png`, `03_sonic-clap-windup_original.png`,
      `04_sonic-clap-impact_original.png`. The originals are untouched.
    - **The updated design.** Red/yellow/green Rasta mesh string vest, olive cargo trousers, tan Clarks
      Wallabees, dark flat cap over the locks, gold chain, gold watch and rings, corded mic in the right hand
      with the cable running down to the sand. This replaces the older rasta-stripe track jacket / green
      trousers portrait, which is archived rather than deleted.
    - **The four poses.** *Mic stance / idle* — mic in the right hand, left hand raised with a motion arc.
      *High kick* — mic still held, extended high left kick. *Sonic Clap windup* — arms spread wide with
      oversized hands, mic tucked in the right cargo pocket. *Sonic Clap impact* — the oversized hands clapped
      together in front inside golden shockwave rings.
    - **Preparation.** `art-source/fighters/prep_lickshot_poses.py` keys the plum studio backdrop, drops the
      soft cast shadow and the vignette pocket sealed off by the mic cable, cuts the lit sand floor while
      protecting the cable and the tan leather, crops to alpha, caps the longest side at 512 px and reports
      the measured alpha bounds (`art-source/fighters/lickshot/prep-report.json`). Outputs in
      `godot/assets/sprites/lickshot/`: `idle.png` (307×512), `high_kick.png` (429×512),
      `sonic_clap_windup.png` (457×512), `sonic_clap_impact.png` (512×307).
    - **Placement rule.** Every pose's measured alpha bottom sits on world **y 592**
      (`BaseFighter.REACTION_FLOOR_Y`), so the Wallabees stay planted on the sand line with zero sinking, and
      every character is authored at 121.75 px crown-to-sole — the shared adult reference, × 1.24 =
      **~151 px**, matching Feedback. Offsets and scales live in `FighterRoster.FIGHTERS[&"lickshot"]`.
    - **Wiring.** K (BOX / `strong`) plays Sonic Clap windup → impact → impact, L (TUMP) plays the high kick,
      and both are listed in the roster's `no_strike_tell`, so `TestArena` no longer paints the generic
      `StrikeTell` smear over drawn art (`BaseFighter.shows_strike_tell()`). The jab still has no drawing and
      keeps the smear. Every neutral, movement, guard and reaction state shows the mic stance — there is no
      walk, jump, hit-reaction or KO drawing for him yet. The `FighterRoster` tagline used by Character Select
      now reads "Fighter #2 · rasta mesh vest, Wallabees and a corded mic"; the HUD name plate already follows
      `display_name`. `RoundController.gd`'s `FINAL ROUND — LATE-NIGHT DUBPLATE` is the music term and is
      untouched.
    - **Archive.** The placeholder portrait moved to
      `godot/assets/sprites/lickshot/_archive/portrait_2026-11-17_placeholder.png` (with its `.import`), and
      the Web preset excludes `assets/sprites/lickshot/_archive/*` so it never ships. `prep_fighter_art.py`'s
      first job now writes to that archive path, so rerunning it cannot resurrect a `dubplate/` sprite folder.
    - **Checks actually run** (Godot 4.5.stable headless: `--import`, then
      `--script res://tools/headless_roster_check.gd`): **58/58 assertions, exit 0**. New assertions: all four
      poses registered; every pose's real alpha bottom at **592.0**; the three full-body frames at 152.5 /
      151.6 / 151.9 px; the impact character at 151.0 px with its shockwave frame taller; the smear
      suppressed for K/L and still present for the jab. The pre-existing Dubplate-rename regression guard
      still passes. `/docs/index.html` was rebuilt with
      `godot --headless --path godot --export-release "Web" ../docs/index.html`.
    - **Still unverified.** There is no GPU here, so the four poses have never been seen in the running game:
      silhouette, cut-out edges at gameplay size, the kick's new head-height hitbox, the clap's reach, timing
      feel and the mirrored left-facing version all need the owner's on-screen pass. Each pose is one drawing,
      not an interpolated sequence, and the cable is drawn per pose rather than animated.

### Approved Backlog / Roadmap — master list (2026-11-16)

Recorded at build `ad27516` (`stage/sound-clash-sand`); §9 items 1–19 above are the decisions that
produced that build. **Everything below is [TODO] — none of it is implemented**, and this section is
documentation only: no code was changed for it — with the single exception of **B4**, implemented
later under decisions item 21. The order is the owner's sprint order followed by the
agent's recommendations, not a delivery promise; each item records its scope and the evidence that
would close it so a later session can pick one up without re-deciding the design. Re-read §2 before
scheduling any of it against the April 21, 2027 target, and §8 before writing any new Patois copy.

#### Owner items — approved in planning (2026-11-16)

**[DONE 2026-11-16] B1. Arcade title screen and match setup (`TitleScreen.tscn`).** Closed by
the 2026-11-16 roster/title build — see “Playable roster #2/#3 and the arcade title screen” at
the end of §9 for the files, the headless evidence and the part left open (a real 1P/2P mode
line belongs with B2’s bindings; the shipped setup picks the AI style instead).
- Bungee **Shade** start screen: `SOUND CLASH BRAWL —` over `PRESS START / CLICK TO CLASH`, then a mode
  select (**1P vs AI** / **Local 2P**), an AI-style picker for the four `SparringController` modes that
  **Y** already cycles in the workshop arena, and the Patois Subtitle on/off toggle that
  `TestHud.toggle_subtitles()` (**V**) already exposes.
- Owner-visible requirement: the title scene boots before `TestArena.tscn`, the three choices live in
  one small autoload/resource, and the arena reads them instead of hard-coding P2 as the Workshop
  Dummy. Esc returns to the title without losing the selection.
- Exit evidence: title → mode select → arena carrying the chosen mode, AI style and subtitle flag;
  keyboard-only navigation; headless boot of both scenes.

**[TODO] B2. Controller support and local 2P bindings.**
- Standard Xbox/PlayStation gamepad mappings (`InputEventJoypadButton` / `InputEventJoypadMotion`) for
  every action the FSM already uses: move, jump, crouch, guard, jab, BOX, tump, upper box, grab, taunt.
- A second keyboard layout (Arrow keys + Numpad) so two players share one Chromebook, P1 keeping
  WASD/`JKLI` and P2 on Arrows/Numpad, with no key claimed by both layouts.
- Owner-visible requirement: the same `p1_*` / `p2_*` action names, device handling kept out of
  `BaseFighter`, hot-plug/reconnect tolerated, and the stick deadzone plus axis signs written down.
- Exit evidence: headless check that every action resolves on both layouts and for a synthetic pad
  event; then a real 2P check on the Chromebook.

**[TODO] B3. Pause and move-list overlay (Esc / H).**
- **Esc** pauses (freezing the fixed-step simulation *and* the beat clock without eating buffered
  inputs); **H** opens the move list without pausing.
- The overlay lists the full set — Jab, BOX, Sparta Kick (`tump`), Upper Box, Mic Defence / Static
  Parry, Grab / Speaker Throw, Skank Taunt — with the 132 BPM on-beat rules and the Crowd Hype Surge
  rules, in Chakra Petch with Bungee headers.
- Owner-visible requirement: read-only, no combat input accepted while open, and no phantom on-beat
  judgement or Hyped damage while the clock is frozen.
- Exit evidence: headless check of the freeze/resume tick budget, a beat-clock rebase after resume,
  and that a pause during startup/active windows resumes into the same state.

**B4. Visual on-beat hit sparks — implemented (2026-11-16).** See decisions item 21.
- Distinct contact bursts: white/gold for a normal contact, vibrant Jamaican green/gold for a contact
  whose **input** was judged on-beat (§9 item 1 — contact quality is judged separately from the beat).
- Owner-visible requirement: built on the existing `ParrySpark` / `_add_spark()` path inside the
  Chromebook caps from §9 item 17 (4 sparks, 16 particles) — no per-hit allocation and no new texture
  group; the burst must stay readable with the sound muted (**M**).
- Exit evidence: headless check that an on-beat contact emits the green/gold variant and an off-beat
  contact the white/gold one, with the live spark count still capped at 4.

**[TODO] B5. Branch consolidation (`stage/sound-clash-sand` → `main`).**
- Merge only after the Chromebook playtest sign-off, not before.
- Owner-visible requirement: history preserved (no squash-rewrite of the sand branch), the TypeScript
  prototype untouched, `/docs` still rebuildable, and the import/headless/export checks re-run on the
  merged tree; record the merge commit in §9.

#### Agent recommendations — additions from this sprint's build work (2026-11-16)

**B6. Round timer and time-out rules — implemented (2026-11-16).** Owner decision: **60 seconds** of
live FIGHTING per round (not the prototype's 90 s, so clashes stay intense and rounds cycle). See
decisions item 20. `RoundController.clock` starts at `round_seconds` each round and drains only in
`Phase.FIGHTING`; on zero `_finish_round_on_time()` gives the round to the higher remaining health under
a `TIME!` banner, and an exact HP tie calls `_replay_round()` — `WHEEL AND COME AGAIN!`, no pip, the
same round number and lighting, clock back to 60. The HUD draws it top-centre between the health bars
(Bungee digits, Chakra Petch `ROUND n` caption, red under 10 s). [TODO] The `TIME!` wording, the
red-under-10 s styling and the 0.05–2.4 s transition timings are agent defaults.

**B7. Fighter push-separation — implemented (2026-11-16).** `TestArena` enforces a shared **64 px**
minimum horizontal gap after both bodies have moved each physics tick: `_physics_process` queues a
deferred `_separate_fighters()` because the arena is the parent node and would otherwise run before the
fighters. The correction splits evenly and lets the speaker-stack walls absorb what one body cannot
take, so a cornered pair still opens a full gap without pushing anyone through a stack. Separation is
skipped while either body is `GRABBED`, `THROWN`, `KNOCKDOWN` or `KO`, and while either body is
airborne — jumps over an opponent, throws, spinbacks and knockdowns pass through cleanly. Positions are
corrected, speeds are not, so walking into an opponent slides you apart instead of stopping dead.
[TODO] 64 px is an agent default; it needs checking against the 96 px grab range and the 60 px body on
the real machine.

**B8. Procedural arcade SFX — implemented (2026-11-16).** `godot/scripts/audio/SfxPlayer.gd` (autoload
`Sfx`) synthesises every cue at start-up with `AudioStreamGenerator`: four voices, 22.05 kHz mono, 0.35 s
buffers — no audio files, no samples, no extra licences and nothing added to the `.pck`. Cues: `hit`
(pitch-swept thud plus noise transient), `hit_onbeat` (the same with a 55 Hz sub-bass punch), `block`
and `clank` (inharmonic metallic knocks), `parry` (gated vinyl-static crackle over a 2.4 kHz ring),
`slam` (808 cone boom), `whoosh` (low-passed noise swell), `airhorn` (detuned saw fanfare on the 100 %
Hype Surge) and `ko` (descending arcade drop). Wiring lives entirely in `TestArena` off signals that
already existed — `strike_resolved`, `static_parry_triggered`, `speaker_slam_triggered`,
`throw_connected`, `throw_broken`, `hype_surge_started`, `died` — so no combat code knows about audio.
**M** now mutes the Master bus (click track and SFX together) instead of pausing the stream, which keeps
the 132 BPM clock running so unmuting never desyncs beat judgement. `clear_buffer()` is never called:
it asserts when no device is mixing, so a voice restarts with `stop()`/`play()`.
[TODO] Every cue is an agent default — none has been listened to, the mix balance is unset, and voice
stealing drops the oldest cue rather than ducking it.

**[TODO] B9. Web loading progress UI and a Chromebook performance readout.** The `/docs` build spends
several seconds on wasm and `.pck` before the first frame with only the bare engine splash screen, and
the 50 MB texture set has never been timed on the real machine. Proposal: a branded Bungee/Chakra
Petch loading screen driven by real download and decode progress, plus a dev-only readout (F3) for
frame time and texture memory so the playtest produces numbers instead of impressions. Exit evidence:
the loading screen advances on a throttled connection, and the readout reports frame time plus memory
while staying out of a release build.

**[TODO] B10. Patois voice-line pipeline.** Every callout is text today because no recorded audio
exists anywhere in the repository; the subtitle pill is the whole delivery. Proposal: when the owner's
lines are recorded, keep the pill as the accessibility layer and drive an `AudioStreamPlayer` from the
same `announce_subtitle()` call site, filing each line under its §8 lexicon entry (Patois verbatim,
gloss in a separate field, no film/TV samples and no generated voice). Exit evidence: one approved
line plays with its subtitle, and the callout cooldown applies to the audio exactly as it already does
to the text.

#### Owner item — Fighter #3 moveset (2026-11-17)

**[TODO] B11. Fighter #3 — Young Selecta's signature moveset (designed by the owner's son).** Full
design, open values and attribution: decisions item 25. Four moves sitting on the four attack keys he
currently shares with every fighter — `J` **Mic Toss** (fast horizontal mic projectile, short cooldown),
`K` **horizontal mic-stand bat swing** (heavy knockback, heavy hitstop, metallic clang), `I` **rising
mic-stand uppercut** (anti-air pop-fly launch), `L` **arcing oversized textbook/dictionary throw** from
the blue backpack (heavy impact, fluttering page particles). Those keys collide with the live `light` /
`heavy` / `tump` / `upper_box` layout and must be resolved deliberately, not overwritten.
- Ordered behind the Feedback pass by the owner: Feedback's combat, blocking, hit reactions and Dancehall
  move attacks (The Bogle, Log On, Signal Di Plane) first, then this, then Lickshot's unique moveset.
- Owner-visible requirement: his four moves read as *his* — the mic, the mic stand and the school bag stay
  the weapons and his names stay the names — and the §1 mic-continuity rule is either satisfied or waived
  in writing.
- Prerequisites that do not exist yet: any player projectile or arc-throw system in `/godot`, a mic-stand
  prop sheet, a book, throwable-page particles, and startup/contact/recovery art for all four moves
  (`assets/sprites/young-selecta/` holds three frames today: `idle`, `thrust`, `slam`).
- Exit evidence: each of the four moves reaches a real active window against a live opponent, both
  projectiles spawn, travel and resolve **through** the existing strike pipeline instead of bypassing it,
  page/flutter particles stay inside their measured budget, and a headless check plus one on-screen look
  confirm the arcs and a landing that respects the y 592 sand line.

**Dependencies worth knowing before picking these up:** B6, B7 and B8 are closed, so the two
combat-feel items now in the plan (B4 sparks and the B3 pause/beat-clock decision) land before the
January 14, 2027 core-mechanics lock (§2, mandatory rule 2). B1 and B3 still wait on B3's pause decision;
B2's P2 layout and B4's mute-readability need the Chromebook in hand; B5 waits on the playtest sign-off,
which is now also the first chance to hear B8's cues and feel B7's separation.

Implementation status: written into `/godot`; **not played**. Until 2026-11-15 the port had never
been opened in an engine. The sand-stage and round-lighting slices were then imported and run headless
in Godot 4.3.stable (no GPU, no audio device, no on-screen look), which proves the project imports
with no script/resource errors and that the stage, shadow, dust, beat-thump, bird and time-of-day
paths execute — not that any of it looks or feels right. No hitbox, guard, beat-window or HUD
behaviour was re-verified, and the port remains unapproved. Details and exact commands: "Sound Clash
Sand Stage integrated" below.

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
| Sound Clash Sand Stage (art + foot dust + shadows + atmosphere + speaker thump + rare bird) | Implemented 2026-11-15 on branch `stage/sound-clash-sand`; headless Godot 4.3 import/run clean; **on-screen playtest [TODO]**. |
| Round-based day → sunset → night lighting | Implemented 2026-11-15 on branch `stage/sound-clash-sand`; headless checks of all three phases, tween and N cycle pass; round-controller driving and **on-screen look [TODO]**. |
| Owner playtest pass: facing, visible CPU strikes, crowd acts, stage lighting, framing, props | Implemented 2026-11-17; headless 4.5 check 49/49; **on-screen look and feel [TODO]**; left-facing frames and multi-frame crowd loops still need art prep. |
| Lickshot four-pose set (stance, high kick, Sonic Clap windup/impact) | Implemented 2026-11-17 (§9 item 27): four keyed 512 px frames wired into `FighterRoster`, the generic smear replaced on K/L, headless 4.5 **58/58**, Web export rebuilt; **on-screen look and motion [TODO]**. |
| Smart Sparring AI modes (P2) | Implemented 2026-11-15 on branch `stage/sound-clash-sand`: 4 modes cycle on **Y**, HUD banner, **G** guard override; headless Godot 4.5 runs pass for every mode; **on-screen/feel playtest [TODO]**. |
| Dancehall crowd line + 100% Hype Surge | Implemented 2026-11-15 on branch `stage/sound-clash-sand`: 6 sliced spectators (Queen centre) + 2 record crates at the stacks, beat bob, FORWARD!/PULL UP! banner, 5 s 1.20× / faster-recovery boost; headless checks pass; **on-screen look and balance [TODO]**. |
| 15-character two-row rotating crowd + contact shadows | Implemented 2026-11-15 on branch `stage/sound-clash-sand`: 9 new slices (pool 15), front/back rows, 12–18 s and 50 %/100 % hype reshuffles, GroundShadow on crowd and crates; headless checks pass; **on-screen look [TODO]**. |
| Family-friendly crowd policy + locked-in move/mechanic roster | Recorded 2026-11-15 in §9 items 12–13 and §8. Documentation only: no move, mechanic, voice line or banner beyond the existing surge banner is implemented. |
| Record Static Parry | Implemented 2026-11-15 on `stage/sound-clash-sand`: on-beat guard negates the hit, +20 hype, 18-tick attacker stun, ParrySpark; headless parry/block checks pass; **on-screen look and tuning [TODO]**. |
| Best-of-3 round lifecycle | Implemented 2026-11-15: RoundController announce → K.O. → rematch, day → sunset → night per round, fighter resets, HUD banners + win pips; headless three-round run passes; **no timer/draw rule, on-screen layout [TODO]**. |
| Chromebook Web export | Implemented 2026-11-15: committed Web preset (GL Compatibility, single-threaded, VRAM compression off) exporting to `/docs`; headless export clean and the build rendered on WebGL2 in a browser; **not yet tried on the 4 GB Chromebook, not deployed [TODO]**. |
| Chromebook crash/freeze safeguards | Implemented 2026-11-15: committed `.import` `size_limit=512` (149.6 → 50.0 MB decoded, pck 10.3 MB) with offset/scale compensation, off-screen effect pre-warm, and 1 bird / 4 spark / 16 particle caps; headless guard checks and WebGL2 boot pass; **on-device timing unmeasured and the 40 MB goal not reached [TODO]**. |
| Grab / throw / tech / speaker bounce | Implemented 2026-11-15: `GRAB`/`GRABBED`/`THROWN` states, 96 px grab, 8-tick throw break, forward 14/+15 and back 12/+18 throws, +4 speaker-stack bounce with `speaker_slam_triggered`, AI grabs a turtling P1 and techs ~55 %; headless chain passes and the Web build rebuilds; **values unplayed, no throw art [TODO]**. |

Next agent: finish the isolated walk review, reconcile asset/engine branches, close the minimal rhythm reference gap, freeze the TypeScript baseline and complete the first Godot port inside Nov 13–26. Then follow Section 2 date gates. Keep costs at zero; preserve the April 21, 2027 target and six-selector commitment while reporting scope risks promptly.

### Smart Sparring AI — headless verification, 2026-11-15

Written into `/godot` on branch `stage/sound-clash-sand`. Engine: **Godot 4.5.stable** headless (no
GPU, no audio device, no on-screen look), imported with
`Godot_v4.5-stable_linux.x86_64 --headless --path godot --import` (clean, 50 assets). Each mode was
then run through a **temporary** harness that instantiated `TestArena.tscn`, stopped the click so
`BeatService` used its wall-clock dev fallback, drove a scripted P1 (walk in → jab/BOX → retreat),
and ticked 480 physics frames (~8 s) per mode. The harness was deleted before the commit; it is not
part of the project. Results:

| Mode | P2 attacks started | Guard ticks | Taunts | P1 HP left | Result |
| --- | --- | --- | --- | --- | --- |
| 0 Workshop Dummy | 0 | 0 | 0 | 100 | pass |
| 1 Counter-Puncher | 5 | 83 | 0 | 34 | pass |
| 2 Riddim Rusher | 4 | 0 | 0 | 48 | pass |
| 3 Spacing & Skank Baiter | 2 | 0 | 3 | 85 | pass |

The **G manual-guard override** was checked separately (mode 2 with `manual_guard = true` → P2
guarding in `IDLE`: pass), and `TestArena.tscn` booted for 150 frames on the Dummy default. No
script, resource, missing-node or illegal-transition warning was printed by any of those runs. The
`--quit-after` main-scene run does print Godot's exit-time "ObjectDB instances leaked / 1 resources
still in use" cleanup notice; the identical notice appears with the pre-change `TestArena.tscn`,
`TestArena.gd` and `TestHud.gd` restored, so it is a forced-quit artefact and not an AI regression.

**Not verified:** frame data, hitbox reach, HUD banner placement or AI feel — nothing was watched on
screen and no mode has been played by the owner. These runs prove the modes tick, guard, punish,
step, attack on the beat and taunt without errors; they do not prove any of it feels right.

### Crowd line + Hype Surge — headless verification, 2026-11-15

Godot 4.5.stable headless; the import is clean apart from the container's missing fontconfig. A
temporary harness instantiated `TestArena.tscn` and asserted: 6 crowd sprites and both crates load
with non-null textures; a synthetic P1 jab resolves 8 damage before the surge and 10 (8 × 1.20)
while it is live; `_add_hype(100)` fires `hype_surge_started`, holds the bar at 100, drives the
crowd (peak 30.6 px of travel) and then resets hype to 0 after the 5 s boost with the crowd settled
and no residual tween. The harness was deleted before the commit and `TestArena.tscn` booted for
150 frames with no script, resource or node errors.

**Not verified:** the on-screen composition — checked only with an offline composite of the stage,
crowd, crates and one idle sprite at the same coordinates and z-order — plus the banner flash,
readability behind the fighters, and the balance of a 5 s 1.20× / faster-recovery window.

### Rotating crowd + contact shadows — headless verification, 2026-11-15

Godot 4.5.stable headless; import clean. A temporary harness on the real `TestArena.tscn` asserted:
15 members splitting 5 front / 6 back / 4 pooled; the Queen at x 640, unshaded and still centred after
36 swaps; the back-row Elder at 0.85 × its scene scale and tinted; a `GroundShadow` on every crowd
member at its own row's y (556 / 516) and on both crates at 592; `rotate_now(2)` swapping members and
emitting `crowd_rotated`; the automatic timer swapping on its own once accelerated to 0.25–0.35 s for
the test; 50 % hype firing `hype_milestone_reached` and reshuffling; and 100 % hype surging both the
fighter and the crowd, holding hype at 100 then resetting it to 0 after 5 s with row counts intact.
The harness was deleted before the commit; `TestArena.tscn` also booted for 150 frames clean.

**Not verified:** the on-screen look — the two-row composition was checked only with an offline
composite of the stage, the 11 visible members, the crates and an idle fighter at the shipped
coordinates, scales, tint and z-order. The shipping 12–18 s cadence was not waited out (the test
accelerated it), and none of it has been played.

Re-verified 2026-11-15 with the §9 owner-decision update applied (no runtime change): the import is
clean, the same harness passed again (15 members at 5/6/4, 36 swaps, Queen still at x 640, shadows at
556/516/592, the 50 % and 100 % hype paths) and `TestArena.tscn` booted for 150 frames.

### Record Static Parry + Best-of-3 rounds — headless verification, 2026-11-15

Godot 4.5.stable headless; import clean. Temporary harnesses on the real `TestArena.tscn` asserted:
**parry** — an on-beat guard press followed by a jab resolved `parried` with 0 damage, exactly one
`static_parry_triggered`, one `ParrySpark` spawned, +20 hype and the attacker left in `HITSTUN`; the
same jab against an off-beat guard stayed an ordinary block (2 chip damage, defender in blockstun).
**rounds** — Round 1 announced `ROUND 1 — AFTERNOON CLASH` on phase 0 with input locked; a K.O. gave
the `K.O.!` banner and 1-0, then Round 2 `ROUND 2 — SUNSET HEAT` on phase 1 with both fighters back
at 100 hp and their start positions; a P2 win levelled 1-1 and opened `FINAL ROUND — LATE-NIGHT
DUBPLATE` on phase 2; a third K.O. reached `MATCH_OVER` with `WHEEL AND COME AGAIN!`, after which the
match restarted at Round 1, 0-0, phase 0. Both harnesses were deleted before the commit, and the
shipping scene booted 200 frames clean.

**Not verified:** no engine render, so the banner boxes, win pips and parry spark were never seen;
the ±70 ms parry window, +20 hype and 18-tick stun are unplayed; and there is still no round timer,
time-out or draw path.

### Chromebook Web build — export verification, 2026-11-15

Godot 4.5.stable exported the **Web** preset headless (`--export-release`, exit 0) into `/docs` with no
export errors. Served from a plain `python3 -m http.server` (which returns the correct
`application/wasm` MIME type) and opened in a browser: `index.wasm` and `index.pck` both returned
200, there were **no script or engine errors** in the console (only the expected autoplay-policy
audio warning and a benign WebGL `ReadPixels` performance notice), a **WebGL2 context was live**, and
the arena, crowd, HUD and both fighters rendered inside the letterboxed frame. Build sizes: wasm
38.1 MB, pck 17.1 MB, `/docs` 53 MB.

Runtime texture budget, measured from the two scenes: **57 referenced PNGs = 149.6 MB decoded RGBA**
(22.6 MB as stored PNGs) load with `BaseFighter.tscn`; that is the bulk of the tab's texture memory,
so the large 1024×1536 / 1536×1024 fighter frames matter far more than the download size. The nine
art files no scene references (a further 62.8 MB decoded) are left out of the pack by the preset's
exclude filter. `art-source/` and every original PNG are untouched and no texture was resized.

**Not verified:** the build was never opened on the actual 4 GB Dell Chromebook or
`editor.godotengine.org`, GitHub Pages was not enabled, nothing was deployed, and the 149.6 MB figure
is computed from the source image dimensions rather than measured inside the browser tab.

### Chromebook safeguards — verification, 2026-11-15

Temporary headless harness on the real `TestArena.tscn`: the arena loads 59 textures totalling
**50.0 MB** decoded (from 149.6 MB); every `CPUParticles2D` reports amount 16; the pre-warm nodes are
gone two frames later; eight rapid parries leave exactly **4** live `ParrySpark`s; six rapid bird
triggers leave exactly **1** bird in the air; and the compensation keeps the authored sizes — P1's
idle renders 255.8 world px tall (a 3× capped 341 px frame at 0.75) and the pinned Queen 123.6 px,
both matching the pre-cap build. The harness was deleted before the commit and `TestArena.tscn`
booted 200 frames clean. The Web export rebuilt headless (exit 0, `.pck` 10.3 MB, `/docs` 47 MB) and
the browser run showed no script or engine errors, a live WebGL2 context, and the same fighter/crowd
sizes and layout as the pre-cap build.

**Not verified:** nothing was measured on the actual 4 GB Chromebook — no frame timings, no tab
memory reading, no long demo session — so the pre-warm is a structural fix rather than a demonstrated
stall removal.

### Grab / throw chain — verification, 2026-11-15

Temporary headless harness on the real `TestArena.tscn`, all six cases on the shipping scene: a grab
inside 96 px held a **guarding** P2; a Grab press inside the 8-tick window fired `throw_broken`, dealt
**0 damage** and shoved the fighters apart; a neutral hold threw forward for **14 damage, +15 Hype**,
`throw_connected(&"forward")`, the victim leaving at ~478 px/s and reaching the knockdown pose; a throw
from x 1150 into the right stack fired `speaker_slam_triggered` with side +1, total damage **18**
(14 + 4) and bounced the body back at −220 px/s; holding back threw for **12 damage, +18 Hype**,
`throw_connected(&"back")`, and dropped the victim behind the attacker (760 → 651, i.e. 700 − 46);
and in Mode 1 the AI grabbed a turtling P1 on its own and broke **5 of 10** scripted grabs. Harness
deleted before the commit; `TestArena.tscn` booted 200 frames clean; the Web export rebuilt headless
(`.pck` 10.3 MB) and the browser run had no script errors, a live WebGL2 context, and the updated
`U grab/tech` legend.

**Not verified:** no throw of any kind was watched on screen, and none of the damage, Hype, timing or
arc values have been playtested — they are hand-set defaults.


### Push separation, 60-second clock and procedural SFX — verification, 2026-11-16

Temporary headless harness on the real `TestArena.tscn` (deleted before the commit). **Separation:**
two fighters placed 8 px apart opened to exactly **64.00 px** with the midpoint held at 504.00; a pair
pinned against the left stack opened to **64.00 px** with the pinned body at 70.06 — inside the wall,
not through it; bodies in `GRABBED`, `THROWN`, `KNOCKDOWN` and `KO` each kept their 8.00 px overlap; and
an airborne body was not pushed sideways. **Clock:** the round started on 60.00 s, still read 60.00
after 0.2 s of announce, drained 60.00 → 59.70 in 0.3 s of live play, awarded the round to the higher
health (80 v 40) under `TIME!`, and on an exact 50 v 50 tie showed `WHEEL AND COME AGAIN!`, awarded
**no pip** (wins stayed `[1, 0]`) and replayed round index **1 → 1** with the clock back at 60.00.
**SFX:** all nine cues synthesised non-silent buffers with peaks inside [-1, 1] — hit 3528 frames /
0.91, hit_onbeat 6174 / 1.00, block 2205 / 0.41, parry 3969 / 0.77, slam 12127 / 1.00, whoosh 5292 /
0.39, clank 4851 / 0.71, airhorn 18742 / 0.61, ko 20947 / 1.00 — each of the seven combat signals
routed to its own cue, and **M** muted both the Master bus and the cue queue, refusing new cues until
unmuted. A 240-frame boot printed no script errors beyond the known exit-time resource notice; the Web
export rebuilt headless (exit 0, `.pck` 10.6 MB, `/docs` 47 MB) and the browser run drew the
`59 / ROUND 1` clock between the health bars with the fighters separated.

**Not verified:** nobody has heard any of these cues — headless Godot has no audio device, so
"non-silent, unclipped buffers" is arithmetic, not a listen. Separation was not felt in motion (walking
into an opponent, being cornered, grabbing at 96 px), and the browser run proved the clock's placement
but not that a full 60 s round reaches zero on a real tab. The silence of a muted build was verified by
bus state, not by ear. All three need the Chromebook playtest.

**Fixed during that run:** `AudioStreamGeneratorPlayback.clear_buffer()` asserts when no audio device is
mixing (headless), and `AudioStreamPlayer.set_stream_paused(true)` is refused while stopped — the mute
path now mutes the Master bus and a recycled voice restarts with `stop()`/`play()`.

### Arcade typography + callout subtitles — verification, 2026-11-15

Temporary headless harness on the real `TestArena.tscn` (deleted before the commit): all four faces
load as real `FontFile`s reporting their own family names — `Bungee`, `Bungee Inline`, `Bungee
Shade`, `Chakra Petch` — so nothing fell back to `ThemeDB.fallback_font`, and a 200-frame boot
printed no `fallback` / `unable to load font` warning. The subtitle state machine passed: the first
`announce_subtitle()` was accepted, a second one inside the 4.0 s cooldown was refused without
replacing the live line, the pill was gone 2.0 s after its trigger and the cooldown read 0.0 s at
4.2 s; `static_parry_triggered`, `taunt_finished(true)`, `speaker_slam_triggered` and
`hype_surge_started` each produced their exact Patois line; an off-beat `taunt_finished(false)`
stayed silent; the **V** toggle refused callouts while off and cleared the pill; and re-enabling kept
a single slot, the newest line replacing the older one. The Web export rebuilt headless (exit 0,
`.pck` 10.6 MB, `/docs` 47 MB) and the browser run drew the Bungee fighter tags and the Chakra Petch
legend and mode labels with no script errors.

**Not verified:** no callout pill was caught on screen (the browser taunt attempts landed off-beat
and headless Godot cannot draw), the banner/Shade faces and the outline weight were not judged on the
actual Chromebook, and none of the sizes or timings have been playtested.


### Newer knee-lift BOX in main handoff — November 14, 2026 (Toronto)

Garfield requested Feedback’s newer foot-off-the-ground BOX enter the GitHub flow. Root `FREEBUFF-HANDOFF.md` and ten exact source/reference media blobs from review commit `9eaeae74144e8a453034aa3ff2cf33014dd63511` are now delivered on main under `artifacts/sound-clash/art-source/feedback/box-handoff-2026-11-13/`. Selected movement: LEFT lean comparison, knee lift → stride → planted windup → BOX → follow-through. Freebuff owns corrections, preparation, verification and integration; return a preview for Garfield. First/last-frame appearance, mic-hand and cable continuity remain open; latest two-loop clip is UNAPPROVED. Verified repository source paths and exact blob reuse; no runtime change or gameplay tests. No broad merge of the review branch. Next: Freebuff fetches main and follows the root handoff while preserving local work.


### Additional Feedback animation requests — November 14, 2026 (Toronto)

Garfield requested `lightah` frames, skank frames, reverse back hand BOX, and a Sparta kick to the stomach, all with the same Feedback character. See `FREEBUFF-HANDOFF.md` → Additional Feedback frame requests for preparation/continuity criteria. Freebuff inventories/reuses existing sources, prepares missing candidate frames and returns previews. Preserve character identity, declared mic hand, continuous jacket-origin cable, Wallabees, frame anchors and shared grid. Reverse BOX stays distinct from Upper Box; do not mirror art to create it. Kick gameplay parameters are unspecified. Status: recorded request only, no new frames or runtime implementation; no gameplay tests applicable. Existing knee-lift BOX handoff remains active.


### Five-move review studies created — November 14, 2026 (Toronto)

Owner assigned ChatGPT creation and added a microphone `squeeeek` defence. Five six-keyframe animated studies now exist: Lightah, skank, reverse backhand BOX, Sparta stomach push kick, and mic-squeak guard. Root `FREEBUFF-HANDOFF.md` at `187c284` records exact owner-access video/player/source-pack links, reference identity, checks and limitations. Status: UNAPPROVED review previews, not smooth final animations or gameplay assets. H.264/AAC export and player syntax verified; no runtime tests. Same right-hand mic setup across this batch; cross-pack canonical hand remains open. Next: Garfield reviews, ChatGPT corrects art/motion and prepares in-betweens; Freebuff handles approved repo preparation/integration. No receipt or implementation by Freebuff is claimed.


### Owner move corrections — November 15, 2026 (Toronto)

Lightah must use existing massive-flame reference and jump-skank; reverse backhand BOX means spinning around into an open-hand backhand, superseding the stationary v1 interpretation. Garfield likes the Sparta kick direction; keep its drawings. Rear-facing two-finger skank original recovered for Freebuff (`libfile_95d3f14281248191821f8825ae8ef570`); preserve original but do not propagate obsolete back pockets/floor cable. Same Feedback appearance and mic/cable continuity mandatory. Root `FREEBUFF-HANDOFF.md` details source identities, screenshot identification and v2 status. V2 Lightah/spinning BOX are new six-keyframe review studies, not final approved animations; other three studies unchanged. No gameplay changes or runtime tests. Next: owner reviews v2, then targeted continuity fixes/in-betweens and Freebuff preparation.


### Sound Clash Sand Stage integrated — November 15, 2026 (Toronto)

Owner uploaded the 1672 × 941 beach sound-yard background to the root of `main`
(`3DFAD58B-2779-4DA7-B37E-9CF15C480341.png`) and asked for it to become the arena background plus a
first pass of stage mechanics and polish, recorded in §9 Owner Decisions Log item 7.

**Branch note, stated plainly:** `main` does not contain `/godot`. The Godot project —
`TestArena.tscn`, `BaseFighter`, `BeatService` — lives on `review/feedback-appearance-consistency`
(`9ad9348`), 39 commits ahead of `main` and never merged into it. This work is therefore committed on
**`stage/sound-clash-sand`**, branched from that review tip and merged with the owner's upload commit
so the source art came along. Nothing was force-pushed, no branch was rewritten, and `main` and the
review branch were not modified. The owner decides when `/godot` lands on `main`.

**Art.** Original moved, byte-identical, to
`art-source/stages/sound-clash-sand/sound-clash-sand-stage-1672x941.png` (root copy removed); notes
and the measured floor data are in that folder's `README.md`. Export:
`godot/assets/stages/sound_clash_sand_stage_1280x720.png` (1280 × 720, Lanczos, no crop, no retouch).
Sand yard measured at source row 660 → world y ≈ 505 in the export, so the floor line stays y = 600
with sand behind and in front of the fighters. Speaker thump centres from the dark-pixel centroids of
the subwoofer cabs: (169, 411) and (1099, 425).

**Scene.** `Stage` (z −10) · `Atmosphere` + `SunGlow` (z −9, gradient resources, drawn behind the
fighters so they are never tinted) · `SpeakerRings` (z −8) · sand splats (z −6) · `WindMotes`
(z −5) · per-fighter `Shadow` (z −2) and `Dust` (z −1) · fighters (0) · splatter on a hit fighter
(z 6) · bird (z 20). Because the background is one 1280 × 720 layer, `TestArena.gd` now clamps camera
zoom to **1.0–1.6** and its position to the stage rectangle; zooming in only shrinks the visible
area, so the art always covers the view and the sand line cannot drift. This is a framing change, not
a combat change — walk speed, animations, hitboxes, guard, beat windows and hitstop are untouched.

**Mechanics.** New scripts are `scripts/stages/{BirdHazard,GroundShadow,SpeakerPulse,StageSplat}.gd`;
`BaseFighter.gd` only gained presentation hooks (`_puff`, `_emit_landing_dust`,
`receive_splatter`) and the two cosmetic children — no FSM, damage, hit-resolution or beat-judgement
logic was altered. Dust fires on walking footfalls (every 8 ticks), jump takeoff, landings above
260 px/s and `17_seated_landing` knockouts. `receive_splatter` is a 12-tick flinch with no damage and
is refused when downed or airborne, so the drop then falls to the sand. The bird and every splat are
drawn with primitives — no invented art assets, no crowd sprites.

**Checks actually run** — Godot **4.3.stable.official** (Linux x86_64, headless; binary kept outside
the repository; temp harness deleted after the run):

```bash
godot --headless --path godot --import
godot --headless --path godot --quit-after 180        # main scene, no errors
```

Results: import and scene load clean (no script or missing-resource errors); `Stage` reports
1280 × 720 at z −10; a scripted run spawned the bird, which flew and dropped a splatter that hit the
standing dummy (splat parented to `P2` at head height, both fighters still at 100 health); a second run
was dodged and produced a sand decal at (820, 600); a driven walk set `dust.emitting = true` at
`amount` 11 and the shadow tracked the fighter at y = 600; `_on_beat` set the thump and started the
speaker rings; camera zoom clamped at 1.6 with the fighter on the floor.

**Not verified, and not claimed:** no GPU render and no on-screen review — colour, gradient strength,
dust/mote density, legibility of the centre lane, thump feel, bird readability and the 5 %/15 s rate
are all unjudged. The engine pin, renderer and export path remain [TODO]. Generated `*.import`
sidecars from the headless import were not committed (the repository still carries none; Godot
regenerates them on open).

**Next:** Garfield opens `/godot` on the target device, presses **B** a few times and plays a round,
then tunes or rejects the hand-set stage values above. Fixing `TestArena.gd`'s camera clamp is
reversible if the tighter framing is not wanted.


### Round-based day → sunset → night lighting — November 15, 2026 (Toronto)

Same branch and commit series as the sand stage (`stage/sound-clash-sand`). Recorded as §9 Owner
Decisions Log item 8.

`TestArena.tscn` gained two nodes and no art: **`TimeOfDay`** (`CanvasModulate`, world canvas only —
the HUD `CanvasLayer` is never tinted) and **`Floodlight`** (a radial warm gradient sprite with an
additive `CanvasItemMaterial` at z 5, i.e. above the fighters, so its soft bloom restores warmth and
contrast over the centre lane at night instead of hiding them).

`TestArena.gd` gained `TIME_PHASES` (Afternoon Sun / Golden Hour / Late-Night with tint, floodlight
aim and sun-glow aim), **`set_time_of_day(phase, duration = 3.0)`** — one parallel `TRANS_SINE`
`EASE_IN_OUT` tween over the tint, the floodlight alpha and `SunGlow`'s alpha, killed and replaced if
re-triggered, applied instantly at `duration <= 0` — plus `cycle_time_of_day()`, `time_of_day_phase()`,
`time_of_day_name()`, and the **N** key. Round 1 is applied on `_ready`. `TestHud.gd`'s legend now
lists `N time of day`.

**Checks actually run** (Godot 4.3.stable headless, temp harness deleted): phase 0 = tint
`(1, 0.98, 0.94)`, floodlight 0, sun 1; `set_time_of_day(2, 0)` = `(0.48, 0.55, 0.8)`, 0.34, 0.22;
a 0.25 s tween from night to phase 1 landed exactly on `(1, 0.78, 0.58)`, 0.1, 0.6; `cycle_time_of_day()`
advanced 1 → 2 and the name followed. The full arena then ran 240 headless physics frames with no
script, scene or resource errors.

**Not verified:** no GPU render — the night tint, floodlight strength, sunset warmth and whether the
lane still reads at phase 2 are all unlooked-at defaults. No round actually drives the phases yet:
the workshop arena has no round lifecycle, so this is an API plus a test key, not a working
"Round 2 turns orange" rule. Wiring `set_time_of_day(round - 1)` into the round controller (and
deciding whether the 3 s fade plays between rounds or under the round intro) stays [TODO].

**Note for whoever writes the next `.tscn` by hand:** the text scene format needs 4-component
`Color(r, g, b, a)`; a 3-component one is a hard scene parse error (found and fixed here), unlike
GDScript where `Color(r, g, b)` is fine.

**Next:** owner playtests **N** through all three phases on the target device and rules on tint
strength and floodlight amount before any round controller is wired to it.

### Playable roster #2/#3 and the arcade title screen — November 16, 2026 (Toronto)

`stage/sound-clash-sand`. `freebuff/scr-crowd-stage` was merged in first because the Record Static
Parry, grabs / directional throws / throw breaks / speaker-stack bounces, the 60-second round clock,
the four-mode Smart Sparring AI and the Chromebook Web export preset all lived on that branch and
not on this one. Backlog item **B1 is closed** for the AI path; see the note on the B1 entry.

**Owner uploads, 2026-11-16.** Four of the twelve files uploaded to `main` are fighters; the other
eight are crowd/dance sheets and a reference still and stay untouched at the repository root.
The originals were moved with `git mv` and no byte was modified:

| Upload | Now at | Role |
| --- | --- | --- |
| `06BF8997-254D-4975-BE48-B69AF05A3DC4.png` | `art-source/fighters/dubplate/dubplate-selector-portrait_original.png` | Fighter #2 portrait |
| `8204ED3A-0BEC-4F86-B9B7-A0A9F9787230.png` | `art-source/fighters/young-selecta/01_idle-backpack_original.png` | #3 idle |
| `69CDB409-52C0-4889-94FC-45C8D1926B98.png` | `art-source/fighters/young-selecta/02_boom-mic-thrust_original.png` | #3 jab / BOX |
| `IMG_6546.jpeg` | `art-source/fighters/young-selecta/03_mic-stand-slam_original.jpeg` | #3 heavy / upper |

`art-source/fighters/prep_fighter_art.py` is the reproducible slicer: edge-seeded flood fill for the
studio backdrop (white or the Dubplate vignette), big enclosed pocket removal, white-keyline trim,
island drop, 1 px erosion plus 0.5 px feather, crop to the alpha bounding box, then downscale to the
512 px cap. `prep-report.json` records crop box, sole row, sole centre, offset and downscale per
frame. Outputs are `godot/assets/sprites/dubplate/portrait.png` and
`godot/assets/sprites/young-selecta/{idle,thrust,slam}.png`. All four `.import` files carry
`process/size_limit=512`; because the processed frames are already ≤512 px, their
`anim_source_max` is 512 and the existing `_import_cap_ratio()` compensation resolves to 1.0, so no
scale is applied twice.

**Dubplate cut-out correction, 2026-11-16 (Freebuff).** The first pass kept the portrait's painted
cast shadow: the mic cable closes a loop around it, so the edge-seeded fill could never reach that
backdrop, and the portrait shipped with a large dark slab behind the mic hand. The pipeline now
clears such a pocket with a gradient-limited growth seeded inside it (`pocket_seeds`), drops any
remaining flat-backdrop fragment by median colour plus low deviation (never by single pixels - a
per-pixel backdrop test punches holes through the trousers' shadow tone), and re-seals the art's own
enclosed flecks smaller than 2,000 px. Regenerated output is 369x512; `FighterRoster`'s Dubplate
`anim_offset` moved from `(-124.2, -255.0)` to `(-137.8, -255.0)` because the crop changed, and
`docs/` was re-exported. The 27 headless checks were re-run after the change and still pass. The
owner's original upload is unchanged, and this is still one static placeholder portrait, not an
animation set.

**Roster** (`godot/scripts/fighters/FighterRoster.gd` — data only, one shared FSM):

| Key | Name | Walk | Reach | Body | Frames |
| --- | --- | --- | --- | --- | --- |
| `feedback` | FEEDBACK | 220 | standard | 60×160 | the existing 17-pose pack in `BaseFighter.tscn` |
| `dubplate` | DUBPLATE | 205 | standard | 62×162 | one portrait, reused by every state |
| `young_selecta` | YOUNG SELECTA | 250 | **+25 px** on every attack | 52×131 (82 %) | idle / thrust / slam mapped onto the existing animation slots |

* Adult fighters render 121.75 px tall (Feedback idle: 487 px × 0.25). Young Selecta is scaled
  to 82 % of that (≈99.8 px), per the owner's kid-prodigy direction; his hurtbox follows the
  drawing, so his spacing is genuinely shorter rather than cosmetically so.
* The +25 px boom-mic reach grows each hitbox forward only: the near edge stays put, so the spacing
  change does not move the art or the startup timing.
* `BaseFighter` gained `fighter_key`, `apply_fighter_profile()`, per-instance
  `anim_offset` / `anim_scale` / `anim_source_max`, and `_apply_reach_bonus()`. No state machine,
  frame data, parry, grab or throw logic is duplicated per fighter. Nothing mirrors art (`flip_h`
  is still never set).

**Title screen (B1).** `godot/scenes/TitleScreen.tscn` is now the main scene: a Bungee Shade
`SOUND CLASH` / Bungee Inline `BRAWL` splash with a blinking `PRESS START / CLICK TO CLASH`, then a
Character & Match Setup panel with four rows — P1 fighter, P2 opponent, AI style (Dummy /
Counter-Puncher / Riddim Rusher / Spacing Baiter) and the Patois subtitle toggle. Up/Down selects,
Left/Right changes, Enter fights, V toggles subtitles, Esc goes back to the splash. The choices live
in the `MatchSetup` autoload; `TestArena` applies them, shows the roster names in the health bars,
and **Esc returns to Character Select with the selection intact**. **Y** still cycles the AI style
mid-match and **V** still toggles subtitles in the arena.

Files: `godot/scripts/MatchSetup.gd`, `godot/scripts/fighters/FighterRoster.gd`,
`godot/scenes/TitleScreen.tscn`, `godot/scripts/ui/TitleScreen.gd`, plus edits to
`BaseFighter.gd`, `TestArena.gd`, `TestHud.gd`, `project.godot` and the rebuilt `docs/`.

**Checks actually run** — Godot 4.5.stable.official (876b29033), headless, templates installed
locally (never committed; `.tools/` is ignored):

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" docs/index.html
```

`tools/headless_roster_check.gd` prints 27 checks and ends `ALL CHECKS PASSED`: title scene boots as
the main scene, MatchSetup defaults and roster cycling, the arena applies both fighters and the AI
style / subtitle flag, Dubplate's frames build and render at the adult scale, Young Selecta walks at
250 px/s with a 109 px (84 + 25) jab box and a 131 px hurtbox, the AI drives the shared FSM through
several states in 240 physics ticks, no `flip_h`, and Esc returns to TitleScreen in the setup phase
with the selection kept. The Web export completed and `docs/index.pck` grew from 10.65 MB to 11.2 MB
with the new sprites included.

**Not verified — no render happened.** This environment has no display, GPU or Xvfb, so nothing was
looked at on screen: the title layout, the 82 % kid height, the per-frame baselines and how much of
the mic-stand prop is worth keeping in frame are all arithmetic, not eyes. Dubplate has a single
portrait (every state reuses it) and Young Selecta has three poses (no walk, guard, hit or KO art);
their mic-hand and cable continuity has not been audited against §1. Owner approval of the new art
is likewise outstanding. A real 1P/2P mode line and gamepad/numpad bindings stay under B2; the pause
and move-list overlay stays B3.

**Next:** open `docs/index.html` (or the editor) on the target device, play each fighter against each
AI style, and rule on proportions, spacing and whether the stand prop reads at gameplay size.

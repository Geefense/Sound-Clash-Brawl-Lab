# Sound Clash Brawl — Master Blueprint

Last updated: 2026-11-19. Owner and final creative approver: Garfield Connell.

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

**Other concepts:** **Lickshot is now Fighter #2's display name** (renamed from Dubplate, 2026-11-17 — §9 item 26); `Disc Jock Lickshot` and `Booyaka Lickshot` stay recorded alternates and the owner says the name may still evolve. The off-screen selecta record-theft gag belongs to Fighter #2 accordingly. The Godot migration gate for Fighter #2 is passed — he is in the roster with his own four-pose set since 2026-11-17 (§9 item 27): mic stance, high kick, Sonic Clap windup and Sonic Clap impact. **Working name pool for the future roster (owner, 2026-11-17; expanded 2026-11-19): FL!NG STONE, RUM PUNCH, SKY JU!CE** — the on-screen spelling under the I → ! rule (§9 item 32); their internal ids would stay clean (`fling_stone`, `sky_juice`) — **joined on 2026-11-19 by POPPY SHOW, SUGAR KANE and JUNE PLUM** (owner direction; Sugar Kane and June Plum are female fighter name candidates — the first female slots in the pool). Working names only, with no slot assigned and no design implied (§2, §9 items 26, 32 and 38).

### Owner clarification — cross-animation consistency (2026-11-13)

Garfield is the visual lead and final visual approver. The same slim Feedback, fitted trousers, Clarks Wallabee construction/size, hat/hair, face concealment, one gold tooth, microphone and cable setup must carry through idle, walking, attacks, defence, hit reactions, falling and KO. Approving a movement rhythm does not approve appearance drift or automatically approve other frames.

**Cable origin: inside the jacket.** This owner instruction supersedes earlier pocket-origin concept descriptions for the current continuity pass. Maintain a connected route from the microphone, through any established forearm wrap, into the jacket; an entry can be occluded by clothing, but it must be spatially plausible. No dangling disconnected plug, unexplained endpoint, duplicated cable, hand switch, disappearing mic, or topology change when walking transitions into attacks/guard/falling. Retraction and slack must follow the same setup. Do not treat the current dangling-connector walking candidate as final. Cross-set anatomical mic handedness still needs reconciliation against the approved source pack; do not solve this by silently mirroring art.

**Idle cable approval — November 13, 2026:** Garfield approved `cable-candidates/01_idle-jacket-entry-v1.png`, preferring its clean concealed treatment over v2's more explicit visible route. The source remains inside the jacket, but the cord does not need to visibly show where it goes unless the action requires it. Do not add exposed cable merely to demonstrate topology. Use v1, not v2, as the approved idle-cable reference; this does not approve every other character detail or pose. Keep original files and both candidates. Next narrow batch: cable-only candidates for 08_block and 12_backhand_windup/13_box_palm/14_followthrough, then review against v1 before propagation. Preserve mic hand, pose, clothing, shoes and anchors; record existing hand/design failures separately rather than silently fixing them in the cable pass.

**BOX cable approval — November 13, 2026:** Garfield approved `12_backhand_windup-cable-v2.png` with the lead entering the sleeve and `14_followthrough-cable-v2.png` with the return around the arm. This approves those cable treatments only; existing cross-pose handedness and character-detail issues remain separate. Do not replace these approved routes with the earlier open-air cut endpoints.

**Optional BOX leg-lift concept — November 13, 2026:** Owner proposed borrowing the right-knee lift/weight transfer of a left-handed pitcher, not the actual baseball throwing-arm motion, to heighten the BOX windup and follow-through. Test one isolated pose first (right knee raised, left support foot planted), preserving the established mic/cord and attack identity. Do not overwrite the current windup, change combat timing or add a full sequence automatically. This is a candidate idea, not an approved replacement or committed launch-scope expansion.

**Clarks: match approved artwork, not a new shoe design.** Tan suede Wallabees must retain their approved moccasin/apron seam, toe shape, lacing, crepe sole, size and proportions through all poses. An isolated improved shoe redraw is only a candidate until compared with the existing pack. Do not bulk-regenerate the approved pose pack or replace files to match an unapproved new candidate.

**Preserve work and audit before replacement.** The existing 17-pose asset pack was re-located on `assets/feedback-transparent-poses`; manifest and README inspected, not a fresh full pixel audit. Its README explicitly says the cable is baked into poses and acknowledges detail drift. Imported assets are recoverable/versioned, but this does not make correction automatic or free of rework. Keep originals and anchors, make a comparison inventory by pose, and apply only necessary local repairs. Recheck idle → walk → BOX windup/contact/recovery → guard → hurt/landing/KO as transitions, not only isolated illustrations.

**Current walk approval:** owner approved the four-pose swing–bop movement reference at approximately 132 BPM with the rear free-arm swing. Added neutral-arm return pose was rejected for limp-looking arm and rushed timing. Appearance consistency remains open: cable origin/continuity, unified slim proportions, Wallabee matching and exactly one gold tooth. Recent generated tooth edits still show excess gold and are not approved. Review videos/candidates created in this chat have not been transferred into this repository by this update. No runtime or asset correction is claimed.

### Core creative identity — permanent manifesto (2026-11-19)

The owner's permanent creative direction is recorded in `artifacts/sound-clash/SOUND_CLASH_CULTURE.md` (§9 item 37). It is the standing reference for every future development, character, animation, sound and gameplay decision, and it states the foundation this section summarises: **Sound Clash Brawl is an original fighting game built around authentic Jamaican sound clash culture — not a generic fighter with reggae aesthetics pasted on top.** Competing sound systems, selectors, MCs, exclusive dubplates, DJ tags, musical strategy, crowd participation and intense rivalry are the base layer. Every fighter is their own sound system, and the objective is to outclass, embarrass, overpower and defeat the opposing sound through superior ammunition, performance, timing and crowd response. Fighters carry different generations of that history through fashion, swagger, movement rhythm and performance — Kangol and bucket hats, gold chains, long button-up shirts, Rasta mesh string vests, corduroy and olive cargo pants, Travel Fox, Clarks Wallabees, early-2000s streetwear and contemporary dancehall fashion — drawing research inspiration from Stone Love, Bodyguard, Silver Hawk, Bass Odyssey and Mighty Crown without implying affiliation. Established designs (Feedback, Lickshot, Likkle Moore — shown on screen as L!CKSHOT and L!KKLE MOORE under §9 item 32) stay consistent unless the creator explicitly approves a change, including the mic-hand, jacket-origin cable, Wallabee and one-gold-tooth rules above. Animation stays creator-led: the owner and the creative AI tools approve original walks and pose references first and Freebuff does not invent a character's initial walk. **[TODO] Cultural direction is not implemented mechanics:** echoing character DJ tags, a "Plenty of Dubs" bass-dizzy stun with a tune-fi-tune counter, musical-note swing trails, 2.5D rim light and impact flashes, Hype-reactive and toppling speaker stacks with an "UNPLUG THAT SOUND!" finish, and "Lightah!" crowd-judge finishes are recorded ambitions only (§9 item 37); nothing of that kind exists in `/godot` today.

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

Roster slots: #1 Feedback; #2 **L!CKSHOT** on screen, key `lickshot` (renamed from Dubplate on 2026-11-17, §9 item 26; I → ! styling rule, §9 item 32 — the name may still evolve); #3 **Likkle Moore**, on screen **L!KKLE MOORE** (renamed from Young Selecta on 2026-11-19, §9 item 35; the roster key `young_selecta` and the sprite folder stay unchanged, and the name may still evolve) (§9 items 22–25); #4–#6 **[TODO]** assign final names/order from the owner's working **name pool: FL!NG STONE, RUM PUNCH, SKY JU!CE** (2026-11-17, styled per §9 item 32), **expanded 2026-11-19 with POPPY SHOW, SUGAR KANE and JUNE PLUM** (owner direction; Sugar Kane and June Plum are female fighter name candidates — §9 item 38). Those six are working names, not assignments: nothing says #4 is Fling Stone, and a name is not a design — do not build a fighter from a name alone or treat the pool as final. The owner named #1–#3 explicitly; #4–#6 remain open. #7–#8 remain optional.

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

### Character & art prompt templates — locked (2026-11-19)

`artifacts/sound-clash/prompt-templates/README.md` holds the locked, copy-pasteable image-generation
appearance blocks for every fighter, so a character description is never rewritten from scratch:
**Feedback**, **L!ckshot** and **Likkle Moore**, each with its outfit, props, declared mic hand and the
"pure #FFFFFF background, zero floor shadow" output rule. Paste the character block verbatim and append
only the pose line. Registered here and in §9 item 36. Documentation only: it approves no art, and a
generated frame still goes through background keying, the 512 px cap, the y 592 floor alignment and the
owner's visual review before it is wired.

### Design documents stay beside the art, never inside the build (2026-11-19)

The permanent creative manifesto lives at `artifacts/sound-clash/SOUND_CLASH_CULTURE.md` (§1, §9 item 37),
alongside the other design records under `artifacts/sound-clash/` and the prompt templates registered
above. Do **not** copy Markdown documentation into `/godot` or `/docs/`. `/docs/` is reserved strictly for
the exported WebGL2 game (`index.html`, `index.js`, `index.wasm`, `index.pck` and their runtime
assets), rebuilt with `--headless --path godot --export-release "Web" ../docs/index.html`; a design
document added there would ship as a stray asset in the playable build. The one exception this section
already mandates is `godot/AGENTS.md`, which stays a byte-identical mirror of this root file and must be
refreshed whenever this document changes.

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
| `PULL UP!` | The second half of the owner's `FORWARD! / PULL UP!` surge callout (recorded in the 2026-11-20 2.5D brief, §9 item 38): wheel the dub back and run it again. `TestHud` has shipped it in the 100 % Hype banner since item 10; the 2.5D pass (§9 item 41) rides its camera punch and comic impact frame on that same banner, leaving the subtitle to the rotating Patois pool (item 38). |
| `WHEEL AND COME AGAIN!` | Shouted banner/voice form of the existing `wheel and cum again`. A separately recorded capitalization variant — do not normalise the two into one. |
| `BIG TUNE!` | Owner's family-friendly crowd/hype callout. Implemented as the rotating Patois subtitle on a Record Static Parry (2026-11-19, §9 item 38); voice delivery still unset. |
| `WHOLE-AWN-DEH!` | Owner gloss: “Hold on a second!” Owner-approved callout added 2026-11-19 (§9 item 38) and wired as a Patois subtitle on the Record Static Parry and on a throw break — the moments the tune gets interrupted. Preserve the spelling and the exclamation. |
| `PLAYAH NEX TUNE!` | Owner gloss: “Play another song!” Owner-approved callout added 2026-11-19 (§9 item 38) and wired as a Patois subtitle on the 100 % Hype Surge and on a round win. Preserve the spelling and the exclamation. |
| `POPPYSHOW!` | Owner gloss: “Show-off! / Clown!” Owner-approved callout added 2026-11-19 (§9 item 38) and wired as a Patois subtitle on a taunt (T) and on a punish hit (a strike that interrupts an attack or a taunt). One word, no space — do not split it. |
| `Feedbackhand` | Proposed backhand pun. |

### Owner callouts added 2026-11-21

| Exact phrase | Meaning / trigger | Status |
| --- | --- | --- |
| `TEK WEH HIM MIC!` | “Take away his microphone!” Crowd shout when the opponent is stunned, dizzied or knocked down. | Implemented as the `&"stun"` pool in `TestArena.CALLOUTS` (fires on `KNOCKDOWN`). Owner wording, verbatim; gloss kept separate. |
| `TUMP OUT HIM TEET!` | “Knock out his teeth!” Heavy punch / Upper Box / counter-hit callout. | Implemented as the `&"heavy"` pool (unblocked `upper_box` / `tump` or a counter-hit). Owner wording, verbatim; gloss kept separate. |

### Jamaican Patwa proverbs & expressions — the owner's 31-entry collection (2026-11-22)

Owner-supplied on `feature/3d-cel-shaded` (commit `c7e408c`). Preserve every spelling and
punctuation mark verbatim; the pronunciation column is a learner aid, never a replacement
spelling, and the English gloss is a separate subtitle field only. **Implemented** in
`TestArena.gd` as `PATWA_COLLECTION` (the 31 entries), `CALLOUTS`, `CALLOUT_GLOSSES` and
`PROVERB_BANNER`, and the headless suite asserts all 31 resolve to a gloss and a live trigger.
`TEK WEH HIM MIC!` and `TUMP OUT HIM TEET!` were already approved and wired on 2026-11-21; they
are entries 7 and 8 of this collection, not duplicates. `BRUK POCKET` is **not** one of the 31;
it is logged in the **[TODO] B15** promoter line pool only.

| # | Phrase (verbatim) | Learner pronunciation | Clean English subtitle gloss (V key) | Wired trigger |
| --- | --- | --- | --- | --- |
| 1 | `WHO CYAAN HEAR, MUS FEEL` | “hoo kyaan hear, mos feel” | Those who refuse warnings must learn through consequences. | `&"heavy"` |
| 2 | `COCK MOUTH KILL COCK` | “kok mout kill kok” | Careless talking exposes your own downfall. | `&"heavy"` |
| 3 | `WEN YUH A DIG HOLE, DIG TWO` | “wen yuh a dig hole, dig two” | A trap set for someone else can backfire on you. | `&"counter"` |
| 4 | `NOBODY NEVA KICK DEAD DAWG` | “no-bah-dee neh-vah kick ded dawg” | Criticism only targets people who are active and making waves. | `&"round_win"` |
| 5 | `SAME KNIFE TICK DI SHEEP, TICK DI GOAT` | “same knife tick di sheep, tick di goat” | What hits one rival can hit you next. | `&"counter"` |
| 6 | `YUH NUH FI EAT HOT RICE` | “yuh nuh fi eat hot rice” | Don't react blindly in anger; stay cool. | `&"parry"` |
| 7 | `TEK WEH HIM MIC!` | “tek weh him mike” | Take away his microphone! | `&"stun"` |
| 8 | `TUMP OUT HIM TEET!` | “tump out him teet” | Knock out his teeth! | `&"heavy"` |
| 9 | `MI NUH TEK CHAT` | “mi nuh tek chat” | I don't tolerate disrespect or foolishness. | `&"taunt"` |
| 10 | `BOASY` | “boh-see” | Showy, flashy, proudly showing off. | `&"taunt"` |
| 11 | `FALLA FASHION` | “fah-lah fah-shun” | Stop copying the crowd; think for yourself. | `&"taunt"` |
| 12 | `YUH ZIMMI?` | “yuh zim-mee?” | Do you understand me? Are you following? | `&"taunt"` |
| 13 | `GINNAL` | “gin-nahl” | Trickster or con artist. | `&"taunt"` |
| 14 | `TEK SET PON MI` | “tek set pon mi” | Repeatedly targeting or pressuring me. | `&"taunt"` |
| 15 | `NUH WAIT TILL DRUM BEAT BEFORE YUH GRINE YUH AXE` | “nuh wait till drum beat before yuh grine yuh axe” | Prepare early before the clash begins. | `&"taunt"` |
| 16 | `NUH PUT YUH SELF IN A BARREL WHEN MATCHBOX CAN HOL YUH` | “nuh put yuh self in a barrel when matchbox can hol yuh” | Stay grounded; don't overreach. | `&"taunt"` |
| 17 | `GWAAN SUH!` | “gwaan suh!” | Keep going! Keep up the pressure! | `&"hype"` |
| 18 | `EVERY MIKKLE MEK A MUKKLE` | “ev-ree mikk-le mek a mukk-le” | Every small hit and effort adds up to victory. | `&"hype"` |
| 19 | `CHAIR DROP A GRUNG AN BENCH GIT UP` | “chair drop a grung an bench git up” | When one steps down, another steps up. | `&"hype"` |
| 20 | `COCKROACH NUH BUSINESS INNA FOWL FIGHT / COWS HAVE NO BUSINESS IN HORSEPLAY` | “kok-roach nuh biz-ness in-na fowl fight / cows have no biz-ness in horse-play” | Stay out of a heavy clash that isn't yours. | `&"throw_break"` |
| 21 | `WASH-BELLY` | “wash-bel-lee” | The youngest prodigy in the crew. | `&"wash_belly"` — L!kkle Moore only |
| 22 | `NICE UP YUHSELF` | “nice up yuh-self” | Carry yourself sharp and strong. | `&"hype"` |
| 23 | `EMPTY YUH PURSE INNA YUH HEAD` | “emp-tee yuh purse in-na yuh head” | Spend on your mind before your pocket; knowledge is the best investment. | match-intro banner |
| 24 | `SORRY FI MAWGA DOG, MAWGA DOG TURN ROUND BITE YUH` | “sor-ree fi maw-ga dawg, maw-ga dawg turn round bite yuh” | Misplaced pity can be repaid with betrayal. | match-intro banner |
| 25 | `IF WIND NUH BLOW, FOWL BATTY NUH SHOW` | “if wind nuh blow, fowl bat-ty nuh show” | What is hidden is only exposed when circumstances stir. | match-intro banner |
| 26 | `PUSS NO AVE HAND, IM USE IM FOOT WIPE IM FACE` | “puss no ave hand, im use im foot wipe im face” | Work with what you have and make a way. | match-intro banner |
| 27 | `FOWL DRINK WATER BUT FOWL NUH PEE` | “fowl drink water but fowl nuh pee” | What goes in does not always come back out. | match-intro banner |
| 28 | `BEFORE DAWG GO WIDOUT SUPPA, IM NYAM COCKROACH` | “before dawg go wid-out sup-pa, im nyam kok-roach” | People will do what they must to survive. | match-intro banner |
| 29 | `IF YUH WANT GOOD, YUH NOSE HAFFI RUN` | “if yuh want good, yuh nose haf-fi run” | Nothing worthwhile comes without hardship. | match-intro banner |
| 30 | `SEE AND BLIND, HEAR AND DEAF` | “see and blind, hear and deaf” | Discretion: see and hear without repeating it. | match-intro banner |
| 31 | `WHEN PUSS BELLY FULL, HIM SEH RAT BATTY BITTER` | “when puss bel-lee full, im seh rat bat-ty bit-ter” | A satisfied person dismisses what others still need. | match-intro banner |

**Wiring, 2026-11-22.** The in-match pools rotate so a phrase leads the first time and every
approved line keeps coming back: `heavy` (1, 2, 8), `counter` (3, 5), `stun` (7), `parry`
(`YUH NUH FI EAT HOT RICE` joins the existing parry lines), `throw_break` (20 joins
`WHOLE-AWN-DEH!`), `taunt` (9–16), `hype` (17–19, 22), `round_win` (4). `WASH-BELLY` (21) is
weighted to **L!kkle Moore**: `_impact_callout()` returns `&"wash_belly"` for his unblocked heavy
or counter contact, and a round he wins uses it instead of the generic round-win line. The nine
traditional proverbs (23–31) rotate on the match-intro wisdom banner, one per match, under a
`YARD WISDOM` heading; the Patwa stays visible with subtitles off and the English gloss follows
the **V** key. Counter hits now get the counter pool instead of the heavy line.

**Translation provenance.** Rows 1–22 use the owner's supplied meanings. The nine banner
glosses are clean English subtitle readings written for this pass and marked **[TODO]** for the
owner's wording check; they are subtitles, not new Patwa lines or cultural claims. Do not
"correct" any Patwa spelling while reviewing them. The display-title **I → !** rule still applies
to character names (`L!CKSHOT`, `L!KKLE MOORE`); the proverb body is preserved verbatim, so no
proverb is rewritten to force the style, and the `YARD WISDOM` heading deliberately contains no I.

### Comedy, taunt and move register

- **`cricket box`**: owner-proposed name for a cricket-bowling-inspired BOX/slap, potentially for another character. No fighter assigned; concept/backlog only, not an implemented move or added launch requirement. Preserve the owner's name. Keep separate from Feedback's current BOX direction: original rear three-quarter camera, right-knee lift, plant/turn into the existing slap/follow-through. The earlier raised-knee illustration changed the camera/build and is not approved production art.

- `Rum Punch`: candidate fighter name, powerful move/hit name, or both; Caribbean punch/fighting wordplay. Now one of the three names in the owner's working pool for Fighters #4–#6 alongside `FL!NG STONE` and `SKY JU!CE` — the on-screen spellings under the I → ! rule (§2, §9 items 26 and 32). Keep options open, not finalized.
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
   `Feedback_Baseball_Pitch_BOX_Foot_Off_Ground.png` (1024×1536; rear
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
      (`ScreenRecording_11-15-2026-{17-34-45,23-25-15,23-26-04}_1.mov`; byte-identical to the blobs
      delivered in `596ae3a`, now filed under `artifacts/sound-clash/art-source/references/`). They live
      outside `/godot` and `/docs`, so the Web pack never carries
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

25. **Fighter #3 — Likkle Moore's (L!KKLE MOORE) signature moveset, designed by the owner's son — recorded,
    not built (2026-11-17; renamed 2026-11-19, item 35).** Documentation only: **no code, scene, input
    action, frame data, hitbox, SFX cue or art was added for this entry.** It exists so the design survives
    the current combat work, not as a claim that any of it runs. The fighter was renamed Young Selecta →
    **Likkle Moore** on 2026-11-19 (item 35); his roster key and asset folder remain `young_selecta`. Apart
    from the name, this design record is unchanged. The owner's production order puts it behind Feedback:
    refine Feedback's combat, blocking and hit reactions and build his **Dancehall dance-move attacks — The
    Bogle, Log On, Signal Di Plane** — first, then Likkle Moore's projectiles and bat swings, then
    Lickshot's unique moveset.

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
      above reassigns all four on Likkle Moore. Decide explicitly whether these four moves **replace** his
      normals, are **held-modifier or stance** variants, or take new keys; do not silently overwrite the
      shared layout, because P1, P2 and the CPU all read it.
    - **Art and audio needed.** Likkle Moore ships **three frames today** — `idle.png`, `thrust.png` and
      `slam.png` in `assets/sprites/young-selecta/` — so none of these moves has a frame. Required art:
      the mic stand in both swing arcs (startup/contact/recovery), a mic projectile with a readable spin,
      an oversized hardcover book, page-flutter frames or a particle, and the backpack reach. Nothing here
      is drawn, generated or purchased yet, and every open value above stays **[TODO]** until the owner
      approves art.
    - **Design intent worth keeping.** All four moves share one identity: a schoolyard kid using what a
      young selecta actually carries — a mic, a mic stand and a school bag — so he reads as comically
      dangerous without a martial-arts sheet. Keep the props literal and the arcs exaggerated.
    - **Production order (owner, 2026-11-17).** 1) Feedback's combat, blocking and Dancehall move attacks
      (The Bogle, Log On, Signal Di Plane). 2) Likkle Moore's projectiles and bat swings. 3) Lickshot's
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
    - **Roster name pool for Fighters #4–#6 (owner, 2026-11-17): FL!NG STONE, RUM PUNCH, SKY JU!CE.**
      Those are the on-screen spellings under the I → ! styling rule (item 32); internal ids would stay
      clean (`fling_stone`, `sky_juice`). Working names for the open slots, recorded in §2 and
      cross-referenced in §8. They are **not
      assignments** — nothing says #4 is FL!NG STONE, #5 RUM PUNCH or #6 SKY JU!CE — and not designs: no
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

28. **Consolidated onto `stage/sound-clash-sand`, with Lickshot merged — done (2026-11-19).**

    - **The merge.** `work/lickshot-art` (`88c7275`) was a straight fast-forward onto stage's `04db5ec`
      (6 commits): the Dubplate → Lickshot rename, his four wired poses, `prep_lickshot_poses.py`, the
      roster/title-screen updates and its rebuilt Web export. No conflict resolution was needed and no
      commit was rewritten.
    - **Roster state.** `FighterRoster.ORDER` is **Feedback, Lickshot, Young Selecta**, and the title screen's
      Character & Match Setup lists those three. `MatchSetup` still defaults to **Feedback vs Feedback**
      (`p1_fighter = p2_fighter = &"feedback"`, AI mode 1), so the default sparring setup is untouched and
      Lickshot and Young Selecta stay selectable.
    - **Engine verification (real, not static).** Godot **4.5.stable.official.876b29033** was installed in the
      cloud workspace with the matching export templates. A first `--headless --path godot --import` pass
      built the import cache and the `class_name` registry, then
      `--headless --path godot --script res://tools/headless_roster_check.gd` printed **ALL CHECKS PASSED** —
      roster order, title-screen setup, shared FSM, Lickshot's Sonic Clap and high kick, Young Selecta's
      reach/height, crowd acts, facing and mirroring, the y 592 sand line, the three lighting phases, the AI
      modes, and the Esc round trip. No GPU, no audio device and no on-screen look, so this proves the
      project imports and those code paths execute — **not** that anything looks or feels right.
    - **Note for the next agent.** A bare `--headless --script` run on a fresh checkout fails with
      `Identifier "FighterRoster" not declared`; that is only the missing class cache, not a code fault.
      Run the `--import` pass first. The `libfontconfig.so.1` warning at startup is non-fatal headless.
    - **`/docs` was rebuilt from this commit** with `--headless --path godot --export-release "Web"
      ../docs/index.html`, so the playable build and the source are the same revision. The export produced
      `index.pck` **11,726,228 B (11.18 MiB)**, `index.wasm` 38,057,390 B, `index.js` 305,185 B and
      `index.html` 5,449 B — byte-identical to the pack the Lickshot branch shipped, which is the expected
      result of exporting the same code.

29. **Next-generation visual & combat direction — approved direction (2026-11-19).**

    Scoped to the **Godot 4.5 project only**. The Phaser/TypeScript prototype is archived reference and is
    not the target: nothing here is ported from it, and no TS/Phaser file is revived. The two documents
    salvaged from `freebuff/20c43fa8…` and kept at `artifacts/sound-clash/VISUAL-DIRECTION-2026-11-18.md`
    and `artifacts/sound-clash/FEEDBACK-ART-INTEGRATION-2026-11-18.md` are the **Phaser-era audit that
    produced this direction** — historical evidence for the reasoning, never a specification for the port.

    - **A. Character polish — *Marvel Tōkon* reference.** Bold, readable silhouettes first; dimensional
      lighting (warm key, core shadow, rim on the near edge, head/jaw highlights) painted or lit per pose;
      exaggerated anticipation → impact → recoil punctuation. Constraint: Feedback's identity is fixed —
      slim build, bucket hat and locks, burgundy jacket with cream stripes, fitted trousers, Clarks
      Wallabees, one gold tooth, face concealed — and item 2's mic-hand rule applies unchanged: one mic, the
      declared anatomical hand, no `flip_h`, no invented left-facing art.
    - **B. Stage polish — *Street Fighter 6* reference.** Layered depth between far scenery, crowd and the
      fight lane; bass-vibrating speaker cones on the cosmetic beat pulse; dynamic lighting and floor/rail
      reflections against the three existing day/sunset/night phases; a fighting lane that stays legible
      above all of it (the arena's readability is a hard requirement, not a nice-to-have).
    - **C. Arcade energy — *Fatal Fury: City of the Wolves* reference.** Immediate hit feedback at contact,
      directional speed lines that follow the strike, layered impact bursts (core → ring → rays) that never
      cover the contact, and crowd reactions with individual personality and phase rather than one shared
      loop.
    - **Boundaries.** Presentation only: no change to hitboxes, startup/active/recovery, damage, guard
      rules, AI, the beat clock or the seeded simulation. Effects and shadows stay separate from source art
      (no baked-in VFX, no re-exported sprites), and the mic/cable continuity audit still gates any new
      Feedback pose that is drawn.
    - **[TODO] Nothing here is implemented yet.** No shader, particle or lighting pass exists in `/godot`;
      this item records the direction so new frames and stage work are judged against one target.

30. **Future 2v2 / 3v3 Sound-Clash Crew tag-switching — [TODO], architecture note only, not implemented
    (2026-11-19).**

    **Do not implement yet.** One-on-one stays the only playable mode and Feedback vs Feedback stays the
    default test setup (item 24). This records where the seams are so the crew mode can be added later
    without rewriting the fighter.

    - **`FighterRoster`** already is the data layer: per-fighter frames, offsets, scales, `anim_source_max`,
      attack-anim mapping and the shared adult/kid height rules. A "crew" can later be nothing more than an
      ordered list of roster keys plus a side owner — no new art pipeline, no per-fighter scripts.
    - **`MatchSetup`** already owns the match choices as plain state (`p1_fighter`, `p2_fighter`, `ai_mode`,
      `subtitles`). Extending it to two crews with an active index per side is an additive change to that
      autoload and the Character & Match Setup screen; the arena keeps reading the same contract.
    - **`BaseFighter`** stays the single shared FSM. A tag would add an explicit `TAG_IN` / `TAG_OUT` state
      pair and a `tag` command beside `jump`/`guard`/`attack`, entered through the existing
      `change_state()` authority — never a parallel state machine and never a scene-level swap.
    - **Match layer.** A round ends when a side has no runnable fighter left, not when one body's health
      hits zero; the KO → knockdown → announcement sequence stays per body, checked after the announcement.
    - **Only the two active bodies are simulated.** Bench fighters are data: no off-screen physics, no spare
      hurtbox, no assist hitbox.
    - **[TODO] Decide before any code:** tag-in invulnerability, cooldown, whether hype/combo carries across
      a swap, entrance camera framing, HUD treatment for a full crew, and how a swap is recorded so a replay
      stays deterministic.
    - **Explicitly not built:** no tag input, no assists, no bench bodies, no simultaneous multi-fighter
      fights, and no change to the current 1v1 rules.

31. **Loose root reference files relocated into `artifacts/sound-clash/art-source/references/` — housekeeping
    (2026-11-19).** The three UUID-named `.mov` screen recordings
    (`6B29EBF9-…`, `7CEDC855-…`, `BC9199CE-…`), `Feedback_Forward_Prepared_Transparent.zip`,
    `Feedback_Crossed_Arms_Import.py`, `Feedback_Walk_Video_Import.py`, the foot-off-ground BOX contact PNG
    and the Baseball-pitch lean comparison MP4 were moved with `git mv` (byte-identical, history kept) so the
    repository root holds only `AGENTS.md`, `FREEBUFF-HANDOFF.md`, the two source trees, `godot/`, `docs/`
    and the workspace config. The in-game copy of the BOX frame stays at
    `godot/assets/sprites/feedback/box-footoff-ground-2026-11-15/`; only the loose reference moved, so item 6's
    offset/scale numbers are unaffected. `Feedback_Walk_Video_Import.py` reads `part-*.b64` files that sit
    beside it and are not in the repository, so it remains a record of how the video was delivered rather
    than a runnable tool — true before the move and after it.

32. **Global fighter-name styling rule — an I renders as ! on screen (owner, 2026-11-19).**

    - **The rule.** Any fighter whose name contains the letter I is shown with **!** instead of **I** on
      screen: Character Select, the HUD health-bar name plate, round/result announcements and every
      roster display. It is a **display-time transform, never a rename** — roster keys, asset folders,
      sprite filenames, script ids and `FighterRoster.FIGHTERS` keys stay clean ASCII.
    - **Implementation.** `FighterRoster.styled_name()` applies `String.replace("I", "!")` and
      `FighterRoster.display_name()` — the single funnel the title screen and the HUD already use —
      returns the styled result. `BaseFighter.apply_fighter_profile()` sets `display_name` through it, so
      any future screen reading the fighter's own name inherits the rule automatically. Applying the rule
      twice is idempotent (`!` is not `I`).
    - **Fighter #2 is L!CKSHOT on screen.** The roster entry still stores `"name": "LICKSHOT"`; the key is
      `lickshot`, the asset folder is `godot/assets/sprites/lickshot/`, the prep script and every code id
      remain `lickshot`. The title-screen splash line is now built from `FighterRoster.ORDER` through
      `display_name()` instead of a hard-coded string, so a rename cannot leave a stale label behind.
    - **Future name pool.** The Fighters #4–#6 working pool renders **FL!NG STONE, RUM PUNCH, SKY JU!CE**
      (§2, §8, item 26). RUM PUNCH contains no I and is unchanged. Still working names, still unassigned.
    - **Font check.** All three Bungee faces shipped in the project (`Bungee-Regular`, `BungeeShade-Regular`,
      `BungeeInline-Regular`) contain the `!` glyph (fontTools cmap check), and the headless roster check
      asserts the Bungee face gives `!` and `L!CKSHOT` non-zero measured advances. That proves the glyph
      and the metrics; it does not prove the name plate looks right at gameplay size, because nothing was
      seen on screen in this environment (no GPU).

33. **Feedback's six 2026-11-18 poses — prepared, wired, headless-verified (2026-11-19).**

    - **Sources.** The six owner uploads were moved with `git mv` (byte-identical) into
      `artifacts/sound-clash/art-source/feedback/selected-frames-2026-11-18/` and join a `PROVENANCE.md`
      plus the script's `prep-report.json`. Original filenames are kept as provenance.
    - **Preparation.** `artifacts/sound-clash/art-source/feedback/prep_feedback_poses_2026-11-18.py` drops
      border-connected near-white background (enclosed highlights are kept), protects the thin black mic
      cord and the cream Clarks soles from the one-pixel edge erosion, crops to the alpha bbox, caps the
      longest side at **512 px**, and measures each pose's crown row, alpha bottom and stance centre.
    - **Floor rule.** Every processed frame's drawn alpha bottom lands on world **y 592**
      (`BaseFighter.REACTION_FLOOR_Y`), the same 8 px above the y 600 origin line the Lickshot set uses.
      Offset y is `frame centre − alpha bottom − 8 / (scale × FIGHTER_ART_SCALE)`; scale is
      `121.75 / crown-to-sole`, so every pose renders at the adult ~151 px height and the cable is the
      lowest drawn pixel rather than an estimate.
    - **What each frame is wired to** (new `BaseFighter.tscn` animations, `ANIM_OFFSET`/`ANIM_SCALE`
      entries and the Feedback roster entry):
      1. `01_double-palm-shove` → **throw break** (both fighters; the breaker uses the hitstun override,
         the attacker's still in GRAB during recovery so it uses the grab override) and the
         **forward-throw release** pose through grab recovery.
      2. `02_lean-back-groove` → first half of the **T (skank) taunt**, then the existing skank loop:
         `taunt_sequence = [lean_back, skank]`.
      3. `03_open-palm-slap` → **jab (J)** startup/active/recovery.
      4. `04_clarks-kick` → **Sparta kick (L / tump) active frame**; the existing Sparta frames keep the
         windup and the recovery.
      5. `05_sky_fist` → **upper box (I)**, and the **round-win / 100 % Hype Surge** celebration.
      6. `06_hand_reach` → **collar grab (U) startup**.
    - **No combat change.** Only `anim_startup/anim_active/anim_recovery` names were remapped. Startup,
      active and recovery ticks, damage, chip, hitstun, knockback, hitbox position/size and the shared FSM
      are untouched. Because jab, kick and upper box now carry drawn contact poses, they join
      `no_strike_tell` so the arena stops painting the generic smear over them.
    - **New shared presentation hooks, all data-driven.** `BaseFighter` gained the optional roster keys
      `state_anims` (`grab`, `throw_break`, `throw_release`), `taunt_sequence` and `celebrate_anim`; a
      fighter without them keeps the old jab/hitstun/skank behaviour. `play_celebration()` shows the pose
      only in IDLE/WALK/CROUCH, so it can never hide an attack drawing; `TestArena` calls it for the round
      winner (`round_ended`) and `BaseFighter` for a Hype Surge (60 ticks).
    - **Verified headless (Godot 4.5).** All six animations registered, every drawn bottom on y 592 within
      0.75 px, every frame ≤512 px, the animation remap applied, the old timings unchanged, the
      grab/throw/taunt/celebration wiring present, and the jab/kick/upper-box smears retired. **Not**
      verified: how the drawings look in motion, whether the high kick's untouched stomach-height hitbox
      still reads against a high kick, or how the shove reads against the throw timing — those need a
      playtest.

34. **L!CKSHOT's seven 2026-11-18 poses — prepared, wired, headless-verified (2026-11-19).**

    - **Sources.** The seven uploads are the untouched originals
      `art-source/fighters/lickshot/05_left-jab_original.png` through
      `11_arms-open_celebration_original.png`, beside the first four. They are pure-white-background
      exports, not the dark studio backdrop of the 2026-11-17 set.
    - **Preparation.** `art-source/fighters/prep_lickshot_poses.py` gained a `white` keying mode: background
      is near-white that touches the frame border **or** forms a large enclosed pocket (a loop of mic
      cable seals a white hole behind the legs in three poses), while sub-1000-px enclosed highlights —
      the silver mic grille, the chain — are kept, and the cream Wallabee soles sit far below the white
      floor so they are never keyed. The four approved 2026-11-17 outputs were **not** rewritten: the new
      pass ran with `--only` and merged its entries into the existing `prep-report.json`.
    - **What each frame is wired to** (Lickshot roster entry; same y 592 floor rule and 121.75 px
      crown-to-sole authoring height as the first four):
      1. `jab` (left-hand straight jab) → **jab (J)**, retiring the placeholder strike smear.
      2. `upper_box` (heavy right-hand mic cross) → **upper box (I)** heavy strike.
      3. `guard_stance` (defensive mic and open palm) → **guard** entry, held block, blockstun and release
         (S). One drawing covers all three guard phases; the phase timing is unchanged.
      4. `hitstun_recoil` (chin snap) → **hitstun** reaction.
      5. `launched_recoil` (head-back groove / heavy recoil) → **launched** pose.
      6. `skank_point` (wide gun-finger / mic-point lean) → **taunt / Dancehall skank (T)**.
      7. `celebration` (wide-open arms, mic in the cargo pocket) → **collar grab (U)** and the **round-win /
         Hype Surge** celebration.
    - **Unchanged.** His existing idle, high kick, Sonic Clap windup and Sonic Clap impact frames stay
      byte-identical to item 27, and knockdown/KO/tumble still fall back to the mic stance.
    - **Verified headless (Godot 4.5).** All seven registered, every drawn bottom on y 592 within 0.75 px,
      every frame ≤512 px, the guard/hitstun/launch/taunt/grab/celebration wiring present, the jab and
      upper-box smears retired, and the celebration pose actually becoming the drawn animation. **Not**
      verified: the in-motion look, how one guard drawing reads across entry→hold→release, or whether the
      mic cross's untouched upper-box hitbox matches the drawing. Those need a playtest.
    - **`/docs` rebuilt from this commit** with `--headless --path godot --export-release "Web"
      ../docs/index.html` after the 13 frames were imported. `index.pck` grew from **11,726,228 B** (item 28)
      to **13,842,592 B**, `index.wasm` 38,057,390 B, `index.js` 305,185 B and `index.html` 5,449 B, so the
      playable build and the source are the same revision.

35. **Fighter #3 renamed Young Selecta → Likkle Moore, displaying as L!KKLE MOORE — implemented
    (2026-11-19).**

    - **What changed.** `FighterRoster.FIGHTERS[&"young_selecta"]["name"]` is now **`LIKKLE MOORE`**. The
      I → ! rule (item 32) renders **L!KKLE MOORE** in the title-screen roster line
      (FEEDBACK · L!CKSHOT · L!KKLE MOORE), Character & Match Setup, the HUD health-bar plate, and any
      future round/result announcement that reads `display_name`.
    - **What deliberately did not change.** The roster key stays `young_selecta`, the sprite folder stays
      `godot/assets/sprites/young-selecta/`, the source originals stay in
      `art-source/fighters/young-selecta/`, and every texture path and UID stays as it was. This is a
      display-name change only, so nothing is re-imported or re-pointed.
    - **Comments and copy.** `FighterRoster.gd`, `MatchSetup.gd`, `BaseFighter.gd`, `godot/README.md`, §2,
      §9 item 25 and Backlog B11 now say Likkle Moore / L!KKLE MOORE. Historical items (26, 28) and the
      milestone rows keep the old name where they describe what shipped at the time.
    - **The name may still evolve** — recorded with the same caveat as Lickshot.
    - **Verified headless (Godot 4.5):** P2's `display_name` is `L!KKLE MOORE` while `fighter_key` is
      `young_selecta`, and the walk-speed, +25 px reach and 82 % height checks still pass unchanged. Not
      verified: the longer name on the real HUD plate and title layout — no GPU here. One stale assertion
      was replaced while doing this: the check used to expect Feedback's jab to draw the generic strike
      smear, which item 33 retired. It now asserts the drawn jab draws **no** smear and that an attack the
      roster does not list still gets one, so the smear path stays covered without depending on CPU timing.
    - **`/docs` rebuilt from this commit** with `--headless --path godot --export-release "Web"
      ../docs/index.html`: `index.pck` **13,842,752 B**, `index.wasm` 38,057,390 B, `index.js` 305,185 B,
      `index.html` 5,449 B.

36. **Locked character & art prompt templates — folder registered (2026-11-19).**

    - **Location.** `artifacts/sound-clash/prompt-templates/README.md`; registered in §5.
    - **Contents.** One locked appearance block each for **Feedback** (bucket hat pulled over the eyes,
      dreads, red striped track jacket, brown trousers, tan Clarks Wallabees, right-hand corded silver
      mic), **L!ckshot** (brown Kangol flat cap low over the eyes, short dreads, goatee, gold tooth,
      red/yellow/green Rasta mesh string vest with no jacket, gold chain, olive cargos, tan Clarks
      Wallabees, right-hand corded silver mic) and **Likkle Moore** (10-year-old Black boy, crisp low fade,
      dark-blue rectangular glasses, patterned durag/bandana, cream school-uniform button-down shirt, navy
      trousers, crisp white sneakers, oversized blue DJ/school gadget backpack), plus the shared output
      rules: pure #FFFFFF background, flat white, **zero floor shadow** and no scenery, one full-body
      figure, no text or watermark.
    - **How it is used.** Paste the character block verbatim and append one pose line. The block is the
      consistency contract: changing an outfit word changes the fighter. Do not generate a pose that
      already has an approved drawing.
    - **Status.** Documentation only. It adds no art, approves no art and changes no pipeline: an upload
      is still a candidate until the owner reviews it and it passes keying, the 512 px cap and the y 592
      floor alignment.

37. **Core Creative Identity & Development Guidelines — permanent creative direction (2026-11-19).**

    The owner set the project's permanent creative foundation in
    `artifacts/sound-clash/SOUND_CLASH_CULTURE.md`, and it now governs every future development,
    character, animation, sound and gameplay decision. **Documentation only:** no Godot scene, script,
    resource, hitbox, timing value or `/docs/` export file was touched for this entry, no art was added or
    approved, and nothing in the document is a claim that a listed system exists.

    - **Foundation.** Authentic Jamaican sound clash culture — competing sound systems, selectors, MCs,
      exclusive dubplates, DJ tags, musical strategy, crowd participation and intense rivalry — is the base
      layer, not a skin on a generic fighter. Every fighter is their own sound system; the objective is
      outclassing and embarrassing the opposing sound through superior musical ammunition, performance,
      timing and crowd response.
    - **Generations.** Stone Love, Bodyguard, Silver Hawk, Bass Odyssey and Mighty Crown are research
      inspiration only, never an implied affiliation. Fighters represent different eras through fashion,
      swagger, movement rhythm and performance: Kangol/bucket hats, gold chains, long button-up shirts,
      Rasta mesh string vests, corduroy and olive cargo pants, Travel Fox, Clarks Wallabees, early-2000s
      streetwear and contemporary dancehall fashion.
    - **Established designs stay fixed.** Feedback, Lickshot and Likkle Moore keep their approved designs
      unless the creator explicitly approves a change — the same rule as §1's appearance, mic-hand,
      jacket-origin cable, Wallabee and one-gold-tooth requirements, and item 36's locked prompt blocks.
    - **Presentation references.** Marvel Tōkon (bold silhouettes, dimensional lighting, exaggerated
      anticipation/impact/recoil), DC team-fighting concepts (long-term 2v2/3v3 crew switching), Street
      Fighter 6 (layered stage depth and lighting) and Fatal Fury: City of the Wolves (arcade energy,
      expressive crowd reactions). These extend item 29's direction; analysing them never licenses copying
      proprietary assets (§1).
    - **[TODO] Recorded ambitions — none implemented:** echoing character DJ tags on major hits and
      counter-attacks; a "Plenty of Dubs" sub-bass dizzy stun (wobbly knees, spinning musical notes)
      unless answered by a timed parry or counter-dub ("WHEEL AND COME AGAIN!"); multicolored, varied-size
      musical-note swing trails on heavies, specials and on-beat strikes while light jabs stay clean; 2.5D
      warm rim light and brief comic-ink impact flash frames; speaker cones flexing harder as Hype rises,
      and a knocked-out fighter's stack smoking, sparking, tilting/toppling and being unplugged with a
      power-down cue while a crew member packs up (resetting cleanly between rounds); and "Lightah!"
      crowd-judge finishes with raised lighters, waving rags, airhorns and individualized crowd reactions
      instead of uniform bouncing loops. **Do not implement these yet.** Item 29's presentation-only
      boundary applies unchanged: no hitbox, damage, startup/active/recovery, guard, AI, beat-clock or
      seeded-simulation change.
    - **Team switching stays unbuilt.** The 2v2/3v3 crew idea is still item 30's architecture note; this
      entry adds no tag input, assist, bench body or simultaneous multi-fighter fight.
    - **Creator-led animation (strict workflow rule).** The owner plus Google Flow, Spriteriffic, Gemini and
      ChatGPT develop, generate, review and approve original walking animations and pose references first.
      **Freebuff must not invent or independently generate a character's initial walk.** Once frames are
      approved and uploaded, Freebuff imports them, aligns baselines (y = 592), refines transitions and
      timing, and verifies gameplay behaviour. Feedback keeps his established skanking-inspired walk,
      132 BPM rhythmic bounce, right-hand corded mic and approved identity. L!ckshot's own signature walk
      is the next creator-led animation task, approved by the creator and the AI tools before sprites are
      handed to Freebuff.
    - **Sound design is a major priority.** Original dubplate-inspired recordings, echoing character DJ
      tags, selector/MC callouts, 132 BPM dancehall/reggae riddims, sound-system sirens and power-downs,
      crowd forwards/whistles/laughter and character-specific voice expressions — strictly original,
      licensed or creator-approved recordings. No paid service and no automatic credit spend (§9 item 8);
      the existing procedural SFX and the dev 132 BPM click track are unaffected.
    - **The 10 Permanent Development Principles.** (1) Sound clash culture is the foundation; (2) epic
      fighting is the primary gameplay; (3) character designs stay consistent; (4) original animations are
      creator-led; (5) cultural authenticity informs gameplay, sound and personality; (6) existing Godot
      4.5 systems are not unnecessarily replaced; (7) major creative changes require creator approval;
      (8) new features are added incrementally and verified; (9) preserve humour, Jamaican expressions and
      competitive swagger; (10) avoid superficial stereotypes.
    - **Cultural accuracy.** Primary cultural references and the creator's lived cultural knowledge come
      first; never reduce sound clash culture to superficial stereotypes. §8's verbatim Patois rule still
      governs every line, including the DJ tags and callouts listed above.
    - **Where it lives.** The document sits under `artifacts/sound-clash/` with the rest of the design
      record and is deliberately **not** copied into `/docs/` (exported WebGL2 build only) or `/godot`
      (code and assets), per §5.

38. **L!CKSHOT's 2026-11-19 batch — 6-frame walk loop, 8-pose skank groove, 12-pose hit/launch/knockdown sheet and the C-recoil prepared, wired and headless-verified; three Patois callouts and an expanded name pool recorded (2026-11-19).**

    - **Uploads.** Four creator-approved files were moved off the repository root with `git mv`
      (byte-identical) into `art-source/fighters/lickshot/batch-2026-11-19/` and recorded in its
      `PROVENANCE.md`: the 2.97 s / 89-frame walk video (stored as `15_bossy-walk_original.mov`, uploaded
      as `lickshot_bossy_walk_phone.mov`), the 2 × 4 lean-back / skank sheet
      (`12_skank-leanback-sheet_original.jpeg`, uploaded as `IMG_6636.jpeg`), the 3 × 4 hitstun / airborne /
      knockdown sheet (`13_hitstun-launch-knockdown-sheet_original.jpeg`, uploaded as `IMG_6643.jpeg`) and the
      single C-recoil pose (`14_c-recoil-launch_original.jpeg`, uploaded as `IMG_6644.jpeg`). Each upload is
      byte-identical to what the owner posted; only the path and the descriptive filename changed. The root
      carries no upload left over from this batch.
    - **Preparation.** `art-source/fighters/prep_lickshot_poses.py --batch 2026-11-19` (measurements in
      `art-source/fighters/lickshot/prep-report-2026-11-19.json`) keys the white background including the
      pocket sealed inside the mic-cable loop, protects the thin black cord, the silver grille and the cream
      Wallabee soles, and crops each drawing as its own connected blob — a straight grid cut chopped the
      poses because the sheet rows touch. Every animation group is then composed onto **one shared canvas**
      (sole row and stance centre aligned, group downscaled once to the **512 px** cap), because
      `FighterRoster` stores one offset/scale per animation name; that is what keeps a sequence from bobbing
      or sinking frame to frame. Measured sole spread inside every group: **0 px**.
    - **Floor rule.** Every frame's drawn alpha bottom lands on world **y 592**
      (`BaseFighter.REACTION_FLOOR_Y`), the same 8 px above the y 600 origin the earlier poses use. The 0.5 px
      feather is re-cut at the sole line, because Godot's `used_rect` counts any non-zero alpha and the
      feather tail would have set a sole two pixels low (it did: 592.7–592.9 before the fix).
    - **Art-scale calibration.** The standalone C-recoil is drawn ~2.7× larger than a sheet pose. The mic
      grille — the only rigid prop in every drawing — calibrates it onto the sheet scale (measured ratio
      **2.682**, `art_scale_match` in the report), so the C-recoil reads at the same body size as the
      airborne poses beside it.
    - **Wiring (presentation only; no combat value changed).** `walk` = the 6 stride frames drawn from the
      walk video (10 fps, looping — the recycled idle walk is retired); `skank` = the 8-pose lean-back
      groove (the T taunt, 7 fps over the 68-tick taunt); `hitstun` = the sheet's 3 standing recoils; `launched` =
      C-recoil + row-1 pose 4 + the first airborne pose; `tumble` = the 4 airborne poses; `knockdown` = the
      seated → sprawled pair; `ko` = the two face-down frames. `FighterRoster.build_frames()` gained optional
      `anim_fps` / `anim_loop` tables (defaults unchanged, so every single-frame pose behaves exactly as
      before) and the knockdown/KO hold their last drawn frame. The three replaced single poses
      (`skank_point.png`, `hitstun_recoil.png`, `launched_recoil.png`) stay in the repo but are no longer
      referenced; idle, jab, upper box, Sonic Clap windup/impact, high kick, guard and celebration are
      untouched.
    - **Walk upload — wired with a source-crop caveat.** The clip is a phone-framed close-up: the hat crown
      is cut by the top edge in all 89 frames and **every frame clips one boot** at a side edge. Six of the
      video's own drawings are sampled evenly across the clip (one per step, never an invented in-between),
      each pick nudged by at most one frame towards the less-clipped drawing, then keyed, capped and
      floor-aligned into `godot/assets/sprites/lickshot/walk/` with `review/walk-strip.png`. The phone crop
      also leaves a chopped boot piece floating beside the fighter once the 1 px stalk that tied it to the
      body is lost in the downscale; `compose_group()` now drops detached specks under 2 000 px so no stray
      fragment ships. All six frames land on y 592 in the headless check. **Superseded later the same day by
      the full-body sheet in item 39** — the crown and one boot were missing from the drawings themselves, and
      no processing could restore pixels the phone never framed.
    - **Patois callouts (§8).** `WHOLE-AWN-DEH!` (Record Static Parry, throw break), `PLAYAH NEX TUNE!`
      (100 % Hype Surge, round win) and `POPPYSHOW!` (taunt, punish hit) are wired through one rotating pool
      in `TestArena.CALLOUTS`: the new line leads its trigger and the lines that already played there
      (`BIG TUNE!`, `WHEEL AND COME AGAIN!`, `YUH TOO BOD MINE!!`) rotate back in. `receive_strike()` now
      records a `punish` flag (the strike interrupted an attack or a taunt) so the punish callout has a real
      trigger. Every line keeps its English gloss in its own field; no spelling was normalised.
    - **Future roster name pool (§2).** POPPY SHOW, SUGAR KANE and JUNE PLUM join FL!NG STONE, RUM PUNCH and
      SKY JU!CE. Sugar Kane and June Plum are **female fighter name candidates**. Still working names with no
      slot assigned and no design implied — do not build a fighter from a name.
    - **One check made deterministic.** `StrikeTell` now carries its `source` fighter, so the headless
      smear check asks whether **P1's own** drawn jab spawned a smear instead of whether *any* smear is
      alive — the CPU (Likkle Moore) draws real smears, and that made the old form flip depending on when
      the AI attacked. Two consecutive runs now both pass.
    - **Checks actually run** — Godot **4.5.stable.official (876b29033)** headless, Web templates installed
      locally (never committed): `--import`, then `--script res://tools/headless_roster_check.gd` →
      **99 assertions, `ALL CHECKS PASSED`, exit 0**, including per-frame floor checks on all 28 sequence
      frames, the 512 px cap, the full frame counts (6/8/3/3/4/2/2), the walk's 10 fps loop, the taunt rate
      and loop flags, the retired single poses, the six-name pool and each new callout's text and rotation.
      The Web export was rebuilt (`docs/`).
    - **Not verified.** No GPU or display here: nothing was watched running, so the groove's feel, the
      frame-to-frame continuity at gameplay size and the punch of the new callout timing are unjudged. The
      frames are **UNAPPROVED** art pending the owner's review; the C-recoil scale match is arithmetic from a
      prop measurement, not an eye check. The walk loop is wired from the drawings the upload contains, so
      the missing crown and boot edge are visible in motion until a full-body re-export arrives.
    - **Next.** Owner review of the four review strips; device playtest of the walk loop, the taunt groove,
      the hit responses and the callout rotation. The walk re-upload arrived the same day — see item 39.

39. **L!CKSHOT's clean 4-pose walk sheet — the clipped phone-crop stride retired, re-sliced, floor-locked and wired at 9 fps (2026-11-19).**

    - **Upload.** `IMG_6654.jpeg` (1792 × 2390, pure `#FFFFFF`, 2 rows × 2 poses, full Kangol cap crowns,
      complete Clarks Wallabee toes and generous margin on all four sides) was uploaded by Garfield to the
      root of `stage/sound-clash-sand` in commit `db85686`. It was moved off the root to
      `art-source/fighters/lickshot/batch-2026-11-19/16_walk-sheet-clean_original.png`, stored as PNG
      (lossless decode of the JPEG; no pixel retouching), and `PROVENANCE.md` records the mapping. The
      3 s phone video `15_bossy-walk_original.mov` stays archived as provenance for the superseded walk and
      is no longer referenced by the roster.
    - **Preparation.** `prep_lickshot_poses.py --batch 2026-11-19 walk` slices the sheet in the owner's order
      (top-left → top-right → bottom-left → bottom-right) by **connected drawing**, not a straight 2 × 2 crop: the
      top row's boots pass below the vertical midpoint and neighbouring drawing boxes overlap, so a quadrant cut
      chopped a Wallabee. Pure white is keyed with the same threshold as the other 2026-11-19 sheets, keeping the
      black cord loop, silver mic grille and cream soles. The four drawings are composed onto **one 454 × 512
      shared canvas** with every sole on row 510 — measured spread **[510, 510], 0 px vertical bobbing** — then
      capped at 512 px. Frames: `godot/assets/sprites/lickshot/walk/01..04.png`; review strip
      `batch-2026-11-19/review/walk-strip.png`; measurements in `prep-report-2026-11-19.json`
      (`anim_scale 0.23873`, `anim_offset [-5.2, -281.0]`, `anim_source_max 512`).
    - **Scale correction (same day).** The first pass derived `anim_scale` from the **median** crown-to-sole of
      the four poses (485 px). Two of those are leaning pass poses, so the upright stride frames rendered about
      **4 % taller than idle**. The walk is now calibrated on the tallest standing frame (510 px, giving
      **0.23873**, offset **-281.0**), matching idle's 507 px reference. A new headless assertion measures
      crown-to-sole with the prep script's crown rule (a thin motion arc cannot be mistaken for the hat) and
      requires walk and idle to agree within 0.5 px: **150.68 vs 150.97 px**. A labelled 2× review loop with
      idle beside the stride is at `batch-2026-11-19/review/walk-loop-preview.gif`.
    - **Wiring (presentation only).** `walk` = those four frames at **9 fps, looping**; `anim_scale`,
      `anim_offset` and `anim_source_max` refreshed from the report, so the single shared offset holds the whole
      stride on world y 592. `walk/05.png` and `walk/06.png` plus their `.import` sidecars are removed. Every other
      L!ckshot pose and sequence, and every combat timing, hitbox, damage value and FSM rule, is untouched.
    - **Checks actually run** — Godot **4.5.stable.official (876b29033)** headless, Web single-thread templates
      installed locally (never committed): `--import`, then `--script res://tools/headless_roster_check.gd` →
      **101 assertions, `ALL CHECKS PASSED`, exit 0**, including the walk frame count (4), the 9 fps loop, the
      explicit **0.00 px** sole-bob measurement across all four frames and the walk-vs-idle height match;
      `--export-release "Web" ../docs/index.html` rebuilt `docs/` (pck 16.0 MB).
    - **Not verified.** No display or GPU in this environment: the stride was not watched in motion and the art
      remains **UNAPPROVED**. Owner review of `review/walk-strip.png` and an on-device playtest are still required.

40. **Both walks retimed with 3rd Strike-inspired uneven frame durations — zero art, speed or hitbox change (2026-11-19).**

    - **Data and engine path.** `FighterRoster` now carries an optional `anim_frame_duration` table per fighter.
      Godot's durations are **relative**: `absolute = duration / (animation fps × playing_speed)`, so the tuned
      base rates stay in charge (L!ckshot **9 fps**, Feedback **4.4 fps**). Godot **4.5** exposes
      `SpriteFrames.get_frame_duration()` but **not** `set_frame_duration()`, so
      `FighterRoster.apply_frame_durations()` rebuilds each retimed animation from its own textures with
      `add_frame(texture, duration)` — animation speed and loop mode persist — and calls the setter directly if
      a newer engine provides it. Only `walk` is retimed.
    - **L!ckshot — Coiled Veteran Strut.** `walk` 01..04 = **[0.8, 1.4, 0.8, 1.4]**: the foot-plant frames snap
      at 0.8× and the passing/coil frames hold at 1.4×, so he lingers in the selector dip before each Clarks
      shoe plants. This supersedes the even 9 fps cadence while keeping the 9 fps base rate.
    - **Feedback — Upbeat Dancehall Skank Bounce.** `walk` 01..04 (`01_contact_a`, `02_pass_a`, `03_contact_b`,
      `04_pass_b`) = **[1.3, 0.75, 1.3, 0.75]**: the grounded plant / skank dip holds at 1.3× and the mid-step
      transfer snaps at 0.75×, for a weighted 132 BPM bounce instead of an even treadmill. The 4.4 fps base
      rate is unchanged.
    - **Isolation.** Presentation data only: no PNG, `anim_scale` or `anim_offset` changed; walk speeds remain
      Feedback **220** / L!ckshot **205** px/s; every hitbox, damage value, attack timing and non-walk animation
      is untouched. Feedback's `SpriteFrames` live in `BaseFighter.tscn`, so
      `BaseFighter.apply_fighter_profile()` duplicates that resource per instance before writing durations and
      never mutates the packed scene resource; L!ckshot's built frames are already per-instance.
    - **Checks actually run.** Godot **4.5.stable.official (876b29033)** headless,
      `--script res://tools/headless_roster_check.gd` → **104 assertions, `ALL CHECKS PASSED`, exit 0**, including
      both exact duration tables, unchanged 9 / 4.4 fps base rates and 205 / 220 walk speeds, the 0 px sole bob
      and the walk-height match (**150.68 vs 150.97 px, Δ0.29**). `--export-release "Web" ../docs/index.html`
      rebuilt `docs/`; `review/walk-loop-preview.gif` was re-rendered with the 0.8×/1.4× timing.
    - **Not verified.** No display or GPU: the new bounce and strut were not watched in-engine. Owner judgement
      of the rhythm and an on-device playtest are pending; the art remains **UNAPPROVED**.

41. **2.5D arcade presentation overhaul — rim light, directional sand shadows, stage depth, impact
    juice and camera (2026-11-20).**

    Owner brief: the high-res sprites still read as flat 2D cut-outs pasted over a backdrop. This pass
    locks them into the stage's light **without changing any sprite art, PNG proportion, y = 592 floor
    alignment, or combat hitbox/timing**. Every system below is presentation-only: nothing in it is read
    by the FSM, the hit registry, damage, knockback, the beat clock or the seeded simulation.

    - **Fighter rim light** — `godot/scripts/stages/fighter_rim_light.gdshader`, a CanvasItem shader on
      the `Sprite` in `BaseFighter.tscn`, so all three roster fighters inherit it from the shared scene.
      Directional rim from the sprite's own alpha gradient: nine clamped texture taps, one pass, no
      screen/depth reads, no includes, no unbounded loops — WebGL2 / GL Compatibility safe on Intel
      Chromebooks. **Sunset** wraps golden-amber; **Night** blends cyan on one side into magenta on the
      other inside the same pass. A warm sand **bounce** tint rides the lower legs and Clarks, and
      `hit_flash` is the dynamic white/gold impact uniform the existing `flash_impact()` drives.
      `BaseFighter.set_rim_light()` pushes the palette; the `sprite_facing` uniform cancels the sprite
      mirror so the rim stays on the stage's light side when a fighter turns.
    - **Directional sand shadows** — `GroundShadow` is now a sheared ellipse stack, not a squashed
      circle: the far edge drags out along the sand away from the light (`shadow_lean()` ≈1.28 px per px
      of half-height at the Sunset 1.95× stretch, negative at Night), thinner with a low sun
      (`density` 0.85 Sunset / 0.72 Night / 1.0 Afternoon), still scaling smoothly through jumps and
      launches. Geometry rebuilds only when the light changes; the per-frame path stays a transform
      write. Fighter shadows remain on the **y 600** origin line and every drawn sole on **y 592**.
    - **Kicked-up sand** — `BaseFighter._puff()` gained a `push_x` direction bias and a hard 16-particle
      ceiling. Walking steps, jump takeoff, jump landing, heavy-strike foot plants (K/L/I), throws,
      skids, knockdowns and speaker-stack slams throw sand away from the plant instead of straight up.
    - **Layered stage depth** — `LightBeams` (z 4, additive, 3 cones × 6 stacked quads) sweeps down from
      the Sunset sky / Night trusses across the speaker stacks and fighters; `HeatHaze` (z −5) draws 11
      drifting shimmer streaks plus a 16-particle soft golden-mote emitter. Both are primitives and CPU
      particles: no shader, no screen reads.
    - **Foreground clash crowd** — `ForegroundCrowd` (z 8: in front of the fighters at 0, behind
      `BirdHazard` 20 and `ImpactFrame` 30) draws a darkened, out-of-focus band of heads, raised hands,
      waving rags and flickering lighters along the bottom screen edge, pinned to the camera's visible
      rect at any zoom so it reads as standing inside a packed yard.
    - **Impact juice** — heavy hit-stop is now **4 frames** on the jab and **6** on `strong`, `tump` and
      `upper_box`, inside the owner's 4–6 frame request. A counter-hit is detected before the strike
      mutates state (`BaseFighter.is_counterable()` → `result["counter"]`) and keeps the 6-frame freeze,
      paying its extra weight in a 1.4× shake, a micro-zoom and the comic frame. `NoteTrail` arcs
      varied-size multicoloured ♩ ♪ ♫/♬ notes along heavy and on-beat strikes (light jabs stay clean);
      `ImpactFrame` draws three frames of black-and-gold comic ink with a gold star burst. Both are
      capped (3 trails, 1 frame) and both are primitives — no texture or font atlas.
    - **Camera** — the framing zoom now eases instead of snapping (`CAMERA_ZOOM_SMOOTH`), still zooming
      in as fighters close and out as bodies are thrown apart, plus `_zoom_punch_burst()` on counters and
      on the 100 % Hype Surge, where `TestHud`'s banner already reads **FORWARD! / PULL UP!**
      (item 10, §8); the subtitle keeps rotating the approved Patois pool from item 38.
    - **Phase palette** — `TestArena.TIME_PHASES` gained `rim_a` / `rim_b` / `rim_strength` / `light_uv` /
      `bounce` / `shadow_density` / `beam` / `haze` / `fg`. `set_time_of_day()` cross-fades all of them
      with `_vis_tween` alongside the existing sky, floodlight and crowd tween, so a round change reads
      as one lighting change rather than five.
    - **Chromebook budget** — every emitter is ≤16 particles and the whole scene is 64 (two fighters +
      heat motes + the existing wind motes), asserted headlessly. No multi-pass post-processing, no
      `SCREEN_TEXTURE`, no threads, no new textures beyond one generated 32×32 radial gradient.
    - **Deliberately unchanged** — no sprite PNG, import cap, scale, offset, `y = 592`
      (`REACTION_FLOOR_Y`) or `y = 600` floor line, hitbox position/size, startup/active/recovery,
      damage, hitstun, knockback, guard, AI, beat window, round flow or roster data.
    - **Verified headless (Godot 4.5.stable, 876b29033):** `tools/headless_roster_check.gd` now prints
      **155** checks and ends `ALL CHECKS PASSED`. The shader is genuinely compiled: headless
      `Shader.get_shader_uniform_list()` returns 11 uniforms, and a syntax error returns 0 (verified by
      deliberately breaking a probe shader). See the verification section at the end of §9.
    - **Not verified — no render happened.** This environment has no GPU or display, so the actual rim
      colour, shadow softness, beam density, foreground silhouettes, note shapes and impact frames have
      **not been seen**. They need a look at `docs/index.html` on the target Chromebook.

42. **3D cel-shaded fighter presentation — the two uploaded models, the Node3D 2.5D plane and the ink/toon pass (2026-11-21).**

    Branch `feature/3d-cel-shaded`, created from `stage/sound-clash-sand` at `3f13116` (the
    `f5eb926` 2.5D presentation pass plus its two asset-upload commits). The stage branch and
    its 2D build are untouched. **Presentation only:** the authoritative fight still runs in
    the 2D `CharacterBody2D` fighters, so every hitbox, hurtbox, attack timing, damage value,
    input buffer, beat window, round timer and Patois callout below is unchanged.

    **Upload inspection.** The two files at the repository root were opened in Godot 4.5:

    | Upload | Bytes | Format | Mesh | Rig | Clip | Texture |
    | --- | --- | --- | --- | --- | --- | --- |
    | `Fighting Idle (1).fbx` | 4,788,128 | Kaydara FBX Binary | **40,000 tris** / 26,215 verts | Mixamo, **25 bones** | `mixamo_com`, 3.30 s, 21 tracks | embedded 4096² atlas |
    | `c534c936-46ff-4878-8dc5-e96053704264 (2).zip` → `output.fbx` | 16,760,749 (4,142,476 FBX) | FBX Binary | **40,000 tris** / 26,215 verts | **none** | **none** | 4096² albedo JPEG + 4096² roughness PNG |

    Both files are the **same Feedback mesh** — identical triangle/vertex count, AABB and
    material name. One export keeps the Mixamo rig and its single idle clip; the other is a
    static bake. There is no second distinct character and no Walk/Attack/Block/Hit/Knockdown
    clip in this upload. **Do not describe them as two different fighters in owner-facing copy.**

    **Files and paths.** Moved byte-identically into `godot/assets/models/fighters/` and removed
    from the repository root (root is spotless again):
    - `feedback_fighting_idle_rigged.fbx` — SHA-256 `c590259b…e273d2c6`
    - `lickshot_placeholder_static.fbx` — SHA-256 `8ea6acb8…ca606322` (archived reference only;
      no fighter slot loads it)
    - `feedback_fitted_jacket_albedo.jpg` — SHA-256 `c4cb0ff4…30c1cb7c`
    - roughness PNG kept as provenance only at
      `artifacts/sound-clash/art-source/models/feedback_upload_roughness.png`.
    Full inventory, import contract and checksums: `godot/assets/models/fighters/MODELS.md`.
    `fbx/embedded_image_handling=0` for both; the shared albedo imports at 2048² with mipmaps
    (`process/size_limit=2048`, `detect_3d/compress_to=0`) to stay inside Chromebook/iPhone
    WebGL2 texture memory. Godot's extracted `*_0.png` images are not committed.

    **Cel shading.** `godot/assets/shaders/toon_cel.gdshader` is a spatial material with
    `diffuse_toon, specular_toon` banding, a rim term and the hit-flash uniform;
    `toon_outline.gdshader` is the inverted-hull `cull_front` `next_pass`, expanded in clip
    space so the ink edge is a constant ~2 px at any camera distance or model scale. Both are
    single-pass, unshaded/forward, with no screen/depth reads, no includes and no unbounded
    loops — WebGL2 / GL Compatibility safe. `FighterModel3D.gd` builds one `ShaderMaterial` per
    model, assigns the outline as `next_pass`, and measures the model's own skeleton/AABB to
    normalise it to **1.55 m** (Feedback, feet at world y 0), independent of the FBX's authored
    centimetre-ish unit scale. Directional rim + the Scene's 3D lights do the lighting; the
    material is not baked flat.

    **Facing.** Undeformed rest bones put Mixamo's left hand on +X and the face on +Z, so the
    model yaw is `facing × 90°` about Y; a fighter facing right shows its +X side, and the
    turn is a rigid yaw (no art mirroring, preserving §9 item 2).

    **State wiring.** The rigged upload plays its baked `mixamo_com` idle clip as the base, and
    `FighterModel3D._animate_rig()` layers the fight states additively on the skeleton after the
    AnimationPlayer has written the frame (process priority 100): walk leg/arm swing, guard
    arms, attack wind-up/lunge/recoil, spine and head hit recoil, crouch, taunt arm and
    celebration. `_animate_pose()` adds the whole-body procedural layer for both uploads:
    Dancehall bob, forward/back lean, strike lunge, hit-recoil, jump/crouch squash, tumble spin
    and a knockdown/KO fall about the feet. This is the clean procedural fallback the brief asked
    for while per-state Mixamo tracks are pending; the combat timing is not driven by it.
    The procedural layer is retained for any future rig that arrives without state clips; the
    current Feedback rig uses it together with the additive skeletal stances.

    **Default mirror showcase (2026-11-21).** `MatchSetup.DEFAULT_P1` and `DEFAULT_P2` are both
    `feedback`, so the untouched title screen boots **FEEDBACK vs FEEDBACK** on the rigged model.
    `Arena3D._apply_mirror_variants()` checks that both fighter keys match and then calls
    `FighterModel3D.set_mirror_variant(true)` on P2 only: a cool jacket tint
    `Color(0.80, 0.90, 1.10)`, `hue_shift` 0.030 and a gold rim `Color(1.0, 0.70, 0.26)`, against
    P1's warm cream rim `Color(1.0, 0.88, 0.62)`. P1 keeps the owner's neutral material; a
    non-mirror opponent is never tinted. Presentation only.

    **Lickshot is a billboard again (2026-11-21).** The static second upload is no longer
    assigned to him: `MODEL_SOURCES` has no `lickshot` entry, so `Arena3D._make_fighter()` falls
    through to `FighterBillboard3D`, which mirrors his approved `AnimatedSprite2D` frames onto a
    camera-facing `Sprite3D` at **1.57 m**. `lickshot_placeholder_static.fbx` stays archived in
    `assets/models/fighters/` for reference and must not be assigned to a fighter. Replace it
    with his own rigged upload when it arrives; no combat or billboard code changes.
    **Superseded 2026-11-22 by item 49:** L!ckshot now renders from the uploaded `lickshot.fbx`
    as a `FighterModel3D`; the billboard remains only as the fallback for a missing upload.

    **L!kkle Moore fallback.** He has no 3D upload, so `FighterBillboard3D.gd` mirrors his
    current approved `AnimatedSprite2D` frame onto a camera-facing `Sprite3D` on the 3D plane,
    normalised to his 82 % relative height (1.27 m). His shared FSM, y 592 art and +25 px reach
    are untouched.
    **Superseded 2026-11-22 by item 49:** he now renders from `likkle_moore.fbx` as a
    `FighterModel3D` at the same 82 % height; the 2D art stays as the fallback.

    **Combat preservation.** `BaseFighter.set_3d_presentation(true)` hides only `Sprite`,
    `Shadow` and `Dust`; the body, hurtbox, hitbox, collision shapes and every numeric table stay
    alive. `TestArena.presentation_3d` (default true) installs the 3D layer; setting it false
    restores the previous 2D drawing path without a code change.

    **Verified headless.** `tools/headless_roster_check.gd` now prints **210** checks and ends
    `ALL CHECKS PASSED` (200 before the mirror pass), including: the default **FEEDBACK vs
    FEEDBACK** arena with both sides on the **40,000**-triangle **25-bone** rig, both baked idle
    clips playing, only P2 carrying the cool/gold mirror accent with a distinct rim, Lickshot on
    the `Sprite3D` billboard at 1.57 m with no `FighterModel3D` proxy, the archived static FBX
    still present but unassigned, Feedback's 1.55 m height and feet offset, the outline
    `next_pass`, the toon and outline shaders **compiling** (uniform lists non-empty) and being
    WebGL2-safe, the 2D stage/sprites hidden, both hitboxes alive, and the 55–65 % camera framing
    (measured **60.3 %**). No GPU/display exists here, so the actual rendered cel bands, ink
    weight, silhouette, mirror tints and model identity have **not been seen**.

43. **3D Sound Clash yard, real lights, camera and music-note impact bursts (2026-11-21).**

    `godot/scripts/stages/Arena3D.gd` is a `Node3D` presentation layer added by `TestArena`. It
    maps the fighting plane as **140 px = 1 m**, world y 0 = the 2D floor line (y 600), world x 0
    = stage centre (x 640); fighters stay on z 0 and only inherit the 2D x/y, so movement remains
    classic 2.5D and collisions never enter 3D.

    - **Yard geometry** — real perspective sand floor, damp-sand discs, a deep sky-gradient
      backdrop, a low horizon band, a metal crowd barrier, two **3D speaker stacks** (plinth,
      three cabinets each, Rasta stripe insets, 16 subwoofer/tweeter/horn cones, a sub-bass
      chimney), a truss with four fixtures, and 26 low-poly crowd figures with unsynchronised
      sway. No wooden crates and no 2D circles.
    - **Lighting** — a real `DirectionalLight3D` sun (shadow-casting, 2-split), two overhead
      `SpotLight3D` pools on the fighters, a warm `OmniLight3D` rim behind them, a cool camera
      fill, depth fog, and a visible additive light pool on the sand. **Afternoon** is a bright
      high sun with the spots resting (sun 1.35 / spot 0.35); **Sunset** drops the sun warm and
      low (spot 0.70, orange sky, sun disc low on the right); **Night** kills the sun (0.12) and
      carries the yard on the spot rig (2.60, cool white/cyan rim, thick fog, no sun disc). The
      arena's existing `set_time_of_day()` drives `Arena3D.apply_phase()` and cross-fades every
      value; this is scene light, not a full-screen tint. The 2D phase nodes remain alive but
      hidden so the older checks and the fallback still work.
    - **Contact shadows** — a soft `contact_shadow.gdshader` quad under each fighter, following
      x/z, shrinking and fading with jump height. It is not a real-time shadow map, so it stays
      cheap on Intel Chromebooks.
    - **Camera** — a steady `Camera3D` (fov 30, 4.8 m, height 1.0) that follows the fighters'
      midpoint horizontally, clamped to the yard. **60.3 %** screen height at neutral play,
      inside the requested 55–65 %. Heavy counters/knockdowns/KOs call `hit_kick()` for a brief
      zoom-in (fov −3.2°) plus decaying shake; the combat hit-stop itself is untouched.
    - **Music-note bursts** — `MusicNoteBurst.gd` replaces generic hit sparks with real 3D
      geometry: eighth notes, sixteenth notes and a stylised treble clef generated as `ArrayMesh`
      triangles in Rasta green/yellow/red, plus an expanding `TorusMesh` bass shockwave ring on
      significant hits. No font glyph or texture atlas, so no missing-glyph risk in the Web
      build. Capped at **4** simultaneous bursts (oldest recycled); each self-frees in 0.72 s.
      Sparks, smears and the old 2D `NoteTrail` route into this system while the 3D layer is on.
    - **Speaker reaction** — `pulse_speakers()` is called on every 132 BPM beat, on heavy
      contacts, tags, throws, K.O.s and round starts; the cones punch out along their local
      depth and settle.
    - **Verified headless** — the `Camera3D` is current, framing 55–65 %, both stacks
      expose 16 cones and the first cone moves >1.0× on a pulse, fog is on, the three lighting
      phases produce the expected sun/spot energies and sky/fog values, `set_time_of_day(2)`
      drives the 3D rig, and note bursts cap at 4 with generated glyph geometry. **No render
      happened:** the actual cel banding, ink weight, speaker stack silhouette, shadow softness,
      note shapes and camera feel have not been viewed on screen.

44. **Event-driven Sound Clash audio engine — tape-delay DJ tags, priorities and crowd layers (2026-11-21).**

    `godot/scripts/audio/SoundClashAudio.gd` is an autoload (`SoundClash`) plus
    `godot/assets/audio/default_bus_layout.tres` and the `[audio]` project setting. No mandatory
    pull-up and no combo gate: *any* strike that lands significant damage, knockback, stun or a
    knockdown triggers the attacker's DJ tag, including a single jab (damage 8). Blocked hits and
    parries do not.
    - **Round-start sting** — a dedicated `Stinger` slot, **6.00 s**, started on
      `RoundController.round_started` (the 1.8 s announce). "Step up!" call + accelerating snare
      roll through the announce, then a single guitar stab and sub drop at **1.8 s = FIGHT!**,
      then a clean tail to 6.0 s. Player control still opens on the RoundController's own clock;
      the audio never gates input.
    - **Native tape-delay chain** — buses `Master / Music / SFX / Crowd / DJTag / Selector /
      Stinger`. `DJTag` carries `AudioEffectDelay` (dry 0.55, taps 265 ms / 530 ms, feedback
      300 ms at −9.5 dB with a 3.6 kHz feedback low-pass) → `AudioEffectLowPassFilter` (4.2 kHz)
      → `AudioEffectReverb` (0.62 room, 0.32 wet, 28 ms pre-delay). Tags play **dry** into that
      bus, so one call cascades under the crowd instead of stacking dry clips. `Selector` has its
      own short echo. The layout is a real `.tres` and the runtime `_ensure_buses()` guard is
      idempotent, so a stripped project still builds the chain.
    - **Priority / anti-overlap** — three tag voices, per-fighter cooldown **1.1 s**, global tag
      cooldown **0.45 s**, selector 3.2 s, horn 4 s. Equal-or-lower priority is rejected while a
      tag is ringing; K.O. (priority 4) force-preempts. `SoundClashAudio.trigger_tag()` is the
      public path used by the arena and the headless checks, so tests cannot bypass the rules.
    - **Crowd intensity** — three looping layers (murmur → cheers → eruption) driven by a 0–1
      level that decays at 0.055/s and reaches **true silence** below 0.01. Tags, heavies,
      knockdowns, throws, parries, Hype Surge and K.O. raise it; the tag also ducks Music
      (−8 dB at full duck) and Crowd (−4 dB) so the selector sits on top instead of mud.
    - **Placeholders, clearly labelled** — the repository still has no approved recordings, so
      every slot synthesises a deterministic 22.05 kHz mono placeholder in memory (voice-like
      formant calls, snare roll, guitar chord, horn, crowd noise). No research clip, sample pack
      or copyrighted recording is loaded from `artifacts/` or the web. `placeholders/` is empty
      by design; `production/` documents the exact override filenames and buses. Placeholders
      prove timing/routing/mixing only and are **not owner-approved sound design**.
    - **Verified headless** — buses and the three effect classes present in order, sting length
      **6.00 s** with its FIGHT marker equal to `RoundController.announce_seconds`, a single
      significant hit firing one tag and the cooldown rejecting the repeat (1 fired / 1
      rejected), equal-priority anti-overlap dropping a duplicate, the answer passing once clear,
      a landed throw firing its own `tag_played` event, crowd level rising from silence, and K.O.
      outranking a ringing tag (horn + selector). The arena listens for `tag_played` and punches
      the 3D cones on the tag itself, not only on the contact that caused it; the old procedural
      airhorn is no longer layered under the engine's horn.
      **Not heard:** headless has no audio device, so the actual cascade, mix balance, crowd
      layers and sting sync have not been listened to on the target device.

45. **New owner Patois callouts — TEK WEH HIM MIC! and TUMP OUT HIM TEET! (2026-11-21).**

    Added verbatim to `TestArena.CALLOUTS` and §8, with separate English glosses:
    - `TEK WEH HIM MIC!` = "Take away his microphone!" — `&"stun"`, fired when a fighter enters
      `KNOCKDOWN` and on a heavy stunned contact.
    - `TUMP OUT HIM TEET!` = "Knock out his teeth!" — `&"heavy"`, fired on an unblocked
      `upper_box` / `tump` contact or a counter-hit.
    Both ride the existing subtitle pill and its cooldown, so a burst cannot stack banners. They
    do not change damage, hitstun or any combat value. Headless checks cover the exact spellings,
    the trigger wiring and the separate glosses.

46. **Backlog recorded, not implemented: B13 Toronto Selector Party & Jukebox, B14 World Clash tour, B15 Panicking Promoter & crowd shout-outs (2026-11-21).**

    Recorded in the backlog below and in `artifacts/sound-clash/SOUND_CLASH_CULTURE.md` as
    **[TODO] — record only, do not implement yet**. No title-menu mode, jukebox, ladder,
    commentator or shout-out system was built in this branch.

47. **FEEDBACK vs FEEDBACK 3D showcase is the default; Lickshot's static clone retired (2026-11-21).**

    Owner request: make the mirror match the default 3D showcase and stop presenting the static
    Feedback bake as Lickshot.
    - `godot/scripts/MatchSetup.gd` now exposes `DEFAULT_P1` / `DEFAULT_P2`, both `&"feedback"`,
      and the title screen already renders those values, so P1 **FEEDBACK** vs P2 **FEEDBACK**
      is what a fresh boot shows with no selection changes.
    - Both slots load `feedback_fighting_idle_rigged.fbx` through `MODEL_SOURCES`; the arena
      verifies both proxies have the 25-bone skeleton and 40,000 triangles.
    - `FighterModel3D.set_mirror_variant(true)` is applied to **P2 only** when both fighter keys
      match. It swaps the material tint to `Color(0.80, 0.90, 1.10)`, raises `hue_shift` to
      0.030 and changes the rim to gold `Color(1.0, 0.70, 0.26)`; P1 stays on the owner's
      neutral tint and cream `Color(1.0, 0.88, 0.62)` rim. No shader/material value enters the
      combat simulation; `BaseFighter` is untouched by the variant.
    - `lickshot_placeholder_static.fbx` is **archived**: the `lickshot` entry is gone from
      `MODEL_SOURCES`, so `Arena3D._make_fighter()` selects `FighterBillboard3D` and mirrors his
      approved 2D frames at 1.57 m. The FBX remains in `assets/models/fighters/` for reference
      and must not be assigned to a fighter again.
    - Headless: **210 PASS / 0 FAIL**, `ALL CHECKS PASSED`. New checks cover the default
      FEEDBACK vs FEEDBACK arena, both rigs and their bones/triangles, P1-vs-P2 mirror accent and
      gold rim, both baked idles playing, Lickshot's billboard texture/height, the absence of a
      `FighterModel3D` proxy for him, and the archived-but-unassigned static file.
    - `/docs/index.html` rebuilt: `index.pck` **24,183,692 B** (24,181,004 B before this pass),
      `index.wasm` 38,057,390 B, `index.js` 305,185 B, `index.html` 5,449 B.
    - **Not verified:** no GPU/display, so the rendered mirror tints, gold rim, billboard art
      alignment and the two-model mirror framing have not been seen on screen. The static bake
      stays in the asset tree only to preserve provenance; it is not part of any match.


48. **Menu / victory beat bed — the owner's three production beats, with active rounds kept music-free (2026-11-21).**

    Three creator-owned reggae hip-hop uploads were moved off the repository root and wired to a
    new `MusicBed` bus through the `MusicBed` autoload. The fight itself is deliberately
    **music-free** so the 6 s round sting, tape-delay DJ tags, selector, horn and crowd layers
    are never muddied.
    - **Files** — `godot/assets/audio/production/beats/`:
      | Slot | Clean file | Original upload | Decoded length |
      | --- | --- | --- | --- |
      | Beat 1 | `beat_01.mp3` | `Buck Shots (2) wonder productions .mp3` | **23.38 s** |
      | Beat 2 | `beat_02.mp3` | `Easy Rider.mp3` | **262.84 s (4:22.8)** |
      | Beat 3 | `beat_03.mp3` | `Lonely Gyal wonder productions.mp3` | **90.04 s** |
      A fourth upload, `Wonder Production.mp3`, has no song title and the same 90.04 s duration
      as Beat 3 but a different audio payload. It is preserved (not deleted) at
      `artifacts/sound-clash/audio-source/beats/Wonder Production (untitled upload,
      same duration as beat_03).mp3` and is **not** in rotation. The owner can promote it if it is a distinct mix.
      Full provenance and policy: `production/beats/README.md`.
    - **Bus** — `MusicBed` added to `default_bus_layout.tres` (−4 dB, → Master). `Music` remains
      the 132 BPM metronome click. The bed is a separate autoload (`scripts/audio/MusicBed.gd`)
      so it survives scene changes, loops each MP3, and fades between screens.
    - **Title / Character Select** — `TitleScreen._ready()` and `_enter_setup()` call
      `MusicBed.play_title()`; the active beat fades in over 0.8 s at −7 dB. `_enter_setup()` also
      restarts the bed on the first gesture so browser autoplay unlock cannot swallow it. The
      setup screen prints `BEAT n — TITLE · M TO CYCLE`.
    - **Match start** — `TitleScreen._start()` calls `MusicBed.stop_for_fight()` before the scene
      change, and `TestArena._ready()` calls it again, so the bed fades to −60 dB and stops during
      the 1.8 s announce. It stays off through FIGHT!, every round and the final blow.
    - **Victory** — the final-round K.O. hook in `TestArena._on_round_ended()` calls
      `MusicBed.play_victory()` immediately (rotation advances Beat 1 → 2 → 3 → 1), and
      `rounds.match_ended` guarantees it without advancing twice. The winner poses out at −4 dB.
    - **M key** — on Title/Character Select and the post-KO/victory screen, M cycles
      Beat 1 → Beat 2 → Beat 3 → Off → Beat 1 for auditioning. During a fight M keeps its old
      meaning (global mute) and never starts the bed.
    - **Verified headless** — **231 PASS / 0 FAIL**, `ALL CHECKS PASSED` (210 before this pass).
      New checks confirm all three files load and loop, decoded lengths (23.38 / 262.84 / 90.04 s),
      the `MusicBed` bus and autoload, Title/Select starting Beat 1, the full M cycle on Title and
      on the post-KO screen, stop-to-silence on match start, MusicBed still silent at
      `RoundController.Phase.FIGHTING`, M acting as mute during the fight, the final K.O. advancing
      to Beat 2, and the victory screen not advancing twice.
    - **`/docs` rebuilt** with `--headless --path godot --export-release "Web" ../docs/index.html`:
      `index.pck` **30,243,396 B** (24,183,692 B before the beats), `index.wasm` 38,057,390 B,
      `index.js` 305,185 B, `index.html` 5,449 B. Export log errors are the known non-fatal
      fontconfig warnings only.
    - **Not heard:** this environment has no audio device, so the actual mix, fade feel, loop
      points and browser/iPhone playback have not been listened to. The bed is intentionally
      absent from combat; if it is ever heard mid-round, that is a regression.


49. **Three uploaded 3D fighters — Feedback v2, L!ckshot and L!kkle Moore playable in the cel-shaded arena (2026-11-22).**

    Owner request on `feature/3d-cel-shaded`: inspect, organise and wire the three new `.fbx`
    uploads that landed at the branch root, replacing L!ckshot's and L!kkle Moore's `Sprite3D`
    billboards with real geometry, and export Mixamo-ready copies. **Implemented and checked
    headlessly; the rendered look is not verified (no GPU/display).**
    - **Files** — the three uploads were moved to `godot/assets/models/fighters/` as
      `feedback_v2.fbx`, `lickshot.fbx` and `likkle_moore.fbx` and removed from the repository
      root. Full inventory, import contract and checksums: `assets/models/fighters/MODELS.md`.
      | File | Mesh | Rig | Face | Embedded albedo |
      | --- | --- | --- | --- | --- |
      | `feedback_v2.fbx` | **29,025 tris** / 23,612 verts | none (static) | +Z | 1024² PNG **RGBA** |
      | `lickshot.fbx` | **270,074 tris** / 151,028 verts → **28,000** after item 50 | none (static) | +X | 1024² PNG RGB |
      | `likkle_moore.fbx` | **246,654 tris** / 139,168 verts → **28,000** after item 50 | none (static) | +X | 1024² PNG RGB |
    - **Texture fix / WebP audit** — every embedded `Video/Content` blob is a standard PNG
      (`\x89PNG`), 8-bit 1024 × 1024, **no WebP/RIFF data**; the earlier WebP concern does not
      apply to this set. The albedos were extracted to `feedback_v2_albedo.png`,
      `lickshot_albedo.png`, `likkle_moore_albedo.png`, alpha-normalised to **RGBA8**, and
      imported lossless with mipmaps and `detect_3d/compress_to=0`, so Godot keeps standard RGBA
      instead of a VRAM-compressed texture. The FBXs import with
      `fbx/embedded_image_handling=0` so the PCK does not carry a second copy of each atlas.
    - **Wiring** — `FighterModel3D.MODEL_SOURCES` maps `feedback`, `lickshot` and `young_selecta`
      (L!kkle Moore's stable roster key) to the three files; `Arena3D._make_fighter()` therefore
      builds a `FighterModel3D` for every slot, and `FighterBillboard3D` is only a missing-upload
      fallback now. Heights are 1.55 m / 1.58 m / **1.27 m** (82 % kid proportion). Yaw offsets
      put each authored face on the fighting axis (Feedback +Z; the Tripo exports +X).
    - **Static-rig limit** — the uploads contain no skeleton, skin or Mixamo clip, so all fight
      motion is the existing whole-body procedural layer: idle bob, walk lean, strike lunge,
      forward/back tilt, hit recoil, crouch squash, throw spin and the knockdown/KO tip. The
      additive skeletal layer is retained for a future rigged upload but idles out.
    - **Normalisation bug fixed** — the GLB→FBX bakes carry a ×1000 root `Lcl Scaling` with
      `UnitScaleFactor 0.1`. `_normalize()` now measures the AABB **through the node transform
      chain**, not the raw mesh AABB, then scales to the authored height and seats the lowest
      bound on world y 0. The raw-AABB path would have scaled these models 1000× too large.
    - **Cel presentation** — every surface gets the Spatial Toon shader plus the inverted-hull
      ink `next_pass` and directional rim band. In a mirror match P2 keeps the cool jacket tint
      (`0.80, 0.90, 1.10`), 0.030 hue shift and gold rim (`1.0, 0.70, 0.26`); P1 keeps white and
      the warm cream rim. Presentation only; no combat value changes.
    - **Mixamo-ready copies** — `models-for-mixamo/` (repository root, outside the game build)
      holds `feedback_mixamo_ready.fbx`, `lickshot_mixamo_ready.fbx` and
      `likkle_moore_mixamo_ready.fbx`. Geometry, UVs and the embedded 1024² PNG atlas are
      byte-identical to the uploads; only the root `Lcl Scaling` and `UnitScaleFactor` were
      rewritten, so the adults open at **180 cm** and the kid at **128 cm** (1 unit = 1 cm).
      README there records the procedure and checksums.
    - **Verified headless** — **256 PASS / 0 FAIL**, `ALL CHECKS PASSED` (231 before this pass).
      New checks cover each model/albedo existing on disk, all three loading as cel-shaded
      `FighterModel3D` nodes with the expected triangle counts, 1024² albedos, Feedback's albedo
      decoding as `FORMAT_RGBA8`, both heights/feet offsets, the ink `next_pass`, the procedural
      lunge following facing and the knockdown tipping the mesh, L!ckshot/L!kkle Moore no longer
      being billboards, and the archived placeholder still present but unassigned.
    - **`/docs` rebuilt** with `--headless --path godot --export-release "Web" ../docs/index.html`:
      `index.pck` **55,143,080 B** (30,243,396 B before these models), `index.wasm` 38,057,390 B,
      `index.js` 305,185 B, `index.html` 5,449 B. Export log has only the known non-fatal
      fontconfig noise; FBX import logs non-fatal ufbx `Bad UTF-8 string` warnings.
    - **Not verified** — no GPU/display here, so the cel bands, ink weight, rim, on-screen texture
      orientation, mirror tint and actual frame rate have not been seen. The 270k/247k-triangle
      meshes are wired exactly as uploaded; Godot's generated LODs are enabled, but a real
      Chromebook frame-time measurement is still required before treating them as shipping-safe.


50. **Three tournament-ready movesets, signature 3D motion and 28k meshes (2026-11-22).**

    Owner request on `feature/3d-cel-shaded` at `f98244b`: give Feedback, L!ckshot and L!kkle Moore
    complete, distinct movesets with readable 3D differentiation, decimate the two large uploads to
    ~28k triangles, assert it headlessly, rebuild `/docs`, document and push. **Implemented,
    headlessly verified; rendered 3D and device frame rate are not verified (no GPU/display).**

    - **Feedback keeps 100 % of his combat data.** `FighterRoster` has no `moves` entry for him, so
      `jab 4/3/9`, `strong 9/4/18`, `tump 12/4/12`, `upper_box 8/4/16`, every damage, knockback and
      hitbox value, hitstop and grab timing are unchanged. His differentiation is presentation:
      J open-palm lunge, I rising launch with lift/pitch and Rasta note burst, K bass surge with a
      1.75× speaker-cone punch and note trail, L high Clarks kick with 0.20 m lift and 0.40 rad
      twist, U collar lunge, T lean-back groove, S gold-rim/vinyl parry.
    - **L!ckshot's own numbers** (`FighterRoster.moves`): J mic snap `3/3/7`, 7 dmg, 96×34 box;
      I heavy cross `14/4/20`, 18 dmg, 124×58 box, 380 px knockback, 6-tick hitstop and heavy
      camera shake; K Sonic Clap `11/3/22` plus a travelling **ProjectileWave** — 16 dmg, 4 chip,
      24 stun, 560 px/s for 1.35 s, 78×110; L advancing knee `10/3/16`, 14 dmg, 96×84, 900 px/s
      advance (~190 px through active + recovery). Throw: hold 14, recovery 16, 16 dmg, launch
      540 px/s, big sand burst + the existing tape-delay DJ tag. T builds 12 Hype and always fires
      a Patois callout.
    - **L!kkle Moore's own numbers**: J `3/3/6`, 7 dmg, 109×32 (keeps the +25 px reach);
      I home-run swing `13/5/20`, 18 dmg, **150×78** box, 340 px knockback, note trail; K dictionary
      `12/3/20` plus a short **ProjectileWave** — 17 dmg, 5 chip, **30 stun**, 470 px/s for 0.52 s;
      L sweep `10/3/14`, 11 dmg, 124×38 low box, `low_profile` (crouch hurtbox 79 px) and
      `knockdown`, 500 px/s advance. Throw: hold 9, recovery 8, 10 dmg. T builds 10 Hype and always
      calls out. A counter-hit with I or K routes to **TEK WEH HIM MIC!** instead of the generic
      heavy line.
    - **3D differentiation** — `FighterModel3D.MOVE_STYLES` gives each fighter a startup coil and
      contact drive per attack (lean, forward lunge, lift, depth pitch, yaw twist, squash). The
      static uploads still have no skeleton, so this remains whole-body procedural motion; no
      hitbox, hurtbox or timing reads it. `GRAB` now lunges forward, and the three taunts differ:
      Feedback leans back, L!ckshot drops into a deeper selector lean with a slow shoulder turn,
      the kid bounces with 0.42 rad footwork twist.
    - **Signature effects** — `BaseFighter` emits `attack_became_active` and `projectile_spawned`;
      `TestArena` stages per-move flourishes through `Arena3D`: a spinning gold-rimmed dubplate or
      school dictionary, CPUParticles3D sand bursts, Rasta note trails, cone punches and a
      black-vinyl/gold parry disc. Projectiles live in the `projectiles` group and are cleared at
      round start/end. `ProjectileWave` is authoritative combat: it tests the live hurtbox and
      calls the shared `receive_strike`, so guard/parry/damage/KO rules stay in one place.
    - **Decimation to 28,000 triangles** — `godot/tools/decimate_fbx.py` parses the FBX, sends
      per-corner UVs through pymeshlab's texture-preserving quadric collapse, then rewrites only
      the `Geometry` children of the original node tree. L!ckshot: 270,074 → **28,000 tris /
      20,797 verts / 3,003,222 B**. L!kkle Moore: 246,654 → **28,000 tris / 20,825 verts /
      2,888,610 B**. Boundary locking was disabled because it plateaued at ~31.8k; the embedded
      1024² PNG is byte-identical (1,418,402 B / 1,299,084 B), the root ×1000 scale is untouched,
      and Godot still measures 1.58 m / 1.27 m. The `models-for-mixamo/` copies were regenerated
      from the decimated files at 180 cm / 128 cm with `UnitScaleFactor 1.0`.
    - **Verified headless** — **276 PASS / 0 FAIL**, `ALL CHECKS PASSED` (256 before this pass).
      New assertions: twelve unique move signatures; Feedback's original timings; L!ckshot's
      fast jab, heavy cross and advancing knee; the 150 px home-run box; the low sweep's live
      crouched hurtbox (top 521, height 79) whiffing a standing jab; dubplate/dictionary specs;
      every model under **35,000** tris (29,025 / 28,000 / 28,000); two signature moves per fighter
      producing different 3D pivots; the dubplate spawning both a combat wave and its 3D proxy and
      landing 100 → 84 hp through `receive_strike`; and accelerated kid throw timing.
    - **`/docs` rebuilt** with `--headless --path godot --export-release "Web" ../docs/index.html`:
      `index.pck` **38,626,932 B** (55,143,080 B before decimation), `index.wasm` 38,057,390 B,
      `index.js` 305,185 B, `index.html` 5,449 B. Only the known fontconfig/ufbx warnings.
    - **Not verified** — no GPU/display/audio here, so the actual 3D move silhouettes, disc/book
      props, sand bursts, gold parry rim, cel look and the **60 FPS on Chromebook / iPhone Safari**
      target have not been seen or measured. The triangle budget and the headless hit logic are
      verified; Safari playback still needs a real-device check.
    - **Files changed** — `godot/scripts/BaseFighter.gd`, `godot/scripts/fighters/
      FighterRoster.gd`, `FighterModel3D.gd`, new `ProjectileWave.gd`, `godot/scripts/TestArena.gd`,
      `godot/scripts/stages/Arena3D.gd`, new `godot/tools/decimate_fbx.py`,
      `godot/tools/headless_roster_check.gd`, both decimated FBXs, `models-for-mixamo/`,
      `MODELS.md`, `docs/`, `AGENTS.md` and `godot/AGENTS.md`.


51. **Active 3D DJs and a staggered, zone-loyal silhouette crowd (2026-11-22).**

    Owner request on `feature/3d-cel-shaded` at `0a5eac1`: give the arena an active 3D DJ booth
    between the mid-ground speaker stacks, replace the placeholder crowd with 16–24 varied
    dark-silhouette spectators carrying flags, lighters and airhorns, wire both to the combat
    events on staggered, side-loyal clocks, keep the whole addition under **15,000 triangles**, and
    leave the existing audio engine completely untouched — no crowd voice audio was added, and the
    custom Patois voice clips remain the owner's later upload. **Implemented, headlessly verified;
    the rendered look and the 60 FPS target are not verified (no GPU/display).**

    - **DJ booth and rig (`DJBooth3D`)** — a 2.5 m deck with plinth, cabinet, Rasta-striped front
      panel, two turntables (platter, spinning vinyl + gold label, tonearm), a centre mixer with
      three channel faders, a sliding crossfader and four knobs, booth monitors, and a small gantry
      sign. It stands at world `(0, 0, -3.2)` — centred between the ±2.55 m speaker stacks and
      behind the barrier — in the bay both crowd banks leave open.
    - **Two rim-lit DJs** work it: bucket-hat selector and headwrapped/dreadlocked partner, each a
      hips/torso/head/shoulder rig with a chain detail and forward `reach` so the hands sit over the
      deck instead of behind the cabinet. Acting states: **neutral** (beat nod + skank), **fader**
      (right hand riding the channel faders), **point** (arm out at the side that just connected on
      a heavy hit), **airhorn** (horn lifted on a knockdown, K.O. or DJ tag) and **celebrate**
      (both arms up, records spinning faster). They nod on every 132 BPM downbeat, because
      `Arena3D.beat_pulse()` is called from the existing `_on_beat`.
    - **Silhouette crowd (`CrowdController3D`)** — the 26-capsule placeholder bank is gone. **20**
      spectators (inside the requested 16–24) stand in **two loyalty banks of 10** across three
      rows, each with a varied height (1.55–1.90 m), build, yaw, hat / headwrap / locks / cap /
      beanie, and an articulated waist-plus-torso, head and two two-bone arms with hands. Props:
      **3 waving Jamaican flags** (green / gold / black cloth, whipping harder when excited),
      **6 raised lighters** whose warm flame quads flicker and spark up on heavy hits and Hype
      moments, and **2 airhorn operators** at the inner edge of each bank beside the speaker stacks.
    - **Staggered, zone reactions** — `Arena3D.notify_combat_event(kind, side)` fans one cue to the
      booth and the crowd. Every spectator's delay is its row base (0.12 s per row back) plus
      0.028 s per metre out along the bank plus a seeded jitter, so ringside answers first and the
      ripple reaches the back rows last; nobody moves on the impact frame itself. The scoring bank
      erupts (jump, arms overhead, flags up) while the rival bank throws both hands on its head in
      disbelief; DJ tags, Hype surges and a 0–0 tie lift both banks. Knockdowns, K.O.s and DJ tags
      put the airhorns up. **HIT_LANDED / HEAVY_HIT / KNOCKDOWN / KO / VICTORY** are the cues, sent
      from the handlers `TestArena` already had (`_on_strike_resolved`, the knockdown state change,
      `_on_fighter_died`, `_on_round_ended`), plus `_on_tag_played` and `_on_hype_surge`.
    - **Cost, not a look claim** — one shared `silhouette_rim.gdshader` `ShaderMaterial` per layer
      (a WebGL2-safe single pass, no screen/depth reads), shared primitive meshes cached per size,
      and **13,644 triangles measured from the built meshes** (crowd 11,520 / booth 2,124) against
      the 15,000 budget. `Arena3D.atmosphere_triangles()` reports the real number; the shader's rim
      colour is pushed from the same afternoon/sunset/night palette as the fighters.
    - **Presentation only** — the cues never write to `BaseFighter`, and the headless suite asserts
      health and fighter state are byte-identical before and after a K.O. cue. No audio node,
      bus, synthesised cue or crowd-voice slot was added or changed.
    - **Verified headless** — **302 PASS / 0 FAIL**, `ALL CHECKS PASSED` (276 before this pass).
      The 26 new checks boot the real arena and assert: two DJs, the booth's centred/behind-barrier
      placement, two vinyl turntables + mixer + three faders, the shader compiling (6 uniforms) and
      passing the WebGL2 static lint, 20 spectators in 10/10 banks, 3 flags / 6 lighters / 2 airhorn
      operators, the old capsule nodes being gone, front-row-only reaction at 0.14 s with the back
      rows still neutral, all 20 answering within a beat, P1's bank cheering while P2's 10 are in
      disbelief, lighters lit, a DJ pointing, faders and records still moving, the knockdown/K.O./
      tag airhorn and celebration states, a Hype surge lighting every lighter, untouched health and
      state, the 13,644-triangle budget and the night rim palette.
    - **`/docs` rebuilt** with `--headless --path godot --export-release "Web" ../docs/index.html`:
      `index.pck` **38,664,500 B** (38,626,932 B before this pass), `index.wasm` 38,057,390 B,
      `index.js` 305,185 B, `index.html` 5,449 B. Only the known non-fatal fontconfig noise.
    - **Not verified** — no GPU, display or audio device here, so the crowd and DJ silhouettes, the
      rim, the flag cloth and lighter flames, the stagger's *feel*, booth framing behind the
      fighters and 60 FPS on a Chromebook / iPhone Safari have not been seen or measured. The
      counts, states, stagger order, palette values and triangle cost are verified; the look is not.
    - **Files added** — `godot/scripts/stages/CrowdController3D.gd`, `DJBooth3D.gd`,
      `godot/assets/shaders/silhouette_rim.gdshader`.
    - **Files changed** — `godot/scripts/stages/Arena3D.gd` (booth/crowd construction, event API,
      beat pulse, triangle budget, palette push), `godot/scripts/TestArena.gd` (six cue call sites,
      `_corner_of`), `godot/tools/headless_roster_check.gd`, `AGENTS.md` and `godot/AGENTS.md`;
      plus the rebuilt `docs/` export.


52. **Owner's 31-entry Jamaican Patwa collection wired across the game; menu/victory beats audited (2026-11-22).**

    Owner request on `feature/3d-cel-shaded` at `c7e408c`: confirm the three uploaded reggae
    hip-hop beats are wired for **Title / Character Select and post-KO victory only** (never during
    a round), give **M** a visible audition cycle on both screens, and embed the full 31-entry
    Patwa proverbs & expressions collection in `TestArena.gd` with V-key English glosses and a
    match-intro wisdom banner. **Implemented, headlessly verified; no audio device and no GPU here,
    so nothing was heard or seen.**

    - **Beat inventory (exact production filenames).** The three owner uploads already live in
      `godot/assets/audio/production/beats/`; no file was re-encoded, renamed or moved by this pass.

      | Slot | Production file | Original upload name | Decoded duration | MD5 |
      | --- | --- | --- | --- | --- |
      | Beat 1 | `beat_01.mp3` | `Buck Shots (2) wonder productions .mp3` | 23.38 s | `084e4f13d7ea61a6bc8c2460bff6bd49` |
      | Beat 2 | `beat_02.mp3` | `Easy Rider.mp3` | 262.84 s | `adfbb2b753955b1baee896cc85ed0359` |
      | Beat 3 | `beat_03.mp3` | `Lonely Gyal wonder productions.mp3` | 90.04 s | `b9a4575dc472d9c902b70f38d4534b9f` |

      The fourth upload, `Wonder Production (untitled upload, same duration as beat_03).mp3`, stays
      archived under `artifacts/sound-clash/audio-source/beats/` (MD5
      `3d5b7956a312407d0056b80defc02fcb`, 90.04 s, different payload from Beat 3); it is not in the
      playlist. Rotation is **Beat 1 → Beat 2 → Beat 3 → Beat 1** across matches.
    - **Title / Select** — `TitleScreen._ready()` calls `MusicBed.play_title()`; the bed fades out in
      `_start()` before `MatchSetup.start_match()`, so the 6 s round sting ("Step up!" → stab on
      FIGHT!) takes over with no music under it. **M** on the splash or the select screen cycles
      Beat 1 → Beat 2 → Beat 3 → Off and flashes `MUSIC · BEAT n — TITLE · M TO CYCLE` in the
      top-right corner for 2.2 s; the select screen also keeps its persistent footer line.
    - **Active rounds** — `MusicBed` is off from FIGHT! through the final blow. **M** during a fight
      remains the existing Master-bus mute toggle and cannot start a beat.
    - **Post-KO / victory** — the final-round K.O. celebration calls `MusicBed.play_victory()`,
      advancing to the next beat and fading it in under the pose; `match_ended` does not advance a
      second time. **M** on the post-KO screen cycles the audition and flashes the same corner label
      (`MUSIC · BEAT n — TITLE · M TO CYCLE`).
    - **31-entry collection** — `PATWA_COLLECTION` holds all 31 phrases; `CALLOUT_GLOSSES` is the
      single gloss field (the Patwa spelling is never folded into it). The 22 in-match lines fill
      `heavy`, `counter`, `stun`, `parry`, `throw_break`, `taunt`, `hype`, `round_win` and
      `wash_belly`; the 9 traditional proverbs fill `PROVERB_BANNER`. `WASH-BELLY` is reserved for
      L!kkle Moore through `_impact_callout()`. The match-intro banner shows one proverb per match
      under `YARD WISDOM`, Patwa always readable, English gloss only while subtitles are on.
      Full table, glosses, wiring map and the I → ! rule note: **§8**.
    - **Verified headless** — **314 PASS / 0 FAIL**, `ALL CHECKS PASSED` (302 before this pass).
      The 12 new checks assert: all three production beats load at their decoded durations
      (23.38 / 262.84 / 90.04 s) and loop; the title screen starts Beat 1 and M's corner label; the
      post-KO bed advances Beat 1 → 2 → 3 across matches; MusicBed stays silent through FIGHTING
      and M stays mute there; the final K.O. celebration starts Beat 2 and the post-KO M cycle
      shows its label; all 31 Patwa entries are unique, resolve to a `(Translation: …)` gloss and
      are wired to a pool or the banner; WASH-BELLY and the counter/heavy routing are
      character/contact correct; the intro banner rotates two different proverbs and V-off hides
      only the English subtitle.
    - **`/docs` rebuilt** with `godot --headless --path godot --export-release "Web"
      ../docs/index.html` (Godot 4.5.stable): `index.pck` **38,674,548 B** (38,664,500 B before),
      `index.wasm` 38,057,390 B, `index.js` 305,185 B, `index.html` 5,449 B. Only the environment's
      known non-fatal fontconfig warnings.
    - **Not verified** — there is no audio device, GPU or display in this sandbox. The songs' actual
      sound, the fades and loop seams, the M-key label's on-screen placement, the banner's fit over
      the 3D yard, and Web/iPhone autoplay are unverified by ear or eye. The 31 phrases were checked
      as data (spelling, gloss, trigger), not as voice performances.
    - **Files changed** — `godot/scripts/TestArena.gd`, `godot/scripts/ui/TestHud.gd`,
      `godot/scripts/ui/TitleScreen.gd`, `godot/tools/headless_roster_check.gd`, `AGENTS.md`,
      `godot/AGENTS.md`, `artifacts/sound-clash/SOUND_CLASH_CULTURE.md` and the rebuilt `docs/`
      export. `godot/scripts/audio/MusicBed.gd` and the three beat files were already in place and
      were not re-encoded.

53. **Four owner playtest fixes: music bleed into Match 2+, real sound-system stacks, arcade type,
    clean human-rig slots (2026-11-23).**

    Owner live-playtested `c74faaf` on `feature/3d-cel-shaded` and reported four high-priority
    presentation / audio problems. **Implemented and headlessly verified; not seen or heard** — the
    sandbox has no GPU, display or audio device.

    - **1. MusicBed can no longer bleed into Match 2+ (critical).** A rematch restarts inside
      `TestArena.tscn` after `RoundController.Phase.MATCH_OVER`, so `_ready()` never re-ran and the
      victory beat started on the previous match's result kept playing under the next match.
      `MusicBed.stop()` is now a new hard cut (kills the fade tween, stops the stream, forces
      −60 dB); `TestArena._on_round_started()` calls it **before** `SoundClash.play_round_start()`,
      and that hook fires for Match 1, Match 2, Match 3 and every rematch / replayed round.
      `_ready()` also hard-stops instead of fading, and `stop_for_fight()` keeps only a 0.15 s fade
      for screen changes. Round start also clears `_match_over` / `_victory_music_started`, so **M**
      returns to the mute toggle and the booth/crowd reset via `Arena3D.reset_atmosphere()`.
    - **2. Authentic Jamaican sound-system stacks.** `Arena3D._build_sound_stack()` replaces the old
      three plain boxes per side with, bottom to top: a plinth; **two stacked double-18" sub bins**
      with a recessed baffle, two 18" drivers in metal surrounds and **metallic protective corner
      brackets**; a mid/bass cabinet with two 15" drivers and a reflex port; a **radial horn tweeter
      box**; and a **rack-mount amp/EQ** with a glowing face, EQ knobs and two channels of
      green → yellow → red **VU LEDs** whose lit count follows the arena's audio-peak cue
      (`_pulse`) on hits, tags and surges. Rasta trim: a woven band across the cabinet seam plus a
      green/gold flag on each horn box. Measured **40 corner brackets**, **40 VU LEDs** (4 lit at
      rest, 40 at a peak), 4 sub bins, 2 racks.
    - **3. Arcade cabinet typography.** `TestHud._text()` now draws every label with a three-step
      extruded drop shadow, a thick black ink outline (`maxi(3, size × 0.24)`), a one-pixel gold rim
      under the face and the crisp face on top. Round / K.O. / rematch banners, `FORWARD!`, the
      `YARD WISDOM` card, fighter names, the round clock and the Patwa callout pill all use gold /
      Rasta accent faces with a **scale-pop entrance** (`POP_GAIN` 0.34 over `POP_SECONDS` 0.26,
      stamped when the banner text changes, when a callout or proverb is shown, and when a Hype
      surge starts). Banners carry a three-block green/gold/red strip along their top edge.
    - **4. Clean human-rig slots — no capsule mannequins.** The capsule/cylinder DJ and spectator
      bodies are gone. Every crowd member and DJ is now a `StageSilhouette`: one camera-facing quad
      (two triangles) wearing a mask painted at start-up by `SilhouetteArt` (signed-distance
      strokes → body coverage + dilated rim channel) through `silhouette_mask.gdshader`. Masks carry
      the bucket hat / headwrap / locks, the neutral skank, arms up, hands-on-head disbelief, the hip
      hop, the fader hand, the point, the horn and the celebration. **`CharacterModelSlots`** adds
      the drop-in slots `godot/assets/models/dj/` and `godot/assets/models/crowd/`: any `.fbx`,
      `.glb` or `.gltf` is instanced at build time, fitted to the slot's height from its own bounds,
      feet on the floor line, first animation started, and the silhouette for that slot is hidden.
      With no files delivered the silhouettes stay on screen (`using_fallback()` is true), so the
      build never depends on missing art. Both folders carry a README with the contract.
    - **Verified headless** — **332 PASS / 0 FAIL**, `ALL CHECKS PASSED` (314 before this pass). New
      coverage: the victory bed is hard-stopped with `-60 dB` before a round start;
      2 stacks / 4 double-18 sub bins / 2 racks / 40 corner brackets; the VU meters climb from 4 to
      40 lit LEDs; 20 + 2 silhouettes with 0 legacy mannequin meshes; the two model-slot folders
      exist and the fallback is active; 20 cached masks/materials; the pop constants and the ink
      outline are present. The existing 302 checks still pass, including the crowd stagger, zone
      loyalty, lighter/flame, horn and palette assertions.
    - **Measured cost** — the new atmosphere budget reads **1,400 triangles (crowd 520 / booth 880)**, down from 13,644, because the 22 articulated rigs became 22 quads. The speaker stacks are yard
      geometry outside `atmosphere_triangles()` and were not added to that budget.
    - **`/docs` rebuilt** with `godot --headless --path godot --export-release "Web"
      ../docs/index.html`: `index.pck` **38,693,836 B**, `index.wasm` 38,057,390 B, `index.js`
      305,185 B, `index.html` 5,449 B. Only the environment's known non-fatal fontconfig warnings.
    - **Not verified — no GPU, display or audio device.** Nothing was seen or heard: the new stack
      proportions, the VU meters ticking, the silhouette art itself (procedurally painted, never
      rendered here), the rim strength through the three lighting phases, the pop timing as an
      audience feels it, and whether a Chromebook / iPhone Safari holds 60 FPS. The music fix is
      verified as state (off, stopped, −60 dB), not by ear. The `.fbx` slots are verified as an
      empty-folder contract; no real Mixamo character has been dropped in or loaded yet.
    - **Files** — added `godot/assets/shaders/silhouette_mask.gdshader`,
      `godot/scripts/stages/{SilhouetteArt,StageSilhouette,CharacterModelSlots}.gd`,
      `godot/assets/models/dj/README.md`, `godot/assets/models/crowd/README.md`; removed
      `godot/assets/shaders/silhouette_rim.gdshader`; edited `godot/scripts/stages/Arena3D.gd`,
      `CrowdController3D.gd`, `DJBooth3D.gd`, `godot/scripts/audio/MusicBed.gd`,
      `godot/scripts/TestArena.gd`, `godot/scripts/ui/TestHud.gd`,
      `godot/tools/headless_roster_check.gd`, `AGENTS.md`, `godot/AGENTS.md` and the rebuilt `docs/`
      export. The audio engine, the beat clock and every combat value are untouched; no crowd voice
      audio was added (still [TODO] until the custom Patois clips arrive).


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

**[TODO] B11. Fighter #3 — Likkle Moore's (L!KKLE MOORE) signature moveset (designed by the owner's son).** Full
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

#### Owner item — mobile touch controls (2026-11-19)

**[TODO] B12. On-screen mobile & tablet touch controls — record only, do not implement yet.** Once the
three-fighter combat loop (Feedback, L!ckshot, Likkle Moore) is locked on keyboard/controller, add clean,
auto-showing arcade virtual touch buttons when the WebGL2 build runs on a phone or tablet: a D-pad /
thumb-stick for movement, jump and crouch, plus **J / K / L / I / S / U / T** (jab, box, tump, upper box,
guard, grab/tech, taunt). The set must appear only on touch devices and touch browsers, must not change the
keyboard or controller bindings, and has to stay inside the 1280×720 canvas without covering the health
bars, name plates, hype bar, round clock or subtitle pill.
- Blocked on: the combat loop being locked (§9 mandatory rule 2, January 14, 2027) and a real phone/tablet
  touch test of the exported Web build.
- Open values: button size and spacing, safe-area insets for notched phones, whether the stick is fixed or
  floating, how simultaneous multi-touch (move + attack + guard) is read from Godot's touch events, whether
  it autohides in landscape vs portrait, and whether a "touch controls" toggle belongs in Character & Match
  Setup.
- Exit evidence: on a phone and a tablet the controls auto-appear on touch and not on desktop, every listed
  action fires, a full round is playable without a keyboard, and the HUD stays legible with the buttons
  present.

**[TODO] B13 — Toronto Selector Party & Jukebox Mode (record only, do not implement yet).**
Standalone Title Menu mode celebrating Toronto's multicultural party melting pot (Reggae, Dancehall,
Hip-Hop, R&B, House and Soca). Players pick a 3D selector (Feedback, L!ckshot, L!kkle Moore) to
dance/skank behind the 3D speaker stacks and talk DJ-style over tracks, with automatic music ducking
and tape-delay mic echo, and can trigger manual **PULL UP! / WHEEL UP!** rewinds and airhorns.
Strictly creator-owned tracks may be streamed and one-click downloaded from `docs/tracks/`; users may
also load local audio files for 100% client-side, in-browser RAM playback only. **Copyright
safeguard:** user files are NEVER uploaded to any server, stored remotely, or distributed to other
players. Not built in this branch: no jukebox scene, no local-file loader, no `docs/tracks/` manifest,
no rewind/ducking UI. Open design: track licensing/provenance per file, whether B13 reuses
`SoundClashAudio`'s DJTag chain, and how a local file is kept in RAM only.

**[TODO] B14 — “World Clash” Arcade Tour & International Bookings (record only, do not implement yet).**
Classic fighting-game world ladder with lightweight promoter-booking progression — never an open
world — where winning clashes unlocks international bookings from Jamaica (Home Beach Arena) to
Toronto, Montreal, New York, London (England) and Japan, each with a distinct 3D stage atmosphere and
an international rival. Not built: no ladder data, booking UI, rival definitions, per-city stage rigs
or unlock save. Open design: bout count per city, difficulty curve, how a stage's atmosphere maps onto
`Arena3D.PHASES`, and whether travel replaces or extends the current best-of-3 Sound Clash.

**[TODO] B15 — Panicking Promoter Commentator & Personal Crowd Shout-Outs (record only, do not implement yet).**
Reactive event-promoter voice slot who panics whenever fighters collide near the speaker stacks
(“Dat coming out yuh fee!”, “Yuh nah get paid fi dat!”, “Me never booking yuh sound again!”), plus
creator-approved crowd shout-out slots dedicated to real-life friends, family and local supporters
(with their permission, avoiding unapproved celebrity names). **Line pool update 2026-11-22:** the
owner's 31-entry Patwa collection adds `BRUK POCKET` (“Short on cash”) to the promoter's panicking
lines — recorded for this future slot only, not wired to any audio or trigger. Not built: no commentator state, no
proximity trigger against the speaker stacks, no shout-out list or audio. Open design: exact
promoter lines/glosses and owner approval, voice recording source, cooldowns against the existing
DJ-tag priority rules, and a written consent record for every shout-out name.

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
| L!ckshot 2026-11-19 batch: 8-pose skank groove, hitstun / launch / tumble / knockdown / KO sequences, C-recoil, three Patois callouts, name pool | Implemented 2026-11-19 (§9 item 38): four uploads archived off the root, sheets sliced and keyed, one shared canvas per animation, every frame on the y 592 sand line, headless 4.5 **99/99**, Web export rebuilt; **art UNAPPROVED and on-screen motion [TODO]**. The 6-frame phone-crop walk was superseded the same day by item 39. |
| L!ckshot clean 4-pose walk sheet (full crowns and Wallabee toes) | Implemented 2026-11-19 (§9 item 39): upload archived as `16_walk-sheet-clean_original.png`, four drawings sliced in reading order onto one 454 × 512 canvas, **0 px vertical sole bobbing**, wired at 9 fps looping in place of `walk/01..06`; scale corrected to match idle height (150.68 vs 150.97 px); headless 4.5 **101/101** at that milestone, Web export rebuilt; **art UNAPPROVED and on-screen stride [TODO]** (2× review loop at `review/walk-loop-preview.gif`). |
| Uneven walk timing for both fighters (3rd Strike-inspired) | Implemented 2026-11-19 (§9 item 40): relative `SpriteFrames` durations — L!ckshot plants 0.8× / coil 1.4×, Feedback skank plant 1.3× / transfer 0.75× — applied without touching art, 9 / 4.4 fps base rates, 205 / 220 px/s walk speeds or any hitbox; rebuilds frames via `add_frame` because 4.5 has no `set_frame_duration`; headless 4.5 **104/104**, Web export rebuilt; **rhythm feel and art [TODO]**. |
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
| `young_selecta` | L!KKLE MOORE | 250 | **+25 px** on every attack | 52×131 (82 %) | idle / thrust / slam mapped onto the existing animation slots |

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

### 2.5D arcade presentation overhaul — headless verification, November 20, 2026

Recorded on branch `stage/sound-clash-sand`; this is the build that adds §9 item 38. The owner brief
was that the high-res sprites read as flat cut-outs over a backdrop, so this pass adds stage light,
projected shadow, depth layers, impact juice and a fighting-game camera **without touching a single
sprite, PNG proportion, y = 592 floor alignment or combat hitbox/timing**.

**Commands actually run** — Godot 4.5.stable.official (876b29033), headless, Web export templates
installed locally in the user profile (never committed):

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" docs/index.html
```

`tools/headless_roster_check.gd` prints **155 PASS / 0 FAIL** and ends `ALL CHECKS PASSED` (99 before the L!CKSHOT and 2.5D
passes joined the tree). The 54 checks added here cover: the rim shader loading and **compiling** (11 uniforms —
`get_shader_uniform_list()` returns 0 for a broken shader, so this is a real parse/compile check), the
WebGL2 static lint (no `hint_screen_texture`, `SCREEN_TEXTURE`, `DEPTH_TEXTURE`, `#include` or `while`),
the shared `ShaderMaterial` on both live fighters, the Sunset golden-amber and Night cyan/magenta
palettes, the shader receiving the artist-facing strength, mirror compensation (`sprite_facing`), the
`hit_flash` raise/clear lifecycle, Sunset/Night shadow lean + stretch + density, the sand-puff and
scene particle budgets (≤16 each, 64 total), heavy vs light sand kicks, the 4/6/9 hit-stop table, the
counter-hit flag and that it changes presentation only (damage identical), beam/haze/foreground
z-order and additive blending, the foreground band pinned to the camera's bottom edge, the note-trail
and impact-frame caps, the camera punch, and that `REACTION_FLOOR_Y` is still 592 and fighter shadows
still sit on y 600.

**Files added** — `godot/scripts/stages/fighter_rim_light.gdshader`, `LightBeams.gd`, `HeatHaze.gd`,
`ForegroundCrowd.gd`, `NoteTrail.gd`, `ImpactFrame.gd`.

**Files changed** — `godot/scripts/BaseFighter.gd` (rim/flash plumbing, counter flag, hit-stop table,
sand push, puff cap), `godot/scripts/stages/GroundShadow.gd` (sheared directional patch + density),
`godot/scripts/stages/CrowdLine.gd` (`set_shadow_density`), `godot/scripts/TestArena.gd` (phase
palette, camera smoothing/punch, note trails, impact frames, counter feedback, surge subtitle),
`godot/scenes/BaseFighter.tscn` (shader material), `godot/scenes/TestArena.tscn` (LightBeams,
HeatHaze, ForegroundCrowd), `godot/tools/headless_roster_check.gd` (new checks).

**`/docs` rebuilt from this commit** with `--headless --path godot --export-release "Web"
../docs/index.html`: `index.pck` **16,087,712 B** (13,883,828 B before L!CKSHOT's items 38–40 joined the tree), `index.wasm`
38,057,390 B, `index.js` 305,185 B, `index.html` 5,449 B.

**Not verified — no render happened.** This environment has no GPU, display or Xvfb, so nothing was
looked at on screen: the actual rim light, the sheared shadow, the beams, the haze motes, the
foreground silhouettes, the note glyph shapes, the comic impact frame and the camera feel are all
arithmetic and geometry, not eyes. Two Chromebook-specific risks remain unmeasured: fill-rate on the
additive full-screen impact frame (three frames, once per counter/surge) and the per-frame cost of the
foreground band at 1.12× zoom. Both are one-pass primitives with no screen reads, but they need a real
frame-time check on the target device.

**Next:** open `docs/index.html` on the Chromebook and play a Sunset and a Night round: confirm the rim
sits on the shadow side, the five depths read (stage → haze → crowd line → fighters → near-crowd), a
counter-hit's black-and-gold frame does not feel like a flashbang, and the foreground band does not
hide a fighter's feet during a corner brawl.

### 3D cel-shaded presentation + Sound Clash audio — headless verification, November 21, 2026

Branch `feature/3d-cel-shaded`, started from `stage/sound-clash-sand` tip `3f13116`; the stage
branch and its 2D build are untouched. This records §9 items 42–46.

**Commands actually run** — Godot 4.5.stable.official (876b29033), headless, export templates
installed locally in the user profile (never committed):

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

`tools/headless_roster_check.gd` prints **200 PASS / 0 FAIL** and ends `ALL CHECKS PASSED` (155
before this pass). The **45 new checks** cover: both uploads' 40,000 triangles, the rigged model's
25 bones and its `mixamo_com` clip, the static model having no skeleton, both normalised heights
and feet offsets, the shared 2048² texture and its mipmaps, the outline `next_pass` and both
shaders **compiling** (uniform lists non-empty) plus the WebGL2 static lint, the 2D stage and
sprites hidden with every hurtbox/hitbox still alive, the Camera3D being current at **60.3 %**
fighter height, the 16 speaker cones moving on a pulse, the afternoon/sunset/night 3D light and
fog values, note bursts capped at 4 with generated glyph mesh geometry, the bus layout and
`AudioEffectDelay → AudioEffectLowPassFilter → AudioEffectReverb` order on `DJTag`, the
**6.00 s** sting whose FIGHT marker equals `RoundController.announce_seconds`, single-hit tag
firing and cooldown rejection, equal-priority anti-overlap and release, the throw `tag_played`
event, crowd rise from true silence, and K.O. priority over a ringing tag.

**Files added** — `godot/assets/models/fighters/` (two FBX files, one albedo JPEG, `MODELS.md`),
`godot/assets/shaders/toon_cel.gdshader`, `toon_outline.gdshader`, `contact_shadow.gdshader`,
`light_pool.gdshader`, `sky_gradient.gdshader`, `sun_disc.gdshader`, `music_note.gdshader`,
`godot/assets/audio/default_bus_layout.tres`, `godot/assets/audio/placeholders/README.md`,
`godot/assets/audio/production/README.md`, `godot/scripts/fighters/FighterModel3D.gd`,
`FighterBillboard3D.gd`, `godot/scripts/stages/Arena3D.gd`, `MusicNoteBurst.gd`,
`godot/scripts/audio/SoundClashAudio.gd`, and `artifacts/sound-clash/art-source/models/
feedback_upload_roughness.png` (provenance only).

**Files changed** — `godot/scripts/TestArena.gd` (3D switch, hazard hiding, effect routing,
audio/callout hooks, new callouts), `godot/scripts/BaseFighter.gd` (`set_3d_presentation` only),
`godot/project.godot` (autoload + bus layout), `godot/tools/headless_roster_check.gd`,
`godot/assets/audio/README.md`, `artifacts/sound-clash/SOUND_CLASH_CULTURE.md` (B13–B15),
`AGENTS.md` + `godot/AGENTS.md`. The two owner uploads were removed from the repository root.

**`/docs` rebuilt from this commit** with `--headless --path godot --export-release "Web"
../docs/index.html`: `index.pck` **24,181,004 B** (16,087,712 B before this pass — the extra
~8.1 MB is the two 4.78 MB / 4.14 MB FBX models and the 2048² texture), `index.wasm`
38,057,390 B, `index.js` 305,185 B, `index.html` 5,449 B. The export log's only errors are the
environment's repeated `Unable to load fontconfig` (known non-fatal; the build uses its own
fallback fonts).

**Not verified — no render and no audio device.** This environment has no GPU, display, Xvfb or
sound card, so nothing was seen or heard: the cel banding, ink weight, model identity and
silhouette, the speaker-stack depth, shadow softness, note-glyph shapes, camera kick and the
actual tag cascade/sting sync are geometry, shader code and bus routing, not eyes or ears. In
particular the **same-mesh** situation means Lickshot is currently a tinted static copy of
Feedback, and his state animation is entirely procedural. Two device risks remain unmeasured:
fill-rate for the 16-cone speaker stacks plus 26 crowd figures on an Intel Chromebook, and
WebGL2 texture memory on iPhone Safari (the 4096² source is capped to 2048² with mipmaps, but
two 40k-tri skinned meshes at once is a real cost).

**Next:** open `docs/index.html` on the Chromebook and an iPhone, play each fighter in Afternoon,
Sunset and Night, and rule on the ink weight, cel bands, 60 % framing, note colours, speaker
pulse, tag cascade and sting sync. Then replace the Lickshot placeholder with his own rigged
model when it is uploaded, and approve or record the production audio slots.

### FEEDBACK vs FEEDBACK mirror showcase — headless verification, November 21, 2026

Owner request on branch `feature/3d-cel-shaded`: make the mirror match the default 3D showcase
and retire Lickshot's static Feedback clone. Recorded as §9 item 47.

**Commands actually run** — Godot 4.5.stable.official (876b29033), headless:

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

`tools/headless_roster_check.gd` prints **210 PASS / 0 FAIL** and ends `ALL CHECKS PASSED` (200
before this pass). The new checks boot the untouched default arena and confirm P1 and P2 are both
`feedback` on the **40,000-triangle / 25-bone** rig with both baked idles playing, that only P2
carries the mirror accent (cool tint `0.80, 0.90, 1.10`, gold rim `1.0, 0.70, 0.26`) while P1
keeps the cream rim, and that Lickshot resolves to `FighterBillboard3D` at 1.57 m with a live
sprite texture and **no** `FighterModel3D` proxy. The archived
`lickshot_placeholder_static.fbx` is checked to still exist on disk and to be absent from
`FighterModel3D.MODEL_SOURCES`.

**Files changed** — `godot/scripts/MatchSetup.gd` (`DEFAULT_P1` / `DEFAULT_P2`),
`godot/scripts/fighters/FighterModel3D.gd` (lickshot source removed; mirror variant),
`godot/scripts/stages/Arena3D.gd` (`_apply_mirror_variants`),
`godot/tools/headless_roster_check.gd`, `godot/assets/models/fighters/MODELS.md`, `AGENTS.md`
and `godot/AGENTS.md`.

**`/docs` rebuilt** with `--headless --path godot --export-release "Web" ../docs/index.html`:
`index.pck` **24,183,692 B**, `index.wasm` 38,057,390 B, `index.js` 305,185 B, `index.html`
5,449 B. The export log's only errors are the environment's known non-fatal fontconfig warnings.

**Not verified — no render.** The rendered mirror tint, gold rim, billboard alignment, billboard
depth sorting against both rigs and the two-model framing have not been seen. The static FBX is
retained only as archived provenance; no fighter slot loads it.

### Menu / victory beat bed — headless verification, November 21, 2026

Owner request on `feature/3d-cel-shaded`: wire the three uploaded beats for Title/Select and the
post-KO victory only, keeping active rounds music-free. Recorded as §9 item 48.

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

**231 PASS / 0 FAIL**, `ALL CHECKS PASSED` (210 before this pass). The new checks load
`beat_01.mp3` / `beat_02.mp3` / `beat_03.mp3` and assert their decoded lengths (23.38 s,
262.84 s, 90.04 s) and looping, then exercise the real TitleScreen input path: Beat 1 starts on
load, M cycles Beat 1 → 2 → 3 → Off → 1, and `stop_for_fight()` reaches true silence. In the
arena they assert MusicBed is off at `Phase.FIGHTING`, that M remains the mute key during the
fight, that the final K.O. starts Beat 2 under the victory pose, that `match_ended` does not
advance twice, and that post-KO M cycles Beat 3 → Off → Beat 1.

**Files changed** — `godot/scripts/audio/MusicBed.gd` (new autoload), `godot/scripts/ui/
TitleScreen.gd`, `godot/scripts/TestArena.gd`, `godot/project.godot`,
`godot/assets/audio/default_bus_layout.tres`, the three beats plus `beats/README.md` and the
archived fourth upload, `godot/assets/audio/README.md`, `production/README.md`,
`godot/tools/headless_roster_check.gd`, `AGENTS.md` and `godot/AGENTS.md`.

**`/docs` rebuilt**: `index.pck` 30,243,396 B, `index.wasm` 38,057,390 B, `index.js` 305,185 B,
`index.html` 5,449 B.

**Not heard — no audio device.** The songs' actual sound, fade shape, loop seam, loudness against
the sting and DJ tags, and Web/iPhone playback are unverified by ear. Browser autoplay is handled
by restarting the bed in `_enter_setup()` on the first gesture, but that needs a real-device check.

### Three uploaded 3D fighters — headless verification, November 22, 2026

Owner request on `feature/3d-cel-shaded`: inspect the three `.fbx` uploads at the branch root,
fix/validate their embedded textures, file them into the game, and replace L!ckshot's and
L!kkle Moore's billboards with real 3D models. Recorded as §9 item 49.

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

**256 PASS / 0 FAIL**, `ALL CHECKS PASSED` (231 before this pass). The new checks assert every
model and albedo exists on disk; all three instantiate as `FighterModel3D` with **29,025 /
270,074 / 246,654** triangles; each albedo decodes at 1024 × 1024 and Feedback's is
`Image.FORMAT_RGBA8`; heights are 1.55 / 1.58 / 1.27 m with feet on world y 0; every material
carries the inverted-hull ink `next_pass`; the procedural lunge moves toward the fighter's facing
and the knockdown tips the mesh; and L!ckshot/L!kkle Moore are no longer `FighterBillboard3D`
while the archived placeholder FBX is still present and unassigned.

**Texture audit.** All embedded images in the three uploads are standard 8-bit PNG at 1024² —
**no WebP data was present**. The albedos were extracted, alpha-normalised to RGBA8, imported
lossless with mipmaps and `detect_3d/compress_to=0`, and the FBXs skip their embedded images at
import so the PCK carries one atlas per fighter.

**Mixamo copies.** `models-for-mixamo/feedback_mixamo_ready.fbx`,
`lickshot_mixamo_ready.fbx` and `likkle_moore_mixamo_ready.fbx` keep the exact geometry and
embedded PNG but are rescaled to 180 cm (adults) / 128 cm (kid) with `UnitScaleFactor = 1.0`,
so they open at human scale in Mixamo's auto-rigger.

**Files changed** — `godot/assets/models/fighters/` (three FBX + three albedo PNG + updated
`MODELS.md`, old uploads archived), `godot/scripts/fighters/FighterModel3D.gd`,
`godot/scripts/stages/Arena3D.gd` (comment-only), `godot/tools/headless_roster_check.gd`,
`models-for-mixamo/` (three FBX + `README.md`), `AGENTS.md` and `godot/AGENTS.md`.

**`/docs` rebuilt**: `index.pck` **55,143,080 B**, `index.wasm` 38,057,390 B, `index.js`
305,185 B, `index.html` 5,449 B. Export logged only the environment's known non-fatal fontconfig
warnings; the FBX import logs non-fatal ufbx `Bad UTF-8 string` warnings from the ImageToStl
writer.

**Not verified — no GPU/display/audio.** The rendered cel bands, ink width, rim lighting, texture
orientation, mirror tint and the actual frame rate of the 270k/247k-triangle meshes have not been
seen on screen. Godot's import generates LODs, but these triangle counts are exactly as uploaded
and still need a real Chromebook frame-time check before being treated as shipping-safe.

### Tournament movesets, 28k meshes — headless verification, November 22, 2026

Owner request on `feature/3d-cel-shaded` at `f98244b`: complete distinct movesets for all three
fighters, per-move 3D differentiation, and 28k-triangle Lickshot/Likkle Moore meshes. Recorded as
§9 item 50.

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

**276 PASS / 0 FAIL**, `ALL CHECKS PASSED` (256 before this pass). The new checks assert twelve
unique move signatures; Feedback's original 4/3/9, 9/4/18, 12/4/12 and 8/4/16 timings; L!ckshot's
3/3/7 jab, 14/4/20 cross and advancing 10/3/16 knee; L!kkle Moore's 3/3/6 jab, 150 px home-run box
and tripping 124×38 low sweep with a crouched live hurtbox that a standing jab misses; the
dubplate and dictionary projectile specs; 29,025 / 28,000 / 28,000 triangles under the 35,000
budget; separate 3D pivots for two signature moves per fighter; and a live dubplate wave that
spawns its 3D proxy and lands through the shared `receive_strike` (100 → 84 hp).

**Decimation.** Both large uploads are exactly 28,000 triangles now (20,797 / 20,825 verts) with
per-corner UVs preserved, a byte-identical embedded 1024² PNG and the original ×1000 root scale;
Godot still measures 1.58 m / 1.27 m. The Mixamo-ready copies were regenerated from those files at
180 cm / 128 cm.

**`/docs` rebuilt**: `index.pck` **38,626,932 B**, `index.wasm` 38,057,390 B, `index.js` 305,185 B,
`index.html` 5,449 B.

**Not verified — no GPU/display/audio.** The new 3D poses, dubplate/dictionary props, sand bursts,
vinyl parry, cel look and the 60 FPS target on Chromebook / iPhone Safari have not been seen or
measured. The headless combat logic and triangle budgets are verified; device playback is not.


### Active 3D DJs and staggered silhouette crowd — headless verification, November 22, 2026

Owner request on `feature/3d-cel-shaded` at `0a5eac1`: add active 3D DJs behind a turntable/mixer
rig between the mid-ground speaker stacks, replace the placeholder crowd with 16–24 varied,
rim-lit dark-silhouette spectators (flags, raised lighters, airhorn operators) whose reactions are
staggered and side-loyal, and keep the whole addition under 15,000 triangles — **without adding or
changing any crowd voice audio**. Recorded as §9 item 51.

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

**302 PASS / 0 FAIL**, `ALL CHECKS PASSED` (276 before this pass). The **26 new checks** boot the
real `TestArena.tscn` and assert: exactly **two** DJs; the booth centred at x 0 and behind the
z −2.55 barrier; two vinyl turntables + one mixer + three channel faders; the new silhouette shader
**compiling** (6 uniforms) and passing the WebGL2 static lint; **20** spectators (in the 16–24
range) split **10 / 10** across the loyalty banks; **3** flags, **6** lighter slots and **2**
airhorn operators; the old capsule crowd nodes gone; a heavy hit queuing all 20 with **zero**
answering on the impact frame, **only ringside** reacting at 0.14 s while the back rows stay
neutral, and all 20 answering within a beat; P1's bank cheering while all 10 of P2's bank are in
disbelief; lighters lit with visible flames; a DJ pointing; faders and records still moving; the
knockdown, K.O. and DJ-tag airhorn/celebration states; a Hype surge lighting every lighter; health
and fighter state byte-identical across a K.O. cue; **13,644 measured triangles** (crowd 11,520 /
booth 2,124) under the 15,000 budget; and the crowd rim recolouring to the night cyan palette.

**`/docs` rebuilt** with `--headless --path godot --export-release "Web" ../docs/index.html`:
`index.pck` **38,664,500 B**, `index.wasm` 38,057,390 B, `index.js` 305,185 B, `index.html`
5,449 B. The export logged only the environment's known non-fatal fontconfig warnings.

**Not verified — no GPU/display/audio.** Nothing was seen on screen: the DJ poses, the stagger's
timing as an audience feels it, the flag cloth and lighter flames, the rim strength against the
three lighting phases, whether the booth reads clearly behind two 1.5 m fighters, and whether the
Chromebook / iPhone Safari frame rate stays at 60 FPS with 20 articulated rigs and 2,124 extra booth
triangles are all unmeasured. The audio engine was deliberately not touched, so there is still no
crowd voice audio — that stays [TODO] until the owner's custom Patois clips are uploaded.

### 31-entry Patwa collection + menu/victory beat audit — headless verification, November 22, 2026

Owner request on `feature/3d-cel-shaded` at `c7e408c`: verify the three uploaded reggae hip-hop
beats are used on Title/Select and post-KO only, make the M-key audition visible, and wire the full
31-entry Jamaican Patwa proverbs & expressions collection through `TestArena.gd` with V-key English
glosses and a match-intro banner. Recorded as §9 item 52; the lexicon table is in §8.

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

**314 PASS / 0 FAIL**, `ALL CHECKS PASSED` (302 before this pass). New coverage: the three beats
load from `assets/audio/production/beats/` at **23.38 s / 262.84 s / 90.04 s** and loop; the Title
screen starts Beat 1, M cycles 1 → 2 → 3 → Off → 1 and shows the corner label; MusicBed is silent
from FIGHT! through the active round and M stays the mute key there; the final K.O. starts Beat 2,
`match_ended` does not advance twice, the post-KO M cycle shows its label, and the victory bed
rotates Beat 1 → 2 → 3 across matches. The **31/31** Patwa checks assert the exact count, no
duplicates, a separate `(Translation: …)` gloss for every entry, a live pool/banner trigger for
every entry, WASH-BELLY restricted to L!kkle Moore, counter/heavy routing, two different rotating
intro proverbs, and V-off hiding only the English subtitle. `BRUK POCKET` is logged in the B15
promoter pool, not in the 31.

**`/docs` rebuilt**: `index.pck` **38,674,548 B**, `index.wasm` 38,057,390 B, `index.js`
305,185 B, `index.html` 5,449 B. The export log contained only the environment's known non-fatal
fontconfig warnings.

**Not verified — no audio device, GPU or display.** Nothing was heard: the songs' sound, the fade
shapes, loop seams and loudness against the round sting are unmeasured. Nothing was seen: the corner
beat label, the `YARD WISDOM` banner's fit over the 3D yard and the Web/iPhone autoplay path still
need a real-device check. The Patwa collection is verified as data and trigger wiring, not as voice
performance.

### Owner playtest fixes: music bleed, sound-system stacks, arcade type, rig slots — headless verification, November 23, 2026

Owner live-playtested `c74faaf` on `feature/3d-cel-shaded` and reported four high-priority issues:
a music bed bleeding into Match 2+, basic speaker boxes instead of Jamaican sound-system stacks,
flat on-screen typography, and capsule mannequins standing in for the DJs and crowd. All four are
implemented and recorded as §9 item 53.

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

**332 PASS / 0 FAIL**, `ALL CHECKS PASSED` (314 before this pass). New coverage:

- **Music bed** — `music_bed.play_victory()` starts the bed, `TestArena._on_round_started(0)` then
  leaves `MusicBed` **off**, the player **stopped** and the bus at **−60 dB**; `music_bed_silent()`
  asserts all three together. The same hook is the Match 2 / Match 3 / rematch path.
- **Stacks** — 2 towers, 4 double-18" sub bins, 2 amp/EQ racks, **40 metallic corner brackets**, and
  **40 VU LEDs** rising from 4 lit at rest to 40 at a peak when `_pulse` is punched.
- **Rigs** — 20 crowd silhouettes + 2 DJ silhouettes, **0** legacy mannequin meshes, both
  `.fbx` slot folders present, fallback active while they are empty, and 20 cached silhouette
  masks/materials.
- **Type** — the HUD's pop constants, gold ink and three-block Rasta strip are present, every label
  draws a `draw_string_outline` ink pass plus a `for step in [3, 2, 1]` extruded shadow, and both the
  round banner and the Patwa callout pill use the scale-pop entrance.

The pre-existing 302 checks still pass unchanged: crowd stagger (`ringside` first, back rows last),
zone loyalty, lighters/flames, airhorns, the night rim palette, the 15 000-triangle ceiling
(now **1 400** measured), and that atmosphere cues never touch health or fighter state.

**`/docs` rebuilt**: `index.pck` **38,693,836 B**, `index.wasm` 38,057,390 B, `index.js` 305,185 B,
`index.html` 5,449 B. Only the environment's known non-fatal fontconfig warnings.

**Not verified — no GPU, display or audio device.** Nothing was seen or heard: the new stack
proportions, the VU meters ticking, the procedurally painted silhouettes, the rim through the three
lighting phases, the pop timing, or the frame rate on a Chromebook / iPhone Safari. The music fix is
verified as state, not by ear. No real Mixamo character has been dropped into the `.fbx` slots yet,
so that path is a contract and an empty-folder fallback, not a working import. Crowd voice audio is
still untouched and [TODO].

### Mixamo upload pass: crowd/DJ characters delivered, fighter clips blocked — November 23, 2026

Owner pushed 45 Mixamo `.fbx` files to the **root** of `feature/3d-cel-shaded` (commit `a46be08`,
"Add Mixamo animations part 1") and asked for the full fighter retarget, hand-attached mics and the
crowd/DJ integration. **Only 3 of the 45 binaries reached this workspace.** `git fsck` reports the
other 42 blobs missing from the local object store; a branch refresh, a reset-to-parent re-pull and
both managed fetch paths all return the commit and trees without those blobs. The three delivered
files — `Crowd Male Angry Gesture`, `Crowd Male Cheering`, `Crowd Male Rallying` — are 68-bone
`mixamorig` **With Skin** exports with one take each. The upload contains **no DJ-specific
character** and no female crowd model (7 `Crowd …` files total).

**Implemented this pass (crowd/DJ only):**

- **Organised** the three delivered characters. Untouched owner originals are archived at
  `art-source/mixamo/crowd/`; decimated game copies are in `godot/assets/models/crowd/`, and the
  Cheering/Rallying copies fill `godot/assets/models/dj/`; the root copies were removed.
- **Decimation** — new `godot/tools/decimate_mixamo_blender.py` runs headless Blender's COLLAPSE
  Decimate, which interpolates vertex groups, so the armature, skin weights, materials, embedded
  textures and take survive. **10 220 → 3 491 tris** each, 68 bones, 1 909 verts. Textures are
  extracted to `*_0/1/2.png` and imported lossless 1024² with mipmaps. The older
  `decimate_fbx.py` only rebuilds static geometry and would drop the skin clusters.
- **Acting** — `CharacterModelSlots` builds one shared `Animation` per role from the uploaded
  filenames (cheer / disbelief / hype), installs them on every character (identical track paths
  `Armature/Skeleton3D:mixamorig_*`) and falls back to the character's own loop. `CrowdController3D`
  and `DJBooth3D` crossfade **0.12 s** on cheer, disbelief, hype, point, airhorn and celebrate.
- **Crowd** — `MODEL_ROWS = 1`: the ringside row (8 bodies, 4 per bank) is real geometry; the back
  rows keep the painted silhouettes. Flags, lighters and airhorns are reparented to
  `mixamorig_RightHand` with **BoneAttachment3D**. Left bank warm, right bank cool, per-body
  tint/hue break-up because the takes share one skin. Measured atmosphere cost **36 310 tris**
  (crowd 28 448 / booth 7 862) under the revised **40 000** cap.
- **DJ booth** — both decks animated from the same library, airhorn on the right hand, procedural
  bob disabled while a clip owns the body, and a new `disbelief` reaction to a knockdown.
- **Cel treatment** — every delivered surface carries `toon_cel.gdshader` with the upload's own
  albedo plus the `toon_outline.gdshader` inverted hull.

**Verification:** `godot --headless --path godot --import`, then
`godot --headless --path godot --script res://tools/headless_roster_check.gd` — **341 PASS /
0 FAIL** (`ALL CHECKS PASSED`). New checks: 10 delivered characters with >20 bones (68 each),
≤3 500 tris on the character mesh (3 491; hand props excluded), acting clips with real tracks
(4 clips / 79–89 tracks), cel + ink on every surface, 6 crowd + 1 booth `BoneAttachment3D` props,
left bank playing `mixamo_cheer` and right bank `mixamo_disbelief` after a heavy hit, selectors on
the hype take while pointing, and a settled yard back on the base loop. Only the environment's known
non-fatal fontconfig warning appeared.

**`/docs` rebuilt:** `index.pck` **54 007 664 B** (38 693 836 before the new characters — the five
imported copies add ~15 MB), `index.wasm` 38 057 390 B, `index.js` 305 185 B, `index.html` 5 449 B.

**NOT implemented — blocked on the 42 missing binaries:** all 38 fighter clips (10 Feedback, 11
L!ckshot, 17 L!kkle Moore), the four `Crowd female …` models and any DJ replacement art; fighter
retargeting onto `feedback_v2.fbx` / `lickshot.fbx` / `likkle_moore.fbx` (those meshes are still
static, with no skeleton); the `FighterModel3D` AnimationPlayer state machine; and the fighter
hand-attached wireless mic, mic stand and dictionary props. The 42 files remain tracked at the repo
root and were **not** deleted or overwritten. Next: re-deliver the missing binaries (zip attachment
or a fresh push), then run this same decimate + retarget pass on the fighter set.

**Not verified — no GPU, display or audio device.** Nothing was seen: the cel/ink look on real
characters, the crowd animation, the prop parenting, or the frame rate on Chromebook / iPhone
Safari. The three delivered takes share one Mixamo skin, so the ringside row is one character with
hue break-up, not seven distinct people.

### Mixamo animation pack: all 38 fighter clips bound, hand props, female crowd — headless verification, November 24, 2026

54. **All 38 uploaded Mixamo takes are bound to Feedback, L!ckshot and L!kkle Moore, with
    hand-attached mics on the right hand and four female models in the ringside crowd
    (2026-11-24).** Implemented and headlessly verified; **nothing seen, heard or timed** — this
    environment still has no GPU, display or audio device.

    - **Delivery.** The owner published all 45 binaries to the GitHub Release `mixamo-pack`. The
      42 that never reached the workspace in `a46be08` were downloaded from
      `assets[].browser_download_url` into `/tmp/mixamo_pack/` (622 MB, all valid FBX 7.4/7.7).
      The 42 root-level placeholder entries were then **removed** from the branch (`36a1ac5`) so
      `git fsck` no longer reports missing blobs; `MODELS.md` records which file became which.
    - **1. Fighter clips.** Every uploaded fighter take is not a bare animation — it is **our own
      fighter mesh skinned to a 65-bone `mixamorig` rig** (Feedback 29 025 tris, L!ckshot 270 060,
      L!kkle Moore 246 641). So no auto-retarget is needed for the body: one take per fighter
      becomes the game body (decimated back to **28 000** tris for the two Tripo uploads with
      `decimate_mixamo_blender.py`), and the other 37 are stripped to armature-plus-take files in
      `godot/assets/models/mixamo/clips/<roster key>/` (10 / 11 / 17, ~0.45 MB each).
      `MixamoClips` maps each clip file to a fight role and re-points every track at the fighter's
      own skeleton path — which is **not** the same in all three uploads (Feedback nests it at
      `Skeleton3D`, the other two at `Armature/Skeleton3D`). `FighterModel3D` mounts the library on
      the body's own `AnimationPlayer` and crossfades **0.10 s** between idles, walks, jab, hook,
      uppercut, tump, block, hit, stun, knockdown, taunt and victory.
    - **2. Hand props.** `FighterProps` builds cel-shaded geometry at run time — a wireless stage
      mic for Feedback and L!ckshot, and a mic stand **plus** the dictionary for L!kkle Moore — and
      parents each to a `BoneAttachment3D` on the right hand, so they follow every take instead of
      being animated per state. The hand bone is found by suffix, because some exports keep an
      exporter tag (`mixamorig8_RightHand`).
    - **3. Female crowd.** The four `Crowd female …` uploads are decimated to **≤3 500 tris**
      (3 393 / 3 484 / 3 399 / 3 484) with their weight-aware COLLAPSE pass, their atlases
      downscaled 4 096² → 512² (≈50 MB → ≈3 MB per model), and dropped into
      `godot/assets/models/crowd/` beside the three male spectators. The ringside row now alternates
      male and female characters across both banks, wearing the same `toon_cel.gdshader`, inverted
      hull ink and hue break-up.
    - **4. Bugs found and fixed on the way.** (a) Blender's bone-heat automatic weights report 68
      groups but write **zero** weights here, so the retargeter uses a distance-falloff solver
      (`23 612 / 23 612` vertices weighted); (b) a skinned mesh must hang off the Hips bone or
      Godot imports it with `skin=false`; (c) `_normalize()` ignored the 0.01 unit scale on the
      Skeleton3D node, which normalised two fighters **100×** too small (1.58 m → 1.6 cm) — the
      check caught it; (d) Godot caches imports, so changed FBX bytes need `.godot/imported` cleared
      before the numbers move.

    **Measured.** `godot --headless --path godot --script res://tools/headless_roster_check.gd` —
    **387 PASS / 0 FAIL, `ALL CHECKS PASSED`** (341 before). New checks: 10/11/17 take files per
    fighter, ≥10 bound roles each, a live crossfade to `mixamo/light` that moves
    `mixamorig_LeftArm`, the mic/stand/dictionary on `mixamorig_RightHand`, 4 female models with
    >20 bones and ≤3 500 tris, female slots in the front-row banks, and the crowd's 6 hand props
    restored.

    **`/docs` rebuilt:** `index.pck` **69 880 088 B** (54 007 664 before — the 38 takes, three
    rigged bodies and four female crowd models add ~16 MB), `index.wasm` 38 057 390 B,
    `index.js` 305 185 B, `index.html` 5 449 B.

    **Not verified.** No GPU/display/audio: the cel look on the animated bodies, the skin quality
    of the distance-falloff weights, whether Mixamo's Hips-space root motion makes the fighters
    drift on the 2.5D plane, the mic/stand grip angles, the downsized female atlases, and the frame
    rate on Chromebook / iPhone Safari have **not** been seen. Crossfade feel (0.10 s) and clip
    length trimming are untuned. The four female takes are still the only female acting clips; the
    shared cheer/disbelief/hype tracks are male-skeleton takes.

---

## 2026-11-24 — Playtest regressions, PART 1 (fighter facing + 2D crowd removal)

Owner playtest on `feature/3d-cel-shaded`. Two failures only: the fighters faced the wrong way,
and the crowd was a bank of dark 2D stick-figure silhouettes with one coloured body. Nothing else
in this pass: combat frame data, the FSM, `ANIM_OFFSET`, 132 BPM beat sync, hitstop and the Crowd
Hype rules are untouched, and `ANIM_OFFSET` in `BaseFighter.gd` is byte-for-byte identical.

### Issue 1 — fighter facing along X (`fix(1)`, commit `d87c5e0`)

**1. Audit (step 1).** Per fighter: root node type, visual child, rest rotation, armature rotation
and the axis the imported mesh actually faces. Measured, not assumed, with
`godot --headless --path godot --script res://tools/diag_playtest.gd`, which projects every mesh
vertex to the ground plane and compares the toe centroid to the foot centroid. The method is
validated against the one case the project already documents (Feedback at rest faces +Z): it reads
`(−0.025, 1.000)` → −1.4° off +Z.

| Fighter | Root | Visual child | Mesh authored forward (XZ) | Off by | `model_forward_yaw_offset_deg` |
| --- | --- | --- | --- | --- | --- |
| Feedback | `CharacterBody3D` (unrotated) | `FighterModel3D` | `(−0.025, +1.000)` ≈ +Z | 90° | **90** |
| L!ckshot | `CharacterBody3D` (unrotated) | `FighterModel3D` | `(+0.999, −0.036)` ≈ +X | 0° | **0** |
| L!kkle Moore | `CharacterBody3D` (unrotated) | `FighterModel3D` | `(+0.997, −0.076)` ≈ +X | 0° | **0** |

L!kkle Moore is *not* stuck facing +Z as suspected: his mesh is authored along +X like L!ckshot.
What made him look stuck was the baked Hips yaw in his takes (see step 6). The `Hips` rest axis is
**not** evidence of rendered facing — the two Tripo-derived rigs read −60°/−51° there purely as a
bind-pose convention — so the mesh-vertex measurement is the authority.

**2–5. Logic/visual split.** The fighter root stays unrotated and moves only on X. The model hangs
off `PosePivot` → **`VisualPivot`** (`FighterModel3D._visual_pivot`), and facing is the *only* thing
that ever writes `VisualPivot.rotation.y`. One function:

```gdscript
func set_facing(dir: int) -> void      # +1 = +X, −1 = −X
```

It sets `deg_to_rad(model_forward_yaw_offset_deg)`, plus `PI` for −1. No negative scale, no
`flip_h`, no mirroring: the mic stays in the same hand in both facings. `BaseFighter` seeds P1 at
`set_facing(+1)` and P2 at `set_facing(-1)` on spawn, and re-faces every tick through
`TURNABLE_STATES = {IDLE, WALK, JUMP, CROUCH, ATTACK_STARTUP}`. Facing is locked in
`ATTACK_ACTIVE`, `ATTACK_RECOVERY`, `HITSTUN`, `KNOCKDOWN` and `KO`.

**6. Baked root/hips yaw — the real cause of the "stuck" fighters.** The delivered takes carry
their own heading inside `mixamorig_Hips`: `fighting-idle-3` is −72.5°, `knocked-out-1` up to
−155°, and the melee takes 45–108°. `drunk-walk`, `bencao` and `getting-up` turn too. Fixed in three
layers, each cheaper than the last:

- `MixamoClips._strip_root_yaw()` flattens the yaw of every `Hips`/`Root` rotation track (and any
  root-node rotation track) to that bone's **rest** yaw at import — the rest yaw, not zero, because
  L!ckshot's Hips rest is −59.6° and L!kkle Moore's −51.2°; zeroing them would turn those bodies.
- `FighterModel3D._lock_root_yaw()` re-pins the Hips pose yaw to its rest yaw every frame, so a clip
  reaching the body through a cached library is caught too. Only Y is touched: pitch, roll, the
  punch twist, the topple and the get-up stay exactly as authored.
- `FighterModel3D._compensate_clip_yaw()` cancels whatever heading is left on `VisualPivot`. Facing
  is authoritative; a take keeps every degree of its topple without turning the character.

**Clips audited, all 3 fighters** (both facings, 8 samples each): `idle` (`fighting-idle-3` /
`fight-idle`), `walk` (`drunk-walk` / `strut-walking`), `light` (`jab-cross` / `lead-jab`), `strong`
(`right-hook` / `hook-punch`), `upper_box`, `tump`, `special` (`bencao`), `block`, `taunt`,
`victory`, `hitstun`/`stun`, `stumble`, `knockdown` (`knocked-out-1`), `getup` (`getting-up`).
**Fixed:** every clip that carried a baked heading — `fighting-idle-3`, `drunk-walk`, `bencao`,
`knocked-out-1`, `getting-up`, the melee takes and the stun/stumble takes.

**8. Verification.** **F3** in the arena prints, per fighter, the pivot yaw, the model's world
forward vector, the off-±X angle and the current animation name
(`TestArena.print_facing_debug()`). `godot --headless --path godot --script
res://tools/facing_audit.gd` drives all three fighters through every take at both facings and all
nine pairings: **94 checks, 0 FAIL — `ALL FACING CHECKS PASSED`**, every forward within 5° of ±X
(worst case 0.0–4.3°), and every pairing, mirror matches included, faces its opponent
(`P1=(+1.00,·) P2=(−1.00,·)`).

### Issue 2 — stick figures deleted, full crowd/DJ albedo restored (`fix(2)`)

**1. Everything 2D in the crowd is gone.** Deleted, not disabled:

- scripts: `CrowdLine.gd`, `ForegroundCrowd.gd`, `SilhouetteArt.gd`, `StageSilhouette.gd`, `CrowdHaze.gd`
- shader: `assets/shaders/silhouette_mask.gdshader`
- textures: all 15 `assets/sprites/crowd/*.png` and their `.import` files
- nodes: `CrowdLine` + its 15 `Sprite2D` children, `ForegroundCrowd`, `CrowdHaze` — removed from
  `scenes/TestArena.tscn` together with their `ext_resource` entries. No `CanvasLayer` or `Control`
  ever hosted them, so none was removed.
- references: `project.godot` never listed them (no autoload); the stale prose in `TestArena.gd`,
  `godot/README.md` and this file is corrected; no `_draw`, `draw_line`, `draw_circle`, `Polygon2D`
  or `Line2D` crowd code survives (`TestArena.gd` keeps only its stage/graphics primitives).

**2. One crowd system.** `CrowdController3D` has no 2D branch and no fallback flag. Every spectator
is a delivered Mixamo character; a slot that cannot be filled stays **empty** and logs a warning.
The yard is now **4 a side in one ringside row (8)** instead of 20, because each body is a real
~3 500-triangle rig rather than two triangles — that is what keeps the whole cast inside the
Chromebook budget with all of it textured. Props (2 flags, 4 lighters, 2 airhorns) are unchanged and
still ride `mixamorig_RightHand` through a `BoneAttachment3D`. `DJBooth3D` lost its silhouette
bodies the same way and keeps its deck, platters, mixer, faders and horn.

**3. Why only one crowd model was coloured — two real causes.**

1. **The female atlases were missing from disk.** Godot's FBX import embeds Diffuse/Normal/
   Specular/Glossiness PNGs; four female spectators (`Dancing Twerk`, `Hip Hop Dancing`, `Moonwalk`,
   `Snake Hip Hop Dance`) had `_1…_5` but no `_0`, so their albedo was `null` and `apply_cel` fell
   back to a 2×2 white texture — flat, untextured bodies. The `_0` atlas is payload index 0 of the
   same FBX (proved: the male `_0.png` is byte-identical to its payload 0, and the existing female
   `_1…_5` match payloads 1–5), so the four atlases were **extracted from the delivered FBX files**
   and their import caches cleared. This is the shipped art, not new art.
2. **Shared material instances plus a global shadow tint.** `apply_cel`'s cache key was
   `source material id + variant`, so several spectators could resolve to one `ShaderMaterial`, and
   every material carried the shader's `shadow_tint_amount = 0.20` — a cool 20 % shadow bias applied
   to the albedo. Both fixed: one material per character keyed by the character's own instance id
   (never shared between characters), `shadow_tint_amount = 0.0`, `hue_shift = 0.0`. Tints are
   sub-percent brightness nudges only. The `albedo_texture` is bound **explicitly per instance** and
   a surface with no albedo is no longer given a white stand-in — it keeps the imported material and
   the instance is reported.

**4. Energy without tint.** Crowd "energy" is animation only: which act is crossfaded in
(`CharacterModelSlots.play_act`), each person's own rate/phase, a ≤2.5 cm beat bob on the anchor,
and the props. `set_palette()` moves the rim highlight only. `CrowdLine.set_night()` — the silhouette
dimmer — is gone with its class; night is a palette change, not a darkening.

**5. DJs** follow the same rules: one cel material each, explicit albedo, `shadow_tint_amount 0.0`,
rim only from the palette.

**6. Verification — albedo.** Every build logs, per crowd/DJ instance, the model name, its material
count and the albedo path bound to every character surface
(`CharacterModelSlots.report_albedo()`, e.g. `[albedo] crowd Crowd female Dancing Twerk
materials=7 Ch07_Body#0=res://assets/models/crowd/Crowd female Dancing Twerk_0.png …`). **No path is
`<none>`**: 8 crowd + 2 DJ characters, 86 character surfaces, 0 unbound. Hand props are excluded by
construction (they are painted geometry, not character albedo).

**6. Verification — no 2D crowd node in the running tree.** `godot --headless --path godot --script
res://tools/tree_dump.gd` prints `print_tree_pretty` of the live arena. Zero matches for
`CrowdLine`, `ForegroundCrowd`, `CrowdHaze`, `Silhouette` or `stick`. The dump:

```
 ┖╴TestArena
    ┠╴Stage
    ┠╴Atmosphere
    ┠╴SunsetWash
    ┠╴NightWash
    ┠╴SunGlow
    ┠╴SunShaft
    ┠╴SpeakerRings
    ┠╴LightBeams
    ┠╴TimeOfDay
    ┠╴Floodlight
    ┠╴WindMotes
    ┠╴Floor
    ┃  ┖╴Shape
    ┠╴WallLeft
    ┃  ┖╴Shape
    ┠╴WallRight
    ┃  ┖╴Shape
    ┠╴RecordCrates
    ┃  ┠╴LeftCrate
    ┃  ┃  ┖╴Shadow
    ┃  ┖╴RightCrate
    ┃     ┖╴Shadow
    ┠╴HeatHaze
    ┃  ┖╴DustMotes
    ┠╴YardBarrier
    ┠╴P1
    ┃  ┠╴Shadow
    ┃  ┠╴Dust
    ┃  ┠╴Sprite
    ┃  ┠╴Body
    ┃  ┠╴Hurtbox
    ┃  ┃  ┖╴Shape
    ┃  ┖╴Hitbox
    ┃     ┖╴Shape
    ┠╴P2
    ┃  ┠╴Shadow
    ┃  ┠╴Dust
    ┃  ┠╴Sprite
    ┃  ┠╴Body
    ┃  ┠╴Hurtbox
    ┃  ┃  ┖╴Shape
    ┃  ┖╴Hitbox
    ┃     ┖╴Shape
    ┠╴BirdHazard
    ┠╴BeatService
    ┠╴SparringAI
    ┠╴RoundController
    ┠╴Music
    ┠╴Camera2D
    ┠╴HUD
    ┃  ┖╴Ui
    ┃     ┖╴Hud
    ┠╴Arena3D
    ┃  ┠╴WorldEnvironment
    ┃  ┠╴StageCamera
    ┃  ┠╴SandFloor
    ┃  ┠╴@MeshInstance3D@6
    ┃  ┠╴@MeshInstance3D@7
    ┃  ┠╴@MeshInstance3D@8
    ┃  ┠╴@MeshInstance3D@9
    ┃  ┠╴@MeshInstance3D@10
    ┃  ┠╴@MeshInstance3D@11
    ┃  ┠╴@MeshInstance3D@12
    ┃  ┠╴@MeshInstance3D@13
    ┃  ┠╴@MeshInstance3D@14
    ┃  ┠╴@MeshInstance3D@15
    ┃  ┠╴@MeshInstance3D@16
    ┃  ┠╴@MeshInstance3D@17
    ┃  ┠╴@MeshInstance3D@18
    ┃  ┠╴@MeshInstance3D@19
    ┃  ┠╴SkyBackdrop
    ┃  ┠╴SunDisc
    ┃  ┠╴HorizonBand
    ┃  ┠╴BarrierRail
    ┃  ┠╴BarrierLower
    ┃  ┠╴BarrierPost
    ┃  ┠╴@MeshInstance3D@20
    ┃  ┠╴@MeshInstance3D@21
    ┃  ┠╴@MeshInstance3D@22
    ┃  ┠╴@MeshInstance3D@23
    ┃  ┠╴@MeshInstance3D@24
    ┃  ┠╴@MeshInstance3D@25
    ┃  ┠╴@MeshInstance3D@26
    ┃  ┠╴@MeshInstance3D@27
    ┃  ┠╴StageLightPool
    ┃  ┠╴SpeakerStackLeft
    ┃  ┃  ┠╴Plinth
    ┃  ┃  ┠╴SubBin0
    ┃  ┃  ┠╴Baffle0
    ┃  ┃  ┠╴Surround0_0
    ┃  ┃  ┠╴Sub18_0_0
    ┃  ┃  ┠╴Surround0_1
    ┃  ┃  ┠╴Sub18_0_1
    ┃  ┃  ┠╴Bracket0
    ┃  ┃  ┠╴Bracket1
    ┃  ┃  ┠╴Bracket2
    ┃  ┃  ┠╴Bracket3
    ┃  ┃  ┠╴Bracket4
    ┃  ┃  ┠╴Bracket5
    ┃  ┃  ┠╴Bracket6
    ┃  ┃  ┠╴Bracket7
    ┃  ┃  ┠╴SubBin1
    ┃  ┃  ┠╴Baffle1
    ┃  ┃  ┠╴Surround1_0
    ┃  ┃  ┠╴Sub18_1_0
    ┃  ┃  ┠╴Surround1_1
    ┃  ┃  ┠╴Sub18_1_1
    ┃  ┃  ┠╴Bracket8
    ┃  ┃  ┠╴Bracket9
    ┃  ┃  ┠╴Bracket10
    ┃  ┃  ┠╴Bracket11
    ┃  ┃  ┠╴Bracket12
    ┃  ┃  ┠╴Bracket13
    ┃  ┃  ┠╴Bracket14
    ┃  ┃  ┠╴Bracket15
    ┃  ┃  ┠╴BassCabinet
    ┃  ┃  ┠╴BassBaffle
    ┃  ┃  ┠╴BassSurround0
    ┃  ┃  ┠╴Mid15_0
    ┃  ┃  ┠╴BassSurround1
    ┃  ┃  ┠╴Mid15_1
    ┃  ┃  ┠╴BassPort
    ┃  ┃  ┠╴BracketBass-1-1
    ┃  ┃  ┠╴BracketBass-11
    ┃  ┃  ┠╴BracketBass1-1
    ┃  ┃  ┠╴BracketBass11
    ┃  ┃  ┠╴RadialHornBox
    ┃  ┃  ┠╴HornFlare0
    ┃  ┃  ┠╴RadialHorn0
    ┃  ┃  ┠╴HornFlare1
    ┃  ┃  ┠╴RadialHorn1
    ┃  ┃  ┠╴HornThroat
    ┃  ┃  ┠╴StackCap
    ┃  ┃  ┠╴RastaBand0
    ┃  ┃  ┠╴RastaBand1
    ┃  ┃  ┠╴RastaBand2
    ┃  ┃  ┠╴RastaFlag
    ┃  ┃  ┠╴RastaFlagGold
    ┃  ┃  ┖╴AmpRack
    ┃  ┃     ┠╴RackCase
    ┃  ┃     ┠╴RackRailL
    ┃  ┃     ┠╴RackRailR
    ┃  ┃     ┠╴EqFace
    ┃  ┃     ┠╴EqKnob0
    ┃  ┃     ┠╴EqKnob1
    ┃  ┃     ┠╴EqKnob2
    ┃  ┃     ┠╴EqKnob3
    ┃  ┃     ┠╴EqKnob4
    ┃  ┃     ┠╴VuLed0_0
    ┃  ┃     ┠╴VuLed0_1
    ┃  ┃     ┠╴VuLed0_2
    ┃  ┃     ┠╴VuLed0_3
    ┃  ┃     ┠╴VuLed0_4
    ┃  ┃     ┠╴VuLed0_5
    ┃  ┃     ┠╴VuLed0_6
    ┃  ┃     ┠╴VuLed0_7
    ┃  ┃     ┠╴VuLed0_8
    ┃  ┃     ┠╴VuLed0_9
    ┃  ┃     ┠╴VuLed1_0
    ┃  ┃     ┠╴VuLed1_1
    ┃  ┃     ┠╴VuLed1_2
    ┃  ┃     ┠╴VuLed1_3
    ┃  ┃     ┠╴VuLed1_4
    ┃  ┃     ┠╴VuLed1_5
    ┃  ┃     ┠╴VuLed1_6
    ┃  ┃     ┠╴VuLed1_7
    ┃  ┃     ┠╴VuLed1_8
    ┃  ┃     ┖╴VuLed1_9
    ┃  ┠╴SpeakerStackRight
    ┃  ┃  ┠╴Plinth
    ┃  ┃  ┠╴SubBin0
    ┃  ┃  ┠╴Baffle0
    ┃  ┃  ┠╴Surround0_0
    ┃  ┃  ┠╴Sub18_0_0
    ┃  ┃  ┠╴Surround0_1
    ┃  ┃  ┠╴Sub18_0_1
    ┃  ┃  ┠╴Bracket0
    ┃  ┃  ┠╴Bracket1
    ┃  ┃  ┠╴Bracket2
    ┃  ┃  ┠╴Bracket3
    ┃  ┃  ┠╴Bracket4
    ┃  ┃  ┠╴Bracket5
    ┃  ┃  ┠╴Bracket6
    ┃  ┃  ┠╴Bracket7
    ┃  ┃  ┠╴SubBin1
    ┃  ┃  ┠╴Baffle1
    ┃  ┃  ┠╴Surround1_0
    ┃  ┃  ┠╴Sub18_1_0
    ┃  ┃  ┠╴Surround1_1
    ┃  ┃  ┠╴Sub18_1_1
    ┃  ┃  ┠╴Bracket8
    ┃  ┃  ┠╴Bracket9
    ┃  ┃  ┠╴Bracket10
    ┃  ┃  ┠╴Bracket11
    ┃  ┃  ┠╴Bracket12
    ┃  ┃  ┠╴Bracket13
    ┃  ┃  ┠╴Bracket14
    ┃  ┃  ┠╴Bracket15
    ┃  ┃  ┠╴BassCabinet
    ┃  ┃  ┠╴BassBaffle
    ┃  ┃  ┠╴BassSurround0
    ┃  ┃  ┠╴Mid15_0
    ┃  ┃  ┠╴BassSurround1
    ┃  ┃  ┠╴Mid15_1
    ┃  ┃  ┠╴BassPort
    ┃  ┃  ┠╴BracketBass-1-1
    ┃  ┃  ┠╴BracketBass-11
    ┃  ┃  ┠╴BracketBass1-1
    ┃  ┃  ┠╴BracketBass11
    ┃  ┃  ┠╴RadialHornBox
    ┃  ┃  ┠╴HornFlare0
    ┃  ┃  ┠╴RadialHorn0
    ┃  ┃  ┠╴HornFlare1
    ┃  ┃  ┠╴RadialHorn1
    ┃  ┃  ┠╴HornThroat
    ┃  ┃  ┠╴StackCap
    ┃  ┃  ┠╴RastaBand0
    ┃  ┃  ┠╴RastaBand1
    ┃  ┃  ┠╴RastaBand2
    ┃  ┃  ┠╴RastaFlag
    ┃  ┃  ┠╴RastaFlagGold
    ┃  ┃  ┖╴AmpRack
    ┃  ┃     ┠╴RackCase
    ┃  ┃     ┠╴RackRailL
    ┃  ┃     ┠╴RackRailR
    ┃  ┃     ┠╴EqFace
    ┃  ┃     ┠╴EqKnob0
    ┃  ┃     ┠╴EqKnob1
    ┃  ┃     ┠╴EqKnob2
    ┃  ┃     ┠╴EqKnob3
    ┃  ┃     ┠╴EqKnob4
    ┃  ┃     ┠╴VuLed0_0
    ┃  ┃     ┠╴VuLed0_1
    ┃  ┃     ┠╴VuLed0_2
    ┃  ┃     ┠╴VuLed0_3
    ┃  ┃     ┠╴VuLed0_4
    ┃  ┃     ┠╴VuLed0_5
    ┃  ┃     ┠╴VuLed0_6
    ┃  ┃     ┠╴VuLed0_7
    ┃  ┃     ┠╴VuLed0_8
    ┃  ┃     ┠╴VuLed0_9
    ┃  ┃     ┠╴VuLed1_0
    ┃  ┃     ┠╴VuLed1_1
    ┃  ┃     ┠╴VuLed1_2
    ┃  ┃     ┠╴VuLed1_3
    ┃  ┃     ┠╴VuLed1_4
    ┃  ┃     ┠╴VuLed1_5
    ┃  ┃     ┠╴VuLed1_6
    ┃  ┃     ┠╴VuLed1_7
    ┃  ┃     ┠╴VuLed1_8
    ┃  ┃     ┖╴VuLed1_9
    ┃  ┠╴TrussTower
    ┃  ┠╴@MeshInstance3D@68
    ┃  ┠╴TrussBeam
    ┃  ┠╴Fixture
    ┃  ┠╴@MeshInstance3D@69
    ┃  ┠╴@MeshInstance3D@70
    ┃  ┠╴@MeshInstance3D@71
    ┃  ┠╴SpotLeft
    ┃  ┠╴SpotRight
    ┃  ┠╴Sun
    ┃  ┠╴CameraFill
    ┃  ┠╴WarmRim
    ┃  ┠╴DJBooth3D
    ┃  ┃  ┠╴Booth
    ┃  ┃  ┃  ┠╴Plinth
    ┃  ┃  ┃  ┠╴Cabinet
    ┃  ┃  ┃  ┠╴Top
    ┃  ┃  ┃  ┠╴Stripe0
    ┃  ┃  ┃  ┠╴Stripe1
    ┃  ┃  ┃  ┠╴Stripe2
    ┃  ┃  ┃  ┠╴Monitor
    ┃  ┃  ┃  ┠╴@MeshInstance3D@72
    ┃  ┃  ┃  ┠╴DeckBase
    ┃  ┃  ┃  ┠╴Platter
    ┃  ┃  ┃  ┠╴Record
    ┃  ┃  ┃  ┃  ┠╴Vinyl
    ┃  ┃  ┃  ┃  ┖╴Label
    ┃  ┃  ┃  ┠╴Tonearm
    ┃  ┃  ┃  ┠╴@MeshInstance3D@73
    ┃  ┃  ┃  ┠╴@MeshInstance3D@74
    ┃  ┃  ┃  ┠╴@Node3D@75
    ┃  ┃  ┃  ┃  ┠╴Vinyl
    ┃  ┃  ┃  ┃  ┖╴Label
    ┃  ┃  ┃  ┠╴@MeshInstance3D@76
    ┃  ┃  ┃  ┠╴Mixer
    ┃  ┃  ┃  ┠╴ChannelFader0
    ┃  ┃  ┃  ┠╴ChannelFader1
    ┃  ┃  ┃  ┠╴ChannelFader2
    ┃  ┃  ┃  ┠╴Crossfader
    ┃  ┃  ┃  ┠╴Knob0
    ┃  ┃  ┃  ┠╴Knob1
    ┃  ┃  ┃  ┠╴Knob2
    ┃  ┃  ┃  ┠╴Knob3
    ┃  ┃  ┃  ┠╴SignPostL
    ┃  ┃  ┃  ┠╴SignPostR
    ┃  ┃  ┃  ┖╴SignBoard
    ┃  ┃  ┠╴DJ1
    ┃  ┃  ┃  ┖╴Crowd Male Cheering
    ┃  ┃  ┃     ┠╴Armature
    ┃  ┃  ┃     ┃  ┖╴Skeleton3D
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Pants_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_L_Eye_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Hat_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Head_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Shoes_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Jacket_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Arms_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Teeth_Down_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_R_Eye_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Teeth_Up_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Cigar_Geo
    ┃  ┃  ┃     ┃     ┠╴AirhornHand
    ┃  ┃  ┃     ┃     ┃  ┖╴Airhorn
    ┃  ┃  ┃     ┃     ┃     ┠╴HornBody
    ┃  ┃  ┃     ┃     ┃     ┠╴HornBell
    ┃  ┃  ┃     ┃     ┃     ┖╴HornCan
    ┃  ┃  ┃     ┃     ┖╴@PhysicalBoneSimulator3D@77
    ┃  ┃  ┃     ┖╴AnimationPlayer
    ┃  ┃  ┖╴DJ2
    ┃  ┃     ┖╴Crowd Male Rallying
    ┃  ┃        ┠╴Armature
    ┃  ┃        ┃  ┖╴Skeleton3D
    ┃  ┃        ┃     ┠╴mixamorig_Arms_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Teeth_Down_Geo
    ┃  ┃        ┃     ┠╴mixamorig_R_Eye_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Teeth_Up_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Cigar_Geo
    ┃  ┃        ┃     ┠╴mixamorig_L_Eye_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Pants_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Hat_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Head_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Shoes_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Jacket_Geo
    ┃  ┃        ┃     ┖╴@PhysicalBoneSimulator3D@78
    ┃  ┃        ┖╴AnimationPlayer
    ┃  ┠╴CrowdController3D
    ┃  ┃  ┠╴Spectator00
    ┃  ┃  ┃  ┖╴Crowd Male Angry Gesture
    ┃  ┃  ┃     ┠╴Armature
    ┃  ┃  ┃     ┃  ┖╴Skeleton3D
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Teeth_Down_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Arms_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_R_Eye_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Teeth_Up_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Cigar_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_L_Eye_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Pants_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Hat_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Head_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Shoes_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Jacket_Geo
    ┃  ┃  ┃     ┃     ┖╴@PhysicalBoneSimulator3D@79
    ┃  ┃  ┃     ┖╴AnimationPlayer
    ┃  ┃  ┠╴Spectator01
    ┃  ┃  ┃  ┖╴Crowd Male Cheering
    ┃  ┃  ┃     ┠╴Armature
    ┃  ┃  ┃     ┃  ┖╴Skeleton3D
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Pants_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_L_Eye_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Hat_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Head_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Shoes_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Jacket_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Arms_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Teeth_Down_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_R_Eye_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Teeth_Up_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Cigar_Geo
    ┃  ┃  ┃     ┃     ┠╴HandProp0
    ┃  ┃  ┃     ┃     ┃  ┖╴FlagPole
    ┃  ┃  ┃     ┃     ┃     ┠╴Pole
    ┃  ┃  ┃     ┃     ┃     ┖╴FlagCloth
    ┃  ┃  ┃     ┃     ┃        ┖╴Cloth
    ┃  ┃  ┃     ┃     ┖╴@PhysicalBoneSimulator3D@80
    ┃  ┃  ┃     ┖╴AnimationPlayer
    ┃  ┃  ┠╴Spectator02
    ┃  ┃  ┃  ┖╴Crowd Male Rallying
    ┃  ┃  ┃     ┠╴Armature
    ┃  ┃  ┃     ┃  ┖╴Skeleton3D
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Arms_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Teeth_Down_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_R_Eye_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Teeth_Up_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Cigar_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_L_Eye_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Pants_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Hat_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Head_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Shoes_Geo
    ┃  ┃  ┃     ┃     ┠╴mixamorig_Jacket_Geo
    ┃  ┃  ┃     ┃     ┠╴HandProp0
    ┃  ┃  ┃     ┃     ┃  ┖╴LighterHand
    ┃  ┃  ┃     ┃     ┃     ┠╴Lighter
    ┃  ┃  ┃     ┃     ┃     ┖╴LighterFlame
    ┃  ┃  ┃     ┃     ┃        ┖╴Flame
    ┃  ┃  ┃     ┃     ┖╴@PhysicalBoneSimulator3D@81
    ┃  ┃  ┃     ┖╴AnimationPlayer
    ┃  ┃  ┠╴Spectator03
    ┃  ┃  ┃  ┖╴Crowd female Dancing Twerk
    ┃  ┃  ┃     ┠╴Armature
    ┃  ┃  ┃     ┃  ┖╴Skeleton3D
    ┃  ┃  ┃     ┃     ┠╴Ch07_Body
    ┃  ┃  ┃     ┃     ┠╴Ch07_Eyelashes
    ┃  ┃  ┃     ┃     ┠╴Ch07_Hair
    ┃  ┃  ┃     ┃     ┠╴Ch07_Heels
    ┃  ┃  ┃     ┃     ┠╴Ch07_Pants
    ┃  ┃  ┃     ┃     ┠╴Ch07_Shirt
    ┃  ┃  ┃     ┃     ┠╴Ch07_Suit
    ┃  ┃  ┃     ┃     ┠╴HandProp0
    ┃  ┃  ┃     ┃     ┃  ┖╴Airhorn
    ┃  ┃  ┃     ┃     ┃     ┠╴HornBody
    ┃  ┃  ┃     ┃     ┃     ┠╴HornBell
    ┃  ┃  ┃     ┃     ┃     ┖╴HornCan
    ┃  ┃  ┃     ┃     ┠╴HandProp1
    ┃  ┃  ┃     ┃     ┃  ┖╴LighterHand
    ┃  ┃  ┃     ┃     ┃     ┠╴Lighter
    ┃  ┃  ┃     ┃     ┃     ┖╴LighterFlame
    ┃  ┃  ┃     ┃     ┃        ┖╴Flame
    ┃  ┃  ┃     ┃     ┖╴@PhysicalBoneSimulator3D@82
    ┃  ┃  ┃     ┖╴AnimationPlayer
    ┃  ┃  ┠╴Spectator04
    ┃  ┃  ┃  ┖╴Crowd female Hip Hop Dancing
    ┃  ┃  ┃     ┠╴Armature
    ┃  ┃  ┃     ┃  ┖╴Skeleton3D
    ┃  ┃  ┃     ┃     ┠╴Ch22_Body
    ┃  ┃  ┃     ┃     ┠╴Ch22_Eyelashes
    ┃  ┃  ┃     ┃     ┠╴Ch22_Hair
    ┃  ┃  ┃     ┃     ┠╴Ch22_Pants
    ┃  ┃  ┃     ┃     ┠╴Ch22_Shirt
    ┃  ┃  ┃     ┃     ┠╴Ch22_Sneakers
    ┃  ┃  ┃     ┃     ┠╴HandProp0
    ┃  ┃  ┃     ┃     ┃  ┖╴Airhorn
    ┃  ┃  ┃     ┃     ┃     ┠╴HornBody
    ┃  ┃  ┃     ┃     ┃     ┠╴HornBell
    ┃  ┃  ┃     ┃     ┃     ┖╴HornCan
    ┃  ┃  ┃     ┃     ┖╴@PhysicalBoneSimulator3D@83
    ┃  ┃  ┃     ┖╴AnimationPlayer
    ┃  ┃  ┠╴Spectator05
    ┃  ┃  ┃  ┖╴Crowd female Moonwalk
    ┃  ┃  ┃     ┠╴Armature
    ┃  ┃  ┃     ┃  ┖╴Skeleton3D
    ┃  ┃  ┃     ┃     ┠╴Ch03
    ┃  ┃  ┃     ┃     ┠╴HandProp0
    ┃  ┃  ┃     ┃     ┃  ┖╴FlagPole
    ┃  ┃  ┃     ┃     ┃     ┠╴Pole
    ┃  ┃  ┃     ┃     ┃     ┖╴FlagCloth
    ┃  ┃  ┃     ┃     ┃        ┖╴Cloth
    ┃  ┃  ┃     ┃     ┖╴@PhysicalBoneSimulator3D@84
    ┃  ┃  ┃     ┖╴AnimationPlayer
    ┃  ┃  ┠╴Spectator06
    ┃  ┃  ┃  ┖╴Crowd female Snake Hip Hop Dance
    ┃  ┃  ┃     ┠╴Armature
    ┃  ┃  ┃     ┃  ┖╴Skeleton3D
    ┃  ┃  ┃     ┃     ┠╴Ch22_Body
    ┃  ┃  ┃     ┃     ┠╴Ch22_Eyelashes
    ┃  ┃  ┃     ┃     ┠╴Ch22_Hair
    ┃  ┃  ┃     ┃     ┠╴Ch22_Pants
    ┃  ┃  ┃     ┃     ┠╴Ch22_Shirt
    ┃  ┃  ┃     ┃     ┠╴Ch22_Sneakers
    ┃  ┃  ┃     ┃     ┠╴HandProp0
    ┃  ┃  ┃     ┃     ┃  ┖╴LighterHand
    ┃  ┃  ┃     ┃     ┃     ┠╴Lighter
    ┃  ┃  ┃     ┃     ┃     ┖╴LighterFlame
    ┃  ┃  ┃     ┃     ┃        ┖╴Flame
    ┃  ┃  ┃     ┃     ┖╴@PhysicalBoneSimulator3D@85
    ┃  ┃  ┃     ┖╴AnimationPlayer
    ┃  ┃  ┖╴Spectator07
    ┃  ┃     ┖╴Crowd Male Angry Gesture
    ┃  ┃        ┠╴Armature
    ┃  ┃        ┃  ┖╴Skeleton3D
    ┃  ┃        ┃     ┠╴mixamorig_Teeth_Down_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Arms_Geo
    ┃  ┃        ┃     ┠╴mixamorig_R_Eye_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Teeth_Up_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Cigar_Geo
    ┃  ┃        ┃     ┠╴mixamorig_L_Eye_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Pants_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Hat_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Head_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Shoes_Geo
    ┃  ┃        ┃     ┠╴mixamorig_Jacket_Geo
    ┃  ┃        ┃     ┠╴HandProp0
    ┃  ┃        ┃     ┃  ┖╴LighterHand
    ┃  ┃        ┃     ┃     ┠╴Lighter
    ┃  ┃        ┃     ┃     ┖╴LighterFlame
    ┃  ┃        ┃     ┃        ┖╴Flame
    ┃  ┃        ┃     ┖╴@PhysicalBoneSimulator3D@86
    ┃  ┃        ┖╴AnimationPlayer
    ┃  ┠╴@Node3D@87
    ┃  ┃  ┖╴PosePivot
    ┃  ┃     ┖╴VisualPivot
    ┃  ┃        ┖╴feedback_rigged
    ┃  ┃           ┠╴Skeleton3D
    ┃  ┃           ┃  ┠╴obj1
    ┃  ┃           ┃  ┠╴MicInHand
    ┃  ┃           ┃  ┃  ┖╴MicInHandProp
    ┃  ┃           ┃  ┃     ┠╴Body
    ┃  ┃           ┃  ┃     ┠╴Band
    ┃  ┃           ┃  ┃     ┖╴Grille
    ┃  ┃           ┃  ┖╴@PhysicalBoneSimulator3D@88
    ┃  ┃           ┖╴AnimationPlayer
    ┃  ┠╴ContactShadow
    ┃  ┠╴@Node3D@89
    ┃  ┃  ┖╴PosePivot
    ┃  ┃     ┖╴VisualPivot
    ┃  ┃        ┖╴feedback_rigged
    ┃  ┃           ┠╴Skeleton3D
    ┃  ┃           ┃  ┠╴obj1
    ┃  ┃           ┃  ┠╴MicInHand
    ┃  ┃           ┃  ┃  ┖╴MicInHandProp
    ┃  ┃           ┃  ┃     ┠╴Body
    ┃  ┃           ┃  ┃     ┠╴Band
    ┃  ┃           ┃  ┃     ┖╴Grille
    ┃  ┃           ┃  ┖╴@PhysicalBoneSimulator3D@90
    ┃  ┃           ┖╴AnimationPlayer
    ┃  ┖╴@MeshInstance3D@91
    ┖╴@Node2D@92
```

> **Read the older entries with this in mind:** everything above that mentions `CrowdLine`,
> `ForegroundCrowd`, `CrowdHaze`, `SilhouetteArt`, `StageSilhouette`, the 15 crowd sprites or
> `CrowdLine.set_night()` describes a system that **no longer exists** — it was deleted on
> 2026-11-24 below. The crowd is 3D only; do not reintroduce a 2D or silhouette layer.

**Measured.** `godot --headless --path godot --script res://tools/headless_roster_check.gd` —
**385 PASS / 0 FAIL, `ALL CHECKS PASSED`** — and `godot --headless --path godot --script
res://tools/facing_audit.gd` — **94 checks, 0 FAIL, `ALL FACING CHECKS PASSED`**. The three new
crowd/DJ checks are the albedo-integrity one (86 surfaces, 0 unbound), material isolation (0
materials shared between characters) and `shadow_tint_amount == 0.0` on every cel material.

**Not verified.** No GPU, display or audio here: the restored female atlases, the brightened crowd,
the removed silhouettes, the facing fix as it *looks* on screen, and the frame rate of eight rigged
spectators on a Chromebook have **not** been seen. The toolbar/visual check is the owner's.

## 2026-11-24 — Playtest regressions, PART 2 (procedural props out, .glb slots in; select screen rebuilt)

Second half of the owner's playtest report. Same rules as PART 1: no programmer art, `ANIM_OFFSET`
and the combat frame data untouched, Chromebook-friendly (no per-frame allocations, no new per-frame
node lookups, no heavy shaders).

### Issue 3 — every procedural prop is deleted; five `.glb` slots replace them

**Deleted (was built in code out of `BoxMesh` / `CylinderMesh` / `SphereMesh` / `QuadMesh`):**
the two speaker stacks (double-18" sub bins, horns, VU LED ladders, rack amps, corner brackets, plinths),
the DJ booth rig (deck shell, two turntables + vinyl, mixer, three channel faders, airhorn), the
wireless microphone each adult fighter held, L!kkle Moore's mic stand, his dictionary, and every crowd
flag, lighter/flame and raised airhorn. No `_draw`, `ArrayMesh` or `CSG*` prop builder survives.

**Kept:** the textured sand stage floor, the stage collision bounds, the barrier, the truss/lights, the
sky/sun/light pool, the contact-shadow quad, the projectiles and `MusicNoteBurst` — these are stage
structure and VFX, not props. `DJBooth3D.airhorn_up()` stays as a clip-state query (`STATE_AIRHORN`)
even though the horn prop is gone.

**`scripts/PropLoader.gd`** (`class_name PropLoader`, `extends Node3D`) — `model_path: String`,
`place_transform: Transform3D`, `required: bool`. On `_ready()` it checks `ResourceLoader.exists()`;
when the file is there it instances the `PackedScene` and runs it through the same shared cel setup as
the fighters and crowd (`CharacterModelSlots.apply_cel`, white tint, `shadow_tint` off → **full
albedo**). When the file is **not** there it loads nothing, draws nothing and emits one
`push_warning("PropLoader: missing <path>")` — never a box, cylinder, capsule, quad or sprite.
`EXPECTED_MODELS` lists the five files so the tree dump and the checks cannot drift from the README.
`is_empty()` and `load_model()` are the only API the rest of the project uses.

**Slots** (each a `PropLoader`, `scale` and `rotation_degrees` live on the slot node for adjustment):

| Slot | Path | Model |
| --- | --- | --- |
| `Arena3D/SpeakerStackLeft` | left of the yard (±2.55, −1.45) | `jamaican_speaker.glb` |
| `Arena3D/SpeakerStackRight` | right of the yard | `rasta_speaker.glb` |
| `Arena3D/DJBooth3D/PropLoader` | behind the stage, 3D DJs at it | `dj_booth.glb` |
| `<fighter>/Skeleton3D/MicInHand/MicInHandSlot` | `BoneAttachment3D` on `mixamorig_RightHand` | Feedback & L!ckshot → `wireless_mic.glb` (no mirroring when turning) |
| same, L!kkle Moore | `BoneAttachment3D` on `mixamorig_RightHand` | `mic_stand.glb` |

`assets/models/props/README.md` documents the contract: **1 unit = 1 m, pivot at the base centre,
facing +Z**. Drop a file in and it appears with no code change.

**Verified empty-folder run** (`godot --headless --path godot --script res://tools/tree_dump.gd`,
all five files absent):

```
PROP SLOTS (5)
  /root/TestArena/Arena3D/SpeakerStackLeft  jamaican_speaker.glb  loaded=false empty=true meshes=0
  /root/TestArena/Arena3D/SpeakerStackRight rasta_speaker.glb     loaded=false empty=true meshes=0
  /root/TestArena/Arena3D/DJBooth3D/PropLoader dj_booth.glb       loaded=false empty=true meshes=0
  .../feedback_rigged/Skeleton3D/MicInHand/MicInHandSlot wireless_mic.glb  loaded=false empty=true meshes=0
  .../lickshot_rigged/.../Skeleton3D/MicInHand/MicInHandSlot wireless_mic.glb loaded=false empty=true meshes=0
MISSING MODELS (5 of 5): jamaican_speaker.glb, rasta_speaker.glb, dj_booth.glb, wireless_mic.glb, mic_stand.glb
```

Zero mesh nodes inside any slot, and the scene tree shows `SpeakerStackLeft` / `SpeakerStackRight` /
`DJBooth3D` with **no** children. The run logs exactly the expected warnings:

```
WARNING: PropLoader: missing res://assets/models/props/jamaican_speaker.glb
WARNING: PropLoader: missing res://assets/models/props/rasta_speaker.glb
WARNING: PropLoader: missing res://assets/models/props/dj_booth.glb
WARNING: PropLoader: missing res://assets/models/props/wireless_mic.glb   (x2, one per fighter)
```

`mic_stand.glb` only warns when L!kkle Moore is in the match — it is the only fighter who asks for it,
so the default Feedback vs L!ckshot match lists four of the five. Nothing crashes, nothing nulls.

### Issue 4 — independent P1/P2 select cursors, lock-in, and "Patois" spelling

`scripts/ui/TitleScreen.gd` was rebuilt around **two independent cursors and two independent locks** —
there is no shared "selected" variable anywhere:

- `p1_cursor` starts on **Feedback**, `p2_cursor` on **L!ckshot** (`MatchSetup.DEFAULT_P2` changed from
  `feedback` to `lickshot`). The menu can no longer open on a Feedback mirror by accident.
- Each card carries its own tag — **P1 in gold, P2 in cyan** — on the panel border, in the corner tag box
  and around the name; the focused panel's cursor arrows (`▶` / `◀`) are drawn inside that player's card,
  never the other one's.
- Keys: **P1** `A`/`D` move, `J` lock, `K` cancel · **P2** `←`/`→` move, `L` lock, `O` cancel ·
  `TAB` AI style · `V` subtitles · `M` beat audition · `ENTER` fight · `ESC` steps back one lock, then
  leaves. Every action fires on **key press** (`event.pressed` and not `event.echo`), never on release,
  and no animation or timer gates a move — a cursor moves on the same frame the key lands.
- P2's keys are handled in the same `_unhandled_input` and are **never** consumed by P1's branch (the
  handler never calls `set_input_as_handled`), so one keyboard drives both panels.
- 1P vs CPU: after P1 locks, `p1_focus` drops to the P2 panel, so P1's own `A`/`D`/`J` pick and lock the
  CPU fighter. `K` unlocks P1 and hands the keyboard back.
- Locked panels fill their bar and read **LOCKED**; `K`/`O`/`ESC` unlock. A mirror match is allowed and
  printed on screen ("MIRROR MATCH · BOTH PLAYERS PICKED …") — a pick is never silently replaced by a
  default, and `ENTER` does nothing at all until **both** sides are locked.
- Hand-off: `MatchSetup.commit_match(p1, p2)` writes `p1_fighter_id` / `p2_fighter_id` (and the older
  `p1_fighter` / `p2_fighter` aliases) in the one autoload; `MatchSetup.start_match()` prints
  `[match] P1 = … P2 = …` and so does `TestArena._ready()`, so the ids that actually loaded are in the log.

**Spelling.** Repo-wide grep for `Patwa`, `Patwah`, `Patoi`, `Patois-ish` found the variant only in
comments, check descriptions and `artifacts/sound-clash/SOUND_CLASH_CULTURE.md` — every player-facing
string already read `PATOIS` / `Patois`. Those comments and the culture note now read **Patois** too.
The **identifier `PATWA_COLLECTION` was deliberately left unchanged** (code depends on it; the brief says
never rename keys/IDs), and so were all Patois entry strings.

**Counts and checksums (before → after, identical):**

| Measurement | Before | After |
| --- | --- | --- |
| Patois entries in `TestArena.PATWA_COLLECTION` | **31** | **31** |
| `BaseFighter.gd` sha256 (frame data) | `8bbf7f540f12820cf4e1cb0065e6e981aa7ae062cfb27959c3a5dd84db1c3371` | same |
| `FighterRoster.gd` sha256 (frame data) | `25b9d82111e6ebacb4cfa02561ce85fc0b2953f5f16e76e43e954dc0c2ac6adb` | same |
| `ANIM_OFFSET` / `ANIM_OFFSET_DEFAULT` (`BaseFighter.gd:203` / `:262`) | untouched | untouched |

**Measured.** `godot --headless --path godot --script res://tools/headless_roster_check.gd` —
**411 PASS / 0 FAIL, `ALL CHECKS PASSED`** (385 in PART 1 + 26 new: five prop slots, empty slots draw no
fallback mesh, IDs unwrapped from the hand, booth/crowd hand attachments gone, and the whole select flow
driven with real `InputEventKey` presses — independent cursors, release-inert keys, lock/unlock, CPU pick,
"cannot start until both locked", P1 = L!kkle Moore vs P2 = Feedback, then P1 = L!ckshot vs P2 = L!ckshot).

**Not verified.** No GPU, display, audio or Chromebook here, and none of the five `.glb` props exist yet:
the select screen's look, the empty speaker/booth positions, the hand-mount transform once a real mic
arrives, and typing on the actual Chromebook keyboard have **not** been seen. Those are the owner's
checks. `godot --headless --path godot --export-release "Web" ../docs/index.html` rebuilds the web
export; it does not prove the art.

## 2026-11-24 — Live-match regressions, PART 1 OF 2: invisible opponent, facing + floor, attack input

Owner playtest of `4560bd2` on `feature/3d-cel-shaded` reported three match-breaking failures.
Every one of them was first **measured** on the real `TestArena.tscn` (not a bare `BaseFighter`),
and each fix is aimed at the measured cause. **`ANIM_OFFSET` / `ANIM_OFFSET_DEFAULT`, every
attack's startup/active/recovery/damage/hitbox value, the 132 BPM beat clock, the round flow and
all 31 Patois entries are untouched**, and no art was added, generated, resized or replaced — the
five `PropLoader` `.glb` slots still draw nothing and still warn (`§` item 53 / PART 2 issue 3).

### Issue 1 — the opponent rendered ~76 m above the sand (read as "invisible P2")

**Measured cause.** `FighterModel3D._play_baked_idle()` picked `animation.get_animation_list()[0]`
*after* `_install_clips()` had already mounted the Mixamo library. That list also contains library
entries, so the call restarted an arbitrary clip — `mixamo/getup` for Feedback — or the body's own
raw baked export (`Armature|Armature|mixamo_com|Layer0` for the two Tripo bodies), whichever sorted
first. Those baked takes animate `mixamorig_Hips` **position** in the source rig's units, which put
the rendered body at world **y ≈ 76 m** (P1 in the mirror match) and out of the camera; the same
call also overwrote the state machine's idle, so nothing the FSM asked for was ever drawn.
`ModelSource` binding, `visible`, mesh and surface counts were all correct — the geometry was simply
above the frame.

**Fix.** `_play_baked_idle()` now returns early whenever a Mixamo library is installed, so the
library is the only thing that can drive a rigged fighter. `_play_role()` no longer short-circuits on
the role name alone: it also compares `animation.current_animation` with the clip it wants and the
playing state, then re-plays, so a clip left on the player by anything else can never freeze the
body on the wrong take.

### Issue 2 — facing the camera, and sinking / teleporting on knockdown

**Measured causes.**
1. `hips_yaw_delta()` took the **Y term of `pose * rest⁻¹` in YXZ order** as "the heading". That is
   not a heading: on the two rigs whose pelvis carries a large bind yaw (L!ckshot −59.6°, L!kkle
   Moore −51.2°) a few degrees of pitch/roll leak into that Euler term, and it reported a phantom
   **29.6° / 39.2°** turn. `_compensate_clip_yaw()` then rotated `VisualPivot` by exactly that
   amount, which is why those two fighters did not face their opponent.
2. The clips' **root translation** was never stripped. Played on a 1.55 m body the Hips position
   keys moved the pelvis metres, so a knockdown sank 0.36–0.47 m through the sand and warped the
   body sideways.

**Fixes.**
- `MixamoClips._strip_root_translation()` removes every `TYPE_POSITION_3D` track on the root node,
  `Hips` or `Root` (iterating backwards so indices stay valid). `MixamoClips.strip_root_motion()`
  applies the same yaw + translation pass to **every** animation on a fighter's player, including
  the body's own baked export in the default library; `FighterModel3D.bind()` calls it before
  anything can play. Every take is now strictly in place: the `CharacterBody2D` owns position, the
  clip owns pose only.
- `pose_turn_yaw()` measures the heading change properly — the signed angle about world up between
  the pelvis' horizontal reference axis at **rest** and at the posed frame. The rest reference is
  essential: both Tripo rigs measure (−0.87, 0.50) / (−0.78, 0.63) at rest while their meshes face
  +X, so an absolute bone axis reports a turn that is not there. `world_forward()` is now
  authored-forward → shipped pivot → pose turn, and `hips_yaw_delta()` returns `pose_turn_yaw()`
  so the pivot compensation cancels a real clip turn and nothing else.
- `FighterModel3D._clamp_to_floor()` is the presentation guard: after posing, if the lowest posed
  bone origin is under `FLOOR_BONE_CLEARANCE` (0.10 m) the pose pivot is lifted by exactly the
  deficit. It only ever lifts, `_animate_pose()` rebuilds the pivot position every frame so the
  correction cannot stack, and `CharacterBody2D`, the 2D sprite and every hitbox are not touched.

### Issue 3 — attack buttons felt dead

Three separate reasons, all fixed:
1. The `_play_baked_idle()` override above meant the combat state changed while the **body kept
   playing one baked clip** — a punch resolved damage but showed nothing.
2. `_play_role()`'s role-only short-circuit (above) could leave the wrong clip running for the
   whole match.
3. **Presses were dropped during hitstop.** `_physics_process()` polled input *after* the
   `_hitstop_frames` early return, so any attack pressed during the 4–9 frozen ticks of a contact
   was lost — exactly "I pressed it and nothing happened". `BaseFighter` now latches attack presses
   (`LATCHED_INPUTS`, `_press_ttl`) at the top of the tick for `INPUT_BUFFER_TICKS`, and
   `_poll_local_input()` consumes them (`_take_press`). One press fires one action, `input_locked`
   clears the latches, and `reset_for_round()` clears them so a round never opens on last round's
   press. Held actions (guard, crouch, movement) and jump keep their instant read, and no frame
   data, damage or hitbox value changed.

### Verification — actually run in this environment

Godot **4.7.2.stable.official (ed1daf0bf)** headless (the workspace binary; no GPU, display or audio
device, and **no export templates are installed for this version**):

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/live_match_check.gd
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --script res://tools/facing_audit.gd
```

- **`tools/live_match_check.gd` (new, 123 assertions, `ALL LIVE MATCH CHECKS PASSED`, exit 0)** —
  boots the real arena for all **9 pairings** and asserts, per side: the model is `visible`, has a
  non-empty `MeshInstance3D` with a real surface, its **live skinned-mesh bounds** (skeleton pose ×
  mesh skin weights, sampled) sit inside the camera frustum and on screen, the lowest drawn point is
  on the sand, and the rendered forward is within 5° of +X (P1) / −X (P2) with the pivot yaw off its
  expected value by ≤0.5°. Then, for all three fighters: a 200-tick knockdown → get-up run keeps the
  lowest drawn point ≥ −0.05 m with **zero** body teleport and the render anchored to the body
  within 0.02 m, and **no installed take animates Hips/Root position**. Finally it presses
  `p1_light` / `p1_heavy` / `p1_tump` / `p1_upper_box` / `p1_grab` and holds `p1_guard` through the
  real InputMap on each fighter and requires the matching state, plus one jab pressed **during
  hitstop** that must still fire.
- **`headless_roster_check.gd`: 411 PASS / 0 FAIL, `ALL CHECKS PASSED`** — unchanged.
- **`facing_audit.gd`: 94 checks, 0 FAIL, `ALL FACING CHECKS PASSED`** — unchanged, and now backed
  by a rest-referenced measurement rather than the self-cancelling one.
- The 58 `.fbx.import` sidecars that Godot 4.7's importer rewrote during the import pass were
  reverted, so the committed import settings stay as authored.

### Not verified, and what is left

- **No GPU, display or audio device here.** Nothing was watched. The fixes are verified as state,
  geometry, animation name and on-screen projection — not as a look. The owner still needs to see
  the cel look, the topple, the clip transitions and 60 FPS on the Chromebook / iPhone Safari.
- **`/docs` was NOT rebuilt.** No 4.7.2 export templates exist in this workspace (the previous
  exports were built with 4.5.stable), so re-exporting would silently change the engine version of
  the shipped build. The playable `/docs` build therefore still predates these three fixes; rebuild
  it with the pinned 4.5 toolchain before publishing.
- The floor clearance (0.10 m) and the latch window (`INPUT_BUFFER_TICKS`, 12 ticks) are hand-set
  defaults for the owner's playtest, not approved tuning.
- P2 is still AI-driven by design (`use_local_input = false`); the press assertions cover P1.
  Local 2P input remains backlog **B2**.
- `_tick_crouch()` still accepts no attacks and air attacks are still `[TODO]` — unchanged by this
  pass, and part of the documented moveset plan rather than a regression.

## 2026-11-24 — Visual presentation, UI polish and the Godot 4.5 Web rebuild: PART 2 OF 2

Second half of the same owner playtest. Same global rules: **zero programmer art**, and
`ANIM_OFFSET`, every combat frame data value, the 132 BPM beat clock and all 31 Patois entries
are untouched. The five `PropLoader` `.glb` slots still draw nothing and still warn. This
**supersedes the 8-body single-row crowd** described in the PART 1 entry above.

### 1. Packed multi-row 3D crowd on all seven delivered characters

`CrowdController3D` went from 8 spectators in one ringside row to **22 across three staggered
depth rows a side**: 4 front + 4 mid + 3 back per bank, rows at **z −4.15 / −5.05 / −5.95**
(behind the z −2.55 barrier), each body with its own depth jitter, its own inward yaw and its
own height (1.52–1.92 m). Every slot cycles the **seven delivered Mixamo characters** in sorted
filename order — all three male and all four female rigs are on screen at once.

- **Shared geometry.** `CharacterModelSlots.share_meshes()` binds the first instance's `Mesh`
  per node path to every later instance of the same file, so 22 bodies reference **53 unique
  meshes across 170 mesh nodes** (measured). Instancing a `PackedScene` happens to share
  sub-resources in Godot, but that is an importer detail; this is the guarantee.
- **Per-instance look without a repaint.** Each member draws one shader material of its own with
  its bank's light colour multiplied by a seeded **±2.5 % brightness** nudge and a
  **±0.012 hue** nudge, `shadow_tint_amount` still 0.0 — full albedo, no two neighbours sharing
  a material.
- **Ripple.** Reaction delay is now row base (0 / 0.11 / 0.22 s) + 0.028 s per metre along the
  bank + seeded jitter, so ringside answers first and the back row last.
- **Cost.** 76,178 crowd triangles + 6,982 booth = **83,160**, measured from the built meshes,
  inside a raised **90,000** atmosphere ceiling (was 40,000). Each character is still held to
  ≤3,500 triangles by its own assertion.

### 2. Afternoon / Sunset / Night rebuilt as three designed light rigs

`Arena3D.PHASES` now drives a real key + fill + rim + fog + sky setup per phase, instead of one
warm tint with the spots turned up:

| | Afternoon | Sunset | Night |
| --- | --- | --- | --- |
| Sun | 1.90, warm white, high | 1.55, amber, 9° above horizon | 0.10 (effectively off) |
| Fill | cool blue 0.26 | **violet/magenta** 0.38 | deep blue 0.46 |
| Spots | 0.26 (resting) | 0.85 amber | **3.00 cool white** |
| Rim | warm sand 0.80 | magenta-amber 1.35 | **cyan 1.60** |
| Ambient | blue sky 0.56 | warm violet 0.48 | deep indigo 0.32 |
| Fog | 0.0032 pale | 0.0115 amber | 0.019 indigo |
| Sky | saturated zenith → warm gold horizon | violet zenith → **amber horizon** | near-black indigo |

The fighters' **crisp directional shadow is preserved in every phase**: the key light always
casts, with `light_angular_distance = 0` (hard-edged), `shadow_blur 0.7`, `shadow_bias 0.03`,
2 splits at 0.28 and a 26 m shadow distance. The cool camera fill is now a phase value, not a
fixed colour, which is what stops dusk and night reading as one flat amber card.

### 3. Bigger, bolder arcade UI and sharper note VFX

- **Match HUD** (`TestHud`): health bars **442 × 32** (was 320 × 18) with a dark plate, gold
  border, Rasta corner tab, two-tone lit fill and 23 px Bungee name plates; Hype meter
  **264 × 22** with a 50 % milestone tick and a 17 px readout; round clock **160 × 66** with
  **40 px** digits under a Rasta rail; round-win pips grown to r 8 with a gold ring; Patois pill
  64 px tall with a 27 px shout and 16 px gloss; banners up to 36 / 88 / 46 px (round / K.O. /
  rematch); `FORWARD!` surge banner 648 × 112 with 48 px type; bottom legend 14 px.
- **Character Select** (`TitleScreen`): cards **544 × 348** with a Rasta top rail, a colour
  frame, a dark inset and a gold inner rail; **58 px** fighter names, a **34 px** P1/P2 tag,
  22 px taglines, a 30 px `LOCKED` badge; splash title 120 / 136 px; 21–27 px footers and
  settings lines. Every input, lock and cursor rule from the PART 1 rebuild is unchanged.
- **Music-note bursts** (`MusicNoteBurst`): burst life tightened 0.72 s → **0.62 s**, velocity
  damping 0.86, glyphs snap to full size at 1/8 of the burst and shrink out after 55 %, note
  heads up to 22 segments with a crisper doubled flag edge, a **thin 40-segment bass ring** and
  a new **hot white-gold impact flash ring** that is gone in **0.16 s** — the readable "hit"
  frame before the notes follow through.

### 4. `/docs` rebuilt with pinned Godot 4.5-stable

`df -h ~` first (187 MB free on `/`, 1.4 GB in `/tmp`). Then:

- **Engine:** `Godot_v4.5-stable_linux.x86_64` (69,032,926 B zip → 135,868,560 B binary),
  reporting **4.5.stable.official.876b29033**, downloaded to `/tmp` and removed after the export.
- **Template:** only `templates/web_nothreads_release.zip` (9,440,969 B) was taken out of the
  1,356,853,963 B `Godot_v4.5-stable_export_templates.tpz` — a Python script read the remote
  ZIP's central directory through HTTP range requests and fetched just that member, so the
  1.36 GB archive never touched the disk. It is installed at
  `~/.local/share/godot/export_templates/4.5.stable/` with `version.txt`.
- **A stale-import trap worth recording.** Pointing 4.5 at a project whose `.godot/imported`
  cache had been built by 4.7.2 loads the FBX scenes but reports **zero animation tracks** —
  all 38 clip roles failed to bind and the build would have shipped silent, T-posed fighters.
  Deleting `godot/.godot/imported` and re-importing with 4.5 fixed it (the same probe then
  reported `anims=1 tracks=53`); the committed `.import` sidecars were **not** rewritten, so
  no import churn was committed. Always build the shipped Web export with the pinned 4.5
  toolchain, and do not trust an import cache produced by another engine version.
- **Export:** `--headless --path godot --export-release "Web" ../docs/index.html` (exit 0, 17 s).
  `docs/index.pck` **68,621,868 B** (69,880,088 before), `index.wasm` 38,057,390 B,
  `index.js` 305,185 B, `index.html` 5,449 B. The only HTML change is the pck size in
  `GODOT_CONFIG`. Log output was the environment's known non-fatal fontconfig noise.

### Verification actually run

Authoring pass on **4.7.2.stable**, final pass on **4.5.stable.official.876b29033**, both
headless, both identical:

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --script res://tools/live_match_check.gd
godot --headless --path godot --script res://tools/facing_audit.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

- **`headless_roster_check.gd`: 425 PASS / 0 FAIL, `ALL CHECKS PASSED`** (411 before). New
  assertions: 18–24 spectators (**22**); two equal banks of 11; three rows holding 8 / 8 / 6
  with a real depth span behind the barrier; **all seven** delivered models on stage; unique
  meshes fewer than mesh nodes (sharing); the raised 90,000-triangle ceiling; the crisp shadow
  settings; the violet sunset fill and amber-horizon/violet-zenith sky; the cyan night rim and
  indigo ambient; the burst's impact flash ring; the HUD's 442 × 32 bars, arcade framing and
  40 px clock.
- **`live_match_check.gd`: 123 checks, 0 FAIL** — unchanged (all nine pairings, facing, floor,
  input).
- **`facing_audit.gd`: 94 checks, 0 FAIL** — unchanged.
- Both earlier suites' crowd assertions were updated for 22 bodies (the "10 delivered
  characters" count and the right-bank act index now derive from `zone_count()` instead of
  hard-coded 4s).

### Not verified — no GPU, display or audio device here

Nothing was **seen**. The packed crowd's look and spacing, whether 22 rigged bodies plus 83k
triangles actually hold 60 FPS on the Chromebook / iPhone Safari, the new light rigs' colour and
contrast in motion, the dodge/ripple feel, the new HUD and select-screen geometry on a real
1080p/720p screen, and the note flash's readability at speed are all **unmeasured**. The
triangle count, the sharing structure, the phase values, the HUD constants and the Web export
are arithmetic and state, not eyes. `/docs` is rebuilt from this commit, but the build has not
been opened in a browser here.

## 2026-11-24 — Stefan Iverson Virtual Mentor combat-feel overhaul (all 6 systems)

Owner brief: implement the complete 2D-to-3D fighting-animation overhaul on
`feature/3d-cel-shaded` (Godot 4.5-stable) — six presentation systems on the 3D layer,
headless verification, `/docs` rebuilt, pushed. **Implemented and headlessly verified;
nothing has been seen, heard or timed** (this environment has no GPU, display or audio
device).

**Core combat determinism is untouched.** `BaseFighter.gd` sha256
`d69c8d859855c6ab9d6565135e2c884d7ba2faeb78d765f2e7a2cb39df70f675` and `FighterRoster.gd`
sha256 `25b9d82111e6ebacb4cfa02561ce85fc0b2953f5f16e76e43e954dc0c2ac6adb` are byte-identical
to the previous commit — no `ANIM_OFFSET`, FSM tick count, hitbox, hurtbox, 132 BPM beat
window, Crowd Hype rule or Patois entry changed. `tools/animation_feel_audit.gd` asserts
both hashes on every run. Zero programmer art was added: the five `PropLoader` `.glb` slots
are untouched and still draw nothing (they still warn).

### New files

- `godot/scripts/fighters/AnimationFeel.gd` — `class_name AnimationFeel`, the shared maths:
  stepped quantization, the attack curve, the overshoot ramp, the engagement/negative-space
  angles, tension, the two squash presets and their damped spring, the recoil ladder, the
  ground-pin tolerance. Used by both the runtime and the audit, so they cannot drift apart.
- `godot/scripts/fighters/FightBodyModifier3D.gd` — `class_name FightBodyModifier3D extends
  SkeletonModifier3D`. Caches Spine1/Spine2/Neck/Head/shoulder/arm bone indices once and
  writes the whole-body engagement, negative space, eye-line, overshoot, micro-tension and
  the additive recoil whip. Registered on the fighter's `Skeleton3D` with `active = false`
  and driven explicitly by the proxy at process priority 100, so the layer always lands
  after the AnimationPlayer wrote the clip pose.
- `godot/tools/animation_feel_audit.gd` — 142 checks (below).

### The six systems

1. **Stepped arcade pose quantization — `F4`, default ON.** `FighterModel3D._drive_clip_time()`
   seeks the sampled clip time every frame from the fighter's combat phase and quantizes it to
   an **18 fps** grid (inside the 16–20 owner band) during `ATTACK_STARTUP/ACTIVE/RECOVERY`,
   `HITSTUN` (hitstun *and* blockstun) and `TAUNT`. The clip therefore holds ~3.3 frames at
   60 fps and the mid-swing breakdown poses are actually sampled instead of being skipped by a
   linear playhead. `CharacterBody2D` movement, the camera and every contact point stay at a
   smooth 60 fps. `F4` (`TestArena.toggle_stepped_arcade()`) flips it live on both fighters and
   flashes `STEPPED ARCADE · ON/OFF` in the HUD corner; the legend lists `F4 stepped step`.
2. **Venom/Makoto non-linear attack curve.** At bind, each attack clip's true peak hand/foot
   reach is measured (24 samples, horizontal hand/foot extension from the hips) and stored as
   `t_impact`, clamped to 0.36–0.62. Measured: Feedback light 0.36, strong 0.36, tump 0.62,
   upper_box 0.50, special 0.50; L!ckshot light 0.375, tump 0.542, special 0.583; L!kkle Moore
   light/strong/upper_box/special 0.36, tump 0.542, kick 0.50. `STARTUP` compresses into the coil
   (`0.35 · p^1.6` → 0.35); `ACTIVE` whips across the breakdown poses to `t_impact` in 1–2 frames
   (frame 1 already ≥75 % of the way) and holds it through a 3-frame settle; `RECOVERY` eases
   `t_impact → 1.0`. Hitstop freezes `state_frame`, so the extended silhouette is held across
   active + freeze. A **+4°** upper-spine/shoulder overshoot rides ACTIVE frames 1–2 and is gone
   by frame 4.
3. **"Move everything in the body" + Wolverine negative space.** `FightBodyModifier3D` adds a
   shoulder/upper-spine counter-twist (coil away on startup, drive through on active, unwind on
   recovery), carries the off-arm/elbow 7° clear of the ribcage in every stance, and a 6°
   head/eye-line awareness toward camera. The **hips are never touched** (asserted), so the ±X
   facing audit is unaffected.
4. **Alive hitstop.** The defender gets a classic X-shake on `PosePivot.position.x` (1.2 cm, 2.1
   rad phase) while frozen — presentation only, the `CharacterBody2D`, hurtbox and hitboxes do not
   move. The attacker's Spine2/Head keep a 0.7° micro-tension at 7.5 Hz.
5. **`SquashPivot` impact pop.** New `Node3D` inserted between `VisualPivot` and the model, so the
   pop can never leak into the facing pivot or a hand attachment. Anticipation/landing/knockdown
   `(1.06, 0.92, 1.06)`, heavy/special contact `(1.07, 1.04, 0.95)` (a light strike gets half),
   driven by a damped spring (stiffness 210, damping 26) that returns **exactly** to
   `Vector3.ONE`. Every `BoneAttachment3D` hand prop is inverse-scaled per axis against the pop,
   so a mic or mic stand keeps its own proportions.
6. **Additive hit-react overlay + ground pinning.** Recoil strength is read from the **existing**
   `strike_resolved` result — blocked 0.40, light 0.55, heavy 1.00, counter 1.35 — and whips
   Spine1 → Spine2 → Neck → Head on hitstun/blockstun with a 0.42 s decay. Horizontal drift is
   locked by construction (the takes carry no Hips/Root position tracks and the Hips yaw stays
   pinned), and `_pin_feet_to_ground()` places the lowest planted foot/toe so the **drawn sole**
   sits on world y 0 within 1 cm, in every grounded state and both facings.

### Defects found and fixed while doing it

- **Ground calibration needed the real skin mapping.** `ARRAY_BONES` indexes the skin's bind list
  on the Mixamo body and skeleton bones directly on the two Tripo bodies; assuming one convention
  made Feedback's drawn sole measure **0.72 m above its own foot bones** (the old bounds helper
  only asserts a lower bound, so nothing caught it). `_measure_sole_drop()` now measures both
  readings once at bind and keeps the physically plausible one (`sole_bind_mapped`), which is
  exposed and asserted.
- **`hips_yaw_delta()` no longer gated on `is_playing()`.** A clip that reached its end kept its
  baked hips turn, which the facing pivot therefore did not cancel — up to 14° off ±X after a
  clip was driven to its last frame. Facing is now corrected whether the take is playing, paused
  or finished.
- **The squash spring clamps its dt to 1/30 s.** An explicit spring integrated with one long first
  frame (cold start / stalled tab) diverged and threw the mesh bounds into the 10^15 range; a
  live-match knockdown check caught it.

### Verification actually run — Godot **4.5.stable.official (876b29033)**, headless

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/animation_feel_audit.gd
godot --headless --path godot --script res://tools/facing_audit.gd
godot --headless --path godot --script res://tools/live_match_check.gd
godot --headless --path godot --script res://tools/headless_roster_check.gd
godot --headless --path godot --export-release "Web" ../docs/index.html
```

- **`animation_feel_audit.gd` — 142 checks, 0 FAIL, `ALL ANIMATION FEEL CHECKS PASSED`.** Covers
  both combat-file hashes; the 18 fps band; `quantize()` grid-exactness and the distinct-pose
  ceiling; the coil → whip → settle → recovery numbers; the +4° overshoot ramp; the recoil
  ladder and decay; both squash presets and the spring's exact return; per fighter — foot-bone
  discovery, a cached modifier, `SquashPivot` parentage, a plausible sole offset, a `t_impact`
  inside the band for every attack clip, **stepped seeks only on the grid** with ≥6 held frames
  of 14 and F4-OFF smooth again (13–14 of 14 frames off grid), shoulder/spine/neck/head deltas
  with the **hips untouched (<0.01 rad)**, hitstop tension present and silent outside hitstop,
  light < heavy < counter recoil, `strike_resolved` arming only on a hit that lands on *this*
  fighter, the stretch/squash peaks, prop counter-scaling, the squash returning to exactly one,
  and **the drawn sole within 1 cm of the sand in IDLE/WALK/ATTACK_ACTIVE/HITSTUN/TAUNT on both
  facings** (measured −0.0004 … −0.0091 m), plus facing still within 5° after all of it.
- **`facing_audit.gd` — 94 checks, 0 FAIL, `ALL FACING CHECKS PASSED`.**
- **`live_match_check.gd` — 123 checks, 0 FAIL, `ALL LIVE MATCH CHECKS PASSED`.**
- **`headless_roster_check.gd` — 425 PASS, 0 FAIL, `ALL CHECKS PASSED`.**
- Real `TestArena.tscn` booted 300 frames headless with no script error (only the known exit-time
  "1 resources still in use" notice and the environment's fontconfig warning).

**`/docs` rebuilt** with the pinned 4.5 toolchain (the import cache was rebuilt from scratch with
4.5 first — a 4.7-built cache loads the FBX scenes with zero animation tracks):
`index.pck` **68,659,380 B** (68,621,868 before), `index.wasm` 38,057,390 B,
`index.js` 305,185 B, `index.html` 5,449 B. The engine download in `/tmp` was deleted after the
export.

### Not verified

- **No GPU, display or audio device here, so nothing was watched.** The 18 fps stepped read, the
  whip/overshoot/settle as it *feels*, the shoulder counter-twist silhouette, the negative-space
  gap, the hitstop shake and micro-tension, the impact pop, the prop isolation and the ground pin
  are verified as numbers and bone/test transforms, not as a look.
- **60 FPS on a Chromebook / iPhone Safari is unmeasured.** The layer adds no per-frame allocation,
  no node lookup, no texture and no extra pass: every bone id, foot bone, prop baseline and
  `t_impact` is cached at bind, and the only per-frame work is a handful of quaternion writes, one
  `seek()` and one scale write.
- The 5 mm pin bias, the 0.05 m pin deadband, the 18 fps rate, the 3-frame settle, the 4° overshoot,
  the engagement/negative-space angles and the recoil ladder are hand-set defaults awaiting the
  owner's eye and a device playtest.

## 2026-11-24 — PART 1 of 2: combat-feel audit, live-match integrity, stepped poses, attack curve, body layer

Owner brief: PART 1 of the Stefan Iverson-technique overhaul on `feature/3d-cel-shaded`, in five
numbered commits. Hard rules read at the top of every commit: `BaseFighter.gd` `ANIM_OFFSET`, all
combat frame data/hitboxes, the 132 BPM beat sync, the Crowd Hype rules and the 31 Patois entries
stay byte-identical; animation code reads combat state and never writes it; **zero programmer art**
(no primitive prop or character meshes — 2D UI and material/post-process shaders are fine); 60 FPS
on a Chromebook and iPhone Safari, so zero per-frame allocations and every bone/node cached; the
techniques are implemented as techniques and the mentor is never cited in code.

### COMMIT 0 — Audit (documentation only)

`git pull --rebase origin feature/3d-cel-shaded`: already current (`behind=0`; HEAD `7d4adbb`), so
no rebase ran. The pre-existing, unrelated `art-source/` working-tree deletions were left untouched
and were not staged.

**Baselines actually run in this session** (Godot **4.5.stable.official, 876b29033**, headless,
`--import` first, no GPU/display/audio device):

| Suite | Result |
| --- | --- |
| `tools/headless_roster_check.gd` | **425 checks, 0 FAIL**, `ALL CHECKS PASSED` |
| `tools/live_match_check.gd` | **123 checks, 0 FAIL**, `ALL LIVE MATCH CHECKS PASSED` |
| `tools/facing_audit.gd` | **94 checks, 0 FAIL**, `ALL FACING CHECKS PASSED` |
| `tools/animation_feel_audit.gd` | **142 checks, 0 FAIL**, `ALL ANIMATION FEEL CHECKS PASSED` |

#### What exists vs what is missing

| Spec item | State at `7d4adbb` | Evidence | PART 1 action |
| --- | --- | --- | --- |
| C1 · both fighters inside the frustum, all 9 pairings | **EXISTS** | `live_match_check`: `_check_pair` × 9, skinned bounds projected into the viewport | keep; no change needed |
| C1 · `VisualPivot` strictly ±X within 5° | **EXISTS** | `facing_audit` 94 checks; `animation_feel_audit` re-asserts after every system | keep |
| C1 · no root/hips drift, sink or teleport on knockdown/get-up | **EXISTS** | `live_match_check` `_check_knockdowns`: lowest ≥ −0.05 m, body drift ≤ 0.5 m, render anchor ≤ 0.02 m, no Hips/Root position tracks | keep |
| C1 · J/K/U/I/L/S answer on the **press frame** | **PARTIAL** | `_press()` polls up to 8 ticks, so a 1–2 tick lag would still pass | **REFINE** — assert the response on the very next tick |
| C1 · packed multi-row 3D crowd, all 7 Mixamo models | **EXISTS** | roster check: 22 spectators, 3 rows, 10/10 banks, all seven delivered models | keep |
| C1 · Afternoon/Sunset/Night vibrant, crisp fighter shadows | **EXISTS** | roster check: three light rigs, `light_angular_distance 0`, per-phase fill/rim/ambient | keep |
| C1 · bold large arcade fonts, Select + HUD | **EXISTS** | roster check: Bungee faces, 442×32 bars, 58 px select names, 40 px clock | keep |
| C1 · `PropLoader` slots stay **empty**, no procedural stand-ins | **EXISTS** | five slots, `is_empty()`, zero child meshes | **REFINE** — assert it from the live arena (not only the roster probe) |
| C2 · stepped 16–20 fps poses, F4 live, HUD label | **EXISTS** | `AnimationFeel.STEPPED_FPS 18`, `_drive_clip_time`, `F4` toast + legend | **REFINE** — expose `step_fps` on the model as the spec asks |
| C3 · `t_impact` measured per attack clip, cached | **EXISTS** | `_measure_impact_times` / `_measure_clip_peak`, 24 samples, band 0.36–0.62 | keep |
| C3 · coil → 1-frame whip → overshoot → settle → hold | **EXISTS** | `startup_progress` / `active_progress` / `recovery_progress`, `+4°` ramp | keep |
| C3 · coil depth scaled by **move weight** (visual only) | **MISSING** | coil always ends at 0.35, light and heavy alike | **BUILD** |
| C3 · curve only remaps clip time, never moves ACTIVE | **EXISTS** | `_attack_clip_progress` reads `state_frame`; no state is written | keep |
| C3 · **arc enforcement** (curved limb path, lateral overshoot bias) | **MISSING** | no lateral component anywhere in the swing | **BUILD** |
| C3 · **1-frame skinned limb smear** on the whip (bone scale) | **MISSING** | no bone scaling | **BUILD** |
| C4 · `SkeletonModifier3D`, cached bone IDs | **EXISTS** | `FightBodyModifier3D`, 8 bones cached at bind, `apply_now()` | keep |
| C4 · runs after the curve, before foot pinning | **EXISTS** | `_process`: drive → lock → compensate → rig → feel → pin → clamp | keep |
| C4 · KOF-Vanessa shoulder/spine counter-twist | **EXISTS** | `engage_twist` on Spine1/Spine2/shoulders | keep |
| C4 · subtle limb clearance from the torso | **EXISTS** | `negative_space` on arms + shoulders | keep |
| C4 · camera-facing **chest**/eye-line cheat at the strike pose | **PARTIAL** | neck + head only; the chest never turns | **BUILD** the chest part |
| C4 · cap total influence, facing stays within 5° | **MISSING** | no explicit cap; only the outcome was asserted | **BUILD** the cap + assertion |

### COMMIT 1 — Live-match integrity (tests tightened, no combat change)

`tools/live_match_check.gd` grew **123 → 167 checks** (44 new) and stays **0 FAIL**. Nothing in
`BaseFighter.gd`, the frame data or the F4 feel layer needed fixing: the extra checks confirmed the
behaviour instead of exposing a defect, with one measurement corrected (below).

- **(d) Press-frame response.** The old `_press()` polls up to 8 ticks, so a 1–2 tick lag would have
  passed. The new check presses the real InputMap action, gives the fighter **exactly one** physics
  tick in which the press is already visible (frame A begins with the key down; the state is read
  once frame A has finished), and requires the state change by the end of that tick. Verified for
  J / K / L / I / U and the held S guard, on all three fighters: every one transitions on the press
  frame — `ATTACK_STARTUP` (or `GRAB`) on the same tick the key goes down, guard up on the same tick.
  This also re-validates the hitstop press latch from the earlier fix from the outside.
- **(e) Presentation contract, measured on the live `TestArena.tscn`:**
  - five `PropLoader` slots, **all empty**, **zero** child `MeshInstance3D` — no procedural stand-in
    anywhere. The yard's three environment slots (`jamaican_speaker.glb`, `rasta_speaker.glb`,
    `dj_booth.glb`) plus one wireless-mic slot per adult fighter.
  - **Correction to an earlier assumption, not a bug:** a Feedback-vs-L!ckshot match carries five
    slots but only *four distinct* files, because L!kkle Moore's `mic_stand.glb` slot only exists when
    he is in the match. The check now asserts the three environment slots by name, both adult
    wireless-mic slots, and then spawns a **L!kkle Moore vs Feedback** arena to prove his
    `mic_stand.glb` slot is present and equally empty. Asserting a fixed five-name set against one
    match would have been a false failure.
  - **22** spectators (18–24 band) drawn from **all seven** delivered Mixamo crowd models.
  - **Three distinct light rigs**, sun / fill / rim energies `1.90/0.26/0.80`, `1.55/0.38/1.35`,
    `0.10/0.46/1.60`, each keeping `shadow_enabled` with `light_angular_distance ≤ 0.001` — the crisp
    directional fighter shadow the owner asked for never disappears.
- Facing stays **94/94**, roster **425/425**, feel audit **142/142** on the same commit.

### COMMIT 2 — Stepped arcade pose quantization (`step_fps` export)

The stepping itself already existed at `7d4adbb`; this commit gives it the export the spec asks for
and pins the re-grid behaviour with tests. **Presentation only** — no combat value, hitbox or tick
count changed.

- `FighterModel3D` gains **`@export_range(16, 20, 1) var step_fps := 18.0`** (default
  `AnimationFeel.STEPPED_FPS`). `_drive_clip_time()` now derives the pose lattice from
  `AnimationFeel.step_count(anim.length, step_fps)`, so a designer can re-grid one body from the
  inspector inside the owner's 16–20 band without touching code. `feel_snapshot()` reports it.
- The world root, the `CharacterBody2D`, the camera and every collision stay on the smooth 60 fps
  path; only the **sampled skeleton pose** is quantized. Idle, walk and jump never step — the gate is
  still the combat states (startup/active/recovery, hitstun/blockstun, taunt).
- `F4` still flips both bodies through the shared `AnimationFeel.stepped_arcade` and flashes the HUD
  label; the default is ON. `set_stepped_arcade()` is now documented as the *shared* switch, because
  writing it also updates the static default.

**Defect found by the new check (test-only, no player impact).** The audit's F4 A/B used
`set_stepped_arcade(false)` and then "restored" `AnimationFeel.stepped_arcade` — but the OFF call had
already flipped that static, so the restore was a no-op, quantisation stayed off for the rest of the
run, and the new 16 fps lattice check failed on all three fighters with **unquantized** times. The
A/B now sets the **per-instance** `stepped_arcade` field and restores from the static. The 16 fps
checks pass: lattice 36 / 21 / 52 steps for the three light clips, **7–10 of 10** frames off the
18 fps grid, proving the export really drives the grid.

Suites on this commit: feel audit **151** (was 142), facing **94**, live match **167**, roster **425**
— all 0 FAIL.

### COMMIT 3 — Non-linear attack curve: weight-scaled coil, arc enforcement, 1-frame smear

Three refinements to the existing curve. **The curve still only remaps clip time**: `ACTIVE` starts and
ends on the combat ticks exactly as before, `_attack_clip_progress()` reads `state_frame` and writes
nothing, and no damage/startup/active/recovery value moved.

- **Coil depth scales with the move's visual weight.** `AnimationFeel.move_weight(damage)` (0.35–1.0,
  clamped) and `coil_end(weight)` lerp the anticipation from **0.42 (a jab)** to **0.30 (a full-weight
  heavy)**, and `startup_progress` / `active_progress` take that coil value. Measured on the real
  bodies: jab **0.356**, upper box **0.300** (Feedback) / **0.364 → 0.300** (L!ckshot). Reading
  `damage` is a read-only presentation input — the value belongs to `FighterRoster` and is never
  written back. `last_attack_weight` / `last_coil_end` expose it for the audit and the HUD.
- **Arc enforcement.** `AnimationFeel.arc_bias(frame, weight)` returns the signed lateral bias of the
  swing — **0.210 rad on the whip frame at full weight** — from `ARC_SWING 0.16` plus a
  `ARC_LATERAL_OVERSHOOT 0.05` push past the target on the whip frames, ramped `1.00 / 0.55 / 0.20 / 0`
  across the settle and scaled by the facing sign. `FightBodyModifier3D` applies it as a yaw on the
  striking shoulder, a smaller yaw on the upper arm and a backward rotation on the forearm, so the
  limb **traces an arc** instead of translating along a straight line to the target — and the contact
  frame leans a hair beyond its own arc. The audit asserts ≥2 bones actually rotate.
- **One-frame skinned limb smear.** On `ACTIVE` frame 1 only, the striking upper arm and forearm get a
  **volume-preserving bone stretch** (`smear_scale(1.0)` = `(0.937, 1.140, 0.937)`), and the very next
  applied frame restores `Vector3.ONE`. Bone scale only: nothing is re-skinned, re-exported or turned
  into extra geometry, and the smear never touches the hips. `_clear_smear()` runs at the top of every
  applied frame with two cached indices, so the restore cannot be missed even if the state changes
  mid-frame — no per-frame arrays, no allocation.

**Finding while asserting it:** the hips carry a legitimate non-unit pose scale on the Tripo uploads
(their 0.01 unit scale), so "the hips scale is 1" was the wrong contract and failed on two of three
fighters. The check now measures that the layer **does not change** the hips scale.

Suites: feel audit **172** (was 151), facing **94**, live match **167**, roster **425** — all 0 FAIL.

### COMMIT 4 — Whole-body engagement: chest cheat, influence cap, ordering contract

The counter-twist, the negative space and the explicit `SkeletonModifier3D` drive already existed;
this commit adds the parts the spec was missing and makes the ordering a property of the scene rather
than a comment.

- **Camera-facing chest cheat.** `AnimationFeel.CHEST_CHEAT = 0.075` rad (**4.3°**, measured on all
  three bodies) turns `Spine2` out of pure profile — full at the strike pose, a third of it in a
  neutral stance — on top of the existing neck/head eye-line. It is an **absolute** yaw, never
  facing-signed: the camera does not move when the fighter turns, so the chest always opens toward
  it. This is what keeps the contact silhouette readable at phone size instead of collapsing to a
  line.
- **Total influence cap.** The layer is a garnish on a baked take, not a second animation, so it now
  budgets its yaw. **`MAX_BONE_YAW = 0.30` rad per bone, cumulative across every system in the frame**
  (two systems writing the same spine cannot add up past 17°), and **`INFLUENCE_CAP = 1.20` rad per
  frame**. `_yaw_budget` is a `PackedFloat32Array` resized once at bind and refilled per frame — no
  allocation, no dictionary. Measured: a deliberately absurd request (2.0 rad chest + 2.0 rad twist)
  is clipped to **17.2°** on the spine and **0.60 rad** total; the *real* maximum strike stack — twist,
  negative space, eye-line, chest, overshoot, arc, tension and a counter recoil all at once — spends
  **0.94 rad**, so the cap never bites on legitimate work.
- **Ordering is structural.** The modifier is a child of the fighter's `Skeleton3D` with
  `active = false`, driven by `FighterModel3D._process` at priority 100 between `_drive_clip_time()`
  (the curve) and `_pin_feet_to_ground()`. The audit asserts parent + `active` so a future change
  cannot let the skeleton invoke it at an unknown point in the frame.
- **Facing re-verified:** `facing_audit` **94/94**, plus the audit's own ±5° check with every system at
  maximum influence.

Suites: feel audit **190** (was 172), facing **94**, live match **167**, roster **425** — all 0 FAIL.
Real `TestArena.tscn` booted 240 frames headless with no script error.

### PART 1 summary

| Commit | Hash | Content | Suites |
| --- | --- | --- | --- |
| 0 | `93cfc02` | Audit table + baselines (docs only) | 425 / 123 / 94 / 142 |
| 1 | `65f514d` | Press-frame + live-arena presentation contract tests (123 → 167) | 425 / 167 / 94 / 142 |
| 2 | `a2a8b1b` | `step_fps` export, 16 fps re-grid proven (142 → 151) | 425 / 167 / 94 / 151 |
| 3 | `1b1ea3d` | Weight-scaled coil, arc enforcement, 1-frame limb smear (151 → 172) | 425 / 167 / 94 / 172 |
| 4 | *(this)* | Chest cheat, influence cap, ordering contract (172 → 190) | 425 / 167 / 94 / 190 |

**`/docs` rebuilt** with the pinned Godot 4.5 toolchain after commit 4, so the playable build is this
source revision: `index.pck` **68,673,716 B**, `index.wasm` 38,057,390 B, `index.js` 305,185 B,
`index.html` 5,449 B. The old `.pck` was deleted first because the 4.3 GB disk was at 98 %, and the
engine download in `/tmp` was removed after the export.

Everything above is **presentation only**. `BaseFighter.gd` (`d69c8d85…f675`) and `FighterRoster.gd`
(`25b9d821…adb`) are byte-identical at every commit — `ANIM_OFFSET`, all frame data, hitboxes, the
132 BPM beat clock, the Crowd Hype rules and the 31 Patois entries are untouched, and the feel audit
re-hashes both files on every run. Zero programmer art was added; the five `PropLoader` slots are
still empty and still warn.

**Not verified:** no GPU, display or audio device in this environment, so nothing was **seen**: the
stepped read, the whip/arc/smear as they feel, the deep coil on a heavy, the chest opening up, the
crowd at 22 bodies and the three light rigs are all numbers, bone transforms and state assertions.
60 FPS on a Chromebook / iPhone Safari is unmeasured (the additions are a handful of quaternion
writes, two bone-scale writes on one frame and one `PackedFloat32Array.fill` per frame — no
allocations, no lookups, no new geometry).

## 2026-11-24 — PART 2 of 2: the Stefan Iverson overhaul, commits 5–8 (hitstop, hit-react, extras, audit)

Branch `feature/3d-cel-shaded`, Godot **4.5.stable.official (876b29033)** headless. Five commits
continue the numbered chain started by PART 1 (`93cfc02`, `65f514d`, `a2a8b1b`, `1b1ea3d`, `0b6a2f3`).
Every change is **presentation only**: `BaseFighter.gd` and `FighterRoster.gd` are byte-identical to
PART 1 — `ANIM_OFFSET`, every startup/active/recovery/damage/hitbox value, the 132 BPM beat clock,
the Crowd Hype rules and all 31 Patois entries are untouched, and the feel audit re-hashes both files
on every run. Zero programmer art.

| # | Commit | What it adds | Roster / live / facing / feel |
| --- | --- | --- | --- |
| 5 | `fac96af` | Hitstop: volume-locked `SquashPivot`, spring camera punch | 425 / 167 / 94 / 195 |
| 6 | `78ee12a` | Direction-aware hit react, foot pinning guard | 425 / 167 / 94 / 195 |
| 7 | `77331f8` | Beat accent, moving-hold idle, variable stepping | 425 / 167 / 94 / 195 |
| 8 | `d926341` | Audit extension + the four defects it caught | 425 / 167 / 94 / **335** |

### Commit 5 — hitstop

- **Volume-locked pop.** `AnimationFeel.squash_volume()` / `volume_preserve()` and the presets
  `SQUASH_POP = (1.06, 0.89, 1.06)`, `SQUASH_STRETCH = (1.06, 1.02, 0.925)`,
  `SQUASH_LANDING = (1.06, 0.89, 1.06)`. A linear lerp between two unit-product triples drifts, so
  every frame the spring writes is passed through `volume_preserve()`; measured drift over the whole
  pop is under `SQUASH_VOLUME_TOLERANCE` (2 %) on all three fighters.
- **Props isolated.** See commit 8 below — the first version was a local counter-scale and it sheared
  the mic, so the final form pins the attachment's world basis.
- **One-frame hit flash.** A rising-edge latch in presentation only (`_flash_lit`), so
  `BaseFighter.gd` stays untouched.
- **Camera punch.** `AnimationFeel.spring_scalar_step()` + `Arena3D.hitstop_punch(stop_frames,
  strength)`; `fov = CAMERA_FOV - _kick * CAMERA_PUNCH_FOV_DEG`, `v_offset = -_kick *
  CAMERA_PUNCH_OFFSET_M`, driven from `TestArena._on_strike_resolved`. The combat hit-stop itself is
  unchanged (4 frames light, 6 heavy).

### Commit 6 — direction-aware hit react

`AnimationFeel.hit_height_weight()` reads the attacking move's own `hitbox_pos.y` (tump 0.00, jab
0.75, strong/upper 1.00) and `recoil_pitch()` / `recoil_head_yaw()` pitch the chain accordingly:
high shots throw the neck and head, low shots fold the spine. `hit_clip_progress(p, extreme)` snaps to
the measured rearward extreme. `_pin_feet_to_ground()` is skipped in every airborne state and in a
rising HITSTUN, so a launch is never pulled back down.

Measured recoil extremes: `_measure_recoil_extreme()` finds one only where a real reaction take exists
(roles `hit`/`stun`/`stumble`). Feedback and L!ckshot ship none, so they fall back to
`HIT_SNAP = 0.30`; L!kkle Moore measures **0.261**. Recorded as a limitation, not hidden.

### Commit 7 — the mentor extras, each behind its own export var

`beat_accent`, `moving_hold_idle`, `variable_stepping` and `step_fps_idle` are `@export` booleans on
`FighterModel3D` (not the **F4** key, which keeps its established meaning as the shared stepped-arcade
switch).

- **Beat accent.** `overshoot_lean_accented(t, on_beat)` adds overshoot up to `BEAT_OVERSHOOT_MAX_DEG`
  and `settle_frames_for(true)` holds one settle frame longer; the flag comes from the input's own
  judgement (`fighter._input_beat.on_beat`), so the accent can never disagree with the HUD.
- **Moving-hold idle.** Weight shift (`idle_sway`), hip roll (`idle_roll`), breathing and a beat dip
  (`idle_breath`, `idle_beat_dip`), all on the pose pivot — the root, facing pivot and collision body
  never move.
- **Variable stepping.** Idle/walk/crouch run on their own slower lattice (`idle_step_count()` at
  `step_fps_idle = 12`); `hold_every(holding, variable)` repeats each grid cell for `HOLD_EVERY = 2`
  frames while the impact is held. **Changed in commit 8:** the hold now also covers the first
  `RECOVERY_HOLD_FRAMES = 3` frames of recovery — in the 3–4-frame active window the settle had
  already saturated, so the hold was invisible before this.

### Commit 8 — the audit, and the four defects it caught

`tools/animation_feel_audit.gd` grew from 190 to **335** checks: frame-data baseline per fighter
(`FRAME_BASELINE`), root motion never quantised, hand reach at `t_impact`, hold + hitstop, volume and
prop isolation, airborne pinning, the three extras, a primitive-mesh scan of the character scripts and
the built scenes, and an allocation run. It found real bugs, all fixed in the layer:

1. **`t_impact` was often the clamp floor.** The peak walk ran during `bind()`, before the
   `AnimationPlayer` had bound its tracks, so every sample read the rest pose and the walk fell back
   to `IMPACT_MIN`. It also took the clip-wide maximum over hands **and feet**, so a walk step could
   win. It is now the striking hand's world-space distance from the pelvis, walked over the legal
   contact window only, measured against a reset rest pose, and re-measured once two frames have been
   processed. A wind-up can carry the hand further from the pelvis than the punch does, so taking the
   clip-wide maximum and clamping it to the window edge placed contact on a *less* extended pose than
   the one available inside the window.
2. **The mic was sheared by the pop.** The pop is applied above the rotating hand, so a local
   counter-scale still left up to 15 % shear on the long axis. `_isolate_props()` now rebuilds each
   attachment's world basis from the hand's orthonormalised rotation times its rest basis.
3. **The hold was invisible** (see commit 7 above).
4. **The primitive scan matched prose** — the comments recording what was deleted. It now looks for
   constructions (`BoxMesh.new(`, sub-resources in the scenes).

Allocation: the feel layer is held to **zero** objects and zero nodes over 600 simulated frames
(measured 1645 → 1645 objects, 41 → 41 nodes). The live arena is held to a flat scene graph and a flat
resource table; its standing **object** count carries a known background drip of about one object per
second from the stage/UI subsystems (measured at frames 98, 158, 218, 278 … with audio, beat,
Arena3D and both fighters already disabled), which is recorded here rather than claimed as zero.

**Checks actually run** (pinned 4.5 toolchain, headless):

```bash
godot --headless --path godot --import
godot --headless --path godot --script res://tools/headless_roster_check.gd   # 425 PASS / 0 FAIL
godot --headless --path godot --script res://tools/live_match_check.gd        # 167 PASS / 0 FAIL
godot --headless --path godot --script res://tools/facing_audit.gd            # 94 PASS / 0 FAIL
godot --headless --path godot --script res://tools/animation_feel_audit.gd    # 335 PASS / 0 FAIL
godot --headless --path godot --export-release "Web" ../docs/index.html
```

`/docs` rebuilt from this revision: `index.pck` **68,703,204 B** (68,673,716 before), `index.wasm`
38,057,390 B, `index.js` 305,185 B, `index.html` 5,449 B. Disk after cleanup **125 MB free (98 % used)**;
the 4.5 engine binary, the Web template archive and the fetch script were deleted from `/tmp`.

**Not verified — no GPU, display or audio device.** Nothing was **seen**: the volume-locked pop, the
spring camera punch, the one-frame flash, the height-aimed recoil, the beat accent, the waiting sway
and the longer hold are bone transforms, spring values and state assertions, not looks. The
`t_impact` retune in particular changes where the whip lands in every attack clip and has only been
checked as a number (hand extension at the contact frame), never as motion. Feedback's and Lickshot's
recoil extremes are still the `0.30` fallback because their uploads contain no reaction take. The
`HIT_SNAP`, `RECOVERY_HOLD_FRAMES`, camera-punch and beat-accent values are hand-set defaults for the
owner's playtest.

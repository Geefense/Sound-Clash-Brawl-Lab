# Screen-Recording Review — Movement, Graphics, Crowd (2026-11-16)

Status: **analysis only. No game file, art asset, or runtime behaviour was changed.**
Author: Freebuff. Owner and final creative approver: Garfield Connell.
Scope: three screen recordings uploaded to the repository root, reviewed against `AGENTS.md`, the
TypeScript prototype on `main`, and the Sound Clash Sand stage on `stage/sound-clash-sand`.

---

## 0. Which files these are (and what could not be proven)

The three requested filenames are **not present** in the repository under those names, and no
`references/` folder existed before this document. The uploads landed at the root as three
UUID-named **QuickTime `.mov`** files (H.264 video + AAC audio, 720 × 1558 portrait, ~30 fps),
delivered in the `Add files via upload` commit `596ae3a` on `main`.

| Requested name | File actually in repo | Duration | Video | Content | Confidence |
| --- | --- | --- | --- | --- | --- |
| `ScreenRecording_11-15-2026 17-34-45_1.mp4` | `BC9199CE-A482-4995-9ECB-5B4FD0076CE0.mov` | 6.43 s | 720 × 1558, ~30 fps, 193 frames | Live-action Jamaican yard brawl with a real, close-standing crowd | **High** — status-bar clock reads **5:35** (17:35 local), the only evening-time recording of the three |
| `ScreenRecording_11-15-2026 23-25-15_1.mp4` | `6B29EBF9-103D-4129-B77E-290897B4FABA.mov` **or** `7CEDC855-2C5B-4ADB-A042-F5231774C436.mov` | 13.30 s / 24.30 s | 720 × 1558, ~30 fps, 399 / 729 frames | Two-dev reel: a *Street Fighter II* UE5-style recreation | **Medium** — see below |
| `ScreenRecording_11-15-2026 23-26-04_1.mp4` | The other of the two above | as above | as above | Two-dev reel: a *Fatal Fury / King of Fighters* UE5-style recreation, plus a second reel of a boxing/brawler stage labelled **“STREET CHOP”** | **Medium** — see below |

**What is certain:** the evening clip is the live-action fight; the two night clips are the two
fighting-game reels. Both night recordings show an identical status bar (50 %, Wi-Fi) from the same
session, and no clock is visible in any frame I sampled (the iOS screen-recording pill occupies that
area), so I **cannot** prove which of the two night files is `23-25-15` and which is `23-26-04`. The file *durations* (13.3 s vs 24.3 s) and the
49-second gap between the two timestamps are consistent with either order. This label ambiguity
does not affect any observation below — I refer to them as **“SF II reel”** and **“Fatal Fury reel”**.

### Source and resolution limitations (affects timing claims)

1. These are **phone screen recordings of an Instagram reel**, not direct captures. The game image
   occupies roughly **660 × 456 px** of the 720 × 1558 frame; everything below is read from that
   ~0.3 MP window.
2. The recordings play **reels cut as highlight montages**: individual exchanges are spliced a few
   frames apart, and the health bar and round timer are re-set between shots (in one 18-frame strip
   the opponent’s health runs 82 → 68 → 64 → 43 → **65** → 51). Consequence: **frame-accurate
   startup / active / recovery durations cannot be certified from this footage.** What *is* usable
   is pose order, silhouette, relative duration of a beat, and the visual language of impact.
3. Capture is ~30 fps (average 29.85 on the night clips, variable) of a 60 fps game, then
   re-encoded to a reel. One captured frame ≈ 33 ms of game time at best.
4. The live-action clip is a **6.4 s window** into a longer scene (its in-app timecode runs 00:08 →
   00:12 during the recording). It reads as a staged film/television scene, not a phone-filmed fight.
5. I inspected stills and frame sequences, **not** the audio. No beat/BPM claim is made about the
   reel music.

### Files in this folder (moved here 2026-11-16)

The three recordings were relocated out of the repository root and renamed to their original capture
names, byte-identical to the root blobs from commit `596ae3a`:

| File | Length | Content |
| --- | --- | --- |
| `ScreenRecording_11-15-2026-17-34-45_1.mov` | 6.43 s | live-action Jamaican yard brawl with a real crowd |
| `ScreenRecording_11-15-2026-23-25-15_1.mov` | 13.30 s | Street Fighter II UE5-style reel |
| `ScreenRecording_11-15-2026-23-26-04_1.mov` | 24.30 s | Fatal Fury / KoF-style reel, then a boxing stage |
| `frames/*.jpg` | — | five evidence stills referenced below |
| `CROWD-AND-MOVEMENT-REVIEW-2026-11-16.md` | — | this document |

They sit outside `/godot` and `/docs`, so the Web export never packs them: `docs/index.pck` is
10,648,048 B (10.16 MiB) after the 2026-11-16 build.

Method: `ffmpeg` (installed to `/tmp` only, not added to the repo) → frame extraction at 1–15 fps,
2×–3× lanczos upscales for the small game window, contact sheets, and tight crops of the crowd band.
Evidence frames are in `frames/` beside this file.

---

## 1. Fighting movement

### What the footage actually shows

**A. The 18-frame continuous strip, SF II reel, t ≈ 5.00 – 6.20 s** (`frames/01-…jpg`, 6 × 3 grid,
left-to-right, ~67 ms per cell). Ryu’s fireball → a high kick → Ken folding forward.

| Beat | Frames | What is visible |
| --- | --- | --- |
| Coil | 2–3 | Pelvis drops, both hands draw to the hip, front knee lifts, weight fully on the rear leg. Reads as a **closed** silhouette — arms overlap the torso. |
| Release | 4 | Both palms fire forward; body squares to camera; the fireball spawns *at the hands*, so the effect and the pose share one frame. Silhouette flips to **open** (negative space under the arms). |
| Extension | 5–15 | The kick sweeps knee → shin → head height over roughly **10 frames (~330 ms)**. The **support foot never changes screen position**; the whole body rotates around the planted hip. The support heel lifts at peak. Arms fling back as counterweight. |
| Contact overlap | 15–16 | The defender begins folding **1–2 frames (~33–66 ms) before** the foot reaches his head. The reaction is authored *ahead* of the visual contact so the read survives at speed. |
| Recovery | 17–18 | Leg retracts along a shorter path than it extended; the torso is already rotated back toward guard before the foot lands. |

**B. Boxing/brawler reel, t ≈ 16.5 – 20 s** (`frames/05-…jpg`, 3 × 3 grid). Two exchanges and a
knockdown.

- **Weight transfer:** wide flat stance, rear heel permanently lifted; the rear hand loads at the hip
  while the front shoulder rolls forward — a windup held for about 2 frames before firing.
- **Body rotation:** ~30–40° of hip/shoulder rotation through a straight punch, head staying level.
- **Impact:** a bright spark burst *plus* a white rim flash on the struck torso *plus* a spray of
  sweat droplets thrown opposite the punch vector. Three separate signals on one frame.
- **Recoil:** head snaps back and away; the body-shot response is a fold at the waist with one knee
  buckling — the same read our `compression` curve is trying to make.
- **Recovery:** retraction is as long as extension; the attacker returns to guard, not to neutral.
  The victim recovers with a stumble-back step, not a slide.

### Translation to Feedback — presentation only

| Observation | Our current behaviour | Practical adjustment (no art regeneration) |
| --- | --- | --- |
| Support foot is planted; hips rotate around it | `GameScene.drawFighter()` computes both legs from `hipY` to `baseY` with a `legKick` sine offset (`GameScene.ts` ≈ 385–395), so feet translate with the body | Add a per-leg *planted anchor*: while `action` is an attack, hold the support shoe’s x and let the hip move. ~15 lines inside `drawFighter`, no sim change. Highest visual return per line in this whole review. |
| Reaction leads contact by 1–2 frames | `getHitReactionPose()` starts at `age 0` on the same tick as the hit (`SimulationEngine.ts` `IMPACT_FREEZE_TICKS = 9`) | `visualReactions.ts` is explicitly presentation-only and may legally run the reaction from `age + 2`. Test at 0/1/2 ticks; 2 is the reference’s value. |
| Attacker holds follow-through; recovery ≈ extension | `12_backhand_windup` → `13_box_palm` → `14_followthrough` exist as *illustrations*, not timed clips; the procedural renderer snaps back to idle | Define an explicit hold window in the move data (startup/active/recovery already exist in `combatRules.ts`); keep total attack length unchanged and spend the hold inside existing recovery. |
| Knockdown ≈ 0.6–0.9 s with a bounce and settle | `KNOCKDOWN_TICKS = 36` (600 ms) + 7-tick rebound in `getKnockdownPose()` | **Already aligned.** No change recommended. |
| Impact is sold by 3 simultaneous signals (spark, rim flash, droplets) | We have spark (`count 8/15/25`) + camera shake + a hit-flash tint | Adding one cheap third signal — a 2-frame white rim on the struck fighter — would close the gap. Purely local to `drawFighter`. |

**Keep in mind:** the reference characters are lean/stylised 3D bodies. Feedback is a slim 2D
figure with a bucket hat and a mic cable; the *timing and rotation principles* transfer, the
*volume and limb length* do not. Do not re-draw approved Feedback poses to imitate these silhouettes.

---

## 2. Graphics — scale, silhouette, depth, separation

### What the footage shows

- **Scale:** fighters fill ~55–65 % of the frame height; the camera holds both plus roughly one body
  width of ground outside them; they never leave frame even when the camera orbits.
- **Silhouette grammar:** *closed* on startup (limbs overlap the torso), *open* at contact (limb
  extended, negative space under/inside the arm), *closed again* on recovery. That closed→open→closed
  rhythm is what makes an attack readable at 1/12 s.
- **Depth is built from 4–6 discrete planes**, each losing contrast and saturation with distance:
  1. foreground occluder — grass fringe over the fighters’ shins, a pier edge, a ring apron, or a
     spectator cropped by the frame edge;
  2. the fight plane, keylit and highest contrast;
  3. a midground crowd or boat/pier element, hazed;
  4. far background (city, mountains, ocean), strongly desaturated;
  5. sky + vignette.
- **Separation:** warm key light from one side, cool rim from behind, and a **contact shadow** under
  each fighter that anchors them to the floor. Dust and haze drift through the midground, which
  doubles as motion in an otherwise static background.

### Our current state (`main`, `GameScene.drawArena()` 124–172)

Three planes only: skyline + speaker stacks, the stage platform, and the floor. The 28 audience
figures (lines 155–163) are one repeated stamp — a 34 px head circle plus a 44 × 73 px rounded body,
all in a single flat `0x172d32`, with only a 17/19/21 px head-radius and a 44 px y-jitter for
variation — and the stage platform drawn at y 538 crops them to a 60 px band, so only heads and
shoulders show. There is no foreground occluder, no haze and no rim light on the fighters.
`drawArena()` is called once from `create()`, so **the crowd never moves at all**.

Two things are already right, and worth keeping: the band is exactly the reference’s “waist-deep
crowd” band (heads sit 68–96 px above `FLOOR = 574`, i.e. about chest height on a ~162 px fighter),
and it is 3 rows deep.

### Practical adjustments

| # | Change | Where | Cost |
| --- | --- | --- | --- |
| G1 | Push the crowd band back: drop it to ~0.72 alpha and tint it toward the stage’s cool blue, and add a 1–2 px haze line above it | `GameScene.drawArena()` | ~15 min |
| G2 | Warm 1-px rim on each fighter’s forward edge | `drawFighter()` | ~30 min, no art |
| G3 | One foreground occluder silhouette (a shoulder-and-hat cropped at the bottom corner) | new 1-frame sprite | 1 asset, biggest perceived depth gain |
| G4 | Attack silhouette pass: verify each attack has a distinct closed → open → closed shape at gameplay scale | art review, no code | review time |

The **Sound Clash Sand stage** (`godot/assets/stages/sound_clash_sand_stage_1280x720.png`) already
gives planes 2, 4 and 5 for free — sand yard from y ≈ 505, floor line y = 600, speaker stacks at
(169, 411) and (1099, 425). It is missing the crowd (plane 3) and the foreground occluder (plane 1),
which is exactly where this reference points.

---

## 3. The Fatal Fury crowd

### What is actually visible (this is the heart of the request)

Evidence: `frames/02-…jpg` (t ≈ 6.0–7.9 s), `frames/03-…jpg` (t ≈ 7.4 and 8.0 s, 3× crop),
`frames/04-…jpg` (live-action crowd).

| Property | Observed |
| --- | --- |
| **Proximity** | The crowd stands **1–2 fighter-widths behind** the fight — not a grandstand, not a distant tier. On the two-shot intro (t ≈ 10.6–12.6 s) a bare-chested boy stands in the **near foreground, cropped by the frame edge**, so spectators exist *in front of* the camera as well as behind. |
| **Placement** | 3–4 overlapping rows. Near row ≈ 60 % of fighter height, far row ≈ 45 %. They form a shallow arc, not a line. All face the fighters at 3/4 to camera; **nobody poses for the viewer**. |
| **Occlusion device** | A **grass bank / vegetation fringe** hides everything below their waists, and it also crosses the fighters’ shins in the foreground. The crowd reads as a “waist-deep band”, never as full bodies. |
| **Clothing / variety** | Bare-chested men in shorts or cloth waist-wraps; beaded necklaces and armbands; headbands and a head-wrap; one woman with long dark hair; one grey-haired elder; a child; varied skin tones; one man holding a stick. Roughly half are bare-chested, but the other half are clearly dressed differently — not a uniform mass. |
| **Poses** | Both arms raised overhead; one fist raised; hands on hips; arms folded; leaning forward with hands on knees; one bent double shouting; one crouched low at the front. Each figure is in a different phase of a different action. |
| **Animation** | Continuous, small, **unsynchronised** movement — weight shifts, arm raises, sway. Motion is slower and lower-amplitude than the fighters’, which keeps the eye on the fight. Dust and haze drift across them. |
| **Atmosphere** | Backlit haze, dust from footwork, desaturated crowd values against keylit fighters. The crowd is *slightly darker* than the fight plane — value separation does the work, not blur. |
| **Crowd reaction to hits** | **I did not capture a clear per-hit or knockout crowd surge** in the sampled frames. What I can confirm is ambient sway and arm-raising, and the crowd closing in after a knockdown in the live-action clip. A per-hit surge is therefore **my suggestion, not the reference’s behaviour.** |

### What the live-action clip adds (public-showdown atmosphere)

`frames/04-…jpg` — a yard fight with maybe 15–20 men in blue coveralls standing in a horseshoe:

- Spectators are within **arm’s reach** of the fight; there is no ring, rope or barrier.
- They **step back only when the fighters rotate into them**, then close in again. That ebb is the
  single strongest “public showdown” cue in the whole set and it costs nothing to fake.
- A couple of men stand **higher** behind (in a doorway / on a step) for a better view.
- One man in a white shirt **flinches and shifts weight** on the big contact — a single, personal
  reaction, not the whole crowd moving.
- Nobody interferes, everybody comments.

---

## 4. Translating to the Jamaican sound-clash setting

The reference is a barefoot yard/beach crowd. Our venues are a sound-system yard on sand, with two
towering stacks and an open centre lane. The mapping is direct:

| Reference device | Sound Clash equivalent |
| --- | --- |
| Grass bank hiding the crowd’s legs | **A low concrete yard wall, a line of crates, cable drums, a parked speaker cabinet**, or simply the sand berm in the stage art at y ≈ 505–600. The sand stage already has the occlusion band. |
| Nearby crowd, no barrier | A **yard crowd in a horseshoe** around the lane, top row on the wall, front row leaning on it. Matches `CROWD_SCATTER` → `RHYTHM_BRAWL` in §6 of `AGENTS.md`. |
| Foreground spectator cropped at frame edge | A single big silhouette shoulder/hat in the bottom corner, plus a **towel/rag** or **lighter** raised near the camera. |
| Varied clothing | Not bare chests: **track jackets, wife-beaters, one cook in an apron, one patty vendor, a selecta in a bucket hat, an elder in a straw hat, a child on shoulders, one man in a full suit who should not be there.** Same variety principle, different wardrobe. |
| Unsynced ambient motion | **Skanking, shoulder dips, swaying, towel waving, lighter raising** — but see §5: keep it unsynchronised so it reads as a crowd, not a chorus line. |
| Crowd closing in after a knockdown | Same beat: hazard-free `DANCE_FLOOR_RETURN` flood-in, and an ebb-back when a fighter is launched into the crowd line. |
| Backlit haze + dust | Sand haze, smoke-machine drift, and the bass-driven dust puff already implied by `SpeakerPulse.gd`. |

---

## 5. Visible behaviour vs new suggestions (kept deliberately separate)

**A. Actually visible in the footage** — safe to treat as reference-backed:

- Ambient, unsynchronised sway and weight-shifting across the whole crowd.
- Individual arm raises — one arm, or both arms overhead.
- Leaning forward, hands on knees; arms folded; hands on hips.
- One figure crouched or sitting low at the front.
- Crowd ebbing back as fighters drive into them, then closing in again (live-action clip).
- Single-spectator flinch/shift on a hard contact (live-action clip).
- Waist-up occlusion behind a vegetation/prop band.
- Foreground spectator cropped by the frame edge.
- Desaturated, hazed, slightly darker crowd than the keylit fighters.

**B. New suggestions for Sound Clash Brawl** — *not* in the footage, needs your approval:

- **Skanking** as the default crowd idle (one-foot bop, shoulder dip) — cultural fit, but the
  reference crowd does not skank.
- **Towel / rag waving** and **lighter raising** (`Lighter!`) on the beat.
- **Beat-locked** group movements (arms up on the downbeat) — deliberately *partial*: 20–25 % of the
  crowd on the beat, the rest free-running, so it doesn't look like choreography.
- **Reactions to big hits / knockdowns / wins:** a 200–400 ms lean-back, a few figures surging
  forward, one person jumping, arms up on the KO, and the `CHAMPION_SOUND` rush onto the sand.
- **Selective hostility and bias** (already planned in `AGENTS.md` §7): a section of the crowd
  disliking one fighter regardless of performance.
- **Hazard-adjacent behaviour:** ducking, shielding drinks, throwing bottles/chairs/extinguishers
  (already in the roadmap, never seen in this reference).
- **Selector/MC above the crowd** (on the stack, mic in hand), pulling up the tune and drawing a
  crowd “ooooh”.
- **Wheel-and-come-again gesture** — an arm-roll from the crowd that reads as “rewind”.

---

## 6. Prioritised recommendations

Estimates are **task estimates in minimum-commitment hours**, not measured durations. Everything in
P0/P1 fits inside the **already-scheduled Weeks 3–6 block (Nov 27 – Dec 24)** which explicitly
allocates “four-stage party crowd loop” and “simple crowd/art placeholders”. Nothing here needs new
spending, and no approved Feedback artwork changes.

### P0 — do first, no new art, all inside Weeks 3–6

| # | Recommendation | Files | Est. | Notes |
| --- | --- | --- | --- | --- |
| P0-1 | **Make the existing silhouette band move.** Keep the 28 figures and the 3 depth rows; give each a phase offset and a 2-frame sway (x ±2 px, y ±3 px, shoulder tilt). One redraw path, one loop. | TS: `GameScene.ts` (`drawArena` 155–163, called from `create`); Godot: new `godot/scripts/stages/CrowdBand.gd` beside `SpeakerPulse.gd` | 2–3 h | Turns the single most static element on screen into life, with zero new assets. |
| P0-2 | **Push the crowd band back and break the repeated stamp**: alpha ~0.72 with a cool haze tint, plus 3 head sizes / 3 body widths / varied shoulder tilt so 28 figures stop reading as one stamp. | `GameScene.drawArena()` | 0.5 h | Cheapest depth win in the build. |
| P0-3 | **Crowd reaction bus.** Tap the events already emitted — `hit-reaction` (carries `kind`/`region`/`direction`), `shake` (its `intensity` already encodes blocked/heavy), `three-piece` — and drive a single crowd-intensity value: sway amplitude, one-shot arm raise, lean-back, surge on knockdown. | TS: `GameScene.handleSimulationEvents()` 253–276; Godot: `CrowdDirector.gd` listening to the same signals `SpeakerPulse` uses | 3–4 h | No simulation change; presentation only. Keeps the `AGENTS.md` rule that presentation never decides combat. |
| P0-4 | **Planted-foot pivot** for attacks (§1) + **reaction lead of 2 ticks** + **2-frame white rim on the struck fighter**. | `GameScene.drawFighter()` 356–484; `visualReactions.ts` | 3–4 h | The three changes that most close the gap to the reference’s *feel*, none of which touch approved art. |
| P0-5 | **One foreground occluder silhouette** (shoulder + bucket hat, bottom corner) | 1 new sprite | 1 h art + 0.5 h code | Sells proximity more than 20 background figures do. |

### P1 — needs a small asset kit, still before the Dec 24 gate

| # | Recommendation | Assets | Est. |
| --- | --- | --- | --- |
| P1-1 | **Crowd actor kit**: 5 poses (sway, arms-up, lean-forward, arms-folded, crouched) × 3 body types (big man, slim youth, woman with head-wrap) as **one silhouette spritesheet, single colour, alpha 0.8**, drawn at gameplay scale (head ≈ 34 px, matching the current 17–21 px radius + body block) | 1 atlas (~15 figures), Spriterrific can produce it | 4–6 h art prep + 2 h wiring |
| P1-2 | **Crowd boundary for the sand venue**: low yard wall / crate row / cable drums, drawn as one strip layer between the crowd and the floor line at y ≈ 600 | 1 strip asset | 2–3 h |
| P1-3 | **Ambient action set**: skank bob, towel wave, lighter raise as 2-frame loops, applied to 20–25 % of figures | included in the P1-1 atlas | 2 h |
| P1-4 | **Reaction set**: lean-back, single jump, arms-up-on-KO, slump | 4 short loops | 3 h |

### P2 — later, or drop if the schedule tightens

- Knockdown surge + `DANCE_FLOOR_RETURN` flood-in and the post-match crowd rush on the sand.
- Selector/MC figure on the stack; `CHAMPION_SOUND` callout choreography.
- Animated haze/dust band and a beat-driven crowd "breath" tied to `BeatService`.
- Crowd stepping *around* a fighter launched into the line (live-action's ebb, fully implemented).
- Foreground crowd member reacting individually (the white-shirt flinch).

---

## 7. What can use existing artwork vs what needs new assets

**Can be reused as-is**

- The **Sound Clash Sand stage** PNG (`godot/assets/stages/sound_clash_sand_stage_1280x720.png`,
  source in `art-source/stages/sound-clash-sand/`) — its open sand band (y 505–600) is a ready-made
  crowd zone, and its two stacks give the vertical framing the reference crowd sits inside.
- `SpeakerPulse.gd` and `BeatService.gd` as the beat hook for any beat-locked crowd action.
- The existing **procedural silhouette band** as the *layout and scale spec* (28 figures, 3 rows,
  head radius 17–21 px, heads ~68–96 px above `FLOOR = 574`).
- All approved Feedback art — **untouched**. Nothing in this review requires redrawing him.

**Needs new assets**

- Crowd silhouette atlas (P1-1) — **there is no crowd artwork anywhere in this repository.**
  Verified against `main`, `assets/feedback-transparent-poses`, `review/feedback-appearance-consistency`,
  `feature/sprite-pipeline` and `stage/sound-clash-sand`: no `crowd`, `audience` or `spectator`
  files exist on any of them.
- Crowd boundary strip (P1-2).
- Foreground occluder silhouette (P0-5).
- Optional: towel, lighter, and one bottle sprite if hazards reach the same slice.

---

## 8. Performance notes

- The TS prototype draws the arena **once** (a static Phaser `Graphics` object) and redraws only the
  fighters every frame. Adding crowd motion via per-frame `Graphics` redraw would move 28 figures
  into the hot path; the cheaper route is to **pre-render 3 band textures once and animate them by
  offset/scale/alpha**. I have **not measured** frame time for either approach — measure before and
  after if P0-1 is adopted.
- The Godot side is far friendlier: `CrowdBand.gd` can be one `Node2D` with a single pre-drawn
  silhouette texture, animated by vertex offset or a modulated sprite, so the crowd costs one draw
  call per depth row regardless of figure count.
- The P1-1 atlas is small: 15 figures at ~90 px tall, single colour → roughly 30–60 KB PNG.
- Do **not** give each crowd member its own `AnimatedSprite2D`; that is 28+ nodes and 28+ texture
  bindings for a 60 px band at the back of the screen.

---

## 9. Schedule fit

| Window | Existing plan | This review adds |
| --- | --- | --- |
| Nov 13–26 (Weeks 1–2) | Lock `AGENTS.md`; finish Feedback’s three-hit combo; Godot setup | Nothing. This document only. |
| Nov 27–Dec 24 (Weeks 3–6) | Party FSM, four-stage crowd loop, hazards, beat window | **P0-1…P0-5** are inside the “four-stage party crowd loop” line; **P1** fits the “simple crowd/art placeholders” allowance. |
| Dec 25–Jan 14 (Weeks 7–9) | `BaseFighter`, Fighter #2, Crowd Hype / Dubplate meters | P1-4 reaction set + wiring the crowd-intensity value into the Hype meter read-out. |
| Mar 12–Apr 1 (Weeks 18–20) | Venues | P2 items belong here, not earlier. |

Risk: P0-4 touches the *look* of every attack. If it slips, ship P0-1/2/3 first — those are isolated
from combat feel and cannot destabilise the Jan 14 core-mechanics lock.

---

## 10. What I did not verify

- **No** frame-accurate startup/active/recovery timing — the reels are montage-cut and reset their
  HUD between shots (§0).
- **No** audio analysis; no BPM or beat-sync claim about the reference music.
- **No** evidence that the Fatal Fury crowd reacts per hit or at knockout. Ambient sway and arm
  raising only. The per-hit surge, skanking, towel wave and lighter raise are **suggestions**.
- **No** measurement of frame cost for any crowd approach.
- **No** runtime, build or test run — nothing in the game was changed.
- Which of the two night recordings is which timestamped filename (§0) — the recording pill hides the
  clock and both share one status bar.

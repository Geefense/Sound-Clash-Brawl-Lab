# Sound Clash Brawl — Visual & Combat Direction: Phase 1 Audit + Phase 2 Prototype

Date: 2026-11-18
Branch: `freebuff/20c43fa8b8505024f782d2ba`
Scope: presentation only. No combat rule, hitbox, timing, damage, AI or deterministic-RNG change.

> **Update, later the same day:** the prototype in §6 is now the game's default presentation and the
> approved Feedback artwork is integrated in place of the vector fighters. Rollback levels, pose
> mapping and verification are in `FEEDBACK-ART-INTEGRATION-2026-11-18.md`. The audit, ranking and
> team-switch design here still stand; the "vector stand-in" finding is superseded.

---

## 1. Concise assessment of the current visual quality

**What the build actually is today.** The playable arena does not render the approved Feedback
pose pack. `GameScene.drawFighter` draws each fighter from Phaser `Graphics` primitives — rounded
rectangles for torso and shoes, stroked lines for limbs, circles for head and fists — coloured from
`FighterState.color / accent / skin`. The 17-pose `assets/feedback-transparent-poses` pack lives on
its own branch and is not loaded on this branch, so in-game Feedback is a vector stand-in, not the
character art. That single fact bounds how close the current presentation can get to any of the
reference games.

Working assets that are genuinely in play and worth preserving: distinct silhouettes and palettes
for the two fighters, directional hit-reaction curves (`visualReactions.ts`), a KO tumble with a
ground-impact ring, camera shake driven by simulation events, an idle bob / walk cycle, the
speaker-stack block-party backdrop, the scorebar/overlay UI, and a fixed 60 Hz simulation that the
presentation reads but never drives.

**Where it falls short against the references**

| Reference principle | Current state | Gap |
| --- | --- | --- |
| Tōkon: dimensional, lit characters with strong silhouettes | Flat single-tone fills, one flat ellipse shadow, no rim light, no core shadow, no light direction | Highest-visibility gap; the fighters read as paper cut-outs against the stage |
| Tōkon: dramatic anticipation → impact → recoil | Startup/active/recovery, hitstun and recoil curves exist; impact feedback is a small circle burst plus shake | Timing is fine; the *punctuation* is thin — no layered burst, no direction, no dust, no crowd answer |
| SF6: layered, living stages | One `Graphics` object drawn once: skyline, 2 cabinets, string lights, 28 identical silhouettes, floor bands | Static stage, no depth separation, no ambient motion, no crowd behaviour |
| Fatal Fury: crowd participation and arcade energy | 28 repeated silhouettes painted once | Crowd is scenery, not a participant |
| Signature Sound Clash comedy | Slap/tump/upper-box vocabulary, Three Piece, HIM DUN! callout, KO tumble all present | Intact; presentation just doesn't sell it yet |

**Readability is currently good** and must stay that way: the fight area is a clean band at
y≈480–575 with dark, low-contrast scenery behind it. Every improvement below is judged against that.

---

## 2. Five highest-impact improvements achievable with existing assets and engine

Ranked by visual benefit ÷ (implementation difficulty × performance cost). All five are code-only.

1. **Dimensional fighter lighting** — one warm key-light direction (the existing low sun at
   x≈1010), a translucent core shadow on the away side of the torso, a warm rim on the near edge,
   a rim arc on the head, and a jaw catch-light. Per fighter this is 5 extra draw calls.
2. **Layered impact presentation** — tight white contact core, one expanding ring, 3–4 directional
   speed lines that trail the strike, a 6-ray burst only on heavy body shots, and 0.2–0.38 s
   lifetime. Reinforces the actual collision instead of covering it.
3. **Living crowd with individual personality** — 36 spectators in three depth rows, each with its
   own phase, tempo, willingness to jump, arm style (none/one/two), and prop (phone light, cloth).
   Energy eases toward a crowd-mood value fed by hit events, so a heavy slap lifts the room.
4. **Stage depth** — atmospheric haze between rooftops and crowd, softened stage-light pools on the
   boards, near-camera foreground silhouettes under the fight line, and speaker cones that flex on
   a cosmetic bass pulse.
5. **Ground contact and debris** — layered contact shadow that tightens as a fighter leaves the
   floor, landing dust puffs, and sand kicked up by heavy body shots.

Deliberately excluded: real parallax (the camera is static, so scroll-factor parallax would only
appear during shake — not worth the complexity), any shader/blend-mode work, any crouch/pose
changes, and any change to the KO or Three Piece timing.

---

## 3. Which improvements need new artwork versus code-only

**Code-only (implemented in this prototype):** items 1–5 above. Zero new files in `public/`, zero
new textures, no changes to existing art.

**Needs new artwork (candidates, not requested or produced here):**

| Asset | Why code cannot close the gap |
| --- | --- |
| A consistent, approved Feedback pose set with *painted* light direction (rim, core shadow, bounce) | Hand-shaded sprites beat any overlay: cloth folds, hat brim occlusion and face concealment need pixels, not geometry |
| Sprite sheets with shared grid, anchors and mic/cable continuity | The existing pack is 17 illustrations on one branch, flagged for cable/handedness drift; not a clip system |
| Speaker cabinets with grille/cone material detail, and a foreground prop layer | Vector cabinets are acceptable at this distance but flat up close |
| 3–4 crowd sprite variants (standing, arms up, towel, phone) | Procedural silhouettes cannot carry fabric, posture nuance or culture-specific detail |
| Per-stage lighting plates (dusk, floodlit, indoor dance) | A second light temperature needs its own art pass |

**Blocking note carried forward from `AGENTS.md`:** mic-hand continuity and the jacket-origin cable
are still unresolved across sets. Any new pose work must respect that; nothing in this prototype
touches character appearance.

---

## 4. Expected performance implications

Measured in this cloud VM (software-rasterised Chromium, no GPU), 2.5 s window, same scene:

| Pass | Avg frame | FPS |
| --- | --- | --- |
| Classic (previous presentation) | 111 ms | 9.0 |
| Enhanced, ambient layers redrawn every frame | 145 ms | 6.9 |
| Enhanced, ambient layers throttled to 30 Hz (shipped) | 138 ms | 7.3 |

The absolute numbers are an artefact of a throttled, software-rendered VM (a nearly static scene
should not cost 111 ms anywhere). The **relative** signal is real: two full-width translucent layers
redrawn per frame cost measurable fill rate.

Mitigations already in the shipped code:

- ambient stage layers (crowd + cabinets) refresh at 30 Hz instead of per frame;
- live particles are hard-capped (12 impact bursts, 90 dust puffs), all drawn into a single
  existing `Graphics` object — no new game objects, no new textures, no render passes;
- impact bursts are short-lived (≤ 0.38 s) and sized so cost scales with hits, not with time.

Guidance: profile on the real target (Chromebook / phone) before Phase 3. If the crowd fill is the
dominant cost there, the cheap levers are fewer spectators, a narrower crowd band, or baking the
crowd to a sprite atlas.

---

## 5. Recommended implementation order

1. **Combat presentation** (done, prototype): fighter lighting, contact shadows, impact bursts,
   dust, landing puffs. Highest benefit, lowest risk, no art dependency.
2. **Stage and crowd** (done, prototype): haze, crowd personalities, cabinet flex, stage light,
   foreground depth. Verify readability first, then push spectacle.
3. **Character polish**: only after an approved, consistently lit sprite set exists — replace the
   vector stand-in with sprite rendering + the same lighting vocabulary (rim/contact/impact).
4. **Round ceremony**: intro pose beat, KO crowd surge, winner celebration — reads as cinematic but
   is camera + delay work on top of the existing timer states.
5. **Team combat**: design only, see §7. Do not start before one-on-one is locked.

---

## 6. The prototype, and how to compare / revert

Changed files:

- `src/game/presentation.ts` — new, drawing-only module (crowd, speakers, haze, stage light,
  foreground, impact bursts, dust).
- `src/game/GameScene.ts` — added four presentation `Graphics` layers, a presentation clock and
  mood value, and enhanced branches inside `drawFighter`, `drawArena` and the event handlers.

Nothing in `simulation/`, `combatRules.ts`, `visualReactions.ts`, the tests or the HUD changed.

**Toggle:** `?visuals=classic` forces the previous presentation at runtime; the same comparison is
available in code by flipping `PRESENTATION_DEFAULT` in `presentation.ts` to `'classic'`. In classic
mode the arena is drawn exactly as before — same shapes, same order, same shadow, same effects.

**Comparison frames:** `visual-prototype/final-classic-1.png`, `final-classic-2.png`,
`final-enhanced-1.png`, `final-enhanced-2.png` — the same arena at the same point of the match
opening, captured from the live dev server against the shipped code (after the 30 Hz ambient
refresh and the final stage-light tuning).

**What is verified:** typecheck clean, `pnpm run test` 53/53 pass, production build succeeds, dev
server serves the scene, both passes rendered and were inspected, and frame timing was measured in
both passes. **What is not verified:** real-device/Chromebook frame rate (the numbers above come
from a software-rendered cloud VM), the KO/round-ceremony crowd reaction (code path exists and is
cheap, but no KO was captured), long-session particle-cap behaviour, and touch input with the new
layers.

---

## 7. Future team-switching combat (design only — not implemented)

Current structure: `GameState` holds exactly `player` and `rival` `FighterState`s; `simulateTick`
updates both, resolves one contact pair per tick, and the scene binds keys to `player` and AI to
`rival`. The match layer owns rounds, KO and transitions. That is a clean 1v1 contract, and the
cheapest path to teams preserves it.

**Proposed shape**

1. `SideState = { roster: FighterState[], activeIndex: number, tagCooldown: number }` and
   `GameState.sides: [SideState, SideState]`. Keep `player`/`rival` as derived getters
   (`sides[0].roster[active]`) for one release so existing rules, tests and HUD keep working.
2. **The simulation stays two-fighter.** Only the two active `FighterState`s are stepped. Bench
   fighters are data, not bodies — no off-screen physics, no second hurtbox, no assist hitbox.
3. **Tag as a tick-level event**, not a scene action: `FighterInput.tag`, resolved inside
   `simulateTick` after timers, so a swap is deterministic and replayable. A swap sets a short
   `incoming` state (entry frames, brief invulnerability decision to be made explicitly), inherits
   position/facing/grounded, and resets the outgoing fighter's combo and buffers. Cooldown and
   "cannot tag during hitstun / KO / airborne" rules live in the same rules module.
4. **Round flow:** a round ends when a side has no runnable fighter, not when one fighter's health
   hits zero. KO presentation (impact-freeze → knockdown → announcement) stays per-fighter; the
   side-wipe check happens after the announcement, so the existing KO path and its callouts
   (`HIM DUN!`, `KO!`) survive unchanged.
5. **Presentation:** swap needs an authored entrance/exit beat (dust, crowd surge, camera nudge);
   the crowd-mood value from this prototype is already a natural trigger. Sound-clash crew identity
   belongs on `SideState` so entrances can quote crew names.
6. **Data:** move attack profiles and per-fighter tuning into per-fighter data now, so a roster is a
   list of data records rather than a code path. This is also the Godot `BaseFighter` boundary from
   the blueprint.
7. **Risks to settle before code:** separation/facing and the air-pass rule assume exactly one
   opponent body; combo/hype economy across a swap; camera framing for an entrance; whether the
   HUD shows two rosters or only the active fighter.

**Explicitly not built:** tag mechanics, assists, bench bodies, multi-active fighters, or any change
to the current one-on-one rules. The current build still runs one fighter per side.

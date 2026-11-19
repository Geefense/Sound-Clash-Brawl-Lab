# Feedback art + enhanced presentation — integrated build, November 18, 2026

Status: **INTEGRATED, awaiting hands-on play review.** This is the shipping default for the
playable game in this repository. Combat, hitboxes, timing and the deterministic simulation are
unchanged.

## 1. What is now in the main game

| Feature | Where | Notes |
| --- | --- | --- |
| Approved Feedback pose artwork | `public/assets/feedback/` + `src/game/feedbackSprite.ts` | 14 of the 17 pack poses are downloaded; the three lighter/fire poses are not drawn by this build |
| Sprite fighters (both sides) | `GameScene.drawSpriteFighter` | Manifest origin, one shared scale, mirroring rules, feet/pelvis anchoring |
| Layered contact + core shadows, rim light, jaw catch-light | `GameScene.drawFighter` (vector path), sprite flash | Vector lighting stays as the fallback when a texture is missing |
| Impact bursts, rings, directional speed lines, heavy-hit rays | `presentation.ts` | Drawn above the fighters so a hit never hides behind a sprite |
| Landing dust, sand displacement, debris chips | `presentation.ts` (`DustPuff`, `DebrisChip`) | Debris spawned on heavy landings, body shots and the KO ground burst |
| 36-person crowd with per-member tempo, jumps, arms, phone lights, towels | `presentation.ts` (`createSpectators`, `drawCrowd`) | Deterministic layout, crowd mood driven by accepted hits |
| Stage depth, haze, light pools, foreground silhouettes | `presentation.ts` | |
| Animated speaker cones on the cosmetic bass pulse | `presentation.ts` (`drawSpeakerStack`) | Cosmetic clock only — it never judges a beat |
| Camera shake, hit reactions, KO tumble, ground ring | existing `visualReactions.ts` + `GameScene` | Unchanged mechanics, now composited with the new layers |

Layer depths are explicit: background 0, speakers 1, crowd 2, stage 3, foreground 4, ground
effects and vector fallback 10, fighter sprites 11, contact effects 12, combo labels 15.

## 2. Pose mapping

The pack is a set of illustrations, not a rig. Each game state picks one picture:

| Game state | Pose | Kind |
| --- | --- | --- |
| Idle, walking | `01_idle` | Pack state |
| Block | `08_block` | Pack state |
| BOX startup / contact / recovery | `12_backhand_windup` / `13_box_palm` / `14_followthrough` | Pack state |
| Body hit taken | `16_gut_punch` | Pack state |
| Knockdown → KO | `03_c_recoil` → `04_inverted_c` → `17_seated_landing` → `02_knockout` | Pack state |
| Jab | `09_point` → `13_box_palm` → `14_followthrough` | **Fallback** |
| TUMP (heavy body) | `07_crouch` → `13_box_palm` → `14_followthrough` | **Fallback** |
| Upper Box | `07_crouch` → `13_box_palm` → `14_followthrough` | **Fallback** |
| Jump / airborne | `15_skank` | **Fallback** |
| Head hit taken | `05_dizzy_bogle` | **Fallback** |

**Missing poses, explicitly not invented:** there is no dedicated jab, TUMP body-shot, Upper Box
or neutral airborne frame in the approved pack, and no approved walk cycle (the four-key walk study
is still unapproved). Those states use the listed nearest pose. `06_rear_salute`,
`10_fire_airborne` and `11_fire_grounded` are not loaded at all because no wired mechanic uses them.

Mic hand and cable: each pose keeps its baked-in artwork and declared anatomical hand. Mirroring is
applied only when the fighter's facing disagrees with the painted facing, and never to the rear
salute or the natively left-facing gut punch, so no pose is silently flipped into the other hand.

## 3. Rollback

Three independent levels, no gameplay or artwork loss:

1. **Runtime:** `?visuals=classic` renders the pre-integration presentation (vector fighters,
   static crowd silhouettes, classic shadows/impacts) and does not download the pose pack.
2. **Code:** set `PRESENTATION_DEFAULT = 'classic'` in `src/game/presentation.ts`.
3. **Git:** tag `rollback/pre-visual-integration-2026-11-18` points at the last commit before this
   integration (`6e99519`, which contains `main`).

## 4. Verification performed

- `pnpm run typecheck` — clean.
- `pnpm run test` — 53/53 pass (combat rules, simulation, visual reactions untouched).
- `pnpm run build` — succeeds.
- Dev server served the game; captured frames in `visual-prototype/`:
  `art-idle.png`, `art-feet.png` (sole alignment on the floor line), `art-block.png`,
  `art-box.png`, `art-jab.png`, `art-ko.png` (KO body resting + BOX contact),
  `art-classic.png` (rollback pass).
- Feedback vs Feedback confirmed with the approved artwork on both sides, mirroring correctly for
  the left-facing rival.
- Ground alignment: soles sit on the stage line; the lying KO pose rests on the floor.
- Rollback pass confirmed: `?visuals=classic` renders the vector fighters and makes **0** feedback
  texture requests.

### Performance

Measured in the cloud VM's Chromium, which throttles `requestAnimationFrame` to roughly 7–9 fps, so
these are **relative** numbers, not device frame rates:

| Pass | Median frame interval | Implied fps |
| --- | --- | --- |
| Classic (vector + static crowd) | 113 ms | ~8.8 |
| Enhanced (this build) | 142 ms | ~7.0 |

The enhanced pass adds ~29 ms per **capped** frame. The new ambient layers (36 spectators and the
speaker cones) refresh at 30 Hz rather than per frame; the sprites are GPU-composited images.
Texture memory is the real mobile risk: 14 packed 1536 × 1024 RGBA poses ≈ 84 MB of GPU memory,
which is why the three unused poses are not loaded.

**Not measured:** real Chromebook or phone frame rate, thermal behaviour, and touch input while all
layers are active. These remain the main open risk for this build.

## 5. Known rough edges to judge in play

- Walking shows the idle paint; there is no approved walk cycle, so feet do not step.
- Jump uses the skank pose, anchored at the pelvis.
- The palm/windup artwork is a pose swap, not an interpolated animation — transitions between
  attack phases are cuts by design.
- Two identical Feedback models are distinguished only by the small accent triangle above the head
  and the HUD; the approved art is not tinted.
- Estimated anchors from the pack may want a few pixels of tuning once the owner has played it.

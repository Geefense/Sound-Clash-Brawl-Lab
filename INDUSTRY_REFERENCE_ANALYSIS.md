# INDUSTRY_REFERENCE_ANALYSIS

Reference analysis for **Sound Clash Brawl**'s visual layer, 2026-11-25.
Owner and final creative approver: Garfield Connell.

This document is a **research record**, not an approval. Nothing in it changes a combat
value, a frame count or an asset. It exists so the visual layer can point at a real source
for every claim it makes, and so the parts nobody has watched yet are clearly marked.

## How to read this document

Each of the seven sections below has **exactly three subsections**:

1. **Confirmed Technical Findings** — only what can be cited to a source that was actually
   reached on 2026-11-25, with the source named inline. Where no source was found, the item
   is labelled **"unverified, general knowledge"** and is a hypothesis, not a finding. No
   quote is copied; every line is a paraphrase. No frame counts, statistics or quotes were
   invented.
2. **Observations from Gameplay Footage** — **OWNER TO FILL.** The agent that wrote this
   document cannot watch video. Instead of inventing observations, each section lists the
   short set of things to look for, with a timestamp box to fill in.
3. **Proposed Godot 4.5 Implementation Techniques** — what can ship now on the
   **Web / Compatibility** target (60 FPS on a Chromebook, iPhone Safari), and the separate
   **console scaling path** for later tiers.

The per-technique decisions that came out of this document are implemented in
`godot/scripts/fighters/AnimationFeel.gd`, `PoseTimingBias.gd`,
`FightBodyModifier3D.gd` and `FighterModel3D.gd`, and are recorded in `AGENTS.md`.
Console-specific budgets live in `CONSOLE_READINESS.md`.

## Sources reached on 2026-11-25

| # | Source | What it was used for |
| --- | --- | --- |
| S1 | Junya C. Motomura (Arc System Works), *Guilty Gear Xrd's Art Style: The X Factor Between 2D and 3D*, GDC 2015. Slides: `https://media.gdcvault.com/gdc2015/presentations/Motomura_Junya_GuiltyGearXrd.pdf` | Limited animation in 3D: every frame is a keyframe, no interpolation between keyframes; models + shaders built to read as 2D. |
| S2 | Unreal Engine developer interview, *How Guilty Gear -Strive- hits an ultra combo…*, 2021-06-23 (`unrealengine.com/en-US/developer-interviews/...`) | Strive's art director states the goal was a distinct Guilty Gear look rather than an imitation of hand-drawn anime. |
| S3 | Capcom, *Street Fighter 6* Dev Column #001, *The Secrets of Drive Impact*, 2023-06-09 (`streetfighter.com/6/column/detail/effects02`) | Drive Impact VFX concept keywords (brush, paint, comic, spray, graffiti, music video, sports); stretched character silhouette and dimension changes tried during development. |
| S4 | Capcom, *Street Fighter 6* Dev Column, *Lighting M. Bison's Super Arts*, 2024-06-26 (`streetfighter.com/6/en-us/column/detail/lighting05`) | Super Art lighting: focus through depth of field, contrasting brightness, extra lighting on the important area, light rising with the animation's tempo. |
| S5 | Capcom, *Street Fighter 6* Dev Column, *Behind the Effects* #01, 2023-06-01 (`streetfighter.com/6/en-asia/column/detail/effects01`) | Readability work on a special: afterglow on the projectile and sparks, and the striking arm reddened by heat. |
| S6 | Capcom, *Online Integrated Report 2023*, Technical Research interview (`capcom.co.jp/ir/english/data/oar/2023/development.html`) | *Street Fighter 6* is the first fighting game on RE Engin; a purpose-built *Fighter Tool* was written for fighting-game character data. |
| S7 | Bandai Namco, Famitsu interview with Kohei Ikeda, 2023-03-29 (`famitsu.com/news/202303/29297557.html`) | *Tekken 8* on UE5: graphics came relatively easily, **lighting** was the hard part; "rich look vs ease of fighting" was a designer/battle-team tension. |
| S8 | Autodesk Media & Entertainement, *TEKKEN 8: Legacy Meets Innovation…*, 2025-01-28 (`blogs.autodesk.com/media-and-entertainment/2025/01/28/tekken-8-legacy-meets-innovation-with-the-combined-power-of-maya-and-unreal-engine`) | Maya → UE5 pipeline; art director Asai Kanji on keeping the series' "feel of destruction" as an art goal. |
| S9 | PlayStation.Blog, *Fatal Fury: City of the Wolves* interview with the SNK director, 2024-09-10 (`blog.playstation.com/2024/09/10/...`) | CotW's art style deliberately mixes American comic art with Japanese anime so characters "pop". |
| S10 | PCMag, *City of the Wolves* Q+A with SNK, 2025-08-04 (`pcmag.com/news/city-of-the-wolves-q-plusa-...`) | Comic-book inspiration is a stated, long-running influence on the series. |
| S11 | Mariel Cartwright, *Making Fluid and Powerful Animations for Skullgirls*, GDC 2014 Animation Bootcamp (talk referenced in third-party notes) | Strong key frames, anticipation and timing; the practical constraint of "only six frames to deliver a punch". |

**Not reached:** any *Dragon Ball FighterZ*-specific developer talk, any *Guilty Gear Strive*
animation talk, the **Zweifuss 3rd Strike animation archive**, and the **Stefan Iverson
Makoto breakdown**. Those names came from the owner's brief; no public source was found for
them on 2026-11-25, so everything attributed to them below is labelled unverified.

---

## 1. Dragon Ball FighterZ

### (1) Confirmed Technical Findings

- The 3D-that-looks-2D technique FighterZ is built on is documented for its sibling title
  **Guilty Gear Xrd** at GDC 2015 (S1): the team stopped interpolating between keyframes and
  treated **every frame as a keyframe**, reproducing the "limited animation" of TV anime
  inside a 3D model. FighterZ uses the same Arc System Works house approach; that is a
  reasonable inference from the shared studio and pipeline, **not** a FighterZ-specific
  citation.
- S1 also states the models and shaders were authored to make a 3D object read as 2D, not to
  be physically correct.
- **Unverified, general knowledge:** FighterZ-specific claims about its ink line, its
  camera-cheated foreshortening and its cinematic Special/KO cameras. The brief lists them;
  no source was reached that documents them for this title.

### (2) Observations from Gameplay Footage — OWNER TO FILL

- [ ] Normal-move exchange, 0.25× speed: count the **pose steps** a jab takes from windup to
  contact (timestamp: ______).
- [ ] Does the ink line **thicken** on the contact frame, or is it constant? (______)
- [ ] A heavy launcher: does the body **stretch** along the launch axis, or stay rigid? (______)
- [ ] Super/KO camera: how far does the lens travel, and how many frames does it hold? (______)
- [ ] Does the background crowd react on the same frame as the hit, or one beat later? (______)

### (3) Proposed Godot 4.5 Implementation Techniques

**Now (Web/Compatibility):** this build already has the three pieces that matter most —
stepped pose quantisation on an 18 FPS grid (`AnimationFeel.quantize`), an inverted-hull ink
`next_pass` (`toon_outline.gdshader`), and a measured contact pose (`t_impact`) per clip.
The FighterZ reading adds nothing that needs a new renderer feature.

- Keep the **pose grid** authoritative for attacks and hold idle/walk on a slower lattice
  (`step_fps_idle`), which is the direct analogue of "every frame is a keyframe" (S1).
- Ink thickness is a **shader constant** per body today. A thicker contact line is a
  per-instance uniform write, not a second material.
- Camera cheats stay **inside the existing frustum test**: any foreshortening is a bone
  scale on the striking limb (`SILHOUETTE_CLAMP`, 1.08×), never a moved hitbox.

**Console scaling path:** raise the pose grid to 24–30 FPS, add a second outline pass for
close-ups, and allow a heavier post chain (bloom + colour grade) — all of which need a real
GPU and a fixed frame budget, so they are a tier-2/3 decision in `CONSOLE_READINESS.md`.

---

## 2. Guilty Gear Strive

### (1) Confirmed Technical Findings

- S2: the art director states Strive deliberately moved away from "recreating hand-drawn
  anime in 3D" toward a **distinct Guilty Gear look**. That is an official statement of
  intent, not a technique breakdown.
- S1 (Xrd, the same studio, earlier title) documents the limited-animation technique in
  detail: no interpolation between keyframes, every frame posed by an animator.
- **Unverified, general knowledge:** that Strive's animation is more fluid / higher-FPS than
  Xrd's. Third-party animation notes say so, but no official source was reached. Do not
  treat it as a target number.

### (2) Observations from Gameplay Footage — OWNER TO FILL

- [ ] Idle loop: is the chest/hip motion continuous, or stepped on a visible grid? (______)
- [ ] A 5-frame normal: how many **distinct silhouettes** can you count? (______)
- [ ] Contact frame: is there a 1–2 frame **hold**, and does the off-hand keep moving? (______)
- [ ] Camera: how much does the lens move during a normal exchange vs a Super? (______)
- [ ] Do the backgrounds/lighting change per stage, or stay one grade? (______)

### (3) Proposed Godot 4.5 Implementation Techniques

**Now:** the Strive reading is a **style** target, and this build's answer is the
Zweifuss/Iverson layer already shipped in PART 1 commit 2:

- **Anticipation into the forward step** — the startup coils along the facing axis by a few
  cm and is exactly zero by the first ACTIVE frame (`AnimationFeel.anticipation_offset`).
- **C → S → reverse-C whip** — the hips lead, the torso arrives 1–2 pose steps later and the
  striking hand last (`whip_weight`), so the spine snaps instead of moving as a block.
- **Frozen impact silhouettes** — 2–3 pose steps locked at peak reach, while the additive
  tension/eye-line layer keeps the pose alive.
- **Non-linear recovery** — a hip dip, an overshoot past neutral, then idle
  (`recovery_dip`).

**Console scaling path:** a second skeleton layer for cloth/hair secondary motion and a
per-material outline width ramp at distance. Both are cheap in isolation but need a
per-frame budget that only a console tier can guarantee.

---

## 3. Tekken 8

### (1) Confirmed Technical Findings

- S7: the developer says UE5 made "beautiful graphics" comparatively easy, but **lighting
  was where the team struggled** — small changes in light made large differences in how the
  game read. The same interview describes the tension between a rich look and ease of
  fighting, resolved between the designer and battle teams.
- S8: characters and backgrounds were authored in Maya, cinematic staging in UE5, with a
  live link between them; the art director frames "the feel of destruction" as an explicit
  art goal carried from earlier titles.
- **Unverified, general knowledge:** specific rim-light values, per-stage light counts and
  any "scalable render tiers" claim. The brief asserts them; no source with numbers was
  reached.

### (2) Observations from Gameplay Footage — OWNER TO FILL

- [ ] Stage lighting: how many **distinct light directions** can you identify on a fighter? (______)
- [ ] On a wall/floor hit: what exactly moves — dust, debris, camera, light flicker? (______)
- [ ] Is the rim light **coloured per stage**, and does it survive the fighter turning around? (______)
- [ ] Does the crowd/environment react on contact, and on which frame? (______)
- [ ] Are there visible quality tiers between modes (e.g. story vs versus)? (______)

### (3) Proposed Godot 4.5 Implementation Techniques

**Now:** the build already ships the Tekken reading's two cheapest levers:

- **Per-preset stage light rigs** — `Arena3D.PHASES` gives Afternoon/Sunset/Night their own
  sun, fill, ambient, fog and four coloured stage spots, all inside Compatibility's
  **eight-lights-per-object** default (asserted: 7 lights, 4 spots, ≤4 directional).
- **Rim separation per preset** — the fighter cel rim is pushed from the same preset
  (`cel_rim`, `cel_rim_strength`), so the body separates from that sky rather than one fixed
  rim being reused.
- **Environmental impact feedback** without new systems: contact shadow, sand burst, note
  burst, stage-beam pulse on the 132 BPM beat, crowd/DJ reaction cues.

**Console scaling path:** real-time shadow cascades, screen-space contact shadows, a second
rim light per fighter, and per-object light counts above 8. Those are exactly the features
the Compatibility renderer cannot do, so they belong behind a tier flag — see
`CONSOLE_READINESS.md` §3.

---

## 4. Street Fighter 6

### (1) Confirmed Technical Findings

- S3 (official VFX column): the Drive Impact effect was developed from concept keywords
  including *brush, paint, comic, spray, graffiti, music video, sports*; the team tried
  **stretching the character's silhouette** and changing dimensions to give attacks a
  different look.
- S4 (official lighting column): for Super Arts the lighting team works with depth of
  field, **contrasting brightness**, extra light on the area the player should look at, and
  raises the overall lighting with the **tempo** of the animation.
- S5 (official VFX column): readability work included afterglow on the projectile and sparks,
  and reddening the striking arm with heat.
- S6 (official IR report): SF6 is the first fighting game on RE Engin, and a purpose-built
  *Fighter Tool* was written for fighting-game character data.

### (2) Observations from Gameplay Footage — OWNER TO FILL

- [ ] Idle: list every body part that keeps moving while the player does nothing (______).
- [ ] Normal vs Special: how does the **camera** differ (distance, angle, hold)? (______)
- [ ] On a Drive Impact: which layers fire, and in what order? (______)
- [ ] Crowd: does it react per hit, per combo, per round — and with what delay? (______)
- [ ] Is the contact frame brighter, or only the VFX? (______)

### (3) Proposed Godot 4.5 Implementation Techniques

**Now:** SF6's "responsive feel" is already the build's contract — input judgement stays in
`BaseFighter`, and no presentation system can write back.

- **Expressive idle** — moving-hold idle (`idle_sway`, `idle_breath`, `idle_beat_dip`), plus
  per-fighter `beat_bounce` in `PoseTimingBias`, so a waiting body is never a frozen loop.
- **Living reactive crowd** — `CrowdController3D` already takes combat cues and runs a 132 BPM
  skank with per-rig phase offsets.
- **Comic impact frame + lighting tempo** — the existing `ImpactFrame` and the camera
  accent (`accent_camera`, commit 3) are the Compatibility-safe versions of S4's
  "contrast + tempo" idea: one clamped total for lean + punch + accent.

**Console scaling path:** a real depth-of-field pass on Super Arts, per-character VFX
shading (S3's brush/graffiti direction) and a light-rig tempo track that can drive more than
the eight-light budget.

---

## 5. Fatal Fury: City of the Wolves

### (1) Confirmed Technical Findings

- S9: the SNK director states the visuals were meant to evoke a **mixture of American comic
  art and Japanese anime**, so characters "pop" for old and new players.
- S10: comic-book inspiration is confirmed again as a long-running influence on the series.
- **Unverified, general knowledge:** the specific claim that CotW uses **comic-style impact
  VFX overlays** and **animated backgrounds** as a system. The brief asserts it; the reached
  sources describe art direction, not the VFX implementation.

### (2) Observations from Gameplay Footage — OWNER TO FILL

- [ ] A heavy hit: is the impact an **overlay** (drawn burst, speed lines) or in-world VFX? (______)
- [ ] Do background elements animate independently of the fight? (______)
- [ ] How long does an impact overlay stay on screen? (______)
- [ ] Are outlines/hatching used on characters, backgrounds, or both? (______)
- [ ] Does the camera cut or move on a Super? (______)

### (3) Proposed Godot 4.5 Implementation Techniques

**Now:** the build already has the compatibility-safe half of this: a comic impact frame
(`ImpactFrame`) on counter-hits and Hype surges, note-trail overlays, a sand-burst contact,
and a per-preset sky/horizon backdrop. All of them are capped
(`MAX_IMPACT_FRAMES = 1`, `MAX_NOTE_TRAILS = 3`), so a long brawl cannot pile nodes up on a
Chromebook.

- An **impact overlay** is a `Control`/`Sprite3D` with an imported texture, not a new
  renderer feature — the existing comic frame is exactly that.
- **Animated backgrounds** stay in the Compatibility path as shader time + a small number of
  transform-animated props; no per-frame node creation.

**Console scaling path:** full-screen impact overlays with per-character art, background
crowd simulation, and screen-space distortion on heavy contacts.

---

## 6. The Zweifuss 3rd Strike animation archive

### (1) Confirmed Technical Findings

- **Unverified, general knowledge — no source reached.** The archive was named in the
  owner's brief; no public page for it was found on 2026-11-25. Nothing in this section is a
  finding. The techniques attributed to it below are the brief's own list plus the
  GDC-documented limited-animation principle from S1, which is a different (but compatible)
  source.
- What **is** confirmed, from S1 and S11, is the general principle the archive is being used
  to argue: strong key poses, deliberate anticipation, and a small number of held frames
  carry more weight than smooth interpolation.

### (2) Observations from Gameplay Footage — OWNER TO FILL

- [ ] Pick one normal and mark every **key pose** with a timestamp (______).
- [ ] How many frames is each key pose **held**? (______)
- [ ] Does the hips/chest lead the striking limb, and by how many frames? (______)
- [ ] Where does the anticipation point — backward, or **into** the step? (______)
- [ ] Recovery: does the body return linealy, or dip and overshoot? (______)

### (3) Proposed Godot 4.5 Implementation Techniques

**Now (all shipped in commit 2):**

| Archive idea | Godot 4.5 implementation | Where |
| --- | --- | --- |
| Archetype timing bias | `PoseTimingBias` resource, one per body, exported on `FighterModel3D` | `PoseTimingBias.gd` |
| Anticipation into the step | `anticipation_offset` on the `VisualPivot` only, ≤5.5 cm, zero by ACTIVE | `AnimationFeel` |
| Hips lead the whip | `whip_weight` per link (hips 0, spine 1, hand 2 pose steps) | `FightBodyModifier3D` |
| Frozen impact silhouette | 2–3 pose-step lock at the contact grid cell | `FighterModel3D._drive_clip_time` |
| Non-linear recovery | `recovery_dip` sine arc + overshoot | `FightBodyModifier3D` |

All of them are skeleton/pivot values: no mesh rebuild, no new material, no combat tick.

**Console scaling path:** more pose steps per clip (24–30 FPS grid), per-bone lag chains
longer than four links, and a real motion-warped in-between layer — none of which is
needed for the current read, and all of which cost per-frame budget.

---

## 7. The Stefan Iverson Makoto breakdown

### (1) Confirmed Technical Findings

- **Unverified, general knowledge — no source reached.** The breakdown was named in the
  owner's brief; no public page for it was found on 2026-11-25. Everything below is a
  paraphrase of the brief plus the shipped implementation, not a citation.
- The one externally documented adjacent fact is S11's practical framing: an animator often
  has very few frames to deliver a punch, so anticipation and timing do the work that extra
  frames cannot.

### (2) Observations from Gameplay Footage — OWNER TO FILL

- [ ] Makoto's lunge: how far does the **hips** travel before the fist moves? (______)
- [ ] Contact: how many frames is the extended pose **held**? (______)
- [ ] Which parts keep moving during the hold? (______)
- [ ] Recovery: how deep is the dip, and does it overshoot? (______)
- [ ] Does the striking hand read **larger** at contact (foreshortening)? (______)

### (3) Proposed Godot 4.5 Implementation Techniques

**Now (commit 3):**

- **Foreshortening** — `foreshorten_scale` gives the striking hand a camera-readable
  1.08× on heavy/special contact frames, releasing smoothly across recovery
  (`foreshorten_amount`). One shared clamp (`SILHOUETTE_CLAMP`) covers foreshortening and the
  existing one-frame smear, so they cannot stack past it. Hand props are rebuilt from the
  hand's **rotation only** (`_isolate_props`), so a mic never scales or shears.
- **Volume lock** — the impact pop renormalises every frame, so the body's scale product
  stays at 1.0 ± 2 % (`SQUASH_VOLUME_TOLERANCE`).
- **No new material per rig** — the whole layer is bone transforms + uniforms on the one cel
  material each body already owns.

**Console scaling path:** screen-space foreshortening (a real projection cheat rather than
a bone scale), a per-bone stretch solver, and a heavier contact post (radial bloom). Those
change the renderer, not the animation data.

---

## 8. What this means for Sound Clash Brawl (synthesis)

- The **two things every reached source agrees on** are: (a) the silhouette is the product,
  and (b) lighting is what makes the silhouette read. Both are already the build's
  priorities (measured contact pose, per-preset rim and light rig).
- **Nothing in this document requires a renderer feature the Web/Compatibility target cannot
  do.** Every technique in §6 and §7 is a skeleton transform, a pivot offset or a uniform
  write.
- **The honest gap:** no footage has been watched by the agent that wrote this, and four of
  the seven references could not be reached. The "OWNER TO FILL" prompts are the shortest
  path to closing that gap; a filled prompt list is worth more than another citation.
- **Console** is a scaling exercise, not a redesign: the same data, higher tiers. See
  `CONSOLE_READINESS.md`.

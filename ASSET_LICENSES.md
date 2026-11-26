# Asset licence ledger — Sound Clash Brawl

**Status: DOCUMENTATION ONLY.** This file is an inventory and a checklist, not a legal opinion and not
a grant of rights. It records **only what this repository proves**; everything the repository cannot
prove is marked **OWNER TO FILL** and must be settled before any commercial release.

| Field | Value |
| --- | --- |
| Created | 2026-11-25 |
| Branch described | `feature/3d-cel-shaded` |
| Owner / final approver | Garfield Connell |
| Related documents | `AGENTS.md` §9, `BUSINESS_AND_RETENTION_STRATEGY.md` §6, `CONSOLE_READINESS.md`, `INDUSTRY_REFERENCE_ANALYSIS.md` |
| Code changes in this milestone | The PART 3 placement commit (prop loading, placement yaw, cel material, tests). This ledger records its asset as well |

> **Notice — not legal or financial advice; verify with a qualified professional.** Every row below
> is a research record. Licence scope, ownership, provenance and redistribution rights must be
> confirmed by a qualified IP lawyer and, where relevant, by the original rights holder.

## How to read this ledger

- **Source/tool** is what the repository itself states or what the file contents show.
- **Plan or licence** is the tier or agreement under which the asset was obtained. If the repository
  does not record it, the cell says **OWNER TO FILL**.
- **Date** is the date the repository records for the asset arriving or being produced. Where no date
  exists, it says **OWNER TO FILL** (or "not recorded").
- **Attribution required** records a licence obligation the repository can evidence (for example a
  SIL Open Font License notice). Otherwise **OWNER TO FILL**.
- **Redistribution notes** must cover the *actual* shipping form, not just "use in a game".

### The extractable-pack problem (applies to every row)

The repository ships a **web build in `/docs`**: `index.pck` (74,480,156 bytes after the PART 3
export on 2026-11-26, up from 68,773,156), `index.wasm` (about 38 MB), `index.js` and
`index.html`. A Godot Web export is **downloadable and extractable**:
anyone can fetch the `.pck` and unpack the models, textures, fonts and audio inside it. Therefore:

1. **Every licence must explicitly allow redistribution inside an extractable, downloadable game
   build** (not merely "use in an application" or "personal use").
2. **Every asset inside the pack is effectively published**, even if it is only visible in-game.
3. **`/docs` WAS re-exported in PART 3 (2026-11-26)** — the pack now contains the delivered
   `jamaican_speaker.glb` mesh and its 2,048² albedo (S3TC and ETC2 variants). That makes the
   speaker row a **live** publication, not a future one: its source and plan cells are still
   **OWNER TO FILL**, so the asset is published before its rights are evidenced. Every other row
   must be complete before the next export, because each export publishes all of them at once.
4. If a licence forbids that, the asset must be excluded from the pack (or replaced) before the next
   export. That decision is the owner's, recorded here.

> **Notice — not legal or financial advice.** Whether a given asset licence permits extractable
> packing is a legal question. Verify with a qualified professional.

---

## 1. 3D fighter bodies (the roster)

The game files are the rigged bodies; the static uploads stay as provenance.

| Asset | Source / tool | Plan or licence under which obtained | Date | Attribution required | Redistribution notes | Repo evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `godot/assets/models/fighters/feedback_rigged.fbx` | Owner upload; static mesh from a **Tripo**-pipeline upload, converted GLB→FBX by **ImageToStl**, skinned by **Adobe Mixamo** (`Feedback.Fighting.Idle.3`) | **OWNER TO FILL** (Tripo plan/tier, ImageToStl terms, Mixamo terms) | Uploaded 2026-11-22; Mixamo take wired 2026-11-24 | **OWNER TO FILL** | Ships in the web pack → must be redistributable in extractable form | `MODELS.md` "Mixamo pack"; `FighterModel3D.MODEL_SOURCES` |
| `godot/assets/models/fighters/lickshot_rigged.fbx` | Same pipeline; decimated 270,060 → 28,000 tris by `godot/tools/decimate_mixamo_blender.py` | **OWNER TO FILL** | 2026-11-22 / 2026-11-24 | **OWNER TO FILL** | As above | `MODELS.md` |
| `godot/assets/models/fighters/likkle_moore_rigged.fbx` | Same pipeline; decimated 246,641 → 28,000 tris | **OWNER TO FILL** | 2026-11-22 / 2026-11-24 | **OWNER TO FILL** | As above | `MODELS.md` |
| `feedback_v2.fbx`, `lickshot.fbx`, `likkle_moore.fbx` | Owner static uploads (Tripo-pipeline meshes, ImageToStl GLB→FBX); no skeleton | **OWNER TO FILL** | Uploaded 2026-11-22 | **OWNER TO FILL** | On disk as provenance; **not** referenced by `MODEL_SOURCES`, but still in the repository and may enter the pack | `MODELS.md` "Playable uploads" |
| `feedback_v2_albedo.png`, `lickshot_albedo.png`, `likkle_moore_albedo.png` | Extracted from each upload's embedded `Video/Content` PNG (1024², PNG) and re-encoded RGBA8 | Follow the mesh's source terms — **OWNER TO FILL** | 2026-11-22 | **OWNER TO FILL** | Ships in the pack | `MODELS.md` "Texture status" |
| `feedback_rigged_0.png`, `lickshot_rigged_0.png`, `likkle_moore_rigged_0.png` | Embedded atlas extracted by Godot on import from the Mixamo-exported FBX | **OWNER TO FILL** (same source family) | 2026-11-24 | **OWNER TO FILL** | Ships in the pack | Files present beside each rigged body |
| `feedback_fighting_idle_rigged.fbx`, `lickshot_placeholder_static.fbx`, `feedback_fitted_jacket_albedo.jpg` | Archived earlier uploads; never assigned | **OWNER TO FILL** | 2026-11-22 (archived) | **OWNER TO FILL** | Archived, not wired; still in the repository | `MODELS.md` "Archived" |

**Notes**

- **No licence text ships with any fighter model.** The repository records the *pipeline* (Tripo mesh
  → ImageToStl conversion → Mixamo skinning → Blender decimation) but not the *terms* of any of the
  three tools. Each must be recorded from the owner's own account/history.
- **Decimation is a human-authored edit** performed in this repository by `decimate_fbx.py` /
  `decimate_mixamo_blender.py`; it does not change the source licence but is a modification to record.
- **Purely generated geometry may be weakly protected by copyright** in some jurisdictions; see
  `BUSINESS_AND_RETENTION_STRATEGY.md` §7b.

> **Notice — not legal or financial advice.** Confirm with a qualified professional that the Tripo
> tier and ImageToStl/Mixamo terms in use permit commercial distribution inside an extractable web
> build, and whether attribution or disclosure is required.

## 2. Adobe Mixamo animation takes and characters

| Asset | Source / tool | Plan or licence under which obtained | Date | Attribution required | Redistribution notes | Repo evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `godot/assets/models/mixamo/clips/feedback/*.fbx` — **10 takes** (bencao, body-jab-cross, drunk-walk, elbow-uppercut-combo, fighting-idle-3, getting-up, jab-cross, knocked-out-1, right-hook, warrior-idle) | Adobe Mixamo; stripped to armature + one take by `godot/tools/strip_anim.py` | **OWNER TO FILL** (Adobe account; Mixamo terms at download time) | Delivered 2026-11-24 (`mixamo-pack` release) | **OWNER TO FILL** | Ships in the pack | `MODELS.md` "Takes" |
| `godot/assets/models/mixamo/clips/lickshot/*.fbx` — **11 takes** | Adobe Mixamo, same pipeline | **OWNER TO FILL** | 2026-11-24 | **OWNER TO FILL** | Ships in the pack | `MODELS.md` |
| `godot/assets/models/mixamo/clips/young_selecta/*.fbx` — **17 takes** | Adobe Mixamo, same pipeline | **OWNER TO FILL** | 2026-11-24 | **OWNER TO FILL** | Ships in the pack | `MODELS.md` |
| `godot/assets/models/crowd/Crowd Male Angry Gesture.fbx`, `… Cheering.fbx`, `… Rallying.fbx` (**3 characters**, each + 3 extracted PNGs) | Adobe Mixamo crowd uploads, decimated to 3,491 tris by `decimate_mixamo_blender.py` | **OWNER TO FILL** | Uploaded 2026-11-23 | **OWNER TO FILL** | Ships in the pack | `crowd/README.md`, `MODELS.md` |
| `godot/assets/models/dj/Crowd Male Cheering.fbx`, `Crowd Male Rallying.fbx` (**2 selector copies**) | Same bytes as the crowd models above, reused for the two DJ slots | **OWNER TO FILL** | 2026-11-23 | **OWNER TO FILL** | Ships in the pack | `dj/README.md` |
| `godot/assets/models/crowd/Crowd female Dancing Twerk.fbx`, `… Hip Hop Dancing.fbx`, `… Moonwalk.fbx`, `… Snake Hip Hop Dance.fbx` (**4 characters**, each + 4–6 PNGs) | Adobe Mixamo, decimated to ≈3,400 tris with 512² atlases | **OWNER TO FILL** | 2026-11-24 | **OWNER TO FILL** | Ships in the pack | `MODELS.md` "Female crowd models" |
| `models-for-mixamo/feedback_mixamo_ready.fbx`, `lickshot_mixamo_ready.fbx`, `likkle_moore_mixamo_ready.fbx` | Repository-made copies (scale records rewritten only) for uploading to Mixamo | Same source terms as §1 — **OWNER TO FILL** | 2026-11-22 | **OWNER TO FILL** | **Not loaded by the game**; present in the repository | `models-for-mixamo/README.md` |
| Untouched Mixamo originals archived under `art-source/mixamo/` | Owner uploads (45-file pack) | **OWNER TO FILL** | 2026-11-23 | **OWNER TO FILL** | Source archive; not in the build, but public in the repository | `MODELS.md` |

**Notes**

- **The repository never records which Mixamo/Adobe plan (free or paid) produced these downloads.**
  This is the single most important **OWNER TO FILL** item in the file: the permitted commercial use
  of Mixamo content depends on the terms accepted at download, and those terms are not in the repo.
- Mixamo content is **redistributed as game data** here (skinned meshes and animation takes), not
  merely used to author a derivative. That distinction must be checked against the terms.
- The three ringside male characters share **one Mixamo character skin**; hue/tint break-up is
  applied at runtime and does not change ownership.

> **Notice — not legal or financial advice.** Mixamo/Adobe terms of use, and whether they permit
> redistribution of the character and animation files inside a downloadable game pack, must be
> confirmed with the provider's current terms and a qualified professional.

## 3. Fonts

| Asset | Source / tool | Plan or licence under which obtained | Date | Attribution required | Redistribution notes | Repo evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `godot/assets/fonts/Bungee-Regular.ttf` | The Bungee Project (upstream: `github.com/djrrb/Bungee`) | **SIL Open Font License 1.1** — full text in repo | Not recorded — **OWNER TO FILL** | Yes: OFL copyright notice must be retained; the licence text ships with the font | May be bundled and redistributed with software; **the font itself may not be sold on its own**; reserved font names apply if modified | `OFL-bungee.txt` (Copyright 2023 The Bungee Project Authors) |
| `godot/assets/fonts/BungeeShade-Regular.ttf` | Bungee family | **OFL 1.1** — full text in repo | Not recorded — **OWNER TO FILL** | Yes, as above | As above | `OFL-bungeeshade.txt` |
| `godot/assets/fonts/BungeeInline-Regular.ttf` | Bungee family | **OWNER TO FILL** — no separate OFL text file exists for this face in the repo (the Bungee and Bungee Shade texts are present) | Not recorded — **OWNER TO FILL** | Likely as above (same family) but **unconfirmed by the repo** | Confirm before export; add its licence text beside the others | Font file present; no matching `OFL-bungeeinline.txt` |
| `godot/assets/fonts/ChakraPetch-Bold.ttf` | The Chakra Petch Project (upstream: `github.com/m4rc1e/Chakra-Petch`) | **OFL 1.1** — full text in repo | Not recorded — **OWNER TO FILL** | Yes: copyright notice retained; licence text ships with the font | As above | `OFL-chakrapetch.txt` (Copyright 2018) |

**Notes**

- All four faces are inside the web pack, so the OFL texts must also be reachable in a release
  (OFL requires the licence to accompany the font software). Packaging the three `OFL-*.txt` files
  into the distribution (or an in-game licences screen plus a `LICENSES.txt` beside the build) is
  **OWNER TO FILL / not yet done**.
- The repository does not record where the TTFs were downloaded from (upstream repo, Google Fonts, a
  design tool) or on what date.

> **Notice — not legal or financial advice.** OFL conditions (notice retention, reserved names,
> licence accompaniment) are strict; confirm the release packaging with a qualified professional.

## 4. Audio

| Asset | Source / tool | Plan or licence under which obtained | Date | Attribution required | Redistribution notes | Repo evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `godot/assets/audio/production/beats/beat_01.mp3` (original upload "Buck Shots (2) wonder productions .mp3", 23.4 s) | Owner-supplied; described in-repo as a **creator-owned** reggae hip-hop beat | **OWNER TO FILL** — the written grant/assignment from the creator is not in the repository | Not recorded — **OWNER TO FILL** | Depends on the grant — **OWNER TO FILL** | Played on Title/Character Select and after victory; ships in the extractable pack | `beats/README.md`, `production/README.md` |
| `godot/assets/audio/production/beats/beat_02.mp3` ("Easy Rider.mp3", 4:22.8) | As above | **OWNER TO FILL** | Not recorded — **OWNER TO FILL** | **OWNER TO FILL** | As above | `beats/README.md` |
| `godot/assets/audio/production/beats/beat_03.mp3` ("Lonely Gyal wonder productions.mp3", 90.04 s) | As above | **OWNER TO FILL** | Not recorded — **OWNER TO FILL** | **OWNER TO FILL** | As above | `beats/README.md` |
| `artifacts/sound-clash/audio-source/beats/Wonder Production (untitled upload, same duration as beat_03).mp3` | Fourth owner upload, not in the playlist | **OWNER TO FILL** | Not recorded | **OWNER TO FILL** | Reference only; not in the build | `beats/README.md` |
| Round sting, DJ tags, selector yell, crowd beds (`production/*.wav` slots) | **No files exist** — every cue is synthesised at runtime by `scripts/audio/SoundClashAudio.gd` | Project code; no third-party audio | n/a | None proven | Generated in memory, not shipped as assets | `placeholders/README.md` |
| `godot/assets/audio/default_bus_layout.tres` | Project-authored bus/effect layout | Project code | n/a | None | Shipped as project data | file present |

**Notes**

- "Creator-owned" is the repository's *description*, not evidence of a signed licence. **Who composed
  each beat, what was paid, and what rights were transferred are all OWNER TO FILL.** Publishing,
  synchronisation and master-use rights are separate rights and each needs a grant.
- The engine references *song titles* of the original uploads in `beats/README.md`. Those titles are
  provenance, not product-facing text; confirm before publishing any of them.
- Placeholder audio is synthesised and contains no samples, so it introduces no third-party rights.

> **Notice — not legal or financial advice.** Music rights (composition, master, synchronisation,
> neighbouring rights) are the highest-risk item in this ledger; confirm every track with a qualified
> professional before release.

## 5. 2D art, stage art and UI imagery

| Asset | Source / tool | Plan or licence under which obtained | Date | Attribution required | Redistribution notes | Repo evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `godot/assets/stages/sound_clash_sand_stage_1280x720.png` (Lanczos resize of a 1672 × 941 original) | **Owner-supplied** original (uploaded as `3DFAD58B-…png`), resized by a documented Pillow recipe; no repaint | **OWNER TO FILL** — the generation/commission tool and its terms are not recorded | Uploaded 2026-11-15 | **OWNER TO FILL** | Ships in the pack; the original stays in `art-source/` | `art-source/stages/sound-clash-sand/README.md` |
| `godot/assets/sprites/feedback/aligned/01…17_*.png` (17-pose pack) + `feedback.poses.json` | Owner-approved illustrations; cleaned/aligned by repository scripts | **OWNER TO FILL** (generation tool and terms not recorded) | Pose pack predates 2026-11-13 | **OWNER TO FILL** | Ships in the pack | `assets/sprites/feedback/README.md`, `AGENTS.md` §4 |
| `godot/assets/sprites/feedback/selected-frames-2026-11-15/` (20 selected 512² frames across lightah / mic-defence / skank / sparta-kick) | Owner-approved working art, prepared from owner uploads | **OWNER TO FILL** | 2026-11-15 | **OWNER TO FILL** | Ships in the pack | folder + `AGENTS.md` |
| `godot/assets/sprites/feedback/selected-frames-2026-11-18/` (6 processed poses: throw/groove/slap/kick/fist/reach) | Owner uploads processed by repository scripts | **OWNER TO FILL** | 2026-11-18 | **OWNER TO FILL** | Ships in the pack | `AGENTS.md` §9 item 33 |
| `godot/assets/sprites/feedback/box-footoff-ground-2026-11-15/` (1 frame, 1024 × 1536) | Owner-approved BOX contact frame; byte-identical copy of the original | **OWNER TO FILL** | 2026-11-15 | **OWNER TO FILL** | Ships in the pack | `godot/README.md` |
| `godot/assets/sprites/feedback/imported-poses/` (6 studies) and `walk-four-keys/poses/` (4 keys) | Owner studies; **unapproved movement test** | **OWNER TO FILL** | 2026-11-13 / 2026-11-15 | **OWNER TO FILL** | Ships in the pack today; keep the approval status separate from licensing | `AGENTS.md` §4 |
| `godot/assets/sprites/lickshot/` (11 + airborne 6, ground 4, hitstun 3, skank 8, walk 4; plus 1 archive frame) | **Creator-approved animation sources uploaded by Garfield Connell**, sliced/background-keyed by `art-source/fighters/prep_lickshot_poses.py` | **OWNER TO FILL** (artist/tool and grant not recorded) | Batches 2026-11-17 → 2026-11-19 | **OWNER TO FILL** | Ships in the pack | `art-source/fighters/lickshot/batch-2026-11-19/PROVENANCE.md` |
| `godot/assets/sprites/young-selecta/` (3 frames: idle, slam, thrust) | Owner uploads (L!kkle Moore) | **OWNER TO FILL** | Not recorded | **OWNER TO FILL** | Ships in the pack | files present |
| `godot/assets/sprites/crates/` (2 images) | Source not recorded | **OWNER TO FILL** | Not recorded | **OWNER TO FILL** | Ships in the pack | files present, no provenance note |
| `godot/assets/shaders/*.gdshader` (toon cel, ink outline, sky, sun, light pool, contact shadow, music note) | **Project-authored code** (written in this repository) | Project code — see §7 on the missing repository licence | 2026-11 | None | Ships as project code | files present |

**Notes**

- **Provenance notes exist for several art batches but record the *preparation*, not the *rights*.**
  Who made each illustration, with which tool, under which subscription tier, and under what
  assignment, is **OWNER TO FILL** for every row in this section.
- The 2D art is used in the Godot build only as presentation; it does not alter hitboxes, so
  replacing an unlicensed or unapproved image is a content swap, not a code change.

> **Notice — not legal or financial advice.** Image provenance, model releases (if any real person's
> likeness informed a character) and tool terms must be confirmed with a qualified professional.

## 6. Prop model slots — one delivered, four still **absent**

`godot/assets/models/props/` now holds the delivered **`jamaican_speaker.glb`** plus the albedo
Godot extracts beside it (`jamaican_speaker_0.png`). `PropLoader` names five files it will load when
they exist; **four are still absent in this revision**. The delivered tower is the only `.glb` in the
repository.

| Asset | Source / tool | Plan or licence under which obtained | Date | Attribution required | Redistribution notes | Repo evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `jamaican_speaker.glb` (left speaker stack) — **PRESENT** | **Meshy** (owner's delivery note). File contents confirm a single 2,618-triangle static mesh, one material, one embedded 2,048² PNG albedo, no skeleton and no animation. Delivered art is unchanged | **OWNER TO FILL** (Meshy plan/tier and its redistribution terms) | Uploaded 2026-11-26 (commit `dd222c4`, "Add files via upload") | **OWNER TO FILL** | **Ships in the extractable pack now** — 3,296,372 bytes of `.glb` plus a 2,048² albedo (S3TC + ETC2 variants) inside `docs/index.pck`. The licence must allow redistribution in a downloadable build; not yet evidenced | `godot/assets/models/props/jamaican_speaker.glb` (SHA-256 `3f4edcbfda3babb8b70daa25a3a14e8d53d72bd40c2400bca471a031cf8f8efc`), `jamaican_speaker_0.png`, `PropLoader` + `Arena3D._build_speakers` |
| `rasta_speaker.glb` (right speaker stack) | As above | **OWNER TO FILL** | **OWNER TO FILL** | **OWNER TO FILL** | As above | as above |
| `dj_booth.glb` (booth prop) | As above | **OWNER TO FILL** | **OWNER TO FILL** | **OWNER TO FILL** | As above | as above |
| `wireless_mic.glb` (per adult fighter) | As above | **OWNER TO FILL** | **OWNER TO FILL** | **OWNER TO FILL** | As above | as above |
| `mic_stand.glb` (L!kkle Moore) | As above | **OWNER TO FILL** | **OWNER TO FILL** | **OWNER TO FILL** | As above | as above |

**Notes**

- The delivered tower is loaded by `PropLoader`, seated to 2.6 m with its lowest vertex on Y = 0,
  yawed 12° into the yard and dressed in the project's double-sided cel material. Nothing about that
  placement changes the licence question.
- The four empty slots stay **empty** and draw nothing (the live-match and roster suites assert the
  delivered tower is the only prop mesh, and no slot draws a procedural stand-in). If any of the other
  four models is delivered later, **a complete row here is a precondition**, not a follow-up.
- A delivered asset's *approval* status (owner's eye) and its *licence* status are separate checks;
  both are required.

> **Notice — not legal or financial advice.** Any prop that reproduces a real speaker cabinet, brand
> or logo design carries trade-dress and trademark risk; confirm clearance with a qualified
> professional.

## 7. Project code, engine and repository licence

| Asset | Source / tool | Plan or licence under which obtained | Date | Attribution required | Redistribution notes | Repo evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `godot/scripts/**`, `godot/scenes/**`, `godot/project.godot`, `godot/export_presets.cfg` | Project-authored | **No `LICENSE` file exists in this repository** — **OWNER TO FILL** | 2026-11 | **OWNER TO FILL** | Absent a licence, default copyright applies (all rights reserved) | `ls LICENSE*` returns nothing |
| Godot Engine **4.5.stable** (`876b29033`) | Godot Engine, MIT licence | **MIT** (engine licence, not a file in this repo) | Pinned in `AGENTS.md` | Yes — include the engine's MIT licence and copyright notice in release documentation | The web build's `docs/index.wasm` **is the engine**, so the notice must ship with the distribution | `AGENTS.md` §5; `docs/index.wasm` |
| `docs/` web export (`index.pck`, `index.wasm`, `index.js`, `index.html`, icons) | Godot 4.5 Web export of this project | Combines all rows above | Re-exported 2026-11-26; `index.pck` 74,480,156 bytes | Engine notice applies | The pack is public and extractable and now contains the delivered tower. Its other contents must be licence-clean at the next export | `docs/` present; `docs/index.pck` |

**Notes**

- **The absence of a `LICENSE` file is itself an open item:** without one, contribution terms and
  third-party reuse are undefined. `package.json` declares `"license": "MIT"` for the JavaScript
  workspace, which is not the same as a repository-wide licence for the game and its art.
- Godot's MIT licence requires the copyright notice and permission text to be included in
  distributions; a licences screen or a `LICENSES.txt` beside the build satisfies this.

> **Notice — not legal or financial advice.** Choosing and filing a repository licence, and the
> engine-attribution packaging, should be confirmed with a qualified professional.

---

## 8. Outstanding items — summary

Every item below is **OWNER TO FILL** and blocks a clean commercial release:

1. **Fighter bodies** — Tripo plan/tier used, ImageToStl terms, and whether commercial distribution is
   permitted (all three rigged bodies + the static uploads + albedos).
2. **Mixamo plan** — which Adobe/Mixamo tier produced the 38 fighter takes, the 7 crowd characters and
   the 2 DJ copies; whether the terms allow redistribution inside a downloadable pack.
3. **Fonts** — a licence file for `BungeeInline-Regular.ttf`; the download source and date for all four
   faces; release packaging that ships the OFL texts.
4. **Music** — written grants for the three menu beats (composition, master, sync), plus the archived
   fourth upload.
5. **2D and stage art** — artist/tool, tier and grant for every sprite pack, the stage background and
   the crates; model releases if a real person informed a design.
6. **Props** — `jamaican_speaker.glb` is **delivered and already shipping in the pack**; its Meshy
   plan/terms, redistribution grant and trade-dress clearance are still **OWNER TO FILL**. The booth,
   rasta speaker and both hand props remain absent, with the same clearance requirement.
7. **Repository licence** — no `LICENSE` file; decide and add one.
8. **Engine attribution** — ship Godot's MIT notice with the build.
9. **Approval vs licence** — record both per asset; today many assets carry an approval status but no
   rights record, and several carry neither.

> **Notice — not legal or financial advice; verify with a qualified professional.**

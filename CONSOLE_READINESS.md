# CONSOLE_READINESS

Console scaling and platform-readiness record for **Sound Clash Brawl**.
Created 2026-11-25. Owner and final approver: Garfield Connell.

Companion documents:

- `AGENTS.md` — the authoritative project blueprint, decisions and verified work log.
- `INDUSTRY_REFERENCE_ANALYSIS.md` — the citable industry reference analysis behind the
  visual techniques, with the source list and the "OWNER TO FILL" footage prompts; §8 is the
  Brawlhalla business/architecture reference.
- `BUSINESS_AND_RETENTION_STRATEGY.md` — the evolving-game vision, the **Carnival Clash** cultural
  event calendar, the twelve research-only revenue streams (all **NOT APPROVED FEATURES**), six
  monetization principles, thirteen KPIs, cultural/IP protection, co-director proposals and the open
  legal questions.
- `ASSET_LICENSES.md` — the per-asset licence ledger (the authority for what may ship in an
  extractable pack). Note that its `OWNER TO FILL` rows block a clean commercial release.

**Status in one line:** the game is a **Web / Compatibility** build. Nothing here is a
console port, a certification submission or a promise of one. This file records what the
current build costs, what a console tier would change, and what is still unknown.

## 1. What ships today (verified)

| Item | Value | How it was verified |
| --- | --- | --- |
| Renderer | Godot 4.5 `gl_compatibility` (WebGL 2) | `project.godot`; the Web export runs headless |
| Target | 1280 × 720, 60 FPS, Chromebook + iPhone Safari | Owner's stated targets; frame rate on real hardware **not measured by an agent** |
| Lights per object | **7** (sun + fill + omni rim + 4 stage spots) | `Arena3D.light_count()` asserted ≤ `max_lights_per_object()` (8) in `headless_roster_check` |
| Directional lights | 2 (sun + fill) | asserted ≤ 4 |
| Screen-space effects | **off**: no SSAO, SSIL, SDFGI or volumetric fog | asserted in `headless_roster_check` |
| Tonemap / glow | ACES + additive glow (low intensity) | asserted in `headless_roster_check` |
| Fighter meshes | 29 025 / 270 074 / 246 654 tris | `FighterModel3D.MODEL_SOURCES` + headless inventory |
| Crowd | 22 rigs, ≤ 3 500 tris each; atmosphere < 90 000 tris | asserted in `headless_roster_check` |
| Pose grid | 18 FPS attacks, 12 FPS idle/walk | `AnimationFeel.STEPPED_FPS`, `step_fps_idle` |
| Web export | `docs/` ≈ 103 MB (`index.pck` ≈ 68.7 MB, `index.wasm` ≈ 38.1 MB) | `--export-release "Web"` run, 2026-11-25 |
| Per-frame allocation | 0 new nodes / 0 new resources over 600 frames | `animation_feel_audit` allocation run |

The **8-lights-per-object** figure is the Compatibility renderer's default and the reason the
Night rig is four stage spots plus a moon key, not a dozen beams. Every new light has to be
paid for by removing one.

## 2. What a console tier would unlock

Ordered by visual gain per unit of risk. None of these is implemented; all of them are
renderer features the Web target cannot do.

| Tier | Feature | Why it is not in the Web build | Reference |
| --- | --- | --- | --- |
| 2 | Real-time shadow cascades / a second shadowed light | Compatibility has one directional shadow and no cascades | Tekken 8's lighting is the reached source's own hard problem (`INDUSTRY_REFERENCE_ANALYSIS.md` §3, S7) |
| 2 | Screen-space ambient occlusion / contact shadows | Not available in Compatibility | same |
| 2 | Depth-of-field on Special/KO accents | Post-process pass; the Web build uses a clamped FOV/angle accent instead | SF6 Super Art lighting (§4, S4) |
| 2 | More than 8 lights per object | Renderer limit | — |
| 3 | 24–30 FPS pose grid + longer per-bone lag chains | Per-frame budget only | Xrd limited animation (§1/§2, S1) |
| 3 | Full-screen per-character impact overlays | Fill-rate and memory | Fatal Fury CotW comic overlays (§5, S9/S10) |
| 3 | Cloth/hair secondary motion, a real projection foreshortening cheat | Solver + GPU budget | Makoto foreshortening (§7) |

**Rule:** a console feature must be a **tier flag over the same data**, never a fork of the
animation or combat code. `BaseFighter`, the frame data, the 132 BPM clock and the 31 Patois
entries are shared across every tier.

## 3. What must be true before a console build is attempted

- [ ] **Platform chosen and SDK access confirmed** (owner decision). No console SDK, devkit
      or certification contact exists in this repository.
- [ ] **Engine version pinned for the console branch.** The Web build is Godot 4.5 stable;
      a console export may require a vendor-supported fork. [TODO] confirm.
- [ ] **Controller input map** — the current `InputMap` is keyboard/touch. Gamepad
      deadzones, remapping and the on-screen prompts are not authored.
- [ ] **Save data / profiles** — none implemented. Round state is in-memory only.
- [ ] **Frame budget measured on target hardware.** No agent in this project has a GPU; all
      performance claims here are structural (node counts, allocations, light counts), not
      measured frame times.
- [ ] **Certification requirements** (suspend/resume, user sign-out, storage-full, parental
      controls, accessibility) reviewed against the chosen platform.
- [ ] **Export pipeline** — the Web export command is documented and reproducible; a console
      export pipeline is not.
- [ ] **Audio** — the Sound Clash audio engine runs, but platform mixing/ducking rules and
      any licensed music are unresolved. No audio file exists in the repository.

## 4. Known risks that a console tier would expose

1. **The 270 k-tri fighter meshes.** L!ckshot and L!kkle Moore are far heavier than
   Feedback. Fine on a desktop GPU, a real question on a low-end Chromebook and on any
   tier that wants two fighters plus 22 crowd rigs plus a full stage in one frame.
2. **Two fighters × two skeletons × per-frame bone writes.** The feel layer writes bones
   every frame (no allocation, but real CPU). A tier-3 secondary-motion layer multiplies
   that.
3. **The 8-light ceiling is load-bearing.** The Night preset's look depends on four coloured
   spots; raising the ceiling changes the art direction, not just the cost.
4. **Web memory.** `docs/` is ~103 MB and GitHub already warns about the 65 MB `.pck`. A
   console build would ship differently, but the asset weight is the same.

## 5. Open questions for the owner

- [ ] Which platform(s) are actually being considered, and in what order?
- [ ] Is 60 FPS locked, or is a 30 FPS quality mode acceptable for a tier-2 build?
- [ ] Does the console tier need to match the Web build's content exactly, or can it add
      modes/venues the Web build cannot afford?
- [ ] Is a physical release (disc/cartridge) in scope, or download-only?

## 6. Cross-references

- Visual techniques and their sources: `INDUSTRY_REFERENCE_ANALYSIS.md` §1–§7; §8 is the
  Brawlhalla reference and §9 the synthesis.
- The implemented visual layer, its counts and its decisions: `AGENTS.md`
  ("2026-11-25 — PART 1" section) and the headless suites
  (`headless_roster_check`, `live_match_check`, `facing_audit`, `animation_feel_audit`).
- The permanent creative direction: `artifacts/sound-clash/SOUND_CLASH_CULTURE.md`.
- Business, retention and licensing: `BUSINESS_AND_RETENTION_STRATEGY.md`, `ASSET_LICENSES.md`.

---

# Part 2 — Long-term technical preparation (documented, not built)

Added 2026-11-25 with the business/retention, licensing and Brawlhalla documentation pass. **Nothing
in this part is built.** No store, payment flow, account system, inventory, entitlement check,
analytics call, DLC pack, profile save or mobile/desktop/console export exists in this repository.

## 7. Ten preparation areas

Each area names what to prepare, why it matters for the long-term/console path, and what must not be
done in this milestone.

### 7.1 Persistent player profiles

- **Prepare:** a profile document that survives a year of absence — display name, last-used fighter,
  cosmetic loadout, progress flags, settings — with a schema version.
- **Why:** the retention thesis in `BUSINESS_AND_RETENTION_STRATEGY.md` §1 needs identity to persist
  across updates, devices and long gaps; console platforms also expect well-formed, migratable saves.
- **Do not now:** implement a save system, add `user://` usage or create profile UI. Today there is no
  save of any kind (round state is in-memory).

### 7.2 Cross-platform progression

- **Prepare:** define progression as **portable identifiers and counters** (fighter IDs, cosmetic IDs,
  milestone flags, aggregate counts), never as a platform-specific save blob.
- **Why:** a player who starts on a phone browser and later plays desktop or console must not lose
  their character; cross-progression is also a multi-platform expectation.
- **Do not now:** build accounts, linking codes, cloud sync or any server.

### 7.3 Secure player inventories

- **Prepare:** the principle that an inventory is a **server-authoritative** list of granted IDs; a
  client save may cache it but never define it.
- **Why:** a client-trusted inventory is a free-cosmetics exploit, and platform stores treat
  entitlement fraud as the developer's problem.
- **Do not now:** add a server, API, token flow or inventory record.

### 7.4 Cosmetic ownership and entitlements

- **Prepare:** separate **ownership** (does this player own outfit X?), **equipability** (is X legal
  for this fighter/slot?) and **presentation** (how X is drawn). Store/platform data answers the
  first, local data the second, `FighterModel3D` the third.
- **Why:** the split lets a licensed collaboration expire (ownership withdrawn or item made
  unequippable) without touching combat or the renderer.
- **Do not now:** implement entitlement checks, receipts, restore-purchases or any store hook.

### 7.5 Modular character and stage content (`.tres` now, `.pck` packs later)

- **Prepare:** the target content model — `FighterDef`, `MoveDef`, `OutfitDef`, `StageDef`,
  `EventCalendar` as **data resources with stable string IDs** — and a future packed form where
  optional content ships as a `.pck` under `res://content/<pack_id>/`.
- **Why:** content as data is what lets a one-person team ship an event per quarter; packs are the
  only realistic way to keep the first mobile download small.
- **Do not now:** create the resource classes, move the roster out of GDScript or build a pack
  pipeline. `MODEL_SOURCES`, `FighterRoster.FIGHTERS` and `MixamoClips.ROLE_FILES` stay hardcoded.

### 7.6 Privacy-conscious analytics

- **Prepare:** a written data list (what is counted, why, retention) and the **opt-in** rule before
  any SDK is chosen; aggregate counters only, no personal data, no third-party trackers at launch.
- **Why:** children play fighting games on shared family phones, and a privacy incident would end the
  project faster than any missing feature; stores require a data-safety disclosure that must match
  reality.
- **Do not now:** add any analytics call, SDK, cookie, identifier or network request for metrics.

### 7.7 Content updates without full rebuilds

- **Prepare:** the loop — data/resource change → content pack published → client discovers it on boot
  → no engine rebuild, no store re-submission for cosmetic content. Event dates, free rotations and
  outfit availability are all data.
- **Why:** every store submission costs days; a solo team cannot afford one per festival.
- **Do not now:** build a pack builder, manifest format, downloader or version negotiator.

### 7.8 Secure payment integration hooks

- **Prepare:** the *interface boundary* only — a future `PurchaseProvider` with `query_products()`,
  `purchase(product_id)`, `restore_purchases()`, plus receipt verification that lives on a server, and
  the rule that the client never grants an entitlement itself.
- **Why:** mobile and console stores require their own billing SDKs and receipt validation; designing
  the seam now keeps monetization out of combat and UI code later.
- **Do not now:** integrate any payment SDK, create products, set a price or write store code.

### 7.9 Strict separation of gameplay logic from monetization

- **Prepare:** an enforceable rule set, not a convention: `BaseFighter.gd` reads **input and combat
  data only** — never inventory, entitlements, purchase state or analytics; frame data, hitboxes, the
  132 BPM beat clock and the Crowd Hype rules stay byte-identical with or without any monetization
  system; entitlement checks live only at the selector UI; a headless check should eventually prove
  combat output is identical with all cosmetics unowned.
- **Why:** the moment a store check enters the combat path, every balance change becomes a revenue
  question and every monetization change becomes a combat risk.
- **Do not now:** edit `BaseFighter.gd`, combat, animation or any gameplay file.

### 7.10 Browser, mobile, desktop and console distribution requirements

| Target | Preparation needed | Known constraint in this repo |
| --- | --- | --- |
| **Browser (web)** | First-load budget; MIME types; COOP/COEP if threaded; WebGL2 fallback | `docs/` is ~103 MB; **GitHub Pages cannot set COOP/COEP**, so a threaded build needs another host |
| **Mobile (Android/iOS)** | Touch sizing, safe areas, app-size limits, OS save conventions, battery/thermal budget | Touch controls exist only in the web prototype; no mobile export preset |
| **Desktop (Windows/macOS/Linux)** | Installer/packaging, save locations, controller support, cloud saves if used | Only the Web preset is in `export_presets.cfg`; desktop export unverified |
| **Console (PlayStation/Xbox/Switch)** | Developer agreement, devkit, certification checklist, age rating, platform save/profile and entitlement APIs, performance certification | Nothing started; no SDK, no certification plan (see Part 1) |

- **Prepare:** one per-target checklist naming the owner, the evidence and the date for each
  requirement, plus the rule that no platform-specific code enters gameplay scripts.
- **Do not now:** contact platform holders, download SDKs, create export presets or promise a console
  release date.

## 8. Guardrails now

Binding on future work. **None of these is implemented by this documentation change.**

1. **Fighter/stage/outfit rosters belong in data resources with stable string IDs.** Fighters, stages
   and outfits should be `.tres` resources keyed by stable strings (`"feedback"`,
   `"carnival_clash_big_truck"`), never by array index or enum int. Today
   `FighterModel3D.MODEL_SOURCES`, `FighterRoster.FIGHTERS` and `MixamoClips.ROLE_FILES` hardcode some
   of this in GDScript. **The refactor is logged as future work and must NOT be done now** — it must
   be its own reviewed change with the four suites re-run.
2. **Saves store IDs, never paths or enum ints, with a versioned schema.** A save may contain
   `"fighter": "lickshot"`, `"outfit": "carnival_clash_fit_01"`, `"schema": 2`; it must not contain
   `res://assets/models/fighters/lickshot_rigged.fbx` or `3`. The first field of any save document is
   its schema version, and every bump ships a migration.
3. **A `ProfileStore` interface, local first and cloud later.** Define the surface once
   (`load_profile()`, `save_profile()`, `list_slots()`) and let the local implementation exist before
   any cloud one. **Do not rely on browser storage alone** — Safari may purge site storage after about
   **7 days of inactivity**, so anything a player would miss needs a server or an explicit
   export/import path.
4. **Outfits via a shared skeleton contract and a `CosmeticLoadout` resource read by
   `FighterModel3D`.** Every outfit is authored against the shared skeleton contract (today a 65-bone
   `mixamorig` rig) so it is a mesh/material swap, not a second animation set; the loadout resource
   carries the chosen outfit/colour/entrance IDs and is read by `FighterModel3D` and nothing else.
5. **DLC packs namespaced under `res://content/<pack_id>/`.** No scripts inside packs; a version check
   before use; on web the pack is downloaded to `user://` and mounted with `load_resource_pack`. A pack
   that fails its version check is rejected, not partially applied.
6. **`BaseFighter` never reads inventory or entitlements.** Entitlement checks live only at the
   selector UI; combat must produce identical results whether a cosmetic is owned, unowned, expired or
   absent.
7. **Keep combat fixed-step and deterministic, with seeded randomness.** The simulation is stepped at
   a fixed rate (60 Hz in `project.godot`) with seeded random choices, so a future online mode, replay
   validation or ghost comparison remains possible. Do not introduce frame-rate-dependent combat;
   ordinary Godot physics is not automatically deterministic across platforms.
8. **Analytics is opt-in, with no personal data and no third-party trackers at launch.** Nothing is
   sent before consent; nothing identifiable is ever sent; no ad-tech or cross-site tracker ships. A
   decline leaves the game fully playable.

## 9. What must not be done next, and what can

| Do not | Why |
| --- | --- |
| Build a store, payment flow, account system, ad unit or monetization UI | Not approved (`BUSINESS_AND_RETENTION_STRATEGY.md` §3 — "NOT APPROVED FEATURES") |
| Refactor `MODEL_SOURCES`/`FighterRoster` into `.tres` | Logged future work; must be its own change with the suites re-run (guardrail 1) |
| Touch `BaseFighter.gd`, combat, animation or gameplay files | This milestone is documentation only |
| Re-export `/docs` | The export is a large binary and this change alters no game asset |
| Promise a console, mobile or store date | No developer agreement, SDK or certification plan exists |

**Permitted next steps**, each as its own reviewed change with the four suites re-run: a data-resource
refactor staged behind byte-identical combat output; a local-only `ProfileStore` with a versioned
schema; an event-calendar resource with a presentation-only free rotation; and a content-pack prototype
in local play only, before any web download path.

> **Notice — not legal or financial advice; verify with a qualified professional.** Console platform
> requirements (developer agreements, certification, age ratings, data-privacy obligations, store
> billing rules) are contractual and legal matters. Nothing in Part 2 is a compliance claim or a
> substitute for the platform holders' own documentation.

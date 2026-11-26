# Sound Clash Brawl — Business & Retention Strategy

**Status: DOCUMENTATION ONLY.** Nothing in this file is an approved feature, a commitment, or a
promise of revenue. Revenue streams are **research subjects only** and are marked
**NOT APPROVED FEATURES**. No monetization code, store, payment flow, account system, ad unit or
monetization UI exists in the repository, and this document does not authorize building any of them.

| Field | Value |
| --- | --- |
| Document created | 2026-11-25 |
| Owner and final approver | Garfield Connell |
| Branch it describes | `feature/3d-cel-shaded` |
| Related documents | `AGENTS.md` (§2 roadmap, §9 guardrails), `CONSOLE_READINESS.md`, `ASSET_LICENSES.md`, `INDUSTRY_REFERENCE_ANALYSIS.md`, `artifacts/sound-clash/SOUND_CLASH_CULTURE.md` |
| Code changes in this milestone | **None** — this is a documentation-only change set |

> **Notice — not legal or financial advice.** Every legal, intellectual-property, privacy,
> licensing, tax and revenue item below is a research note, not advice. Verify with a qualified
> professional (a lawyer and an accountant in the relevant jurisdiction) before acting on any of it.
> The same notice applies to every legal/IP/privacy/licensing item in this document.

---

## 1. Evolving-game vision (5–10+ years)

Sound Clash Brawl is planned as an **evolving game rather than a sequence of sequels**. The target
shape of the product over five to ten years and beyond:

- **A player can leave for months or years and come back without being punished.** No account reset,
  no lost roster, no "you had to be there" wall. Returning players should find the festival they
  loved still running, plus content they have never seen.
- **Return is a discovery moment, not a catching-up chore.** The first session after a long absence
  should open on something new — a festival stage, a rotating outfit, a returning character, a
  refreshed selector — and re-teach nothing that still works.
- **No forced sequels.** Growth comes from content, events and cultural moments inside one
  continuously updated game, so a small team never has to ship a second full product to earn a
  second launch.
- **Content is additive and non-destructive.** New fighters, stages, outfits and events extend the
  same core; existing saves, ownership and muscle memory keep working. This is why the technical
  guardrails in `CONSOLE_READINESS.md` (stable string IDs, versioned saves, entitlement separation)
  exist before any of this is built.
- **The core loop is the retention engine.** The 132 BPM rhythm-fight, the sound-clash fantasy, the
  crowd, the comedy and the local two-player match are what bring people back. Events are a reason
  to return to that loop, never a replacement for it.

### The Brawlhalla benchmark — borrow the structure, not the scale

Brawlhalla is the clearest public example of this shape: a **free-to-play 2D platform fighter** with
local and online play for up to eight players and full cross-play across PC, PlayStation, Xbox,
Nintendo Switch, iOS and Android (official product pages:
<https://www.brawlhalla.com/>, <https://www.ubisoft.com/en-us/games/brawlhalla>). It released on
17 October 2017 (Steam store page) and Ubisoft announced that it had acquired the developer Blue
Mammoth Games in March 2018 (<https://news.ubisoft.com/en-us/article/4xuBkncNEEFHXpWzpDPK19/blue-mammoth-games-joins-ubisoft>).
Ubisoft's own newsroom reported **100 million lifetime players** in May 2023
(<https://news.ubisoft.com/en-us/article/MvVxfuQT6SZ5XnlJY8Pgp>) — that figure is cited here only
as evidence of longevity, not as a target.

**What is worth borrowing (structure):** one continuously updated free-to-play game; a rotating
free roster alongside permanent unlocks; cosmetic-only monetization with crossover collaborations;
the same build playable on many devices; and an event calendar that gives lapsed players a date to
come back to.

**What must not be borrowed (scale):** Brawlhalla has a large publisher, a multi-discipline studio
and a live-operations team behind it. Sound Clash Brawl is a small, zero-budget, owner-led project
(`AGENTS.md` §3). Copying its *scale* — always-on live ops, seasonal battle passes, a marketing
calendar, a support desk — is out of reach and would break the April 21, 2027 target. Copy the
*shape*: a small number of well-chosen events, content that is data rather than code, and a core
loop good enough to survive long gaps between updates.

*Everything else about Brawlhalla's internal economics, retention curves, revenue and team size is
**unverified, general knowledge** and is deliberately not asserted here.*

---

## 2. Cultural event calendar for reactivation and cosmetic drops

The calendar exists to give lapsed players **a date to return to** and to give the art pipeline a
reason to produce outfits, stages and selectors. It is designed so that **the whole calendar is
data, not code** (see §2.4).

### 2.1 Flagship — "Carnival Clash" (early August)

**Carnival Clash** is the flagship early-August event. It is anchored on three overlapping cultural
facts of the season, all used in **generic** cultural terms:

- **Emancipation Day** (1 August) — the public holiday marking the abolition of slavery in the
  British Caribbean, observed in Jamaica and across the region.
- **Jamaican Independence Day** (6 August) — national independence, celebrated with street
  celebrations, music and community events.
- **The early-August Carnival long weekend** — the masquerade/street-parade season that closes the
  same week in the Caribbean diaspora, including the **Toronto-area** Caribbean festival season
  (reggae, soca and sound-clash celebrations treated here as a generic category, not as any one
  organiser's event).

**Content themes (generic terms only):**

| Theme | What it means in-game | Cosmetic outlet |
| --- | --- | --- |
| **Best-dressed fits** | The costume-and-competition culture of the season: judged looks, coordinated crews, standout outfits | Outfits and colour variants; a "best dressed" crowd reaction and end-of-match pose |
| **Big Truck** | The slow-rolling sound truck with the stack on the flatbed, crowd walking alongside | Stage variant: a rolling truck stage with a moving crowd edge |
| **Road March** | The procession/route itself — moving through the street with the music | Stage variant and a rotating "route" selector; crowd density changes along the route |

**Naming rule (hard):** the event is called **Carnival Clash** and is described only with generic
cultural words — *Carnival, Big Truck, Road March, best-dressed fits, masquerade season, long
weekend*. **No real festival organiser, parade, band, committee or trademarked event brand may be
named in any document, code comment, store listing, trailer or product-facing text.** Any future use
of a real-world festival's name or branding requires **the organisers' written permission first**,
and that permission must be recorded in `ASSET_LICENSES.md` before use.

> **Notice — not legal or financial advice.** Festival names, parade brands and event marks are
> third-party intellectual property and may be registered trademarks. Confirm rights and obtain
> written permission with a qualified professional before any use.

### 2.2 Three lighter anchors

The flagship carries the year. Three lighter anchors keep the game visibly alive with minimal live
operations work — each is a single data row, a rotating free item and a crowd/audio variant.

| Anchor (working name — not approved) | Window | Cultural hook (generic) | Content load |
| --- | --- | --- | --- |
| **Reggae Month Riddim** | February (Reggae Month) | Reggae Month is observed in Jamaica in February; a month of sound-system, dubplate and dancehall programming | One free rotating outfit per fighter, a "riddim" selector recolour, one dubplate-style entrance line |
| **Carnival Season Opener** | Carnival season (spring, diaspora) | The build-up weeks before the summer parade season: fetes, crews, road-ready looks | One stage variant (street/yard dressing), one crew-banner cosmetic, crowd chant variant |
| **December Yard** | December | The homecoming/yard season: family, food, dances, the year's biggest local parties | One "homecoming" outfit, a night-lights stage variant, a year-end crowd and selector celebration |

These are deliberately light: no new fighter, no new mode, no new mechanics. If a year is short on
capacity, an anchor can be a **free rotating outfit only**.

### 2.3 Dropping the calendar as data

The calendar is specified as a **resource**, not as code. A future `EventCalendar` data resource
(planned, **not built**) holds one entry per event:

```
id              "carnival_clash"                 # stable string ID, never an enum int
display_name    "CARNIVAL CLASH"
start_md        "08-01"                          # month-day only; year resolved at runtime
end_md          "08-10"
region_note     "Emancipation Day / Independence / Carnival long weekend"
free_rotation   ["outfit:...", "stage:...", "selector:..."]
cosmetic_pool   ["outfit:...", "stage:...", "selector:..."]
stage_variant   "big_truck" | "road_march" | null
crowd_variant   "road_march_crowd"
enabled         true
```

Rules that make this work without a code release:

1. **Events need no code release.** Shipping a new event means editing a data entry (dates plus a
   free rotating outfit/stage/selector) and adding the referenced content under a pack namespace
   (see `CONSOLE_READINESS.md`, guardrail 5). The client reads the data at boot.
2. **Dates are month-day, not year-locked**, so the same entry repeats annually and does not need
   editing every January.
3. **Free rotation is the reactivation hook** — during an event window a cosmetic is free for
   everyone, which is a reason to log in and does not depend on a purchase.
4. **Nothing in the calendar gates gameplay.** Events change presentation and availability of
   cosmetics only; fighters, stages and movesets stay playable outside the window.
5. **Offline and web builds must degrade gracefully** — if the calendar cannot be fetched, the
   built-in default calendar applies.

> **Notice — not legal or financial advice.** Public-holiday and festival dates, and any use of a
> real event's identity, are matters to confirm with a qualified professional before publication.

---

## 3. Twelve potential revenue streams (research only)

> **ALL TWELVE ITEMS BELOW ARE "NOT APPROVED FEATURES".** They are research subjects recorded so
> the owner can decide later. None is implemented, scheduled, costed or promised. No store, payment
> flow, ad unit or purchase UI may be built from this list without a separate, explicit owner
> decision and an approved design.

| # | Stream | What it would be | Free-to-play compatibility | Research status |
| --- | --- | --- | --- | --- |
| 1 | Optional cosmetic purchases | Individual outfits, colourways, entrance effects sold à la carte | High — cosmetic only | NOT APPROVED FEATURES |
| 2 | Alternative outfits | Alternate looks per fighter (festival fits, era looks, crew colours) | High | NOT APPROVED FEATURES |
| 3 | Founder / supporter packs | One-off bundles that fund development and grant cosmetic recognition (badge, outfit, nameplate) | High — time-limited, not power | NOT APPROVED FEATURES |
| 4 | Additional character packs | New fighters sold as packs, with a free rotation so everyone can try them | Medium — must never split the player base | NOT APPROVED FEATURES |
| 5 | Premium stages / cosmetics | Themed stages and stage variants as paid content | Medium — stages must stay competitively neutral | NOT APPROVED FEATURES |
| 6 | Seasonal content | Bundled seasonal cosmetics tied to the cultural calendar (§2) | High | NOT APPROVED FEATURES |
| 7 | Official cultural and commercial partnerships | Co-branded festival/season content with a licensed partner | Medium — permission-heavy | NOT APPROVED FEATURES |
| 8 | Licensed guest characters | A real artist, sound system or brand character licensed into the roster | Medium — contract-heavy | NOT APPROVED FEATURES |
| 9 | Sponsorships | A sponsor attached to an event, stage or tournament, disclosed in-game | Medium — must not touch combat | NOT APPROVED FEATURES |
| 10 | Merchandise | Apparel, prints, accessories using original characters and marks | Independent of the game | NOT APPROVED FEATURES |
| 11 | Premium downloadable editions | A paid "complete" edition bundling cosmetics and future packs | High — convenience, not power | NOT APPROVED FEATURES |
| 12 | Optional rewarded ads (if appropriate) | A voluntary, opt-in ad that grants a small cosmetic currency amount, never in combat | Low-to-medium — needs strict rules | NOT APPROVED FEATURES |

**Preferred research direction: free-to-play with optional purchases.** The game is playable in full
for free; money buys cosmetics, convenience or cultural celebration, never advantage. This matches
the project's stated audience (a diaspora community on phones and Chromebooks) and the
accessibility principle in §4.

> **Notice — not legal or financial advice.** App-store billing rules, tax/VAT handling, consumer
> law, refund policy, advertising-disclosure rules and children's privacy law all apply to these
> streams differently per platform and country. Verify with a qualified professional before
> designing any of them.

---

## 4. Six monetization principles

These are **binding design principles** for any future monetization work, not features.

1. **No pay-to-win.** Nothing purchasable may change damage, reach, speed, hitbox, beat window,
   startup/active/recovery frames, Crowd Hype or Dubplate gain. Frame data lives in
   `FighterRoster.gd`/`BaseFighter.gd` and stays untouched by any store system. Cosmetics only.
2. **No intrusive ads in combat.** A fight is never interrupted by an ad. If rewarded ads are ever
   explored (stream 12), they are opt-in, outside a match, and never in the middle of a round.
3. **No deliberate frustration to force purchases.** No artificial energy gates, no "you must pay
   to continue" walls, no difficulty or grind tuned to sell a shortcut, no purchase prompt after a
   loss. If a system only makes money by making the game worse, it is rejected.
4. **Accessibility for players who cannot afford premium content.** All fighters must be reachable
   by playing. Free rotation, earned currency and event freebies keep the whole roster experience
   available; nothing gameplay-relevant is permanently locked behind payment.
5. **Purchases must be *desirable*, not extracted.** The reason to buy is **character attachment**
   (a fighter you love, in a fit you want), **cultural authenticity** (a Carnival Clash outfit that
   feels right), **artistic quality** (the cel-shaded look, the crowd, the animation) and
   **entertainment value** — never pressure, scarcity tricks or sunk-cost mechanics.
6. **Proper permissions and licences for every real-world element.** Real artists, sound systems,
   brands, music, voices and personalities require written permission and a recorded licence before
   they appear — in a cosmetic, a stage, a name, a likeness or a sample. `ASSET_LICENSES.md` is the
   ledger; nothing enters the game without a row there.

> **Notice — not legal or financial advice.** Principles 1, 5 and 6 are legal and consumer-protection
> sensitive (advertising claims, minors, loot-box rules, likeness rights). Verify with a qualified
> professional.

---

## 5. Thirteen KPIs

Tracked to judge whether the game is growing, retaining and paying for itself. **A loyal returning
community is worth more than a launch spike**: a launch-week number that decays to zero is a failed
launch, while a modest, stable, returning audience is a healthy product.

| # | KPI | Definition (plain) | Pre-launch instrument? | Notes |
| --- | --- | --- | --- | --- |
| 1 | **DAU** | Unique players in a day | Yes (opt-in) | Daily active users |
| 2 | **MAU** | Unique players in 30 days | Yes (opt-in) | With DAU gives the stickiness ratio (DAU/MAU) |
| 3 | **Concurrent players** | Peak simultaneous sessions | Yes (opt-in, aggregate) | Capacity and server planning |
| 4 | **New player acquisition** | First-ever sessions per period | Yes (opt-in) | Distinguish store/organic/event QR arrivals where possible |
| 5 | **Day 1 retention** | Share of new players returning the next day | Yes (opt-in) | First-session quality signal |
| 6 | **Day 7 retention** | Share returning within a week | Yes (opt-in) | Core-loop signal |
| 7 | **Day 30 retention** | Share returning within a month | Yes (opt-in) | Long-term product signal |
| 8 | **Returning / reactivated players** | Players back after 30+ days away | Yes (opt-in) | The metric the whole cultural calendar exists to move |
| 9 | **Average session length** | Mean minutes per session | Yes (opt-in) | Beware of counting idle/paused time |
| 10 | **Completed matches** | Matches that reach a result (KO, timeout or draw) | Yes (local, no account) | The sturdiest health metric: fights that actually finish |
| 11 | **Purchase conversion** | Share of MAU making any purchase | Only after monetization exists | NOT APPROVED FEATURES; instrument design must be reviewed first |
| 12 | **ARPU** | Average revenue per user per period | Only after monetization exists | NOT APPROVED FEATURES; never a design target on its own |
| 13 | **Monthly revenue / operating expenses / net profitability** | Money in, money out, what is left | Expenses: yes, from day one; revenue: only after monetization | Expenses include hosting, tools and any licensed content — the honest number is net |

### Instrumentation policy (pre-launch)

- **Privacy-conscious and opt-in.** No analytics is enabled by default. A first-run choice asks
  whether the player wants to share anonymous gameplay statistics; declining leaves the game fully
  playable and sends nothing.
- **No personal data, no third-party trackers at launch.** Aggregate counters only: session start,
  session end, match completed, fighter selected by stable ID, event viewed. No names, no emails, no
  advertising identifiers, no device fingerprinting, no cross-site trackers.
- **Local-first.** Completed matches, session length and fighter picks can be counted on-device and
  shown to the player, with aggregate sharing only if they opted in. This keeps the pre-launch
  numbers usable even with analytics unavailable.
- **Accounting, not surveillance.** Every KPI above is either an on-device count or an anonymous
  aggregate; nothing should be attributable to an identifiable child or adult.
- **The purchase-side KPIs (11–12) cannot be instrumented before a store exists** and must be
  designed alongside that store's privacy review, not retrofitted.

> **Notice — not legal or financial advice.** Analytics, consent and children's data collection are
> regulated (for example under privacy laws applicable where players live, and app-store policies).
> Get the consent flow and data list reviewed by a qualified professional before shipping any
> telemetry.

---

## 6. Cultural identity and IP protection

### 6.1 Authentic Jamaican sound-system and dancehall culture

The cultural foundation is the sound clash: competing sound systems, selectors, MCs, exclusive
dubplates, DJ tags, musical strategy, crowd response and intense but performative rivalry
(`artifacts/sound-clash/SOUND_CLASH_CULTURE.md`). Every business decision must protect that
authenticity rather than genericise it:

- Patois spellings are preserved verbatim and never "corrected" (`AGENTS.md` §8).
- Fighters read as sound-system personalities, not interchangeable boxers.
- Outfits, stages and events draw on real fashion and real season culture (Kangol-style hats,
  Wallabee-style shoes, mesh string vests, crew colours) **as original designs**, not as copies of a
  specific brand's product or a specific crew's identity.
- Carnival Clash content is designed with diaspora community review (§7d), not invented from outside.

### 6.2 Future licensed collaborations

Future collaborations with **real sound systems, selectors, artists, dancers, clothing brands and
events** are a legitimate long-term direction and a strong authenticity signal — but they are
**permission-first partnerships**, not free references:

- Written permission and a recorded licence before any name, likeness, logo, voice, dubplate or
  recording is used.
- Scope stated explicitly: which platform, which territory, how long, whether the web build (which
  ships extractable asset packs — see `ASSET_LICENSES.md`) is included.
- A recorded row in `ASSET_LICENSES.md` with the licence file reference, dates and expiry.
- No implied endorsement: a licensed artist appearing as a guest character is not thereby a sponsor
  of the whole game unless the contract says so.
- Real crew and sound-system names may be used as **research inspiration** only, and never in
  product-facing text as an affiliation claim.

### 6.3 Protecting original IP

The project's own assets are the long-term asset base and must be protected deliberately:

| Asset class | Protection to establish | Current state |
| --- | --- | --- |
| Original characters (Feedback, L!ckshot, L!kkle Moore and the name pool) | Trademark the game name and key character names; keep a dated design record per character | Design records exist in `AGENTS.md`/`art-source/`; **no filing recorded — OWNER TO FILL** |
| Art and animation | Keep source files, timestamps and the human-authored design decisions that produced them | Sources preserved under `art-source/`; provenance notes exist for several batches |
| Branding (logo, wordmark, UI look) | Trademark and consistent use; avoid third-party marks in the logo | No filing recorded — OWNER TO FILL |
| Music | Commission or license; keep the written grant per track | The three menu beats are owner-supplied and described as "creator-owned"; the paperwork itself is not in the repo — OWNER TO FILL |
| Code | Copyright notice and a repository licence file | **The repository has no `LICENSE` file** — OWNER TO FILL |
| Third-party licences | A single ledger with attribution and redistribution terms | `ASSET_LICENSES.md` (created 2026-11-25) records what the repo proves and flags the rest |

### 6.4 Tracking third-party licences

- `ASSET_LICENSES.md` is the ledger. Model uploads, Mixamo animations and crowd, fonts, audio,
  generated art and any future licensed content each need a row.
- The **web build ships extractable asset packs** (`docs/index.pck`), so every licence must be
  confirmed to allow redistribution in an extractable, downloadable form — not merely "use in a
  game".
- Licences expire and plans change: record the date obtained, the plan/tier used, and a review date.

> **Notice — not legal or financial advice.** Trademark, copyright, likeness, moral rights and
> licence-scope questions above require a qualified IP lawyer; this section is a checklist, not an
> opinion on your rights.

---

## 7. Co-Director recommendations (owner to approve)

> Every item in this section is a **PROPOSAL**, not an approved feature or decision. The owner
> approves, rejects or amends each one.

### (a) Music must be original, commissioned or licensed

- **Proposal:** every music bed, dubplate, DJ tag and selector yell is either **original
  (commissioned or created in-house)** or **licensed in writing**. No unlicensed commercial track,
  no "reference" clip, no streamed audio.
- **Current state:** active rounds are music-free; the 132 BPM click is synthesised; menu/victory
  beds are three owner-supplied beats described in-repo as creator-owned; all other audio is
  synthesised at runtime (no files). Real artists, sound systems and brands are **permission-first
  partnerships** — written grant first, then audio, then a ledger row.
- **Why:** a sound-clash game whose music is uncleared is legally unshippable, and dubplate culture
  is precisely about *exclusive, paid-for* versions — authenticity and legality point the same way.

> **Notice — not legal or financial advice.** Synchronisation, master-use and neighbouring rights
> for recordings are jurisdiction-specific; confirm each grant with a qualified professional.

### (b) AI-generated assets — Tripo, Meshy, Mixamo and similar

- **Facts recorded in this repo:** the three fighter bodies come from **owner uploads** (a Tripopipeline static mesh family, converted GLB→FBX), then skinned and animated through **Adobe Mixamo**;
  the crowd and DJ characters and the fighter takes are Mixamo exports; the pixel-art pose sets are
  owner-supplied and creator-approved. (See `ASSET_LICENSES.md` for the per-asset rows and the
  evidence each one rests on.)
- **Proposal:** treat the **licence of each asset as tied to the plan/tier under which it was
  generated** (free vs. paid tier, personal vs. commercial), record that tier, and re-check the
  provider's current terms before each store submission. Where a tool's free tier restricts
  commercial use, either upgrade deliberately or regenerate under a compliant plan.
- **Purely AI-generated work may have weak or uncertain copyright protection** in some
  jurisdictions. Do not rely on copyright alone for the fighters' identity: **build trademark
  protection around names and logos** (Feedback, L!ckshot, L!kkle Moore, the game name, the mark),
  and keep **human-authored design** on top of generated meshes — silhouette decisions, outfits,
  colour, posing, rigs, hand props and the cel-shaded look are human choices and should be documented
  as such in `art-source/`.
- **Ask an IP lawyer** about registrability, authorship and disclosure before filing or publishing.

> **Notice — not legal or financial advice.** AI-tool terms of service, output ownership and
> registrability vary by provider, plan and country. Verify with a qualified professional before
> commercial release.

### (c) Retention loops (proposals)

| Loop | Proposal | Why it retains | Status |
| --- | --- | --- | --- |
| **Sound-system crews** | Players join or form a crew; a crew leaderboard aggregates crew members' match results | Social accountability; a reason to return for the crew, not just yourself | PROPOSAL — no backend exists |
| **Dubplate unlocks** | Unlockable entrance music and voice lines ("dubplates") tied to character mastery and events | Cosmetic self-expression in the exact cultural idiom of the game | PROPOSAL |
| **QR-code play at community events** | A QR code at a dance, fete or community event opens a browser-first build (no install) that drops the player into a fight | Converts real-world cultural moments into new players at near-zero cost | PROPOSAL — needs hosting decision (f) |
| **Local 2P as a community engine** | Two players, one device, one screen, tuned for a phone on a table | The cheapest social feature and the strongest diaspora-party use case | Exists as local play; tuning is PROPOSAL |
| **Shareable clips** | Short auto-captured KO/finisher moments, exportable or shareable | Free distribution; the comedy is the marketing | PROPOSAL |
| **Optional PWA home-screen install** | Add-to-home-screen with an offline shell so returning is one tap | Reduces the friction that kills return visits on mobile web | PROPOSAL |

> **Notice — not legal or financial advice.** Leaderboards, UGC clips and community events involve
> privacy, moderation and (for minors) consent questions. Verify with a qualified professional.

### (d) Cultural review of Patois content and art

- **Proposal:** before any Patois line, gesture, outfit or event asset ships, a small panel of
  **diaspora community members** (Jamaican and Toronto-area, mixed ages) reviews it for accuracy,
  register, respect and comic timing — and the review is recorded with the asset.
- The owner remains the final creative approver (`AGENTS.md` §1); the panel informs, it does not
  override.
- Patois is preserved verbatim; reviewers advise on context and usage, never on "correcting"
  spelling into standard English.

> **Notice — not legal or financial advice.** Cultural consultation is not a substitute for rights
> clearance; where a line or image references a real person or group, permission is still required.

### (e) First-load size budget and on-demand pack strategy

- **Proposal:** set an explicit first-load budget (currently the web package is large: `docs/index.pck`
  is about 68.7 MB in the existing export) and move optional content — alternate outfits, event
  stages, extra selectors — into **on-demand packs** that a player downloads only when they want
  them.
- Mobile-data reality: a diaspora audience on prepaid phones will abandon a 70 MB first load.
  Fighters and one stage must fit a small first download; everything else is optional.
- Packs are namespaced under `res://content/<pack_id>/` and loaded on web by downloading to
  `user://` then `load_resource_pack` (`CONSOLE_READINESS.md`, guardrail 5). Events ship content as
  packs, never as a client rebuild.

> **Notice — not legal or financial advice.** Data-usage disclosure and app-store size limits are
> platform-policy matters; confirm current limits with the stores and a qualified professional.

### (f) Production hosting decision

- **Proposal:** choose the production host deliberately, because it constrains distribution.
  Godot's threaded Web export requires **special HTTP response headers** (cross-origin isolation:
  `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`) to enable
  `SharedArrayBuffer`-backed threading. **GitHub Pages cannot set those headers**, so a threaded
  build cannot be served from Pages as-is; a single-threaded export avoids the requirement at a
  performance cost.
- Options to evaluate: a host that allows custom headers, a self-managed static host behind a CDN
  with header rules, or shipping the single-threaded build on Pages initially and moving later.
- Whatever is chosen, the build must stay playable on a Chromebook and iPhone Safari at the
  documented target, and the choice must be recorded in `AGENTS.md` before launch.

> **Notice — not legal or financial advice.** Hosting terms, bandwidth costs and store distribution
> agreements should be reviewed before committing to a provider.

---

## 8. Open questions

### For the owner

1. Which of the twelve revenue streams (§3) is the **first** to be researched seriously, and is
   free-to-play with optional cosmetics confirmed as the direction?
2. Does "Carnival Clash" become the permanent flagship name, and are the three lighter anchors'
   working names acceptable?
3. Who sits on the diaspora cultural review panel (§7d), and how are reviews recorded?
4. Which host is chosen for production (§7f), and is a threaded or single-threaded web build the
   launch target?
5. Is there an existing trademark, business entity or brand registration to build on?
6. Are the three menu beats' ownership documents available to record in `ASSET_LICENSES.md`?
7. Which platform is the April 2027 launch target (web, Android, desktop), and does that change the
   first-load budget?
8. What is the acceptable operating expense ceiling per month (hosting, tools, licensed content)?

### For a lawyer

1. **Trademark filing in Canada and the United States**: which marks (game name, logo, key character
   names) should be filed, in which classes, and in what order given a limited budget?
2. **Licensing**: what must a licence grant contain for a guest character, a real sound system's
   name, a dubplate, a voice line or a real-world brand, to cover a web build whose asset pack is
   downloadable and extractable?
3. **Children's privacy**: if the game is played by under-13s (likely on shared family phones), what
   consent, data-minimisation and store-rating obligations apply — and does an opt-in anonymous
   analytics counter change that?
4. **AI-asset ownership**: what is protectable in the Tripo/Mixamo-derived fighter bodies, what
   should be claimed as human authorship (design, rigging choices, cel shader, outfits), and what
   must be disclosed on store listings?
5. **Consumer protection and advertising**: what claims ("free-to-play", "no pay-to-win", event
   promotions) need substantiation, and what disclosure do sponsorships and rewarded ads require?
6. **Music rights**: what synchronisation/master grants are needed for commissioned beats,
   dubplates and any licensed recording, including for trailers and shareable clips?

> **Notice — not legal or financial advice.** These questions exist to structure a professional
> consultation. Verify every answer with a qualified lawyer and accountant in the relevant
> jurisdiction before acting.

---

*Documentation only. No feature code, store, payment flow, account system, ad unit or monetization
UI exists in this repository, and this document does not authorize building any of them.*

# Feedback appearance consistency — review build and per-pose verdicts

Date: 2026-11-13. Reviewer: Freebuff (inspection only). Owner and final visual approver:
**Garfield Connell**.
Status: **not approved.** No pose pack file was regenerated, repainted or overwritten. No combat,
collision or simulation code was touched. No credits were spent.

This document is the working companion to
`APPEARANCE-CONSISTENCY-AUDIT-2026-11-13.md` (the ChatGPT audit). That audit recorded what the
pack contains; this one adds a side-by-side review tool, an individual verdict for each of the 17
poses, and the exact list of media that is still missing from the repository.

## 1. Where this work lives

| Item | Value |
| --- | --- |
| Repository | `Geefense/Sound-Clash-Brawl-Lab` |
| Branch | `review/feedback-appearance-consistency`, fast-forwarded to the owner's `1f33780` (which delivered the approved walk transfer package); started from `feat/combat-animation-refinement` @ `6d09175` so the pack and its renderer are present |
| Blueprint and audit source | Lab `main` @ `be7367dd84981b520e63192c190446de7b437c5c`, restored into the worktree with `git restore --source=be7367d --worktree -- AGENTS.md artifacts/sound-clash/art-source/feedback`. No branch switch, no reset, nothing local overwritten. |
| Uncommitted work preserved | `artifacts/integration-plan.md`, `artifacts/lab-patches/`, `artifacts/playtest-*.png`, `artifacts/feedback-final.png` — left untouched and out of the commit |

The April 21, 2027 launch plan in `AGENTS.md` was read, not modified. No Godot work, no gameplay
features, no roster or scope change.

## 2. The review preview

**URL (dev server):** `/review/appearance.html`
**Cloud preview:** `https://pv-d924746c0cb9-aaa73364-fe60-45e9-a11f-853ab7528005.style.dev/review/appearance.html`

On the Chromebook:

```bash
git fetch origin
git switch review/feedback-appearance-consistency     # after this branch is pushed
pnpm install --frozen-lockfile
pnpm --filter @workspace/sound-clash run dev          # or: cd artifacts/sound-clash && pnpm dev
# then open http://localhost:5173/review/appearance.html
```

What it does:

- Sequence: `01_idle` → four walk keys → `12_backhand_windup` → `13_box_palm` →
  `14_followthrough` → `08_block` → `16_gut_punch` → `17_seated_landing` → `02_knockout`.
- **Pause**, **prev/next** stepping, hold time 0.5/0.8/1.2/2 s, clickable step strip, keyboard
  `←`/`→`/`space`, and a scale slider (0.14–0.52) so the same frames can be judged at gameplay
  size as well as review size.
- **Side-by-side against the existing idle**: the right pane is always `01_idle` at the same
  scale, origin and floor line. An optional idle ghost (22% alpha) is drawn under the current
  pose for silhouette comparison.
- Anchor overlay toggle, floor line (`y900`) and pelvis line (`y610`) guides.
- Per-pose verdict panel with one check row each for mic hand, cable route, hat/locks,
  face/tooth, build/trousers, Wallabees and alpha edges, each with the specific observation.
- A separate **“Approved movement reference — appearance pending”** block (see section 9): the restored four-pose
  132 BPM keys played on the manifest's own hold counts (27/28/27/27 at 60 fps) with its own
  pause/step controls, plus the recorded MP4. The older four-key study stays in the main sequence,
  relabelled **OLDER STUDY**, so the two can never be mistaken for each other.

Anchors are respected, not invented: the page fetches `feedback.poses.json` and pivots every image
on that pose's own `origin`/`anchorPx`. Feet and ground-contact poses pin `[768, 900]` to the floor
line; pelvis poses pin `[768, 610]` to a pelvis line held 290 canvas px above the floor. **One
display scale is used for every pose** — no figure is independently resized to hide a difference.
The walk keys are a different canvas (460 × 620, sole at y = 566) and get their own single shared
alignment, labelled as outside the pack.

Nothing on the page feeds combat: it is static files under `public/review/` plus the unchanged
`src/` game. Collision, hitboxes and `SimulationEngine` are untouched.

## 3. How the verdicts were reached

- All 17 aligned PNGs inspected at full 1536 × 1024, then as 2×–2.5× crops of the hands, faces,
  cable terminals and shoes.
- The approved crossed-arms idle (`feedback-crossed-arms-approved.jpeg`, mic in right hand,
  three-loop wrist coil, no trailing tail) was used as the comparison baseline, not as proof that
  every pack pose matches it.
- Objective alpha/edge measurements per file: connected components above 50 px, stray pixels,
  and the share of soft-alpha edge. Every pose is a single component with 0–17 stray pixels, which alone cannot prove the absence of trapped background or a connected duplicate detail.
  Visual inspection is also required. Soft edges
  sit at 3.8–5.4%.
- Limits: the review is visual and per-frame. It cannot prove anatomy under occlusion, and a
  concealed face means the tooth is unverifiable rather than passing.

## 4. Per-pose verdicts

`pass` = the named requirement holds; `fail` = a specific, visible violation; `uncertain` = the
evidence does not settle it. The per-pose cable review records **16 failures and one uncertain
case (04_inverted_c)**, so the pack is not approved as a set.

| # | Pose | Verdict | Failed checks (evidence) |
| --- | --- | --- | --- |
| 01 | `01_idle` | **fail** | Cable: coil leaves the wrist, crosses the hip, hangs past the knee, ends as a bare strand on the floor — no jacket entry. Hat: narrower brim / shorter crown than the approved reference. |
| 02 | `02_knockout` | **fail** | Cable lies along the floor in a long loop. Trousers read light grey and baggy, not the fitted charcoal. Boots have a heel counter and thin pale sole. |
| 03 | `03_c_recoil` | **fail** | Cable terminates mid-body near the free hand, no plug, no jacket entry. Mic hand unreadable at the chest centre. |
| 04 | `04_inverted_c` | **uncertain** | Cable wraps the hip/thigh and its terminal is hidden behind the body — continuity cannot be confirmed or denied. Tooth unreadable inverted. |
| 05 | `05_dizzy_bogle` | **fail** | Cable drops behind the rear boot into a bare floor loop. |
| 06 | `06_rear_salute` | **fail** | Cable drapes across the back and falls to a wide flat coil on the floor behind the feet. |
| 07 | `07_crouch` | **fail** | Cable loops beside the planted boot. Hat hides the whole face, so the tooth cannot be signed off. |
| 08 | `08_block` | **fail** | Cable hangs to the floor beside the boot. Hat crown is taller than the idle hat in the adjacent frame. |
| 09 | `09_point` | **fail** | Cable trails to the floor behind the rear foot and ends in a bare loop. Everything else passes. |
| 10 | `10_fire_airborne` | **fail** | Cable ends mid-air below the hip with no plug and no jacket entry. |
| 11 | `11_fire_grounded` | **fail** | Cable reaches the floor and coils beside the forward boot. |
| 12 | `12_backhand_windup` | **fail** | Cable trails across the ground behind the rear boot. Torso is drawn from behind (no zipper tape) while the head holds a right-facing profile, so the cocked near arm is raised and the mic sits in the far hand — the opposite reading from contact/recovery. Hat brim/crown differ from the contact frame. Shoe larger with a paler sole. |
| 13 | `13_box_palm` | **fail** | Cable loops around the rear boot. Gold reads as a band across two to three teeth. Hat crown tall / brim narrow, opposite drift to the windup. Broad shoulders and heavy pale sole with a dark midsole line. |
| 14 | `14_followthrough` | **fail** | Cable falls to the floor and loops left of the lead boot. Hat proportions differ again from windup and contact. |
| 15 | `15_skank` | **fail** | Cable curls with a free end floating above the floor. |
| 16 | `16_gut_punch` | **fail** | Cable ends in a loop floating below the boot. Slouchy bucket hat with a different band. Stocky, short-legged build against the slim idle. Orange bulbous boots. |
| 17 | `17_seated_landing` | **fail** | Cable hangs past the hip and curls with a floating end away from any jacket seam. Very wide brim. Rounded toe and thin sole. |

Tallies: **16 fail, 1 uncertain, 0 pass.**

## 5. Cross-pose failures, consolidated

1. **Cable origin — 16 fail, 1 uncertain.** Sixteen frames show an unconnected/floor-trailing
   route; 04_inverted_c hides its terminal, so jacket continuity is unverified, not disproven.
   The forearm wrap is present and consistent in 01, 08, 09, 13, 14, 15 — the break is always
   *after* the wrap. This is the single largest defect and it is systemic, not per-pose drift.
2. **Mic hand — 13 pass, 3 uncertain, 1 contradicted by its neighbours.** One mic in every frame,
   carried by the near/right hand with the back of the hand to camera, matching the four-key rule
   and the approved idle. `12_backhand_windup` is the exception: its torso is drawn from behind,
   so the mic reads in the far/left hand while the cocking arm is the near/right. Windup, contact
   and recovery therefore do not demonstrably share one anatomical mic hand.
3. **Hat / dreadlocks — drift in 7 frames.** Brim width and crown height vary enough to change the
   silhouette: 01 (narrow, short) vs 13 (tall, narrow) vs 16 (slouchy, different band) vs 17 (very
   wide). Locks also thin out in 01 against the approved reference's thick cylindrical locks.
4. **Face / gold tooth — 1 fail, 7 uncertain.** `13_box_palm` shows a gold band across multiple
   teeth. Concealed faces in 04, 07, 10, 16, 17 and profiles in 02, 03 make the tooth count
   unverifiable, so it cannot be marked passed.
5. **Build and trousers — fails in 02 and 16; drift in 12–14.** The hurt frame is drawn on a
   heavier, shorter body with a different trouser; the KO frame wears a baggy light-grey trouser;
   the BOX trio broadens the shoulders and flares the trouser over the shoe.
6. **Wallabees — 4 fails / 3 uncertain.** 02, 16, 17 and 13 depart from the apron-seam
   moccasin with the pale crepe sole (heel counter, orange bulbous toe, rounded thin sole, heavy
   midsole line respectively).
7. **Alpha and edges — pass in all 17.** Single connected figure per file, 0–17 stray pixels,
   no obvious trapped background or duplicate prop reported in this inspection. Component counts
   alone do not certify those details; targeted visual QA remains required.

## 6. Missing assets — exact status

Present in this repository:

- `art-source/feedback/chat-movement-transfer-2026-11-13/movement-reference/` — **the owner-approved
  four-pose 132 BPM movement reference**, restored 2026-11-13 from the transfer package (section 9).
  Movement approved; appearance still pending.
- `art-source/feedback/feedback-walk-flow-test.mp4` — earlier Flow idle→walk test;
  `walk-video-review/` holds its contact sheets and inspection report.
- `art-source/feedback/walk-cycle-preview/` — 35 extracted frames + loop player + unapproved
  loop MP4, derived from that same clip.
- `art-source/feedback/walk-four-keys/` — the four-key study used in the preview
  (`poses/01_contact_a.png` … `04_pass_b.png`), comparison/splice material, `candidates/`.
- `art-source/feedback/walk-video-transfer/` — base64 parts of the existing MP4.

**Not in the repository at any ref** (checked with `git log --all --name-only`):

- the **rejected neutral-arm return pose** — deliberately excluded from the delivered reference, so
  the rejection cannot be evidenced from a file; that is by design, not a gap;
- the newer **ChatGPT-generated walk and correction images** from the 2026-11-13 chat;
- the **gold-tooth correction** images (and any note establishing exactly one tooth);
- the **moccasin / Wallabee correction** candidate;
- the **jacket-entry cable correction**, including the pending new idle candidate;
- any video or GIF produced in that chat session.

Separately, `walk-four-keys/poses/04_pass_b_corrected.png` appears in history (commits `0eb3816`,
`8fd3c01`) but exists in **no branch tree**, so it is not available for review either. The older
eight-key walk (`forward-test/walk-preview/`, 8 keys + MP4) exists only on
`feature/feedback-forward-walk-test` and is not in this worktree; it is a different, earlier
experiment and was deliberately **not** substituted for the approved reference.

## 7. The smallest next correction

Do not regenerate the pack. Repair the cable terminal only, in this order:

1. **`01_idle` first**, as a versioned candidate beside the original: keep the existing character,
   hat, trousers and shoes untouched; keep the forearm coil; end the cord at the jacket hem /
   lower front seam, entering behind the fabric so the entry is occluded but spatially plausible.
   No pocket, no dangling plug, no floor contact. Compare original vs candidate at full size and
   at 0.44 gameplay scale on the same anchor.
2. **Then propagate that exact terminal** to the other 16 frames — one drawing decision applied 16
   times, not 17 separate inventions. The wrap segment is already consistent, so only the run from
   wrap to jacket changes.
3. Only after Garfield approves the idle candidate: fix `12_backhand_windup`'s back-facing torso
   (mic hand), then the hat silhouette, then the gold tooth in `13_box_palm`, then the 02/16/17
   shoe and build drift. Each as a narrow candidate, before/after in this preview.

That order is deliberately smallest-first: one cable decision unblocks the entire set, while the
hat/shoe/build work is per-frame and should follow the approved reference.

## 8. Checks actually run

- `node --check` on `review-data.js` and `appearance.js`; all preview files return HTTP 200 from
  the dev server (`/review/appearance.html`, CSS, JS, walk PNGs, manifest, pose PNGs).
- Browser load of the preview page: title correct, 12 steps built, both canvases painted
  (14,097 and 11,633 non-transparent pixels), 7 check rows for the current pose, step buttons
  switch pose and verdict, pause/step work, no page errors.
- `vite build` after the review files were added (public assets ship unchanged).
- Existing test suite and typecheck were not re-run for this change: no `src/` file, test or
  config was modified. That is a deliberate scope limit, not a skipped result.
- Movement-reference import and page checks are recorded in section 9.

## 9. Approved movement reference — restored and wired in (2026-11-13, second pass)

Branch fast-forwarded from `8b2b359` to the owner's `1f33780`; local untracked work preserved, no
reset, no unrelated branch merged. The transfer directory
`art-source/feedback/chat-movement-transfer-2026-11-13/` was read, then its importer run from the
repository root:

```bash
python3 artifacts/sound-clash/art-source/feedback/chat-movement-transfer-2026-11-13/restore_movement_reference.py --check-only
python3 artifacts/sound-clash/art-source/feedback/chat-movement-transfer-2026-11-13/restore_movement_reference.py
```

| Step | Result |
| --- | --- |
| `--check-only` | `CHECK PASSED: archive + 5 media hashes; 6 safe entries. No files written.` (exit 0) |
| restore | `RESTORED …/movement-reference` · `6 files verified` (exit 0) |
| Archive SHA-256 | `88a55337…7447`, matches the value in the README |
| Re-hashed on disk | all five media digests match `reference-manifest.json` exactly |
| Side effects | source poses, `public/assets/feedback/`, runtime and gameplay untouched |

Restored content: `01_contact_a.webp`, `02_pass_a.webp`, `03_contact_b.webp`,
`04_pass_b_rear_arm.png`, `Feedback_Walk_132BPM_Preferred.mp4`, `reference-manifest.json`.
Timing from the manifest: 109 frames/cycle at 60 fps, holds 27 / 28 / 27 / 27, **132.11 BPM**.

Two factual notes recorded while wiring it up, neither corrected:

1. **Sole height under the recorded placement.** Measured support soles in the 460 × 620 panel are
   571 / 572 / 571 px for keys 1–3. Key 4 is a 1080 × 1456 image placed at (9, 1) at 455 × 613 as
   the manifest directs, which puts its sole at ≈566 — about 5 px high relative to the others. The
   manifest says to follow the recorded placement rather than a guessed per-pose fit, so that is
   what the page does, and the 5 px is left visible rather than hidden.
2. **Inline video playback works, but metadata is slow to arrive.** The clip is a valid MP4
   (`ftyp isom`, `moov` + `mdat` present, 346,253 bytes, 10.9 s = six 109-frame cycles) served with
   `206 Partial Content` range support. In the cloud preview the element took longer than 2.5 s to
   reach metadata, which made an early timeout report a false failure; it then loaded and played.
   Verified: `readyState 4`, duration 10.900 s, 460 × 620, and `currentTime` advanced 0.90 s over
   0.90 s of wall clock while playing. The page now waits 8 s before showing its “did not load
   inline” fallback and clears that message as soon as metadata arrives, so a slow first load cannot
   masquerade as a broken clip.

Not treated as approval: the movement reference is owner-approved **as movement**. Cable, one gold
tooth, Wallabee construction and slim proportions remain open, and the rejected neutral-arm return
pose is absent by design.

## 10. What this review does not claim

- It does not approve appearance, and it does not approve the four-key movement test (its own
  note records unapproved timing, no arm counter-swing and a non-closing loop).
- It does not resolve handedness by mirroring. The pack README warns that mirroring flips the
  microphone handedness; nothing was mirrored.
- It does not claim the missing generated material exists. Those files must be delivered before
  the approved movement reference and any appearance correction can be reviewed against it.

## 11. Cable correction candidate — `01_idle` (awaiting Garfield's visual approval)

One candidate, one pose. Nothing here is applied to the pack, the other sixteen poses, the
simulation, collision data or the Godot project.

| | |
| --- | --- |
| Original (never written) | `public/assets/feedback/aligned/01_idle.png` — sha256 `d2e47bb7…3dbdf2` |
| Candidate v1 | `public/review/appearance/cable/01_idle-jacket-entry-v1.png` — sha256 `5390f116…4a9ad9` |
| Sanitised source copy | `art-source/feedback/cable-candidates/01_idle-jacket-entry-v1.png` |
| Diff view | `art-source/feedback/cable-candidates/diff-original-vs-v1.png` |
| Changed-region data | `art-source/feedback/cable-candidates/diff-regions.json` |
| Repeatable builder | `art-source/feedback/cable-candidates/build_idle_cable_candidate.py` |

**What was done.** Below the forearm wrap the mic cable hangs free of the garment, so it could be
removed as *silhouette runs* rather than by colour: every row from `y 632` down keeps only the
figure's own runs, and the floor loop is found as the thin structure a 13 px opening of the boot
cannot explain. That leaves the cord's cut end at the wrap, and a short anti-aliased stroke
(4-bit supersampled, cord colour sampled from the removed cable) carries it across the jacket and
under the ribbed hem's bottom edge at `y ≈ 648`, above the cream waistband. The original hem
pixels are pasted back over the stroke's tip, so it reads as passing behind the fabric instead of
stopping on it.

**Checks actually run**

- `python3 build_idle_cable_candidate.py` → `changed pixels: 2226 in 1 regions`, bbox
  `[622, 619, 732, 892]`; the builder aborts if anything above `y 610` changes.
- Independent comparison of original vs candidate: `changed px 2226`, bbox
  `[622, 619, 732, 892]`, **0** changed pixels above `y 610`, **0** right of `x 745`; every
  opaque pixel outside that region is identical.
- `node --check public/review/appearance/appearance.js` → clean; `vite build` → exit 0.
- Original's sha256 is recorded above and its file is unmodified (`git status` clean for the path).

**Deliberately unchanged:** mic, hand, wrist coil, hat, face, dreads, jacket body, cream
waistband, trousers, Clarks and the whole right half of the canvas. No plug body, no pocket route,
no glow, no background was added. Pose `04_knockout`'s uncertain status and the rejected modern
neutral-arm pose are unaffected; the sixteen other poses were not touched.

**How Garfield reviews it:** the preview page's section *Cable correction candidate v1 — 01_idle*
draws original and candidate through the same anchor and origin (`[768, 900]`, `0.5, 0.87890625`)
at one shared scale, with a difference view and the changed-region table. The five-pixel walk
alignment issue stays a separate recorded item (§9) and is **not** concealed by any rescale here.

Not approval. Candidate v1 awaits the owner's verdict; if rejected, the next candidate gets a new
version suffix rather than overwriting this one.

## 12. Cable correction candidate v2 — entry refined, removal preserved

v1's cable-tail and floor-loop removal stays exactly as it was. v2 rebuilds only the drawn
wrap-to-jacket segment, which read as a flat dark strip next to the pack's rounded cord.

| | |
| --- | --- |
| Candidate v2 | `art-source/feedback/cable-candidates/01_idle-jacket-entry-v2.png` (served from `public/review/appearance/cable/`) |
| v1 (kept, untouched) | `01_idle-jacket-entry-v1.png` |
| v1 vs v2 diff | `diff-v1-vs-v2.png` · `diff-v1-vs-v2.json` |
| Builder | `build_idle_cable_v2.py` — reads the original and v1, never writes either |

**What changed.** The stroke now follows the cord's measured section: a 1 px dark outline, a
3 px mid body and a one-pixel highlight on the lit side, sampled from the original cable at
`y 700` where the free cord crosses its own outline (values ≈ 1 / 35-69 / 30 / 1 across five
pixels). The path leaves the wrap vertically, as the original cord does, then curves under the
hem's lower corner; the hem's own edge and shadow are pasted back over the tip, so the jacket
occludes it instead of the stroke stopping on the fabric.

**Checks actually run**

- `python3 build_idle_cable_v2.py` → `v1 vs v2 changed pixels: 388 in 1 regions`, bbox
  `[698, 617, 732, 654]`: 387 px in the listed region plus one pixel at `(725, 654)` that v1 left
  with alpha 1 and v2 with alpha 1 at a different channel value — invisible, and below the
  4-pixel region threshold. The builder aborts unless its rebuilt removal base matches v1 exactly
  outside the entry box, and unless v2 changes nothing outside that box; an independent check
  confirms 0 differing pixels anywhere outside it.
- v1's file, the original, the floor-loop removal, the jacket, waistband, trousers and Clarks
  therefore carry identical bytes in both candidates.
- `node --check public/review/appearance/appearance.js` → clean; `vite build` → exit 0.

**Shown for approval:** v1 against v2 at source resolution (1:1), enlarged, and gameplay size
(0.44), plus the v1-vs-v2 difference map and its region list, in the new preview section
*Cable correction candidate v2 — 01_idle entry refined*. Not applied to any other pose, and not
to the pack, runtime or gameplay.

## 13. Cable batch — `08_block`, `12_backhand_windup`, `13_box_palm`, `14_followthrough`

The approved idle-v1 treatment, applied one pose at a time. Each candidate loses only its trailing
cable; nothing is drawn, no connector or route is added, and the cord simply stops where a
jacket, trouser leg or wrist wrap is in the way.

| pose | original (sha256 prefix) | candidate | removed | bbox | cut |
| --- | --- | --- | --- | --- | --- |
| `08_block` | `50856507…` | `08_block-cable-v1.png` | 1 863 px | `[592, 634, 700, 895]` | hem, y 634 |
| `12_backhand_windup` | `6532d778…` | `12_backhand_windup-cable-v1.png` | 2 035 px | `[855, 660, 1013, 898]` | right thigh, y 660 |
| `13_box_palm` | `40fd81c2…` | `13_box_palm-cable-v1.png` | 2 223 px | `[498, 642, 683, 886]` | hem, y 642 |
| `14_followthrough` | `83345247…` | `14_followthrough-cable-v1.png` | 2 419 px | `[479, 667, 619, 892]` | past the wrist wrap, y 667 |

Files: candidates, per-pose difference maps and region JSON under
`public/review/appearance/cable/batch/`, with the untracked working copies in
`art-source/feedback/cable-candidates/`. One builder, `build_cable_batch.py`, produces all four
from the untouched originals.

**Method.** In the corridor below each pose's cut line, the cable is whatever the figure's own
solid mass and thin rims (garment outlines, wrap rings, laces) do not explain. The builder aborts
if anything changes above the cut or outside the corridor, which is how the body, hands, hat,
face, trousers and Clarks keep their exact pixels. Anchors are untouched: all four keep the
manifest's `[768, 900]` on the 1536×1024 canvas.

**Checks actually run**

- `python3 build_cable_batch.py` → the four counts and bboxes above, every guard passing.
- Pack untouched: `git status` clean for `public/assets/feedback/`, and the four originals' hashes
  are recorded above.
- `node --check public/review/appearance/appearance.js` → clean; `vite build` → exit 0.
- Page: all four comparison images and the BOX GIF load, difference views open, no console errors.

**Recorded separately, not repaired here:** the mic hand and other appearance differences between
these keys are unchanged by this pass; cross-set handedness is still the open item in §5. In `12`
and `14` the remaining cord end sits in open air near the connector, because those poses have no
garment at that point — that is a limit of the concealed treatment in these two keys, not an
occlusion, and it is the main thing to judge in review.

Not applied to the other twelve poses. No gameplay, collision, manifest or Godot change.

## 14. Cable batch v2 — BOX endpoints (`12_backhand_windup`, `14_followthrough`)

v1 removed each pose's floor tail but left the cable ending in open air. v2 keeps v1 byte-for-byte
except for one short connection per pose, drawn at the cable's own section and then covered by the
occluder's own pixels at its tip, so the lead disappears behind something already in the drawing.

| pose | connection | changed | removed | added | bbox |
| --- | --- | --- | --- | --- | --- |
| `12_backhand_windup` | plug mouth → under the sleeve cuff, 24 px | 372 px | 0 | 215 px | `[839, 630, 865, 669]` |
| `14_followthrough` | last 46 px of hang deleted, loop back behind the forearm wrap | 1 370 px | 373 px | 763 px | `[603, 582, 661, 689]` |

No route crosses the body. 12's cuff is 8 px from the plug's left edge; 14's wrap ring is 20 px
from the hang. `08_block` (`f4f2b9fc…`) and `13_box_palm` (`116e1abf…`) candidates are unchanged,
and all four originals still match the hashes in §13.

**Guards.** The same builder invariant applies: relative to v1, nothing may change outside the
connection box (and, for 14, the deleted hang). v1's floor-tail removal is carried over, never
redrawn. Anchors stay `[768, 900]` on 1536×1024.

**Checks actually run.** `python3 build_cable_v2_box.py` → the counts above, both guards passing;
`make_v2_review_assets.py` → close-ups, gameplay comparisons, stacked BOX strip and
`box-sequence-v2.gif`; pack `git status` clean and originals hash-identical; `node --check` and
`vite build` clean; every asset on the review page loads.

**Trade-offs to judge, not hidden.** 12's connection is a short visible stroke beside the sleeve;
14's loop changes the wrist silhouette from a straight hang to a looped one. Neither is hidden
behind the mic body or the trousers, and both were built only because the pack has no closer
occluder in those two keys. Handedness and other appearance differences remain recorded, not
repaired.

Not applied to the other fourteen poses. No gameplay, collision, manifest or Godot change.

## Follow-up clarification — November 13, 2026

ChatGPT verified this saved handoff and corrected the cable summary to preserve pose 04's uncertain status. The 132 BPM approved movement reference and its exact four source keys exist in the chat workspace; delivery to this branch is pending explicit owner authorization after automatic upload review blocked the media transfer. Do not substitute the older four keys or mark the newer appearance approved. The added neutral-arm return pose remains rejected. Latest main AGENTS.md also includes the owner's requested Spriteriffic team/asset/grid rules; these are documentation updates, not proof of completed animation generation.

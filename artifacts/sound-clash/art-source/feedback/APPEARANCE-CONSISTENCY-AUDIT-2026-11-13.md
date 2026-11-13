# Feedback appearance consistency — audit and Freebuff handoff
Date: November 13, 2026. Owner/final visual approver: Garfield Connell.

## Evidence and status
Inspected all 17 aligned PNGs retrieved from `assets/feedback-transparent-poses` in `Geefense/Sound-Clash-Brawl-Lab`, plus enlarged views of idle, guard, BOX startup/contact/recovery and knockout. All 17 decoded at 1536x1024. This verifies readable source files, not final approval or smooth transitions. Originals are unchanged.

Source directory: `artifacts/sound-clash/public/assets/feedback/aligned/`.
Source metadata: `feedback.poses.json` and `README.md` in the parent directory.
The pack is not on inspected main; do not interpret a main-path 404 as lost artwork.

## Actual findings
- Stored idle `01_idle.png` is a useful starting reference for the existing slim silhouette, fitted trousers and recognizable Wallabee apron seams/crepe soles. This is a working reference recommendation, not a new owner approval.
- Several existing poses visibly carry long trailing/pooling floor cables, including idle, block, BOX windup/contact/recovery, knockout and seated landing. These conflict with the owner's clarified jacket-origin setup.
- Airborne/recoil/rear-facing cable paths require close individual tracing. Do not invent a jacket connection where it cannot be seen.
- The current walk uses a shorter cord with a dangling connector. It also fails the jacket-origin requirement.
- Walk variants drifted toward structured boot soles and a narrower torso. Later moccasin corrections are candidates, not automatically consistent with all original shoes.
- Generated tooth corrections still show excess gold. Their filenames do not establish exactly one gold tooth.
- The three BOX poses have strongly different body/arm orientations. Confirm anatomical mic hand through the full sequence; no automatic mirrored fix.
- This review is a first visual inventory, not a certified every-detail pass for each image.

## Locked owner requirements
One recognizable slim Feedback with fitted/slim trousers throughout idle, walk, attacks, defence, hurt, falling and KO. Preserve consistent hat, dreadlocks, concealed eyes, face, skin palette, jacket stripes, Wallabee construction/size and single gold tooth. Cable comes from INSIDE THE JACKET: a continuous mic-to-established-wrap-to-jacket route. No loose disconnected plug, missing mic, doubled cable or unexplained reappearance. Keep wrap configuration stable or explicitly animate unwrapping. Do not route into trousers pockets.

Owner approved four-pose swing–bop movement at approx 132 BPM, including the rear free-arm swing and larger shoes as movement direction. Neutral return in-between was rejected for limp-looking arm/rushed timing. Appearance remains pending. Preserve approved cadence while repairing art.

## Freebuff: next concrete work
1. Inspect local branch/status and AGENTS.md. Preserve uncommitted work. Identify whether the 17-pose pack is already present locally; reference its named asset branch without merging unrelated work.
2. Work on an isolated appearance-review branch. Keep original raw/aligned images immutable.
3. Build a review-only scene/page with ORIGINAL idle, walk, BOX startup/contact/recovery, guard, hurt and KO at consistent anchors, with step-through and readable pose names. Render-origin changes must not change collision logic.
4. Record per-pose pass/fail/uncertain for mic hand, cable origin/wrap, hat/face/tooth, torso/limbs/pants, Wallabees and alpha edges. Mark unseen anatomy uncertain.
5. Prototype the cable-only jacket-entry correction on idle first. Preserve the existing character/shoes. Compare original/candidate at full and gameplay size. New generated idle candidate from ChatGPT is pending review and not yet committed here.
6. Once owner approves the reference setup, apply narrow repairs only to affected frames and show transitions. Do not bulk-regenerate the whole pack to fit a new candidate.
7. Consider a separate render-only cable layer if it improves continuity; do not let it alter deterministic combat, and remove the baked duplicate only in versioned candidate art. This is an implementation option, not a settled owner decision.
8. Run relevant existing checks only for code actually changed. Report repository, branch, commit, changed files, actual checks and unresolved art issues.

No Godot installation is needed to complete this comparison. The Chromebook is available for Freebuff inspection/testing; Godot can be installed later when useful. No code or PNG was changed by this audit document.

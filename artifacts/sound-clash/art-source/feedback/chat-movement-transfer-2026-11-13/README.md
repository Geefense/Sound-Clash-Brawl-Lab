# Approved Feedback walk movement reference — November 13, 2026

**Owner-approved movement reference; appearance NOT final.** Uploaded with Garfield's explicit authorization in ChatGPT. No new generation or paid action is needed.

Repository: Geefense/Sound-Clash-Brawl-Lab
Branch: review/feedback-appearance-consistency
Importer commit: e11aa45606c95fb3dc65256172f0324120d829bd

## Restore locally

From repository root:

```bash
python3 artifacts/sound-clash/art-source/feedback/chat-movement-transfer-2026-11-13/restore_movement_reference.py --check-only
python3 artifacts/sound-clash/art-source/feedback/chat-movement-transfer-2026-11-13/restore_movement_reference.py
```

The importer reads four base64 parts beside itself, validates the archive and five media hashes, then writes six files under the sibling `movement-reference/` directory. Standard-library Python only. Existing differing files cause an error before any restored file is written; identical files are preserved. Source poses, runtime, public assets and gameplay are untouched.

Restored files:
- 01_contact_a.webp
- 02_pass_a.webp
- 03_contact_b.webp
- 04_pass_b_rear_arm.png
- Feedback_Walk_132BPM_Preferred.mp4
- reference-manifest.json

The first three keys are the original embedded preview images; fourth is the generated rear-arm swing pose. Dimensions differ deliberately; follow the recorded preview placement, not a guessed per-pose fit. 109 frames per cycle at 60 fps, holds [27,28,27,27], approximately 132.11 BPM. The manifest records image placement and individual SHA-256 values.

Archive SHA-256: 88a553374f253e8d8298f1f6cb674a8166a888734d45fb5dc2bd0c03f299f747

## Freebuff next action

Preserve local work; fetch the review branch and integrate this transfer directory without resetting the worktree or merging unrelated branches. Run the importer checks and restore. Add a clearly labelled APPROVED MOVEMENT / APPEARANCE PENDING comparison to the review page, keeping the older four-key study separately labelled. Do not treat older walk poses as this reference.

Current appearance repairs remain pending: jacket-connected cord, consistent slim body/fitted pants, approved Wallabee construction/size, exactly one gold tooth. Do not propagate the dangling plug or floor cable into final art. The rejected neutral-arm return pose is intentionally not included. Other unsuccessful shoe/tooth/cable generated candidates are not included.

Next art task remains cable-only idle candidate beside the untouched original, for owner review. Do not regenerate the pack. An occluded cable terminal is uncertain, not proof of failure; alpha component counts do not prove no trapped backgrounds. Follow current AGENTS.md including Spriteriffic role/asset/grid requirements.

## Validation performed in ChatGPT workspace

Package hash and five media hashes verified. Importer check-only, restore, identical rerun, and differing-file protection passed. All four GitHub part contents and the importer were read back and matched exactly. This does not claim the importer has run in Freebuff or that its preview has been updated.

GitHub connector supports text writes, so the binary media is delivered losslessly as a bounded transfer package. Once restored and committed locally through Git, keep one authoritative binary set and retire transfer chunks only in an explicit later cleanup.

# Feedback walk test — reconstruction and movement inspection

Status: **unapproved movement test. Not integrated into gameplay. No world/game code touched.**
Reviewed: 2026-11-12

## 1. Asset identity and integrity

| Property | Value |
| --- | --- |
| File | `artifacts/sound-clash/art-source/feedback/feedback-walk-flow-test.mp4` |
| Size | 3,695,350 bytes |
| SHA-256 | `7c644df616db66b7a3bd7747ddf27f65479e156cf2a869bd11598f74e8794011` |
| Container | MP4 (`mov,mp4,m4a,3gp,3g2,mj2`) |
| Duration | 7.933333 s |
| Video | H.264, 910×512, yuv420p, 30/1 fps, 238 frames |
| Audio | AAC, 374 frames, 7.928 s |
| Bitrate | 3,726,403 b/s |

The file was reconstructed from the 19 committed base64 transfer parts by
`Feedback_Walk_Video_Import.py`. The importer validates size and SHA-256 before
writing and refuses to overwrite a different existing file. The written file
matches the expected size and digest exactly, so this is byte-identical to the
source walk test rather than a re-encode.

Reproduce:

```bash
python3 Feedback_Walk_Video_Import.py
sha256sum artifacts/sound-clash/art-source/feedback/feedback-walk-flow-test.mp4
# 7c644df616db66b7a3bd7747ddf27f65479e156cf2a869bd11598f74e8794011
```

## 2. Method

`ffmpeg`/`ffprobe` 7.0.2 static (installed into `/tmp`, nothing added to the
repository) was used to decode and inspect the clip.

- Full decode with error output: clean, no decode errors.
- All **238 frames** extracted and analysed numerically (per-frame differencing,
  foreground bounding box, mic-region measurement).
- Two labelled contact sheets covering the entire clip at 0.1 s resolution
  (every 3rd frame, 80 sampled frames).
- One zoom sheet plus additional 2×–4× close-ups of the mic grip and the
  cable's free end.
- Every third frame was inspected visually; roughly 30 frames were additionally
  inspected at native resolution or higher zoom.

Sampling is stated plainly: all 238 frames are covered by the numeric checks and
the two contact sheets, but the frames between samples were reviewed through the
sheets rather than one by one at full resolution.

## 3. Structure of the clip

| Frames | Time | Content |
| --- | --- | --- |
| 001–061 | 0.00–2.00 s | Idle: crossed arms, mic raised at the chest, cord coiled on the forearm |
| 062–070 | 2.03–2.33 s | Transition: arms uncross, mic lowers to the walk carry |
| 071–238 | 2.33–7.90 s | Walking in place, mic carried forward at chest height |

Cadence: one duplicate frame every five frames (f007, f012, f017 …), 46
duplicates in total. That is the 3:2 pulldown signature of a **24 fps** source
encoded into a 30 fps stream. Played back naively at 30 fps the walk carries
~25% judder; frame-rate conversion to 24 fps will present it as authored.

## 4. Findings

### 4.1 Mic hand — does not meet the stated left-hand rule (blocking)

The microphone is held in the same hand for the whole clip, including through
the idle → walk transition: **238/238 frames**, no swap.

That hand is the one on the facing side of the body (screen-right), held across
the chest, with the cord coiled around the wrist — exactly the carry of the
approved crossed-arms idle in `feedback-crossed-arms-approved.jpeg`. The
repository's own `feedback-idle-spec.json` records that approved pose as
**"mic in right hand"**.

The six imported gameplay poses are drawn the other way: in
`feedback-gameplay-comparison.png` the mic sits on the screen-left of the torso
while the free hand gestures to the screen-right. So the project's references
already disagree about which hand owns the mic.

Consequence: under the rule that the mic belongs in **Feedback's left hand**,
this walk test does not comply — it matches the approved idle carry, which the
repo labels right-hand. Before this movement test can be approved, one
authoritative answer is needed for: approved idle, six-pose pack, and walk. The
walk cannot be signed off while the references disagree.

Evidence: `contact-sheet-01-frames-001-118.png`,
`contact-sheet-02-frames-120-237.png`,
`zoom-sheet-hand-and-cable.png`.

### 4.2 Cable continuity — continuous, but the free end drifts (medium)

The run from the mic → coil on the wrist → down the front of the leg is
continuous in every frame; the cord is never broken or detached, and it is never
drawn twice.

The **terminal end** is inconsistent. In some poses a 1/4" plug is clearly
drawn at mid-thigh (e.g. f124, f145). In others the cord simply stops as a bare
strand at the shin or ankle with no plug visible (e.g. f196, f232, f238). The
hanging length therefore grows by roughly a leg length while the hand stays at
chest height, which is not physically consistent.

This is a drawing/detail inconsistency, not a broken cable.

### 4.3 No duplicate and no disappearing mic (pass)

Measured across all 238 frames:

- mic-grille pixel count stays in a single-mic range every frame
  (min 635, max 919 px) — never zero, never double.
- mic centroid never jumps more than 25 px between consecutive frames.
- visual inspection of every 3rd frame and ~30 close-ups found exactly one mic
  at all times.

### 4.4 Movement quality (medium)

- **Arms do not counter-swing.** The mic arm is effectively locked at the chest
  for the entire 5.6 s walk and the free arm hangs at the hip with little
  movement, while the legs cycle normally. The result reads as a stiff carry,
  not a walk with arm swing.
- **No root motion.** The figure walks in place. Body centre moves laterally
  about ±25 px (408–461 px across the clip, settling 425–459 during the walk),
  which reads as swagger/weight shift rather than travel; a gameplay
  integration will need root motion added separately.
- **No ground plane or contact shadow**, so foot contact and foot sliding cannot
  be judged from this clip. Sliding is therefore unreported rather than cleared.
- **No loop.** The final frame does not match any earlier walk pose closely
  (closest is f175, and even that is a looser match than adjacent frames), and
  f001 differs from f238 substantially. The clip is a one-shot idle → walk, not
  a seamless cycle, and cannot be looped as-is.

## 5. Verdict

- Reconstruction: **complete and byte-exact.**
- Movement test: **not approved.** The mic-hand rule is unresolved and the clip
  follows the pose that the repo records as right-handed; the cable's terminal
  end drifts; the arms are static through the walk; the clip does not loop.
- Gameplay integration: **none performed**, per instruction, and none should be
  attempted from this asset until the mic hand is settled.

## 6. Recommended next steps (not started)

1. Decide the single authoritative mic hand (left, per instruction) and update
   `feedback-idle-spec.json` plus the six-pose pack accordingly, then mirror or
   regenerate the walk carry.
2. Fix the cable terminal so the plug is drawn consistently at a stable height.
3. Add arm counter-swing to the walk; keep the mic arm's carry subtle but alive.
4. Re-shoot or re-time the next test at 24 fps with a ground/shadow reference so
   foot contact and sliding can actually be judged.

## 7. Limitations

- No ground plane exists in the clip, so foot sliding is unverified.
- Visual review sampled every 3rd frame in the contact sheets, with ~30 frames
  at native/high zoom; the remaining frames were covered by the numeric checks
  only.
- Left/right hand naming relies on the repository's own spec label
  ("mic in right hand" for the approved idle) because a 2D 3/4 drawing cannot be
  resolved anatomically with certainty; the observable fact — same hand as the
  approved idle, opposite side to the six-pose pack — is independent of that
  label.

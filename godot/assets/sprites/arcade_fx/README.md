# Arcade FX sprite sheets

Four transparent PNG sprite sheets for the retro arcade FX layer (`ArcadeVFX2D.gd`, PART 2
commit 4). **None of them exist yet.** The game runs with all four missing: each missing sheet
is logged once at boot and draws nothing. Drop a file in this folder and it starts playing with
no code change.

## Required files

| File | Plays on | Reads as |
| --- | --- | --- |
| `hit_spark_sheet.png` | any unblocked contact | a 2D arcade hit flash — the burst that sells the contact frame |
| `bass_shockwave_sheet.png` | a heavy strike **judged on the beat** | a sub-bass ring/shockwave expanding from the impact |
| `clash_callout_sheet.png` | a Record Static Parry (the clash moment) | a comic "clash" burst around the parrying fighter |
| `ko_callout_sheet.png` | a round-winning K.O. | the arcade K.O. starburst / callout flash over the losing fighter |

## Grid (author to exactly this)

| Property | Value |
| --- | --- |
| Format | PNG, 32-bit RGBA, fully transparent background |
| Grid | **4 × 4 = 16 frames**, left-to-right, top-to-bottom |
| Frame size | **256 × 256 px** |
| Sheet size | **1024 × 1024 px** |
| Playback | **24 fps**, one pass, no loop (16 frames = 0.667 s) |
| Padding / margin | **none** — frames must touch edge to edge; no gutters |
| Bleed | keep the art inside each 256 px cell; a frame that bleeds into its neighbour shows the neighbour's edge |
| Colour | designed for **additive** blending — pure black is invisible, so paint the glow, not the background |
| Pivot | frame centre; the effect is stamped at the impact and does not need to rotate |

Draw the motion so frame 0 is the full-strength burst and the last frame has faded to near
black — the layer does not scale or fade the sheet, it only steps frames.

## What the layer does

- Preallocates **3 Sprite2D nodes per existing sheet** at boot (12 at most) and reuses them; it
  never creates a node while the match runs.
- Steps `frame` on a `Sprite2D` with `hframes = 4`, `vframes = 4` — no `AtlasTexture`, no
  `AnimatedSprite2D`, no per-frame allocation.
- Blends with a single `CanvasItemMaterial` in **additive** mode.
- Positions each effect with `Camera3D.unproject_position()` of the world point of the event, so
  it sits over the fighter at any camera distance or lean.
- Lives on its own `CanvasLayer` (`VFX`), below the HUD, so it can never touch the camera, the
  frustum or the backdrop — `live_match_check._check_camera_stage_clearance` stays green with
  the layer present.

Documented in `AGENTS.md` (PART 2, commit 4) and summarised in `assets/models/props/README.md`
for the same author.

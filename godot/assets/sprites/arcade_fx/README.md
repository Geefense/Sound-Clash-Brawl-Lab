# Arcade FX sprite sheets

Transparent PNG sprite sheets for the retro arcade FX layer (`ArcadeVFX2D.gd`, PART 2 commit 4).
Two of the four were delivered on 2026-11-27 in a **six-frame horizontal strip** layout; the
other two are still specified on the older 4 × 4 grid and draw nothing until they arrive — each
missing sheet is logged once at boot and the game runs without it.

## Delivered (2026-11-27)

| File | Size | Grid | Cell | Bytes | Plays on |
| --- | --- | --- | --- | --- | --- |
| `hit_spark_sheet.png` | 768 × 128 | **6 × 1** | 128 × 128 | 22 287 | every unblocked contact |
| `bass_shockwave_sheet.png` | 1536 × 256 | **6 × 1** | 256 × 256 | 98 126 | a heavy strike judged on the beat, and the `SPEAKER BOX!` blowout |

Both play at **24 fps, one pass, no loop** (6 frames = 0.25 s). The layer reads the grid from the
texture instead of assuming it: a sheet six times as wide as it is tall is a six-frame strip,
anything else keeps the 4 × 4 README grid. A 128 px cell is drawn at twice the scale of a
256 px one (`draw_scale_for()`), so both sheets keep the same 115 px on-screen footprint.

## Still expected (not delivered)

| File | Plays on |
| --- | --- |
| `clash_callout_sheet.png` | a Record Static Parry (the clash moment) |
| `ko_callout_sheet.png` | a round-winning K.O. |

## Grid for the two undelivered sheets (author to exactly this)

| Property | Value |
| --- | --- |
| Format | PNG, 32-bit RGBA, fully transparent background |
| Grid | **4 × 4 = 16 frames**, left-to-right, top-to-bottom |
| Frame size | **256 × 256 px** |
| Sheet size | **1024 × 1024 px** |
| Padding / margin | **none** — frames must touch edge to edge; no gutters |
| Colour | designed for **additive** blending — pure black is invisible, so paint the glow |

## What the layer does

- Preallocates **3 Sprite2D nodes per existing sheet** at boot (12 at most) and reuses them; it
  never creates a node while the match runs.
- Steps `frame` on a `Sprite2D` with `hframes`/`vframes` read from the delivered texture — no
  `AtlasTexture`, no `AnimatedSprite2D`, no per-frame allocation.
- Blends with a single `CanvasItemMaterial` in **additive** mode.
- Tints per play: a yellow-white contact flash with a brief red edge on a heavy counter, a green
  edge on a confirmed on-beat ring, and the full green → gold → red ramp for `SPEAKER BOX!`.
- Positions each effect with `Camera3D.unproject_position()` of the world point of the event, so
  it sits over the fighter at any camera distance or lean.
- Lives on its own `CanvasLayer` (`VFX`), below the HUD, so it can never touch the camera, the
  frustum or the backdrop — `live_match_check._check_camera_stage_clearance` stays green with
  the layer present.
- The two delivered sheets import **lossless** with `detect_3d/compress_to=0`: they are 2D
  only, so the additive glow is never VRAM-compressed into blocky edges.

Documented in `AGENTS.md` (PART 2 commit 4 and PART L) and summarised in
`assets/models/props/README.md` for the same author.

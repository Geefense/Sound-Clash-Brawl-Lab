# QA stills

`contact_sheet.png` is the one committed image set for the 3D knockdown and prop work.
Everything else the harness produces stays out of the repository.

**Software-GL stills are for geometry and orientation checks only.** They were rendered by
Mesa `llvmpipe` on a CPU under Xvfb at 320×180 or 640×360. They say nothing about GPU
performance, fill rate, shader cost or frame time, and must never be used as evidence about
them.

## What is in the sheet

| Tile | Taken from |
| --- | --- |
| `knock_<fighter>_p2_ko04` | first impact frame of a real K.O. |
| `knock_<fighter>_p2_ko20` | mid-fall |
| `knock_<fighter>_p2_ko45` | flat phase, after the topple settles |
| `hand_upper_box_zoom` | Feedback's right hand during the ACTIVE window of U |
| `hand_jab_full` / `hand_upper_box_full` | the same two attacks on the whole arena |
| `speaker_full`, `speaker_zoom` | the delivered tower |
| `crowd_full`, `arena_wide` | the crowd bank and the wide arena |

## How it was produced

Every state is reached through the real live-match path: the harness boots a normal match,
presses real `InputMap` actions (`p1_right`, `p1_grab`, `p1_heavy`), and starts shooting on
the frame the fighter actually enters `KNOCKDOWN` / `KO`. No state is forced, no animation is
seeked, nothing is placed by hand.

```sh
# Xvfb + Mesa llvmpipe (no root in this workspace: packages were extracted user-side)
setsid /tmp/xroot/usr/bin/proot -b /tmp/xroot/usr/bin/xkbcomp:/usr/bin/xkbcomp \
  /tmp/xroot/usr/bin/Xvfb :96 -screen 0 1280x720x24 -nolisten tcp &
export LD_LIBRARY_PATH=/tmp/xroot/usr/lib/x86_64-linux-gnu \
       LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe FONTCONFIG_PATH=/tmp/xroot/etc/fonts

godot --display-driver x11 --rendering-driver opengl3 --path . --resolution 640x360 \
      --fixed-fps 60 --disable-vsync --script res://tools/capture_frames.gd \
      -- --only=knock --out=/tmp/sheet      # then --only=hands / props / arena / sheet
```

`--headless` cannot be used: with no window Godot falls back to the dummy renderer and every
still comes out blank. `--rendering-driver opengl3` alone does not help either; only a real
X display plus llvmpipe produces pixels.

Per-tick numbers come from `tools/dump_pose_csv.gd` (hips, head, chest and both feet in world
space plus the drawn skinned bounds, one row per tick, per fighter and slot).

## Why the old `_check_downed_pose` table reported `up·y 1.00`

The audit sampled the frame at which `state == KO` first becomes true, and at that frame the
body has only just been hit: `_fall = 0.0504` and the hips→head axis still reads
`up·y = 0.9986`. `_fall` is driven by the clip and by `DOWNED_SEAT_SPEED`, so at 60 fixed fps
it needs roughly 0.4 s to reach 1.0; the audit never stepped that far. The owner was looking
at the *end* of the animation, where the same measurement reads `up·y = −0.1444` — the body
inverted — and the drawn mesh sat 0.24–0.30 m above the sand because the shipped seat lifts
until the lowest *bone* clears the floor, not the lowest *vertex*.

So the old table was not wrong about the frame it sampled; it sampled the wrong frame and
measured the wrong primitive. The harness now reports both, and reports them at
`fall > 0.95` where the player actually sees the pose.

## Known gaps in this run

- **Only the P2 slot can be knocked out.** The shipped P2 opponent is the workshop dummy,
  which stands and blocks but never throws, so nothing in a real match can put the P1 fighter
  on the floor. The sheet therefore shows each rig in the P2 slot; the P1 heading is the same
  code with the facing sign flipped, and the facing audit covers it (310 checks, 0 FAIL).
- **The jab tile was captured outside its ACTIVE window** (`active=false` in the log); the
  upper-box tile is inside it. The hand rig is unchanged by this work, so the tile documents
  the hand it landed on, not a fix.

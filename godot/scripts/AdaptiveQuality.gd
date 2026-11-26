class_name AdaptiveQuality
extends RefCounted
## PART B commit 5 — the resolution guard for a Chromebook and for iPhone Safari.
##
## The game cannot measure GPU time, so this helper does the two things that can be measured
## honestly instead of pretending to know the frame budget:
##
## 1. **A one-time 3D scale from the window size × device pixel ratio.** A 1280×720 window at
##    1× is 0.92 Mpx and runs at scale 1.0; a 2560×1440 desktop at 1× is 3.69 Mpx and runs at
##    0.77; a retina phone (1920×1080 at 2×) is 8.29 Mpx and clamps to the 0.67 floor. The cap
##    is ~2.2 Mpx, the point where the yard's 7 lights and the 3D bodies stop being free.
## 2. **A hysteresis frame-time governor.** Below 55 fps for 2 s it steps the scale down by 0.06,
##    at most once every 3 s, never below 0.67. After 10 s of stable frames it steps back up
##    toward the capped scale. The two timers are separate, so a yard that hovers at 54 fps
##    cannot oscillate: it takes 2 s of slow to drop, and 10 s of steady to climb back.
##
## `Viewport.scaling_3d_scale` is a real 3D-only downscale in the Compatibility renderer from
## Godot 4.3 on (GLES3 gained 3D MSAA and bilinear scaling in that release), so the HUD keeps
## its canvas resolution while the yard costs fewer pixels.
##
## Allocation-free: every field is a scalar, `step()` builds nothing, and the game calls it once
## per presented frame.

## 2.2 Mpx. Roughly 1080p at 1× (2.07 Mpx) with a little headroom, and half of a 1440p panel.
const PIXEL_CAP := 2_200_000.0
## Never render the 3D buffer below two thirds of the window: past that the cel ink lines and the
## fighter silhouettes stop reading, and dropping further saves less than it costs.
const SCALE_FLOOR := 0.67
## One governor step. Small enough that a drop is not a visible snap.
const STEP := 0.06
## Below this the governor considers the frame expensive. 55 fps leaves room under 60 Hz vsync.
const FPS_FLOOR := 55.0
## Seconds under FPS_FLOOR before a step down.
const DOWN_AFTER := 2.0
## Minimum seconds between two down steps, so a single hitch cannot cascade.
const DOWN_INTERVAL := 3.0
## Seconds of stable frames before a step back up.
const UP_AFTER := 10.0

## The scale the startup pixel budget allows. Cached once: the window can be resized, but a
## resize goes through `configure()` again rather than being recomputed per frame.
var cap_scale: float = 1.0
## The scale currently requested from the viewport.
var scale: float = 1.0

var _slow: float = 0.0
var _fast: float = 0.0
var _since_down: float = DOWN_INTERVAL
var _downs: int = 0
var _ups: int = 0


## The pure half: the largest 3D scale whose rendered buffer stays at or under `cap` pixels for
## a window of `window_size` at `dpr` device pixels per axis. Always 1.0 or lower, never below
## `SCALE_FLOOR`.
static func render_scale_for(window_size: Vector2, dpr: float, cap: float = PIXEL_CAP) -> float:
	var pixels := maxf(window_size.x, 1.0) * maxf(window_size.y, 1.0) \
		* maxf(dpr, 1.0) * maxf(dpr, 1.0)
	if pixels <= cap:
		return 1.0
	return clampf(sqrt(cap / pixels), SCALE_FLOOR, 1.0)


## Boot: cache the capped scale and start from it.
func configure(window_size: Vector2, dpr: float) -> float:
	cap_scale = render_scale_for(window_size, dpr)
	scale = cap_scale
	_slow = 0.0
	_fast = 0.0
	_since_down = DOWN_INTERVAL
	return scale


## One presented frame. `delta` is the frame time, `fps` the engine's smoothed reading. Returns
## the scale the viewport should carry this frame; never allocates.
func step(delta: float, fps: float) -> float:
	var dt := clampf(delta, 0.0, 0.5)
	_since_down += dt
	if fps > 0.0 and fps < FPS_FLOOR:
		_fast = 0.0
		_slow += dt
		if _slow >= DOWN_AFTER and _since_down >= DOWN_INTERVAL \
				and scale > SCALE_FLOOR + 0.0001:
			scale = maxf(SCALE_FLOOR, scale - STEP)
			_slow = 0.0
			_since_down = 0.0
			_downs += 1
	else:
		_slow = 0.0
		_fast += dt
		if _fast >= UP_AFTER and scale < cap_scale - 0.0001:
			scale = minf(cap_scale, scale + STEP)
			_fast = 0.0
			_ups += 1
	return scale


## HUD/debug label: what the governor is asking for and how often it has moved.
func label() -> String:
	return "%.2f× 3D" % scale


func down_steps() -> int:
	return _downs


func up_steps() -> int:
	return _ups


## True while the governor is holding the floor: the yard cannot get cheaper than this.
func at_floor() -> bool:
	return scale <= SCALE_FLOOR + 0.0001

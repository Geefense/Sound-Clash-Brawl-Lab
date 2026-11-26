class_name AIBrain
extends RefCounted
## PART B commit 6 — the decision core behind `SparringController`, split out so the timing rules
## can be tested on their own.
##
## **Delayed perception.** `observe()` writes P1's state into a preallocated ring buffer every
## physics frame; `perceive()` reads the entry `reaction_frames + seeded jitter` frames old. The
## policy never sees a younger snapshot, so it cannot react frame-perfectly to a jab startup.
##
## **One attack gate.** `commit_attack()` is the only way an attack can be pressed. It refuses
## while the 40-frame-and-up cooldown runs, while the breathing window after two chained attacks
## is open, and while a mandatory neutral window is up (round start, its own get-up, its own
## whiffed or blocked attack).
##
## **Seeded and allocation-free.** Every random number comes from `rng`, seeded per match, so the
## same seed produces the same decisions; the ring, the buffers and every timer are allocated at
## construction or `setup()`, never per frame.
##
## Nothing here reads or writes a hitbox, a frame-data table or a Crowd Hype value.

## 96 frames is comfortably more than the largest shipped delay (26 + 8) and leaves the window
## open for a slower profile without ever reallocating.
const RING := 96
## How often the seeded jitter is re-rolled. The delay only ever *grows* above
## `reaction_frames`, so the "never younger than" contract cannot be broken by a re-roll.
const RESEED_EVERY := 45

var profile: AIProfile
var rng := RandomNumberGenerator.new()

# --- What the AI currently believes about P1 (refreshed by `perceive()`) --------------------
var seen_state: int = BaseFighter.State.IDLE
var seen_x: float = 0.0
var seen_vx: float = 0.0
var seen_guarding: bool = false
var seen_attacking: bool = false

var _states := PackedInt32Array()
var _xs := PackedFloat32Array()
var _vxs := PackedFloat32Array()
var _guard := PackedByteArray()
var _attack := PackedByteArray()
var _head := 0
var _count := 0

var _delay := 18
var _delay_age := 0
var _cooldown := 0
var _neutral := 0
var _breathing := 0
var _consecutive := 0
var _threat_ticks := 0
var _punish_armed := false
var _punish_wait := 0
var _punish_ok := false


func _init() -> void:
	_states.resize(RING)
	_xs.resize(RING)
	_vxs.resize(RING)
	_guard.resize(RING)
	_attack.resize(RING)


## Bind a profile and a seed. Call once per opponent; `reset_for_round()` opens the neutral window.
func setup(p: AIProfile, seed_value: int) -> void:
	profile = p
	rng.seed = seed_value
	_head = 0
	_count = 0
	_cooldown = 0
	_consecutive = 0
	_breathing = 0
	_threat_ticks = 0
	_punish_armed = false
	_punish_wait = 0
	_punish_ok = false
	_delay_age = 0
	_roll_delay()
	_neutral = profile.round_start_neutral_frames if profile != null else 0


## Re-seed without rebuilding: the workshop's determinism check and a rematch both use this.
func seed_decisions(seed_value: int) -> void:
	rng.seed = seed_value
	_delay_age = 0
	_roll_delay()
	_neutral = maxi(_neutral, profile.round_start_neutral_frames if profile != null else 0)
	_cooldown = 0
	_consecutive = 0
	_breathing = 0


func _roll_delay() -> void:
	if profile == null:
		_delay = 18
		return
	var jitter := maxi(0, profile.reaction_jitter)
	_delay = maxi(0, profile.reaction_frames + (rng.randi_range(0, jitter) if jitter > 0 else 0))


# =========================================================================
# Perception
# =========================================================================
## One physics frame of P1, written into the ring. Cheap scalar writes; no allocation.
func observe(state: int, x: float, vx: float, guarding: bool, attacking: bool) -> void:
	_states[_head] = state
	_xs[_head] = x
	_vxs[_head] = vx
	_guard[_head] = 1 if guarding else 0
	_attack[_head] = 1 if attacking else 0
	_head = (_head + 1) % RING
	_count = mini(_count + 1, RING)


## Refresh the perceived snapshot from the entry `_delay` frames back. Never reads the current
## frame: with an empty buffer it reads frame 0, and with a full buffer it is exactly `_delay`.
func perceive() -> void:
	var lag := mini(_delay, maxi(_count - 1, 0))
	var idx := (_head - 1 - lag + RING * 2) % RING
	seen_state = _states[idx]
	seen_x = _xs[idx]
	seen_vx = _vxs[idx]
	seen_guarding = _guard[idx] == 1
	seen_attacking = _attack[idx] == 1


# =========================================================================
# Frame timers and the attack gate
# =========================================================================
## Advance every timer. Called once per physics frame, before `perceive()`.
func tick() -> void:
	_cooldown = maxi(0, _cooldown - 1)
	_neutral = maxi(0, _neutral - 1)
	_breathing = maxi(0, _breathing - 1)
	_delay_age += 1
	if _delay_age >= RESEED_EVERY:
		_delay_age = 0
		_roll_delay()
	if _punish_wait > 0:
		_punish_wait -= 1
		if _punish_wait == 0:
			_punish_ok = rng.randf() < (profile.punish_chance if profile != null else 0.5)
			# A missed punish must not stay armed forever: disarm it so the NEXT opening can
			# be rolled too. (Found by the live probe: without this line the counter-puncher
			# rolled once per match and then never attacked again.)
			if not _punish_ok:
				_punish_armed = false


## True when an attack decision is allowed this frame. This is the single gate every mode uses.
func attack_ready() -> bool:
	if profile == null:
		return false
	return _cooldown == 0 and _neutral == 0 and _breathing == 0 \
		and _consecutive < profile.max_consecutive_attacks


## Book one attack decision. Refuses (and changes nothing) when the gate is closed.
func commit_attack() -> bool:
	if not attack_ready():
		return false
	_consecutive += 1
	_cooldown = maxi(40, profile.attack_cooldown_frames)
	if _consecutive >= profile.max_consecutive_attacks:
		_consecutive = 0
		_breathing = rng.randi_range(profile.breathing_min_frames,
			maxi(profile.breathing_min_frames, profile.breathing_max_frames))
	return true


## A seen recovery arms a punish, but it only fires after the reaction delay has passed again,
## and only on a probability roll — so the AI misses openings like a person does.
func arm_punish() -> void:
	if _punish_armed:
		return
	_punish_armed = true
	_punish_wait = maxi(1, _delay)


## True once for each armed punish that won its roll.
func punish_ready() -> bool:
	if not _punish_ok:
		return false
	_punish_ok = false
	_punish_armed = false
	return true


## Guard is a delayed read too: the delayed snapshot has to show the threat for
## `guard_delay_frames` before the body actually blocks.
func guard_pressure(inside_range: bool) -> bool:
	if not inside_range:
		_threat_ticks = 0
		return false
	if seen_attacking or seen_state == BaseFighter.State.ATTACK_RECOVERY:
		_threat_ticks += 1
	else:
		_threat_ticks = 0
	return _threat_ticks >= maxi(1, profile.guard_delay_frames if profile != null else 12)


# =========================================================================
# Neutral windows
# =========================================================================
## Its own attack finished. A whiff or a blocked hit costs the full window; a clean hit only a
## short reset, so landing does not make the AI passive.
func on_own_attack_ended(landed: bool) -> void:
	if profile == null:
		return
	_neutral = maxi(_neutral, profile.landed_neutral_frames if landed
		else profile.whiff_neutral_frames)


## Its own get-up: the longest non-round neutral, so it never stands into an attack.
func on_getup() -> void:
	if profile == null:
		return
	_neutral = maxi(_neutral, profile.getup_neutral_frames)
	_cooldown = 0
	_consecutive = 0
	_breathing = 0


## Round start: a full neutral window, so the opening exchange is not a CPU jump-in.
func reset_for_round() -> void:
	if profile == null:
		return
	_neutral = maxi(_neutral, profile.round_start_neutral_frames)
	_cooldown = 0
	_consecutive = 0
	_breathing = 0
	_threat_ticks = 0
	_punish_armed = false
	_punish_wait = 0
	_punish_ok = false


# =========================================================================
# Reporting (audits and the debug HUD)
# =========================================================================
func reaction_frames() -> int:
	return _delay


func cooldown_frames() -> int:
	return _cooldown


func neutral_frames() -> int:
	return _neutral


func breathing_frames() -> int:
	return _breathing


func consecutive_attacks() -> int:
	return _consecutive


func profile_id() -> StringName:
	return profile.id if profile != null else &""

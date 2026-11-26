class_name SparringController
extends Node
## Smart Sparring AI for P2 — a workshop test partner, not a shipping opponent.
## Authority: AGENTS.md §5 (input adapter, beat service) and §9 (guardrails).
##
## This node owns exactly one thing: the `BaseFighter.Command` it hands to P2 every physics
## tick. It never assigns `state`, never calls `change_state`, never touches the hitbox and
## never skips frame data — every attack goes through the same startup/active/recovery path
## as a human input, including the input buffer and the beat judgement taken at input time.
##
## **PART B commit 6 — the CPU no longer reacts frame-perfectly.** All four modes now read P1
## through `AIBrain`'s delayed ring buffer (`reaction_frames` + seeded jitter), and every attack
## they would like to throw passes the brain's one gate: a ≥40-frame cooldown between decisions,
## at most two attacks in a row followed by a 30–45-frame breathing window of spacing and guard,
## and mandatory neutral windows after the round opens, after the AI's own get-up, and after its
## own whiffed or blocked attack. Punishes and blocks are delayed reads with a probability roll.
## All randomness is one seeded RNG (`decision_seed`), so a seed reproduces the same decisions.
##
## Modes (cycle with **Y** in TestArena):
##   0 Workshop Dummy   — stands still, or holds guard while G is toggled (the old behaviour).
##   1 Counter-Puncher  — mic-defence when the delayed snapshot shows a threat, punish a seen recovery.
##   2 Riddim Rusher    — steps on the 132 BPM beat and throws on-beat Jab → Kick / BOX strings.
##   3 Spacing Baiter   — footsies through mid-range, skank taunts when far, BOX on the dash-in.
##
## G is a manual guard override in every mode: the controller ORs it into every command.
## [TODO] Every range, cooldown and pattern below is a hand-set lab default awaiting a playtest;
## the difficulty knobs themselves live in `AIProfile` and are documented in AGENTS.md.

enum Mode { DUMMY, COUNTER_PUNCHER, RIDDIM_RUSHER, SPACING_BAITER }

const MODE_NAMES := [
	"Workshop Dummy",
	"Counter-Puncher",
	"Riddim Rusher",
	"Spacing & Skank Baiter",
]
const MODE_TAGS := [
	"Stand / hold guard",
	"Bait & Punish",
	"On-Beat Pressure",
	"Footsies & Skank Bait",
]

# Reach is centre-to-centre: the attack hitbox's forward edge plus P1's half hurtbox
# (BaseFighter.stand_size.x = 60). Jab 84+42+30 ≈ 156 px, tump 88+52+30 ≈ 170 px,
# BOX 96+54+30 ≈ 180 px. The margins below sit just under each true reach so a punish
# is only thrown when the box actually overlaps.
const JAB_RANGE := 150.0
const KICK_RANGE := 166.0
const BOX_RANGE := 178.0
const THREAT_RANGE := 190.0        # P1's jab can reach us from about here
const MID_RANGE := 240.0
const FAR_RANGE := 330.0
const FALLBACK_BEAT_STEP_TICKS := 26   # 132 BPM = 27.3 ticks per beat
const TAUNT_COOLDOWN_TICKS := 70
const DASH_SPEED := 150.0          # |velocity.x| that counts as a P1 dash-in
# Grab / throw-break behaviour (§9 item 18). The AI uses the same Command as a human.
const GRAB_RANGE := 92.0           # just inside BaseFighter.GRAB_RANGE
const GRAB_COOLDOWN_TICKS := 110

## One action per beat, two bars at 132 BPM: a Jab-led string into the Sparta Kick (L)
## and a BOX (K) accent on the 6th beat, with beat-steps in between to close distance.
const RUSH_PATTERN := [&"step", &"light", &"tump", &"step", &"light", &"heavy", &"", &"step"]

## The difficulty profile, as data. `AIProfile.preset(&"normal")` is the default and is
## noticeably gentler than the frame-perfect partner this file used to be.
@export var profile: AIProfile
## Seeded so a replay, a test or a rematch reproduces the same decisions. Change it for a
## different-feeling partner at the same difficulty.
@export var decision_seed: int = 20261126

var p1: BaseFighter
var p2: BaseFighter
var beat: BeatService
var manual_guard: bool = false    # G toggle from TestArena; ORed into every command
var mode: Mode = Mode.DUMMY
## The decision core: delayed perception, cooldown, breathing and neutral windows. Read-only for
## the audits (`brain.attack_ready()`, `brain.reaction_frames()`), never written by them.
var brain := AIBrain.new()

var _pending: StringName = &""
var _step_ticks: int = 0
var _footsie_advance: bool = true
var _taunt_cooldown: int = 0
var _grab_cooldown: int = 0
var _tech_armed: bool = false
var _tech_delay: int = 0
## Its own last state, so the controller can see its attack end and its get-up finish.
var _last_own_state: int = BaseFighter.State.IDLE
var _own_hit_landed: bool = false


func _ready() -> void:
	# Run before the fighters so the command is fresh when BaseFighter ticks.
	process_physics_priority = -1
	if profile == null:
		profile = AIProfile.preset(&"normal")


## TestArena owns the wiring; everything else stays inside this node.
func setup(one: BaseFighter, two: BaseFighter, service: BeatService) -> void:
	if profile == null:
		profile = AIProfile.preset(&"normal")
	p1 = one
	p2 = two
	beat = service
	if beat != null and not beat.beat.is_connected(_on_beat):
		beat.beat.connect(_on_beat)
	if p2 != null and not p2.strike_resolved.is_connected(_on_strike_resolved):
		p2.strike_resolved.connect(_on_strike_resolved)
	brain.setup(profile, decision_seed)
	brain.reset_for_round()
	if p1 != null and p2 != null:
		_last_own_state = p2.state
	_reset_mode_state()


## Swap difficulty without a menu: the presets are `easy`, `normal` and `hard`.
func set_preset(name: StringName) -> AIProfile:
	profile = AIProfile.preset(name)
	brain.setup(profile, decision_seed)
	brain.reset_for_round()
	return profile


func profile_id() -> StringName:
	return profile.id if profile != null else &""


# =========================================================================
# Mode switching (Y)
# =========================================================================
func cycle_mode() -> Mode:
	return set_mode((int(mode) + 1) % MODE_NAMES.size())


func set_mode(next: int) -> Mode:
	# Switching mid-action is safe: the FSM finishes the current state on its own.
	mode = clampi(next, 0, MODE_NAMES.size() - 1) as Mode
	_reset_mode_state()
	return mode


func mode_name() -> String:
	return MODE_NAMES[int(mode)]


func mode_tag() -> String:
	return MODE_TAGS[int(mode)]


func mode_index() -> int:
	return int(mode)


func _reset_mode_state() -> void:
	_pending = &""
	_step_ticks = 0
	_taunt_cooldown = 0
	_grab_cooldown = 0
	_tech_armed = false
	_tech_delay = 0
	_footsie_advance = true


# =========================================================================
# Tick — perceive (late), then build one Command for BaseFighter to run
# =========================================================================
func _physics_process(_delta: float) -> void:
	if p1 == null or p2 == null:
		return
	if profile == null:
		profile = AIProfile.preset(&"normal")
	# PERCEPTION IS DELAYED: P1 is only ever read through the ring buffer, and `perceive()`
	# hands the policy a snapshot `reaction_frames + jitter` old — never this frame's input.
	brain.observe(p1.state, p1.global_position.x, p1.velocity.x, p1.guarding,
		_p1_attacking())
	brain.tick()
	brain.perceive()
	_track_own_state()

	var c := BaseFighter.Command.new()
	match mode:
		Mode.COUNTER_PUNCHER:
			_drive_counter(c)
		Mode.RIDDIM_RUSHER:
			_drive_rusher(c)
		Mode.SPACING_BAITER:
			_drive_baiter(c)
		_:
			pass                          # Workshop Dummy: no input at all
	_tick_grab(c)
	c.guard = c.guard or manual_guard
	p2.command = c


func _p1_attacking() -> bool:
	return p1.state == BaseFighter.State.ATTACK_STARTUP \
		or p1.state == BaseFighter.State.ATTACK_ACTIVE


## Its own attack ending is the whiff/blocked cue; its own get-up is the recovery cue. Both open
## a mandatory neutral window, so the CPU cannot stand straight into another swing.
func _track_own_state() -> void:
	var was_attacking: bool = _last_own_state in [
		BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE,
		BaseFighter.State.ATTACK_RECOVERY]
	var is_attacking: bool = p2.state in [
		BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE,
		BaseFighter.State.ATTACK_RECOVERY]
	if is_attacking and not was_attacking:
		_own_hit_landed = false
	elif was_attacking and not is_attacking:
		brain.on_own_attack_ended(_own_hit_landed)
		_own_hit_landed = false
	if _last_own_state == BaseFighter.State.KNOCKDOWN \
			and p2.state != BaseFighter.State.KNOCKDOWN:
		brain.on_getup()
	_last_own_state = p2.state


## A landed strike on P1. Blocked or parried contacts count as a whiff for the neutral window.
func _on_strike_resolved(attacker: BaseFighter, _target: BaseFighter, result: Dictionary) -> void:
	if attacker != p2:
		return
	if bool(result.get("ignored", false)) or bool(result.get("blocked", false)) \
			or bool(result.get("parried", false)):
		return
	_own_hit_landed = true


func _tick_timers() -> void:
	_step_ticks = maxi(0, _step_ticks - 1)
	_taunt_cooldown = maxi(0, _taunt_cooldown - 1)
	_grab_cooldown = maxi(0, _grab_cooldown - 1)


## Throw break: while held, occasionally press Grab inside the defender's window.
func _tick_grab(c: BaseFighter.Command) -> void:
	if p2.state != BaseFighter.State.GRABBED:
		_tech_armed = false
		return
	if not _tech_armed:
		_tech_armed = true
		_tech_delay = brain.rng.randi_range(1, 6)
		if brain.rng.randf() > 0.55:
			_tech_delay = 99          # this grab goes through
	_tech_delay -= 1
	if _tech_delay <= 0:
		c.grab = true


## True when a grab is worth throwing at a turtling P1 (or a crouching one). Reads the delayed
## snapshot, like every other decision.
func _wants_grab() -> bool:
	if _grab_cooldown > 0 or not _can_act():
		return false
	if _seen_distance() > GRAB_RANGE:
		return false
	return brain.seen_guarding or brain.seen_state == BaseFighter.State.CROUCH


func _on_beat(beat_index: int) -> void:
	match mode:
		Mode.RIDDIM_RUSHER:
			_pending = RUSH_PATTERN[beat_index % RUSH_PATTERN.size()]
		Mode.SPACING_BAITER:
			# Two beats in, two beats out — footsies on the pulse.
			_footsie_advance = (int(beat_index / 2) % 2) == 0


# =========================================================================
# Mode 1 — Counter-Puncher ("Bait & Punish")
# =========================================================================
func _drive_counter(c: BaseFighter.Command) -> void:
	_tick_timers()
	var d := _seen_distance()
	p2.face_toward(p1.global_position.x)

	# Turtling P1: a grab beats the held guard, so take it instead of swinging.
	if _wants_grab():
		c.grab = true
		_grab_cooldown = GRAB_COOLDOWN_TICKS
		return

	# A seen recovery arms a punish — it still waits for the delay and a probability roll.
	if brain.seen_state in [BaseFighter.State.ATTACK_RECOVERY, BaseFighter.State.HITSTUN,
			BaseFighter.State.THROWN]:
		brain.arm_punish()
	# Read the punish only when the strike can actually reach: `punish_ready()` is one-shot, and
	# the old order burned a successful roll every time P1's own knockback had pushed us out of
	# range, which is what made a jabbed counter-puncher look switched off.
	if brain.attack_ready() and d <= KICK_RANGE and brain.punish_ready():
		if d <= JAB_RANGE and _try_attack(c, &"light"):
			return
		if _try_attack(c, &"tump"):
			return

	# Breathing window: make space, then come back in. No attack is allowed here.
	if brain.breathing_frames() > 0:
		c.move_x = _away_from_p1() if d < MID_RANGE else _toward_p1()
		c.guard = d <= THREAT_RANGE and brain.guard_pressure(true)
		return

	if brain.guard_pressure(d <= THREAT_RANGE):
		c.guard = true                    # Mic Defence, one delay late
		return
	if d <= THREAT_RANGE:
		# Holding the threat range without attacking: drift, do not turtle permanently.
		c.move_x = _away_from_p1() if d < JAB_RANGE * 0.8 else 0.0
		return
	c.move_x = _toward_p1()               # walk into bait range and wait


# =========================================================================
# Mode 2 — Riddim Rusher ("On-Beat Pressure")
# =========================================================================
func _drive_rusher(c: BaseFighter.Command) -> void:
	_tick_timers()
	p2.face_toward(p1.global_position.x)

	# Mix a grab into the on-beat pressure when P1 is holding guard.
	if _pending == &"" and _wants_grab():
		c.grab = true
		_grab_cooldown = GRAB_COOLDOWN_TICKS
		return

	# The breathing window is the spacing lesson: step out of range, then re-enter on the beat.
	if brain.breathing_frames() > 0:
		if _seen_distance() < MID_RANGE:
			c.move_x = _away_from_p1()
		elif _seen_distance() > JAB_RANGE:
			c.move_x = _toward_p1()
		return

	if _pending != &"":
		var action := _pending
		_pending = &""
		if _play_rush_action(action, c):
			return

	if _step_ticks > 0 and _seen_distance() > JAB_RANGE * 0.85:
		c.move_x = _toward_p1()           # the beat-step is still carrying us in


## Returns true when the action was turned into an attack this tick.
func _play_rush_action(action: StringName, c: BaseFighter.Command) -> bool:
	var d := _seen_distance()
	match action:
		&"light":
			if d <= JAB_RANGE and _try_attack(c, &"light"):
				return true
		&"tump":
			if d <= KICK_RANGE and _try_attack(c, &"tump"):
				return true
		&"heavy":
			if d <= BOX_RANGE and _try_attack(c, &"heavy"):
				return true
		&"step":
			_step_ticks = _beat_step_ticks()
			return false
	# Out of reach — or the gate refused the attack — keep the beat by stepping instead.
	_step_ticks = _beat_step_ticks()
	return false


## A beat-step stays down until the next beat, so the walk actually covers ground.
func _beat_step_ticks() -> int:
	if beat == null:
		return FALLBACK_BEAT_STEP_TICKS
	return maxi(4, int(round(beat.beat_length_sec() * 60.0)) - 1)


# =========================================================================
# Mode 3 — Spacing & Skank Baiter ("Footsies & Skank Bait")
# =========================================================================
func _drive_baiter(c: BaseFighter.Command) -> void:
	_tick_timers()
	var d := _seen_distance()
	var closing := (brain.seen_x - p2.global_position.x) * brain.seen_vx < 0.0
	var dashing := closing and absf(brain.seen_vx) > DASH_SPEED
	p2.face_toward(p1.global_position.x)

	# Catch the dash-in with the heavy BOX (still through the one gate).
	if dashing and d <= BOX_RANGE + 24.0 and _try_attack(c, &"heavy"):
		_taunt_cooldown = TAUNT_COOLDOWN_TICKS
		return

	# Risky skank taunt: only far away, only outside the neutral window, and only while the
	# delayed snapshot does not show a swing.
	if d > FAR_RANGE and _taunt_cooldown == 0 and _can_act() \
			and brain.neutral_frames() == 0 and not brain.seen_attacking:
		c.taunt = true
		_taunt_cooldown = TAUNT_COOLDOWN_TICKS
		return

	# Footsies: drift through mid-range on the beat, then back out.
	if _footsie_advance:
		if d > JAB_RANGE + 15.0:
			c.move_x = _toward_p1()
		elif d < JAB_RANGE * 0.6:
			c.move_x = _away_from_p1()
	elif d < MID_RANGE:
		c.move_x = _away_from_p1()


# =========================================================================
# Helpers
# =========================================================================
## Every attack in every mode funnels through here. `commit_attack()` is the only gate.
## A body that cannot act (hitstun, knockdown, held, thrown) never spends a decision: the old
## controller burned its cooldown and neutral window on inputs the FSM dropped, which is why a
## jabbed CPU looked inert instead of merely late.
func _try_attack(c: BaseFighter.Command, kind: StringName) -> bool:
	if p2.state in [BaseFighter.State.HITSTUN, BaseFighter.State.KNOCKDOWN,
			BaseFighter.State.KO, BaseFighter.State.GRABBED, BaseFighter.State.THROWN]:
		return false
	if not brain.commit_attack():
		return false
	match kind:
		&"tump":
			c.tump = true
		&"heavy":
			c.heavy = true
		_:
			c.light = true
	return true


## Fiction to the delayed snapshot, not to P1's live position: that is the whole point.
func _seen_distance() -> float:
	return absf(brain.seen_x - p2.global_position.x)


func _toward_p1() -> float:
	return signf(brain.seen_x - p2.global_position.x)


func _away_from_p1() -> float:
	return -_toward_p1()


## Actions the FSM accepts right now. Attacks can also be buffered mid-attack, so the
## rusher does not need this check for its strings.
func _can_act() -> bool:
	return p2.state == BaseFighter.State.IDLE or p2.state == BaseFighter.State.WALK

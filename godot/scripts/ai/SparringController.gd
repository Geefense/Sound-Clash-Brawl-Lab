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
## Modes (cycle with **Y** in TestArena):
##   0 Workshop Dummy   — stands still, or holds guard while G is toggled (the old behaviour).
##   1 Counter-Puncher  — mic-defence when P1 is inside strike range, punish the whiff/recovery.
##   2 Riddim Rusher    — steps on the 132 BPM beat and throws on-beat Jab → Kick / BOX strings.
##   3 Spacing Baiter   — footsies through mid-range, skank taunts when far, BOX on the dash-in.
##
## G is a manual guard override in every mode: the controller ORs it into every command.
## [TODO] Every range, cooldown and pattern below is a hand-set lab default awaiting a playtest.

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
const PUNISH_TICKS := 16           # reaction window after P1 enters recovery
const TAUNT_COOLDOWN_TICKS := 70
const DASH_SPEED := 150.0          # |velocity.x| that counts as a P1 dash-in

## One action per beat, two bars at 132 BPM: a Jab-led string into the Sparta Kick (L)
## and a BOX (K) accent on the 6th beat, with beat-steps in between to close distance.
const RUSH_PATTERN := [&"step", &"light", &"tump", &"step", &"light", &"heavy", &"", &"step"]

var p1: BaseFighter
var p2: BaseFighter
var beat: BeatService
var manual_guard: bool = false    # G toggle from TestArena; ORed into every command
var mode: Mode = Mode.DUMMY

var _p1_state: int = BaseFighter.State.IDLE
var _punish_ticks: int = 0
var _pending: StringName = &""
var _step_ticks: int = 0
var _footsie_advance: bool = true
var _taunt_cooldown: int = 0


func _ready() -> void:
	# Run before the fighters so the command is fresh when BaseFighter ticks.
	process_physics_priority = -1


## TestArena owns the wiring; everything else stays inside this node.
func setup(one: BaseFighter, two: BaseFighter, service: BeatService) -> void:
	p1 = one
	p2 = two
	beat = service
	if beat != null and not beat.beat.is_connected(_on_beat):
		beat.beat.connect(_on_beat)
	if p1 != null:
		_p1_state = p1.state
	_reset_mode_state()


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
	_punish_ticks = 0
	_taunt_cooldown = 0
	_footsie_advance = true


# =========================================================================
# Tick — build one Command, then let BaseFighter run its own FSM on it
# =========================================================================
func _physics_process(_delta: float) -> void:
	if p1 == null or p2 == null:
		return
	_read_p1()
	_tick_timers()

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
	c.guard = c.guard or manual_guard
	p2.command = c


func _read_p1() -> void:
	var s: int = p1.state
	if s == _p1_state:
		return
	# Whiffed or blocked attacks both end in P1's own recovery — that is the punish cue.
	if _p1_state in [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE] \
			and s == BaseFighter.State.ATTACK_RECOVERY:
		_punish_ticks = PUNISH_TICKS
	_p1_state = s


func _tick_timers() -> void:
	_punish_ticks = maxi(0, _punish_ticks - 1)
	_step_ticks = maxi(0, _step_ticks - 1)
	_taunt_cooldown = maxi(0, _taunt_cooldown - 1)


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
	var d := _distance()
	p2.face_toward(p1.global_position.x)

	if _punish_ticks > 0 and _can_act():
		if d <= JAB_RANGE:
			c.light = true                # fast punish on the recovery
			_punish_ticks = 0
			return
		if d <= KICK_RANGE:
			c.tump = true                 # Sparta Kick when the jab would fall short
			_punish_ticks = 0
			return
		c.move_x = _toward_p1()           # close while the opening is still live
		return

	if d <= THREAT_RANGE:
		c.guard = true                    # Mic Defence held inside strike range
		return
	c.move_x = _toward_p1()               # walk into bait range and wait


# =========================================================================
# Mode 2 — Riddim Rusher ("On-Beat Pressure")
# =========================================================================
func _drive_rusher(c: BaseFighter.Command) -> void:
	p2.face_toward(p1.global_position.x)

	if _pending != &"":
		var action := _pending
		_pending = &""
		if _play_rush_action(action, c):
			return

	if _step_ticks > 0 and _distance() > JAB_RANGE * 0.85:
		c.move_x = _toward_p1()           # the beat-step is still carrying us in


## Returns true when the action was turned into an attack this tick.
func _play_rush_action(action: StringName, c: BaseFighter.Command) -> bool:
	var d := _distance()
	match action:
		&"light":
			if d <= JAB_RANGE:
				c.light = true
				return true
		&"tump":
			if d <= KICK_RANGE:
				c.tump = true
				return true
		&"heavy":
			if d <= BOX_RANGE:
				c.heavy = true
				return true
		&"step":
			_step_ticks = _beat_step_ticks()
			return false
	# Out of reach: keep the beat by stepping in instead of swinging at air.
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
	var d := _distance()
	var closing := (p1.global_position.x - p2.global_position.x) * p1.velocity.x < 0.0
	var dashing := closing and absf(p1.velocity.x) > DASH_SPEED
	p2.face_toward(p1.global_position.x)

	# Catch the dash-in with the heavy BOX.
	if dashing and d <= BOX_RANGE + 24.0 and _can_act():
		c.heavy = true
		_taunt_cooldown = TAUNT_COOLDOWN_TICKS
		return

	# Risky skank taunt: only far away and only while P1 is not swinging.
	if d > FAR_RANGE and _taunt_cooldown == 0 and _can_act() and not _p1_attacking():
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
func _distance() -> float:
	return absf(p1.global_position.x - p2.global_position.x)


func _toward_p1() -> float:
	return signf(p1.global_position.x - p2.global_position.x)


func _away_from_p1() -> float:
	return -_toward_p1()


## Actions the FSM accepts right now. Attacks can also be buffered mid-attack, so the
## rusher does not need this check for its strings.
func _can_act() -> bool:
	return p2.state == BaseFighter.State.IDLE or p2.state == BaseFighter.State.WALK


func _p1_attacking() -> bool:
	return _p1_state in [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE]

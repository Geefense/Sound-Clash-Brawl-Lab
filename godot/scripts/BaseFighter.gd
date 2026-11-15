class_name BaseFighter
extends CharacterBody2D
## Fighter base: FSM + guard flag + beat-judgement hook.
## Authority: AGENTS.md §5 (FSM, beat service) and §9 (guardrails).
## Origin = feet. Sprite is presentation only; it never decides combat.
## Frame origins come from feedback.poses.json: grounded poses anchor at y 900,
## pelvis-anchored poses at y 610, the walk keys at their pinned sole y 566.
## Canonical mic hand (owner decision): never mirror the art. A left-facing fighter
## looks for <anim>_left and falls back to the right-facing frames until that art exists.

enum State {
	IDLE, WALK, JUMP, CROUCH,
	ATTACK_STARTUP, ATTACK_ACTIVE, ATTACK_RECOVERY,
	TAUNT, HITSTUN, KNOCKDOWN, KO,
	GRAB, GRABBED, THROWN,
}

signal state_changed(old_state: State, new_state: State)
signal health_changed(current: int, maximum: int)
signal hype_changed(current: int, maximum: int)
signal strike_resolved(attacker: BaseFighter, target: BaseFighter, result: Dictionary)
signal taunt_started(beat: Dictionary)
signal static_parry_triggered(defender: BaseFighter, attacker: BaseFighter)
signal hype_milestone_reached(percent: int)
signal hype_surge_started(seconds: float)
signal camera_shake_requested(intensity: float, duration: float)
signal died
# Grab / throw chain (§9 item 18). No new art: the victim is thrown into the existing
# launched -> tumble -> knockdown poses.
signal grab_connected(attacker: BaseFighter, defender: BaseFighter)
signal throw_broken(attacker: BaseFighter, defender: BaseFighter)
signal throw_connected(attacker: BaseFighter, defender: BaseFighter, kind: StringName)
signal speaker_slam_triggered(victim: BaseFighter, side: int)   # -1 left stack, +1 right stack

## One tick of input. Local keyboard fills it; AI/dummy/replay can set it instead.
class Command:
	var move_x: float = 0.0
	var jump: bool = false        # just pressed
	var guard: bool = false       # held (S / Down)
	var crouch: bool = false      # held (distinct input; see DEFAULT_P1_KEYS)
	var light: bool = false       # just pressed (J)
	var heavy: bool = false       # just pressed (K)
	var tump: bool = false        # just pressed (L)
	var upper_box: bool = false   # just pressed (I)
	var taunt: bool = false       # just pressed
	var grab: bool = false        # just pressed (U) — also the throw-break input

# ---- Config ----------------------------------------------------------------
@export var input_prefix: String = "p1_"
@export var use_local_input: bool = true
@export var beat_service: BeatService          # optional; judgement is "unavailable" without it
@export var max_health: int = 100              # [TODO] PLACEHOLDER: confirm from SimulationEngine.ts
## true = hype is awarded only when the on-beat strike actually connects (owner default)
@export var hype_requires_connect: bool = true

@export var walk_speed: float = 220.0          # keep as playtested; do not touch with jump tuning
# Playtest pass 1: crisper SF2-style arc. 2 x 1000 / 2800 = 0.71 s airtime, ~178 px apex.
@export var jump_velocity: float = -1000.0     # [TODO] still to be ported from TS
@export var gravity: float = 2800.0            # [TODO] still to be ported from TS
@export var stand_size: Vector2 = Vector2(60, 160)
@export var crouch_size: Vector2 = Vector2(60, 96)

# 60 Hz tick counts. [TODO] PLACEHOLDERS unless noted: port from combatRules.ts.
const KNOCKDOWN_FALL_TICKS := 36       # KO fall constant from AGENTS.md §3; nonlethal get-up [TODO]
# One full 5-frame skank cycle at 4.4 fps = 2.5 beats at 132 BPM, so each pose lands
# on an eighth note. [TODO] confirm the taunt commitment feels right on beat.
const TAUNT_TICKS := 68
const BLOCKSTUN_TICKS := 8
# Guard presentation phases (mic-defence frames): entry -> held brace -> release.
const GUARD_ENTRY_TICKS := 8
const GUARD_RECOVERY_TICKS := 8
const BLOCK_PUSHBACK := 120.0
const INPUT_BUFFER_TICKS := 12
const STUN_FRICTION := 900.0

# Sand stage presentation (AGENTS.md §9). Cosmetic only: never touches combat.
const STEP_PUFF_TICKS := 8          # one footfall puff every 8 ticks of walking
const LANDING_PUFF_MIN_SPEED := 260.0
const SPLATTER_STUN_TICKS := 12     # comedic bird-splatter flinch, no damage

# Owner-approved on-beat reward policy (AGENTS.md §9 Owner Decisions Log):
# +15 Crowd Hype and damage x1.15, judged at input time.
const HYPE_MAX := 100
const ON_BEAT_HYPE := 15               # [TODO] amount is a placeholder value
const ON_BEAT_DAMAGE_MULT := 1.15

# 100% Crowd Hype Surge (owner decision, AGENTS.md §9 item 10): a full meter buys ~5 s
# of momentum — 1.20x damage and 25% faster attack recovery — then the meter resets to 0.
const HYPE_SURGE_TICKS := 300
const SURGE_DAMAGE_MULT := 1.20
const SURGE_RECOVERY_MULT := 0.75

# Record Static Parry (§9 item 13): guard tapped on the beat negates the strike.
const PARRY_WINDOW_TICKS := 10        # ~167 ms after the on-beat guard press
const PARRY_HYPE := 20
const PARRY_ATTACKER_STUN_TICKS := 18 # long enough to punish

# Grab / directional throw / throw break (AGENTS.md §9 item 18, Def Jam-inspired).
const GRAB_RANGE := 96.0              # centre-to-centre, owner-specified close range
const GRAB_STARTUP_TICKS := 5         # fast: beats a held guard before it can react
const GRAB_TECH_TICKS := 8            # defender's break window, in ticks
const GRAB_HOLD_TICKS := 16           # how long the attacker holds before committing
const GRAB_RECOVERY_TICKS := 12
const GRAB_HOLD_GAP := 46.0           # victim stands this far in front of the attacker
const THROW_FORWARD_DAMAGE := 14
const THROW_FORWARD_HYPE := 15
const THROW_BACK_DAMAGE := 12
const THROW_BACK_HYPE := 18
const THROW_LAUNCH := Vector2(520.0, -420.0)
const THROW_BACK_LAUNCH := Vector2(160.0, -260.0)
const THROW_SPIN_TICKS := 18          # launched pose -> tumble pose
const THROW_BREAK_PUSH := 200.0       # mutual shove-apart
const THROW_BREAK_STUN := 10          # no damage, just the standoff
const WALL_SLAM_BONUS := 4            # extra damage off a speaker stack
const WALL_SLAM_BOUNCE := 0.62        # how much horizontal speed comes back
## Sand stage speaker stacks: 40-wide walls at x 20 / 1260, so a 60-wide fighter's
## centre can reach 70 / 1210. Those are the points a thrown body slams the stack.
const STAGE_LEFT := 70.0
const STAGE_RIGHT := 1210.0

# Best-of-3 round flow (§9 item 14): the match controller freezes input while it resets.
var input_locked: bool = false

# Hitstop, in ticks. KO uses its own value.
const HITSTOP_TICKS := {&"jab": 4, &"strong": 7, &"tump": 7, &"upper_box": 7}
const KO_HITSTOP_TICKS := 9
const SHAKE_LIGHT := 0.35
const SHAKE_HEAVY := 0.7
const SHAKE_SECONDS := 0.12

# Sprite placement per animation, in texture pixels (before the node's 0.25 scale):
# offset.y = canvas_height / 2 - anchor_y. The pose frame is 1536x1024 and the walk
# keys are 460x620, so their origins cannot share one offset. [TODO] the walk scale
# was matched by eye against the pose frames; confirm it on screen.
const ANIM_OFFSET := {
	&"idle": Vector2(0, -388), &"crouch": Vector2(0, -388),
	&"jab": Vector2(0, -388), &"box_startup": Vector2(0, -388),
	&"box_recovery": Vector2(0, -388),
	&"fire_ground": Vector2(0, -388),
	&"launched": Vector2(0, -98), &"tumble": Vector2(0, -98), &"hitstun": Vector2(0, -98),
	&"salute": Vector2(0, -98), &"fire_air": Vector2(0, -98),
	&"jump": Vector2(0, -98),          # pelvis-anchored airborne pose, 10_fire_airborne
	&"walk": Vector2(0, -256),
	&"knockdown": Vector2(0, -399),    # 17_seated_landing, bottom 911
	&"ko": Vector2(0, -426),           # 02_knockout, bottom 938
	# Selected 512x512 frames (offset = 256 - median sole row of that animation).
	# Soles measured per frame: 488-494, so each animation keeps its own baseline.
	&"guard_entry": Vector2(0, -235),  # mic-defence 01-02, soles 491-492
	&"block": Vector2(0, -235),        # mic-defence 03-04, soles 492
	&"guard_recovery": Vector2(0, -235),  # mic-defence 05-06, soles 491
	&"sparta_startup": Vector2(0, -234),  # sparta-kick 01-03, soles 488-490
	&"sparta_active": Vector2(0, -234),   # sparta-kick 04, sole 490
	&"sparta_recovery": Vector2(0, -234), # sparta-kick 05-06, soles 488-490
	&"skank": Vector2(0, -238),        # skank 01-05, soles 492-494 (grounded dance loop)
	&"lightah": Vector2(0, -168),      # lightah 03-04, airborne (sole rows 423-425)
	# Foot-off-ground BOX contact (baseball-pitch lean), 1024x1536: planted sole at row
	# 1406, planted-foot centre x 402, crown-to-sole 1202 px. y = 768 - 1406 = -638;
	# x puts the planted foot at the +37.5 px the pack's 12/13/14 feet share.
	&"box_active": Vector2(479, -638),
}

# Selected frames are 512x512, not 1536x1024, so they need their own display scale.
# 0.257 makes a 477 px standing figure render at the pack's 122.5 px (490 px at 0.25).
# [TODO] confirm on screen; individual frames vary by a few px in alpha height.
const BASE_SPRITE_SCALE := 0.25
const ANIM_SCALE := {
	"guard_entry": 0.257, "block": 0.257, "guard_recovery": 0.257,
	"sparta_startup": 0.257, "sparta_active": 0.257, "sparta_recovery": 0.257,
	"skank": 0.257, "lightah": 0.257,
	# 121.75 px target (pack idle 487 px at 0.25) / 1202 px crown-to-sole.
	"box_active": 0.1013,
}
const ANIM_OFFSET_DEFAULT := Vector2(0, -388)

# Import-cache cap compensation (AGENTS.md §9 item 17). `process/size_limit=512` in the
# .import files decodes the big frames smaller, so the pixel-space ANIM_OFFSET/ANIM_SCALE
# above are divided/multiplied by the same factor. Values are the longest side of the
# original art, so an uncapped import (ratio 1.0) behaves exactly as before.
const ANIM_SOURCE_MAX := {
	"walk": 620.0,
	"guard_entry": 512.0, "block": 512.0, "guard_recovery": 512.0,
	"sparta_startup": 512.0, "sparta_active": 512.0, "sparta_recovery": 512.0,
	"skank": 512.0, "lightah": 512.0,
}
const ANIM_SOURCE_MAX_DEFAULT := 1536.0

# Attack data. [TODO] move to data-driven move resources (§5). Damage values are from §3.
# Active window is polled from the tick after the hitbox is enabled (one-tick lag).
# tump and upper_box are runnable placeholders: no art and no ported frame data yet.
var attacks: Dictionary = {
	&"jab": {
		"anim_startup": &"jab", "anim_active": &"jab", "anim_recovery": &"jab",
		"startup": 4, "active": 3, "recovery": 9,
		"damage": 8, "blocked_damage": 2,
		"hitstun": 14, "knockback": Vector2(160, 0), "knockdown": false,
		"hitbox_pos": Vector2(84, -110), "hitbox_size": Vector2(84, 38),
	},
	# K = BOX (head/backhand). Poses 12/13/14 = startup/contact/recovery.
	&"strong": {
		"anim_startup": &"box_startup", "anim_active": &"box_active", "anim_recovery": &"box_recovery",
		"startup": 9, "active": 4, "recovery": 18,
		"damage": 15, "blocked_damage": 4,
		"hitstun": 22, "knockback": Vector2(260, -60), "knockdown": false,
		"hitbox_pos": Vector2(96, -125), "hitbox_size": Vector2(108, 54),
	},
	# L = TUMP, played by the selected Sparta kick frames: 01-03 startup, 04 contact,
	# 05-06 recovery. Contact is the extended kick, so the box sits at stomach height.
	# [TODO] frame data still not ported; the timing below is hand-set to the art.
	&"tump": {
		"anim_startup": &"sparta_startup", "anim_active": &"sparta_active", "anim_recovery": &"sparta_recovery",
		"startup": 12, "active": 4, "recovery": 12,
		"damage": 15, "blocked_damage": 4,
		"hitstun": 20, "knockback": Vector2(220, -20), "knockdown": false,
		"hitbox_pos": Vector2(88, -78), "hitbox_size": Vector2(104, 52),
	},
	# I = UPPER BOX (rising backhand). [TODO] frame data, reach and art.
	&"upper_box": {
		"anim_startup": &"jab", "anim_active": &"jab", "anim_recovery": &"jab",
		"startup": 8, "active": 4, "recovery": 16,
		"damage": 15, "blocked_damage": 4,
		"hitstun": 22, "knockback": Vector2(180, -120), "knockdown": false,
		"hitbox_pos": Vector2(70, -132), "hitbox_size": Vector2(92, 96),
	},
}

# PROVISIONAL dev defaults, registered only for the p1_ prefix and only if missing.
# Move to Project Settings > Input Map. crouch (C) and taunt (T) are not specified in AGENTS.md.
const DEFAULT_P1_KEYS := {
	"left": [KEY_A, KEY_LEFT],
	"right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_W, KEY_UP],
	"guard": [KEY_S, KEY_DOWN],
	"light": [KEY_J],
	"heavy": [KEY_K],
	"tump": [KEY_L],
	"upper_box": [KEY_I],
	"crouch": [KEY_C],
	"taunt": [KEY_T],
	"grab": [KEY_U],
}

# Single transition authority (§5). Anything not listed is rejected.
const LEGAL := {
	State.IDLE: [State.WALK, State.JUMP, State.CROUCH, State.ATTACK_STARTUP, State.TAUNT, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRAB, State.GRABBED],
	State.WALK: [State.IDLE, State.JUMP, State.CROUCH, State.ATTACK_STARTUP, State.TAUNT, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRAB, State.GRABBED],
	State.JUMP: [State.IDLE, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRABBED],       # air attacks [TODO]
	State.CROUCH: [State.IDLE, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRABBED],     # low moves [TODO]
	State.ATTACK_STARTUP: [State.ATTACK_ACTIVE, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRABBED],
	State.ATTACK_ACTIVE: [State.ATTACK_RECOVERY, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRABBED],
	State.ATTACK_RECOVERY: [State.IDLE, State.ATTACK_STARTUP, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRABBED],
	State.TAUNT: [State.IDLE, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRABBED],
	State.HITSTUN: [State.IDLE, State.KNOCKDOWN, State.KO, State.GRABBED],
	State.KNOCKDOWN: [State.IDLE, State.KO],
	State.KO: [],
	# The grab chain: attacker holds, victim waits out the tech window, then flies.
	State.GRAB: [State.IDLE, State.HITSTUN, State.KNOCKDOWN, State.KO, State.GRABBED],
	State.GRABBED: [State.IDLE, State.HITSTUN, State.THROWN, State.KNOCKDOWN, State.KO],
	State.THROWN: [State.IDLE, State.KNOCKDOWN, State.KO],
}

# ---- Runtime state -----------------------------------------------------------
var state: State = State.IDLE
var state_frame: int = 0
var facing: int = 1
var health: int = 0
var hype: int = 0
var guarding: bool = false                 # defensive flag (no BLOCK in the state enum, per §5)
var command: Command = Command.new()

var _tick_count: int = 0
var _attack_id: StringName = &""
var _attack: Dictionary = {}
var _input_beat: Dictionary = {}
var _taunt_beat: Dictionary = {}
var _hit_targets: Array[BaseFighter] = []
var _pending_strikes: Array[Dictionary] = []
var _resolve_queued: bool = false
var _snap_guarding: bool = false
var _buffered: Dictionary = {}
var _stun_frames: int = 0
var _stun_is_block: bool = false
var _hitstop_frames: int = 0
var _surge_ticks: int = 0
var _half_hype_awarded: bool = false
var _guard_beat: Dictionary = {}
var _guard_pressed_tick: int = -999
var _guard_ticks: int = 0
var _guard_recovering: bool = false
# Grab / throw runtime.
var _grab_target: BaseFighter = null
var _grab_hold: int = 0
var _grab_recovery: int = 0
var _grabbed_by: BaseFighter = null
var _grab_tech_ticks: int = 0
var _wall_bounced: bool = false
var _was_on_floor: bool = true
var _fall_speed: float = 0.0
var _step_ticks: int = 0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var body_shape: CollisionShape2D = $Body
@onready var hurt_shape: CollisionShape2D = $Hurtbox/Shape
@onready var hitbox: Area2D = $Hitbox
@onready var hit_shape: CollisionShape2D = $Hitbox/Shape
@onready var dust: CPUParticles2D = get_node_or_null("Dust") as CPUParticles2D


func _ready() -> void:
	add_to_group("fighters")          # geometric strike checks find opponents through this group
	health = max_health
	if use_local_input:
		_ensure_default_actions()
	_set_hitbox_active(false)
	_apply_stance(false)
	_play_state_anim()
	health_changed.emit(health, max_health)
	hype_changed.emit(hype, HYPE_MAX)


# =========================================================================
# Tick
# =========================================================================
func _physics_process(_delta: float) -> void:
	# The surge runs on the wall clock: hitstop must not extend the boost.
	if _surge_ticks > 0:
		_surge_ticks -= 1
		if _surge_ticks == 0:
			hype = 0
			_half_hype_awarded = false
			hype_changed.emit(hype, HYPE_MAX)

	# Hitstop freezes state logic but keeps the body moving so nothing tunnels.
	if _hitstop_frames > 0:
		_hitstop_frames -= 1
		move_and_slide()
		return

	_tick_count += 1
	state_frame += 1
	if use_local_input:
		command = _poll_local_input()
	if input_locked:
		command = Command.new()     # round announce / KO: no actions, physics still runs

	match state:
		State.IDLE, State.WALK: _tick_grounded()
		State.CROUCH: _tick_crouch()
		State.JUMP: _tick_jump()
		State.ATTACK_STARTUP: _tick_attack_startup()
		State.ATTACK_ACTIVE: _tick_attack_active()
		State.ATTACK_RECOVERY: _tick_attack_recovery()
		State.TAUNT: _tick_taunt()
		State.HITSTUN: _tick_hitstun()
		State.KNOCKDOWN: _tick_knockdown()
		State.KO: _tick_ko()
		State.GRAB: _tick_grab()
		State.GRABBED: _tick_grabbed()
		State.THROWN: _tick_thrown()

	# Guard presentation phases: refresh the animation when a phase expires.
	if guarding or _guard_recovering:
		_guard_ticks += 1
		if guarding and _guard_ticks == GUARD_ENTRY_TICKS:
			_play_state_anim()
		elif _guard_recovering and _guard_ticks == GUARD_RECOVERY_TICKS:
			_guard_recovering = false
			_play_state_anim()

	_fall_speed = velocity.y
	move_and_slide()
	_emit_landing_dust()

	# Snapshot for simultaneous resolution, then resolve after every fighter has ticked.
	_snap_guarding = guarding
	if not _pending_strikes.is_empty() and not _resolve_queued:
		_resolve_queued = true
		call_deferred("_resolve_pending_strikes")


# =========================================================================
# FSM core
# =========================================================================
func change_state(new_state: State) -> bool:
	if new_state == state:
		return false
	if not (new_state in LEGAL[state]):
		push_warning("BaseFighter: illegal transition %s -> %s" % [State.keys()[state], State.keys()[new_state]])
		return false
	var old := state
	_exit_state(old)
	if new_state != State.IDLE:
		guarding = false
	state = new_state
	state_frame = 0
	_enter_state(new_state)
	_play_state_anim()
	state_changed.emit(old, new_state)
	return true


func _enter_state(s: State) -> void:
	match s:
		State.ATTACK_STARTUP:
			velocity.x = 0.0
		State.ATTACK_ACTIVE:
			_hit_targets.clear()
			_set_hitbox_active(true)
			_poll_hitbox()      # immediate check: the Area2D only reports overlaps on the next physics frame
		State.TAUNT:
			velocity.x = 0.0
		State.CROUCH:
			velocity.x = 0.0
			_apply_stance(true)
		State.KNOCKDOWN:
			_buffered = {}
			_puff(1.6)                 # heavy knockdown (17_seated_landing) sand burst
		State.HITSTUN:
			_buffered = {}
		State.KO:
			_buffered = {}
			died.emit()


func _exit_state(s: State) -> void:
	match s:
		State.ATTACK_ACTIVE:
			_set_hitbox_active(false)
		State.CROUCH:
			_apply_stance(false)
		State.GRAB:
			_release_grab_target()    # interrupted mid-hold: never leave a victim frozen


func _apply_gravity() -> void:
	if not is_on_floor():
		velocity.y += gravity * get_physics_process_delta_time()


# =========================================================================
# Grounded / crouch / jump
# =========================================================================
func _tick_grounded() -> void:
	_apply_gravity()
	if not is_on_floor():
		change_state(State.JUMP)
		return
	if command.grab:
		_start_grab()             # beats a held guard: the grab never enters receive_strike
		return
	if command.light:
		_start_attack(&"jab", _judge_beat())
		return
	if command.heavy:
		_start_attack(&"strong", _judge_beat())
		return
	if command.tump:
		_start_attack(&"tump", _judge_beat())
		return
	if command.upper_box:
		_start_attack(&"upper_box", _judge_beat())
		return
	if command.taunt:
		var b := _judge_beat()
		if change_state(State.TAUNT):
			_taunt_beat = b
			taunt_started.emit(b)   # risk/reward still undecided (§5 TODO)
		return
	if command.jump:
		velocity.y = jump_velocity
		velocity.x = command.move_x * walk_speed   # takeoff velocity latched [TODO confirm vs TS]
		_puff(1.0)                                 # takeoff kick-up
		change_state(State.JUMP)
		return
	if command.crouch:
		change_state(State.CROUCH)
		return
	if command.guard:
		_set_guarding(true)
		velocity.x = 0.0                           # [TODO] confirm whether TS allows moving while guarding
		change_state(State.IDLE)
		return

	_set_guarding(false)
	if absf(command.move_x) > 0.1:
		_set_facing(int(signf(command.move_x)))
		velocity.x = command.move_x * walk_speed
		_step_ticks += 1
		if _step_ticks % STEP_PUFF_TICKS == 0:
			_puff(0.32)                            # walking footfall
		change_state(State.WALK)
	else:
		_step_ticks = 0
		velocity.x = 0.0
		change_state(State.IDLE)


func _tick_crouch() -> void:
	_apply_gravity()
	velocity.x = 0.0
	if not command.crouch:
		change_state(State.IDLE)


func _tick_jump() -> void:
	_apply_gravity()
	if state_frame > 1 and velocity.y >= 0.0 and is_on_floor():
		change_state(State.IDLE)


# =========================================================================
# Attacks
# =========================================================================
func _start_attack(id: StringName, beat: Dictionary) -> void:
	if not attacks.has(id):
		push_warning("BaseFighter: unknown attack '%s'" % id)
		return
	_attack_id = id
	_attack = attacks[id]
	_input_beat = beat                  # beat quality of the INPUT; contact quality is recorded separately
	_configure_hitbox(_attack)          # facing is latched here and not changed until the attack ends
	if not hype_requires_connect and bool(beat.get("on_beat", false)):
		_add_hype(ON_BEAT_HYPE)         # opt-in: award on trigger instead of on connect
	change_state(State.ATTACK_STARTUP)


func _tick_attack_startup() -> void:
	_apply_gravity()
	_buffer_attack_input()
	if state_frame >= int(_attack["startup"]):
		change_state(State.ATTACK_ACTIVE)


func _tick_attack_active() -> void:
	_apply_gravity()
	_buffer_attack_input()
	_poll_hitbox()
	if state_frame >= int(_attack["active"]):
		change_state(State.ATTACK_RECOVERY)


func _tick_attack_recovery() -> void:
	_apply_gravity()
	_buffer_attack_input()
	# A surging fighter shakes off recovery 25% faster (integer ticks, never below 1).
	var recovery: int = int(_attack["recovery"])
	if is_hype_surging():
		recovery = maxi(1, int(round(float(recovery) * SURGE_RECOVERY_MULT)))
	if state_frame >= recovery:
		var next := _take_buffered_attack()
		if next.is_empty():
			change_state(State.IDLE)
		else:
			_start_attack(next["id"], next["beat"])


func _buffer_attack_input() -> void:
	var id: StringName = &""
	if command.light:
		id = &"jab"
	elif command.heavy:
		id = &"strong"
	elif command.tump:
		id = &"tump"
	elif command.upper_box:
		id = &"upper_box"
	if id != &"":
		_buffered = {"id": id, "tick": _tick_count, "beat": _judge_beat()}


func _take_buffered_attack() -> Dictionary:
	if _buffered.is_empty():
		return {}
	var fresh := _tick_count - int(_buffered["tick"]) <= INPUT_BUFFER_TICKS
	var out := _buffered if fresh else {}
	_buffered = {}
	return out


func _configure_hitbox(a: Dictionary) -> void:
	var size: Vector2 = a["hitbox_size"]
	var pos: Vector2 = a["hitbox_pos"]
	(hit_shape.shape as RectangleShape2D).size = size
	hit_shape.position = Vector2(pos.x * facing, pos.y)


func _set_hitbox_active(on: bool) -> void:
	hitbox.set_deferred("monitoring", on)
	hit_shape.set_deferred("disabled", not on)


## Strike volume, in world space, from the attack data and the latched facing.
func _hitbox_rect() -> Rect2:
	var size: Vector2 = _attack.get("hitbox_size", Vector2.ZERO)
	var pos: Vector2 = _attack.get("hitbox_pos", Vector2.ZERO)
	var centre := global_position + Vector2(pos.x * facing, pos.y)
	return Rect2(centre - size * 0.5, size)


## Body rectangle opponents can hit. Simulation shape, independent of the sprite.
func hurt_rect() -> Rect2:
	var size := crouch_size if state == State.CROUCH else stand_size
	return Rect2(global_position + Vector2(-size.x * 0.5, -size.y), size)


## Collect only. Damage is applied after all fighters tick (no node-order advantage).
## Uses rectangle overlap rather than Area2D overlap so a one-tick active window still lands:
## Area2D monitoring changes only refresh on the next physics frame, which is why contacts
## were being missed on the first active tick.
func _poll_hitbox() -> void:
	var volume := _hitbox_rect()
	for node in get_tree().get_nodes_in_group("fighters"):
		var target := node as BaseFighter
		if target == null or target == self or target in _hit_targets:
			continue
		if not volume.intersects(target.hurt_rect()):
			continue
		_hit_targets.append(target)             # one hit per strike
		_pending_strikes.append({
			"target": target,
			"attack_id": _attack_id,
			"attack": _attack,
			"input_beat": _input_beat,
			"contact_beat": _judge_beat(),      # separate from collision result (§5)
		})


func _resolve_pending_strikes() -> void:
	_resolve_queued = false
	var strikes := _pending_strikes
	_pending_strikes = []
	for s in strikes:
		var target := s["target"] as BaseFighter
		if not is_instance_valid(target):
			continue
		var result := target.receive_strike(self, s)
		var ignored := bool(result.get("ignored", false))
		var stop := KO_HITSTOP_TICKS if result.get("ko", false) else int(HITSTOP_TICKS.get(s["attack_id"], 7))
		if not ignored:
			_apply_hitstop(stop)
			target._apply_hitstop(stop)
			camera_shake_requested.emit(SHAKE_LIGHT if stop <= 4 else SHAKE_HEAVY, SHAKE_SECONDS)
		if hype_requires_connect and bool((s["input_beat"] as Dictionary).get("on_beat", false)):
			_add_hype(ON_BEAT_HYPE)
		strike_resolved.emit(self, target, result)


func _apply_hitstop(ticks: int) -> void:
	_hitstop_frames = maxi(_hitstop_frames, ticks)


# =========================================================================
# Sand stage presentation (cosmetic — AGENTS.md §9)
# =========================================================================
## One sand puff at the feet. Uses the Dust CPUParticles2D child when it exists, so
## the base scene still works without stage art. Strength 0.3 = footfall, 1.0 = jump
## takeoff, 1.6 = heavy knockdown.
func _puff(strength: float) -> void:
	if dust == null:
		return
	dust.amount = int(clampf(6.0 + 16.0 * strength, 6.0, 40.0))
	dust.initial_velocity_min = 24.0 + 26.0 * strength
	dust.initial_velocity_max = 74.0 + 96.0 * strength
	dust.restart()
	dust.emitting = true


func _emit_landing_dust() -> void:
	var grounded := is_on_floor()
	if grounded and not _was_on_floor and _fall_speed > LANDING_PUFF_MIN_SPEED:
		_puff(clampf(_fall_speed / 1200.0, 0.5, 1.8))
	_was_on_floor = grounded


## Rare bird splatter (AGENTS.md §9). A brief comedic flinch only: no damage and no
## strike resolution. Returns false when the fighter is downed, mid-air or already
## recovering, in which case the drop keeps falling and may splat the sand instead.
func receive_splatter(source_x: float) -> bool:
	if state in [State.KO, State.KNOCKDOWN] or not is_on_floor():
		return false
	velocity.x = signf(global_position.x - source_x) * 70.0
	_begin_stun(SPLATTER_STUN_TICKS, false)
	camera_shake_requested.emit(SHAKE_LIGHT * 0.5, 0.08)
	return true


func _add_hype(amount: int) -> void:
	if _surge_ticks > 0:
		return                          # the meter is held full until the surge expires
	var before := hype
	hype = clampi(hype + amount, 0, HYPE_MAX)
	if hype != before:
		hype_changed.emit(hype, HYPE_MAX)
	# 50 % is a crowd reaction of its own; 100 % escalates into the surge.
	if not _half_hype_awarded and hype >= int(HYPE_MAX * 0.5):
		_half_hype_awarded = true
		hype_milestone_reached.emit(50)
	if hype >= HYPE_MAX:
		_start_hype_surge()


## A full Crowd Hype meter: boost now, hold the bar at 100, reset to 0 when it expires.
func _start_hype_surge() -> void:
	_surge_ticks = HYPE_SURGE_TICKS
	hype_surge_started.emit(HYPE_SURGE_TICKS / 60.0)
	camera_shake_requested.emit(SHAKE_LIGHT, SHAKE_SECONDS)


func is_hype_surging() -> bool:
	return _surge_ticks > 0


func hype_surge_seconds_left() -> float:
	return _surge_ticks / 60.0


# =========================================================================
# Taunt — plays the skank pose; an on-beat completion awards hype
# =========================================================================
func _tick_taunt() -> void:
	_apply_gravity()
	if state_frame >= TAUNT_TICKS:
		if bool(_taunt_beat.get("on_beat", false)):
			_add_hype(ON_BEAT_HYPE)       # [TODO] amount and interruptibility
		_taunt_beat = {}
		change_state(State.IDLE)


# =========================================================================
# Grab / directional throw / throw break (AGENTS.md §9 item 18)
# =========================================================================
## Grab start: a 5-tick reach window, then the 96 px check. The attempt is fast enough
## that a held guard has no answer — nothing in this path enters receive_strike.
func _start_grab() -> void:
	_grab_target = null
	_grab_hold = 0
	_grab_recovery = 0
	velocity.x = 0.0
	change_state(State.GRAB)


func _tick_grab() -> void:
	_apply_gravity()
	if _grab_recovery > 0:
		# Recovery keeps the break shove: it decays instead of snapping to zero.
		velocity.x = move_toward(velocity.x, 0.0, STUN_FRICTION * get_physics_process_delta_time())
		_grab_recovery -= 1
		if _grab_recovery == 0:
			change_state(State.IDLE)
		return
	velocity.x = 0.0
	if _grab_target == null or not is_instance_valid(_grab_target) \
			or _grab_target.state != State.GRABBED:
		_grab_target = null              # the hold ended by other means (reset, break, KO)
		if state_frame >= GRAB_STARTUP_TICKS:
			var victim := _find_grab_target()
			if victim != null:
				_begin_grab_hold(victim)
			else:
				_grab_recovery = GRAB_RECOVERY_TICKS   # a whiffed grab still commits
		return
	_grab_hold += 1
	_hold_target_in_place()
	if _grab_hold >= GRAB_HOLD_TICKS:
		_throw_target()


## Closest standing, in-front opponent inside the grab reach.
func _find_grab_target() -> BaseFighter:
	var best: BaseFighter = null
	for node in get_tree().get_nodes_in_group("fighters"):
		var other := node as BaseFighter
		if other == null or other == self:
			continue
		if other.state in [State.KO, State.KNOCKDOWN, State.THROWN, State.GRABBED]:
			continue
		if not other.is_on_floor():
			continue
		var offset := other.global_position.x - global_position.x
		if offset * float(facing) < -12.0 or absf(offset) > GRAB_RANGE:
			continue
		return other
	return best


func _begin_grab_hold(victim: BaseFighter) -> void:
	if not victim.begin_grabbed(self):
		_grab_recovery = GRAB_RECOVERY_TICKS
		return
	_grab_target = victim
	_grab_hold = 0
	grab_connected.emit(self, victim)


func _hold_target_in_place() -> void:
	var victim := _grab_target
	victim.global_position.x = clampf(global_position.x + float(facing) * GRAB_HOLD_GAP,
		STAGE_LEFT, STAGE_RIGHT)
	victim.global_position.y = global_position.y
	victim.velocity = Vector2.ZERO
	victim._set_facing(-facing)


## Holding back spins them behind (corner escape); forward or neutral hurls them across
## the sand towards the speaker stacks.
func _throw_target() -> void:
	var victim := _grab_target
	_grab_target = null
	_grab_recovery = GRAB_RECOVERY_TICKS
	if victim == null or not is_instance_valid(victim):
		return
	var holding_back := absf(command.move_x) > 0.1 and signf(command.move_x) != float(facing)
	if holding_back:
		_add_hype(THROW_BACK_HYPE)
		victim.receive_back_throw(self, THROW_BACK_DAMAGE)
		throw_connected.emit(self, victim, &"back")
	else:
		_add_hype(THROW_FORWARD_HYPE)
		victim.receive_forward_throw(self, THROW_FORWARD_DAMAGE)
		throw_connected.emit(self, victim, &"forward")


func _release_grab_target() -> void:
	var victim := _grab_target
	_grab_target = null
	if victim != null and is_instance_valid(victim) and victim.state == State.GRABBED:
		victim.released_from_grab()


# ---- victim side -------------------------------------------------------------
## Called by the attacker. Refuses when the victim cannot be held.
func begin_grabbed(attacker: BaseFighter) -> bool:
	if state in [State.KO, State.KNOCKDOWN, State.THROWN, State.GRABBED]:
		return false
	_set_hitbox_active(false)
	_buffered = {}
	_grabbed_by = attacker
	_grab_tech_ticks = GRAB_TECH_TICKS
	velocity = Vector2.ZERO
	guarding = false
	if not change_state(State.GRABBED):
		_grabbed_by = null
		return false
	return true


func _tick_grabbed() -> void:
	velocity = Vector2.ZERO
	if _grab_tech_ticks > 0:
		_grab_tech_ticks -= 1
		if command.grab:
			_tech_throw()
			return
	if _grabbed_by == null or not is_instance_valid(_grabbed_by) \
			or _grabbed_by.state != State.GRAB:
		_grabbed_by = null
		change_state(State.IDLE)


## Throw break: both fighters shove apart with no damage. The arena flashes the spark.
func _tech_throw() -> void:
	var attacker := _grabbed_by
	_grabbed_by = null
	_grab_tech_ticks = 0
	if attacker != null and is_instance_valid(attacker):
		attacker._on_throw_broken()
		throw_broken.emit(attacker, self)
	velocity.x = -float(facing) * THROW_BREAK_PUSH
	_begin_stun(THROW_BREAK_STUN, false)


func _on_throw_broken() -> void:
	_grab_target = null
	_grab_recovery = GRAB_RECOVERY_TICKS
	velocity.x = -float(facing) * THROW_BREAK_PUSH
	camera_shake_requested.emit(SHAKE_LIGHT, SHAKE_SECONDS)


func released_from_grab() -> void:
	_grabbed_by = null
	_grab_tech_ticks = 0
	if state == State.GRABBED:
		change_state(State.IDLE)


func receive_forward_throw(attacker: BaseFighter, damage: int) -> void:
	var dir := _throw_dir_from(attacker)
	_grabbed_by = null
	_grab_tech_ticks = 0
	_wall_bounced = false
	var ko := _take_throw_damage(damage)
	global_position.x = clampf(global_position.x, STAGE_LEFT, STAGE_RIGHT)
	velocity = Vector2(THROW_LAUNCH.x * dir, THROW_LAUNCH.y)
	if ko:
		change_state(State.KO)
		return
	change_state(State.THROWN)


func receive_back_throw(attacker: BaseFighter, damage: int) -> void:
	var dir := _throw_dir_from(attacker)
	_grabbed_by = null
	_grab_tech_ticks = 0
	_wall_bounced = true           # a spinback is a corner escape, not a wall slam
	var ko := _take_throw_damage(damage)
	# Spun around and dropped behind the attacker.
	global_position.x = clampf(attacker.global_position.x - dir * GRAB_HOLD_GAP,
		STAGE_LEFT, STAGE_RIGHT)
	velocity = Vector2(-dir * THROW_BACK_LAUNCH.x, THROW_BACK_LAUNCH.y)
	if ko:
		change_state(State.KO)
		return
	change_state(State.THROWN)


func _throw_dir_from(attacker: BaseFighter) -> float:
	var dir := float(attacker.facing)
	return dir if dir != 0.0 else 1.0


func _take_throw_damage(amount: int) -> bool:
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	return health == 0


func _tick_thrown() -> void:
	_apply_gravity()
	velocity.x = move_toward(velocity.x, 0.0, 120.0 * get_physics_process_delta_time())
	_check_speaker_wall()
	if state_frame == THROW_SPIN_TICKS:
		_play_state_anim()        # launched -> tumble
	if state_frame > 4 and is_on_floor():
		change_state(State.KNOCKDOWN)


## Speaker-Stack Bounce: an airborne thrown fighter that reaches a stack slams it,
## takes the bonus damage, shakes the camera and comes back onto the sand.
func _check_speaker_wall() -> void:
	if _wall_bounced or is_on_floor():
		return
	# The body stops a fraction short of the collision face, so allow a small margin.
	var side := 0
	if global_position.x <= STAGE_LEFT + 2.0:
		side = -1
	elif global_position.x >= STAGE_RIGHT - 2.0:
		side = 1
	if side == 0:
		return
	_wall_bounced = true
	global_position.x = clampf(global_position.x, STAGE_LEFT, STAGE_RIGHT)
	# The wall collision may already have zeroed velocity.x, so bounce off the side that
	# was hit rather than off the incoming sign.
	var speed := absf(velocity.x)
	velocity.x = -float(side) * maxf(speed * WALL_SLAM_BOUNCE, 220.0)
	velocity.y = minf(velocity.y, -200.0)      # pop back up off the stack
	var ko := _take_throw_damage(WALL_SLAM_BONUS)
	speaker_slam_triggered.emit(self, side)
	camera_shake_requested.emit(SHAKE_HEAVY * 1.5, 0.26)
	if ko:
		change_state(State.KO)


# =========================================================================
# Taking hits / block
# =========================================================================
func receive_strike(attacker: BaseFighter, strike: Dictionary) -> Dictionary:
	if state == State.KO or state == State.KNOCKDOWN:
		return {"ignored": true}               # [TODO] confirm TS rule for hits on downed fighters

	var a: Dictionary = strike["attack"]
	var away := signf(global_position.x - attacker.global_position.x)
	if away == 0.0:
		away = float(attacker.facing)
	# Directional guard, decided from the pre-resolution snapshot.
	var blocked := _snap_guarding \
		and signf(attacker.global_position.x - global_position.x) == float(facing)
	# Record Static Parry: the guard was tapped on the beat, so the strike is negated.
	if blocked and _parry_window_open():
		return _resolve_static_parry(attacker, strike)

	var base: int = int(a["blocked_damage"]) if blocked else int(a["damage"])
	var on_beat := bool((strike["input_beat"] as Dictionary).get("on_beat", false))
	# The 100% Hype Surge multiplies the attacker's damage before the on-beat bonus, so a
	# surging on-beat strike is 1.20 x 1.15. On-beat still applies to chip damage too.
	var surge_mult: float = SURGE_DAMAGE_MULT if attacker.is_hype_surging() else 1.0
	var dmg: int = roundi(base * surge_mult * (ON_BEAT_DAMAGE_MULT if on_beat else 1.0))
	health = maxi(0, health - dmg)
	health_changed.emit(health, max_health)

	var kb: Vector2 = a["knockback"]
	var result := {
		"blocked": blocked, "damage": dmg, "ko": false, "on_beat": on_beat,
		"attacker_surge": attacker.is_hype_surging(),
		"attack_id": strike["attack_id"],
		"input_beat": strike["input_beat"],
		"contact_beat": strike["contact_beat"],
	}

	if health == 0:
		result["ko"] = true
		velocity = Vector2(kb.x * away, kb.y)
		change_state(State.KO)
	elif blocked:
		velocity = Vector2(BLOCK_PUSHBACK * away, 0.0)
		_begin_stun(BLOCKSTUN_TICKS, true)
	elif bool(a["knockdown"]):
		velocity = Vector2(kb.x * away, kb.y)
		change_state(State.KNOCKDOWN)
	else:
		velocity = Vector2(kb.x * away, kb.y)
		_begin_stun(int(a["hitstun"]), false)
	return result


## True while the current guard was pressed inside the beat judgement window.
func _parry_window_open() -> bool:
	if not bool(_guard_beat.get("on_beat", false)):
		return false
	return _tick_count - _guard_pressed_tick <= PARRY_WINDOW_TICKS


## Record Static Parry: no chip damage, no blockstun for the defender; the attacker is
## left stunned and the defender gains hype.
func _resolve_static_parry(attacker: BaseFighter, strike: Dictionary) -> Dictionary:
	_add_hype(PARRY_HYPE)
	camera_shake_requested.emit(SHAKE_HEAVY, SHAKE_SECONDS)
	static_parry_triggered.emit(self, attacker)
	attacker._take_parry_stun(PARRY_ATTACKER_STUN_TICKS)
	return {
		"blocked": true, "parried": true, "damage": 0, "ko": false, "on_beat": false,
		"attacker_surge": attacker.is_hype_surging(),
		"attack_id": strike.get("attack_id", &""),
		"input_beat": strike.get("input_beat", {}),
		"contact_beat": strike.get("contact_beat", {}),
	}


func _take_parry_stun(ticks: int) -> void:
	velocity.x = 0.0
	_buffered = {}
	_begin_stun(ticks, false)


func _begin_stun(frames: int, is_block: bool) -> void:
	_stun_frames = frames
	_stun_is_block = is_block
	if state == State.HITSTUN:
		state_frame = 0
		_play_state_anim()
	else:
		change_state(State.HITSTUN)


func _tick_hitstun() -> void:
	_apply_gravity()
	velocity.x = move_toward(velocity.x, 0.0, STUN_FRICTION * get_physics_process_delta_time())
	if state_frame >= _stun_frames:
		change_state(State.IDLE)


func _tick_knockdown() -> void:
	_apply_gravity()
	velocity.x = move_toward(velocity.x, 0.0, STUN_FRICTION * get_physics_process_delta_time())
	if state_frame >= KNOCKDOWN_FALL_TICKS and is_on_floor():
		change_state(State.IDLE)


func _tick_ko() -> void:
	_apply_gravity()
	velocity.x = move_toward(velocity.x, 0.0, STUN_FRICTION * get_physics_process_delta_time())


# =========================================================================
# Helpers
# =========================================================================
func _judge_beat() -> Dictionary:
	if beat_service == null:
		return {"available": false}
	var j := beat_service.judge()
	j["available"] = true
	return j


## Match-controller reset for a new round. This is deliberately not a gameplay transition,
## so it clears a KO/hitstun state without going through the LEGAL table; no combat tick can
## reach it because the round controller owns the call.
func reset_for_round(at: Vector2) -> void:
	_set_hitbox_active(false)
	_hit_targets.clear()
	_pending_strikes.clear()
	_resolve_queued = false
	_buffered = {}
	_stun_frames = 0
	_stun_is_block = false
	_hitstop_frames = 0
	_surge_ticks = 0
	_half_hype_awarded = false
	_guard_beat = {}
	_guard_pressed_tick = -999
	guarding = false
	_guard_ticks = 0
	_guard_recovering = false
	_grab_target = null
	_grab_hold = 0
	_grab_recovery = 0
	_grabbed_by = null
	_grab_tech_ticks = 0
	_wall_bounced = false
	velocity = Vector2.ZERO
	global_position = at
	health = max_health
	hype = 0
	var old := state
	if old != State.IDLE:
		_exit_state(old)
		state = State.IDLE
		state_frame = 0
		_enter_state(State.IDLE)
		_play_state_anim()
		state_changed.emit(old, State.IDLE)
	health_changed.emit(health, max_health)
	hype_changed.emit(hype, HYPE_MAX)


## For a match controller (auto-face is not implemented here). Ignored mid-attack.
func face_toward(x: float) -> void:
	if state in [State.IDLE, State.WALK, State.CROUCH]:
		_set_facing(1 if x >= global_position.x else -1)


## Canonical mic hand: never mirror. Left-facing art would be <anim>_left.
func _set_facing(dir: int) -> void:
	if dir == 0 or dir == facing:
		return
	facing = dir
	_play_state_anim()


func _set_guarding(v: bool) -> void:
	if v == guarding:
		return
	guarding = v
	_guard_ticks = 0
	_guard_recovering = not v      # releasing the guard plays the mic-defence recovery
	if v:
		# Remember the beat quality of this guard press for the Record Static Parry.
		_guard_beat = _judge_beat()
		_guard_pressed_tick = _tick_count
	_play_state_anim()


## Guard uses the selected mic-defence frames: brace in, hold, release.
func _guard_anim() -> StringName:
	if guarding:
		return &"guard_entry" if _guard_ticks < GUARD_ENTRY_TICKS else &"block"
	if _guard_recovering and _guard_ticks < GUARD_RECOVERY_TICKS:
		return &"guard_recovery"
	return &"idle"


func _apply_stance(crouching: bool) -> void:
	var size := crouch_size if crouching else stand_size
	(body_shape.shape as RectangleShape2D).size = size
	body_shape.position.y = -size.y * 0.5
	(hurt_shape.shape as RectangleShape2D).size = size + Vector2(10, 10)
	hurt_shape.position.y = -size.y * 0.5


## SpriteFrames animation names expected (missing ones are skipped silently):
## idle, walk, jump, crouch, guard_entry, block, guard_recovery, jab,
## sparta_startup, sparta_active, sparta_recovery, hitstun, knockdown, ko, skank.
## The scene also carries the pack's unused poses (launched, tumble, salute, dizzy,
## fire_air, fire_ground) and the lightah prototype for later wiring.
## Left-facing attempts <name>_left first; no such art exists yet, so it falls back.
func _play_state_anim() -> void:
	var anim: StringName = &"idle"
	match state:
		State.IDLE: anim = _guard_anim()
		State.WALK: anim = &"walk"
		State.JUMP: anim = &"jump"
		State.CROUCH: anim = &"crouch"
		State.ATTACK_STARTUP: anim = _attack.get("anim_startup", &"jab")
		State.ATTACK_ACTIVE: anim = _attack.get("anim_active", &"jab")
		State.ATTACK_RECOVERY: anim = _attack.get("anim_recovery", &"jab")
		State.TAUNT: anim = &"skank"
		State.HITSTUN: anim = &"block" if _stun_is_block else &"hitstun"
		State.KNOCKDOWN: anim = &"knockdown"
		State.KO: anim = &"ko"
		State.GRAB: anim = &"jab"           # reaching grab frames, no new art
		State.GRABBED: anim = &"hitstun"    # held: the recoil pose reads as being wrenched
		State.THROWN: anim = &"tumble" if state_frame >= THROW_SPIN_TICKS else &"launched"
	if sprite.sprite_frames == null:
		return
	if facing < 0 and sprite.sprite_frames.has_animation("%s_left" % anim):
		anim = StringName("%s_left" % anim)
	if sprite.sprite_frames.has_animation(anim):
		var key := String(anim).trim_suffix("_left")
		var k := _import_cap_ratio(key, anim)
		sprite.offset = ANIM_OFFSET.get(StringName(key), ANIM_OFFSET_DEFAULT) / k
		var s: float = float(ANIM_SCALE.get(key, BASE_SPRITE_SCALE)) * k
		sprite.scale = Vector2(s, s)
		sprite.play(anim)


## How much the import cap shrank this animation's frames (1.0 when uncapped). The
## offset is authored in texture pixels, so it shrinks with the texture and the scale
## has to grow by the same factor to keep the fighter's on-screen size.
func _import_cap_ratio(key: String, anim: StringName) -> float:
	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation(anim) or frames.get_frame_count(anim) == 0:
		return 1.0
	var tex := frames.get_frame_texture(anim, 0)
	if tex == null:
		return 1.0
	var decoded := float(maxi(tex.get_width(), tex.get_height()))
	if decoded <= 0.0:
		return 1.0
	return float(ANIM_SOURCE_MAX.get(key, ANIM_SOURCE_MAX_DEFAULT)) / decoded


func _poll_local_input() -> Command:
	var c := Command.new()
	c.move_x = Input.get_axis(input_prefix + "left", input_prefix + "right")
	c.jump = Input.is_action_just_pressed(input_prefix + "jump")
	c.guard = Input.is_action_pressed(input_prefix + "guard")
	c.crouch = Input.is_action_pressed(input_prefix + "crouch")
	c.light = Input.is_action_just_pressed(input_prefix + "light")
	c.heavy = Input.is_action_just_pressed(input_prefix + "heavy")
	c.tump = Input.is_action_just_pressed(input_prefix + "tump")
	c.upper_box = Input.is_action_just_pressed(input_prefix + "upper_box")
	c.taunt = Input.is_action_just_pressed(input_prefix + "taunt")
	c.grab = Input.is_action_just_pressed(input_prefix + "grab")
	return c


func _ensure_default_actions() -> void:
	if input_prefix != "p1_":
		return
	for suffix in DEFAULT_P1_KEYS:
		var action: String = input_prefix + suffix
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in DEFAULT_P1_KEYS[suffix]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

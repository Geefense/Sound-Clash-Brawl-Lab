class_name RoundController
extends Node
## Best-of-3 Sound Clash match flow (AGENTS.md §9 item 14).
##
## Owns the round lifecycle around `BaseFighter`: announce → fight → K.O. → next round or
## match end. It drives the arena's day → sunset → night lighting, resets both fighters
## between rounds and publishes the banner text the HUD draws. It never resolves a strike
## or changes a fighter's state directly — `BaseFighter.reset_for_round()` is the only
## entry point, and only between rounds.
##
## R still reloads the whole scene; this controller restarts the match after a result.
##
## Round clock (AGENTS.md §9 backlog item B6): **60 seconds** of live FIGHTING only — frozen
## through the announce, the K.O. banner, the rematch banner and (later) the pause menu. On
## zero the higher remaining health takes the round; an exact health tie replays the round
## with the `WHEEL AND COME AGAIN!` banner and awards no pip.

signal round_started(round_index: int)
signal round_ended(round_index: int, winner: int)
signal match_ended(winner: int)

enum Phase { IDLE, ANNOUNCE, FIGHTING, ROUND_OVER, MATCH_OVER }

const ROUND_BANNERS := [
	"ROUND 1 — AFTERNOON CLASH",
	"ROUND 2 — SUNSET HEAT",
	"FINAL ROUND — LATE-NIGHT DUBPLATE",
]
const KO_BANNER := "K.O.!"
const TIME_BANNER := "TIME!"
const REMATCH_BANNER := "WHEEL AND COME AGAIN!"
const START_POSITIONS := [Vector2(420, 600), Vector2(860, 600)]

@export var enabled: bool = true
@export var rounds_to_win: int = 2
@export var round_seconds: float = 60.0      # owner decision: 60 s, not the prototype's 90 s
@export var announce_seconds: float = 1.8
@export var round_over_seconds: float = 2.4
@export var match_over_seconds: float = 3.2

var p1: BaseFighter
var p2: BaseFighter
var arena: Node

var phase: Phase = Phase.IDLE
var round_index: int = 0
var wins: Array[int] = [0, 0]
var banner: String = ""
var banner_alpha: float = 0.0
var clock: float = 60.0                     # seconds left in the current round

var _replay: bool = false                   # the next transition replays, it does not advance

var _timer: float = 0.0
var _banner_life: float = 0.0
var _banner_age: float = 0.0


func setup(one: BaseFighter, two: BaseFighter, arena_node: Node) -> void:
	p1 = one
	p2 = two
	arena = arena_node
	if not p1.died.is_connected(_on_p1_died):
		p1.died.connect(_on_p1_died)
	if not p2.died.is_connected(_on_p2_died):
		p2.died.connect(_on_p2_died)


func start_match() -> void:
	if p1 == null or p2 == null:
		return
	wins = [0, 0]
	round_index = 0
	_begin_round()


func _begin_round() -> void:
	round_index = clampi(round_index, 0, ROUND_BANNERS.size() - 1)
	clock = round_seconds
	var phase_index: int = mini(round_index, 2)
	# Round 1 snaps straight to afternoon; later rounds cross-fade for 3 s.
	if arena != null and arena.has_method("set_time_of_day"):
		arena.set_time_of_day(phase_index, 0.0 if round_index == 0 else 3.0)
	_reset_fighters()
	_lock(true)
	_show_banner(ROUND_BANNERS[phase_index], announce_seconds + 0.6)
	phase = Phase.ANNOUNCE
	_timer = announce_seconds
	round_started.emit(round_index)


func _reset_fighters() -> void:
	p1.reset_for_round(START_POSITIONS[0])
	p2.reset_for_round(START_POSITIONS[1])
	p1.face_toward(p2.global_position.x)
	p2.face_toward(p1.global_position.x)


func _start_fighting() -> void:
	phase = Phase.FIGHTING
	_lock(false)


func _lock(locked: bool) -> void:
	p1.input_locked = locked
	p2.input_locked = locked


func _on_p1_died() -> void:
	_finish_round(1)


func _on_p2_died() -> void:
	_finish_round(0)


func _finish_round(winner: int, banner_text: String = KO_BANNER) -> void:
	if phase != Phase.FIGHTING:
		return
	wins[winner] += 1
	_lock(true)
	_show_banner(banner_text, round_over_seconds)
	phase = Phase.ROUND_OVER
	_timer = round_over_seconds
	round_ended.emit(round_index, winner)


## 60-second clock expired. Higher remaining health takes it; an exact tie wheels the
## tune back and replays the round without touching either fighter's win count.
func _finish_round_on_time() -> void:
	if phase != Phase.FIGHTING:
		return
	if p1.health == p2.health:
		_replay_round()
		return
	_finish_round(0 if p1.health > p2.health else 1, TIME_BANNER)


func _replay_round() -> void:
	_lock(true)
	_show_banner(REMATCH_BANNER, round_over_seconds)
	phase = Phase.ROUND_OVER
	_timer = round_over_seconds
	_replay = true
	round_ended.emit(round_index, -1)       # -1 = tie, no pip awarded


func _next_round_or_match() -> void:
	if _replay:
		_replay = false
		_begin_round()                      # same round number, same lighting, fresh clock
		return
	if wins[0] >= rounds_to_win or wins[1] >= rounds_to_win:
		var winner := 0 if wins[0] > wins[1] else 1
		_show_banner(REMATCH_BANNER, match_over_seconds)
		phase = Phase.MATCH_OVER
		_timer = match_over_seconds
		match_ended.emit(winner)
		return
	round_index += 1
	_begin_round()


func _process(delta: float) -> void:
	if not enabled or phase == Phase.IDLE:
		return
	_tick_banner(delta)
	match phase:
		Phase.ANNOUNCE:
			_timer -= delta
			if _timer <= 0.0:
				_start_fighting()
		Phase.FIGHTING:
			# The clock only runs during live play, so announce/K.O./rematch never eat it.
			clock = maxf(0.0, clock - delta)
			if clock <= 0.0:
				_finish_round_on_time()
		Phase.ROUND_OVER:
			_timer -= delta
			if _timer <= 0.0:
				_next_round_or_match()
		Phase.MATCH_OVER:
			_timer -= delta
			if _timer <= 0.0:
				start_match()


func _show_banner(text: String, life: float) -> void:
	banner = text
	_banner_life = maxf(life, 0.3)
	_banner_age = 0.0
	banner_alpha = 0.0


func _tick_banner(delta: float) -> void:
	if banner == "":
		return
	_banner_age += delta
	var a := 1.0
	if _banner_age < 0.18:
		a = _banner_age / 0.18
	elif _banner_age > _banner_life - 0.35:
		a = maxf(0.0, (_banner_life - _banner_age) / 0.35)
	banner_alpha = a
	if _banner_age >= _banner_life:
		banner = ""
		banner_alpha = 0.0


## Seconds left on the round clock, and whether it is currently draining (HUD/test hooks).
func time_left() -> float:
	return clock


func clock_running() -> bool:
	return enabled and phase == Phase.FIGHTING


## Test/debug helper: the round number a human would read (1-based).
func round_number() -> int:
	return round_index + 1

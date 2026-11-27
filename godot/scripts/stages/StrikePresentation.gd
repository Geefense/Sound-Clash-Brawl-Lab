class_name StrikePresentation
extends RefCounted
## Per-strike presentation coordinator (PART L, 2026-11-27). Presentation only.
##
## One resolved strike reaches the FX layer from several readings of the same instant: the
## contact itself (`hit`), the counter flag and the on-beat flag — and the finisher can claim
## the same strike's word. Left alone, a heavy counter landed on the beat stacks two sparks, a
## ring and two callout words over one frame of combat. This object owns them instead:
##
##   * `begin()` opens a strike record from the resolution the fight already produces;
##   * `contribute()` adds a cue (`hit`, `counter`, `beat`, `heavy`, `blocked`, `ko`,
##     `featured`); the same cue arriving twice sets one flag twice and never spawns a second
##     effect;
##   * `commit()` fires AT MOST one spark, one word, one bass ring and one note request, then
##     closes the record. A second `commit()` on the same strike is a counted no-op.
##
## Pool-tight priority, in the brief's order: the contact word is placed FIRST so it can take
## the last free label; the contact spark can never be refused (the sheet pool recycles its
## oldest slot); the extra music notes are trimmed before anything else, and the secondary bass
## ring is skipped before the spark or the word is sacrificed.
##
## Nothing here reads or writes a combat value: it is handed the already-resolved `result`
## dictionary and a world point. Its per-strike dictionary is cleared and refilled, so a long
## brawl with thousands of strikes allocates nothing after the first commit.

## Yellow-white contact flash, with a brief red edge when the contact was a heavy counter.
const SPARK_TINT := Color(1.0, 1.0, 0.90, 1.0)
const SPARK_COUNTER_ACCENT := Color(1.0, 0.20, 0.16, 1.0)
## The on-beat bass ring: a green edge that settles to white, drawn smaller than the contact
## flash so it reads as the secondary cue it is.
const RING_EDGE := Color(0.38, 1.0, 0.50, 1.0)
const RING_TINT := Color(1.0, 0.96, 0.62, 1.0)
const RING_SCALE := 0.75
## The `SPEAKER BOX!` blowout: the ring runs its whole green -> gold -> red sequence at 1.6x the
## ordinary ring's size, from the cabinet's own world anchor.
const FINISHER_GREEN := Color(0.32, 1.0, 0.45, 1.0)
const FINISHER_GOLD := Color(1.0, 0.82, 0.22, 1.0)
const FINISHER_RED := Color(1.0, 0.24, 0.20, 1.0)
const FINISHER_RING_SCALE := 1.6
const FEATURED_TINT := Color(1.0, 0.90, 0.40, 1.0)

## How long after the contact the pooled music notes leave the impact, so the spark has started
## to clear before they cross it. A scalar on the arena, never a Timer node.
const NOTE_DELAY := 0.22

var arcade: ArcadeVFX2D = null
var comic: ComicCallout2D = null

## F9 master switch (`TestArena.toggle_strike_fx`). Off makes every trigger return false and
## leaves nothing half-drawn.
var enabled: bool = true

## Reused outcome, cleared and refilled by every commit: no allocation per strike.
var last: Dictionary = {}
var strikes: int = 0
var duplicates: int = 0
var trimmed_notes: int = 0
var trimmed_rings: int = 0

var _duplicate: Dictionary = {"ok": false, "duplicate": true}
var _open: bool = false
var _seq: int = 0
var _hit: bool = false
var _counter: bool = false
var _beat: bool = false
var _heavy: bool = false
var _blocked: bool = false
var _ko: bool = false
var _featured: bool = false
var _attacker: BaseFighter = null
var _target: BaseFighter = null
var _attack_id: StringName = &""
var _pos: Vector3 = Vector3.ZERO
var _downed: bool = false


## Open the record for one resolved strike. `featured` marks a strike whose word belongs to the
## `SPEAKER BOX!` finisher: the ordinary K.O./hit word is then suppressed for this strike only.
func begin(attacker: BaseFighter, target: BaseFighter, result: Dictionary, world_pos: Vector3,
		featured: bool = false) -> void:
	if _open:
		# A second resolution over an open record is one strike counted twice: keep the first
		# and count it, so the dedup is measurable instead of silent.
		duplicates += 1
		return
	_open = true
	_seq += 1
	_attacker = attacker
	_target = target
	_pos = world_pos
	_attack_id = StringName(result.get("attack_id", &""))
	var parried := bool(result.get("parried", false)) or bool(result.get("ignored", false))
	_blocked = bool(result.get("blocked", false))
	_hit = not (_blocked or parried)
	_counter = bool(result.get("counter", false))
	_beat = bool(result.get("on_beat", false))
	_ko = bool(result.get("ko", false))
	_heavy = _counter or _attack_id in BaseFighter.HEAVY_ATTACK_IDS
	_featured = featured
	_downed = _ko or (target != null and (target.state == BaseFighter.State.KNOCKDOWN
		or target.state == BaseFighter.State.KO))


## Add one reading of the same strike. Idempotent: `hit` twice is still one spark.
func contribute(flag: StringName) -> void:
	if not _open:
		return
	match flag:
		&"hit":
			_hit = true
		&"counter":
			_counter = true
			_heavy = true
		&"beat":
			_beat = true
		&"heavy":
			_heavy = true
		&"blocked":
			_blocked = true
			_hit = false
		&"ko":
			_ko = true
			_downed = true
		&"featured":
			_featured = true


func is_open() -> bool:
	return _open


## Close the record and fire each cue at most once. Returns the reused outcome dictionary:
## `{ok, duplicate, strike, spark, word, ring, notes, featured}`.
func commit() -> Dictionary:
	if not _open:
		duplicates += 1
		return _duplicate
	_open = false
	strikes += 1
	last.clear()
	last["ok"] = true
	last["duplicate"] = false
	last["strike"] = _seq
	# How much room the callout pool has BEFORE this strike's word is placed. One free label
	# means the word takes the last one, so this strike's extras are trimmed.
	var free_labels := comic.free_label_count() if comic != null else 2
	var word_ok := false
	var spark_ok := false
	var ring_ok := false
	var notes_ok := false
	if enabled:
		# 1. The word first: it is the only cue an exhausted pool can refuse, so the contact
		#    word claims the last free label before this strike spends anything else.
		if _featured:
			pass                      # the finisher places its own word at the cabinet blowout
		elif _blocked:
			word_ok = _fire_word(&"block")
		else:
			word_ok = _fire_word(&"")
		# 2. The contact flash. Unblocked contacts only, exactly as the shipped layer did.
		if _hit:
			spark_ok = _fire_spark()
		# 3. Secondary cue: the on-beat bass ring on a heavy contact.
		var tight := free_labels <= 1
		if _hit and _beat and _heavy:
			if tight:
				trimmed_rings += 1
			elif arcade != null:
				ring_ok = arcade.play_accent(&"bass_shockwave", _pos, RING_EDGE, RING_TINT,
					1.0, RING_SCALE)
		# 4. Lowest priority: the extra music notes. Trimmed first when the label pool is spent.
		if _hit and (_heavy or _beat):
			if tight:
				trimmed_notes += 1
			else:
				notes_ok = true
	last["spark"] = spark_ok
	last["word"] = word_ok
	last["ring"] = ring_ok
	last["notes"] = notes_ok
	last["featured"] = _featured
	return last


func _fire_word(category: StringName) -> bool:
	if comic == null or _attacker == null:
		return false
	if category == &"block":
		return comic.register_block(_attacker, _pos)
	return comic.register_hit(_attacker, _attack_id, _counter, _beat, _pos, _downed)


func _fire_spark() -> bool:
	if arcade == null:
		return false
	if _counter and _heavy:
		return arcade.play_accent(&"hit_spark", _pos, SPARK_COUNTER_ACCENT, SPARK_TINT, 0.6)
	return arcade.play_at_world(&"hit_spark", _pos, 0.55 if _beat else 0.4, SPARK_TINT)


# =========================================================================
# Finisher cues (SPEAKER BOX!)
# =========================================================================
## The featured word at the cabinet blowout. Routed through here so it shares the layer's
## counters and the F9 switch with every other callout.
func feature_word(phrase: String, world_pos: Vector3) -> bool:
	if not enabled or comic == null:
		return false
	return comic.fire_featured(phrase, world_pos, FEATURED_TINT)


## The full green -> gold -> red ring, at `FINISHER_RING_SCALE` x the ordinary ring.
func finisher_ring(world_pos: Vector3) -> bool:
	if not enabled or arcade == null:
		return false
	return arcade.play_ramp(&"bass_shockwave", world_pos, FINISHER_GREEN, FINISHER_GOLD,
		FINISHER_RED, 1.0, FINISHER_RING_SCALE)


func set_enabled(on: bool) -> void:
	enabled = on


func is_enabled() -> bool:
	return enabled


# =========================================================================
# Headless reporting
# =========================================================================
func reset_counts() -> void:
	strikes = 0
	duplicates = 0
	trimmed_notes = 0
	trimmed_rings = 0
	last.clear()


## Abandon an open record without firing (the boot warm pass never commits a real strike).
func discard() -> void:
	_open = false

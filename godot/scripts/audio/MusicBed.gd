extends Node
## Menu and victory music bed (AGENTS.md §9 item 48).
##
## Combat rounds are deliberately **music-free**: the Sound Clash engine's 6 s round sting,
## tape-delay DJ tags, selector, horn and crowd layers are the only audio between FIGHT! and
## the final blow, so a background loop can never muddy them. This bed starts on the
## Title / Character Select screen, fades out on match start, and returns only after the
## match is won, when the winner poses out.
##
## The three beats are owner-supplied production files under
## `assets/audio/production/beats/`. No research clip, unlicensed track or web stream is
## ever loaded here; local files stay local.

const BEAT_DIR := "res://assets/audio/production/beats/"
const BUS := &"MusicBed"
const SILENT_DB := -60.0
const TITLE_DB := -7.0
const VICTORY_DB := -4.0
const FADE_IN := 0.8
const FADE_OUT := 0.45
## Match start gets a much shorter fade than a screen change: the 6 s round sting must never
## share the speakers with a bed from the previous match (owner playtest, 2026-11-23).
const FIGHT_FADE_OUT := 0.15

## Cycle order is Beat 1 → Beat 2 → Beat 3 → Off. The `source` names are the exact owner
## uploads, kept for provenance in AGENTS.md §9 / the beats README.
const BEATS := [
	{"file": "beat_01.mp3", "title": "Buck Shots", "source": "Buck Shots (2) wonder productions .mp3"},
	{"file": "beat_02.mp3", "title": "Easy Rider", "source": "Easy Rider.mp3"},
	{"file": "beat_03.mp3", "title": "Lonely Gyal", "source": "Lonely Gyal wonder productions.mp3"},
]

enum Mode { OFF, TITLE, VICTORY }

var mode: Mode = Mode.OFF
var index: int = 0
## Which screen owns the bed when it is off: TITLE or VICTORY. M resumes into this context.
var context: Mode = Mode.TITLE
var player: AudioStreamPlayer = null

var _streams: Array[AudioStream] = []
var _tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()
	player = AudioStreamPlayer.new()
	player.name = "BeatPlayer"
	player.bus = BUS
	player.volume_db = SILENT_DB
	add_child(player)
	_load_beats()


func _load_beats() -> void:
	for beat in BEATS:
		var stream := load(BEAT_DIR + String(beat["file"])) as AudioStream
		if stream == null:
			push_warning("MusicBed: could not load %s" % beat["file"])
			_streams.append(null)
			continue
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		_streams.append(stream)


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS)
	AudioServer.set_bus_send(index, &"Master")
	AudioServer.set_bus_volume_db(index, -4.0)


# =========================================================================
# Screen hooks
# =========================================================================
## Title / Character Select: start the active beat as soon as the screen loads.
func play_title() -> bool:
	context = Mode.TITLE
	return _start(index, Mode.TITLE)


## Match won: advance the rotation and fade the next beat in under the victory pose.
func play_victory() -> bool:
	context = Mode.VICTORY
	index = (index + 1) % BEATS.size()
	return _start(index, Mode.VICTORY)


## Match start: fade the bed out so the round sting takes over. The fade completes during
## the announce, before FIGHT!, and no beat is playing during the round itself.
func stop_for_fight() -> void:
	context = mode if mode != Mode.OFF else context
	mode = Mode.OFF
	if player == null:
		return
	if not player.playing:
		player.stop()
		player.volume_db = SILENT_DB
		return
	_fade_to(SILENT_DB, FIGHT_FADE_OUT, true)


## Hard cut, no fade and no queued tween. Every round start (Match 1's, Match 2's and every
## rematch) calls this *before* the 6 s round sting: a victory bed started on the previous
## match's result kept playing under the next match because a rematch restarts inside the
## same scene and never re-runs `TestArena._ready()` (owner playtest, 2026-11-23).
func stop() -> void:
	mode = Mode.OFF
	_stop_now()
	if player != null:
		player.volume_db = SILENT_DB


## M on Title/Select and the post-KO screen: Beat 1 → Beat 2 → Beat 3 → Off → Beat 1.
func cycle() -> String:
	var ctx := context if mode == Mode.OFF else mode
	if ctx != Mode.TITLE and ctx != Mode.VICTORY:
		ctx = Mode.TITLE
	if mode == Mode.OFF:
		_start(0, ctx)
	elif index < BEATS.size() - 1:
		_start(index + 1, ctx)
	else:
		_stop_now()
		mode = Mode.OFF
		context = ctx
	return state_name()


# =========================================================================
# Playback
# =========================================================================
func _start(at: int, as_mode: Mode) -> bool:
	if player == null or _streams.is_empty():
		return false
	index = clampi(at, 0, _streams.size() - 1)
	var stream := _streams[index]
	if stream == null:
		return false
	mode = as_mode
	context = as_mode
	player.stream = stream
	player.volume_db = SILENT_DB
	player.stop()
	player.play()
	_fade_to(TITLE_DB if as_mode == Mode.TITLE else VICTORY_DB, FADE_IN)
	return true


func _fade_to(db: float, seconds: float, stop_after: bool = false) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(player, "volume_db", db, seconds)
	if stop_after:
		_tween.tween_callback(player.stop)


func _stop_now() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if player != null:
		player.stop()


# =========================================================================
# Read-only state for the UI and the headless checks
# =========================================================================
func beat_count() -> int:
	return BEATS.size()


func stream_at(i: int) -> AudioStream:
	if i < 0 or i >= _streams.size():
		return null
	return _streams[i]


func beat_title(i: int) -> String:
	if i < 0 or i >= BEATS.size():
		return ""
	return String(BEATS[i]["title"])


func beat_file(i: int) -> String:
	if i < 0 or i >= BEATS.size():
		return ""
	return String(BEATS[i]["file"])


func state_name() -> String:
	if mode == Mode.OFF:
		return "off"
	return "beat_%d" % (index + 1)


func current_db() -> float:
	return player.volume_db if player != null else SILENT_DB


func is_playing() -> bool:
	return player != null and player.playing


func in_title() -> bool:
	return mode == Mode.TITLE


func in_victory() -> bool:
	return mode == Mode.VICTORY


func is_off() -> bool:
	return mode == Mode.OFF


func label() -> String:
	if state_name() == "off":
		return "MUSIC OFF"
	return "BEAT %d — %s" % [index + 1, beat_title(index).to_upper()]

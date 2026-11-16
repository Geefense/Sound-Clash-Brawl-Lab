class_name BeatService
extends Node
## Beat service (AGENTS.md §5). Audio-clock based when audio_player is playing.
## Wall-clock fallback is DEV ONLY (no approved music yet); it is not a long-song clock.

signal beat(beat_index: int)

@export var bpm: float = 132.0                   # from the assets/flow_exports/walk reference
@export var beat_offset_sec: float = 0.0         # [TODO] measure first-downbeat offset in the reference audio
@export var judgement_window_ms: float = 70.0    # [TODO] PLACEHOLDER: no approved window exists
@export var latency_calibration_ms: float = 0.0  # [TODO] player calibration
@export var audio_player: AudioStreamPlayer      # assign the music/click player

var _wall_origin_usec: int = 0
var _last_beat_index: int = -1


func _ready() -> void:
	_wall_origin_usec = Time.get_ticks_usec()


func beat_length_sec() -> float:
	return 60.0 / bpm


func has_audio_clock() -> bool:
	return audio_player != null and audio_player.playing


func clock_time() -> float:
	if has_audio_clock():
		return audio_player.get_playback_position() \
			+ AudioServer.get_time_since_last_mix() \
			- AudioServer.get_output_latency()
	return float(Time.get_ticks_usec() - _wall_origin_usec) / 1_000_000.0


func _grid_time() -> float:
	return clock_time() - beat_offset_sec - latency_calibration_ms / 1000.0


func beat_index() -> int:
	return int(floor(_grid_time() / beat_length_sec()))


## 0..1 position *inside* the current beat, for presentation that grooves on the grid
## (idle bob, crowd sway). Never used for judgement — §9 item 1 judges the input.
func beat_phase() -> float:
	return fposmod(_grid_time() / beat_length_sec(), 1.0)


## Signed error to the nearest beat in ms. Negative = early, positive = late.
func nearest_beat_error_ms() -> float:
	var beat_len := beat_length_sec()
	var phase := fposmod(_grid_time() / beat_len, 1.0)
	var err := phase if phase <= 0.5 else phase - 1.0
	return err * beat_len * 1000.0


## Judgement record. Pure data: gameplay decides what (if anything) it means.
func judge() -> Dictionary:
	var e := nearest_beat_error_ms()
	return {
		"error_ms": e,
		"on_beat": absf(e) <= judgement_window_ms,
		"audio_clock": has_audio_clock(),
	}


func _process(_delta: float) -> void:
	var idx := beat_index()
	if idx != _last_beat_index:
		_last_beat_index = idx
		beat.emit(idx)

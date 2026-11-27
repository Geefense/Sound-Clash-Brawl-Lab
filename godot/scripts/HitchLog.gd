class_name HitchLog
extends RefCounted

## Fix pass commit 3: a frame that took longer than a 30 fps frame is a hitch, and on a Chromebook
## the only way to name one is to remember the event that was on screen when it happened.
##
## The ring is built once in `_init` at a fixed CAPACITY, so `record_frame()` is a float compare
## on every normal frame — no Array, no String, no PackedByteArray is touched unless a spike
## actually happens. The console line for a spike is formatted once, at record time, and the
## overlay reads the cached lines instead of rebuilding them per frame.
const CAPACITY := 16
const SPIKE_MS := 33.0
const SHOWN := 6

var _ms := PackedFloat32Array()
var _frames := PackedInt32Array()
var _tags: Array[StringName] = []
var _lines: Array[String] = []
var _next := 0
var _stored := 0
var _frame_index := 0
var _spikes := 0
var _worst_ms := 0.0
var _echo := true


func _init() -> void:
	_ms.resize(CAPACITY)
	_frames.resize(CAPACITY)
	_tags.resize(CAPACITY)
	_lines.resize(CAPACITY)
	for i in CAPACITY:
		_tags[i] = &"none"
		_lines[i] = ""


## One call per frame. Returns true only when this frame was logged, so a caller can also react.
func record_frame(delta: float, tag: StringName = &"none") -> bool:
	_frame_index += 1
	var ms := delta * 1000.0
	if ms <= SPIKE_MS:
		return false
	_spikes += 1
	_worst_ms = maxf(_worst_ms, ms)
	_ms[_next] = ms
	_frames[_next] = _frame_index
	_tags[_next] = tag
	_lines[_next] = "%5.1f ms  frame %d  %s" % [ms, _frame_index, String(tag)]
	if _echo:
		print("[hitch] " + _lines[_next])
	_next = (_next + 1) % CAPACITY
	_stored = mini(_stored + 1, CAPACITY)
	return true


## Newest last. Only called when the spike count moved, never per frame.
func recent(count: int = SHOWN) -> Array:
	var out: Array[String] = []
	var take := mini(count, _stored)
	for i in range(take, 0, -1):
		var slot := (_next - i + CAPACITY * 2) % CAPACITY
		out.append(_lines[slot])
	return out


func spike_count() -> int:
	return _spikes


func stored() -> int:
	return _stored


func capacity() -> int:
	return CAPACITY


func worst_ms() -> float:
	return _worst_ms


func total_frames() -> int:
	return _frame_index


func last_tag() -> StringName:
	return _tags[(_next - 1 + CAPACITY) % CAPACITY]


func set_echo(enabled: bool) -> void:
	_echo = enabled


## One line for the F8 overlay: the count, the worst frame and the last tag.
func summary() -> String:
	if _spikes == 0:
		return "HITCHES 0"
	return "HITCHES %d · worst %5.1f ms · last %s" % [_spikes, _worst_ms,
		String(_tags[(_next - 1 + CAPACITY) % CAPACITY])]

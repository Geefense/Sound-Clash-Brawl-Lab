class_name SfxPlayer
extends Node
## Zero-asset arcade SFX (AGENTS.md §9 backlog item B8).
##
## Every cue is synthesised at start-up with `AudioStreamGenerator`, so the build ships no
## audio files, no samples and no extra licences — nothing to download on a Chromebook and
## nothing to add to the `.pck`. Four voices at 22.05 kHz mono keep the buffer cost small.
##
## The arena drives `muted` from the **M** key, which also pauses the click track, so one
## toggle silences everything. Cues are presentation only: they never touch combat state.

const SAMPLE_RATE := 22050.0
const VOICES := 4
const BUFFER_SECONDS := 0.35
const CUES: Array[StringName] = [
	&"hit", &"hit_onbeat", &"block", &"parry", &"slam", &"whoosh", &"clank", &"airhorn", &"ko",
]

var muted: bool = false
var played: int = 0                 # test hook: cues actually queued
var last_cue: StringName = &""      # test hook: the most recent cue

var _players: Array[AudioStreamPlayer] = []
var _playbacks: Array = []          # AudioStreamGeneratorPlayback, or null without an audio device
var _cursor: Array[int] = []
var _data: Array = []               # PackedVector2Array per voice
var _next: int = 0
var _cache: Dictionary = {}


func _ready() -> void:
	# Audio must survive a paused tree (the B3 pause menu will pause the game, not the SFX).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		var generator := AudioStreamGenerator.new()
		generator.mix_rate = SAMPLE_RATE
		generator.buffer_length = BUFFER_SECONDS
		player.stream = generator
		player.volume_db = -4.0
		add_child(player)
		player.play()
		_players.append(player)
		_playbacks.append(player.get_stream_playback())
		_cursor.append(0)
		_data.append(PackedVector2Array())
	# Build every cue once, behind the round announce, so a first hit never allocates.
	for cue in CUES:
		_cue(cue)


func _process(_delta: float) -> void:
	for voice in VOICES:
		_feed(voice)


# =========================================================================
# Public API
# =========================================================================
## Queue a cue on the next free voice. Returns false while muted or when the cue is unknown.
func play(cue: StringName) -> bool:
	if muted:
		return false
	var samples := _cue(cue)
	if samples.is_empty():
		return false
	var voice := _next
	_next = (_next + 1) % VOICES
	# Restart the voice: `play()` resets the generator buffer, which is the only way to drop
	# the tail of the previous cue — `clear_buffer()` asserts when no audio device is mixing
	# (headless), so it must never be called directly.
	var player := _players[voice]
	player.stop()
	player.play()
	_playbacks[voice] = player.get_stream_playback()
	_data[voice] = samples
	_cursor[voice] = 0
	played += 1
	last_cue = cue
	_feed(voice)
	return true


func set_muted(value: bool) -> void:
	muted = value


func toggle_muted() -> bool:
	muted = not muted
	return muted


## Test hooks: sample count and peak amplitude (must stay within [-1, 1] — no clipping).
func cue_length(cue: StringName) -> int:
	return _cue(cue).size()


func cue_peak(cue: StringName) -> float:
	var peak := 0.0
	for sample in _cue(cue):
		peak = maxf(peak, absf(sample.x))
	return peak


# =========================================================================
# Voice feeding
# =========================================================================
func _feed(voice: int) -> void:
	var playback: AudioStreamGeneratorPlayback = _playbacks[voice]
	if playback == null:
		return
	var samples: PackedVector2Array = _data[voice]
	var cursor: int = _cursor[voice]
	if cursor >= samples.size():
		return
	var free_frames := playback.get_frames_available()
	if free_frames <= 0:
		return
	var count := mini(free_frames, samples.size() - cursor)
	playback.push_buffer(samples.slice(cursor, cursor + count))
	_cursor[voice] = cursor + count


# =========================================================================
# Synthesis
# =========================================================================
func _cue(cue: StringName) -> PackedVector2Array:
	if _cache.has(cue):
		return _cache[cue]
	var out := PackedVector2Array()
	match cue:
		&"hit":
			out = _thud(0.16, 200.0, 70.0, 0.9, false)
		&"hit_onbeat":
			out = _thud(0.28, 200.0, 58.0, 1.0, true)
		&"block":
			out = _clank(0.1, 640.0, 0.5)
		&"parry":
			out = _crackle()
		&"slam":
			out = _boom()
		&"whoosh":
			out = _whoosh()
		&"clank":
			out = _clank(0.22, 1080.0, 0.85)
		&"airhorn":
			out = _airhorn()
		&"ko":
			out = _ko()
	_cache[cue] = out
	return out


func _frames(seconds: float) -> int:
	return maxi(1, int(SAMPLE_RATE * seconds))


func _pack(values: PackedFloat32Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(values.size())
	for i in values.size():
		var v := clampf(values[i], -1.0, 1.0)
		out[i] = Vector2(v, v)
	return out


## Punchy body thud: a fast downward pitch sweep plus a noise transient. `sub` adds the
## 55 Hz sub-bass punch reserved for strikes judged on the beat.
func _thud(seconds: float, from_hz: float, to_hz: float, gain: float, sub: bool) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var n := _frames(seconds)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var k := float(i) / float(n)
		var freq := lerpf(from_hz, to_hz, pow(k, 0.45))
		phase += TAU * freq / SAMPLE_RATE
		var body := sin(phase) * exp(-9.0 * k)
		var click := rng.randf_range(-1.0, 1.0) * exp(-70.0 * k) * 0.55
		var value := body * 0.85 + click
		if sub:
			value += sin(TAU * 55.0 * t) * exp(-7.0 * k) * 0.55
		buf[i] = value * gain
	return _pack(buf)


## Throw-break / blocked-hit clank: three inharmonic partials with a fast metallic decay.
func _clank(seconds: float, base_hz: float, gain: float) -> PackedVector2Array:
	var n := _frames(seconds)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var k := float(i) / float(n)
		var t := float(i) / SAMPLE_RATE
		var env := exp(-16.0 * k)
		var value := sin(TAU * base_hz * t) * 0.5 \
			+ sin(TAU * base_hz * 1.63 * t) * 0.3 \
			+ sin(TAU * base_hz * 2.41 * t) * 0.18
		buf[i] = value * env * gain
	return _pack(buf)


## Record Static Parry: stuttering vinyl-static crackle over a 2.4 kHz ring.
func _crackle() -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var n := _frames(0.18)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var k := float(i) / float(n)
		var t := float(i) / SAMPLE_RATE
		# Gate the noise in ~380 Hz slices so it reads as broken static, not a hiss.
		var gate := 1.0 if (int(t * 380.0) % 3) != 0 else 0.12
		var value := sin(TAU * 2400.0 * t) * 0.35 + rng.randf_range(-1.0, 1.0) * 0.75
		buf[i] = value * gate * exp(-6.5 * k) * 0.85
	return _pack(buf)


## Speaker-stack bounce: an 808 cone boom — deep sweep, long decay, hard click.
func _boom() -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var n := _frames(0.55)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / float(n)
		var freq := lerpf(78.0, 36.0, pow(k, 0.35))
		phase += TAU * freq / SAMPLE_RATE
		var body := sin(phase) * exp(-5.0 * k)
		var click := rng.randf_range(-1.0, 1.0) * exp(-90.0 * k) * 0.4
		buf[i] = (body + click) * 0.95
	return _pack(buf)


## Throw whoosh: low-passed noise that swells then falls away.
func _whoosh() -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var n := _frames(0.24)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var smoothed := 0.0
	for i in n:
		var k := float(i) / float(n)
		smoothed = lerpf(smoothed, rng.randf_range(-1.0, 1.0), 0.14)
		var env := sin(PI * k) * (1.0 - k * 0.35)
		buf[i] = smoothed * env * 1.1
	return _pack(buf)


## Dancehall airhorn: a fast rise into a held, detuned saw stack with a little vibrato.
func _airhorn() -> PackedVector2Array:
	var seconds := 0.85
	var n := _frames(seconds)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SAMPLE_RATE
		var k := float(i) / float(n)
		var freq := 330.0 + 185.0 * clampf(k / 0.16, 0.0, 1.0)
		freq *= 1.0 + 0.012 * sin(TAU * 6.5 * t)      # brass-style wobble
		phase += TAU * freq / SAMPLE_RATE
		var saw := 0.0
		for detune in [-0.014, 0.0, 0.014]:
			var p := phase * (1.0 + float(detune))
			saw += (2.0 * (p / TAU - floorf(p / TAU + 0.5))) * 0.34
		var env := minf(1.0, k / 0.05) * clampf((1.0 - k) / 0.3, 0.0, 1.0)
		buf[i] = saw * env * 0.6
	return _pack(buf)


## K.O. drop: a descending arcade sweep with a noise burst on the hit.
func _ko() -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var seconds := 0.95
	var n := _frames(seconds)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var phase := 0.0
	for i in n:
		var k := float(i) / float(n)
		var freq := lerpf(320.0, 46.0, pow(k, 0.7))
		phase += TAU * freq / SAMPLE_RATE
		var sweep := sin(phase) * exp(-2.4 * k) * 0.8
		var hit := rng.randf_range(-1.0, 1.0) * exp(-60.0 * k) * 0.6
		buf[i] = sweep + hit
	return _pack(buf)

class_name SoundClashAudio
extends Node
## Event-driven Sound Clash audio engine (AGENTS.md §9 item 46).
##
## No mandatory pull-up, no combo gate: any strike that does significant damage, knockback,
## stun or knockdown fires the attacker's DJ tag. The tag is routed through the native
## AudioBusLayout chain — AudioEffectDelay → AudioEffectLowPassFilter → AudioEffectReverb —
## so one call cascades ("Feedback! Feedback! feedback…") under the crowd instead of playing
## a dry clip. Priority, per-fighter cooldowns and a global cooldown stop tags, selector
## yells, airhorns and stabs stacking into mud; the crowd is layered (murmur → cheers →
## eruption) and decays back to silence between explosions.
##
## Audio content: the repository still has no approved recordings, so every slot falls back
## to a **clearly-labelled synthesised placeholder** generated at run time (22.05 kHz mono,
## zero asset files). Production files take over automatically when they exist:
##   res://assets/audio/production/round_start_sting.wav
##   res://assets/audio/production/feedback_tag.wav
##   res://assets/audio/production/lickshot_tag.wav
##   res://assets/audio/production/selector_yell.wav
##   res://assets/audio/production/crowd_murmur.wav / crowd_cheer.wav / crowd_eruption.wav
## Raw research clips are never loaded from `artifacts/` or the web.

const MIX_RATE := 22050
const STING_SECONDS := 6.0
## The round controller's announce is 1.8 s; the single guitar stab lands exactly on FIGHT!
const FIGHT_AT := 1.8
const TAG_COOLDOWN := 1.1
const GLOBAL_TAG_COOLDOWN := 0.45
const SELECTOR_COOLDOWN := 3.2
const HORN_COOLDOWN := 4.0
const MAX_TAG_VOICES := 3

enum Priority { SELECTOR = 1, TAG = 2, HORN = 3, KO = 4 }

## Fired when a DJ tag actually starts, so the 3D speaker stacks can punch in sync with it.
signal tag_played(key: StringName, priority: int)

const BUSES := ["Music", "SFX", "Crowd", "DJTag", "Selector", "Stinger"]
const PRODUCTION_DIR := "res://assets/audio/production/"

## Test hooks (read by `tools/headless_roster_check.gd`).
var tag_count: int = 0
var rejected_count: int = 0
var sting_count: int = 0
var horn_count: int = 0
var selector_count: int = 0
var last_event: StringName = &""
var last_tag_key: StringName = &""
var last_priority: int = 0
var last_sting_started_at: float = -1.0
var last_selector_line: StringName = &""
var crowd_level: float = 0.0
var muted: bool = false

var _streams: Dictionary = {}
var _tag_players: Array[AudioStreamPlayer] = []
var _tag_cursor: int = 0
var _sting: AudioStreamPlayer = null
var _horn: AudioStreamPlayer = null
var _selector: AudioStreamPlayer = null
var _stab: AudioStreamPlayer = null
var _crowd_players: Dictionary = {}
var _fighter_until: Dictionary = {}
var _global_until: float = 0.0
var _active_priority: int = 0
var _active_until: float = 0.0
var _selector_until: float = 0.0
var _horn_until: float = 0.0
var _crowd_target: float = 0.0
var _duck: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_build_players()
	# Warm the sting and tag voices during the round announce, so the first trigger never
	# allocates mid-fight.
	_stream(&"sting")
	_stream(&"feedback_tag")
	_stream(&"lickshot_tag")
	_stream(&"crowd_murmur")


func _process(delta: float) -> void:
	_crowd_target = maxf(0.0, _crowd_target - delta * 0.055)
	crowd_level = move_toward(crowd_level, _crowd_target, delta * 1.6)
	_duck = move_toward(_duck, 0.0, delta * 2.2)
	_apply_crowd_mix()
	_apply_duck()


# =========================================================================
# Public events
# =========================================================================
## Round start: one ~6 s slot. "Step up!" call, snare roll through the announce, then the
## single guitar stab on FIGHT! at 1.8 s. Player control starts on the round controller's
## own clock — this never gates input.
func play_round_start() -> bool:
	if _sting == null:
		return false
	_sting.stream = _stream(&"sting")
	_sting.volume_db = -1.5
	_sting.play()
	sting_count += 1
	last_event = &"round_start"
	last_sting_started_at = Time.get_ticks_msec() / 1000.0
	_raise_crowd(0.45)
	_duck = maxf(_duck, 0.45)
	return true


## A significant strike. Fired on any single damaging hit, not a combo. Blocked contacts and
## parries stay silent; heavies and counters push harder.
func on_strike(result: Dictionary, attacker: BaseFighter, target: BaseFighter) -> void:
	if bool(result.get("ignored", false)) or bool(result.get("parried", false)):
		return
	var blocked := bool(result.get("blocked", false))
	var damage := int(result.get("damage", 0))
	var attack_id := StringName(result.get("attack_id", &""))
	var heavy := attack_id in BaseFighter.HEAVY_ATTACK_IDS
	var counter := bool(result.get("counter", false))
	if blocked:
		_raise_crowd(0.28)
		return
	if attacker != null and (heavy or counter or damage >= 8):
		var key := attacker.fighter_key
		var priority := Priority.TAG if not counter else Priority.HORN
		if _trigger_tag(key, priority, &"tag"):
			# The crowd answers the tag; a heavy lands the eruption layer a beat later.
			_raise_crowd(0.95 if (heavy or counter) else 0.55)
	if heavy and target != null:
		_play_stab()
		_raise_crowd(1.0)


## A landed throw is a significant knockback even though it does not go through the strike
## resolver, so it gets the attacker's tag and the crowd spike like any heavy contact.
func on_throw(attacker: BaseFighter) -> void:
	if attacker == null:
		return
	_raise_crowd(0.9)
	_trigger_tag(attacker.fighter_key, Priority.TAG, &"throw")


## Knockdown: the selector barks over the tune and the crowd spikes. No damage numbers here.
func on_knockdown(fighter: BaseFighter) -> void:
	if fighter == null:
		return
	_raise_crowd(0.9)
	_trigger_selector(&"TEK WEH HIM MIC!")


## K.O.: the loudest slot; it outranks any tag still ringing.
func on_ko(winner: BaseFighter = null) -> void:
	_raise_crowd(1.0)
	_trigger_horn(true)
	_trigger_selector(&"UNPLUG THAT SOUND!", true)
	_duck = maxf(_duck, 0.8)
	last_event = &"ko"
	last_priority = Priority.KO
	_active_priority = Priority.KO
	_active_until = _now() + 1.4


## Hype Surge / 100 % crowd: horn + selector, no tag consumed.
func on_hype_surge() -> void:
	_trigger_horn(false)
	_raise_crowd(1.0)


func set_crowd_intensity(value: float) -> void:
	_crowd_target = clampf(value, 0.0, 1.0)


func _raise_crowd(value: float) -> void:
	_crowd_target = maxf(_crowd_target, clampf(value, 0.0, 1.0))


# =========================================================================
# DJ tag / selector / horn triggers
# =========================================================================
## Public trigger used by the arena and the headless checks. Same cooldown/priority path as
## the strike event, so a test can never bypass the anti-overlap rules.
func trigger_tag(key: StringName, priority: int = Priority.TAG) -> bool:
	return _trigger_tag(key, priority, &"tag")


func _trigger_tag(key: StringName, priority: int, event: StringName) -> bool:
	var now := _now()
	if now < _global_until:
		rejected_count += 1
		return false
	if now < float(_fighter_until.get(key, 0.0)):
		rejected_count += 1
		return false
	# Equal priority also blocks: one tag rings at a time, so two fighters cannot stack.
	if now < _active_until and _active_priority >= priority:
		rejected_count += 1
		return false
	var stream := _stream(StringName("%s_tag" % String(key)))
	if stream == null:
		return false
	var player := _free_tag_player()
	player.stream = stream
	player.pitch_scale = 0.97 if key == &"lickshot" else 1.03
	player.play()
	_fighter_until[key] = now + TAG_COOLDOWN
	_global_until = now + GLOBAL_TAG_COOLDOWN
	_active_priority = priority
	_active_until = now + stream.get_length()
	last_tag_key = key
	tag_count += 1
	last_event = event
	last_priority = priority
	_duck = maxf(_duck, 0.55)
	tag_played.emit(key, priority)
	return true


func _trigger_selector(line: StringName, force: bool = false) -> bool:
	var now := _now()
	if not force and now < _selector_until:
		return false
	if not force and now < _active_until and _active_priority > Priority.SELECTOR:
		return false
	if _selector == null:
		return false
	_selector.stream = _stream(&"selector_yell")
	_selector.play()
	_selector_until = now + SELECTOR_COOLDOWN
	selector_count += 1
	last_selector_line = line
	last_event = &"selector"
	last_priority = Priority.SELECTOR
	_active_priority = Priority.SELECTOR
	_active_until = now + _selector.stream.get_length()
	_duck = maxf(_duck, 0.45)
	return true


func _trigger_horn(force: bool) -> bool:
	var now := _now()
	if not force and now < _horn_until:
		return false
	if _horn == null:
		return false
	_horn.stream = _stream(&"horn")
	_horn.play()
	_horn_until = now + HORN_COOLDOWN
	horn_count += 1
	last_event = &"horn"
	last_priority = Priority.HORN
	_active_priority = maxi(_active_priority, Priority.HORN)
	_active_until = maxi(_active_until, now + _horn.stream.get_length())
	_duck = maxf(_duck, 0.35)
	return true


func _play_stab() -> void:
	if _stab == null:
		return
	_stab.stream = _stream(&"stab")
	_stab.play()


func _free_tag_player() -> AudioStreamPlayer:
	# Round-robin over three voices: the bus echo, not a long clip, is what creates the
	# cascade, so a new tag may start while the previous tail is still echoing.
	var player := _tag_players[_tag_cursor % _tag_players.size()]
	_tag_cursor += 1
	return player


# =========================================================================
# Audio buses — native tape-delay chain
# =========================================================================
func _ensure_buses() -> void:
	for name in BUSES:
		if AudioServer.get_bus_index(StringName(name)) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, name)
			AudioServer.set_bus_send(index, &"Master")
	_tag_bus_effects()
	_set_bus_db("Music", -2.0)
	_set_bus_db("SFX", 0.0)
	_set_bus_db("Crowd", -6.0)
	_set_bus_db("DJTag", 0.0)
	_set_bus_db("Selector", -1.0)
	_set_bus_db("Stinger", -1.0)


## Idempotent: adds the delay/low-pass/reverb chain only when the DJTag bus does not have it
## yet, so the project's `default_bus_layout.tres` and this runtime guard agree.
func _tag_bus_effects() -> void:
	var tag := AudioServer.get_bus_index(&"DJTag")
	if tag == -1:
		return
	if AudioServer.get_bus_effect_count(tag) == 0:
		var delay := AudioEffectDelay.new()
		delay.dry = 0.55
		delay.tap1_active = true
		delay.tap1_delay_ms = 265.0
		delay.tap1_level_db = -5.0
		delay.tap2_active = true
		delay.tap2_delay_ms = 530.0
		delay.tap2_level_db = -13.0
		delay.feedback_active = true
		delay.feedback_delay_ms = 300.0
		delay.feedback_level_db = -9.5
		delay.feedback_lowpass = 3600.0
		AudioServer.add_bus_effect(tag, delay)
		var lowpass := AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = 4200.0
		lowpass.resonance = 0.35
		AudioServer.add_bus_effect(tag, lowpass)
		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.62
		reverb.damping = 0.45
		reverb.spread = 0.9
		reverb.hipass = 220.0
		reverb.dry = 0.85
		reverb.wet = 0.32
		reverb.predelay_msec = 28.0
		AudioServer.add_bus_effect(tag, reverb)
	var selector := AudioServer.get_bus_index(&"Selector")
	if selector != -1 and AudioServer.get_bus_effect_count(selector) == 0:
		var echo := AudioEffectDelay.new()
		echo.dry = 0.7
		echo.tap1_active = true
		echo.tap1_delay_ms = 180.0
		echo.tap1_level_db = -8.0
		AudioServer.add_bus_effect(selector, echo)


func bus_names() -> Array:
	var names: Array = []
	for i in AudioServer.bus_count:
		names.append(AudioServer.get_bus_name(i))
	return names


func dj_bus_effect_names() -> Array:
	var names: Array = []
	var tag := AudioServer.get_bus_index(&"DJTag")
	if tag == -1:
		return names
	for i in AudioServer.get_bus_effect_count(tag):
		var effect := AudioServer.get_bus_effect(tag, i)
		if effect != null:
			names.append(effect.get_class())
	return names


func sting_stream_length() -> float:
	var stream := _stream(&"sting")
	return stream.get_length() if stream != null else 0.0


func sting_fight_marker() -> float:
	return FIGHT_AT


func _set_bus_db(name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(StringName(name))
	if index != -1:
		AudioServer.set_bus_volume_db(index, value)


func _apply_crowd_mix() -> void:
	var murmur := -60.0
	var cheer := -60.0
	var eruption := -60.0
	if crowd_level > 0.01:
		murmur = lerpf(-38.0, -17.0, clampf(crowd_level / 0.45, 0.0, 1.0))
	if crowd_level > 0.35:
		cheer = lerpf(-46.0, -14.0, clampf((crowd_level - 0.35) / 0.40, 0.0, 1.0))
	if crowd_level > 0.70:
		eruption = lerpf(-44.0, -7.0, clampf((crowd_level - 0.70) / 0.30, 0.0, 1.0))
	_set_player_db("murmur", murmur)
	_set_player_db("cheer", cheer)
	_set_player_db("eruption", eruption)


func _set_player_db(key: String, value: float) -> void:
	var player := _crowd_players.get(key) as AudioStreamPlayer
	if player != null:
		player.volume_db = value


func _apply_duck() -> void:
	# Duck bed and crowd, not the impact SFX: the tag stays on top of the mix.
	_set_bus_db("Music", -2.0 - _duck * 8.0)
	_set_bus_db("Crowd", -6.0 - _duck * 4.0)


func set_muted(value: bool) -> void:
	muted = value
	var index := AudioServer.get_bus_index(&"Master")
	if index != -1:
		AudioServer.set_bus_mute(index, value)


# =========================================================================
# Players
# =========================================================================
func _build_players() -> void:
	for i in MAX_TAG_VOICES:
		var player := AudioStreamPlayer.new()
		player.name = "TagVoice%d" % i
		player.bus = "DJTag"
		player.volume_db = -4.0
		add_child(player)
		_tag_players.append(player)
	_sting = _player("RoundSting", "Stinger", -1.5)
	_horn = _player("Airhorn", "DJTag", -5.0)
	_selector = _player("Selector", "Selector", -3.0)
	_stab = _player("GuitarStab", "SFX", -7.0)
	for key in ["murmur", "cheer", "eruption"]:
		var player := _player("Crowd_%s" % key, "Crowd", -60.0)
		player.stream = _stream(StringName("crowd_%s" % key))
		player.play()
		_crowd_players[key] = player


func _player(node_name: String, bus: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = bus
	player.volume_db = volume
	add_child(player)
	return player


# =========================================================================
# Stream sources
# =========================================================================
func _stream(key: StringName) -> AudioStream:
	if _streams.has(key):
		var cached: AudioStream = _streams[key]
		return cached
	var production := _load_production(key)
	var stream: AudioStream = production
	if stream == null:
		stream = _synth_stream(key)
	_streams[key] = stream
	return stream


## Production recordings win when they exist. No research clip is ever loaded.
func _load_production(key: StringName) -> AudioStream:
	var path := PRODUCTION_DIR + String(key) + ".wav"
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _synth_stream(key: StringName) -> AudioStream:
	match key:
		&"sting":
			return _make_wav(_synth_sting(), false)
		&"feedback_tag", &"lickshot_tag":
			return _make_wav(_synth_tag(key == &"feedback_tag"), false)
		&"selector_yell":
			return _make_wav(_synth_selector(), false)
		&"horn":
			return _make_wav(_synth_horn(), false)
		&"stab":
			return _make_wav(_synth_stab(1.2, 1.1, 0.55), false)
		&"crowd_murmur":
			return _make_wav(_synth_crowd(1201, 0.06, false), true)
		&"crowd_cheer":
			return _make_wav(_synth_crowd(1202, 0.12, true), true)
		&"crowd_eruption":
			return _make_wav(_synth_crowd(1203, 0.22, true), true)
	return _make_wav(PackedFloat32Array([0.0, 0.0]), false)


func _make_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -0.98, 0.98) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# =========================================================================
# Placeholder synthesis (documented, deterministic, peak-safe)
# =========================================================================
func _frames(seconds: float) -> int:
	return maxi(1, int(MIX_RATE * seconds))


func _synth_sting() -> PackedFloat32Array:
	var n := _frames(STING_SECONDS)
	var buf := PackedFloat32Array()
	buf.resize(n)
	# "Step up!" — a formant-shaped call over the first half second.
	_add_call(buf, 0.05, 0.42, 150.0, 720.0, 1150.0, 0.45, 3)
	# Snare roll building through the 1.8 s announce, then the stab on FIGHT.
	var roll_start := 0.45
	var hits := 18
	for i in hits:
		var t := roll_start + (float(i) / float(hits)) * (FIGHT_AT - roll_start)
		var spacing := (FIGHT_AT - roll_start) / float(hits)
		var gain := 0.10 + 0.16 * (float(i) / float(hits))
		_add_noise(buf, t, spacing * 0.8, gain, 71 + i, 0.55)
	# Riser under the roll.
	_add_tone(buf, 0.7, 1.0, 180.0, 640.0, 0.10, 1, 0.0)
	# Single guitar stab: one chord, fast attack, long ring.
	_add_stab_chord(buf, FIGHT_AT, 1.5, 0.62)
	# Sub-bass drop under the stab, for the speaker stack to answer.
	_add_tone(buf, FIGHT_AT, 1.3, 96.0, 38.0, 0.42, 0, 0.0)
	# Crowd swell under the whole intro, then a clean tail out to 6.0 s.
	_add_noise(buf, 0.9, 2.4, 0.06, 99, 0.20)
	for i in n:
		buf[i] = tanh(buf[i] * 1.1) * 0.9
	return buf


func _synth_tag(feedback_voice: bool) -> PackedFloat32Array:
	var n := _frames(1.05)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var base := 124.0 if feedback_voice else 108.0
	# Two-syllable selector call ("Feed-back" / "Lick-shot"), formant shifted per fighter.
	_add_call(buf, 0.02, 0.34, base, 620.0, 1080.0, 0.75, 17)
	_add_call(buf, 0.34, 0.46, base * 0.94, 880.0, 1420.0, 0.65, 23)
	# A vinyl transient so the tag reads as a sound-system drop.
	_add_noise(buf, 0.0, 0.05, 0.25, 41, 0.15)
	_add_noise(buf, 1.0, 0.05, 0.12, 43, 0.10)
	for i in n:
		buf[i] = tanh(buf[i] * 1.4) * 0.85
	return buf


func _synth_selector() -> PackedFloat32Array:
	var n := _frames(0.9)
	var buf := PackedFloat32Array()
	buf.resize(n)
	# "Wheel up!" — two selector syllables, then the bus echo does the rest.
	_add_call(buf, 0.0, 0.52, 122.0, 700.0, 1180.0, 0.70, 31)
	_add_call(buf, 0.46, 0.38, 152.0, 900.0, 1480.0, 0.55, 37)
	for i in n:
		buf[i] = tanh(buf[i] * 1.3) * 0.9
	return buf


func _synth_horn() -> PackedFloat32Array:
	var n := _frames(0.9)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t := float(i) / MIX_RATE
		var k := float(i) / float(n)
		var freq := 320.0 + 190.0 * clampf(k / 0.14, 0.0, 1.0)
		freq *= 1.0 + 0.012 * sin(TAU * 6.2 * t)
		var value := 0.0
		for detune in [-0.014, 0.0, 0.014]:
			var phase := TAU * freq * (1.0 + float(detune)) * t
			value += (2.0 * (phase / TAU - floorf(phase / TAU + 0.5))) * 0.30
		var env := minf(1.0, k / 0.05) * clampf((1.0 - k) / 0.28, 0.0, 1.0)
		buf[i] = tanh(value * env * 1.4) * 0.55
	return buf


func _synth_stab(seconds: float, ring: float, gain: float) -> PackedFloat32Array:
	var n := _frames(seconds)
	var buf := PackedFloat32Array()
	buf.resize(n)
	_add_stab_chord(buf, 0.0, ring, gain)
	return buf


func _synth_crowd(seed_value: int, level: float, voices: bool) -> PackedFloat32Array:
	var seconds := 1.6
	var n := _frames(seconds)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var smoothed := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		smoothed = lerpf(smoothed, rng.randf_range(-1.0, 1.0), 0.06)
		# Slow swell so a 2.4 s loop does not read as a static noise bed.
		var swell := 0.55 + 0.45 * sin(t * 1.1 + float(seed_value % 7))
		var value := smoothed * level * swell
		if voices:
			# Scattered whistle/voice partials keep the cheer from being pure noise.
			var voice := sin(TAU * 720.0 * t + sin(TAU * 3.1 * t) * 2.0)
			voice += 0.6 * sin(TAU * 1080.0 * t + sin(TAU * 2.3 * t) * 1.4)
			value += voice * level * 0.35 * pow(maxf(0.0, sin(t * 2.7 + 1.3)), 3.0)
		buf[i] = value
	# 30 ms de-click at the loop seam.
	var edge := int(MIX_RATE * 0.03)
	for i in edge:
		var k := float(i) / float(edge)
		buf[i] *= k
		buf[n - 1 - i] *= k
	return buf


func _add_stab_chord(buf: PackedFloat32Array, start: float, ring: float, gain: float) -> void:
	for freq in [196.0, 246.94, 293.66, 392.0]:
		_add_tone(buf, start, ring, freq, freq * 0.995, gain * 0.30, 1, 0.7)


## `wave` 0 = sine, 1 = saw. Adds with a short attack and exponential decay.
func _add_tone(buf: PackedFloat32Array, start: float, seconds: float, from_hz: float,
		to_hz: float, gain: float, wave: int, drive: float) -> void:
	var first := int(start * MIX_RATE)
	var count := int(seconds * MIX_RATE)
	for i in count:
		var index := first + i
		if index < 0 or index >= buf.size():
			continue
		var k := float(i) / float(maxi(count - 1, 1))
		var freq := lerpf(from_hz, to_hz, k)
		var phase := TAU * freq * (float(i) / MIX_RATE)
		var value := sin(phase)
		if wave == 1:
			value = 2.0 * (phase / TAU - floorf(phase / TAU + 0.5))
		var env := minf(1.0, k / 0.01) * exp(-4.2 * k)
		if drive > 0.0:
			value = tanh(value * (1.0 + drive * 4.0))
		buf[index] += value * env * gain


func _add_noise(buf: PackedFloat32Array, start: float, seconds: float, gain: float,
		seed_value: int, smoothing: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var first := int(start * MIX_RATE)
	var count := int(seconds * MIX_RATE)
	var smooth := 0.0
	for i in count:
		var index := first + i
		if index < 0 or index >= buf.size():
			continue
		var k := float(i) / float(maxi(count - 1, 1))
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), smoothing)
		var env := minf(1.0, k / 0.02) * exp(-2.6 * k)
		buf[index] += smooth * env * gain


## A vowel-ish selector call: voiced saw + two formant sines + a breath transient.
func _add_call(buf: PackedFloat32Array, start: float, seconds: float, pitch: float,
		formant_a: float, formant_b: float, gain: float, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var first := int(start * MIX_RATE)
	var count := int(seconds * MIX_RATE)
	var vibrato := 0.0
	for i in count:
		var index := first + i
		if index < 0 or index >= buf.size():
			continue
		var t := float(i) / MIX_RATE
		var k := float(i) / float(maxi(count - 1, 1))
		vibrato += (rng.randf_range(-1.0, 1.0) - vibrato) * 0.02
		var f0 := pitch * (1.0 + vibrato * 0.05)
		var phase := TAU * f0 * t
		var voiced := 2.0 * (phase / TAU - floorf(phase / TAU + 0.5))
		var vowel := sin(TAU * formant_a * t) * 0.5 + sin(TAU * formant_b * t) * 0.28
		var breath := rng.randf_range(-1.0, 1.0) * 0.05
		# Syllable-shaped envelope: a fast open, a dip, then a close.
		var env := minf(1.0, k / 0.12) * clampf((1.0 - k) / 0.25, 0.0, 1.0)
		env *= 0.6 + 0.4 * sin(PI * k)
		buf[index] += tanh((voiced * 0.35 + vowel + breath) * env * 2.0) * gain

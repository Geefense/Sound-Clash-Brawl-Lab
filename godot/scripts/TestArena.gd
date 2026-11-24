extends Node2D
## Workshop arena for Fighter #1 (UNAPPROVED — no Godot checks have been run).
##
## Wires the two fighters to one BeatService, drives the dummy, follows the action
## with the camera, shakes it on impact, and repeats the dev click loop.
##
## 3D presentation (AGENTS.md §9 items 43–45): when `presentation_3d` is on, `Arena3D` adds
## a real Node3D yard, Camera3D, cel-shaded fighter models and 3D note bursts. The 2D stage
## art and sprite drawing are hidden; the combat simulation, hitboxes, input buffering, beat
## clock, round timers and Patois callouts all keep running unchanged underneath. Set
## `presentation_3d = false` to get the previous 2D build back byte-for-byte.
##
## Stage: `Sound Clash Sand Stage` (1280x720 art, z_index -10) with the fighting floor
## at y = 600 — the sand yard starts at y ≈ 505 in that art, so both fighters stand
## inside the sand lane. The camera never zooms out past 1.0 or leaves the stage
## rectangle, so the single-layer art always covers the view.
##
## Round lighting: `set_time_of_day(phase)` runs the afternoon → golden hour →
## late-night progression (AGENTS.md §9). Round 1 defaults to phase 0; **N** cycles it
## by hand until the round controller drives it.
##
## Match flow: a best-of-3 Sound Clash runs by default (RoundController) — announce, fight,
## K.O., next round with the day → sunset → night lighting, then a rematch banner and restart.
## R reloads the scene and starts a fresh match; N still overrides the lighting by hand.
##
## Workshop keys: Esc back to Character & Match Setup · R reset · G dummy guard (manual
## guard override in every AI mode) · Y cycle P2's sparring AI mode · M mute (click track
## + procedural SFX) · B bird hazard · N time of day · V subtitles · J/K/L/I attacks ·
## T taunt · U grab/throw · C crouch · WASD/arrows move.
##
## Push separation (AGENTS.md §9 backlog item B7): bodies keep a shared minimum gap so the
## fighters cannot occupy the same pixel, which also keeps the 96 px grab range meaningful.
## It is skipped while a body is held, airborne, thrown or knocked down, so jumps over an
## opponent, throws, spinbacks and knockdowns pass through cleanly instead of snagging.
##
## Sound (backlog item B8): every impact cue comes from `Sfx`, which synthesises its
## samples at run time — the build ships no audio files.
##
## Crowd staging (AGENTS.md §9 item 21): `YardBarrier` closes the base of the yard so the
## crowd stands behind something instead of being pinned onto the sand. The crowd itself is
## 3D only — `Arena3D.crowd3d`, eight delivered Mixamo characters, reached here through the
## `crowd` property. The 2D `CrowdLine` sprite layer, the `ForegroundCrowd` silhouette stack
## and the `CrowdHaze` wash were deleted with the silhouettes (2026-11-24). Presentation only.

const CLICK_LOOP_SECONDS := 10.0      # 22 beats at 132 BPM
const CAMERA_MIN_DISTANCE := 620.0
const CAMERA_MAX_DISTANCE := 1100.0
## Framing (§9 item 23, owner playtest: "reduce the excessive zoom — I want to appreciate the
## scenery"). At the neutral 440 px spacing this frames at ~1.04 and, with both fighters up
## close, tops out at 1.12 instead of the old 1.6 — the old close-range crop threw away most of
## the yard. Both full speaker stacks (left 82–204, right 1075–1201) stay inside the view at
## 1.12, and the 1.0 floor still guarantees the single-layer stage art covers the frame.
const CAMERA_FIT_DISTANCE := 820.0
const STAGE_SIZE := Vector2(1280, 720)
const CAMERA_MIN_ZOOM := 1.0          # keep the 1280x720 stage art covering the view
const CAMERA_MAX_ZOOM := 1.12
const CAMERA_FOCUS_LIFT := 140.0
const THUMP_ZOOM := 0.008             # 132 BPM speaker thump: 0.8% micro-pulse
const THUMP_DECAY := 7.0
## Fighting-game camera (AGENTS.md §9 item 41): the framing zoom approaches its target
## smoothly instead of snapping every frame, and a micro-zoom burst punches in on a counter
## or a 100 % Hype Surge. Both are additive above 1.0, so the stage art always covers the view.
const CAMERA_ZOOM_SMOOTH := 6.0       # per-second approach rate to the framing zoom
const CAMERA_PUNCH_DECAY := 0.30      # how fast a micro-zoom burst settles (per second)

## Round-based time of day (AGENTS.md §9 owner decision). `tint` is a CanvasModulate
## over the whole world canvas — the HUD lives in a CanvasLayer, so it stays readable —
## and `flood` is the aim of the warm additive floodlight over the centre lane, which
## only rises at night so both fighters stay crisp against the dark sky.
## [TODO] Phase-to-round mapping is exposed as an API, not driven: this workshop arena
## has no round lifecycle yet. The match controller calls set_time_of_day(round - 1).
## Each phase now changes the *scene*, not just a screen filter (owner playtest, 2026-11-17).
##   tint    — CanvasModulate over the world canvas (the HUD is a CanvasLayer, so it stays clean)
##   sunset  — warm sky wash alpha (`SunsetWash`, orange over the top of the frame)
##   night   — deep-blue sky/beach wash alpha (`NightWash`), so the clouds and surf go subdued
##   sun/sun_pos/sun_scale — the sun bloom: high and white at noon, low and big at sunset, gone
##             at night
##   shaft   — warm directional light from the sun side (`SunShaft`, additive)
##   flood   — warm arena floodlight over the centre lane; only the night really lights it
##   crowd   — 0–1 crowd silhouette for the night
##   shadow  — contact-shadow stretch / cast direction (long low sun, short night flood)
const TIME_PHASES := [
	{
		"name": "Afternoon Sun",
		"tint": Color(1.0, 0.99, 0.96),
		"sunset": 0.0,
		"night": 0.0,
		"sun": 1.0,
		"sun_pos": Vector2(1010, 205),
		"sun_scale": 2.4,
		"shaft": 0.1,
		"flood": 0.0,
		"shadow_stretch": 0.95,
		"shadow_dir": -1.0,
		# 2.5D lighting pass (AGENTS.md §9 item 41): a high, slightly warm daylight rim.
		"rim_a": Color(1.0, 0.88, 0.66),
		"rim_b": Color(1.0, 0.78, 0.48),
		"rim_strength": 0.55,
		"light_uv": Vector2(0.62, -0.78),
		"bounce": 0.30,
		"shadow_density": 1.0,
		"beam": 0.0,
		"haze": 0.35,
	},
	{
		"name": "Golden Hour / Sunset Clash",
		"tint": Color(1.0, 0.84, 0.68),
		"sunset": 0.62,
		"night": 0.0,
		"sun": 1.2,
		"sun_pos": Vector2(1046, 300),
		"sun_scale": 3.1,
		"shaft": 0.36,
		"flood": 0.12,
		"shadow_stretch": 1.95,     # low sun: long shadows cast to the right
		"shadow_dir": 1.0,
		# Golden-amber wrap from the low sun on the right, plus heavy sand bounce.
		"rim_a": Color(1.0, 0.70, 0.24),
		"rim_b": Color(1.0, 0.50, 0.16),
		"rim_strength": 1.15,
		"light_uv": Vector2(0.90, -0.36),
		"bounce": 0.55,
		"shadow_density": 0.85,
		"beam": 0.85,
		"haze": 1.0,
	},
	{
		"name": "Late-Night Sound Clash",
		"tint": Color(0.44, 0.52, 0.78),
		"sunset": 0.0,
		"night": 0.74,
		"sun": 0.0,
		"sun_pos": Vector2(1010, 150),
		"sun_scale": 1.7,
		"shaft": 0.0,
		"flood": 0.46,              # the stage lights, not the sun, carry this round
		"shadow_stretch": 1.1,
		"shadow_dir": -1.0,
		# Cyan/magenta neon wrap from the truss rig, low bounce, softer crowd shadows.
		"rim_a": Color(0.30, 0.95, 1.0),
		"rim_b": Color(1.0, 0.32, 0.95),
		"rim_strength": 1.30,
		"light_uv": Vector2(-0.28, -0.92),
		"bounce": 0.18,
		"shadow_density": 0.72,
		"beam": 0.72,
		"haze": 0.45,
	},
]
const TIME_TRANSITION_SEC := 3.0

## Long-demo safeguards for low-RAM Chromebooks (AGENTS.md §9). Rapid inputs and long
## sessions must never pile up effects, so every transient spawn goes through a cap.
const MAX_ACTIVE_BIRDS := 1           # one bird in the air at a time, however fast B is pressed
const MAX_PARRY_SPARKS := 4           # oldest spark is recycled once four are alive
const MAX_PARTICLE_AMOUNT := 16       # hard ceiling applied to every CPUParticles2D
const MAX_STRIKE_TELLS := 4           # attack smears, same cap policy as the sparks
## 2.5D impact juice (AGENTS.md §9 item 41). Note trails and the comic impact frame are
## transient primitives under the same cap policy as the sparks, so a long brawl never piles
## nodes up on a Chromebook.
const MAX_NOTE_TRAILS := 3            # musical-note swing trails alive at once
const MAX_IMPACT_FRAMES := 1          # one comic frame at a time, never a stack

## Crowd proximity ebb (AGENTS.md §9 item 21). A body crossing the line at this speed, or
## any thrown / landing body, pulls the nearest spectators back for a beat. Walking is 220,
## so this only fires on a dash, a jump-in, a throw or a knockdown.
const CROWD_FLINCH_SPEED := 320.0
## Where the pre-warm instances live: far outside the camera's clamped stage rectangle,
## so they are never on screen even for one frame.
const PREWARM_OFFSCREEN := Vector2(-4000.0, -4000.0)

## Patois callout rotation (AGENTS.md §8). Each trigger owns a pool and the pool rotates, so
## every approved line keeps coming round instead of being replaced. Spellings are the
## owner's, verbatim; the English gloss lives only in CALLOUT_GLOSSES, which is the only
## place it belongs.
##
## 2026-11-22: the owner's 31-entry Jamaican Patwa proverbs & expressions collection is
## wired here. PATWA_COLLECTION is the canonical list (22 in-match lines + the 9 match-intro
## proverbs below); the headless checks assert every entry resolves to a gloss and to a live
## trigger. PROVERB_BANNER rotates the traditional proverbs on the match-intro banner, so a
## clash opens on a different piece of yard wisdom every match.
const CALLOUT_GLOSSES := {
	"TUMP OUT HIM TEET!": "(Translation: Knock out his teeth!)",
	"WHO CYAAN HEAR, MUS FEEL": "(Translation: Those who refuse warnings must learn through consequences.)",
	"COCK MOUTH KILL COCK": "(Translation: Careless talking exposes your own downfall.)",
	"TEK WEH HIM MIC!": "(Translation: Take away his microphone!)",
	"SAME KNIFE TICK DI SHEEP, TICK DI GOAT": "(Translation: What hits one rival can hit you next.)",
	"WEN YUH A DIG HOLE, DIG TWO": "(Translation: A trap set for someone else can backfire on you.)",
	"YUH NUH FI EAT HOT RICE": "(Translation: Don't react blindly in anger; stay cool.)",
	"MI NUH TEK CHAT": "(Translation: I don't tolerate disrespect or foolishness.)",
	"BOASY": "(Translation: Showy, flashy, proudly showing off.)",
	"FALLA FASHION": "(Translation: Stop copying the crowd; think for yourself.)",
	"YUH ZIMMI?": "(Translation: Do you understand me? Are you following?)",
	"GINNAL": "(Translation: Trickster or con artist.)",
	"TEK SET PON MI": "(Translation: Repeatedly targeting or pressuring me.)",
	"NUH WAIT TILL DRUM BEAT BEFORE YUH GRINE YUH AXE": "(Translation: Prepare early before the clash begins.)",
	"NUH PUT YUH SELF IN A BARREL WHEN MATCHBOX CAN HOL YUH": "(Translation: Stay grounded; don't overreach.)",
	"GWAAN SUH!": "(Translation: Keep going! Keep up the pressure!)",
	"EVERY MIKKLE MEK A MUKKLE": "(Translation: Every small hit and effort adds up to victory.)",
	"CHAIR DROP A GRUNG AN BENCH GIT UP": "(Translation: When one steps down, another steps up.)",
	"COCKROACH NUH BUSINESS INNA FOWL FIGHT / COWS HAVE NO BUSINESS IN HORSEPLAY": "(Translation: Stay out of a heavy clash that isn't yours.)",
	"WASH-BELLY": "(Translation: The youngest prodigy in the crew.)",
	"NICE UP YUHSELF": "(Translation: Carry yourself sharp and strong.)",
	"NOBODY NEVA KICK DEAD DAWG": "(Translation: Criticism only targets people who are active and making waves.)",
	"EMPTY YUH PURSE INNA YUH HEAD": "(Translation: Spend on your mind before your pocket; knowledge is the best investment.)",
	"SORRY FI MAWGA DOG, MAWGA DOG TURN ROUND BITE YUH": "(Translation: Misplaced pity can be repaid with betrayal.)",
	"IF WIND NUH BLOW, FOWL BATTY NUH SHOW": "(Translation: What is hidden is only exposed when circumstances stir.)",
	"PUSS NO AVE HAND, IM USE IM FOOT WIPE IM FACE": "(Translation: Work with what you have and make a way.)",
	"FOWL DRINK WATER BUT FOWL NUH PEE": "(Translation: What goes in does not always come back out.)",
	"BEFORE DAWG GO WIDOUT SUPPA, IM NYAM COCKROACH": "(Translation: People will do what they must to survive.)",
	"IF YUH WANT GOOD, YUH NOSE HAFFI RUN": "(Translation: Nothing worthwhile comes without hardship.)",
	"SEE AND BLIND, HEAR AND DEAF": "(Translation: Discretion: see and hear without repeating it.)",
	"WHEN PUSS BELLY FULL, HIM SEH RAT BATTY BITTER": "(Translation: A satisfied person dismisses what others still need.)",
	"WHOLE-AWN-DEH!": "(Translation: Hold on a second!)",
	"BIG TUNE!": "(Translation: Cleanest block in the dance!)",
	"PLAYAH NEX TUNE!": "(Translation: Play another song!)",
	"WHEEL AND COME AGAIN!": "(Translation: Rewind the track — rematch!)",
	"POPPYSHOW!": "(Translation: Show-off! / Clown!)",
	"YUH TOO BOD MINE!!": "(Translation: You're way too jealous!)",
}

## The 31-entry owner collection: 22 in-match lines plus the 9 match-intro proverbs.
const PATWA_COLLECTION := [
	"WHO CYAAN HEAR, MUS FEEL",
	"COCK MOUTH KILL COCK",
	"WEN YUH A DIG HOLE, DIG TWO",
	"NOBODY NEVA KICK DEAD DAWG",
	"SAME KNIFE TICK DI SHEEP, TICK DI GOAT",
	"YUH NUH FI EAT HOT RICE",
	"TEK WEH HIM MIC!",
	"TUMP OUT HIM TEET!",
	"MI NUH TEK CHAT",
	"BOASY",
	"FALLA FASHION",
	"YUH ZIMMI?",
	"GINNAL",
	"TEK SET PON MI",
	"NUH WAIT TILL DRUM BEAT BEFORE YUH GRINE YUH AXE",
	"NUH PUT YUH SELF IN A BARREL WHEN MATCHBOX CAN HOL YUH",
	"GWAAN SUH!",
	"EVERY MIKKLE MEK A MUKKLE",
	"CHAIR DROP A GRUNG AN BENCH GIT UP",
	"COCKROACH NUH BUSINESS INNA FOWL FIGHT / COWS HAVE NO BUSINESS IN HORSEPLAY",
	"WASH-BELLY",
	"NICE UP YUHSELF",
	"EMPTY YUH PURSE INNA YUH HEAD",
	"SORRY FI MAWGA DOG, MAWGA DOG TURN ROUND BITE YUH",
	"IF WIND NUH BLOW, FOWL BATTY NUH SHOW",
	"PUSS NO AVE HAND, IM USE IM FOOT WIPE IM FACE",
	"FOWL DRINK WATER BUT FOWL NUH PEE",
	"BEFORE DAWG GO WIDOUT SUPPA, IM NYAM COCKROACH",
	"IF YUH WANT GOOD, YUH NOSE HAFFI RUN",
	"SEE AND BLIND, HEAR AND DEAF",
	"WHEN PUSS BELLY FULL, HIM SEH RAT BATTY BITTER",
]

const CALLOUTS := {
	&"heavy": [
		"TUMP OUT HIM TEET!",
		"WHO CYAAN HEAR, MUS FEEL",
		"COCK MOUTH KILL COCK",
	],
	&"stun": [
		"TEK WEH HIM MIC!",
	],
	&"counter": [
		"SAME KNIFE TICK DI SHEEP, TICK DI GOAT",
		"WEN YUH A DIG HOLE, DIG TWO",
	],
	&"parry": [
		"WHOLE-AWN-DEH!",
		"BIG TUNE!",
		"YUH NUH FI EAT HOT RICE",
	],
	&"throw_break": [
		"WHOLE-AWN-DEH!",
		"COCKROACH NUH BUSINESS INNA FOWL FIGHT / COWS HAVE NO BUSINESS IN HORSEPLAY",
	],
	&"hype": [
		"PLAYAH NEX TUNE!",
		"GWAAN SUH!",
		"EVERY MIKKLE MEK A MUKKLE",
		"CHAIR DROP A GRUNG AN BENCH GIT UP",
		"NICE UP YUHSELF",
	],
	&"round_win": [
		"PLAYAH NEX TUNE!",
		"NOBODY NEVA KICK DEAD DAWG",
	],
	&"taunt": [
		"POPPYSHOW!",
		"YUH TOO BOD MINE!!",
		"MI NUH TEK CHAT",
		"BOASY",
		"FALLA FASHION",
		"YUH ZIMMI?",
		"GINNAL",
		"TEK SET PON MI",
		"NUH WAIT TILL DRUM BEAT BEFORE YUH GRINE YUH AXE",
		"NUH PUT YUH SELF IN A BARREL WHEN MATCHBOX CAN HOL YUH",
	],
	&"punish": [
		"POPPYSHOW!",
	],
	&"wash_belly": [
		"WASH-BELLY",
	],
}

## Match-intro wisdom banner: one traditional proverb per match, rotating the full set.
const PROVERB_BANNER := [
	"EMPTY YUH PURSE INNA YUH HEAD",
	"SORRY FI MAWGA DOG, MAWGA DOG TURN ROUND BITE YUH",
	"IF WIND NUH BLOW, FOWL BATTY NUH SHOW",
	"PUSS NO AVE HAND, IM USE IM FOOT WIPE IM FACE",
	"FOWL DRINK WATER BUT FOWL NUH PEE",
	"BEFORE DAWG GO WIDOUT SUPPA, IM NYAM COCKROACH",
	"IF YUH WANT GOOD, YUH NOSE HAFFI RUN",
	"SEE AND BLIND, HEAR AND DEAF",
	"WHEN PUSS BELLY FULL, HIM SEH RAT BATTY BITTER",
]
const PROVERB_BANNER_SECONDS := 3.4
var _callout_cursor := {}
var _proverb_cursor: int = 0

## Push separation (AGENTS.md §9 backlog item B7). 64 px is wider than the 60 px body, so
## the fighters never visually overlap; grabs (96 px) still reach comfortably.
const BODY_GAP := 64.0
## These states must be able to pass through the other body: a held or thrown fighter is
## positioned by the throw, and a knockdown/KO body must be allowed to land where it lands.
const NO_SEPARATION_STATES := [
	BaseFighter.State.GRABBED, BaseFighter.State.THROWN,
	BaseFighter.State.KNOCKDOWN, BaseFighter.State.KO,
]

## 3D presentation toggle (AGENTS.md §9 item 43). Presentation only.
@export var presentation_3d: bool = true
var arena3d: Arena3D = null

@onready var p1: BaseFighter = $P1
@onready var p2: BaseFighter = $P2
@onready var beat: BeatService = $BeatService
@onready var music: AudioStreamPlayer = $Music
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/Ui/Hud
@onready var sparring: SparringController = $SparringAI
## The only crowd in the game is the 3D one, built by `Arena3D`. The 2D `CrowdLine` sprite
## layer, its `StageSilhouette` bodies and the `SilhouetteArt` masks are deleted (2026-11-24).
var crowd: CrowdController3D:
	get:
		if arena3d != null:
			return arena3d.crowd3d
		return null
@onready var rounds: RoundController = $RoundController
@onready var bird: BirdHazard = $BirdHazard
@onready var speaker_rings: SpeakerPulse = $SpeakerRings
@onready var time_modulate: CanvasModulate = $TimeOfDay
@onready var floodlight: Sprite2D = $Floodlight
@onready var sun_glow: Sprite2D = $SunGlow
@onready var sunset_wash: Sprite2D = $SunsetWash
@onready var night_wash: Sprite2D = $NightWash
@onready var sun_shaft: Sprite2D = $SunShaft
# 2.5D stage depth (AGENTS.md §9 item 41). `get_node_or_null` keeps the arena runnable if a
# stripped scene omits them; every call site below already null-checks.
@onready var beams: LightBeams = get_node_or_null("LightBeams") as LightBeams
@onready var heat_haze: HeatHaze = get_node_or_null("HeatHaze") as HeatHaze

var _dummy_guard: bool = false
var _shake_time: float = 0.0
var _shake_intensity: float = 0.0
var _thump: float = 0.0
var _time_phase: int = 0
var _time_tween: Tween = null
var _muted: bool = false
## True from the final-round victory until the scene reloads: M auditions the victory beat
## instead of toggling the global mute (AGENTS.md §9 item 48).
var _match_over: bool = false
var _victory_music_started: bool = false
var _separation_queued: bool = false
var _shadow_stretch: float = 1.0
var _shadow_dir: float = -1.0
# Camera (AGENTS.md §9 item 41).
var _zoom_smooth: float = CAMERA_MAX_ZOOM
var _zoom_punch: float = 0.0
var _camera_ready: bool = false
# Phase-driven 2.5D palette: _vis_now is what is on screen, _vis_from/_vis_to bracket the
# cross-fade, so a round change blends the rim, bounce, beams, haze and near-crowd together.
var _vis_now: Dictionary = {}
var _vis_from: Dictionary = {}
var _vis_to: Dictionary = {}
var _vis_tween: Tween = null


func _ready() -> void:
	# Active rounds carry no background music: the round sting, DJ tags, selector and crowd
	# own the fight. A hard stop (not a fade) covers loading the arena while a victory beat or
	# a menu audition is still running (owner playtest, 2026-11-23).
	MusicBed.stop()
	p1.beat_service = beat
	p2.beat_service = beat
	beat.audio_player = music

	# Roster + match setup from TitleScreen.tscn (AGENTS.md §9 backlog item B1). Same FSM,
	# same move table, same beat clock: only the fighter data and the AI style change.
	p1.apply_fighter_profile(MatchSetup.p1_fighter)
	p2.apply_fighter_profile(MatchSetup.p2_fighter)

	# 3D presentation is installed before the round controller applies round 1 lighting, so
	# the first announce already has an arena to light.
	_setup_3d_presentation()

	p2.use_local_input = false          # P2 is driven by the sparring controller only
	p2.input_prefix = "p2_"
	sparring.setup(p1, p2, beat)
	sparring.set_mode(MatchSetup.ai_mode)
	sparring.manual_guard = _dummy_guard
	hud.set("subtitles_enabled", MatchSetup.subtitles)

	p1.camera_shake_requested.connect(_on_shake)
	p2.camera_shake_requested.connect(_on_shake)

	# Facing (owner playtest, 2026-11-17): both fighters track each other for the whole match
	# and turn when they swap sides. RoundController resets it between rounds.
	p1.duel_opponent = p2
	p2.duel_opponent = p1
	# Spawn facing (playtest fix 2026-11-24, issue 1 step 5): P1 opens facing +X and P2 −X,
	# so the very first frame reads as a face-off instead of both looking the same way.
	p1.set_facing(1)
	p2.set_facing(-1)
	p1.face_toward(p2.global_position.x)
	p2.face_toward(p1.global_position.x)

	# Visible attacks: every strike draws a smear over its own hit volume for the whole active
	# window, so a fighter whose sheet has no attack frames (a portrait-only roster entry)
	# no longer lands invisible damage.
	p1.state_changed.connect(_on_fighter_state_changed.bind(p1))
	p2.state_changed.connect(_on_fighter_state_changed.bind(p2))

	hud.set("p1", p1)
	hud.set("p2", p2)
	hud.set("beat", beat)
	hud.set("sparring", sparring)
	hud.set("rounds", rounds)

	if SoundClash != null and not SoundClash.tag_played.is_connected(_on_tag_played):
		SoundClash.tag_played.connect(_on_tag_played)
	beat.beat.connect(_on_beat)
	p1.hype_surge_started.connect(_on_hype_surge)
	p2.hype_surge_started.connect(_on_hype_surge)
	p1.hype_milestone_reached.connect(_on_hype_milestone)
	p2.hype_milestone_reached.connect(_on_hype_milestone)
	p1.static_parry_triggered.connect(_on_static_parry)
	p2.static_parry_triggered.connect(_on_static_parry)
	p1.taunt_finished.connect(_on_taunt_finished)
	p2.taunt_finished.connect(_on_taunt_finished)
	p1.throw_broken.connect(_on_throw_broken)
	p2.throw_broken.connect(_on_throw_broken)
	p1.throw_connected.connect(_on_throw_connected)
	p2.throw_connected.connect(_on_throw_connected)
	p1.speaker_slam_triggered.connect(_on_speaker_slam)
	p2.speaker_slam_triggered.connect(_on_speaker_slam)
	p1.strike_resolved.connect(_on_strike_resolved)
	p2.strike_resolved.connect(_on_strike_resolved)
	# Signature-move staging (2026-11-22): the arena only reacts to cues; damage and hitboxes
	# already resolved inside BaseFighter / ProjectileWave.
	p1.attack_became_active.connect(_on_attack_active)
	p2.attack_became_active.connect(_on_attack_active)
	p1.projectile_spawned.connect(_on_projectile_spawned)
	p2.projectile_spawned.connect(_on_projectile_spawned)
	p1.taunt_callout.connect(_on_taunt_callout)
	p2.taunt_callout.connect(_on_taunt_callout)
	p1.died.connect(_on_fighter_died)
	p2.died.connect(_on_fighter_died)

	# The phase palette must exist before the round controller applies round 1 lighting.
	_init_visuals()
	rounds.setup(p1, p2, self)
	if not rounds.round_ended.is_connected(_on_round_ended):
		rounds.round_ended.connect(_on_round_ended)
	if not rounds.round_started.is_connected(_on_round_started):
		rounds.round_started.connect(_on_round_started)
	if not rounds.match_ended.is_connected(_on_match_ended):
		rounds.match_ended.connect(_on_match_ended)
	if rounds.enabled:
		rounds.start_match()          # Round 1 lighting is applied by the round controller
	else:
		set_time_of_day(_time_phase, 0.0)

	music.finished.connect(_restart_click_loop)
	if not music.playing:
		music.play()

	_cap_particles()
	_prewarm_effects()


func _process(delta: float) -> void:
	_thump = maxf(0.0, _thump - delta * THUMP_DECAY)
	_follow_action(delta)
	_update_shake(delta)
	hud.queue_redraw()


## F3 playtest readout (issue 1 step 8). Prints, for every fighter, the facing yaw of the
## `VisualPivot`, the body's world-space forward, the angle between that forward and the
## nearest ±X axis, and the animation that is actually playing. A forward further than 5°
## off ±X is flagged WRONG so a broken upload cannot pass by looking plausible in motion.
func print_facing_debug() -> void:
	print("\n=== FACING (F3) ===")
	for side in ["p1", "p2"]:
		var fighter: BaseFighter = _fighter_of(side)
		if fighter == null:
			continue
		var model := _model_of(side)
		var name := FighterRoster.display_name(fighter.fighter_key)
		var anim := _anim_of(fighter)
		if model == null:
			print("%-14s key=%s  facing=%+d  NO 3D MODEL (2D sprite)  anim=%s"
				% [side.to_upper() + " " + name, fighter.fighter_key, fighter.facing, anim])
			continue
		var fwd := model.world_forward()
		var err := rad_to_deg(acos(clampf(absf(fwd.x), 0.0, 1.0)))
		print("%-14s key=%-14s state=%-14s facing=%+d  pivot_yaw=%+7.1f deg  forward=(%+.3f, %+.3f)  off±X=%5.1f deg  %s  anim=%s"
			% [side.to_upper() + " " + name, fighter.fighter_key,
				BaseFighter.State.keys()[fighter.state], fighter.facing,
				model.facing_yaw_deg(), fwd.x, fwd.z, err,
				"OK" if err <= 5.0 else "WRONG", anim])
	print("=== END FACING ===\n")


func _fighter_of(side: String) -> BaseFighter:
	return p1 if side == "p1" else p2


func _model_of(side: String) -> FighterModel3D:
	if arena3d == null or arena3d.models == null:
		return null
	return arena3d.models.get(side) as FighterModel3D


func _anim_of(fighter: BaseFighter) -> String:
	var model := _model_of("p1" if fighter == p1 else "p2")
	if model != null:
		var clip := model.current_animation_name()
		if clip != "":
			return clip
	return BaseFighter.State.keys()[fighter.state]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_ESCAPE:
			# Back to Character & Match Setup with the selection intact (B1).
			MatchSetup.escape_to_setup()
		KEY_R:
			get_tree().reload_current_scene()
		KEY_G:
			_dummy_guard = not _dummy_guard
			if sparring != null:
				sparring.manual_guard = _dummy_guard
		KEY_Y:
			if sparring != null:
				sparring.cycle_mode()
		KEY_M:
			# Post-KO the M key auditions the beats; during the fight it stays the mute toggle.
			if _match_over:
				MusicBed.cycle()
				hud.show_music_toast("MUSIC · %s · M TO CYCLE" % MusicBed.label())
			else:
				_set_muted(not _muted)
		KEY_B:
			_spawn_bird()
		KEY_N:
			cycle_time_of_day()
		KEY_V:
			hud.toggle_subtitles()
		KEY_F3:
			print_facing_debug()


# =========================================================================
# Push separation (AGENTS.md §9 backlog item B7)
# =========================================================================
## Deferred so it runs after both fighters have finished their own `move_and_slide()`
## this physics tick — the arena is the parent node, so its `_physics_process` runs first.
func _physics_process(_delta: float) -> void:
	if _separation_queued:
		return
	_separation_queued = true
	call_deferred("_separate_fighters")


func _separate_fighters() -> void:
	_separation_queued = false
	if not _separation_allowed():
		return
	var pos1 := p1.global_position
	var pos2 := p2.global_position
	var distance := pos2.x - pos1.x
	if absf(distance) >= BODY_GAP:
		return
	var dir := 1.0 if distance >= 0.0 else -1.0
	# Split the correction evenly, then let the speaker-stack walls absorb what they can.
	var half := (BODY_GAP - absf(distance)) * 0.5
	var x1 := pos1.x - dir * half
	var x2 := pos2.x + dir * half
	x1 = clampf(x1, BaseFighter.STAGE_LEFT, BaseFighter.STAGE_RIGHT)
	x2 = clampf(x2, BaseFighter.STAGE_LEFT, BaseFighter.STAGE_RIGHT)
	if absf(x2 - x1) < BODY_GAP:
		# One body is pinned against a stack: the free one takes the whole remainder.
		if x1 <= BaseFighter.STAGE_LEFT + 0.5:
			x2 = minf(x1 + BODY_GAP, BaseFighter.STAGE_RIGHT)
		elif x2 >= BaseFighter.STAGE_RIGHT - 0.5:
			x1 = maxf(x2 - BODY_GAP, BaseFighter.STAGE_LEFT)
	if is_equal_approx(x1, pos1.x) and is_equal_approx(x2, pos2.x):
		return
	pos1.x = x1
	pos2.x = x2
	p1.global_position = pos1
	p2.global_position = pos2


## Separation only exists for two grounded bodies that are in control of their position.
func _separation_allowed() -> bool:
	if p1 == null or p2 == null:
		return false
	if p1.state in NO_SEPARATION_STATES or p2.state in NO_SEPARATION_STATES:
		return false
	# Airborne bodies pass over each other: jumping across is part of the movement feel.
	if not p1.is_on_floor() or not p2.is_on_floor():
		return false
	return true


# =========================================================================
# Sound (AGENTS.md §9 backlog item B8)
# =========================================================================
## Mute toggle for everything: the dev click loop and the procedural SFX together, so one
## key never leaves half the game talking. The Master bus carries both, and muting the bus
## (rather than pausing the stream) keeps the 132 BPM clock running, so unmuting never
## desyncs the beat judgement from the music.
func _set_muted(value: bool) -> void:
	_muted = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), value)
	Sfx.set_muted(value)
	if SoundClash != null:
		SoundClash.set_muted(value)


func is_muted() -> bool:
	return _muted


## Impact cue. Blocked contacts knock, plain contacts thud, and a strike judged on the beat
## gets the sub-bass punch so timing reads with the music muted.
func _on_strike_resolved(attacker: BaseFighter, target: BaseFighter, result: Dictionary) -> void:
	if bool(result.get("ignored", false)) or bool(result.get("parried", false)):
		return                    # a parry has its own cue, fired from the fighter signal
	# Event-driven sound clash engine (AGENTS.md §9 item 46): any significant single hit
	# fires the attacker's DJ tag through the tape-delay bus, with no combo/pull-up gate.
	if SoundClash != null:
		SoundClash.on_strike(result, attacker, target)
	var on_beat := bool(result.get("on_beat", false))
	if on_beat:
		Sfx.play(&"hit_onbeat")
	elif bool(result.get("blocked", false)):
		Sfx.play(&"block")
	else:
		Sfx.play(&"hit")

	# B4 / §9 item 21: the struck body flashes for two ticks and throws a contact burst —
	# white/gold when the input was off the beat, green/gold when it was on it.
	if target != null and not bool(result.get("blocked", false)):
		target.flash_impact(on_beat)
	if target != null:
		_add_spark(target.global_position + Vector2(0.0, -110.0),
			&"hit_onbeat" if on_beat else &"hit")
	# Punish: the hit interrupted an attack or a taunt, so it gets the show-off callout.
	if bool(result.get("punish", false)) and not bool(result.get("blocked", false)):
		_announce_callout(&"punish")

	# Patois callouts (AGENTS.md §8). TUMP OUT HIM TEET! answers a heavy upper-box / tump
	# contact, the proverbs answer counters, and TEK WEH HIM MIC! answers a stun/down.
	var hit_id := StringName(result.get("attack_id", &""))
	var unblocked := not bool(result.get("blocked", false))
	# L!kkle Moore's dictionary slam on a counter is his named moment: TEK WEH HIM MIC!
	# replaces the generic line instead of stacking two pills.
	var kid_mic_counter := attacker != null and attacker.fighter_key == &"young_selecta" \
		and bool(result.get("counter", false)) and (hit_id == &"strong" or hit_id == &"upper_box")
	if unblocked:
		if kid_mic_counter:
			_announce_callout(&"stun")
		else:
			var impact_kind := _impact_callout(hit_id, bool(result.get("counter", false)),
				attacker.fighter_key if attacker != null else &"")
			if impact_kind != &"":
				_announce_callout(impact_kind)
	if arena3d != null:
		arena3d.hit_kick(0.9 if bool(result.get("counter", false)) else 0.3)
		arena3d.pulse_speakers(0.8 if unblocked else 0.3)
		# DJs and crowd answer the contact itself (owner request, 2026-11-22). The cue only
		# starts their staggered timers; no combat value is read back out of the yard.
		if unblocked and attacker != null:
			var heavy_contact := hit_id in BaseFighter.HEAVY_ATTACK_IDS \
				or bool(result.get("counter", false))
			arena3d.notify_combat_event(&"heavy_hit" if heavy_contact else &"hit",
				_corner_of(attacker))

	# 2.5D impact juice (AGENTS.md §9 item 41): musical-note trails on heavies and on-beat
	# contacts, and the black-and-gold comic frame plus a micro-zoom on a counter-hit. Light
	# jabs stay clean so a fast exchange is still readable.
	if target == null:
		return
	if not bool(result.get("blocked", false)):
		var attack_id := StringName(result.get("attack_id", &""))
		var heavy_hit := attack_id in BaseFighter.HEAVY_ATTACK_IDS
		var face := attacker.facing if attacker != null else 1
		if heavy_hit or on_beat:
			_add_note_trail(target.global_position + Vector2(0.0, -96.0), face, heavy_hit)
		if bool(result.get("counter", false)):
			_add_impact_frame(&"counter")
			_zoom_punch_burst(0.06)
			_on_shake(1.0, 0.20)


## Headless probe (owner playtest, 2026-11-23): no background beat may be audible while a
## round is live. True when the bed is off and its player is stopped at silence.
func music_bed_silent() -> bool:
	return MusicBed.is_off() and not MusicBed.is_playing() \
		and MusicBed.current_db() <= MusicBed.SILENT_DB + 0.01


## A fighter entering KO: the dramatic arcade drop (fired once per K.O.).
func _on_fighter_died() -> void:
	Sfx.play(&"ko")
	if SoundClash != null:
		SoundClash.on_ko()
	if arena3d != null:
		arena3d.hit_kick(1.3)
		arena3d.pulse_speakers(1.6)
		# The corner that is still standing erupts; the other bank puts its hands on its head.
		var winner_side := 1 if p1 != null and p1.state == BaseFighter.State.KO else 0
		arena3d.notify_combat_event(&"ko", winner_side)


## Round win: the winner throws its celebration pose while the result banner runs
## (AGENTS.md §9 items 33–34). winner -1 is the time-out tie, which has nobody to celebrate.
func _on_round_ended(_round_index: int, winner: int) -> void:
	_clear_projectiles()
	var champion: BaseFighter = null
	if winner == 0:
		champion = p1
	elif winner == 1:
		champion = p2
	if champion != null:
		champion.play_celebration(140)
		# The crowd wants the next tune, not this one again. L!kkle Moore gets WASH-BELLY:
		# the youngest prodigy in the crew is his line, not a generic round-win callout.
		_announce_callout(&"wash_belly" if champion.fighter_key == &"young_selecta" else &"round_win")
	# Final-round K.O.: the winner poses out to the next beat as soon as the celebration starts,
	# instead of waiting through the round-over banner.
	if winner >= 0 and winner < rounds.wins.size() and rounds.wins[winner] >= rounds.rounds_to_win:
		_victory_music_started = true
		_match_over = true
		MusicBed.play_victory()
	if SoundClash != null:
		SoundClash.set_crowd_intensity(1.0)
	if arena3d != null:
		arena3d.pulse_speakers(1.4)
		arena3d.notify_combat_event(&"victory", winner)


## Match over: guarantee the victory bed is running (no-op if the final K.O. already started
## it) and switch M from mute to the beat audition cycle.
func _on_match_ended(_winner: int) -> void:
	_match_over = true
	if not _victory_music_started:
		_victory_music_started = true
		MusicBed.play_victory()


## 100% Crowd Hype Surge: the crowd jumps and the HUD banner flashes for the same
## window the fighter's momentum boost lasts.
func _on_hype_surge(seconds: float) -> void:
	if crowd != null:
		crowd.react(&"hype")
	# The Sound Clash engine owns the horn now, so the old procedural airhorn is not layered
	# under it (anti-mud rule, AGENTS.md §9 item 44).
	if SoundClash != null:
		SoundClash.on_hype_surge()
	if arena3d != null:
		arena3d.hit_kick(0.55)
		arena3d.pulse_speakers(1.5)
		arena3d.notify_combat_event(&"hype", -1)
	# 100 % Crowd Hype punches the camera in and throws the comic frame (AGENTS.md §9 item 41).
	_zoom_punch_burst(0.075)
	_add_impact_frame(&"surge")
	# `TestHud`'s own banner already reads FORWARD! / PULL UP! (§9 item 10); the subtitle keeps
	# rotating the approved Patois pool (item 38) instead of repeating the banner.
	_announce_callout(&"hype")


## Advance one trigger's callout pool and show the next line. Returns false when subtitles
## are off or the HUD pill is still cooling down, so a burst can never stack pills.
func _announce_callout(kind: StringName) -> bool:
	var pool: Array = CALLOUTS.get(kind, [])
	if pool.is_empty():
		return false
	var index := int(_callout_cursor.get(kind, 0)) % pool.size()
	_callout_cursor[kind] = index + 1
	var phrase := String(pool[index])
	return hud.announce_subtitle(phrase, String(CALLOUT_GLOSSES.get(phrase, "")))


## 50 % Crowd Hype: the line reshuffles itself even before the surge lands.
func _on_hype_milestone(_percent: int) -> void:
	if crowd != null:
		crowd.react(&"victory")


## Record Static Parry: an electric vinyl-static spark between the two fighters.
func _on_static_parry(defender: BaseFighter, attacker: BaseFighter) -> void:
	if defender == null or attacker == null:
		return
	var mid := (defender.global_position + attacker.global_position) * 0.5 + Vector2(0.0, -110.0)
	_add_spark(mid)
	if arena3d != null:
		arena3d.spawn_vinyl_parry(mid)
		arena3d.pulse_speakers(0.5)
	_on_shake(0.5, 0.12)
	Sfx.play(&"parry")
	if SoundClash != null:
		SoundClash.set_crowd_intensity(0.7)
	# Record Static Parry interrupts the tune: "hold on a second".
	_announce_callout(&"parry")


## On-beat skank taunt: the one taunt line that gets a callout (off-beat stays quiet).
func _on_taunt_finished(on_beat: bool) -> void:
	if not on_beat:
		return
	# A taunt is a show-off: POPPYSHOW! leads, the older taunt line rotates back in.
	_announce_callout(&"taunt")


## Throw break: the mutual shove-apart gets the same spark flash, with no damage.
func _on_throw_broken(attacker: BaseFighter, defender: BaseFighter) -> void:
	if attacker == null or defender == null:
		return
	_add_spark((attacker.global_position + defender.global_position) * 0.5 + Vector2(0.0, -110.0))
	_on_shake(0.55, 0.14)
	Sfx.play(&"clank")
	# Throw break is the same interruption of the run: hold on a second.
	_announce_callout(&"throw_break")


## A landed throw: the spinback pops the crowd (the slam's shake comes from the fighter).
func _on_throw_connected(attacker: BaseFighter, defender: BaseFighter, kind: StringName) -> void:
	Sfx.play(&"whoosh")
	if kind == &"back":
		if crowd != null:
			crowd.react(&"victory")
	if SoundClash != null:
		SoundClash.set_crowd_intensity(0.85)
		SoundClash.on_throw(attacker)
	if arena3d != null and defender != null:
		arena3d.pulse_speakers(1.1)
		# L!ckshot's collar snatch ends in a mic-drop slam: a bigger sand burst and an
		# extra stack kick read the heavier throw without touching its damage values.
		var slam := attacker != null and attacker.fighter_key == &"lickshot"
		arena3d.spawn_sand_burst(defender.global_position, 1.6 if slam else 0.9)
		if slam:
			arena3d.hit_kick(0.7)
			Sfx.play(&"slam")


## Once per active window: per-move 3D flourish. These are presentation only; the hitbox
## and frame data were already fixed in FighterRoster / BaseFighter.
func _on_attack_active(attacker: BaseFighter, attack_id: StringName) -> void:
	if attacker == null or arena3d == null:
		return
	var front := attacker.global_position + Vector2(float(attacker.facing) * 78.0, -110.0)
	match attacker.fighter_key:
		&"feedback":
			if attack_id == &"strong":
				# Sound-System Bass Jab / Feedback Surge: the stack answers the surge.
				arena3d.pulse_speakers(1.75)
				arena3d.hit_kick(0.3)
				_add_note_trail(front, attacker.facing, true)
			elif attack_id == &"upper_box":
				_add_note_trail(front, attacker.facing, true)
			elif attack_id == &"tump":
				arena3d.hit_kick(0.25)
		&"lickshot":
			if attack_id == &"strong":
				arena3d.pulse_speakers(1.9)     # the dubplate launches off the sub
			elif attack_id == &"tump":
				arena3d.hit_kick(0.45)
				arena3d.spawn_sand_burst(attacker.global_position, 0.8)
				_add_spark(front, &"hit")
			elif attack_id == &"upper_box":
				_add_note_trail(front, attacker.facing, true)
		&"young_selecta":
			if attack_id == &"tump":
				arena3d.spawn_sand_burst(attacker.global_position, 1.1)
				arena3d.hit_kick(0.3)
			elif attack_id == &"upper_box":
				_add_note_trail(front, attacker.facing, true)
			elif attack_id == &"strong":
				arena3d.hit_kick(0.3)


## Projectiles are real combat nodes; the arena mirrors each one with its own 3D prop.
func _on_projectile_spawned(attacker: BaseFighter, _attack_id: StringName, wave: Node2D) -> void:
	if attacker == null or wave == null:
		return
	Sfx.play(&"whoosh")
	if arena3d == null:
		return
	arena3d.spawn_projectile(wave.kind, wave.global_position.x, int(signf(wave.dir)),
		wave.lifetime, wave.travel_distance())
	arena3d.pulse_speakers(1.9)
	_add_note_trail(Vector2(wave.global_position.x, attacker.global_position.y - 104.0),
		attacker.facing, true)


## L!ckshot and L!kkle Moore always get their taunt callout, on or off the beat.
func _on_taunt_callout(fighter: BaseFighter) -> void:
	if fighter == null:
		return
	_announce_callout(&"taunt")
	if arena3d != null:
		arena3d.spawn_sand_burst(fighter.global_position, 0.6)
		arena3d.pulse_speakers(0.7)


## A projectile or its 3D proxy must never survive into the next round.
func _clear_projectiles() -> void:
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("arena_projectiles"):
		node.queue_free()


## Speaker-Stack Bounce: electric impact right where the thrown fighter hit the stack.
func _on_speaker_slam(victim: BaseFighter, _side: int) -> void:
	if victim == null:
		return
	_add_spark(victim.global_position + Vector2(0.0, -110.0), &"hit")
	Sfx.play(&"slam")
	if arena3d != null:
		arena3d.hit_kick(0.8)
		arena3d.pulse_speakers(1.5)
	hud.announce_subtitle("HOLD DAT!", "(Translation: Take that to the speakers!)")


## Transient sparks all share the ParrySpark cap, so a long demo can never pile up nodes.
func _add_spark(at: Vector2, style: StringName = &"parry") -> void:
	if arena3d != null:
		arena3d.spawn_spark(at, style)
		return
	var live := _live_parry_sparks()
	if live.size() >= MAX_PARRY_SPARKS:
		# Recycle the oldest spark so the newest effect still reads.
		live[0].queue_free()
	var spark := ParrySpark.new()
	spark.style = style
	spark.global_position = at
	add_child(spark)


# =========================================================================
# Crowd staging: yard barrier, foreground silhouette and the proximity ebb (§9 item 21)
# =========================================================================


# =========================================================================
# Chromebook safeguards (AGENTS.md §9)
# =========================================================================
## Hard particle ceiling: applied once at start-up to every emitter in the arena, so
## adding nodes later cannot raise it by accident.
func _cap_particles() -> void:
	for node in find_children("*", "CPUParticles2D", true, false):
		var particles := node as CPUParticles2D
		particles.amount = mini(particles.amount, MAX_PARTICLE_AMOUNT)


## Spawn a bird only when none is already in the air (the hazard guards itself too;
## this is the arena-level cap so rapid B presses cannot queue work).
func _spawn_bird() -> void:
	if bird == null:
		return
	var active := 0
	for child in get_children():
		var hazard := child as BirdHazard
		if hazard != null and hazard.is_flying():
			active += 1
	if active >= MAX_ACTIVE_BIRDS:
		return
	bird.spawn_now()


func _live_parry_sparks() -> Array[ParrySpark]:
	var found: Array[ParrySpark] = []
	for child in get_children():
		var spark := child as ParrySpark
		if spark != null and not spark.is_queued_for_deletion():
			found.append(spark)
	return found


## Compile the primitive shaders and allocate the particle buffers now, off-screen and
## invisible, behind the round announce banner. Without this the first footstep, hit or
## parry pays the driver cost mid-fight, which is exactly where an Intel Chromebook's
## shared-memory GPU stutters or freezes.
func _prewarm_effects() -> void:
	var spark := ParrySpark.new()
	spark.global_position = PREWARM_OFFSCREEN
	spark.modulate.a = 0.0            # silent even if it were inside the frame
	add_child(spark)

	var puff := CPUParticles2D.new()
	puff.position = PREWARM_OFFSCREEN
	puff.amount = 4
	puff.lifetime = 0.1
	puff.one_shot = true
	puff.emitting = true
	puff.finished.connect(puff.queue_free)   # self-cleaning, no timer to leak
	add_child(puff)
	# The spark frees itself after ParrySpark.DURATION; both are invisible here.


## Stage thump: one micro-pulse per 132 BPM downbeat (BeatService.beat).
func _on_beat(_beat_index: int) -> void:
	_thump = 1.0
	if speaker_rings != null:
		speaker_rings.pulse()
	if arena3d != null:
		arena3d.pulse_speakers(1.0)
		arena3d.beat_pulse()


# =========================================================================
# Round-based time of day (AGENTS.md §9)
# =========================================================================
## phase 0 = Afternoon Sun (Round 1), 1 = Golden Hour (Round 2), 2 = Late Night
## (Round 3 / final). `duration` 0 applies instantly; otherwise the tint, floodlight
## and sun glow cross-fade together.
func set_time_of_day(phase: int, duration: float = TIME_TRANSITION_SEC) -> void:
	_time_phase = clampi(phase, 0, TIME_PHASES.size() - 1)
	if arena3d != null:
		arena3d.apply_phase(_time_phase, duration)
	var target: Dictionary = TIME_PHASES[_time_phase]
	var tint: Color = target["tint"]
	var flood: float = target["flood"]
	var sun: float = target["sun"]
	var sunset: float = target["sunset"]
	var night: float = target["night"]
	var shaft: float = target["shaft"]
	var sun_pos: Vector2 = target["sun_pos"]
	var sun_scale: float = target["sun_scale"]
	var stretch: float = target["shadow_stretch"]

	if _time_tween != null and _time_tween.is_valid():
		_time_tween.kill()
	# The cast direction is a switch, not a blend: shadows flip to the sunset side at once and
	# the stretch carries the eye through the transition.
	_shadow_dir = float(target["shadow_dir"])
	# 2.5D palette: blend the rim colours, bounce, beams, haze and near-crowd with the same
	# duration as the sky, so a round change reads as one lighting change, not five.
	_vis_from = _vis_now.duplicate()
	_vis_to = _phase_visuals(target)
	if _vis_tween != null and _vis_tween.is_valid():
		_vis_tween.kill()
	if duration <= 0.0:
		_apply_vis_blend(1.0)
	if duration <= 0.0:
		time_modulate.color = tint
		floodlight.modulate.a = flood
		sun_glow.modulate.a = sun
		sun_glow.position = sun_pos
		sun_glow.scale = Vector2(sun_scale, sun_scale)
		sunset_wash.modulate.a = sunset
		night_wash.modulate.a = night
		sun_shaft.modulate.a = shaft
		_set_shadow_light(stretch)
		return

	_time_tween = create_tween()
	_time_tween.set_parallel(true)
	_time_tween.set_trans(Tween.TRANS_SINE)
	_time_tween.set_ease(Tween.EASE_IN_OUT)
	_time_tween.tween_property(time_modulate, "color", tint, duration)
	_time_tween.tween_property(floodlight, "modulate:a", flood, duration)
	_time_tween.tween_property(sun_glow, "modulate:a", sun, duration)
	_time_tween.tween_property(sun_glow, "position", sun_pos, duration)
	_time_tween.tween_property(sun_glow, "scale", Vector2(sun_scale, sun_scale), duration)
	_time_tween.tween_property(sunset_wash, "modulate:a", sunset, duration)
	_time_tween.tween_property(night_wash, "modulate:a", night, duration)
	_time_tween.tween_property(sun_shaft, "modulate:a", shaft, duration)
	_time_tween.tween_method(_set_shadow_light, _shadow_stretch, stretch, duration)
	_vis_tween = create_tween()
	_vis_tween.tween_method(_apply_vis_blend, 0.0, 1.0, duration)



## Contact-shadow shape for the current phase: fighters and the crowd move together.
func _set_shadow_light(stretch: float) -> void:
	_shadow_stretch = stretch
	for fighter in [p1, p2]:
		if fighter != null:
			fighter.set_light(_shadow_dir, _shadow_stretch)


# =========================================================================
# Visible strikes (AGENTS.md §9 item 23)
# =========================================================================
## Fired on every FSM transition for both fighters. ATTACK_ACTIVE is the tick the hitbox is
## armed, so the smear appears exactly with the contact window instead of on the input.
func _on_fighter_state_changed(old_state: int, new_state: int, fighter: BaseFighter) -> void:
	if fighter != null and new_state == BaseFighter.State.KNOCKDOWN \
			and old_state != BaseFighter.State.KNOCKDOWN:
		# TEK WEH HIM MIC! for a body on the sand (AGENTS.md §8, item 47).
		_announce_callout(&"stun")
		if SoundClash != null:
			SoundClash.on_knockdown(fighter)
		if arena3d != null:
			arena3d.hit_kick(0.75)
			# The other corner scored the knockdown and gets the roar.
			arena3d.notify_combat_event(&"knockdown", 1 - _corner_of(fighter))
	if new_state != BaseFighter.State.ATTACK_ACTIVE or fighter == null:
		return
	if not fighter.shows_strike_tell():
		return              # this attack has its own drawn pose (AGENTS.md §9 item 27)
	_add_strike_tell(fighter)


func _add_strike_tell(fighter: BaseFighter) -> void:
	var volume := fighter.attack_volume()
	if volume.size == Vector2.ZERO:
		return
	if arena3d != null:
		arena3d.spawn_strike_arc(volume.get_center(), fighter.facing, volume.size.x > 90.0)
		return
	var live := _live_strike_tells()
	if live.size() >= MAX_STRIKE_TELLS:
		live[0].queue_free()
	var tell := StrikeTell.new()
	tell.source = fighter
	tell.global_position = Vector2(volume.get_center().x, volume.get_center().y)
	tell.facing = fighter.facing
	tell.reach = volume.size.x * 0.5 + 26.0
	tell.radius = maxf(volume.size.y * 0.5, 14.0)
	tell.heavy = volume.size.x > 90.0
	add_child(tell)


func _live_strike_tells() -> Array[StrikeTell]:
	var found: Array[StrikeTell] = []
	for child in get_children():
		var tell := child as StrikeTell
		if tell != null and not tell.is_queued_for_deletion():
			found.append(tell)
	return found


func cycle_time_of_day(duration: float = TIME_TRANSITION_SEC) -> void:
	set_time_of_day((_time_phase + 1) % TIME_PHASES.size(), duration)


func time_of_day_phase() -> int:
	return _time_phase


func time_of_day_name() -> String:
	return String(TIME_PHASES[_time_phase]["name"])


func _restart_click_loop() -> void:
	if is_instance_valid(music) and music.stream_paused == false:
		music.play()


# =========================================================================
# 3D presentation layer (AGENTS.md §9 items 43–45)
# =========================================================================
## Build the Node3D yard + camera + cel-shaded fighter proxies, then hide the 2D drawing
## layer. Combat nodes (Floor/Wall static bodies, P1/P2 CharacterBody2Ds, hitboxes, beat
## service, round controller, HUD) are deliberately left alone.
func _setup_3d_presentation() -> void:
	if not presentation_3d:
		return
	arena3d = Arena3D.new()
	arena3d.name = "Arena3D"
	add_child(arena3d)
	arena3d.setup(p1, p2)
	# The 3D proxies replace these drawings; the nodes stay alive so their measured values
	# (shadow stretch, crowd darkness, palette) keep driving the headless checks and any
	# later 2D fallback.
	var hidden := [
		"Stage", "Atmosphere", "SunsetWash", "NightWash", "SunGlow", "SunShaft",
		"SpeakerRings", "LightBeams", "TimeOfDay", "Floodlight", "WindMotes",
		"RecordCrates", "HeatHaze", "YardBarrier", "BirdHazard",
	]
	for node_name in hidden:
		var node := get_node_or_null(node_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		elif node is Node3D:
			(node as Node3D).visible = false
	p1.set_3d_presentation(true)
	p2.set_3d_presentation(true)


## Round start: the ~6 s intro slot begins on the announce, so the single guitar stab lands
## on FIGHT! at 1.8 s while player control still opens on the round controller's own clock.
## The 3D speaker cones punch on the tag itself, not just on the contact that caused it.
func _on_tag_played(_key: StringName, _priority: int) -> void:
	if arena3d != null:
		arena3d.pulse_speakers(1.35)
		# A DJ tag is the booth's own cue: horn up, crowd on its feet.
		arena3d.notify_combat_event(&"tag", -1)


func _on_round_started(round_index: int) -> void:
	_clear_projectiles()
	# Every round start runs through here — Match 1, Match 2, Match 3 and each rematch, which
	# restarts inside this scene after MATCH_OVER. The music bed is cut *before* the 6 s round
	# sting, so no post-K.O. victory beat can bleed under the next match's rounds
	# (owner playtest, 2026-11-23).
	MusicBed.stop()
	_match_over = false
	_victory_music_started = false
	if arena3d != null:
		# No new round opens on last round's celebration.
		arena3d.reset_atmosphere()
	if SoundClash != null:
		SoundClash.play_round_start()
	if arena3d != null:
		arena3d.pulse_speakers(1.6)
	# Match intro (round 1 only): the rotating Patwa wisdom banner, with the V-key gloss.
	if round_index == 0:
		_show_match_proverb()


## Show the next match-intro proverb and advance the rotation. Returns false only when the
## pool is empty; the HUD decides whether the English gloss is visible (V).
func _show_match_proverb(seconds: float = PROVERB_BANNER_SECONDS) -> bool:
	if PROVERB_BANNER.is_empty():
		return false
	var phrase := String(PROVERB_BANNER[_proverb_cursor % PROVERB_BANNER.size()])
	_proverb_cursor += 1
	return hud.show_proverb(phrase, String(CALLOUT_GLOSSES.get(phrase, "")), seconds)


## Which in-match proverb pool a contact belongs to. WASH-BELLY is reserved for L!kkle
## Moore, the crew's youngest prodigy; every fighter uses the shared counter/heavy pools.
func _impact_callout(hit_id: StringName, counter: bool, fighter_key: StringName) -> StringName:
	if fighter_key == &"young_selecta" and (counter or hit_id in BaseFighter.HEAVY_ATTACK_IDS):
		return &"wash_belly"
	if counter:
		return &"counter"
	if hit_id == &"upper_box" or hit_id == &"tump":
		return &"heavy"
	return &""


func _follow_action(delta: float = 0.0) -> void:
	var mid := (p1.global_position + p2.global_position) * 0.5
	var span := clampf(absf(p1.global_position.x - p2.global_position.x) * 1.8,
		CAMERA_MIN_DISTANCE, CAMERA_MAX_DISTANCE)
	var target_zoom := clampf(CAMERA_FIT_DISTANCE / span, CAMERA_MIN_ZOOM, CAMERA_MAX_ZOOM)
	if not _camera_ready:
		_zoom_smooth = target_zoom
		_camera_ready = true
	if delta > 0.0:
		# Closing for a brawl eases in, and bodies thrown apart ease back out, instead of
		# the framing snapping on every position change.
		_zoom_smooth = lerpf(_zoom_smooth, target_zoom,
			1.0 - exp(-CAMERA_ZOOM_SMOOTH * delta))
		_zoom_punch = move_toward(_zoom_punch, 0.0, CAMERA_PUNCH_DECAY * delta)
	else:
		_zoom_smooth = target_zoom
	var half := STAGE_SIZE * 0.5 / _zoom_smooth
	var target := mid + Vector2(0.0, -CAMERA_FOCUS_LIFT)
	target.x = clampf(target.x, half.x, STAGE_SIZE.x - half.x)
	target.y = clampf(target.y, half.y, STAGE_SIZE.y - half.y)
	camera.global_position = target
	# Zooming in only ever shrinks the visible area, so the thump and the punch never expose
	# an edge of the single-layer stage art.
	camera.zoom = Vector2(_zoom_smooth, _zoom_smooth) * (1.0 + THUMP_ZOOM * _thump + _zoom_punch)


## Which loyalty bank a fighter belongs to: 0 = P1's left corner, 1 = P2's right corner.
## Presentation only — the crowd's side never feeds back into the fight.
func _corner_of(fighter: BaseFighter) -> int:
	return 0 if fighter == p1 else 1


func _on_shake(intensity: float, duration: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_time = maxf(_shake_time, duration)


func _update_shake(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) \
			* _shake_intensity * 14.0
		if _shake_time <= 0.0:
			_shake_time = 0.0
			_shake_intensity = 0.0
			camera.offset = Vector2.ZERO


# =========================================================================
# 2.5D impact juice (AGENTS.md §9 item 41)
# =========================================================================
## Punch the framing zoom in by `amount`, then let `_follow_action()` ease it back. Only ever
## positive, so the stage art keeps covering the whole view.
func _zoom_punch_burst(amount: float = 0.055) -> void:
	_zoom_punch = maxf(_zoom_punch, maxf(amount, 0.0))


## Vibrant musical notes arcing along a heavy strike (or an on-beat contact). Capped like
## every other transient in the arena.
func _add_note_trail(at: Vector2, facing: int, heavy: bool) -> void:
	if arena3d != null:
		arena3d.spawn_notes(at, facing, heavy)
		return
	var live := _live_note_trails()
	if live.size() >= MAX_NOTE_TRAILS:
		live[0].queue_free()
	var trail := NoteTrail.new()
	trail.global_position = at
	trail.facing = facing if facing != 0 else 1
	trail.heavy = heavy
	add_child(trail)


func _live_note_trails() -> Array[NoteTrail]:
	var found: Array[NoteTrail] = []
	for child in get_children():
		var trail := child as NoteTrail
		if trail != null and not trail.is_queued_for_deletion():
			found.append(trail)
	return found


## Black-and-gold comic impact frame: at most one alive at a time, so two contacts in the same
## second never stack a black screen.
func _add_impact_frame(kind: StringName) -> void:
	var live := _live_impact_frames()
	if live.size() >= MAX_IMPACT_FRAMES:
		live[0].queue_free()
	var frame := ImpactFrame.new()
	frame.kind = kind
	add_child(frame)


func _live_impact_frames() -> Array[ImpactFrame]:
	var found: Array[ImpactFrame] = []
	for child in get_children():
		var frame := child as ImpactFrame
		if frame != null and not frame.is_queued_for_deletion():
			found.append(frame)
	return found


# =========================================================================
# Phase-driven 2.5D palette (AGENTS.md §9 item 41)
# =========================================================================
## The colours and weights one time-of-day phase hands to every presentation layer.
func _phase_visuals(phase: Dictionary) -> Dictionary:
	return {
		"rim_a": phase["rim_a"],
		"rim_b": phase["rim_b"],
		"rim_strength": float(phase["rim_strength"]),
		"light_uv": phase["light_uv"],
		"bounce": float(phase["bounce"]),
		"density": float(phase["shadow_density"]),
		"beam": float(phase["beam"]),
		"haze": float(phase["haze"]),
		"sunset": float(phase["sunset"]),
		"night": float(phase["night"]),
	}


## Round 1's palette, applied before the round controller can change it.
func _init_visuals() -> void:
	_vis_now = _phase_visuals(TIME_PHASES[0])
	_vis_from = _vis_now.duplicate()
	_vis_to = _vis_now.duplicate()
	_push_visuals()


## `t` 0 → the palette on screen before the change, 1 → the new phase.
func _apply_vis_blend(t: float) -> void:
	for key in _vis_to:
		var to = _vis_to[key]
		var from = _vis_from.get(key, to)
		match typeof(to):
			TYPE_COLOR:
				_vis_now[key] = (from as Color).lerp(to as Color, t)
			TYPE_VECTOR2:
				_vis_now[key] = (from as Vector2).lerp(to as Vector2, t)
			_:
				_vis_now[key] = lerpf(float(from), float(to), t)
	_push_visuals()


## Fan the blended palette out to the fighters, crowd, beams, haze and near-crowd. Every
## target is null-checked, so a scene without one of the new nodes still runs.
func _push_visuals() -> void:
	if _vis_now.is_empty():
		return
	var rim_a: Color = _vis_now.get("rim_a", Color.WHITE)
	var rim_b: Color = _vis_now.get("rim_b", Color.WHITE)
	var rim_strength := float(_vis_now.get("rim_strength", 0.0))
	var light_uv: Vector2 = _vis_now.get("light_uv", Vector2(0.0, -1.0))
	var bounce := float(_vis_now.get("bounce", 0.0))
	var density := float(_vis_now.get("density", 1.0))
	var sunset := float(_vis_now.get("sunset", 0.0))
	var night := float(_vis_now.get("night", 0.0))
	for fighter in [p1, p2]:
		if fighter == null:
			continue
		fighter.set_rim_light(rim_a, rim_b, rim_strength, light_uv, bounce)
		if fighter.shadow != null:
			fighter.shadow.density = density
	if beams != null:
		beams.set_palette(rim_a, rim_b)
		beams.set_intensity(float(_vis_now.get("beam", 0.0)))
	if heat_haze != null:
		heat_haze.set_phase(sunset, night)
		heat_haze.set_intensity(float(_vis_now.get("haze", 0.0)))

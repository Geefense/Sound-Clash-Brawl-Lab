class_name AIProfile
extends Resource
## PART B commit 6 — the CPU's difficulty knobs, as data instead of constants baked into the
## policy. `SparringController` carries one as an `@export`, so the workshop can swap a profile in
## the inspector or through `set_preset()` without a new menu; the three presets below are the
## shipped ones and **Normal is the default**.
##
## Every value is a count of 60 Hz physics frames unless it says otherwise. Nothing here reads or
## writes frame data, hitboxes or Crowd Hype — the brain only decides *when* the same `Command`
## a human would press is allowed to be pressed.
##
## The knobs, and what they change:
##   reaction_frames     how old the P1 snapshot must be before the AI can see it at all
##   reaction_jitter     seeded 0…N extra frames on top, re-rolled every 45 frames
##   attack_cooldown_frames  minimum frames between two attack decisions (never below 40)
##   max_consecutive_attacks how many attacks the AI may chain before it must breathe
##   breathing_min/max_frames  the spacing/footsies window after that chain, seeded per roll
##   round_start_neutral_frames  no attack at all this long after the round opens
##   getup_neutral_frames  same, after its own get-up
##   whiff_neutral_frames  same, after its own whiffed or blocked attack
##   landed_neutral_frames  a short reset after an attack that actually landed
##   punish_chance       probability that a seen recovery becomes a punish at all
##   guard_delay_frames  how long the delayed snapshot must show a threat before it guards

@export var id: StringName = &"normal"
@export var reaction_frames: int = 18
@export var reaction_jitter: int = 6
@export var attack_cooldown_frames: int = 44
@export var max_consecutive_attacks: int = 2
@export var breathing_min_frames: int = 30
@export var breathing_max_frames: int = 45
@export var round_start_neutral_frames: int = 66
@export var getup_neutral_frames: int = 42
@export var whiff_neutral_frames: int = 34
@export var landed_neutral_frames: int = 6
@export var punish_chance: float = 0.55
## How long the delayed snapshot has to keep showing a threat before the guard actually rises.
## With the 18-frame perception delay this is the AI's whole block reaction (~40 frames on
## Normal), which is what lets a jab string land before it starts blocking.
@export var guard_delay_frames: int = 22

## The three shipped presets. Built once and handed out read-only: a profile is data, and the
## brain never writes to it, so sharing one instance keeps `set_preset()` allocation-free.
static var _presets: Dictionary = {}


## Named preset. Unknown names fall back to Normal, which is also the default profile.
static func preset(name: StringName) -> AIProfile:
	var key := String(name)
	if _presets.has(key):
		return _presets[key]
	var p := AIProfile.new()
	p.id = &"normal"
	match key:
		"easy":
			p.id = &"easy"
			p.reaction_frames = 26
			p.reaction_jitter = 8
			p.attack_cooldown_frames = 58
			p.breathing_min_frames = 45
			p.breathing_max_frames = 60
			p.round_start_neutral_frames = 84
			p.getup_neutral_frames = 54
			p.whiff_neutral_frames = 46
			p.punish_chance = 0.30
			p.guard_delay_frames = 30
		"hard":
			p.id = &"hard"
			p.reaction_frames = 12
			p.reaction_jitter = 4
			# Hard is still gated: the owner's 40-frame floor and the two-attack ceiling hold at
			# every difficulty, only the delay and the punish rate get tighter.
			p.attack_cooldown_frames = 40
			p.breathing_min_frames = 30
			p.breathing_max_frames = 40
			p.round_start_neutral_frames = 60
			p.getup_neutral_frames = 30
			p.whiff_neutral_frames = 24
			p.punish_chance = 0.80
			p.guard_delay_frames = 14
		_:
			p.id = &"normal"
	_presets[key] = p
	return p


## The preset names the workshop can ask for, easiest first.
static func preset_names() -> Array[String]:
	return ["easy", "normal", "hard"]

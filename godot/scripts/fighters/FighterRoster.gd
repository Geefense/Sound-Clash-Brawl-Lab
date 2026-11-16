class_name FighterRoster
extends RefCounted
## Playable roster data for Fighter #1–#3 (AGENTS.md §9 backlog item B1).
##
## One shared FSM (`BaseFighter`), one shared move table, one shared beat clock: this file
## only supplies the per-fighter numbers and the sprite frames. Nothing here decides combat
## outcomes, and no fighter gets its own copy of the state machine.
##
## Art note: the two new fighters were imported from owner uploads that were sliced and
## background-stripped by `art-source/fighters/prep_fighter_art.py` into ≤512 px frames
## (the project import cap). Their offsets and scales are therefore authored against those
## processed frames, and `anim_source_max` is set to each frame's own longest side so the
## `_import_cap_ratio()` compensation is 1.0 rather than the Feedback pack's 1536 → 512.
##
## Sizes are the owner's proportions, not measured precision:
##   * adult fighters (Feedback, Dubplate) render 121.75 px tall — the Feedback idle
##     reference (487 px at BASE_SPRITE_SCALE 0.25),
##   * Young Selecta renders at 82 % of that (≈ 99.8 px) for kid-prodigy spacing.
## Per-frame scales differ only because each frame's canvas contains different props
## (mic stand, boombox); they are chosen to hold the *character* at the target height.

const ADULT_RENDER_HEIGHT := 121.75     # Feedback idle: 487 px × 0.25
const KID_HEIGHT_FRACTION := 0.82       # owner direction: ~82 % of an adult fighter

## Order shown on the title screen.
const ORDER: Array[StringName] = [&"feedback", &"dubplate", &"young_selecta"]

const FIGHTERS := {
	&"feedback": {
		"name": "FEEDBACK",
		"tagline": "Fighter #1 · mic cord and Wallabees",
		"walk_speed": 220.0,
		"reach_bonus": 0.0,
		"stand_size": Vector2(60, 160),
		"crouch_size": Vector2(60, 96),
		"uses_scene_frames": true,      # the full 17-pose pack already lives in BaseFighter.tscn
		"frames": {},
		"anim_offset": {},
		"anim_scale": {},
		"anim_source_max": {},
		"attack_anims": {},
	},
	# Fighter #2 — the Rasta-stripe veteran selector. One approved portrait so far, so every
	# state shows it until Dubplate's own animation set exists (§9 art TODO, not invented here).
	&"dubplate": {
		"name": "DUBPLATE",
		"tagline": "Fighter #2 · veteran selector, rasta-stripe jacket",
		"walk_speed": 205.0,            # heavier, more deliberate than Feedback
		"reach_bonus": 0.0,
		"stand_size": Vector2(62, 162),
		"crouch_size": Vector2(62, 98),
		"uses_scene_frames": false,
		"frames": {
			&"idle": ["res://assets/sprites/dubplate/portrait.png"],
		},
		"anim_offset": {
			"idle": Vector2(-137.8, -255.0),
		},
		"anim_scale": {
			"idle": 0.2378,             # 121.75 px target / 512 px frame
		},
		"anim_source_max": {
			"idle": 512.0,
		},
		"attack_anims": {},
	},
	# Fighter #3 — the ten-year-old school-uniform prodigy. Faster on his feet and the
	# boom-mic thrust reaches 25 px further than an adult's jab (owner direction).
	&"young_selecta": {
		"name": "YOUNG SELECTA",
		"tagline": "Fighter #3 · school-uniform prodigy",
		"walk_speed": 250.0,            # "slightly faster": 220 × 1.14
		"reach_bonus": 25.0,            # +25 px boom-mic reach
		"stand_size": Vector2(52, 131),  # 160 × 0.82 — the hurtbox follows the drawing
		"crouch_size": Vector2(52, 79),
		"uses_scene_frames": false,
		"frames": {
			# Ready stance (backpack, two-finger salute) covers every unanimated state.
			&"idle": ["res://assets/sprites/young-selecta/idle.png"],
			&"walk": ["res://assets/sprites/young-selecta/idle.png"],
			&"jump": ["res://assets/sprites/young-selecta/idle.png"],
			&"crouch": ["res://assets/sprites/young-selecta/idle.png"],
			&"block": ["res://assets/sprites/young-selecta/idle.png"],
			&"guard_entry": ["res://assets/sprites/young-selecta/idle.png"],
			&"guard_recovery": ["res://assets/sprites/young-selecta/idle.png"],
			&"skank": ["res://assets/sprites/young-selecta/idle.png"],
			&"hitstun": ["res://assets/sprites/young-selecta/idle.png"],
			&"knockdown": ["res://assets/sprites/young-selecta/idle.png"],
			&"ko": ["res://assets/sprites/young-selecta/idle.png"],
			&"launched": ["res://assets/sprites/young-selecta/idle.png"],
			&"tumble": ["res://assets/sprites/young-selecta/idle.png"],
			# Two-handed boom-mic thrust = light jab and the BOX (J / K).
			&"jab": ["res://assets/sprites/young-selecta/thrust.png"],
			&"box_startup": ["res://assets/sprites/young-selecta/thrust.png"],
			&"box_active": ["res://assets/sprites/young-selecta/thrust.png"],
			&"box_recovery": ["res://assets/sprites/young-selecta/thrust.png"],
			# Upright mic-stand slam = the heavy hits (L kick slot and I upper box).
			&"sparta_startup": ["res://assets/sprites/young-selecta/slam.png"],
			&"sparta_active": ["res://assets/sprites/young-selecta/slam.png"],
			&"sparta_recovery": ["res://assets/sprites/young-selecta/slam.png"],
		},
		"anim_offset": {
			# offset = frame centre − (sole centre x, sole row), in processed pixels.
			"idle": Vector2(33.0, -255.0),
			"walk": Vector2(33.0, -255.0),
			"jump": Vector2(33.0, -255.0),
			"crouch": Vector2(33.0, -255.0),
			"block": Vector2(33.0, -255.0),
			"guard_entry": Vector2(33.0, -255.0),
			"guard_recovery": Vector2(33.0, -255.0),
			"skank": Vector2(33.0, -255.0),
			"hitstun": Vector2(33.0, -255.0),
			"knockdown": Vector2(33.0, -255.0),
			"ko": Vector2(33.0, -255.0),
			"launched": Vector2(33.0, -255.0),
			"tumble": Vector2(33.0, -255.0),
			"jab": Vector2(-46.8, -254.0),
			"box_startup": Vector2(-46.8, -254.0),
			"box_active": Vector2(-46.8, -254.0),
			"box_recovery": Vector2(-46.8, -254.0),
			"sparta_startup": Vector2(-17.0, -254.0),
			"sparta_active": Vector2(-17.0, -254.0),
			"sparta_recovery": Vector2(-17.0, -254.0),
		},
		"anim_scale": {
			"idle": 0.195,              # 99.8 px target / 512 px frame
			"walk": 0.195, "jump": 0.195, "crouch": 0.195, "block": 0.195,
			"guard_entry": 0.195, "guard_recovery": 0.195, "skank": 0.195,
			"hitstun": 0.195, "knockdown": 0.195, "ko": 0.195,
			"launched": 0.195, "tumble": 0.195,
			"jab": 0.198,               # frame also carries the mic stand
			"box_startup": 0.198, "box_active": 0.198, "box_recovery": 0.198,
			"sparta_startup": 0.225,    # the stand is taller than the kid in this frame
			"sparta_active": 0.225, "sparta_recovery": 0.225,
		},
		"anim_source_max": {
			"idle": 512.0, "walk": 512.0, "jump": 512.0, "crouch": 512.0,
			"block": 512.0, "guard_entry": 512.0, "guard_recovery": 512.0, "skank": 512.0,
			"hitstun": 512.0, "knockdown": 512.0, "ko": 512.0,
			"launched": 512.0, "tumble": 512.0,
			"jab": 512.0, "box_startup": 512.0, "box_active": 512.0, "box_recovery": 512.0,
			"sparta_startup": 512.0, "sparta_active": 512.0, "sparta_recovery": 512.0,
		},
		# I = Upper Box plays the mic-stand slam, the same pose as the heavy hits.
		"attack_anims": {
			&"upper_box": {
				"anim_startup": &"sparta_startup",
				"anim_active": &"sparta_active",
				"anim_recovery": &"sparta_recovery",
			},
		},
	},
}


static func has_fighter(key: StringName) -> bool:
	return FIGHTERS.has(key)


static func profile(key: StringName) -> Dictionary:
	return FIGHTERS.get(key, FIGHTERS[&"feedback"])


static func display_name(key: StringName) -> String:
	return String(profile(key)["name"])


static func walk_speed_for(key: StringName) -> float:
	return float(profile(key)["walk_speed"])


## Build the frames for a fighter that does not use the scene's Feedback SpriteFrames.
## Textures are loaded by path so the .tscn stays readable; the Web export includes them
## because the preset exports all resources.
static func build_frames(key: StringName) -> SpriteFrames:
	var data := profile(key)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var table: Dictionary = data["frames"]
	for anim in table:
		var paths: Array = table[anim]
		if paths.is_empty():
			continue
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, 1.0)
		for path in paths:
			var tex := load(String(path)) as Texture2D
			if tex == null:
				push_warning("FighterRoster: missing texture %s" % path)
				continue
			frames.add_frame(anim, tex)
	return frames

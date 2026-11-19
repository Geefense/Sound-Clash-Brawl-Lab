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
##   * adult fighters (Feedback, Lickshot) render 121.75 px tall — the Feedback idle
##     reference (487 px at BASE_SPRITE_SCALE 0.25),
##   * Likkle Moore (Fighter #3, key `young_selecta`) renders at 82 % of that (≈ 99.8 px) for
##     kid-prodigy spacing.
## Per-frame scales differ only because each frame's canvas contains different props
## (mic stand, boombox); they are chosen to hold the *character* at the target height.

const ADULT_RENDER_HEIGHT := 121.75     # Feedback idle: 487 px × 0.25
const KID_HEIGHT_FRACTION := 0.82       # owner direction: ~82 % of an adult fighter

## Order shown on the title screen.
const ORDER: Array[StringName] = [&"feedback", &"lickshot", &"young_selecta"]

const FIGHTERS := {
	&"feedback": {
		"name": "FEEDBACK",
		"tagline": "Fighter #1 · mic cord and Wallabees",
		"walk_speed": 220.0,
		"reach_bonus": 0.0,
		"stand_size": Vector2(60, 160),
		"crouch_size": Vector2(60, 96),
		"uses_scene_frames": true,      # the full 17-pose pack + 2026-11-18 set live in BaseFighter.tscn
		"frames": {},
		"anim_offset": {},
		"anim_scale": {},
		"anim_source_max": {},
		# 2026-11-18 pose set (AGENTS.md §9 item 33). Only the animation names change: the
		# startup/active/recovery ticks, damage, knockback and hitboxes stay exactly as they
		# were, so this is presentation wiring and not a combat change.
		"attack_anims": {
			&"jab": {
				"anim_startup": &"open_slap",
				"anim_active": &"open_slap",
				"anim_recovery": &"open_slap",
			},
			# The high Clarks boot replaces only the L (tump) contact frame; the Sparta frames
			# still carry the windup and the recovery.
			&"tump": {
				"anim_startup": &"sparta_startup",
				"anim_active": &"clarks_kick",
				"anim_recovery": &"sparta_recovery",
			},
			&"upper_box": {
				"anim_startup": &"sky_fist",
				"anim_active": &"sky_fist",
				"anim_recovery": &"sky_fist",
			},
		},
		# The two throw moments and the collar grab now carry drawn poses.
		"state_anims": {
			"grab": &"hand_reach",
			"throw_break": &"palm_shove",
			"throw_release": &"palm_shove",
		},
		# T: lean back into the groove, then settle into the existing skank loop.
		"taunt_sequence": [&"lean_back", &"skank"],
		"celebrate_anim": &"sky_fist",
		# These attacks now ship their own drawn pose, so the arena must not also smear the
		# generic strike tell over them.
		"no_strike_tell": [&"jab", &"tump", &"upper_box"],
	},
	# Fighter #2 — Lickshot, renamed from Dubplate (AGENTS.md §9 item 26) and given his own
	# four-pose set on 2026-11-17 (§9 item 27): mic stance, high kick, Sonic Clap windup and
	# Sonic Clap impact. The old single portrait is archived under
	# assets/sprites/lickshot/_archive/ and is no longer wired. The key is `lickshot`; no
	# `dubplate` roster entry may come back — the word survives only as the music term
	# (Dubplate meter, the late-night-dubplate round banner), never as this fighter's name.
	#
	# Art: the four poses were keyed, floor-cut and capped to 512 px by
	# `art-source/fighters/prep_lickshot_poses.py`. Offsets and scales come from that script's
	# report, not from eyeballing: the character crown-to-sole is authored at 121.75 px (× 1.24
	# = ~151 px on screen) and each pose's measured alpha bottom lands on world y 592
	# (`BaseFighter.REACTION_FLOOR_Y`), so the Wallabees never sink into the sand.
	# `no_strike_tell` lists the attacks that now have real pose art, so the arena stops
	# painting the generic strike smear over them.
	&"lickshot": {
		"name": "LICKSHOT",
		"tagline": "Fighter #2 · rasta mesh vest, Wallabees and a corded mic",
		"walk_speed": 205.0,            # heavier, more deliberate than Feedback
		"reach_bonus": 0.0,
		"stand_size": Vector2(62, 162),
		"crouch_size": Vector2(62, 98),
		"uses_scene_frames": false,
		"frames": {
			# Mic stance carries the neutral movement states; the 2026-11-18 set (AGENTS.md §9
			# item 34) covers guard, jab, upper box, taunt art and celebration, and the approved
			# 2026-11-19 batch (§9 item 38) owns walk, the 8-pose skank and every reaction.
			&"idle": ["res://assets/sprites/lickshot/idle.png"],
			# Signature selector walk: six evenly spaced stride poses extracted from the owner's
			# 3 s walk video (the recycled idle walk is retired).
			&"walk": [
				"res://assets/sprites/lickshot/walk_01.png",
				"res://assets/sprites/lickshot/walk_02.png",
				"res://assets/sprites/lickshot/walk_03.png",
				"res://assets/sprites/lickshot/walk_04.png",
				"res://assets/sprites/lickshot/walk_05.png",
				"res://assets/sprites/lickshot/walk_06.png",
			],
			&"jump": ["res://assets/sprites/lickshot/idle.png"],
			&"crouch": ["res://assets/sprites/lickshot/idle.png"],
			# One drawn guard pose covers entry, the held brace and the release.
			&"block": ["res://assets/sprites/lickshot/guard_stance.png"],
			&"guard_entry": ["res://assets/sprites/lickshot/guard_stance.png"],
			&"guard_recovery": ["res://assets/sprites/lickshot/guard_stance.png"],
			# The approved 2026-11-18 gun-finger lean stays on `skank`; the 8-pose sheet below
			# is the full T groove, one drawing per taunt slot.
			&"skank": ["res://assets/sprites/lickshot/skank_point.png"],
			&"skank_1": ["res://assets/sprites/lickshot/skank_1.png"],
			&"skank_2": ["res://assets/sprites/lickshot/skank_2.png"],
			&"skank_3": ["res://assets/sprites/lickshot/skank_3.png"],
			&"skank_4": ["res://assets/sprites/lickshot/skank_4.png"],
			&"skank_5": ["res://assets/sprites/lickshot/skank_5.png"],
			&"skank_6": ["res://assets/sprites/lickshot/skank_6.png"],
			&"skank_7": ["res://assets/sprites/lickshot/skank_7.png"],
			&"skank_8": ["res://assets/sprites/lickshot/skank_8.png"],
			&"jab": ["res://assets/sprites/lickshot/jab.png"],
			&"upper_box": ["res://assets/sprites/lickshot/upper_box.png"],
			# Reactions from the 12-pose sheet: top row = standing recoil, middle row = airborne
			# launch/tumble, bottom row = grounded knockdown and prone KO. The single C-recoil
			# upload opens `launched`.
			&"hitstun": [
				"res://assets/sprites/lickshot/hitstun_01.png",
				"res://assets/sprites/lickshot/hitstun_02.png",
				"res://assets/sprites/lickshot/hitstun_03.png",
				"res://assets/sprites/lickshot/hitstun_04.png",
			],
			&"launched": [
				"res://assets/sprites/lickshot/launched_01.png",
				"res://assets/sprites/lickshot/launched_02.png",
				"res://assets/sprites/lickshot/launched_03.png",
			],
			&"tumble": [
				"res://assets/sprites/lickshot/tumble_01.png",
				"res://assets/sprites/lickshot/tumble_02.png",
			],
			&"knockdown": [
				"res://assets/sprites/lickshot/knockdown_01.png",
				"res://assets/sprites/lickshot/knockdown_02.png",
			],
			&"ko": [
				"res://assets/sprites/lickshot/ko_01.png",
				"res://assets/sprites/lickshot/ko_02.png",
			],
			# K = BOX is the Sonic Clap: arms spread wide, then the oversized hands meet with a
			# golden shockwave. L = TUMP is the extended high left kick.
			&"high_kick": ["res://assets/sprites/lickshot/high_kick.png"],
			&"sonic_clap_windup": ["res://assets/sprites/lickshot/sonic_clap_windup.png"],
			&"sonic_clap_impact": ["res://assets/sprites/lickshot/sonic_clap_impact.png"],
			# Collar grab (U) and the round-win / Hype Surge celebration share the wide-open
			# arms pose with the mic in the cargo pocket.
			&"celebration": ["res://assets/sprites/lickshot/celebration.png"],
		},
		"anim_offset": {
			# offset = frame centre − (stance centre x, sole row), with the sole lifted to y 592:
			# y = H/2 − sole_row − 8 / (anim_scale × FIGHTER_ART_SCALE).
			# States still drawn by the mic stance keep the idle placement.
			"idle": Vector2(7.5, -281.9),
			"jump": Vector2(7.5, -281.9),
			"crouch": Vector2(7.5, -281.9),
			# 2026-11-19 batch (§9 item 38): every frame's canvas is symmetric around its
			# stance centre (so x = 0) and its lowest alpha row is the sole row, measured by
			# `prep_lickshot_poses.py --batch 2026-11-19` for the y 592 rule.
			"walk": Vector2(0.0, -281.77),
			"skank_1": Vector2(0.0, -198.52),
			"skank_2": Vector2(0.0, -196.52),
			"skank_3": Vector2(0.0, -189.02),
			"skank_4": Vector2(0.0, -196.52),
			"skank_5": Vector2(0.0, -192.52),
			"skank_6": Vector2(0.0, -192.52),
			"skank_7": Vector2(0.0, -192.52),
			"skank_8": Vector2(0.0, -195.52),
			"knockdown": Vector2(0.0, -101.46),
			"ko": Vector2(0.0, -59.46),
			"tumble": Vector2(0.0, -134.46),
			"high_kick": Vector2(127.5, -282.0),
			"sonic_clap_windup": Vector2(-28.5, -281.0),
			"sonic_clap_impact": Vector2(141.0, -167.5),
			# 2026-11-18 set: same floor rule, measured per frame by the prep script.
			"jab": Vector2(-34.5, -282.0),
			"upper_box": Vector2(-30.0, -282.0),
			"block": Vector2(-47.5, -282.0),
			"guard_entry": Vector2(-47.5, -282.0),
			"guard_recovery": Vector2(-47.5, -282.0),
			"hitstun": Vector2(0.0, -223.96),
			"launched": Vector2(0.0, -190.46),
			"skank": Vector2(-16.5, -282.0),
			"celebration": Vector2(-1.0, -282.1),
		},
		"anim_scale": {
			# 121.75 px crown-to-sole / that frame's measured height (the 1.24 art scale is
			# applied once, by BaseFighter, so every fighter grows together).
			"idle": 0.24014,
			"jump": 0.24014, "crouch": 0.24014,
			"walk": 0.241,
			"skank_1": 0.33914, "skank_2": 0.33914, "skank_3": 0.33914,
			"skank_4": 0.33914, "skank_5": 0.33914, "skank_6": 0.33914,
			"skank_7": 0.33914, "skank_8": 0.33914,
			"knockdown": 0.30062, "ko": 0.30062, "tumble": 0.30062,
			"high_kick": 0.23873,
			"sonic_clap_windup": 0.23919,
			"sonic_clap_impact": 0.43021,   # the shockwave sits above the cap in this frame
			"jab": 0.23873, "upper_box": 0.23873,
			"block": 0.23873, "guard_entry": 0.23873, "guard_recovery": 0.23873,
			"hitstun": 0.30062, "launched": 0.30062, "celebration": 0.23826,
			"skank": 0.23873,
		},
		"anim_source_max": {
			"idle": 512.0, "walk": 512.0, "jump": 512.0, "crouch": 512.0,
			"knockdown": 334.0, "ko": 356.0, "tumble": 390.0,
			"high_kick": 512.0, "sonic_clap_windup": 512.0, "sonic_clap_impact": 512.0,
			"jab": 512.0, "upper_box": 512.0,
			"block": 512.0, "guard_entry": 512.0, "guard_recovery": 512.0,
			"hitstun": 480.0, "launched": 358.0, "skank": 512.0, "celebration": 512.0,
			"skank_1": 361.0, "skank_2": 357.0, "skank_3": 372.0, "skank_4": 357.0,
			"skank_5": 349.0, "skank_6": 349.0, "skank_7": 349.0, "skank_8": 355.0,
		},
		# Playback rate per animation, applied by build_frames. Walk is one cycle per two
		# beats at 132 BPM; the reaction loops are timed to their FSM window (hitstun 14-22
		# ticks, launched 18 ticks before the tumble switch). §9 item 38.
		"anim_fps": {
			"walk": 6.6,
			"hitstun": 12.0,
			"launched": 10.0,
			"tumble": 6.0,
			"knockdown": 4.0,
			"ko": 2.5,
		},
		# K = BOX plays windup → impact; L = TUMP plays the high kick. The kick's contact box
		# moves up to head height, because the art is an extended high kick and not the
		# Sparta stomach push the shared box was authored for.
		"attack_anims": {
			&"strong": {
				"anim_startup": &"sonic_clap_windup",
				"anim_active": &"sonic_clap_impact",
				"anim_recovery": &"sonic_clap_impact",
			},
			&"tump": {
				"anim_startup": &"high_kick",
				"anim_active": &"high_kick",
				"anim_recovery": &"high_kick",
				"hitbox_pos": Vector2(96, -128),
				"hitbox_size": Vector2(112, 56),
			},
			# I = upper box now plays the drawn heavy mic cross instead of the idle stance.
			&"upper_box": {
				"anim_startup": &"upper_box",
				"anim_active": &"upper_box",
				"anim_recovery": &"upper_box",
			},
		},
		# U = collar grab and the round-win / Hype Surge pose share the wide-open arms art.
		"state_anims": {"grab": &"celebration"},
		# T plays the full 8-pose lean-back groove, one drawing per taunt slot; TAUNT_TICKS is
		# unchanged, so the commitment and its hype timing are exactly as approved.
		"taunt_sequence": [&"skank_1", &"skank_2", &"skank_3", &"skank_4",
			&"skank_5", &"skank_6", &"skank_7", &"skank_8"],
		"celebrate_anim": &"celebration",
		# Every attack now ships its own drawn pose, so none of them also gets the generic
		# strike smear: the jab's placeholder smear is retired.
		"no_strike_tell": [&"strong", &"tump", &"jab", &"upper_box"],
	},
	# Fighter #3 — Likkle Moore, the ten-year-old school-uniform prodigy (formerly Young Selecta;
	# renamed 2026-11-19, AGENTS.md §9 item 35). The key stays `young_selecta` and the art folder
	# stays `assets/sprites/young-selecta/`, so no texture UID or path changes. The on-screen name
	# is styled by `styled_name()`, which renders L!KKLE MOORE. Faster on his feet and the
	# boom-mic thrust reaches 25 px further than an adult's jab (owner direction).
	&"young_selecta": {
		"name": "LIKKLE MOORE",
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


## Owner styling rule (AGENTS.md §9 item 32): any fighter whose name contains the letter I
## renders with "!" instead of "I" on screen. Applied at display time only, so roster keys,
## asset folders and code ids keep their clean ASCII spelling (`lickshot`, not `l!ckshot`).
static func styled_name(raw: String) -> String:
	return raw.replace("I", "!")


static func display_name(key: StringName) -> String:
	return styled_name(String(profile(key)["name"]))


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
	var speeds: Dictionary = data.get("anim_fps", {})
	for anim in table:
		var paths: Array = table[anim]
		if paths.is_empty():
			continue
		frames.add_animation(anim)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, float(speeds.get(anim, 1.0)))
		for path in paths:
			var tex := load(String(path)) as Texture2D
			if tex == null:
				push_warning("FighterRoster: missing texture %s" % path)
				continue
			frames.add_frame(anim, tex)
	return frames

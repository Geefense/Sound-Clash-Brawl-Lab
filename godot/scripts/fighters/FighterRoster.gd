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
		# 3rd Strike-inspired uneven walk timing (AGENTS.md §9 item 40). Durations are
		# RELATIVE: seconds = duration / (fps × playing speed), so the scene's 4.4 fps walk
		# tempo is unchanged. Frames 1/3 are 01_contact_a / 03_contact_b — the grounded
		# plant / skank dip — and hold at 1.3×; frames 2/4 are the pass/transfer and snap
		# through at 0.75×. No art, walk speed or hitbox changes.
		"anim_frame_duration": {
			&"walk": [1.3, 0.75, 1.3, 0.75],
		},
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
			# item 34) covers guard, jab, upper box and celebration, and the 2026-11-19 batch
			# (item 38) replaces the single taunt / hit / launch / knockdown poses and the
			# recycled idle walk with drawn sequences. The walk is the clean 2 x 2 sheet (full
			# crowns and Wallabee toes on white), re-sliced 2026-11-19; the clipped phone-video
			# frames it replaced stay archived as provenance only — see the batch PROVENANCE.md.
			&"idle": ["res://assets/sprites/lickshot/idle.png"],
			&"walk": [
				"res://assets/sprites/lickshot/walk/01.png",
				"res://assets/sprites/lickshot/walk/02.png",
				"res://assets/sprites/lickshot/walk/03.png",
				"res://assets/sprites/lickshot/walk/04.png",
			],
			&"jump": ["res://assets/sprites/lickshot/idle.png"],
			&"crouch": ["res://assets/sprites/lickshot/idle.png"],
			# One drawn guard pose covers entry, the held brace and the release.
			&"block": ["res://assets/sprites/lickshot/guard_stance.png"],
			&"guard_entry": ["res://assets/sprites/lickshot/guard_stance.png"],
			&"guard_recovery": ["res://assets/sprites/lickshot/guard_stance.png"],
			# T = the full 8-pose lean-back / skank groove, one pose per beat of the taunt.
			&"skank": [
				"res://assets/sprites/lickshot/skank/01.png",
				"res://assets/sprites/lickshot/skank/02.png",
				"res://assets/sprites/lickshot/skank/03.png",
				"res://assets/sprites/lickshot/skank/04.png",
				"res://assets/sprites/lickshot/skank/05.png",
				"res://assets/sprites/lickshot/skank/06.png",
				"res://assets/sprites/lickshot/skank/07.png",
				"res://assets/sprites/lickshot/skank/08.png",
			],
			&"jab": ["res://assets/sprites/lickshot/jab.png"],
			&"upper_box": ["res://assets/sprites/lickshot/upper_box.png"],
			# Standing recoil snap (top row of the 3 x 4 sheet).
			&"hitstun": [
				"res://assets/sprites/lickshot/hitstun/01.png",
				"res://assets/sprites/lickshot/hitstun/02.png",
				"res://assets/sprites/lickshot/hitstun/03.png",
			],
			# C-recoil launch, then the sheet's airborne poses.
			&"launched": [
				"res://assets/sprites/lickshot/airborne/01.png",
				"res://assets/sprites/lickshot/airborne/02.png",
				"res://assets/sprites/lickshot/airborne/03.png",
			],
			&"tumble": [
				"res://assets/sprites/lickshot/airborne/03.png",
				"res://assets/sprites/lickshot/airborne/04.png",
				"res://assets/sprites/lickshot/airborne/05.png",
				"res://assets/sprites/lickshot/airborne/06.png",
			],
			# Bottom row of the sheet: seated into sprawled, then the face-down frames.
			&"knockdown": [
				"res://assets/sprites/lickshot/ground/01.png",
				"res://assets/sprites/lickshot/ground/02.png",
			],
			&"ko": [
				"res://assets/sprites/lickshot/ground/03.png",
				"res://assets/sprites/lickshot/ground/04.png",
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
			# Clean 4-pose walk sheet: one shared 454 x 512 canvas, every sole on row 510, so the
			# group formula holds the whole stride on 592 with 0 px vertical bob (no per-frame
			# correction needed, unlike the clipped video frames this replaced).
			"walk": Vector2(-5.2, -281.0),
			"jump": Vector2(7.5, -281.9),
			"crouch": Vector2(7.5, -281.9),
			"high_kick": Vector2(127.5, -282.0),
			"sonic_clap_windup": Vector2(-28.5, -281.0),
			"sonic_clap_impact": Vector2(141.0, -167.5),
			# 2026-11-18 set: same floor rule, measured per frame by the prep script.
			"jab": Vector2(-34.5, -282.0),
			"upper_box": Vector2(-30.0, -282.0),
			"block": Vector2(-47.5, -282.0),
			"guard_entry": Vector2(-47.5, -282.0),
			"guard_recovery": Vector2(-47.5, -282.0),
			"celebration": Vector2(-1.0, -282.1),
			# 2026-11-19 sequences (AGENTS.md §9 item 38). Each group is composed onto one
			# shared canvas, so every frame of an animation has the same sole row and stance
			# centre and these single offsets hold the y 592 sand line for the whole sequence.
			"skank": Vector2(-11.0, -196.4),
			"hitstun": Vector2(-37.5, -221.9),
			"launched": Vector2(-35.5, -165.9),
			"tumble": Vector2(-35.5, -165.9),
			"knockdown": Vector2(10.5, -99.4),
			"ko": Vector2(10.5, -99.4),
		},
		"anim_scale": {
			# 121.75 px crown-to-sole / that frame's measured height (the 1.24 art scale is
			# applied once, by BaseFighter, so every fighter grows together).
			"idle": 0.24014,
			# Walk is calibrated on the tallest upright frame (510 px crown-to-sole), not the
			# median of the leaning pass poses: the median made the stride render ~4% taller
			# than idle. 121.75 / 510 = 0.23873, so the standing stride matches idle's 507 px.
			"walk": 0.23873, "jump": 0.24014, "crouch": 0.24014,
			"high_kick": 0.23873,
			"sonic_clap_windup": 0.23919,
			"sonic_clap_impact": 0.43021,   # the shockwave sits above the cap in this frame
			"jab": 0.23873, "upper_box": 0.23873,
			"block": 0.23873, "guard_entry": 0.23873, "guard_recovery": 0.23873,
			"celebration": 0.23826,
			# 2026-11-19: 121.75 px target / the group's standing crown-to-sole. The skank
			# sheet is drawn at a larger art scale than the 3 x 4 sheet, so its factor differs;
			# the C-recoil inside `launched` is rescaled onto the sheet by its mic grille.
			"skank": 0.34104,
			"hitstun": 0.30211, "launched": 0.30211, "tumble": 0.30211,
			"knockdown": 0.30211, "ko": 0.30211,
		},
		# Playback rates for the drawn sequences. One pose per beat on the taunt (8 poses over
		# the 68-tick taunt) and a short snap for the reactions. Single-frame poses keep the
		# default 1 fps, so nothing that was already wired changes speed.
		"anim_fps": {
			"walk": 9.0, "skank": 7.0, "hitstun": 12.0,
			"launched": 10.0, "tumble": 10.0,
			"knockdown": 8.0, "ko": 5.0,
		},
		# The knockdown and KO settle on their last drawn frame instead of snapping back.
		"anim_loop": {
			"walk": true, "skank": true, "hitstun": false, "launched": false,
			"tumble": true, "knockdown": false, "ko": false,
		},
		# Coiled Veteran Strut (AGENTS.md §9 item 40): relative durations on the 9 fps walk.
		# 01/03 are the foot-plant stride frames and snap at 0.8×; 02/04 are the passing /
		# coil frames and hold at 1.4×, so he lingers in the selector dip before each plant.
		"anim_frame_duration": {
			&"walk": [0.8, 1.4, 0.8, 1.4],
		},
		"anim_source_max": {
			"idle": 512.0, "walk": 512.0, "jump": 512.0, "crouch": 512.0,
			"high_kick": 512.0, "sonic_clap_windup": 512.0, "sonic_clap_impact": 512.0,
			"jab": 512.0, "upper_box": 512.0,
			"block": 512.0, "guard_entry": 512.0, "guard_recovery": 512.0,
			"celebration": 512.0,
			# 2026-11-19 sequences: the shared canvas' longest side, so the import-cap ratio
			# stays 1.0 and no scale is applied twice.
			"skank": 365.0,
			"hitstun": 411.0, "launched": 401.0, "tumble": 401.0,
			"knockdown": 339.0, "ko": 339.0,
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
		"taunt_sequence": [&"skank"],
		"celebrate_anim": &"celebration",
		# Every attack now ships its own drawn pose, so none of them also gets the generic
		# strike smear: the jab's placeholder smear is retired.
		"no_strike_tell": [&"strong", &"tump", &"jab", &"upper_box"],
		# Signature moveset (2026-11-22). Frame data, damage, knockback and hitboxes are
		# L!ckshot's own; K launches a travelling sub-bass dubplate, L is an advancing knee.
		"moves": {
			&"jab": {
				"startup": 3, "active": 3, "recovery": 7,
				"damage": 7, "blocked_damage": 2,
				"hitstun": 12, "knockback": Vector2(150, 0), "knockdown": false,
				"hitbox_pos": Vector2(88, -112), "hitbox_size": Vector2(96, 34),
			},
			&"upper_box": {
				"startup": 14, "active": 4, "recovery": 20,
				"damage": 18, "blocked_damage": 5,
				"hitstun": 26, "knockback": Vector2(380, -50), "knockdown": false,
				"hitbox_pos": Vector2(100, -118), "hitbox_size": Vector2(124, 58),
			},
			# K = Sub-Bass Dubplate Wave: the close clap still carries a small hitbox, then
			# the wave travels across the sand and controls the mid-range.
			&"strong": {
				"startup": 11, "active": 3, "recovery": 22,
				"damage": 10, "blocked_damage": 3,
				"hitstun": 14, "knockback": Vector2(100, -30), "knockdown": false,
				"hitbox_pos": Vector2(80, -118), "hitbox_size": Vector2(92, 72),
				"projectile": {
					"kind": &"dubplate", "speed": 560.0, "life": 1.35,
					"attack_id": &"strong", "damage": 16, "blocked_damage": 4,
					"hitstun": 24, "knockback": Vector2(300, -90), "knockdown": false,
					"hitbox_size": Vector2(78, 110),
				},
			},
			# L = Jumping Sound-Clash Knee: advances through the active window.
			&"tump": {
				"startup": 10, "active": 3, "recovery": 16,
				"damage": 14, "blocked_damage": 4,
				"hitstun": 20, "knockback": Vector2(240, -80), "knockdown": false,
				"hitbox_pos": Vector2(86, -96), "hitbox_size": Vector2(96, 84),
				"advance": 900.0,       # carries him roughly 190 px through the active + recovery
			},
		},
		"throw": {
			"hold": 14, "recovery": 16,
			"forward_damage": 16, "back_damage": 12,
			"forward_launch": Vector2(540, -440), "back_launch": Vector2(160, -260),
		},
		"taunt_hype": 12,
		"taunt_callout": true,
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
		# Compact-prodigy moveset (2026-11-22): long poke, wide home-run swing, thrown
		# dictionary and a low sweeping trip that ducks high jabs. The +25 px reach is
		# already folded into the jab width (109) that the existing reach check expects.
		"moves": {
			&"jab": {
				"startup": 3, "active": 3, "recovery": 6,
				"damage": 7, "blocked_damage": 2,
				"hitstun": 12, "knockback": Vector2(140, 0), "knockdown": false,
				"hitbox_pos": Vector2(98, -96), "hitbox_size": Vector2(109, 32),
			},
			# I = mic-stand home-run swing: the widest box of the three fighters.
			&"upper_box": {
				"startup": 13, "active": 5, "recovery": 20,
				"damage": 18, "blocked_damage": 5,
				"hitstun": 26, "knockback": Vector2(340, -40), "knockdown": false,
				"hitbox_pos": Vector2(94, -108), "hitbox_size": Vector2(150, 78),
			},
			# K = dictionary / backpack hurl. It travels only a short way, but the stun is
			# the longest in the roster and the guard chip is high.
			&"strong": {
				"startup": 12, "active": 3, "recovery": 20,
				"damage": 12, "blocked_damage": 3,
				"hitstun": 18, "knockback": Vector2(160, -40), "knockdown": false,
				"hitbox_pos": Vector2(74, -112), "hitbox_size": Vector2(84, 60),
				"projectile": {
					"kind": &"dictionary", "speed": 470.0, "life": 0.52,
					"attack_id": &"strong", "damage": 17, "blocked_damage": 5,
					"hitstun": 30, "knockback": Vector2(200, -70), "knockdown": false,
					"hitbox_size": Vector2(66, 90),
				},
			},
			# L = low spinning sweep: crouched hurtbox, advancing, and it trips.
			&"tump": {
				"startup": 10, "active": 3, "recovery": 14,
				"damage": 11, "blocked_damage": 3,
				"hitstun": 20, "knockback": Vector2(180, -10), "knockdown": true,
				"hitbox_pos": Vector2(78, -30), "hitbox_size": Vector2(124, 38),
				"low_profile": true, "advance": 500.0,
			},
		},
		"throw": {
			"hold": 9, "recovery": 8,
			"forward_damage": 10, "back_damage": 9,
			"forward_launch": Vector2(430, -360), "back_launch": Vector2(140, -240),
		},
		"taunt_hype": 10,
		"taunt_callout": true,
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
## Apply a fighter's relative per-frame durations to an existing SpriteFrames resource.
## Godot treats these as multipliers of the animation's fps (absolute = duration / fps),
## so the base walk rates stay exactly what each hero was tuned at. Missing animations and
## short tables are skipped, and fighters without the table keep the default 1.0 timing.
static func apply_frame_durations(frames: SpriteFrames, key: StringName) -> void:
	if frames == null:
		return
	var table: Dictionary = profile(key).get("anim_frame_duration", {})
	for anim in table:
		if not frames.has_animation(anim):
			continue
		var durations: Array = table[anim]
		var frame_count := frames.get_frame_count(anim)
		var count := mini(durations.size(), frame_count)
		if count == 0:
			continue
		if frames.has_method("set_frame_duration"):
			for i in count:
				frames.set_frame_duration(anim, i, float(durations[i]))
			continue
		# Godot 4.5 has no per-frame duration setter (it was added in a later release).
		# Rebuild the animation from its own textures and pass each relative duration to
		# add_frame(); speed and loop mode are properties of the animation and survive.
		var textures: Array[Texture2D] = []
		for i in frame_count:
			textures.append(frames.get_frame_texture(anim, i))
		for i in frame_count:
			frames.remove_frame(anim, 0)
		for i in textures.size():
			var duration := float(durations[i]) if i < durations.size() else 1.0
			frames.add_frame(anim, textures[i], duration)


static func build_frames(key: StringName) -> SpriteFrames:
	var data := profile(key)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var table: Dictionary = data["frames"]
	# Optional playback: a drawn sequence needs a real frame rate, and a knockdown or KO
	# should hold its last pose. A fighter with no tables keeps 1 fps / loop, exactly as
	# every single-frame pose already behaved.
	var fps_table: Dictionary = data.get("anim_fps", {})
	var loop_table: Dictionary = data.get("anim_loop", {})
	for anim in table:
		var paths: Array = table[anim]
		if paths.is_empty():
			continue
		frames.add_animation(anim)
		frames.set_animation_loop(anim, bool(loop_table.get(anim, true)))
		frames.set_animation_speed(anim, float(fps_table.get(anim, 1.0)))
		for path in paths:
			var tex := load(String(path)) as Texture2D
			if tex == null:
				push_warning("FighterRoster: missing texture %s" % path)
				continue
			frames.add_frame(anim, tex)
	return frames

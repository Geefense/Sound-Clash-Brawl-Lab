class_name YardBarrier
extends Node2D
## Low wooden / zinc yard barrier that closes the crowd line (AGENTS.md §9 item 21).
##
## Drawn with primitives only — no texture, no new export weight. Presentation only: it
## never touches the simulation, a hitbox or either fighter's FSM.
##
## The 15 Dancehall crowd sprites stand at y 556 (front) and y 516 (back). Their art is
## cut off at the soles, which reads as "floating" when nothing hides the cut. This band
## spans y 524–558, i.e. the crowd's shins down to the sand, so the line stands *behind*
## something instead of being pinned onto the floor. Fighters stand on y = 600 and draw in
## front of it (z 0 against z −4 here).
##
## Palette is pulled from the sand stage: weathered plank brown, a zinc cap, and the same
## warm sand shadow the raft of the stage art uses, so the barrier reads as yard furniture
## rather than a game-object outline.

const LEFT := -6.0
const RIGHT := 1286.0
const TOP_Y := 524.0
const BASE_Y := 558.0
const RAIL_H := 10.0
const PLANK_W := 45.5
const POST_EVERY := 6

## Kept deliberately dark and low-saturation: the barrier is an occluder, not a subject.
## The first on-screen check showed the earlier mid-brown plank tones reading as a bright
## straw-yellow band that pulled the eye off the fighters at default zoom, so every value
## here sits roughly 30 % lower and the zinc rail lost its bright highlight.
@export var wood_dark: Color = Color(0.19, 0.12, 0.08, 1.0)
@export var wood_mid: Color = Color(0.25, 0.16, 0.10, 1.0)
@export var wood_light: Color = Color(0.30, 0.20, 0.13, 1.0)
@export var post_colour: Color = Color(0.14, 0.09, 0.06, 1.0)
@export var rail_colour: Color = Color(0.36, 0.39, 0.39, 1.0)
@export var rail_hi: Color = Color(0.52, 0.55, 0.54, 1.0)
@export var nail_colour: Color = Color(0.17, 0.12, 0.09, 1.0)
@export var sand_shadow: Color = Color(0.20, 0.11, 0.06, 0.30)
## The tall corner post beside the right-hand stack is gone (owner playtest, 2026-11-17):
## its only job was to give the leaning spectator something to lean on, and that spectator is
## now retired from the line. A lone post read as clutter, so the rail is continuous again.


func _ready() -> void:
	z_index = -4                     # over the crowd rows (−5 / −6), under fighters (0)
	queue_redraw()


func _draw() -> void:
	var width := RIGHT - LEFT
	# Soft contact shadow pooling on the sand at the foot of the barrier.
	draw_rect(Rect2(LEFT, BASE_Y - 4.0, width, 9.0), sand_shadow)
	draw_rect(Rect2(LEFT, BASE_Y - 1.0, width, 3.0), Color(0.15, 0.08, 0.04, 0.45))

	# Planks: a hair of height and tone variation so the band is not a flat box.
	var plank_top := TOP_Y + RAIL_H
	var i := 0
	var x := LEFT
	while x < RIGHT:
		var wobble := float(i % 3) * 1.4
		var tone := wood_mid
		if i % 5 == 0:
			tone = wood_light
		elif i % 4 == 0:
			tone = wood_dark
		draw_rect(Rect2(x + 1.0, plank_top - wobble, PLANK_W - 2.0,
			BASE_Y - plank_top + wobble), tone)
		# Grain: one thin darker line down each plank, offset so the seams never line up.
		draw_line(Vector2(x + 12.0 + float(i % 4) * 5.0, plank_top + 2.0),
			Vector2(x + 14.0 + float(i % 4) * 5.0, BASE_Y - 2.0),
			Color(0.22, 0.14, 0.09, 0.55), 1.0)
		# Nails at the top of every plank.
		draw_circle(Vector2(x + PLANK_W * 0.5, plank_top + 4.0), 1.4, nail_colour)
		x += PLANK_W
		i += 1

	# Posts every few planks, with a slightly proud cap.
	var posts := int(ceil(width / (PLANK_W * POST_EVERY)))
	for p in posts + 1:
		var px := LEFT + float(p) * PLANK_W * POST_EVERY
		draw_rect(Rect2(px - 3.5, TOP_Y + 2.0, 7.0, BASE_Y - TOP_Y - 2.0), post_colour)
		draw_rect(Rect2(px - 5.0, TOP_Y + 1.0, 10.0, 4.0), wood_dark)

	# Zinc cap rail: one flat band, a darker underside and a bright top edge.
	draw_rect(Rect2(LEFT, TOP_Y, width, RAIL_H), rail_colour)
	draw_rect(Rect2(LEFT, TOP_Y + RAIL_H - 3.0, width, 3.0), Color(0.22, 0.24, 0.24, 1.0))
	draw_line(Vector2(LEFT, TOP_Y + 1.0), Vector2(RIGHT, TOP_Y + 1.0), rail_hi, 1.2)
	# Contact darkening where the rail meets the planks, so the cap does not read as a
	# bright horizontal stripe across the frame.
	draw_rect(Rect2(LEFT, TOP_Y + RAIL_H, width, 2.0), Color(0.10, 0.07, 0.05, 0.55))
	# Corrugation marks, cheap and even.
	var cx := LEFT
	while cx < RIGHT:
		draw_line(Vector2(cx, TOP_Y + 2.0), Vector2(cx, TOP_Y + RAIL_H - 3.0),
			Color(0.28, 0.30, 0.30, 0.45), 1.0)
		cx += 17.0

extends Node
## Match setup carried from the title screen into the arena (AGENTS.md §9 backlog item B1).
##
## The three choices live here, in one autoload, so the arena reads them instead of
## hard-coding P2 as the Workshop Dummy. Esc in the arena comes back here with the
## selection intact.

const TITLE_SCENE := "res://scenes/TitleScreen.tscn"
const ARENA_SCENE := "res://scenes/TestArena.tscn"

## Fighter keys are FighterRoster keys.
## Owner decision (2026-11-17, AGENTS.md §9 item 24; reaffirmed 2026-11-21 as the 3D showcase):
## the default matchup is **FEEDBACK vs FEEDBACK** on the rigged 25-bone model, so the mirror
## match demonstrates the cel shading, mirror accent and full animation on both sides.
## L!CKSHOT and Likkle Moore stay selectable.
const DEFAULT_P1: StringName = &"feedback"
const DEFAULT_P2: StringName = &"feedback"
var p1_fighter: StringName = DEFAULT_P1
var p2_fighter: StringName = DEFAULT_P2
## SparringController.Mode index: 0 Dummy, 1 Counter-Puncher, 2 Riddim Rusher, 3 Baiter.
var ai_mode: int = 1
var subtitles: bool = true
## Set by Esc in the arena: the title screen then skips the splash and reopens setup.
var return_to_setup: bool = false


func fighter_count() -> int:
	return FighterRoster.ORDER.size()


func fighter_at(index: int) -> StringName:
	var count := fighter_count()
	return FighterRoster.ORDER[posmod(index, count)]


func fighter_index(key: StringName) -> int:
	return FighterRoster.ORDER.find(key)


## dir = +1 / -1. Wraps, so holding right cycles the whole roster.
func cycle_p1(dir: int = 1) -> void:
	p1_fighter = fighter_at(fighter_index(p1_fighter) + dir)


func cycle_p2(dir: int = 1) -> void:
	p2_fighter = fighter_at(fighter_index(p2_fighter) + dir)


func cycle_ai(dir: int = 1) -> void:
	ai_mode = posmod(ai_mode + dir, SparringController.MODE_NAMES.size())


func toggle_subtitles() -> void:
	subtitles = not subtitles


func ai_mode_name() -> String:
	return String(SparringController.MODE_NAMES[ai_mode])


func ai_mode_tag() -> String:
	return String(SparringController.MODE_TAGS[ai_mode])


func start_match() -> void:
	return_to_setup = false
	get_tree().change_scene_to_file(ARENA_SCENE)


## Esc from the arena: Character Select, same fighters, no splash screen.
func escape_to_setup() -> void:
	return_to_setup = true
	get_tree().change_scene_to_file(TITLE_SCENE)


func open_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)

extends Node
## Match setup carried from the title screen into the arena (AGENTS.md §9 backlog item B1).
##
## The three choices live here, in one autoload, so the arena reads them instead of
## hard-coding P2 as the Workshop Dummy. Esc in the arena comes back here with the
## selection intact.

const TITLE_SCENE := "res://scenes/TitleScreen.tscn"
const ARENA_SCENE := "res://scenes/TestArena.tscn"

## Fighter keys are FighterRoster keys.
## Playtest fix 2026-11-24: the cursor defaults are now **Feedback for P1 and L!ckshot for
## P2**, so Character Select never opens on a Feedback-vs-Feedback mirror by accident (the
## old shared "selected" flag defaulted both panels to the same fighter). A mirror is still
## allowed, but only when a player actually picks it.
const DEFAULT_P1: StringName = &"feedback"
const DEFAULT_P2: StringName = &"lickshot"
## The committed match payload. `commit_match()` is the only writer, called once by Character
## Select when both panels are locked; the arena reads `p1_fighter_id` / `p2_fighter_id`.
var p1_fighter_id: StringName = DEFAULT_P1
var p2_fighter_id: StringName = DEFAULT_P2
## The same two picks, kept under the names the rest of the project already uses.
var p1_fighter: StringName = DEFAULT_P1
var p2_fighter: StringName = DEFAULT_P2
## SparringController.Mode index: 0 Dummy, 1 Counter-Puncher, 2 Riddim Rusher, 3 Baiter.
var ai_mode: int = 1
## PART B commit 6: which `AIProfile` preset the CPU wears. `normal` is the default and the
## shipped difficulty; `easy` and `hard` are the other two loaded by `AIProfile.preset()`.
var ai_preset: StringName = &"normal"
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


## Lock in both picks and hand them to the arena. Called only from Character Select.
func commit_match(p1: StringName, p2: StringName) -> void:
	p1_fighter_id = p1
	p2_fighter_id = p2
	p1_fighter = p1
	p2_fighter = p2


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
	print("[match] P1 = %s   P2 = %s" % [p1_fighter_id, p2_fighter_id])
	get_tree().change_scene_to_file(ARENA_SCENE)


## Esc from the arena: Character Select, same fighters, no splash screen.
func escape_to_setup() -> void:
	return_to_setup = true
	get_tree().change_scene_to_file(TITLE_SCENE)


func open_title() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)

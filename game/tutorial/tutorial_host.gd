## Everything a tutorial lesson may ask of the game. Lessons talk only to this class; GameRoot supplies the real
## implementation (GameTutorialHost). Methods marked "coroutine" must be awaited.
class_name TutorialHost
extends RefCounted

## Never emitted: the coroutine defaults wait on it, so a missing implementation parks the lesson (and reports an error).
signal _unimplemented

## Targets for point_at; any other id is `slot_<item id>` (a consumable slot of the side column).
const TARGET_ATTACK := &"attack"
const TARGET_BLOCK := &"block"
const TARGET_SHOP := &"shop"
const TARGET_NONE := &""

## Option keys of start_fight.
const OPT_ALLOWED := "allowed"
const OPT_HOLD := "hold"
const OPT_HP := "hp"
## true: the enemy can really die from the player's hits (default false: only win_fight ends the fight).
const OPT_MORTAL := "mortal"

## Coroutine. Walks the road to a new encounter against data/enemies/<enemy_id>.tres, lets the enemy step in and
## returns the running Duel. opts: "allowed" Array[StringName] of Duel.ACTION_* (default: all), "hold" bool (the
## enemy waits and never attacks, default false), "hp" int (player hp, default full).
func start_fight(_enemy_id: StringName, _opts := {}) -> Duel:
	push_error("TutorialHost.start_fight not implemented")
	await _unimplemented
	return null

## Coroutine. Defeats the enemy of the running fight (victory banner included) and returns when the road is free.
func win_fight() -> void:
	push_error("TutorialHost.win_fight not implemented")
	await _unimplemented

## Shows the hint bubble with tr(text_key); when `<text_key>_<SCHEME>` exists (e.g. TUT_CUE_ATTACK_BUTTONS) that variant wins,
## so a lesson reads right for the player's input scheme.
func say(_text_key: String) -> void:
	push_error("TutorialHost.say not implemented")

## Hides the hint bubble and the highlight.
func hush() -> void:
	push_error("TutorialHost.hush not implemented")

## "Great!" pop in the middle of the screen.
func praise() -> void:
	push_error("TutorialHost.praise not implemented")

## Pulsing highlight on a control: TARGET_* or `slot_<item id>`; TARGET_NONE clears it.
func point_at(_target: StringName) -> void:
	push_error("TutorialHost.point_at not implemented")

## Puts consumable charges into the bag.
func give_item(_item_id: StringName, _count := 1) -> void:
	push_error("TutorialHost.give_item not implemented")

## Sets the player's hp (clamped to 1..max) and updates the bar.
func set_hp(_hp: int) -> void:
	push_error("TutorialHost.set_hp not implemented")

## Coroutine. Waits `seconds` of game time (a tween, not a SceneTree timer).
func pause(_seconds: float) -> void:
	push_error("TutorialHost.pause not implemented")
	await _unimplemented

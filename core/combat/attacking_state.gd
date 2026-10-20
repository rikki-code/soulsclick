## Attack lock for the player, windup for the enemy. With on_done the owner decides what follows.
class_name AttackingState
extends FighterState

const ID := &"attacking"

var _duration: float
var _on_done: Callable

func _init(p_duration: float, p_on_done: Callable = Callable()) -> void:
	_duration = p_duration
	_on_done = p_on_done

func id() -> StringName:
	return ID

func duration() -> float:
	return _duration

func on_finished(duel: Duel, fighter: Fighter) -> void:
	if _on_done.is_valid():
		_on_done.call()
		return
	super.on_finished(duel, fighter)

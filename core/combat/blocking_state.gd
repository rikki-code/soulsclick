## Guard up for block_duration. Strikes landing in the first parry_window seconds are parried.
class_name BlockingState
extends FighterState

const ID := &"blocking"

var _duration: float

func _init(p_duration: float) -> void:
	_duration = p_duration

func id() -> StringName:
	return ID

func duration() -> float:
	return _duration

func on_finished(duel: Duel, fighter: Fighter) -> void:
	fighter.block_cooldown = duel.tuning.block_cooldown
	super.on_finished(duel, fighter)

func receive_strike(duel: Duel, fighter: Fighter, kind: AttackKind, result: StrikeResult) -> void:
	if fighter.state_elapsed <= duel.tuning.parry_window:
		kind.on_parried(duel, result)
		return
	kind.on_blocked(duel, result)

## A parry frees the defender at once so the punish window is not spent finishing the block.
func after_strike(duel: Duel, fighter: Fighter, result: StrikeResult) -> void:
	if result.outcome == StrikeResult.PARRIED:
		duel.enter_state(fighter, IdleState.new())

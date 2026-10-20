## A windup that never strikes; it reports the imitated kind so only timing knowledge gives it away.
class_name FeintAttack
extends AttackKind

const ID := &"feint"

func id() -> StringName:
	return ID

func telegraph_id() -> StringName:
	return step.imitates

func resolve(_duel: Duel, index: int) -> StrikeResult:
	var result := StrikeResult.new(id(), index, strike_count(), 0)
	result.outcome = StrikeResult.FEINT
	return result

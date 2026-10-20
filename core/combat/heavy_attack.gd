## A plain block does not hold: the strike goes through as a hit with reduced damage and drains stamina.
## Parry works as usual.
class_name HeavyAttack
extends AttackKind

const ID := &"heavy"

func id() -> StringName:
	return ID

func on_blocked(duel: Duel, result: StrikeResult) -> void:
	guard_break(duel, result)

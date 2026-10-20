## A plain block does not hold: the strike goes through as a hit with reduced damage and drains stamina.
## Parry works as usual.
class_name HeavyAttack
extends AttackKind

const ID := &"heavy"

func id() -> StringName:
	return ID

func on_blocked(duel: Duel, result: StrikeResult) -> void:
	result.outcome = StrikeResult.HIT
	result.damage = roundi(result.damage * duel.tuning.guard_break_damage_share)
	result.stamina_cost = duel.player.max_stamina
	result.guard_broken = true

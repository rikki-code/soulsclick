## Base of the enemy attack kinds. Defaults describe a single plain strike; a new kind overrides only the
## hooks that differ and is registered in AttackKindCatalog.
class_name AttackKind
extends RefCounted

var step: AttackStepDefinition

func _init(p_step: AttackStepDefinition) -> void:
	step = p_step

func id() -> StringName:
	return &""

## Kind id the view is told when the windup starts; a feint reports the kind it imitates.
func telegraph_id() -> StringName:
	return id()

func strike_count() -> int:
	return 1

func telegraph_time(_index: int) -> float:
	return step.telegraph_time

func strike_gap() -> float:
	return step.strike_gap

func strike_damage(duel: Duel, _index: int) -> int:
	return roundi(duel.enemy.damage * step.damage_scale)

func resolve(duel: Duel, index: int) -> StrikeResult:
	var result := StrikeResult.new(id(), index, strike_count(), strike_damage(duel, index))
	duel.player.state.receive_strike(duel, duel.player, self, result)
	return result

func on_hit(_duel: Duel, result: StrikeResult) -> void:
	result.outcome = StrikeResult.HIT

func on_blocked(duel: Duel, result: StrikeResult) -> void:
	result.outcome = StrikeResult.BLOCKED
	result.damage = roundi(result.damage * duel.tuning.chip_damage_share)
	result.stamina_cost = duel.tuning.block_stamina_cost

func on_parried(_duel: Duel, result: StrikeResult) -> void:
	result.outcome = StrikeResult.PARRIED
	result.damage = 0
	result.staggers_attacker = true

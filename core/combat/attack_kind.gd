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
	var stats := duel.player.stats
	var cost := result.damage * stats.value(CombatStats.BLOCK_COST)
	if duel.player.stamina - cost <= 0.0:
		guard_break(duel, result)
		return
	result.outcome = StrikeResult.BLOCKED
	result.damage = roundi(result.damage * stats.value(CombatStats.CHIP_SHARE))
	result.stamina_cost = cost

func on_parried(_duel: Duel, result: StrikeResult) -> void:
	result.outcome = StrikeResult.PARRIED
	result.damage = 0
	result.staggers_attacker = true

## The guard fails: the strike goes through with reduced damage and drains the stamina left.
## guard_break_resist pulls the result towards a plain block.
func guard_break(duel: Duel, result: StrikeResult) -> void:
	var stats := duel.player.stats
	var resist := clampf(stats.value(CombatStats.GUARD_BREAK_RESIST), 0.0, 1.0)
	var share := lerpf(stats.value(CombatStats.GUARD_BREAK_SHARE), stats.value(CombatStats.CHIP_SHARE), resist)
	var plain_cost := result.damage * stats.value(CombatStats.BLOCK_COST)
	result.outcome = StrikeResult.HIT
	result.damage = roundi(result.damage * share)
	result.stamina_cost = lerpf(duel.player.max_stamina, plain_cost, resist)
	result.guard_broken = resist < 1.0

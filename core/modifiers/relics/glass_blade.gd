## Hits harder and takes more damage.
class_name GlassBlade
extends Modifier

const ID := &"glass_blade"

func _init() -> void:
	stage = Stage.MUL
	params = {&"damage": 0.5, &"taken": 0.4}

func id() -> StringName:
	return ID

func modify_stat(stat_id: StringName, value: float, _ctx: HookCtx) -> float:
	if stat_id == CombatStats.DAMAGE_DEALT_MULT:
		return value * (1.0 + param(&"damage"))
	if stat_id == CombatStats.DAMAGE_TAKEN_MULT:
		return value * (1.0 + param(&"taken"))
	return value

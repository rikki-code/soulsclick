## Elite affix: more hp and less damage taken.
class_name PlatedAffix
extends Modifier

const ID := &"plated"

func _init() -> void:
	stage = Stage.MUL
	params = {&"hp": 1.4, &"taken": 0.85}

func id() -> StringName:
	return ID

func modify_stat(stat_id: StringName, value: float, _ctx: HookCtx) -> float:
	if stat_id == CombatStats.MAX_HP:
		return value * params[&"hp"]
	if stat_id == CombatStats.DAMAGE_TAKEN_MULT:
		return value * params[&"taken"]
	return value

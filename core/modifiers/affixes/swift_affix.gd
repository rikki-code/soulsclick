## Elite affix: shorter telegraphs.
class_name SwiftAffix
extends Modifier

const ID := &"swift"

func _init() -> void:
	stage = Stage.MUL
	params = {&"scale": 0.75}

func id() -> StringName:
	return ID

func modify_stat(stat_id: StringName, value: float, _ctx: HookCtx) -> float:
	if stat_id == CombatStats.TELEGRAPH_SCALE:
		return value * params[&"scale"]
	return value

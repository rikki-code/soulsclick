## Data-driven stat change: add, multiply or set one stat. Equipment stats become these.
class_name StatModifier
extends Modifier

var stat: StringName
var amount: float
var source: StringName

func _init(p_stat: StringName = &"", p_stage := Stage.ADD, p_amount := 0.0, p_source: StringName = &"") -> void:
	stat = p_stat
	stage = p_stage
	amount = p_amount
	source = p_source

func id() -> StringName:
	return source

func modify_stat(stat_id: StringName, value: float, _ctx: HookCtx) -> float:
	if stat_id != stat:
		return value
	match stage:
		Stage.ADD:
			return value + amount
		Stage.MUL:
			return value * amount
	return amount

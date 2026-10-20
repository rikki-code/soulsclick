## Attacks hit harder and cost more stamina.
class_name Overreach
extends Modifier

const ID := &"overreach"

func _init() -> void:
	params = {&"damage": 0.6, &"cost": 0.5}

func id() -> StringName:
	return ID

func modify_attack(ctx: AttackCtx) -> void:
	ctx.damage *= 1.0 + param(&"damage")
	ctx.stamina_cost *= 1.0 + param(&"cost")

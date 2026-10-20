## A parry triggers a free riposte.
class_name CounterTide
extends Modifier

const ID := &"counter_tide"

func _init() -> void:
	params = {&"mult": 0.6}

func id() -> StringName:
	return ID

func on_parry(ctx: StrikeCtx) -> void:
	ctx.fx.queue_free_attack(param(&"mult") * (1.5 if ctx.perfect else 1.0))

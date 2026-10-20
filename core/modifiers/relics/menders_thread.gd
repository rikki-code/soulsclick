## Heals on every parry, twice as much on a perfect one.
class_name MendersThread
extends Modifier

const ID := &"menders_thread"

func _init() -> void:
	params = {&"heal": 3.0}

func id() -> StringName:
	return ID

func on_parry(ctx: StrikeCtx) -> void:
	ctx.fx.heal(ctx.side, roundi(param(&"heal") * (2.0 if ctx.perfect else 1.0)))

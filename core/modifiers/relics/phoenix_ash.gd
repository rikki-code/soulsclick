## Survives the first lethal blow of the run with a share of max hp.
class_name PhoenixAsh
extends Modifier

const ID := &"phoenix_ash"
const USED := &"used"

func _init() -> void:
	params = {&"hp_share": 0.35}

func id() -> StringName:
	return ID

func on_would_die(ctx: DeathCtx) -> void:
	if run_data.get(USED, false):
		return
	run_data[USED] = true
	ctx.fx.prevent_death(ceili(ctx.owner.max_hp * param(&"hp_share")))

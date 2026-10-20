## Bonfire (rest), shop and altar rooms. Shop and altar are placeholders until relics exist.
class_name PlacePanel
extends RunScreen

signal finished(choice: StringName)

func setup(run: Run, plan: RoomPlan) -> PlacePanel:
	_build(RunScreen.kind_name(plan.kind_id))
	_status(run)
	if plan.kind_id == BonfireRoom.ID:
		var heal := roundi(run.config.max_hp * float(plan.data.get("heal_share", 0.0)))
		_text(tr("PLACE_BONFIRE"), 34, MUTED)
		_button(tr("PLACE_REST") % heal, func() -> void: finished.emit(BonfireRoom.HEAL), BIG_BUTTON_HEIGHT)
	else:
		_text(tr("PLACE_SOON"), 40, MUTED)
		_button(tr("BATTLE_CONTINUE"), func() -> void: finished.emit(&""), BIG_BUTTON_HEIGHT)
	return self

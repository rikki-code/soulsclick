## Recovery. Only the heal option exists now; reforge and cleanse join `options` with their systems.
class_name BonfireRoom
extends RoomKind

const ID := &"bonfire"
const HEAL := &"heal"

func id() -> StringName:
	return ID

func make_preview(run: Run, door: Door) -> Dictionary:
	var preview := super.make_preview(run, door)
	preview["rewards"] = [{"id": HEAL, "share": run.realm().bonfire_heal_share}]
	return preview

func _fill_plan(run: Run, _door: Door, plan: RoomPlan) -> void:
	plan.data = {"options": [HEAL], "heal_share": run.realm().bonfire_heal_share}

func complete(run: Run, plan: RoomPlan, result: RoomResult) -> void:
	super.complete(run, plan, result)
	if result.choice == &"" or result.choice == HEAL:
		run.heal(roundi(run.config.max_hp * float(plan.data["heal_share"])))

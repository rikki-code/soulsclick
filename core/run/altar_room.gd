## Free relic pick; the offer itself is rolled by the relic system from `data.offer_seed`.
class_name AltarRoom
extends RoomKind

const ID := &"altar"

func id() -> StringName:
	return ID

func make_preview(run: Run, door: Door) -> Dictionary:
	var preview := super.make_preview(run, door)
	preview["rewards"] = [{"id": &"relic_offer", "size": run.realm().altar_offer_size}]
	return preview

func _fill_plan(run: Run, door: Door, plan: RoomPlan) -> void:
	plan.data = {"offer_size": run.realm().altar_offer_size, "offer_seed": _reward_seed(run, door)}

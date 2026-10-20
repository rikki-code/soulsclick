## Placeholder stock: the relic system rolls `offer_size` items from `offer_seed`; prices are in Souls. Purchases are applied by the shop flow;
## the run deducts the Souls reported in `RoomResult.souls_spent`.
class_name ShopRoom
extends RoomKind

const ID := &"shop"

func id() -> StringName:
	return ID

func make_preview(run: Run, door: Door) -> Dictionary:
	var preview := super.make_preview(run, door)
	preview["rewards"] = [{"id": &"shop", "size": run.realm().shop_offer_size}]
	return preview

func _fill_plan(run: Run, door: Door, plan: RoomPlan) -> void:
	var realm := run.realm()
	plan.data = {
		"offer_size": realm.shop_offer_size, "offer_seed": _reward_seed(run, door),
		"heal_price": realm.shop_heal_price, "reroll_price": realm.shop_reroll_price,
	}

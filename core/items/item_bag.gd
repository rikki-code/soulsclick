## What Duel.use_item needs from an inventory: take one charge of a consumable. Inventory extends it.
class_name ItemBag
extends RefCounted

## Spends one charge and returns the item, or null when none is left.
func take_charge(_item_id: StringName) -> ConsumableItem:
	return null

func charges(_item_id: StringName) -> int:
	return 0

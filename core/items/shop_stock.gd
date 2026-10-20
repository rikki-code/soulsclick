## What the in-battle shop panel offers. `list` = every item sold for Souls, catalog order (owned run buffs
## are left out when an inventory is given).
class_name ShopStock
extends RefCounted

static func list(inventory: Inventory = null) -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for def in ItemCatalog.all():
		if def.price_souls <= 0:
			continue
		if inventory != null and not def.is_consumable() and inventory.owns(def.id):
			continue
		result.append(def)
	return result

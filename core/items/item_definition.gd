## An item bought in battle with run Souls, any time (side panel). Data in data/items/*.tres.
## Kind is the class: ConsumableItem (used mid-fight) or RunBuffItem (Modifier active for the whole run).
class_name ItemDefinition
extends Resource

@export var id: StringName
@export var name_key := ""
@export var desc_key := ""
@export var icon: StringName
@export var price_souls := 0

func is_consumable() -> bool:
	return false

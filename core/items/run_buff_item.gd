## A Modifier active for the whole run: Inventory.begin_fight adds it to the player at every fight start.
## `stats` become StatModifiers.
class_name RunBuffItem
extends ItemDefinition

@export var stats: Array[EquipmentStat] = []

func modifiers() -> Array[Modifier]:
	var result: Array[Modifier] = []
	for entry in stats:
		result.append(StatModifier.new(entry.stat, entry.stage, entry.amount, id))
	return result

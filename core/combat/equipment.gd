## A weapon, shield or armor as data (data/equipment/*.tres): trade-offs expressed as stat changes.
class_name Equipment
extends Resource

const WEAPON := &"weapon"
const SHIELD := &"shield"
const ARMOR := &"armor"

@export var id: StringName
@export var name_key := ""
@export var desc_key := ""
@export var slot: StringName = WEAPON
@export var stats: Array[EquipmentStat] = []

func modifiers() -> Array[Modifier]:
	var result: Array[Modifier] = []
	for entry in stats:
		result.append(StatModifier.new(entry.stat, entry.stage, entry.amount, id))
	return result

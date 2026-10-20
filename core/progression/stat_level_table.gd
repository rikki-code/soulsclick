## Data of one level set (data/progression/*.tres): which stats can be leveled, gains and prices.
class_name StatLevelTable
extends Resource

@export var stats: Array[StatLevelDef] = []

func def_of(stat: StringName) -> StatLevelDef:
	for entry in stats:
		if entry.stat == stat:
			return entry
	return null

func stat_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for entry in stats:
		result.append(entry.stat)
	return result

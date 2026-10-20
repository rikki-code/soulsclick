## Levels of one set (run levels paid in Souls, or permanent levels paid in Embers) over a StatLevelTable.
## Pure state: the game layer pays the cost, calls level_up and applies modifiers() to the player fighter.
class_name StatLevels
extends RefCounted

var table: StatLevelTable
var levels := {}

func _init(p_table: StatLevelTable = null) -> void:
	table = p_table

func level_of(stat: StringName) -> int:
	return int(levels.get(stat, 0))

func has_stat(stat: StringName) -> bool:
	return table != null and table.def_of(stat) != null

## Price of the next level; -1 for a stat not in the table.
func cost_of(stat: StringName) -> int:
	if not has_stat(stat):
		return -1
	return table.def_of(stat).cost_at(level_of(stat))

## Raises the level by one; the caller has already paid cost_of(stat).
func level_up(stat: StringName) -> bool:
	if not has_stat(stat):
		return false
	levels[stat] = level_of(stat) + 1
	return true

func total_levels() -> int:
	var sum := 0
	for stat in levels:
		sum += int(levels[stat])
	return sum

func reset() -> void:
	levels.clear()

func to_dict() -> Dictionary:
	var result := {}
	for stat in levels:
		result[String(stat)] = int(levels[stat])
	return result

func from_dict(data: Dictionary) -> void:
	levels.clear()
	for key in data:
		var stat := StringName(key)
		if has_stat(stat):
			levels[stat] = maxi(int(data[key]), 0)

## One ADD StatModifier per leveled stat. Add them to fighter.mods (source id = `source`).
func modifiers(source: StringName = &"levels") -> Array[Modifier]:
	var result: Array[Modifier] = []
	if table == null:
		return result
	for entry in table.stats:
		var level := level_of(entry.stat)
		if level > 0:
			result.append(StatModifier.new(entry.stat, Modifier.Stage.ADD, entry.increment * level, source))
	return result

func apply_to(fighter: Fighter, source: StringName = &"levels") -> void:
	for mod in modifiers(source):
		fighter.mods.add(mod)

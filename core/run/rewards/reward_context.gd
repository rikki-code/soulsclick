## What reward cards change besides the Run: refs the game layer owns and passes in. Data holder, no signals.
class_name RewardContext
extends RefCounted

## Owned relic ids in pick order. Game layer: `relic_modifiers()` at every fight start, save `to_dict()` with the run.
var relics: Array[StringName] = []
var run_levels: StatLevels
var inventory: Inventory

func _init(p_run_levels: StatLevels = null, p_inventory: Inventory = null) -> void:
	run_levels = p_run_levels
	inventory = p_inventory

func has_relic(relic_id: StringName) -> bool:
	return relics.has(relic_id)

func add_relic(relic_id: StringName) -> bool:
	if relics.has(relic_id) or not ModifierCatalog.has(relic_id):
		return false
	relics.append(relic_id)
	return true

## Fresh modifier instances of every owned relic (add to `duel.player.mods`).
func relic_modifiers() -> Array[Modifier]:
	var result: Array[Modifier] = []
	for relic_id in relics:
		var mod := ModifierCatalog.create(relic_id)
		if mod != null:
			result.append(mod)
	return result

func to_dict() -> Dictionary:
	return {"relics": relics.map(func(r: StringName) -> String: return String(r))}

func from_dict(data: Dictionary) -> void:
	relics.clear()
	for key in data.get("relics", []):
		add_relic(StringName(key))

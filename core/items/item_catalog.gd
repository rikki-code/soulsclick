## id -> ItemDefinition (data/items/<id>.tres). Order = display order.
class_name ItemCatalog
extends RefCounted

const IDS: Array[StringName] = [
	&"flask", &"ember_bomb", &"whetstone_oil", &"warding_ash",
]
const DIR := "res://data/items/"

static var _cache := {}

static func ids() -> Array[StringName]:
	return IDS

static func has(item_id: StringName) -> bool:
	return IDS.has(item_id)

static func get_def(item_id: StringName) -> ItemDefinition:
	if not has(item_id):
		return null
	if not _cache.has(item_id):
		_cache[item_id] = load(DIR + String(item_id) + ".tres")
	return _cache[item_id]

static func all() -> Array[ItemDefinition]:
	var result: Array[ItemDefinition] = []
	for item_id in IDS:
		result.append(get_def(item_id))
	return result

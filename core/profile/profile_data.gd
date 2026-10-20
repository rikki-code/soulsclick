## Everything saved about the player across games: souls, character levels, best stats and the
## language and controls choice. Plain data, no file access (SaveStore does that).
class_name ProfileData
extends RefCounted

const VERSION := 1

var souls := 0
var levels: Dictionary = {}  # stat id (StringName) -> int
var best: Dictionary = {}  # stat id (StringName) -> int
## Locale code; empty means "follow the platform or OS language".
var language := ""
## Battle input scheme id; empty means "pick by device" (Hands on touch devices, Buttons otherwise).
var input_scheme := ""
## Scheme ids whose first-battle hint was already shown.
var hinted_schemes: Array[String] = []

func level_of(stat: StringName) -> int:
	return int(levels.get(stat, 0))

func record_best(stat: StringName, value: int) -> bool:
	if value <= int(best.get(stat, 0)):
		return false
	best[stat] = value
	return true

func was_hinted(scheme_id: String) -> bool:
	return hinted_schemes.has(scheme_id)

func mark_hinted(scheme_id: String) -> void:
	if not hinted_schemes.has(scheme_id):
		hinted_schemes.append(scheme_id)

func to_dict() -> Dictionary:
	return {"version": VERSION, "souls": souls, "levels": levels, "best": best, "language": language, "input_scheme": input_scheme, "hinted_schemes": hinted_schemes}

static func from_dict(data: Dictionary) -> ProfileData:
	var migrated := _migrate(data)
	if migrated.is_empty():
		return ProfileData.new()
	var profile := ProfileData.new()
	profile.souls = maxi(int(migrated.get("souls", 0)), 0)
	profile.levels = _int_map(migrated.get("levels", {}))
	profile.best = _int_map(migrated.get("best", {}))
	profile.language = str(migrated.get("language", ""))
	profile.input_scheme = str(migrated.get("input_scheme", ""))
	for id: Variant in migrated.get("hinted_schemes", []):
		profile.hinted_schemes.append(str(id))
	return profile

## Brings older formats up to VERSION step by step; an unknown or newer version yields an empty dict.
static func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version < 1 or version > VERSION:
		return {}
	return data

static func _int_map(source: Variant) -> Dictionary:
	var result := {}
	if not (source is Dictionary):
		return result
	for key in source:
		result[StringName(key)] = int(source[key])
	return result

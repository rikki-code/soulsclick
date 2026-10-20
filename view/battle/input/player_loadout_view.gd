## What the player's hands hold: a shield id and a weapon id as named in the player pack's gear.json. The game layer
## builds it from the equipped items with from_equipment(); the id map between equipment ids and gear ids lives here.
class_name PlayerLoadoutView
extends RefCounted

const DEFAULT_SHIELD := &"kite"
const DEFAULT_WEAPON := &"sword"
const SHIELD_GEAR := {&"buckler": &"buckler", &"kite_shield": &"kite", &"tower_shield": &"tower"}
const WEAPON_GEAR := {&"dagger": &"dagger", &"sword": &"sword", &"greatsword": &"greatsword"}

## Dev screenshots only (`--gear=<shield>,<weapon>`): used when a scheme is built without a loadout.
static var dev_loadout: PlayerLoadoutView

var shield_id := DEFAULT_SHIELD
var weapon_id := DEFAULT_WEAPON

## Equipment ids (buckler, kite_shield, tower_shield / dagger, sword, greatsword); gear ids pass through; unknown or
## empty ids fall back to the defaults.
static func from_equipment(shield_equipment_id: StringName, weapon_equipment_id: StringName) -> PlayerLoadoutView:
	var result := PlayerLoadoutView.new()
	result.shield_id = _lookup(SHIELD_GEAR, shield_equipment_id, DEFAULT_SHIELD)
	result.weapon_id = _lookup(WEAPON_GEAR, weapon_equipment_id, DEFAULT_WEAPON)
	return result

static func resolve(loadout: PlayerLoadoutView) -> PlayerLoadoutView:
	if loadout != null:
		return loadout
	return dev_loadout if dev_loadout != null else PlayerLoadoutView.new()

static func _lookup(table: Dictionary, equipment_id: StringName, fallback: StringName) -> StringName:
	if table.has(equipment_id):
		return table[equipment_id]
	return equipment_id if table.values().has(equipment_id) else fallback

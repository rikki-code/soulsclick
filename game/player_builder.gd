## Assembles the player fighter of a run: base from tuning, start loadout, permanent levels (Embers), run levels (Souls).
class_name PlayerBuilder
extends RefCounted

const EQUIPMENT_DIR := "res://data/equipment/%s.tres"
const START_SHIELD := &"kite_shield"
const START_WEAPON := &"sword"
const PERMANENT_SOURCE := &"perm_levels"
const RUN_SOURCE := &"run_levels"

static func build(tuning: CombatTuning, permanent: StatLevels, run_levels: StatLevels) -> Fighter:
	var player := Fighter.make_player(tuning)
	var weapon := load(EQUIPMENT_DIR % START_WEAPON) as Equipment
	var shield := load(EQUIPMENT_DIR % START_SHIELD) as Equipment
	Loadout.of(weapon, shield).apply_to(player)
	permanent.apply_to(player, PERMANENT_SOURCE)
	run_levels.apply_to(player, RUN_SOURCE)
	player.reset_pools()
	return player

## Current resolved value of one stat for the level-up screens.
static func stat_value(tuning: CombatTuning, permanent: StatLevels, run_levels: StatLevels, stat: StringName) -> float:
	var player := build(tuning, permanent, run_levels)
	var value := player.stats.value(stat)
	player.dispose()
	return value

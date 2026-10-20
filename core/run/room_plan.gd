## What the game layer needs to play one entered room. Resources stay in core; the view reads ids.
class_name RoomPlan
extends RefCounted

var kind_id: StringName = &""
var realm_index := 0
var step_index := 0
var door_index := 0
var door: Door
var is_combat := false
## Combat rooms only.
var enemy: EnemyDefinition
var affix_id: StringName = &""
var combat_seed := 0
## Level for `Duel` / `CombatScaling`.
var combat_level := 1
var hp_multiplier := 1.0
var souls_reward := 0
var player_hp := 0
var player_max_hp := 0
## Kind specific payload (offer seeds, prices, options); plain data only.
var data: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"kind": kind_id, "realm_index": realm_index, "step_index": step_index, "door_index": door_index,
		"enemy": enemy.id if enemy != null else &"", "affix": affix_id, "combat_seed": combat_seed,
		"combat_level": combat_level, "hp_multiplier": hp_multiplier, "souls_reward": souls_reward,
		"player_hp": player_hp, "player_max_hp": player_max_hp, "data": data,
	}

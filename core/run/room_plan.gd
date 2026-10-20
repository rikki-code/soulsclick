## What the game layer needs to play one entered room. Resources stay in core; the view reads ids.
class_name RoomPlan
extends RefCounted

var kind_id: StringName = &""
var realm_index := 0
## Realms completed before this room (endless depth) and 0-based ordinal of the room in the run.
var depth := 0
var node := 0
var step_index := 0
var door_index := 0
var door: Door
var is_combat := false
## Combat rooms only.
var enemy: EnemyDefinition
var affix_id: StringName = &""
## All affixes of the enemy (affix_id is the first); the game applies each.
var affix_ids: Array[StringName] = []
## The whole wave fought one after another; index 0 is `enemy`. Parallel arrays hold each enemy's affixes (Array of
## Array[StringName]) and hp / damage multipliers. Empty on plans built by hand: use the *_at helpers.
var wave: Array[EnemyDefinition] = []
var wave_affixes: Array = []
var wave_hp_multipliers: Array[float] = []
var wave_damage_multipliers: Array[float] = []
var combat_seed := 0
## Level for `Duel` / `CombatScaling`.
var combat_level := 1
var hp_multiplier := 1.0
## Multiplier the game applies to every damage the enemy deals.
var damage_multiplier := 1.0
var souls_reward := 0
var player_hp := 0
var player_max_hp := 0
## Kind specific payload (offer seeds, prices, options); plain data only.
var data: Dictionary = {}

func wave_size() -> int:
	return maxi(wave.size(), 1 if enemy != null else 0)

func enemy_at(index: int) -> EnemyDefinition:
	return wave[index] if index < wave.size() else enemy

func affixes_at(index: int) -> Array[StringName]:
	if index < wave_affixes.size():
		var list: Array[StringName] = []
		list.assign(wave_affixes[index])
		return list
	return affix_ids

func hp_multiplier_at(index: int) -> float:
	return wave_hp_multipliers[index] if index < wave_hp_multipliers.size() else hp_multiplier

func damage_multiplier_at(index: int) -> float:
	return wave_damage_multipliers[index] if index < wave_damage_multipliers.size() else damage_multiplier

func to_dict() -> Dictionary:
	return {
		"kind": kind_id, "realm_index": realm_index, "depth": depth, "node": node, "step_index": step_index, "door_index": door_index,
		"enemy": enemy.id if enemy != null else &"", "wave": wave.map(func(e: EnemyDefinition) -> StringName: return e.id), "wave_affixes": wave_affixes, "affix": affix_id, "affixes": affix_ids, "combat_seed": combat_seed,
		"combat_level": combat_level, "hp_multiplier": hp_multiplier, "damage_multiplier": damage_multiplier, "souls_reward": souls_reward,
		"player_hp": player_hp, "player_max_hp": player_max_hp, "data": data,
	}

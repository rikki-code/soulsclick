## Shared logic of rooms that start a duel: enemy choice from a realm pool, souls and hp multipliers.
class_name CombatRoomKind
extends RoomKind

func is_combat() -> bool:
	return true

func entries(_realm: RealmDefinition) -> Array[RealmEnemyEntry]:
	return []

func uses_affixes() -> bool:
	return false

func souls_multiplier(_realm: RealmDefinition) -> float:
	return 1.0

func hp_multiplier(_realm: RealmDefinition) -> float:
	return 1.0

## Share of max hp restored after winning.
func heal_share(_realm: RealmDefinition) -> float:
	return 0.0

func make_door(realm: RealmDefinition, rng: RandomNumberGenerator, taken: Dictionary) -> Door:
	var doors: Array[Door] = []
	var weights: Array[float] = []
	for entry in entries(realm):
		if entry.enemy == null:
			continue
		var affixes: Array[StringName] = [&""]
		if uses_affixes() and not entry.affixes.is_empty():
			affixes = entry.affixes
		for affix in affixes:
			var door := Door.make(id(), entry.enemy.id, affix)
			if taken.has(door.signature()):
				continue
			doors.append(door)
			weights.append(entry.weight / affixes.size())
	var picked := WeightedPick.index(rng, weights)
	return null if picked < 0 else doors[picked]

func make_preview(run: Run, door: Door) -> Dictionary:
	var preview := super.make_preview(run, door)
	var enemy := _enemy_of(run.realm(), door)
	if enemy == null:
		return preview
	preview["enemy"] = enemy.id
	preview["name_key"] = enemy.name_key
	preview["palette_tag"] = enemy.palette_tag
	preview["rewards"] = _rewards(run, enemy)
	return preview

func complete(run: Run, plan: RoomPlan, result: RoomResult) -> void:
	super.complete(run, plan, result)
	run.add_souls(plan.souls_reward)
	var share := heal_share(run.realm())
	if share > 0.0:
		run.heal(roundi(run.config.max_hp * share))

func _rewards(run: Run, enemy: EnemyDefinition) -> Array[Dictionary]:
	return [{"id": &"souls", "amount": _souls_for(run.realm(), enemy)}]

func _souls_for(realm: RealmDefinition, enemy: EnemyDefinition) -> int:
	return roundi(enemy.souls_reward * souls_multiplier(realm))

func _fill_plan(run: Run, door: Door, plan: RoomPlan) -> void:
	var enemy := _enemy_of(run.realm(), door)
	plan.enemy = enemy
	plan.affix_id = door.affix_id
	plan.combat_seed = RunRng.seed_for(run.config.seed, RunRng.COMBAT, run.realm_index, run.step_index, door.index)
	plan.hp_multiplier = hp_multiplier(run.realm())
	plan.souls_reward = _souls_for(run.realm(), enemy) if enemy != null else 0
	plan.data = _reward_data(run, door)

## Kind specific reward data resolved at entry (offer seeds, pick rolls).
func _reward_data(_run: Run, _door: Door) -> Dictionary:
	return {}

func _enemy_of(realm: RealmDefinition, door: Door) -> EnemyDefinition:
	for entry in entries(realm):
		if entry.enemy != null and entry.enemy.id == door.variant:
			return entry.enemy
	return null

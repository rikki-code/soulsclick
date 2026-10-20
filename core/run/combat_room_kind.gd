## Shared logic of rooms that start a duel: enemy choice from a realm pool, souls and hp multipliers.
class_name CombatRoomKind
extends RoomKind

const WAVE_SEED_OFFSET := 7919

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

## Extra curve factors of this kind (elite, boss).
func kind_hp_factor(_curve: DepthCurve) -> float:
	return 1.0

func kind_damage_factor(_curve: DepthCurve) -> float:
	return 1.0

## Share of max hp restored after winning.
func heal_share(_realm: RealmDefinition) -> float:
	return 0.0

## How many enemies follow the first one; drawn from `rng` (the wave stream of the room).
func wave_extra_count(_curve: DepthCurve, _depth: int, _node: int, _rng: RandomNumberGenerator) -> int:
	return 0

## Pool the follow-up enemies come from.
func extra_entries(realm: RealmDefinition) -> Array[RealmEnemyEntry]:
	return realm.fight_pool

func make_door(realm: RealmDefinition, rng: RandomNumberGenerator, taken: Dictionary, depth := 0) -> Door:
	var doors: Array[Door] = []
	var weights: Array[float] = []
	var pools: Array[RealmEnemyEntry] = []
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
			pools.append(entry)
			weights.append(entry.weight / affixes.size())
	var picked := WeightedPick.index(rng, weights)
	if picked < 0:
		return null
	_escalate(doors[picked], pools[picked], rng, realm.curve(), depth, taken)
	return doors[picked]

## Depth escalation: normal fights may roll one affix, elites a second one. Draws nothing below the curve's start depths.
func _escalate(door: Door, entry: RealmEnemyEntry, rng: RandomNumberGenerator, curve: DepthCurve, depth: int, taken: Dictionary) -> void:
	var chance := curve.double_affix_chance_at(depth) if uses_affixes() else curve.fight_affix_chance_at(depth)
	if chance <= 0.0:
		return
	var options: Array[StringName] = []
	for affix in entry.affixes:
		if not door.affix_ids.has(affix):
			options.append(affix)
	if options.is_empty() or rng.randf() >= chance:
		return
	var extra := options[rng.randi_range(0, options.size() - 1)]
	var plain_affixes := door.affix_ids.duplicate()
	door.add_affix(extra)
	if taken.has(door.signature()):
		door.affix_ids.clear()
		door.affix_id = &""
		for affix in plain_affixes:
			door.add_affix(affix)

func make_preview(run: Run, door: Door) -> Dictionary:
	var preview := super.make_preview(run, door)
	var enemy := _enemy_of(run.realm(), door)
	if enemy == null:
		return preview
	preview["enemy"] = enemy.id
	preview["name_key"] = enemy.name_key
	preview["palette_tag"] = enemy.palette_tag
	preview["rewards"] = _rewards(run, enemy)
	preview["affixes"] = door.affix_ids
	return preview

func complete(run: Run, plan: RoomPlan, result: RoomResult) -> void:
	super.complete(run, plan, result)
	run.add_souls(plan.souls_reward)
	var share := heal_share(run.realm())
	if share > 0.0:
		run.heal(roundi(run.config.max_hp * share))

func _rewards(run: Run, enemy: EnemyDefinition) -> Array[Dictionary]:
	return [{"id": &"souls", "amount": _souls_for(run, enemy)}]

func _souls_for(run: Run, enemy: EnemyDefinition) -> int:
	return roundi(enemy.souls_reward * souls_multiplier(run.realm()) * run.curve().souls_multiplier(run.upcoming_node()))

func _fill_plan(run: Run, door: Door, plan: RoomPlan) -> void:
	var enemy := _enemy_of(run.realm(), door)
	plan.enemy = enemy
	plan.affix_id = door.affix_id
	plan.affix_ids = door.affix_ids.duplicate()
	plan.combat_seed = RunRng.seed_for(run.config.seed, RunRng.COMBAT, run.realm_index, run.step_index, door.index)
	var curve := run.curve()
	var node := run.upcoming_node()
	plan.hp_multiplier = hp_multiplier(run.realm()) * kind_hp_factor(curve) * curve.hp_multiplier(node)
	plan.damage_multiplier = kind_damage_factor(curve) * curve.damage_multiplier(node)
	plan.souls_reward = _souls_for(run, enemy) if enemy != null else 0
	_fill_wave(run, plan, enemy)
	plan.data = _reward_data(run, door)

## Kind specific reward data resolved at entry (offer seeds, pick rolls).
func _reward_data(_run: Run, _door: Door) -> Dictionary:
	return {}

func _enemy_of(realm: RealmDefinition, door: Door) -> EnemyDefinition:
	for entry in entries(realm):
		if entry.enemy != null and entry.enemy.id == door.variant:
			return entry.enemy
	return null

## First enemy as planned, then `wave_extra_count` more from the fight pool (hp / damage by the plain curve, no kind factors).
## Own rng stream derived from the combat seed, so the wave is stable per room.
func _fill_wave(run: Run, plan: RoomPlan, first: EnemyDefinition) -> void:
	if first == null:
		return
	plan.wave = [first]
	plan.wave_affixes = [plan.affix_ids]
	plan.wave_hp_multipliers = [plan.hp_multiplier]
	plan.wave_damage_multipliers = [plan.damage_multiplier]
	var curve := run.curve()
	var node := plan.node
	var rng := RandomNumberGenerator.new()
	rng.seed = plan.combat_seed + WAVE_SEED_OFFSET
	var extra := wave_extra_count(curve, run.depth, node, rng)
	var pool: Array[RealmEnemyEntry] = []
	for entry in extra_entries(run.realm()):
		if entry.enemy != null:
			pool.append(entry)
	if pool.is_empty():
		return
	var weights: Array[float] = []
	for entry in pool:
		weights.append(entry.weight)
	for i in extra:
		var entry := pool[maxi(WeightedPick.index(rng, weights), 0)]
		var affixes: Array[StringName] = []
		if not entry.affixes.is_empty() and rng.randf() < curve.fight_affix_chance_at(run.depth):
			affixes.append(entry.affixes[rng.randi_range(0, entry.affixes.size() - 1)])
		plan.wave.append(entry.enemy)
		plan.wave_affixes.append(affixes)
		plan.wave_hp_multipliers.append(curve.hp_multiplier(node))
		plan.wave_damage_multipliers.append(curve.damage_multiplier(node))
		plan.souls_reward += roundi(entry.enemy.souls_reward * curve.souls_multiplier(node))

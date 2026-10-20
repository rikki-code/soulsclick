## One normal enemy. Souls, and sometimes a relic-or-heal pick (rolled on the reward stream).
class_name FightRoom
extends CombatRoomKind

const ID := &"fight"

func id() -> StringName:
	return ID

func entries(realm: RealmDefinition) -> Array[RealmEnemyEntry]:
	return realm.fight_pool

func _rewards(run: Run, enemy: EnemyDefinition) -> Array[Dictionary]:
	var list := super._rewards(run, enemy)
	list.append({"id": &"relic_or_heal", "chance": run.realm().fight_pick_chance})
	return list

func _reward_data(run: Run, door: Door) -> Dictionary:
	var seed_value := _reward_seed(run, door)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return {"pick": rng.randf() < run.realm().fight_pick_chance, "offer_seed": seed_value}

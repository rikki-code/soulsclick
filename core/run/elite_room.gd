## Enemy plus one affix (placeholder ids from the pool entry), bonus souls, relic offer.
class_name EliteRoom
extends CombatRoomKind

const ID := &"elite"

func id() -> StringName:
	return ID

func entries(realm: RealmDefinition) -> Array[RealmEnemyEntry]:
	return realm.elite_pool

func uses_affixes() -> bool:
	return true

func souls_multiplier(realm: RealmDefinition) -> float:
	return realm.elite_souls_multiplier

func hp_multiplier(realm: RealmDefinition) -> float:
	return realm.elite_hp_multiplier

func _rewards(run: Run, enemy: EnemyDefinition) -> Array[Dictionary]:
	var list := super._rewards(run, enemy)
	list.append({"id": &"relic_offer", "size": run.realm().altar_offer_size})
	return list

func _reward_data(run: Run, door: Door) -> Dictionary:
	return {"offer_size": run.realm().altar_offer_size, "offer_seed": _reward_seed(run, door)}

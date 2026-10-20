## The realm boss: relic offer and a partial heal.
class_name BossRoom
extends CombatRoomKind

const ID := &"boss"

func id() -> StringName:
	return ID

func entries(realm: RealmDefinition) -> Array[RealmEnemyEntry]:
	if realm.boss == null:
		return []
	var entry := RealmEnemyEntry.new()
	entry.enemy = realm.boss
	return [entry]

func heal_share(realm: RealmDefinition) -> float:
	return realm.boss_heal_share

func _rewards(run: Run, enemy: EnemyDefinition) -> Array[Dictionary]:
	var list := super._rewards(run, enemy)
	list.append({"id": &"relic_offer", "size": run.realm().altar_offer_size, "boss": true})
	list.append({"id": &"heal", "share": run.realm().boss_heal_share})
	return list

func _reward_data(run: Run, door: Door) -> Dictionary:
	return {"offer_size": run.realm().altar_offer_size, "offer_seed": _reward_seed(run, door), "boss": true}

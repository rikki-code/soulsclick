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

func kind_hp_factor(curve: DepthCurve) -> float:
	return curve.elite_hp_factor

func kind_damage_factor(curve: DepthCurve) -> float:
	return curve.elite_damage_factor

func wave_extra_count(curve: DepthCurve, depth: int, _node: int, rng: RandomNumberGenerator) -> int:
	var chance := curve.elite_wave_chance_at(depth)
	return 1 if chance > 0.0 and rng.randf() < chance else 0

func _rewards(run: Run, enemy: EnemyDefinition) -> Array[Dictionary]:
	var list := super._rewards(run, enemy)
	list.append({"id": &"relic_offer", "size": run.realm().altar_offer_size})
	return list

func _reward_data(run: Run, door: Door) -> Dictionary:
	return {"offer_size": run.realm().altar_offer_size, "offer_seed": _reward_seed(run, door)}

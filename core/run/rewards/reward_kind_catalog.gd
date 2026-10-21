## Turns a reward kind id into the (stateless) kind object. One line per kind; lambdas keep class refs out of the static initializer.
class_name RewardKindCatalog
extends RefCounted

static var _factories := {
	&"relic": func() -> RewardKind: return RelicReward.new(),
	&"stat_level": func() -> RewardKind: return StatLevelReward.new(),
	&"consumable": func() -> RewardKind: return ConsumableReward.new(),
	&"souls": func() -> RewardKind: return SoulsReward.new(),
	&"heal": func() -> RewardKind: return HealReward.new(),
}
static var _instances := {}

static func has(kind_id: StringName) -> bool:
	return _factories.has(kind_id)

static func ids() -> Array:
	return _factories.keys()

static func get_kind(kind_id: StringName) -> RewardKind:
	if not has(kind_id):
		push_error("Unknown reward kind '%s'" % kind_id)
		return null
	if not _instances.has(kind_id):
		_instances[kind_id] = _factories[kind_id].call()
	return _instances[kind_id]

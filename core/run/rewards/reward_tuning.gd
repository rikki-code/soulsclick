## Numbers and card layout of the post-fight reward (data/rewards/reward_tuning.tres).
class_name RewardTuning
extends Resource

const PATH := "res://data/rewards/reward_tuning.tres"
static var _cached: RewardTuning

## Rooms that offer the big pick: `big_count` cards from `big_kinds`. Other combat rooms: `small_count` from `small_kinds`.
@export var big_room_ids: Array[StringName] = [&"elite", &"boss"]
@export var big_kinds: Array[StringName] = [&"relic", &"stat_level", &"consumable"]
@export var big_count := 3
@export var small_kinds: Array[StringName] = [&"souls", &"consumable", &"heal"]
@export var small_count := 2
## Souls card: base amount x DepthCurve.souls_multiplier(node).
@export var souls_base := 25
@export_range(0.0, 1.0) var heal_share := 0.25
@export var consumable_charges := 1

static func current() -> RewardTuning:
	if _cached == null:
		_cached = load(PATH) as RewardTuning
		if _cached == null:
			_cached = RewardTuning.new()
	return _cached

func is_big(room_kind_id: StringName) -> bool:
	return big_room_ids.has(room_kind_id)

func kinds_for(room_kind_id: StringName) -> Array[StringName]:
	return big_kinds if is_big(room_kind_id) else small_kinds

func count_for(room_kind_id: StringName) -> int:
	return big_count if is_big(room_kind_id) else small_count

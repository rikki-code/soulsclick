## Base of all room kinds. Every hook has a working default; a kind overrides only what differs.
## Kinds are stateless: all run state lives in `Run`.
class_name RoomKind
extends RefCounted

func id() -> StringName:
	return &""

func is_combat() -> bool:
	return false

## A door of this kind that is not in `taken` (signature -> true), or null when the kind has no variant left.
func make_door(_realm: RealmDefinition, _rng: RandomNumberGenerator, taken: Dictionary, _depth := 0) -> Door:
	var door := Door.make(id())
	return null if taken.has(door.signature()) else door

## Reward preview shown on the door: {kind, rewards: [{id, ...}]} plus kind specific keys.
func make_preview(_run: Run, door: Door) -> Dictionary:
	return {"kind": id(), "variant": door.variant, "affix": door.affix_id, "rewards": []}

func enter(run: Run, door: Door) -> RoomPlan:
	var plan := RoomPlan.new()
	plan.kind_id = id()
	plan.realm_index = run.realm_index
	plan.depth = run.depth
	plan.node = run.upcoming_node()
	plan.step_index = run.step_index
	plan.door_index = door.index
	plan.door = door
	plan.is_combat = is_combat()
	plan.combat_level = run.curve().combat_level(run.depth)
	plan.player_hp = run.hp
	plan.player_max_hp = run.config.max_hp
	_fill_plan(run, door, plan)
	return plan

## Applies the room's outcome to the run. Called only for a won room.
func complete(run: Run, _plan: RoomPlan, result: RoomResult) -> void:
	run.add_souls(-clampi(result.souls_spent, 0, run.souls))
	run.add_souls(maxi(result.souls_bonus, 0))

func _fill_plan(_run: Run, _door: Door, _plan: RoomPlan) -> void:
	pass

func _reward_seed(run: Run, door: Door) -> int:
	return RunRng.seed_for(run.config.seed, RunRng.REWARD, run.depth, run.step_index, door.index)

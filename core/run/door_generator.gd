## Doors of one step. A pure function of (seed, realm, step): the offer never depends on earlier choices.
class_name DoorGenerator
extends RefCounted

static func generate(run: Run) -> DoorOffer:
	return generate_at(run, run.depth, run.step_index)

## Doors of any step of the run's current realm; `run` only lends seed, realm and curve.
static func generate_at(run: Run, depth: int, step_index: int) -> DoorOffer:
	var realm := run.realm()
	var rule := realm.rule_at(step_index)
	var rng := RunRng.stream(run.config.seed, RunRng.MAP, depth, step_index)
	var offer := DoorOffer.new()
	offer.realm_index = run.realm_index
	offer.depth = depth
	offer.realm_id = realm.id
	offer.step_index = step_index
	offer.step_count = realm.step_count()
	var taken := {}
	var doors: Array[Door] = []
	for kind_id in rule.required_kinds:
		_add(doors, taken, kind_id, realm, rng, depth)
	var wanted := maxi(_door_count(rule, rng), doors.size())
	var candidates: Array[StringName] = []
	for kind_id in rule.kind_weights:
		candidates.append(StringName(kind_id))
	while doors.size() < wanted and not candidates.is_empty():
		var weights: Array[float] = []
		for kind_id in candidates:
			weights.append(float(rule.kind_weights[kind_id]))
		var picked := WeightedPick.index(rng, weights)
		if picked < 0:
			break
		if not _add(doors, taken, candidates[picked], realm, rng, depth):
			candidates.remove_at(picked)
	_shuffle(doors, rng)
	for i in doors.size():
		doors[i].index = i
	for door in doors:
		door.preview = RoomKindCatalog.get_kind(door.kind_id).make_preview(run, door)
	offer.doors = doors
	return offer

static func _add(doors: Array[Door], taken: Dictionary, kind_id: StringName, realm: RealmDefinition, rng: RandomNumberGenerator, depth: int) -> bool:
	var kind := RoomKindCatalog.get_kind(kind_id)
	var door := kind.make_door(realm, rng, taken, depth) if kind != null else null
	if door == null:
		return false
	taken[door.signature()] = true
	doors.append(door)
	return true

static func _door_count(rule: StepRule, rng: RandomNumberGenerator) -> int:
	var counts: Array[int] = []
	var weights: Array[float] = []
	for count in rule.door_count_weights:
		counts.append(int(count))
		weights.append(float(rule.door_count_weights[count]))
	var picked := WeightedPick.index(rng, weights)
	return 1 if picked < 0 else counts[picked]

static func _shuffle(doors: Array[Door], rng: RandomNumberGenerator) -> void:
	for i in range(doors.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := doors[i]
		doors[i] = doors[j]
		doors[j] = held

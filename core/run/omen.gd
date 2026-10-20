## A run theme: two favored tags. Effects (relic weight, tint) are read from `tags` by later systems.
class_name Omen
extends RefCounted

const TAGS: Array[StringName] = [&"parry", &"block", &"strike", &"stamina", &"vital", &"bleed", &"burn", &"frost", &"shock", &"soul", &"read", &"focus", &"curse"]
const TAGS_PER_OMEN := 2
const MAX_ROLL_ATTEMPTS := 64

var id: StringName = &""
var tags: Array[StringName] = []

static func make(p_tags: Array[StringName]) -> Omen:
	var omen := Omen.new()
	omen.tags = p_tags.duplicate()
	omen.tags.sort_custom(func(a: StringName, b: StringName) -> bool: return TAGS.find(a) < TAGS.find(b))
	omen.id = StringName("_".join(omen.tags))
	return omen

## `count` distinct omens, a pure function of the seed.
static func roll(run_seed: int, count := 2) -> Array[Omen]:
	var rng := RunRng.stream(run_seed, RunRng.OMEN)
	var result: Array[Omen] = []
	var seen := {}
	for attempt in MAX_ROLL_ATTEMPTS:
		if result.size() >= count:
			break
		var pool := TAGS.duplicate()
		var picked: Array[StringName] = []
		for i in TAGS_PER_OMEN:
			picked.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
		var omen := Omen.make(picked)
		if seen.has(omen.id):
			continue
		seen[omen.id] = true
		result.append(omen)
	return result

func to_dict() -> Dictionary:
	return {"id": id, "tags": tags}

static func from_dict(data: Dictionary) -> Omen:
	var list: Array[StringName] = []
	for tag in data.get("tags", []):
		list.append(StringName(tag))
	return Omen.make(list)

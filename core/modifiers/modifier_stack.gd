## Ordered modifiers of one fighter: stage (add < mul < set), then priority, then acquire order.
class_name ModifierStack
extends RefCounted

signal changed

## Hard cap of the proc chain, so effects that trigger effects cannot loop.
const MAX_DEPTH := 4

var seed_value := 0
var _owner: Fighter
var _next_order := 0
var _items: Array[Modifier] = []
var _ordered: Array[Modifier] = []

func _init(p_owner: Fighter) -> void:
	_owner = p_owner

func add(mod: Modifier) -> void:
	mod.owner = _owner
	mod.order = _next_order
	_next_order += 1
	_seed(mod)
	_items.append(mod)
	_resort()
	mod.on_added(_owner)
	changed.emit()

func remove(mod: Modifier) -> void:
	_items.erase(mod)
	_resort()
	changed.emit()

func items() -> Array[Modifier]:
	return _ordered

func find(mod_id: StringName) -> Modifier:
	for mod in _items:
		if mod.id() == mod_id:
			return mod
	return null

func reset_fight() -> void:
	for mod in _items:
		mod.fight_data = {}

func reseed(p_seed: int) -> void:
	seed_value = p_seed
	for mod in _items:
		_seed(mod)

func resolve(stat_id: StringName, base: float, ctx: HookCtx) -> float:
	var value := base
	for mod in _ordered:
		value = mod.modify_stat(stat_id, value, ctx)
	return value

## Calls `hook` on each modifier; the context is shared, fx and mod are set per receiver.
func fire(hook: StringName, ctx: HookCtx, duel: Duel) -> void:
	if ctx.depth > MAX_DEPTH:
		return
	for mod in _ordered.duplicate():
		if ctx.is_proc and not mod.reacts_to_proc:
			continue
		ctx.mod = mod
		ctx.rng = mod.rng
		ctx.fx = HookApi.new(duel, mod, ctx.owner.side, ctx.depth)
		mod.call(hook, ctx)

func _resort() -> void:
	_ordered = _items.duplicate()
	_ordered.sort_custom(_before)

static func _before(a: Modifier, b: Modifier) -> bool:
	if a.stage != b.stage:
		return a.stage < b.stage
	if a.priority != b.priority:
		return a.priority < b.priority
	return a.order < b.order

func _seed(mod: Modifier) -> void:
	mod.rng.seed = hash([seed_value, String(mod.id())])

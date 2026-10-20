## The only way a modifier changes the duel. Every call is a proc: it carries depth + 1 and is refused past
## ModifierStack.MAX_DEPTH. A successful call announces the modifier so the view can flash its icon.
class_name HookApi
extends RefCounted

const TAG_PROC := &"proc"
const TAG_ATTACK := &"attack"

var _duel: Duel
var _mod: Modifier
var _owner_side: StringName
var _depth: int

func _init(p_duel: Duel, p_mod: Modifier, p_owner_side: StringName, p_ctx_depth: int) -> void:
	_duel = p_duel
	_mod = p_mod
	_owner_side = p_owner_side
	_depth = p_ctx_depth + 1

func heal(side: StringName, amount: int) -> void:
	if _allowed() and _duel.heal_fighter(side, amount):
		_announce()

func damage(side: StringName, amount: int, tags: Array[StringName] = []) -> void:
	if not _allowed():
		return
	var proc_tags: Array[StringName] = [TAG_PROC]
	proc_tags.append_array(tags)
	if _duel.deal_damage(_duel.fighter_on(side), amount, proc_tags, _depth) > 0:
		_announce()

func add_stamina(side: StringName, amount: float) -> void:
	if _allowed():
		_duel.add_stamina(side, amount)
		_announce()

func stagger(side: StringName, seconds: float) -> void:
	if _allowed() and side == Fighter.ENEMY:
		_duel.stagger_enemy(seconds)
		_announce()

## Player riposte: costs nothing, no lock.
func queue_free_attack(damage_mult: float) -> void:
	if not _allowed():
		return
	if _duel.free_attack(damage_mult, _depth) > 0:
		_announce()

func prevent_death(survive_hp: int) -> void:
	if _allowed() and _duel.prevent_death(survive_hp):
		_announce()

func set_flag(key: StringName, value: Variant) -> void:
	_mod.fight_data[key] = value

func cue(_cue_id: StringName) -> void:
	if _allowed():
		_announce()

func _allowed() -> bool:
	return _depth <= ModifierStack.MAX_DEPTH

func _announce() -> void:
	_duel.modifier_triggered.emit(_mod.id(), _owner_side)

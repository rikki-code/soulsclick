## The equipment a fighter wears; turns into modifiers on its stack.
class_name Loadout
extends Resource

@export var weapon: Equipment
@export var shield: Equipment
@export var armor: Equipment

static func of(p_weapon: Equipment, p_shield: Equipment, p_armor: Equipment = null) -> Loadout:
	var loadout := Loadout.new()
	loadout.weapon = p_weapon
	loadout.shield = p_shield
	loadout.armor = p_armor
	return loadout

func pieces() -> Array[Equipment]:
	var result: Array[Equipment] = []
	for piece in [weapon, shield, armor]:
		if piece != null:
			result.append(piece)
	return result

func modifiers() -> Array[Modifier]:
	var result: Array[Modifier] = []
	for piece in pieces():
		result.append_array(piece.modifiers())
	return result

func apply_to(fighter: Fighter) -> void:
	for mod in modifiers():
		fighter.mods.add(mod)

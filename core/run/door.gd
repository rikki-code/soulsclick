## One choice on the map: a room kind plus its variant and a preview payload for the door icon.
class_name Door
extends RefCounted

var index := 0
var kind_id: StringName = &""
## Enemy id for combat rooms, empty otherwise.
var variant: StringName = &""
## First affix (kept for single-affix readers); `affix_ids` holds all of them, in order.
var affix_id: StringName = &""
var affix_ids: Array[StringName] = []
var preview: Dictionary = {}

static func make(p_kind_id: StringName, p_variant: StringName = &"", p_affix_id: StringName = &"") -> Door:
	var door := Door.new()
	door.kind_id = p_kind_id
	door.variant = p_variant
	door.add_affix(p_affix_id)
	return door

func add_affix(affix: StringName) -> void:
	if affix == &"" or affix_ids.has(affix):
		return
	affix_ids.append(affix)
	affix_id = affix_ids[0]

## Two doors with the same signature would look identical to the player.
func signature() -> String:
	return "%s:%s:%s" % [kind_id, variant, "+".join(affix_ids)]

func to_dict() -> Dictionary:
	return {"index": index, "kind": kind_id, "variant": variant, "affix": affix_id, "affixes": affix_ids, "preview": preview}

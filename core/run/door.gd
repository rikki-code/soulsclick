## One choice on the map: a room kind plus its variant and a preview payload for the door icon.
class_name Door
extends RefCounted

var index := 0
var kind_id: StringName = &""
## Enemy id for combat rooms, empty otherwise.
var variant: StringName = &""
var affix_id: StringName = &""
var preview: Dictionary = {}

static func make(p_kind_id: StringName, p_variant: StringName = &"", p_affix_id: StringName = &"") -> Door:
	var door := Door.new()
	door.kind_id = p_kind_id
	door.variant = p_variant
	door.affix_id = p_affix_id
	return door

## Two doors with the same signature would look identical to the player.
func signature() -> String:
	return "%s:%s:%s" % [kind_id, variant, affix_id]

func to_dict() -> Dictionary:
	return {"index": index, "kind": kind_id, "variant": variant, "affix": affix_id, "preview": preview}

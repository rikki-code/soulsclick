## Stand-in modifier for a consumable use: carries the item id so HookApi announces modifier_triggered(item_id).
class_name ItemUseMod
extends Modifier

var _item_id: StringName

func _init(p_item_id: StringName = &"") -> void:
	_item_id = p_item_id

func id() -> StringName:
	return _item_id

## Lists the input schemes by id and builds them. Translation keys follow the id: CONTROLS_<ID>, HINT_<ID>.
## With no saved choice the default is Hands on touch devices (including mobile web) and Buttons elsewhere.
class_name InputSchemeCatalog
extends RefCounted

const DEFAULT_TOUCH := &"hands"
const DEFAULT_POINTER := &"buttons"

static func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in _factories():
		result.append(id)
	return result

static func has(id: StringName) -> bool:
	return _factories().has(id)

static func default_id() -> StringName:
	return DEFAULT_TOUCH if is_touch_device() else DEFAULT_POINTER

static func resolve(saved_id: String) -> StringName:
	var id := StringName(saved_id)
	return id if has(id) else default_id()

static func make(id: StringName) -> InputScheme:
	return _factories()[resolve(String(id))].call()

static func label_key(id: StringName) -> String:
	return "CONTROLS_%s" % String(id).to_upper()

static func hint_key(id: StringName) -> String:
	return "HINT_%s" % String(id).to_upper()

static func is_touch_device() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

static func _factories() -> Dictionary:
	return {&"hands": HandsScheme.new, &"buttons": ButtonsScheme.new, &"swipes": SwipeScheme.new}

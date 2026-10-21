## Turns a room kind id from data into the (stateless) kind object. One line per kind.
class_name RoomKindCatalog
extends RefCounted

static var _factories := {
	FightRoom.ID: func() -> RoomKind: return FightRoom.new(),
	EliteRoom.ID: func() -> RoomKind: return EliteRoom.new(),
	AltarRoom.ID: func() -> RoomKind: return AltarRoom.new(),
	ShopRoom.ID: func() -> RoomKind: return ShopRoom.new(),
	BonfireRoom.ID: func() -> RoomKind: return BonfireRoom.new(),
	BossRoom.ID: func() -> RoomKind: return BossRoom.new(),
}
static var _instances := {}

static func has(kind_id: StringName) -> bool:
	return _factories.has(kind_id)

static func ids() -> Array:
	return _factories.keys()

static func get_kind(kind_id: StringName) -> RoomKind:
	if not has(kind_id):
		push_error("Unknown room kind '%s'" % kind_id)
		return null
	if not _instances.has(kind_id):
		_instances[kind_id] = _factories[kind_id].call()
	return _instances[kind_id]

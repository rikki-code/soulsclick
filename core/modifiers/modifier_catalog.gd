## Turns a modifier id into a fresh instance. One line per relic or affix.
class_name ModifierCatalog
extends RefCounted

static var _relics := {
	MendersThread.ID: func() -> Modifier: return MendersThread.new(),
	GlassBlade.ID: func() -> Modifier: return GlassBlade.new(),
	CounterTide.ID: func() -> Modifier: return CounterTide.new(),
	PhoenixAsh.ID: func() -> Modifier: return PhoenixAsh.new(),
	Overreach.ID: func() -> Modifier: return Overreach.new(),
	DuelistsPride.ID: func() -> Modifier: return DuelistsPride.new(),
}

static var _affixes := {
	SwiftAffix.ID: func() -> Modifier: return SwiftAffix.new(),
	PlatedAffix.ID: func() -> Modifier: return PlatedAffix.new(),
}

static func has(mod_id: StringName) -> bool:
	return _relics.has(mod_id) or _affixes.has(mod_id)

static func relic_ids() -> Array:
	return _relics.keys()

static func affix_ids() -> Array:
	return _affixes.keys()

static func create(mod_id: StringName) -> Modifier:
	if _relics.has(mod_id):
		return _relics[mod_id].call()
	if _affixes.has(mod_id):
		return _affixes[mod_id].call()
	push_error("Unknown modifier '%s'" % mod_id)
	return null

## Ending id -> outcome object. One line per ending.
class_name RunOutcomeCatalog
extends RefCounted

static var _factories := {
	VictoryOutcome.ID: func() -> RunOutcome: return VictoryOutcome.new(),
	DeathOutcome.ID: func() -> RunOutcome: return DeathOutcome.new(),
	AbandonOutcome.ABANDON_ID: func() -> RunOutcome: return AbandonOutcome.new(),
}

static func has(outcome_id: StringName) -> bool:
	return _factories.has(outcome_id)

static func create(outcome_id: StringName) -> RunOutcome:
	if not has(outcome_id):
		push_error("Unknown run outcome '%s'" % outcome_id)
		return null
	return _factories[outcome_id].call()

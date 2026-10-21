## Turns a kind id from data into an AttackKind instance. One line per kind.
class_name AttackKindCatalog
extends RefCounted

static var _factories := {
	QuickAttack.ID: func(step: AttackStepDefinition) -> AttackKind: return QuickAttack.new(step),
	HeavyAttack.ID: func(step: AttackStepDefinition) -> AttackKind: return HeavyAttack.new(step),
	FeintAttack.ID: func(step: AttackStepDefinition) -> AttackKind: return FeintAttack.new(step),
	ComboAttack.ID: func(step: AttackStepDefinition) -> AttackKind: return ComboAttack.new(step),
}

static func has(kind_id: StringName) -> bool:
	return _factories.has(kind_id)

static func create(step: AttackStepDefinition) -> AttackKind:
	if not has(step.kind_id):
		push_error("Unknown attack kind '%s', using quick" % step.kind_id)
		return QuickAttack.new(step)
	return _factories[step.kind_id].call(step)

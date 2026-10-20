## A realm as data: step door tables, enemy pools per room kind, boss and room tuning.
class_name RealmDefinition
extends Resource

@export var id: StringName = &""
@export var name_key := ""
## Tag the view maps to a background and tint; core never holds visuals.
@export var palette_tag: StringName = &""
@export var step_rules: Array[StepRule] = []
@export var fight_pool: Array[RealmEnemyEntry] = []
@export var elite_pool: Array[RealmEnemyEntry] = []
@export var boss: EnemyDefinition
## Endless difficulty curve; a default curve is used when null.
@export var depth_curve: DepthCurve
@export var elite_hp_multiplier := 1.3
@export var elite_souls_multiplier := 2.0
@export var bonfire_heal_share := 0.4
@export var boss_heal_share := 0.3
@export var altar_offer_size := 3
@export var shop_offer_size := 3
@export var shop_heal_price := 30
@export var shop_reroll_price := 15
## Chance a normal fight also offers a relic-or-heal pick.
@export var fight_pick_chance := 0.4

var _fallback_curve: DepthCurve

func curve() -> DepthCurve:
	if depth_curve != null:
		return depth_curve
	if _fallback_curve == null:
		_fallback_curve = DepthCurve.new()
	return _fallback_curve

func step_count() -> int:
	return step_rules.size()

func rule_at(step: int) -> StepRule:
	return step_rules[clampi(step, 0, step_rules.size() - 1)]

## Realm guarantees as readable problems; empty when the definition is sound.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if step_rules.is_empty():
		problems.append("no steps")
		return problems
	if boss == null:
		problems.append("no boss")
	var required := {}
	for step in step_rules.size():
		var rule := step_rules[step]
		for kind_id in rule.kind_weights:
			if not RoomKindCatalog.has(StringName(kind_id)):
				problems.append("step %d: unknown kind %s" % [step, kind_id])
		for kind_id in rule.required_kinds:
			required[kind_id] = true
	for kind_id in [&"elite", &"bonfire", &"altar"]:
		if not required.has(kind_id):
			problems.append("no step requires %s" % kind_id)
	var last := step_rules[-1]
	if last.required_kinds.size() != 1 or last.required_kinds[0] != &"boss" or last.kind_weights.size() != 1:
		problems.append("last step must offer only the boss")
	return problems

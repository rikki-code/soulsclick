## One levelable stat: gain per level and the price curve (cost = base * growth ^ current_level).
class_name StatLevelDef
extends Resource

## A CombatStats id (max_hp, max_stamina, attack_damage, stamina_regen).
@export var stat: StringName
## Added to the stat (ADD stage) for every level.
@export var increment := 1.0
@export var cost_base := 10.0
@export var cost_growth := 1.3

func cost_at(level: int) -> int:
	return maxi(roundi(cost_base * pow(cost_growth, level)), 1)

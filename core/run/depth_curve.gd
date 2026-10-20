## Endless difficulty as data: exponential growth per node (rooms entered), extra factors for elites and bosses,
## and how affix chances grow with depth (realms completed). Referenced by `RealmDefinition.depth_curve`.
class_name DepthCurve
extends Resource

## Enemy hp and damage multiplier per node: growth ^ node.
@export var hp_growth := 1.12
@export var damage_growth := 1.12
## Souls reward growth per node (slower than stats so the economy keeps up).
@export var souls_growth := 1.08
## Extra factors on top of the realm's own elite/boss tuning.
@export var elite_hp_factor := 1.0
@export var elite_damage_factor := 1.1
@export var boss_hp_factor := 1.25
@export var boss_damage_factor := 1.15
## Normal fights roll one affix from depth `fight_affix_depth`.
@export var fight_affix_depth := 1
@export var fight_affix_chance := 0.2
@export var fight_affix_chance_per_depth := 0.1
@export var fight_affix_chance_max := 0.6
## Elites roll a second affix from depth `double_affix_depth`.
@export var double_affix_depth := 2
@export var double_affix_chance := 0.3
@export var double_affix_chance_per_depth := 0.1
@export var double_affix_chance_max := 0.7
## Waves (enemies fought back to back in one room). Fights: 1 enemy for the first `wave_solo_nodes` nodes of depth 0, then
## 1..2; the range grows with depth (low end every `wave_min_depth_step` depths, high end every `wave_max_depth_step`), capped.
@export var wave_solo_nodes := 2
@export var wave_max_size := 4
@export var wave_min_depth_step := 3
@export var wave_max_depth_step := 2
## Elites bring one extra normal enemy with this chance from depth `elite_wave_depth`.
@export var elite_wave_depth := 1
@export var elite_wave_chance := 0.5
@export var elite_wave_chance_per_depth := 0.1
@export var elite_wave_chance_max := 1.0

func hp_multiplier(node: int) -> float:
	return pow(hp_growth, maxi(node, 0))

func damage_multiplier(node: int) -> float:
	return pow(damage_growth, maxi(node, 0))

func souls_multiplier(node: int) -> float:
	return pow(souls_growth, maxi(node, 0))

func combat_level(depth: int) -> int:
	return maxi(depth, 0) + 1

func fight_affix_chance_at(depth: int) -> float:
	return _chance(depth, fight_affix_depth, fight_affix_chance, fight_affix_chance_per_depth, fight_affix_chance_max)

func double_affix_chance_at(depth: int) -> float:
	return _chance(depth, double_affix_depth, double_affix_chance, double_affix_chance_per_depth, double_affix_chance_max)

static func _chance(depth: int, start: int, base: float, per_depth: float, top: float) -> float:
	if depth < start:
		return 0.0
	return minf(base + per_depth * (depth - start), top)

## Inclusive wave size range of a normal fight.
func fight_wave_range(depth: int, node: int) -> Vector2i:
	if depth <= 0 and node < wave_solo_nodes:
		return Vector2i(1, 1)
	var high := mini(2 + maxi(depth, 0) / maxi(wave_max_depth_step, 1), wave_max_size)
	var low := mini(1 + maxi(depth, 0) / maxi(wave_min_depth_step, 1), high)
	return Vector2i(low, high)

func elite_wave_chance_at(depth: int) -> float:
	return _chance(depth, elite_wave_depth, elite_wave_chance, elite_wave_chance_per_depth, elite_wave_chance_max)

## One side of the duel: numbers plus a state object. Stamina is used by the player only.
class_name Fighter
extends RefCounted

const PLAYER := &"player"
const ENEMY := &"enemy"

var side: StringName
var max_hp: int
var hp: int
var max_stamina: float
var stamina: float
var stamina_regen: float
var damage: int
var state: FighterState = IdleState.new()
var state_elapsed := 0.0
var block_cooldown := 0.0

func _init(p_side: StringName, p_max_hp: int, p_damage: int, p_max_stamina: float = 0.0, p_stamina_regen: float = 0.0) -> void:
	side = p_side
	max_hp = p_max_hp
	hp = p_max_hp
	damage = p_damage
	max_stamina = p_max_stamina
	stamina = p_max_stamina
	stamina_regen = p_stamina_regen

static func make_player(tuning: CombatTuning) -> Fighter:
	return Fighter.new(PLAYER, tuning.player_hp, tuning.player_damage, tuning.player_stamina, tuning.stamina_regen)

static func make_enemy(definition: EnemyDefinition, scaling: CombatScaling) -> Fighter:
	return Fighter.new(ENEMY, scaling.enemy_hp(definition.hp), scaling.enemy_damage(definition.damage))

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)

func spend_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)

func advance(duel: Duel, dt: float) -> void:
	state_elapsed += dt
	block_cooldown = maxf(block_cooldown - dt, 0.0)
	stamina = minf(stamina + stamina_regen * state.stamina_regen_factor() * dt, max_stamina)
	state.advance(duel, self, dt)
	if state_elapsed >= state.duration():
		state.on_finished(duel, self)

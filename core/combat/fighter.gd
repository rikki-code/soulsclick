## One side of the duel: resolved stats, modifiers, hp, stamina and a state object. Stamina is used by the
## player only.
class_name Fighter
extends RefCounted

const PLAYER := &"player"
const ENEMY := &"enemy"

var side: StringName
var hp: int
var stamina: float
var state: FighterState = IdleState.new()
var state_elapsed := 0.0
var block_cooldown := 0.0
var holding_block := false
var mods: ModifierStack
var stats: CombatStats

var max_hp: int:
	get:
		return stats.int_value(CombatStats.MAX_HP)
	set(value):
		stats.set_base(CombatStats.MAX_HP, value)
var max_stamina: float:
	get:
		return stats.value(CombatStats.MAX_STAMINA)
	set(value):
		stats.set_base(CombatStats.MAX_STAMINA, value)
var stamina_regen: float:
	get:
		return stats.value(CombatStats.STAMINA_REGEN)
	set(value):
		stats.set_base(CombatStats.STAMINA_REGEN, value)
## Base attack damage; setting it overrides the base value (modifiers still apply on top).
var damage: int:
	get:
		return stats.int_value(CombatStats.ATTACK_DAMAGE)
	set(value):
		stats.set_base(CombatStats.ATTACK_DAMAGE, value)

var _last_max_hp: int
var _last_max_stamina: float

func _init(p_side: StringName, p_max_hp: int, p_damage: int, p_max_stamina: float = 0.0, p_stamina_regen: float = 0.0) -> void:
	side = p_side
	mods = ModifierStack.new(self)
	stats = CombatStats.new(self, mods)
	stats.load_base({
		CombatStats.MAX_HP: float(p_max_hp),
		CombatStats.ATTACK_DAMAGE: float(p_damage),
		CombatStats.MAX_STAMINA: p_max_stamina,
		CombatStats.STAMINA_REGEN: p_stamina_regen,
	})
	reset_pools()
	mods.changed.connect(_on_mods_changed)

static func make_player(tuning: CombatTuning) -> Fighter:
	var fighter := Fighter.new(PLAYER, tuning.player_hp, tuning.player_damage, tuning.player_stamina, tuning.stamina_regen)
	fighter.stats.load_base(CombatStats.tuning_base(tuning))
	fighter.reset_pools()
	return fighter

static func make_enemy(definition: EnemyDefinition, scaling: CombatScaling, tuning: CombatTuning = null) -> Fighter:
	var fighter := Fighter.new(ENEMY, scaling.enemy_hp(definition.hp), scaling.enemy_damage(definition.damage))
	if tuning != null:
		var base := CombatStats.tuning_base(tuning)
		base[CombatStats.MAX_HP] = float(scaling.enemy_hp(definition.hp))
		base[CombatStats.ATTACK_DAMAGE] = float(scaling.enemy_damage(definition.damage))
		fighter.stats.load_base(base)
		fighter.reset_pools()
	return fighter

func reset_pools() -> void:
	_last_max_hp = max_hp
	_last_max_stamina = max_stamina
	hp = _last_max_hp
	stamina = _last_max_stamina

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)

func heal(amount: int) -> void:
	if is_alive():
		hp = mini(hp + amount, max_hp)

func spend_stamina(amount: float) -> void:
	stamina = maxf(stamina - amount, 0.0)

func advance(duel: Duel, dt: float) -> void:
	state_elapsed += dt
	block_cooldown = maxf(block_cooldown - dt, 0.0)
	stamina = minf(stamina + stamina_regen * state.stamina_regen_factor() * dt, max_stamina)
	state.advance(duel, self, dt)
	if state_elapsed >= state.duration():
		state.on_finished(duel, self)

func _on_mods_changed() -> void:
	stats.invalidate()
	var new_hp := max_hp
	if is_alive():
		hp = clampi(hp + new_hp - _last_max_hp, 1, new_hp)
	_last_max_hp = new_hp
	var new_stamina := max_stamina
	stamina = clampf(stamina + new_stamina - _last_max_stamina, 0.0, new_stamina)
	_last_max_stamina = new_stamina

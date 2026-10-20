## Every global combat number in one Resource (data/tuning/default_tuning.tres). Enemy numbers live in
## EnemyDefinition / AttackStepDefinition; level scaling goes through CombatScaling.
class_name CombatTuning
extends Resource

@export_group("Player base stats")
@export var player_hp := 100
@export var player_stamina := 100.0
@export var player_damage := 10

@export_group("Timing")
## A block pressed at most this long before the strike is a parry.
@export var parry_window := 0.25
@export var block_duration := 0.5
## Time after a block ends during which block cannot be pressed again.
@export var block_cooldown := 0.35
## Recovery lock after an attack; the hit itself lands when the attack is accepted.
@export var attack_duration := 0.45
@export var stagger_time := 1.6

@export_group("Stamina")
@export var attack_stamina_cost := 22.0
@export var block_stamina_cost := 18.0
@export var stamina_regen := 28.0

@export_group("Damage")
## Player damage multiplier while the target is staggered.
@export var punish_multiplier := 2.0
## Share of strike damage taken through a plain block.
@export var chip_damage_share := 0.25
## Share of heavy strike damage taken when a plain block fails to hold.
@export var guard_break_damage_share := 0.6

@export_group("Level scaling")
@export var enemy_hp_growth := 0.25
@export var enemy_damage_growth := 0.15
@export var enemy_souls_growth := 0.2

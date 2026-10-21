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
## Seconds after the press before the guard is up; a strike landing earlier hits.
@export var block_startup := 0.0
## Minimum time the guard stays up after the press (block_min_duration).
@export var block_duration := 0.5
## Time after a block ends during which block cannot be pressed again.
@export var block_cooldown := 0.35
## Recovery lock after an attack; the hit itself lands when the attack is accepted.
@export var attack_duration := 0.45
@export var stagger_time := 1.6
## Share of the parry window (late end) that counts as a perfect parry.
@export var perfect_threshold := 0.8
## Pause of the enemy after the player was revived.
@export var revive_grace := 1.5

@export_group("Stamina")
@export var attack_stamina_cost := 22.0
## Stamina per point of strike damage absorbed by a block; 0 stamina left = guard break.
@export var block_stamina_cost := 1.35
@export var stamina_regen := 28.0

@export_group("Damage")
## Player damage multiplier while the target is staggered.
@export var punish_multiplier := 2.0
## Share of strike damage taken through a plain block.
@export var chip_damage_share := 0.05
## Share of heavy strike damage taken when a plain block fails to hold.
@export var guard_break_damage_share := 0.6
## One enemy hit takes at most this share of the player's max hp (stat `max_hit_share`; >= 1 disables).
@export var max_hit_share := 0.35

@export_group("Level scaling")
@export var enemy_hp_growth := 0.25
@export var enemy_damage_growth := 0.15
@export var enemy_souls_growth := 0.2

@export_group("Combo")
## Damage bonus per counted consecutive hit without taking damage (0.1 = +10%).
@export var combo_step := 0.1
@export var combo_max_multiplier := 3.0
## A hit on a staggered enemy (crit) counts this many times.
@export var combo_crit_weight := 2
## Clicker income (Souls): per player hit (x combo multiplier; fractions carry over) and per parry.
@export var souls_per_hit := 0.2
@export var souls_per_parry := 2.0

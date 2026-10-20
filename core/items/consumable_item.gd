## Used mid-fight (Duel.use_item), carried in the run. Generic effect fields, all optional; a new kind of
## effect = a subclass overriding use(). Effects go through ctx.fx (HookApi), so they are procs.
class_name ConsumableItem
extends ItemDefinition

## Charges added by one purchase, and the most the inventory holds.
@export var charges_per_buy := 1
@export var max_charges := 6
@export_range(0.0, 1.0) var heal_share := 0.0
@export var damage := 0
@export var stagger := 0.0
@export_range(0.0, 1.0) var stamina_share := 0.0

func is_consumable() -> bool:
	return true

func use(ctx: HookCtx) -> void:
	if heal_share > 0.0:
		ctx.fx.heal(ctx.side, ceili(ctx.owner.max_hp * heal_share))
	if stamina_share > 0.0:
		ctx.fx.add_stamina(ctx.side, ctx.owner.max_stamina * stamina_share)
	if damage > 0:
		ctx.fx.damage(Fighter.ENEMY, damage)
	if stagger > 0.0 and ctx.foe.is_alive():
		ctx.fx.stagger(Fighter.ENEMY, stagger)

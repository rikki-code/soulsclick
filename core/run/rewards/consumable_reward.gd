## Extra charges of a consumable item (flask, bomb).
class_name ConsumableReward
extends RewardKind

const ID := &"consumable"

func id() -> StringName:
	return ID

func make_cards(_run: Run, _plan: RoomPlan, rng: RandomNumberGenerator, ctx: RewardContext) -> Array[RewardCard]:
	var defs: Array = ItemCatalog.all().filter(func(d: ItemDefinition) -> bool: return d is ConsumableItem)
	var charges := RewardTuning.current().consumable_charges
	var cards: Array[RewardCard] = []
	for def: ConsumableItem in shuffled(defs, rng):
		if ctx != null and ctx.inventory != null and ctx.inventory.charges(def.id) >= def.max_charges:
			continue
		cards.append(_card(def.id, def.name_key, def.desc_key, [], {"item_id": def.id, "charges": charges, "icon": def.icon}, def.icon_path))
	return cards

func apply(_run: Run, card: RewardCard, ctx: RewardContext) -> bool:
	return ctx != null and ctx.inventory != null and ctx.inventory.grant(card.payload["item_id"], int(card.payload["charges"]))

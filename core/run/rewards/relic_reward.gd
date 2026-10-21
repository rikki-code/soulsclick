## A relic from ModifierCatalog the player does not own yet.
class_name RelicReward
extends RewardKind

const ID := &"relic"
const FALLBACK_ICON := "res://view/packs/icon_pack/silhouette_pack/rewards/relic.svg"
const ICON_DIR := "res://view/packs/icon_pack/silhouette_pack/relics/"

func id() -> StringName:
	return ID

func make_cards(_run: Run, _plan: RoomPlan, rng: RandomNumberGenerator, ctx: RewardContext) -> Array[RewardCard]:
	var cards: Array[RewardCard] = []
	for relic_id in shuffled(ModifierCatalog.relic_ids(), rng):
		if ctx != null and ctx.has_relic(relic_id):
			continue
		var key := "RELIC_" + String(relic_id).to_upper()
		var icon := ICON_DIR + String(relic_id) + ".svg"
		cards.append(_card(relic_id, key, key + "_DESC", [], {"relic_id": relic_id}, icon if ResourceLoader.exists(icon) else FALLBACK_ICON))
	return cards

func apply(_run: Run, card: RewardCard, ctx: RewardContext) -> bool:
	return ctx != null and ctx.add_relic(card.payload["relic_id"])

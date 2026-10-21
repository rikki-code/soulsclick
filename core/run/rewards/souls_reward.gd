## Flat Souls, scaled by the depth curve like fight income.
class_name SoulsReward
extends RewardKind

const ID := &"souls"
const ICON := "res://view/packs/icon_pack/silhouette_pack/rewards/souls.svg"

func id() -> StringName:
	return ID

func make_cards(run: Run, plan: RoomPlan, _rng: RandomNumberGenerator, _ctx: RewardContext) -> Array[RewardCard]:
	var amount := maxi(roundi(RewardTuning.current().souls_base * run.curve().souls_multiplier(plan.node)), 1)
	return [_card(ID, "REWARD_CARD_SOULS", "REWARD_CARD_SOULS_DESC", [amount], {"amount": amount}, ICON)]

func apply(run: Run, card: RewardCard, _ctx: RewardContext) -> bool:
	run.add_souls(int(card.payload["amount"]))
	return true

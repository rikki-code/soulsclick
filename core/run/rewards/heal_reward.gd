## Restores a share of max HP.
class_name HealReward
extends RewardKind

const ID := &"heal"
const ICON := "res://view/packs/icon_pack/silhouette_pack/rewards/heal.svg"

func id() -> StringName:
	return ID

func make_cards(_run: Run, _plan: RoomPlan, _rng: RandomNumberGenerator, _ctx: RewardContext) -> Array[RewardCard]:
	var share := RewardTuning.current().heal_share
	return [_card(ID, "REWARD_CARD_HEAL", "REWARD_CARD_HEAL_DESC", [roundi(share * 100.0)], {"share": share}, ICON)]

func apply(run: Run, card: RewardCard, _ctx: RewardContext) -> bool:
	run.heal(ceili(run.config.max_hp * float(card.payload["share"])))
	return true

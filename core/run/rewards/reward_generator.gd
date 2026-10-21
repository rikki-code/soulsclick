## Builds the reward offer of a won room from the seed only: same seed + depth + step = same offer, whatever was picked before.
## `ctx` (optional) only filters: owned relics and full consumables are skipped after the random draw.
class_name RewardGenerator
extends RefCounted

const _KIND_PICK_STREAM := 1000

static func generate(run: Run, plan: RoomPlan, ctx: RewardContext = null) -> RewardOffer:
	var offer := RewardOffer.new()
	if not plan.is_combat:
		return offer
	var tuning := RewardTuning.current()
	var seed_value := run.config.seed
	var order := RewardKind.shuffled(tuning.kinds_for(plan.kind_id), RunRng.stream(seed_value, RunRng.REWARD_CHOICE, plan.depth, plan.step_index, _KIND_PICK_STREAM))
	var wanted := tuning.count_for(plan.kind_id)
	for kind_id in order:
		if offer.cards.size() >= wanted:
			break
		var kind := RewardKindCatalog.get_kind(kind_id)
		if kind == null:
			continue
		var rng := RunRng.stream(seed_value, RunRng.REWARD_CHOICE, plan.depth, plan.step_index, RewardKindCatalog.ids().find(kind_id))
		var cards := kind.make_cards(run, plan, rng, ctx)
		if not cards.is_empty():
			offer.cards.append(cards[0])
	return offer

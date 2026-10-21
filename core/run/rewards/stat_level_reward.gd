## +1 run level of one stat (same levels the player buys with Souls).
class_name StatLevelReward
extends RewardKind

const ID := &"stat_level"
const ICON_DIR := "res://view/packs/icon_pack/silhouette_pack/rewards/"
const TABLE_PATH := "res://data/progression/run_levels.tres"

func id() -> StringName:
	return ID

func make_cards(_run: Run, _plan: RoomPlan, rng: RandomNumberGenerator, ctx: RewardContext) -> Array[RewardCard]:
	var table: StatLevelTable = ctx.run_levels.table if ctx != null and ctx.run_levels != null else load(TABLE_PATH)
	var cards: Array[RewardCard] = []
	for stat in shuffled(table.stat_ids(), rng):
		var key := "REWARD_STAT_" + String(stat).to_upper()
		var icon := ICON_DIR + "stat_" + String(stat) + ".svg"
		cards.append(_card(stat, key, key + "_DESC", [int(table.def_of(stat).increment)], {"stat": stat}, icon if ResourceLoader.exists(icon) else ""))
	return cards

func apply(_run: Run, card: RewardCard, ctx: RewardContext) -> bool:
	return ctx != null and ctx.run_levels != null and ctx.run_levels.level_up(card.payload["stat"])

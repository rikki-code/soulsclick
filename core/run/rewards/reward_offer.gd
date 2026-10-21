## The cards offered after a room. Pick one (`is_pick_one`); the game layer calls `apply(index, run, ctx)` once.
class_name RewardOffer
extends RefCounted

var cards: Array[RewardCard] = []
var is_pick_one := true
## Index of the applied card, -1 while open.
var chosen := -1

func is_open() -> bool:
	return chosen < 0 and not cards.is_empty()

## Gives card `index` to the run / context. False = bad index, already taken, or refused.
func apply(index: int, run: Run, ctx: RewardContext) -> bool:
	if not is_open() or index < 0 or index >= cards.size():
		return false
	var card := cards[index]
	var kind := RewardKindCatalog.get_kind(card.kind_id)
	if kind == null or not kind.apply(run, card, ctx):
		return false
	chosen = index
	return true

func to_dict() -> Dictionary:
	return {"pick_one": is_pick_one, "chosen": chosen, "cards": cards.map(func(c: RewardCard) -> Dictionary: return c.to_dict())}

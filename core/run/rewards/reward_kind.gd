## Base of a reward kind. Kinds are stateless; every hook has a default.
class_name RewardKind
extends RefCounted

func id() -> StringName:
	return &""

func tag_key() -> String:
	return "REWARD_KIND_" + String(id()).to_upper()

## Candidate cards, best first (the generator takes the first). `rng` is this kind's own seeded stream, drawn from
## regardless of `ctx`, so ctx (null in previews) only filters. Empty = nothing to offer.
func make_cards(_run: Run, _plan: RoomPlan, _rng: RandomNumberGenerator, _ctx: RewardContext) -> Array[RewardCard]:
	return []

## Gives the card's reward. False = refused (nothing changed).
func apply(_run: Run, _card: RewardCard, _ctx: RewardContext) -> bool:
	return false

func _card(card_id: StringName, name_key: String, info_key: String, info_args: Array, payload: Dictionary, icon_path := "") -> RewardCard:
	var card := RewardCard.new()
	card.id = card_id
	card.kind_id = id()
	card.tag_key = tag_key()
	card.name_key = name_key
	card.info_key = info_key
	card.info_args = info_args
	card.payload = payload
	card.icon_path = icon_path
	return card

## Deterministic shuffle of `list` on `rng`.
static func shuffled(list: Array, rng: RandomNumberGenerator) -> Array:
	var result := list.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result

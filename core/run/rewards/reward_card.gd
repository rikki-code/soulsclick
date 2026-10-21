## One choice of a reward offer. Plain data: the view shows tag/name/info/icon, `RewardOffer.apply` does the rest.
class_name RewardCard
extends RefCounted

var id: StringName = &""
var kind_id: StringName = &""
## Locale keys; `*_args` fill the `%` placeholders of the translated text (numbers only).
var tag_key := ""
var name_key := ""
var info_key := ""
var info_args: Array = []
## Empty when the card has no art; the view may fall back to payload ids.
var icon_path := ""
## Kind specific plain data (relic_id, stat, item_id, amount, share).
var payload: Dictionary = {}

func title() -> String:
	return TranslationServer.translate(name_key)

func info() -> String:
	var text := TranslationServer.translate(info_key)
	return text % info_args if not info_args.is_empty() else text

func to_dict() -> Dictionary:
	return {"id": id, "kind": kind_id, "name_key": name_key, "info_key": info_key, "info_args": info_args, "icon": icon_path, "payload": payload}

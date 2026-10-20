## Door choice: one big button per door with kind, enemy, affix and the reward preview.
class_name DoorsScreen
extends RunScreen

signal door_picked(index: int)

func setup(run: Run) -> DoorsScreen:
	var offer := run.offer
	_build(tr(run.realm().name_key))
	_text(tr("DOORS_PROGRESS") % [offer.step_index + 1, offer.step_count], 30, MUTED)
	_status(run)
	var path := PathView.new().setup(run)
	path.door_picked.connect(func(index: int) -> void: door_picked.emit(index))
	_page.add_child(path)
	for door in offer.doors:
		var index := door.index
		var button := _button(DoorsScreen.door_line(door), func() -> void: door_picked.emit(index), MenuKit.ROW_HEIGHT)
		button.add_theme_font_size_override("font_size", 26)
		button.clip_text = true
	return self

## One-line summary for the compact door buttons under the map.
static func door_line(door: Door) -> String:
	var lines := door_text(door).split("\n")
	return lines[0] if lines.size() == 1 else "%s | %s" % [lines[0], lines[-1].split(", ")[0]]

static func door_text(door: Door) -> String:
	var lines: Array[String] = []
	var title := RunScreen.kind_name(door.kind_id)
	if door.preview.has("name_key"):
		title += ": " + TranslationServer.translate(door.preview["name_key"])
	lines.append(title)
	var affixes: Array[String] = []
	for affix_id in door.affix_ids:
		affixes.append(RunScreen.affix_name(affix_id))
	if not affixes.is_empty():
		lines.append(", ".join(affixes))
	var rewards: Array[String] = []
	for reward: Dictionary in door.preview.get("rewards", []):
		var text := DoorsScreen.reward_text(reward)
		if text != "":
			rewards.append(text)
	if not rewards.is_empty():
		lines.append(", ".join(rewards))
	return "\n".join(lines)

static func reward_text(reward: Dictionary) -> String:
	match StringName(reward.get("id", "")):
		&"souls":
			return TranslationServer.translate("REWARD_SOULS") % int(reward.get("amount", 0))
		&"heal":
			return TranslationServer.translate("REWARD_HEAL") % roundi(float(reward.get("share", 0.0)) * 100.0)
		&"relic_offer":
			return TranslationServer.translate("REWARD_RELIC")
		&"relic_or_heal":
			return TranslationServer.translate("REWARD_ALTAR")
		&"shop":
			return TranslationServer.translate("REWARD_SHOP")
	# Unknown reward ids are internal: show nothing rather than a raw id.
	return ""

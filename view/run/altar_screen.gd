## Altar room: spend run Souls on stat levels and run-long buffs, then leave. GameRoot owns the purchases and
## rebuilds the screen after each one.
class_name AltarScreen
extends RunScreen

signal level_requested(stat: StringName)
signal buff_requested(item_id: StringName)
signal leave_requested

## `levels` rows: {id, name, value, next, price, affordable, ad}; `buffs` rows: {id, name, info, price, affordable, ad}.
func setup(run: Run, levels: Array[Dictionary], buffs: Array[Dictionary]) -> AltarScreen:
	_build(RunScreen.kind_name(AltarRoom.ID))
	_status(run)
	_text(tr("ALTAR_HINT"), 32, MUTED)
	for row in levels:
		var text := tr("ALTAR_LEVEL") % [row["name"], row["value"], row["next"], row["price"]]
		_offer(text, row, level_requested.emit.bind(row["id"]))
	for row in buffs:
		var text := tr("ALTAR_BUFF") % [row["name"], row["info"], row["price"]]
		_offer(text, row, buff_requested.emit.bind(row["id"]))
	_button(tr("ALTAR_LEAVE"), leave_requested.emit, BIG_BUTTON_HEIGHT)
	return self

func _offer(text: String, row: Dictionary, on_pressed: Callable) -> void:
	var ad := bool(row.get("ad", false))
	var button := _button(text + tr("ALTAR_WATCH_AD") if ad else text, on_pressed)
	button.disabled = not (bool(row["affordable"]) or ad)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

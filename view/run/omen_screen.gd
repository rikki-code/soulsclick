## Start of a run: pick one of two omens (each favors two tags).
class_name OmenScreen
extends RunScreen

signal omen_picked(index: int)

func setup(omens: Array[Omen]) -> OmenScreen:
	_build(tr("OMEN_TITLE"))
	_text(tr("OMEN_HINT"), 30, MUTED)
	for i in omens.size():
		var names: Array[String] = []
		for tag in omens[i].tags:
			names.append(tr("TAG_" + String(tag).to_upper()))
		_button(" + ".join(names), func() -> void: omen_picked.emit(i), BIG_BUTTON_HEIGHT)
	return self

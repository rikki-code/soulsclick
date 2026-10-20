## After a boss: end the journey and bank every Soul, or go one realm deeper and risk them all.
class_name CrossroadsScreen
extends RunScreen

signal retire_requested
signal deeper_requested

func setup(run: Run) -> CrossroadsScreen:
	_build(tr("CROSSROADS_TITLE"))
	_status(run)
	_text(tr("CROSSROADS_HINT"), 32, MUTED)
	_button(tr("CROSSROADS_RETIRE") % run.souls, retire_requested.emit, BIG_BUTTON_HEIGHT)
	_button(tr("CROSSROADS_DEEPER") % (run.depth + 1), deeper_requested.emit, BIG_BUTTON_HEIGHT)
	return self

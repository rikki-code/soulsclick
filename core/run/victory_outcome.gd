## Final boss defeated: all Souls become Embers.
class_name VictoryOutcome
extends RunOutcome

const ID := &"victory"

func id() -> StringName:
	return ID

func is_victory() -> bool:
	return true

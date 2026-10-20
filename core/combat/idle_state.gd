class_name IdleState
extends FighterState

const ID := &"idle"

func id() -> StringName:
	return ID

func can_act() -> bool:
	return true

func stamina_regen_factor() -> float:
	return 1.0

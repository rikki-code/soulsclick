## A chain of strikes, each with its own windup (step.telegraph_times). A parry on any strike ends the chain.
class_name ComboAttack
extends AttackKind

const ID := &"combo"

func id() -> StringName:
	return ID

func strike_count() -> int:
	return maxi(step.telegraph_times.size(), 1)

func telegraph_time(index: int) -> float:
	if index >= step.telegraph_times.size():
		return step.telegraph_time
	return step.telegraph_times[index]

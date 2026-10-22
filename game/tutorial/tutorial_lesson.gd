## One tutorial lesson: a short script that starts a fight (or a road event), guides the player and returns when the
## goal is reached. Subclasses override id() and play(); they use only the host and Duel signals.
class_name TutorialLesson
extends RefCounted

## Never emitted: the default play() waits on it so it is a coroutine like every override.
signal _unplayed

func id() -> StringName:
	return &""

## Coroutine: plays the lesson to its end.
func play(_host: TutorialHost) -> void:
	await _unplayed

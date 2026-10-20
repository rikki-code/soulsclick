## How a run ended and how much of the Souls turn into Embers. Subclass per ending.
class_name RunOutcome
extends RefCounted

func id() -> StringName:
	return &""

func is_victory() -> bool:
	return false

func bank_rate(_config: RunConfig) -> float:
	return 1.0

## Flat Embers on top of the conversion (victory bonus later).
func bonus_embers(_run: Run) -> int:
	return 0

func embers(run: Run) -> int:
	return floori(run.souls * bank_rate(run.config)) + bonus_embers(run)

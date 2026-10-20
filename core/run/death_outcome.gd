## Hp reached 0: Souls convert at the config bank rate (50% base).
class_name DeathOutcome
extends RunOutcome

const ID := &"death"

func id() -> StringName:
	return ID

func bank_rate(config: RunConfig) -> float:
	return config.death_bank_rate

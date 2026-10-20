## End-of-run data for the end screen and the profile (Embers are computed here, applied by the game layer).
class_name RunSummary
extends RefCounted

var outcome_id: StringName = &""
var victory := false
var seed_code := ""
var omen_id: StringName = &""
## 1-based realm the run ended in.
var realm_reached := 0
var realm_count := 0
var step_reached := 0
var rooms_cleared := 0
var souls := 0
var bank_rate := 0.0
var embers := 0
## Enemy id that ended a death run, empty otherwise.
var killer_enemy_id: StringName = &""
var history: Array[Dictionary] = []

static func build(run: Run, outcome: RunOutcome) -> RunSummary:
	var summary := RunSummary.new()
	summary.outcome_id = outcome.id()
	summary.victory = outcome.is_victory()
	summary.seed_code = SeedCode.encode(run.config.seed)
	summary.omen_id = run.omen.id if run.omen != null else &""
	summary.realm_count = run.realms.size()
	summary.realm_reached = mini(run.realm_index + 1, run.realms.size())
	summary.step_reached = run.step_index
	summary.rooms_cleared = run.history.size()
	summary.souls = run.souls
	summary.bank_rate = outcome.bank_rate(run.config)
	summary.embers = outcome.embers(run)
	summary.killer_enemy_id = run.killer_enemy_id
	summary.history = run.history.duplicate(true)
	return summary

func to_dict() -> Dictionary:
	return {
		"outcome": outcome_id, "victory": victory, "seed_code": seed_code, "omen": omen_id,
		"realm_reached": realm_reached, "realm_count": realm_count, "step_reached": step_reached,
		"rooms_cleared": rooms_cleared, "souls": souls, "bank_rate": bank_rate, "embers": embers,
		"killer_enemy": killer_enemy_id, "history": history,
	}

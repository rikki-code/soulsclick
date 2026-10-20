## State that outlives a scene reload: the loaded profile, how the game scene should start, and the revive count of the run.
class_name GameSession
extends RefCounted

const ENEMY_ORDER: Array[StringName] = [&"grunt", &"knight", &"warden"]
const ENEMY_DIR := "res://data/enemies/"
const PERMANENT_LEVELS_PATH := "res://data/progression/permanent_levels.tres"
const RUN_LEVELS_PATH := "res://data/progression/run_levels.tres"

## What the game scene does on load.
enum Launch { NEW_RUN, CONTINUE_RUN }

static var launch := Launch.NEW_RUN
## Legacy single-enemy index (dev `--enemy` flag, tests); the run layer picks enemies from the room plan.
static var run_index := 0
## Revives taken so far in the run (saved with the run); the k-th costs k rewarded ads, capped at MAX_REVIVE_ADS.
static var revives_used := 0
## One revive per fight: set by use_revive, cleared when a new fight starts.
static var fight_revived := false
const MAX_REVIVE_ADS := 3
static var _profile: ProfileData

static func profile() -> ProfileData:
	if _profile == null:
		_profile = SaveStore.load_profile()
	return _profile

static func save_profile() -> bool:
	return SaveStore.save_profile(profile())

static func permanent_table() -> StatLevelTable:
	return load(PERMANENT_LEVELS_PATH) as StatLevelTable

static func run_table() -> StatLevelTable:
	return load(RUN_LEVELS_PATH) as StatLevelTable

static func current_enemy_id() -> StringName:
	return ENEMY_ORDER[clampi(run_index, 0, ENEMY_ORDER.size() - 1)]

static func current_enemy() -> EnemyDefinition:
	return load("%s%s.tres" % [ENEMY_DIR, current_enemy_id()]) as EnemyDefinition

static func has_next_enemy() -> bool:
	return run_index + 1 < ENEMY_ORDER.size()

static func advance_run() -> void:
	run_index += 1

static func reset_run() -> void:
	run_index = 0
	revives_used = 0
	fight_revived = false

static func begin_fight() -> void:
	fight_revived = false

static func can_revive() -> bool:
	return not fight_revived

## Rewarded ads the next revive costs.
static func revive_ads() -> int:
	return clampi(revives_used + 1, 1, MAX_REVIVE_ADS)

static func use_revive() -> void:
	revives_used += 1
	fight_revived = true

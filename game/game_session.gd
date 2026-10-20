## State that outlives a scene reload: the loaded profile and the current run (enemy order, position, revive).
class_name GameSession
extends RefCounted

const ENEMY_ORDER: Array[StringName] = [&"grunt", &"knight", &"warden"]
const ENEMY_DIR := "res://data/enemies/"

static var run_index := 0
static var revive_used := false
static var _profile: ProfileData

static func profile() -> ProfileData:
	if _profile == null:
		_profile = SaveStore.load_profile()
	return _profile

static func save_profile() -> bool:
	return SaveStore.save_profile(profile())

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
	revive_used = false

static func can_revive() -> bool:
	return not revive_used

static func use_revive() -> void:
	revive_used = true

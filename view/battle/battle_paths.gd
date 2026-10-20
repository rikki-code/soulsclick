## Active enemy, background and player packs for the battle screen (same idea as PackPaths, kept local to the battle view).
class_name BattlePaths
extends RefCounted

const ENEMY_PACK := "res://view/packs/enemy_pack/silhouette_pack/"
const BACKGROUND_PACK := "res://view/packs/background_pack/silhouette_pack/"
const PLAYER_PACK := "res://view/packs/player_pack/silhouette_pack/"
const RIG_FILE := "rig.json"

static func rig_json(enemy_id: StringName) -> String:
	return "%s%s/%s" % [ENEMY_PACK, enemy_id, RIG_FILE]

static func hands_rig_json() -> String:
	return "%shands/%s" % [PLAYER_PACK, RIG_FILE]

static func gear_json() -> String:
	return "%sgear.json" % PLAYER_PACK

static func background(enemy_id: StringName) -> String:
	return "%s%s.svg" % [BACKGROUND_PACK, enemy_id]

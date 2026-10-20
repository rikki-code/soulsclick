## Translation lookup with a built-in fallback, so a view string works before its key lands in the locale table.
class_name BattleText
extends RefCounted

static func text(key: String, fallback: String) -> String:
	var translated := TranslationServer.translate(StringName(key))
	return fallback if translated == "" or translated == key else translated

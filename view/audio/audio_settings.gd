## Saved volumes (user://audio.cfg), linear 0..1 per bus key.
class_name AudioSettings
extends RefCounted

const PATH := "user://audio.cfg"
const MASTER := &"master"
const MUSIC := &"music"
const SFX := &"sfx"
const DEFAULTS := {MASTER: 1.0, MUSIC: 0.6, SFX: 0.9}

static var _values: Dictionary = {}

static func volume(key: StringName) -> float:
	if _values.is_empty():
		_load()
	return _values[key]

static func set_volume(key: StringName, value: float) -> void:
	if _values.is_empty():
		_load()
	_values[key] = clampf(value, 0.0, 1.0)

static func save() -> void:
	var config := ConfigFile.new()
	for key: StringName in _values:
		config.set_value("volume", key, _values[key])
	config.save(PATH)

static func _load() -> void:
	var config := ConfigFile.new()
	var loaded := config.load(PATH) == OK
	for key: StringName in DEFAULTS:
		_values[key] = clampf(float(config.get_value("volume", key, DEFAULTS[key])) if loaded else DEFAULTS[key], 0.0, 1.0)

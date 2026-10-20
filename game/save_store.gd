## The only place that touches saved files (user:// is IndexedDB on the web).
class_name SaveStore
extends RefCounted

const PROFILE_PATH := "user://profile.json"

static func load_profile() -> ProfileData:
	if not FileAccess.file_exists(PROFILE_PATH):
		return ProfileData.new()
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	if not (data is Dictionary):
		push_warning("Unreadable profile, starting a fresh one")
		return ProfileData.new()
	return ProfileData.from_dict(data)

static func save_profile(profile: ProfileData) -> bool:
	return _write(PROFILE_PATH, JSON.stringify(profile.to_dict()))

## Writes beside the target and renames, so an interrupted write never leaves a half file.
static func _write(path: String, text: String) -> bool:
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Cannot write %s (error %d)" % [temp_path, FileAccess.get_open_error()])
		return false
	file.store_string(text)
	file.close()
	var error := DirAccess.rename_absolute(temp_path, path)
	if error != OK:
		push_warning("Cannot replace %s (error %d)" % [path, error])
	return error == OK

## The sound part of a settings page: master, music and effects volume sliders.
class_name SoundSettings
extends RefCounted

const VOLUMES := [
	[AudioSettings.MASTER, "SETTINGS_MASTER"],
	[AudioSettings.MUSIC, "SETTINGS_MUSIC"],
	[AudioSettings.SFX, "SETTINGS_SFX"],
]

## Adds the sliders as one panel of tiles.
static func add_to(page: Control) -> void:
	var group := MenuKit.group(page)
	for entry: Array in VOLUMES:
		var key: StringName = entry[0]
		var slider := MenuKit.slider(AudioSettings.volume(key))
		slider.value_changed.connect(func(value: float) -> void: Audio.set_volume(key, value))
		group.add_child(MenuKit.row(page.tr(entry[1]), slider))

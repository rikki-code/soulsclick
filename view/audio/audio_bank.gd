## Everything one audio pack plays: cues by name, and looping music tracks by name.
## Missing names are silent on purpose, so a pack may skip events.
class_name AudioBank
extends Resource

@export var cues: Dictionary = {}  # StringName -> SoundCue
@export var music: Dictionary = {}  # StringName -> AudioStream

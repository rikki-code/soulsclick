## One named sound: pick a random stream per play, so repeated events do not machine-gun the same sample.
class_name SoundCue
extends Resource

@export var streams: Array[AudioStream] = []
@export var volume_db := 0.0
## +- share of the pitch randomised per play.
@export var pitch_jitter := 0.0
## Plays closer together than this are dropped: a burst of 20 identical events is one sound.
@export var cooldown_msec := 0

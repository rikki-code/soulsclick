## The one audio entry point, autoloaded as `Audio`: Audio.play(&"attack"), Audio.play_music(&"menu").
## Cue names are resolved in the active audio pack (view/packs/audio_pack/), see AudioBank.
class_name AudioDirector
extends Node

const MUSIC_BUS := &"Music"
const SFX_BUS := &"Sfx"
const BUS_BY_KEY := {AudioSettings.MASTER: &"Master", AudioSettings.MUSIC: MUSIC_BUS, AudioSettings.SFX: SFX_BUS}
const VOICES := 24
const MUSIC_FADE_SECONDS := 1.2
const SILENT_DB := -60.0
const PAUSE_MUFFLE_HZ := 900.0
const SAVE_DELAY_SECONDS := 0.6

var _bank: AudioBank
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last_msec: Dictionary = {}  # StringName -> int
var _music: Array[AudioStreamPlayer] = []
var _music_active := 0
var _music_name := &""
var _muffled := false
var _save_timer: Timer

func _ready() -> void:
	# Sounds must keep playing under the pause menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for i in range(VOICES):
		_voices.append(_make_player(SFX_BUS))
	for i in range(2):
		_music.append(_make_player(MUSIC_BUS))
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY_SECONDS
	_save_timer.timeout.connect(AudioSettings.save)
	add_child(_save_timer)
	reload()
	get_tree().node_added.connect(_on_node_added)

func _process(_delta: float) -> void:
	var paused := get_tree().paused
	if paused != _muffled:
		_muffled = paused
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(MUSIC_BUS), 0, paused)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _save_timer.is_stopped():
		AudioSettings.save()

## Loads the active pack's bank; a playing track crossfades to the new pack's version.
func reload() -> void:
	_bank = load(PackPaths.AUDIO_PACK + "sound_bank.tres") as AudioBank
	if _bank == null:
		push_warning("No sound bank in %s" % PackPaths.AUDIO_PACK)
	if _music_name != &"":
		_start_track()

func play(cue_name: StringName, pitch := 1.0, volume_db := 0.0) -> void:
	if _bank == null or cue_name == &"":
		return
	var cue: SoundCue = _bank.cues.get(cue_name)
	if cue == null or cue.streams.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_msec.get(cue_name, -1000000)) < cue.cooldown_msec:
		return
	_last_msec[cue_name] = now
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = cue.streams[randi() % cue.streams.size()]
	voice.volume_db = cue.volume_db + volume_db
	voice.pitch_scale = pitch * (1.0 + randf_range(-cue.pitch_jitter, cue.pitch_jitter))
	voice.play()

func play_music(track: StringName) -> void:
	if track == _music_name:
		return
	_music_name = track
	_start_track()

func set_volume(key: StringName, value: float) -> void:
	AudioSettings.set_volume(key, value)
	_apply_volume(key)
	_save_timer.start()

func _start_track() -> void:
	var stream: AudioStream = _bank.music.get(_music_name) if _bank != null else null
	var old := _music[_music_active]
	_music_active = 1 - _music_active
	var fresh := _music[_music_active]
	var fade := create_tween().set_parallel()
	fade.tween_property(old, "volume_db", SILENT_DB, MUSIC_FADE_SECONDS)
	fade.chain().tween_callback(func() -> void:
		if old != _music[_music_active]:
			old.stop()
	)
	if stream == null:
		return
	fresh.stream = stream
	fresh.volume_db = SILENT_DB
	fresh.play()
	fade.tween_property(fresh, "volume_db", 0.0, MUSIC_FADE_SECONDS)

func _make_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player

func _setup_buses() -> void:
	for bus in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, &"Master")
	var muffle := AudioEffectLowPassFilter.new()
	muffle.cutoff_hz = PAUSE_MUFFLE_HZ
	var music_index := AudioServer.get_bus_index(MUSIC_BUS)
	AudioServer.add_bus_effect(music_index, muffle, 0)
	AudioServer.set_bus_effect_enabled(music_index, 0, false)
	for key: StringName in BUS_BY_KEY:
		_apply_volume(key)

func _apply_volume(key: StringName) -> void:
	var index := AudioServer.get_bus_index(BUS_BY_KEY[key])
	var value := AudioSettings.volume(key)
	AudioServer.set_bus_volume_db(index, linear_to_db(value))
	AudioServer.set_bus_mute(index, value <= 0.001)

# Every button and slider in every scene gets click/hover sounds without per-widget wiring.
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play.bind(&"ui_click"))
		node.mouse_entered.connect(_on_button_hover.bind(node))
	elif node is Slider:
		node.drag_ended.connect(func(_changed: bool) -> void: play(&"ui_click"))

func _on_button_hover(button: BaseButton) -> void:
	if not button.disabled:
		play(&"ui_hover")

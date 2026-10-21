## Dev lab: the road with random forks in any realm, no run needed. Pick a trail, walk it, a new fork follows.
## Buttons: realm 1-4, doors 2/3/random, kind of the next fork, portals after a boss. Keys: R reroll, P portals.
class_name ForkLab
extends Control

const KINDS: Array[StringName] = [&"fight", &"elite", &"altar", &"bonfire", &"boss"]
const WALK_BETWEEN := 1.2

var _road: RoadScene
var _portals: PortalView
var _info := Label.new()
var _realm := 0
var _doors := 0 ## 0 = random
var _rng := RandomNumberGenerator.new()
var _busy := false

func _ready() -> void:
	UiScale.fit(get_window())
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_road = RoadScene.new()
	_road.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_road)
	_road.fork_reached.connect(func() -> void: _say("pick a trail"))
	_road.trail_picked.connect(func(i: int) -> void: _say("picked %d: %s" % [i, _last_kinds[i]]))
	_road.trail_arrived.connect(_on_arrived)
	_build_hud()
	_reroll()

var _last_kinds: Array[StringName] = []

func _build_hud() -> void:
	var bar := HFlowContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, 8)
	bar.add_theme_constant_override("h_separation", 8)
	add_child(bar)
	for r in 4:
		_button(bar, "R%d" % (r + 1), func() -> void: _realm = r; _reroll())
	for d in [2, 3, 0]:
		_button(bar, "%s doors" % (str(d) if d > 0 else "any"), func() -> void: _doors = d; _reroll())
	_button(bar, "Reroll", _reroll)
	_button(bar, "Portals", _show_portals)
	_button(bar, "Boss fork", _show_boss_fork)
	_button(bar, "Menu", SceneRouter.to_menu)
	_info.add_theme_font_size_override("font_size", 28)
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 8)
	_info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 12)
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_info)

func _button(parent: Control, text: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 72)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(on_pressed)
	parent.add_child(b)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reroll()
		elif event.keycode == KEY_P:
			_show_portals()

func _say(text: String) -> void:
	_info.text = "realm %d | %s" % [_realm + 1, text]

func _random_offer() -> DoorOffer:
	var offer := DoorOffer.new()
	offer.realm_index = _realm
	var count := _doors if _doors > 0 else _rng.randi_range(2, 3)
	var pool := KINDS.duplicate()
	pool.shuffle()
	_last_kinds.clear()
	for i in count:
		var door := Door.make(pool[i], &"")
		door.index = i
		offer.doors.append(door)
		_last_kinds.append(pool[i])
	return offer

func _reroll() -> void:
	_clear_portals()
	_busy = false
	_road.clear_fork()
	_road.setup(_realm, _rng.randi())
	_say("walking")
	_road.show_fork(_random_offer())
	_road.walk_to_fork()

func _on_arrived(_index: int) -> void:
	_say("arrived: %s (new fork soon)" % _last_kinds[_index])
	if _busy:
		return
	_busy = true
	await get_tree().create_timer(1.2).timeout
	if not _busy:
		return
	_road.fade_fork(0.4)
	await get_tree().create_timer(WALK_BETWEEN).timeout
	if not _busy:
		return
	_busy = false
	_road.show_fork(_random_offer())
	_road.walk_to_fork()
	_say("walking")

func _show_boss_fork() -> void:
	_busy = true
	_clear_portals()
	_road.clear_fork()
	_road.setup(_realm, _rng.randi())
	_last_kinds = [&"home", &"deeper"]
	_road.show_fork(GameRoot.crossroads_offer(1234, _realm + 2))
	_road.walk_to_fork()
	_say("boss fork")

func _clear_portals() -> void:
	if _portals != null:
		_portals.queue_free()
		_portals = null

func _show_portals() -> void:
	_busy = false
	_road.clear_fork()
	_clear_portals()
	_portals = PortalView.new().setup(1234, _realm + 2)
	_portals.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_portals)
	_portals.home_picked.connect(func() -> void: _say("home picked"); _clear_portals())
	_portals.deeper_picked.connect(func() -> void:
		_say("deeper picked")
		_clear_portals()
		_realm = (_realm + 1) % 4
		_road.transition_to_realm(_realm, _rng.randi(), 2.5)
		_road.set_speed(0.4)
		await get_tree().create_timer(2.5).timeout
		_reroll())
	_portals.reveal()
	_say("portals")

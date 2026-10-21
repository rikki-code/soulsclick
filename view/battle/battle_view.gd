## The duel screen: background, enemy rig, HUD, buttons, effects and end overlays. It only reacts to events it is
## handed (on_* methods) and never reads the duel; GameRoot wires the signals.
class_name BattleView
extends Control

signal walk_finished
signal reward_picked(index: int)
signal trail_picked(index: int)
signal fork_reached
signal trail_arrived(index: int)
signal home_picked
signal deeper_picked
signal revive_pressed
signal menu_pressed
signal pause_requested
signal resume_requested
signal abandon_requested
signal menu_requested
signal settings_requested
signal buy_item_requested(item_id: StringName)
signal buy_level_requested(stat_id: StringName)
signal use_item_requested(item_id: StringName)

const BG_SIZE := Vector2(1080, 1920)
const BG_GROUND_Y := 1500.0
const RIG_ORIGIN_IN_BG := Vector2(28, 560)
const RIG_FEET_Y := 975.0
const RIG_INK_HEIGHT := 915.0
const LANDSCAPE_INK_SHARE := 0.76
const PORTRAIT_MAX_RIG_SCALE := 1.3
const BG_BELOW_GROUND := 420.0
## On the road the enemy stands far ahead: smaller, feet on the road centre line.
const ROAD_RIG_SHARE := 0.8
const ROAD_FEET_Y_SHARE := 0.72
const SHADOW_HALF_WIDTH := 300.0
const SHADOW_HALF_HEIGHT := 46.0
const SHADOW_ALPHA := 0.6
const SHADOW_STEPS := 24
const MARGIN_SHARE := 0.04
const TOP_HUD_SHARE := 0.02
const TOP_HUD_HEIGHT := 130.0
const BARS_GAP := 14.0
const BARS_BOTTOM_PAD := 0.02
const PORTRAIT_BARS_HEIGHT := 96.0
const LANDSCAPE_BARS_HEIGHT := 82.0
const LANDSCAPE_BARS_WIDTH_SHARE := 0.36
const BARS_Z := 100
const NAME_FONT := 40
const HINT_FONT := 44
const HINT_SECONDS := 5.0
const HINT_FADE := 0.6
const HINT_WIDTH_SHARE := 0.8
const LANDSCAPE_HINT_WIDTH_SHARE := 0.22
const LANDSCAPE_HINT_Y_SHARE := 0.16
const LANDSCAPE_HINT_HEIGHT := 300.0
const RING_SCALE_REF := 1704.0
const RING_SCALE_MIN := 0.7
const RING_SCALE_MAX := 1.3
const TELL_FLASH_ALPHA := 0.12
const TELL_FLASH_SECONDS := 0.12
const TICK_PITCH := 2.0
const TICK_DB := -4.0
const DEFAULT_PARRY_WINDOW := 0.25
const HIT_NUMBER_LIFT := 70.0
const STRIKE_SECONDS := 0.09
const RECOVER_SECONDS := 0.4
const SETTLE_SECONDS := 0.3
const FEINT_SECONDS := 0.3
const STAGGER_SECONDS := 0.15
const HURT_SECONDS := 0.07
const END_DELAY := 1.1
const PARRY_COLOR := Color(1.0, 0.95, 0.7)
const HIT_COLOR := Color(1.0, 0.25, 0.2)
const BLOCK_COLOR := Color(0.7, 0.85, 1.0)
const PUNISH_COLOR := Color(1.0, 0.85, 0.2)
const CRIT_TEXT := "CRIT!"
const PAUSE_BUTTON_SIZE := 76.0
const SOULS_FONT := 34
const SOULS_COLOR := Color(1.0, 0.82, 0.3)
const SOULS_ROLL_SECONDS := 0.5
const SOULS_FLY_SECONDS := 0.7
const SHOP_TOP_GAP := 20.0
## Portrait: the combo readout shifts left of the shop button column.
const SHOP_COLUMN_CLEARANCE := 200.0
const COMBO_MIN_SHOWN := 2
const COMBO_BOX := Vector2(300, 150)
const COMBO_COUNT_FONT := 84
const COMBO_MULT_FONT := 40
const COMBO_PUNCH := 0.35
const COMBO_COLD := Color.WHITE
const COMBO_WARM := Color(1.0, 0.7, 0.2)
const COMBO_HOT := Color(1.0, 0.2, 0.15)
const COMBO_HOT_MULT := 3.0
const HITSTOP_SECONDS := 0.04
const HITSTOP_COMBO := 8
const HITSTOP_SCALE := 0.05
const CRIT_SPARK_COLOR := Color(1.0, 0.85, 0.2)
const BACK_GRADIENT_TOP := Color(0.1, 0.08, 0.12)
const BACK_GRADIENT_BOTTOM := Color(0.03, 0.03, 0.04)
const WALK_SPEED := 0.3
const STEP_IN_SECONDS := 0.5
const STEP_FAR_SCALE := 0.35
const BANNER_SECONDS := 1.0
const BANNER_FONT := 72
const OVERLAY_LAYER := 4
const LOCK_COLORS := {&"attacking": Color(0.95, 0.6, 0.2), &"blocking": Color(0.4, 0.7, 1.0), &"staggered": Color(0.9, 0.2, 0.2)}

var _definition: EnemyDefinition
var _enemy_max := 1
var _player_max := 1.0
var _rig: EnemyRig
var _telegraphing := false
var _enemy_staggered := false
var _landscape := false
var _telegraph_tween: Tween
var _lock_tween: Tween
var _background := TextureRect.new()
## Background file id in the background pack (e.g. `realm_2_boss`); empty = the enemy's own background.
var background_id: StringName = &""
var _stage_layer := CanvasLayer.new()
var _stage := Node2D.new()
var _hud_layer := CanvasLayer.new()
var _hud := Control.new()
var _fx := BattleFx.new()
var _overlay := BattleOverlay.new()
var _enemy_name := Label.new()
var _enemy_bar := StatBar.new()
var _telegraph_bar := StatBar.new()
var _player_bar := StatBar.new()
var _stamina_bar := StatBar.new()
var _lock_bar := StatBar.new()
var _scheme: InputScheme
var _hint := Label.new()
var _hint_tween: Tween
var _hit_point := Vector2.ZERO
var _ring := ParryRing.new()
var _combo_box := Control.new()
var _combo_count := Label.new()
var _combo_mult := Label.new()
var _combo_tween: Tween
var _combo_last := 0
var _combo_home := Vector2.ZERO
var _pending_number := -1
var _hitstop_active := false
var _pause_button := Button.new()
var _pause_menu := PauseMenu.new()
var _shop := ShopPanel.new()
var _souls_label := Label.new()
var _souls_target := 0
var _souls_shown := 0
var _souls_tween: Tween
var _paused := false
var _finished := false
var _road: RoadScene
const APPEAR_SECONDS := 0.25
const FORK_FADE_SECONDS := 0.4
var _walk_tween: Tween
var _step_tween: Tween
var _step := 1.0
var _shadow: Polygon2D
var _banner := Label.new()
var _banner_tween: Tween
var _overlay_layer := CanvasLayer.new()
## Parry window length (s) used when the duel gives no strike_timing; set from the tuning by the composition root.
var parry_window := DEFAULT_PARRY_WINDOW

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_SCALE
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)
	_stage_layer.layer = 1
	add_child(_stage_layer)
	_stage_layer.add_child(_stage)
	_hud_layer.layer = 2
	add_child(_hud_layer)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_layer.add_child(_hud)
	_build_hud()
	_ring.anchor = _weapon_point
	_ring.window_opened.connect(_on_parry_window_opened)
	_hud_layer.add_child(_ring)
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 3
	add_child(fx_layer)
	fx_layer.add_child(_fx)
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.setup(_stage)
	var pause_layer := CanvasLayer.new()
	pause_layer.layer = 5
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)
	pause_layer.add_child(_pause_menu)
	_pause_menu.resume_requested.connect(close_pause)
	_pause_menu.settings_requested.connect(settings_requested.emit)
	_pause_menu.abandon_requested.connect(abandon_requested.emit)
	_pause_menu.menu_requested.connect(menu_requested.emit)
	_overlay_layer.layer = OVERLAY_LAYER
	add_child(_overlay_layer)
	_overlay_layer.add_child(_overlay)
	_banner.visible = false
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_banner.add_theme_font_size_override("font_size", BANNER_FONT)
	_banner.add_theme_color_override("font_color", SOULS_COLOR)
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 12)
	_overlay_layer.add_child(_banner)
	_overlay.revive_pressed.connect(revive_pressed.emit)
	_overlay.menu_pressed.connect(menu_pressed.emit)
	get_viewport().size_changed.connect(_layout)

## Starts (or restarts after a revive) the view for a fresh duel; reads the initial numbers once.
## step_in false: the player walked here (trail), so the enemy just fades in place while the fork fades out.
func begin(definition: EnemyDefinition, enemy: Fighter, player: Fighter, step_in := true) -> void:
	_definition = definition
	_enemy_max = enemy.max_hp
	_player_max = player.max_hp
	_telegraphing = false
	_enemy_staggered = false
	_overlay.hide_overlay()
	_kill(_walk_tween)
	if _road != null:
		_road.set_speed(0.0)
	_enemy_name.visible = true
	_enemy_bar.visible = true
	_kill(_telegraph_tween)
	_kill(_lock_tween)
	_telegraph_bar.visible = false
	_lock_bar.visible = false
	_ring.stop()
	_combo_last = 0
	_finished = false
	_kill(_combo_tween)
	_combo_box.modulate.a = 0.0
	_enemy_name.text = tr(definition.name_key)
	_enemy_bar.set_values(enemy.hp, enemy.max_hp, false)
	_player_bar.set_values(player.hp, player.max_hp, false)
	_stamina_bar.set_values(player.stamina, player.max_stamina, false)
	if _rig != null:
		_rig.queue_free()
	_rig = EnemyRig.new()
	_make_shadow()
	_stage.add_child(_rig)
	_rig.setup(RigSpec.load_for(definition.id, Color(0.9, 0.3, 0.2)))
	_load_background(background_id if background_id != &"" else definition.id)
	set_input_enabled(true)
	if step_in:
		_step_in()
	else:
		_appear_in_place()

## Puts the active input scheme into the HUD (below the bars); call before begin().
func mount_scheme(scheme: InputScheme) -> void:
	if _scheme != null:
		_scheme.queue_free()
	_scheme = scheme
	_hud.add_child(scheme)
	_hud.move_child(scheme, 0)
	_layout()
	_update_exclusions()

func show_hint(text: String) -> void:
	_hint.text = text
	_hint.modulate.a = 1.0
	_hint.visible = true
	_kill(_hint_tween)
	_hint_tween = create_tween()
	_hint_tween.tween_interval(HINT_SECONDS)
	_hint_tween.tween_property(_hint, "modulate:a", 0.0, HINT_FADE)
	_hint_tween.tween_callback(_hint.hide)

func set_input_enabled(enabled: bool) -> void:
	if _scheme != null:
		_scheme.set_input_enabled(enabled)

func press_feedback(action_id: StringName) -> void:
	if _scheme != null:
		_scheme.on_action_accepted(action_id)

## Flashes a "Victory +N souls" banner for about a second; no button.
func show_victory(souls: int) -> void:
	_banner.text = "%s\n%s" % [tr("BATTLE_VICTORY"), tr("BATTLE_SOULS") % souls]
	_banner.modulate.a = 1.0
	_banner.visible = true
	Audio.play(&"souls_gain")
	_kill(_banner_tween)
	_banner_tween = create_tween()
	_banner_tween.tween_interval(BANNER_SECONDS * 0.7)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, BANNER_SECONDS * 0.3)
	_banner_tween.tween_callback(_banner.hide)

## Replaces the background texture with a RoadScene of the realm; the road stands until walk().
func set_road(realm_index: int, seed: int) -> void:
	if _road == null:
		_road = RoadScene.new()
		_road.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_road)
		move_child(_road, 0)
		_road.fork_reached.connect(fork_reached.emit)
		_road.trail_picked.connect(trail_picked.emit)
		_road.trail_arrived.connect(trail_arrived.emit)
	_road.setup(realm_index, seed)
	_road.set_speed(0.0)
	_background.visible = false

## Blends the road into another realm over `seconds` (keeps scrolling; pair with walk()).
func transition_road(realm_index: int, seed: int, seconds: float) -> void:
	if _road == null:
		set_road(realm_index, seed)
		return
	_road.transition_to_realm(realm_index, seed, seconds)

## Walks the road for `seconds` (enemy hidden, input off, speed eased in/out), then emits walk_finished.
func walk(seconds: float) -> void:
	clear_enemy()
	set_input_enabled(false)
	_kill(_walk_tween)
	_walk_tween = create_tween()
	_walk_tween.tween_method(_set_walk_progress.bind(seconds), 0.0, 1.0, maxf(seconds, 0.01))
	_walk_tween.tween_callback(_end_walk)

func _set_walk_progress(t: float, _seconds: float) -> void:
	if _road != null:
		_road.set_speed(WALK_SPEED * sin(PI * t))

func _end_walk() -> void:
	if _road != null:
		_road.set_speed(0.0)
	walk_finished.emit()

## Hides the rig and the enemy bars between encounters; begin() shows them again.
func clear_enemy() -> void:
	_kill(_step_tween)
	_kill(_telegraph_tween)
	_ring.stop()
	_telegraphing = false
	_enemy_staggered = false
	_telegraph_bar.visible = false
	_enemy_bar.visible = false
	_enemy_name.visible = false
	if _rig != null:
		_rig.stop_glow()
		_rig.visible = false

func show_rewards(offer: RewardOffer) -> void:
	var overlay := RewardOverlay.new().setup(offer)
	overlay.card_picked.connect(reward_picked.emit)
	_overlay_layer.add_child(overlay)

## The fork stands far ahead on the road while the room before it is fought.
func preview_fork(offer: DoorOffer) -> void:
	_road.show_fork(offer)

## Walks up to the fork (enemy hidden, input off); emits fork_reached when the road stops.
func walk_to_fork() -> void:
	clear_enemy()
	set_input_enabled(false)
	_kill(_walk_tween)
	_road.walk_to_fork()

func update_fork(offer: DoorOffer) -> void:
	_road.update_fork(offer)

## Boss fallen: two portals on the road ahead (home banks the Souls, deeper risks them).
func show_portals(souls: int, next_depth: int) -> void:
	clear_enemy()
	var portals := PortalView.new().setup(souls, next_depth)
	portals.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portals.home_picked.connect(func() -> void:
		portals.queue_free()
		home_picked.emit())
	portals.deeper_picked.connect(func() -> void:
		portals.queue_free()
		deeper_picked.emit())
	_overlay_layer.add_child(portals)
	portals.reveal()

## Rig appears where it stands: quick fade-in, no scale from far; the walked-to fork fades away.
func _appear_in_place() -> void:
	_kill(_step_tween)
	_step = 1.0
	_rig.modulate.a = 0.0
	_layout()
	_step_tween = create_tween()
	_step_tween.tween_property(_rig, "modulate:a", 1.0, APPEAR_SECONDS)
	clear_road_fork()

## Fork landmark and remaining trail fade out (road removes the fork afterwards).
func clear_road_fork() -> void:
	if _road != null:
		_road.fade_fork(FORK_FADE_SECONDS)

## Enemy steps in: scales up from far over STEP_IN_SECONDS.
func _step_in() -> void:
	_kill(_step_tween)
	_step = STEP_FAR_SCALE
	_rig.modulate.a = 0.0
	_layout()
	_step_tween = create_tween().set_parallel()
	_step_tween.tween_method(_set_step, STEP_FAR_SCALE, 1.0, STEP_IN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_step_tween.tween_property(_rig, "modulate:a", 1.0, STEP_IN_SECONDS * 0.6)

## Soft dark ellipse under the feet (sibling below the rig, placed by _layout, alpha follows the rig).
func _make_shadow() -> void:
	if _shadow != null:
		_shadow.queue_free()
	_shadow = Polygon2D.new()
	var points := PackedVector2Array([Vector2.ZERO])
	var colors := PackedColorArray([Color(0, 0, 0, SHADOW_ALPHA)])
	for i in SHADOW_STEPS + 1:
		var a := TAU * i / SHADOW_STEPS
		points.append(Vector2(cos(a), sin(a)))
		colors.append(Color(0, 0, 0, 0))
	_shadow.polygon = points
	_shadow.vertex_colors = colors
	_stage.add_child(_shadow)

func _process(_delta: float) -> void:
	if _shadow != null and _rig != null and is_instance_valid(_rig):
		_shadow.visible = _rig.visible and _road != null
		_shadow.modulate.a = _rig.modulate.a

func _set_step(k: float) -> void:
	_step = k
	_layout()

func show_death(can_revive: bool) -> void:
	_overlay.show_death(can_revive, END_DELAY)

func on_telegraph_started(kind_id: StringName, duration: float, _index: int) -> void:
	_telegraphing = true
	on_strike_timing(duration, parry_window, kind_id, _index)
	var style := GlowStyles.style_for(kind_id)
	var color := GlowStyles.color_for(kind_id, _rig.accent)
	_rig.play_pose(StringName("windup_%s" % kind_id), duration)
	_rig.pulse_glow(color, duration, style["period"], style["peak"])
	_telegraph_bar.configure(color, false)
	_telegraph_bar.visible = true
	_kill(_telegraph_tween)
	_telegraph_tween = create_tween()
	_telegraph_tween.tween_method(func(t: float) -> void: _telegraph_bar.set_values(t, 1.0, false), 0.0, 1.0, maxf(duration, 0.01))
	Audio.play(&"telegraph_heavy" if kind_id == &"heavy" else &"enemy_telegraph")

## Starts the approach ring: the strike lands in `strike_in` seconds and the last `window_seconds` of that are the parry
## window. Also derived from on_telegraph_started when the duel sends no timing; a later call replaces the ring.
func on_strike_timing(strike_in: float, window_seconds: float, kind_id: StringName, _index_in_combo := 0) -> void:
	var accent := _rig.accent if _rig != null else Color.WHITE
	_ring.start(strike_in, window_seconds, GlowStyles.color_for(kind_id, accent))

func on_strike_resolved(result: StrikeResult) -> void:
	_ring.stop()
	_telegraphing = false
	_kill(_telegraph_tween)
	_telegraph_bar.visible = false
	_rig.stop_glow()
	_player_bar.set_values(result.target_hp, _player_max)
	if _scheme != null:
		_scheme.on_strike_resolved(result)
	match result.outcome:
		StrikeResult.PARRIED:
			_show_parry()
		StrikeResult.BLOCKED:
			_show_block(result)
		StrikeResult.FEINT:
			_rig.play_sequence([[&"recover", FEINT_SECONDS], [RigSpec.IDLE, SETTLE_SECONDS]])
			Audio.play(&"feint")
		_:
			_show_hit(result)

## Heals and item effects change hp outside a strike: keep the bars in sync at once.
func on_player_hp_changed(hp: int, max_hp: int) -> void:
	_player_bar.set_values(hp, max_hp)

func on_enemy_hp_changed(hp: int, max_hp: int) -> void:
	_enemy_bar.set_values(hp, max_hp)

## Instant feedback for a drunk or thrown consumable.
func on_item_used(_item_id: StringName, _charges_left: int) -> void:
	_fx.burst(Vector2(size.x * 0.5, _hit_point.y), Color(0.95, 0.75, 0.3), 0.9)
	Audio.play(&"souls_gain")

func on_player_attacked(damage: int, enemy_hp: int) -> void:
	_enemy_bar.set_values(enemy_hp, _enemy_max)
	var focus := _enemy_focus()
	_pending_number = damage
	_flush_pending_number.call_deferred()
	_fx.burst(focus, Color.WHITE, 0.6)
	_rig.flash(0.15)
	Audio.play(&"attack")
	if _telegraphing:
		_rig.nudge(14.0)
		return
	var rest := &"staggered" if _enemy_staggered else RigSpec.IDLE
	_rig.play_sequence([[&"hurt", HURT_SECONDS], [rest, SETTLE_SECONDS]])

## Right after on_player_attacked: owns the damage number (the fallback number is dropped), crit pop and combo-scaled juice.
func on_player_hit(damage: int, enemy_hp: int, crit: bool, combo: int) -> void:
	_enemy_bar.set_values(enemy_hp, _enemy_max)
	_pending_number = -1
	var focus := _enemy_focus()
	var text := str(damage)
	if _enemy_staggered and not crit:
		_fx.number(focus, text, PUNISH_COLOR, 1.1, 0.6)
	else:
		_fx.hit_number(focus, text, crit)
	var heat := clampf(combo / 20.0, 0.0, 1.0)
	_rig.flash(0.15 + heat * 0.1)
	if crit:
		_fx.number(focus + Vector2(0, -90), CRIT_TEXT, CRIT_SPARK_COLOR, 1.0, 0.5, 50.0)
		_fx.burst(focus, CRIT_SPARK_COLOR, 1.8)
		_fx.shake(6.0 + heat * 6.0, 0.2)
		_fx.flash(CRIT_SPARK_COLOR, 0.18, 0.12)
	elif combo >= HITSTOP_COMBO:
		_fx.burst(focus, COMBO_WARM.lerp(COMBO_HOT, heat), 0.5 + heat)
		_fx.shake(2.0 + heat * 4.0, 0.12)
	if crit or combo >= HITSTOP_COMBO:
		_hitstop(HITSTOP_SECONDS * (1.0 + heat))

## Combo counter near the enemy: punches on every hit, heats up with the multiplier, shakes and fades on reset (0).
func on_combo_changed(count: int, multiplier: float) -> void:
	_kill(_combo_tween)
	if count < COMBO_MIN_SHOWN:
		if _combo_last >= COMBO_MIN_SHOWN:
			_combo_reset()
		_combo_last = count
		if count == 0:
			return
		_combo_box.modulate.a = 0.0
		return
	_combo_last = count
	var color := _combo_color(multiplier)
	_combo_count.text = "x%d" % count
	_combo_mult.text = "×%.1f" % multiplier
	_combo_count.add_theme_color_override("font_color", color)
	_combo_mult.add_theme_color_override("font_color", color)
	_combo_box.modulate.a = 1.0
	_combo_box.position.x = _combo_home.x
	var punch := 1.0 + COMBO_PUNCH * (0.6 + 0.4 * clampf(multiplier / COMBO_HOT_MULT, 0.0, 1.0))
	_combo_box.scale = Vector2.ONE * punch
	_combo_box.rotation = randf_range(-0.06, 0.06)
	_combo_tween = create_tween().set_parallel()
	_combo_tween.tween_property(_combo_box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_combo_tween.tween_property(_combo_box, "rotation", 0.0, 0.18)

## Pause menu (the game layer stops the duel clock on pause_requested / resume_requested).
func open_pause() -> void:
	if _paused or _finished:
		return
	_paused = true
	_pause_menu.open()
	if _scheme != null:
		_scheme.set_input_enabled(false)
	pause_requested.emit()

func close_pause() -> void:
	if not _paused:
		return
	_paused = false
	_pause_menu.close()
	if _scheme != null and not _finished:
		_scheme.set_input_enabled(true)
	resume_requested.emit()

func toggle_pause() -> void:
	if _paused:
		close_pause()
	else:
		open_pause()

func is_paused() -> bool:
	return _paused

## Side shop contents; see ShopPanel.set_shop for the dictionary fields.
func set_shop(items: Array[Dictionary], levels: Array[Dictionary], souls: int) -> void:
	_shop.set_shop(items, levels, souls)
	_roll_souls(souls, false)

## Souls of the run: rolls the counter and refreshes the shop's affordability.
func set_souls(souls: int) -> void:
	_shop.set_souls(souls)
	_roll_souls(souls, true)

## Souls gained from a kill: a "+N" flies from the enemy to the counter.
func on_souls_earned(amount: int) -> void:
	_fx.fly_text(_enemy_focus(), _souls_label.global_position + _souls_label.size * 0.5, "+%d" % amount, SOULS_COLOR, SOULS_FLY_SECONDS)
	Audio.play(&"souls_gain")

func _roll_souls(souls: int, animate: bool) -> void:
	_souls_target = souls
	_kill(_souls_tween)
	if not animate:
		_set_souls_shown(souls)
		return
	_souls_tween = create_tween()
	_souls_tween.tween_method(_set_souls_shown, _souls_shown, souls, SOULS_ROLL_SECONDS).set_delay(SOULS_FLY_SECONDS * 0.8)

func _set_souls_shown(value: int) -> void:
	_souls_shown = value
	_souls_label.text = "%s %d" % [BattleText.text("HUD_SOULS", "Souls"), value]

func _build_chrome() -> void:
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.flat = true
	_pause_button.size = Vector2.ONE * PAUSE_BUTTON_SIZE
	_pause_button.z_index = BARS_Z
	_pause_button.pressed.connect(open_pause)
	_pause_button.draw.connect(_draw_pause_icon)
	_hud.add_child(_pause_button)
	_souls_label.add_theme_font_size_override("font_size", SOULS_FONT)
	_souls_label.add_theme_color_override("font_color", SOULS_COLOR)
	_souls_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_souls_label.add_theme_constant_override("outline_size", 8)
	_souls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_souls_label.z_index = BARS_Z
	_hud.add_child(_souls_label)
	_set_souls_shown(0)
	_shop.z_index = BARS_Z
	_shop.rects_changed.connect(_update_exclusions)
	_shop.buy_item_requested.connect(buy_item_requested.emit)
	_shop.buy_level_requested.connect(buy_level_requested.emit)
	_shop.use_item_requested.connect(use_item_requested.emit)
	_hud.add_child(_shop)

func _draw_pause_icon() -> void:
	var rect := Rect2(Vector2.ZERO, _pause_button.size)
	_pause_button.draw_rect(rect, Color(0.03, 0.03, 0.04, 0.7))
	_pause_button.draw_rect(rect, Color(0.45, 0.48, 0.55, 0.8), false, 2.0)
	for i in 3:
		_pause_button.draw_rect(Rect2(18.0, 20.0 + i * 15.0, rect.size.x - 36.0, 6.0), Color.WHITE)

func _update_exclusions() -> void:
	if _scheme == null:
		return
	var rects: Array[Rect2] = [Rect2(_pause_button.position, _pause_button.size).grow(6.0)]
	rects.append_array(_shop.input_rects())
	_scheme.excluded_rects = rects

func _combo_reset() -> void:
	_combo_count.add_theme_color_override("font_color", COMBO_COLD)
	_combo_mult.add_theme_color_override("font_color", COMBO_COLD)
	_combo_tween = create_tween()
	_combo_tween.tween_method(func(t: float) -> void:
		_combo_box.position.x = _combo_home.x + randf_range(-1.0, 1.0) * 14.0 * (1.0 - t)
		_combo_box.modulate.a = 1.0 - t, 0.0, 1.0, 0.45)
	_combo_tween.tween_callback(func() -> void: _combo_box.position.x = _combo_home.x)

static func _combo_color(multiplier: float) -> Color:
	var t := clampf((multiplier - 1.0) / (COMBO_HOT_MULT - 1.0), 0.0, 1.0)
	if t < 0.5:
		return COMBO_COLD.lerp(COMBO_WARM, t * 2.0)
	return COMBO_WARM.lerp(COMBO_HOT, (t - 0.5) * 2.0)

func _flush_pending_number() -> void:
	if _pending_number < 0:
		return
	var damage := _pending_number
	_pending_number = -1
	if _enemy_staggered:
		_fx.number(_enemy_focus(), str(damage), PUNISH_COLOR, 1.2, 0.6)
	else:
		_fx.hit_number(_enemy_focus(), str(damage), false)

## Real-time freeze: slows the game clock for a few frames; overlapping calls are ignored.
func _hitstop(seconds: float) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = HITSTOP_SCALE
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func on_stamina_changed(value: float, max_value: float) -> void:
	_stamina_bar.set_values(value, max_value)

func on_fighter_state_timed(side: StringName, state_id: StringName, duration: float) -> void:
	if side == Fighter.PLAYER:
		_show_player_state(state_id, duration)
		return
	if state_id == &"staggered":
		_enemy_staggered = true
		_telegraphing = false
		_rig.stop_glow()
		_rig.play_pose(&"staggered", STAGGER_SECONDS, Tween.TRANS_BACK)
		Audio.play(&"stagger")
	elif state_id == &"idle" and _enemy_staggered:
		_enemy_staggered = false
		_rig.play_pose(RigSpec.IDLE, SETTLE_SECONDS)

func on_action_rejected(action_id: StringName, reason: StringName) -> void:
	if reason == Duel.REJECT_FINISHED:
		return
	if _scheme != null:
		_scheme.on_action_rejected(action_id, reason)
	if reason == Duel.REJECT_STAMINA:
		_stamina_bar.flash_warning()
		Audio.play(&"stamina_empty")

func on_duel_finished(winner_side: StringName) -> void:
	_finished = true
	_ring.stop()
	_telegraphing = false
	_kill(_telegraph_tween)
	_telegraph_bar.visible = false
	set_input_enabled(false)
	_rig.stop_glow()
	if winner_side == Fighter.PLAYER:
		_rig.play_pose(&"death", 0.9)
		_rig.fade_out(1.4)
		Audio.play(&"victory")
		return
	_rig.play_pose(RigSpec.IDLE, SETTLE_SECONDS)
	Audio.play(&"death")

func _on_parry_window_opened() -> void:
	_fx.flash(Color.WHITE, TELL_FLASH_ALPHA, TELL_FLASH_SECONDS)
	Audio.play(&"enemy_telegraph", TICK_PITCH, TICK_DB)

func _show_parry() -> void:
	var focus := _weapon_point()
	_fx.burst(focus, PARRY_COLOR, 1.6)
	_fx.flash(PARRY_COLOR, 0.35)
	_fx.shake(10.0)
	_fx.number(focus + Vector2(0, -60), tr("BATTLE_PARRY"), PARRY_COLOR, 1.3)
	Audio.play(&"parry")

func _show_block(result: StrikeResult) -> void:
	_play_strike(result.kind_id)
	_fx.burst(_weapon_point(), BLOCK_COLOR, 0.8)
	_fx.shake(result.damage * 0.4 + 6.0)
	_fx.number(_hit_point, "-%d" % result.damage, BLOCK_COLOR)
	Audio.play(&"block")

func _show_hit(result: StrikeResult) -> void:
	_play_strike(result.kind_id)
	var shake := GlowStyles.style_for(result.kind_id)["shake"] as float
	_fx.shake(shake * (1.6 if result.guard_broken else 1.0))
	_fx.flash(HIT_COLOR, 0.4)
	_fx.number(_hit_point, "-%d" % result.damage, HIT_COLOR, 1.4 if result.guard_broken else 1.0)
	Audio.play(&"guard_break" if result.guard_broken else &"hit")

func _play_strike(kind_id: StringName) -> void:
	_rig.play_sequence([[StringName("strike_%s" % kind_id), STRIKE_SECONDS, Tween.TRANS_EXPO], [&"recover", RECOVER_SECONDS], [RigSpec.IDLE, SETTLE_SECONDS]])

func _show_player_state(state_id: StringName, duration: float) -> void:
	_kill(_lock_tween)
	if _scheme != null:
		_scheme.on_player_state(state_id, duration)
	if not LOCK_COLORS.has(state_id) or is_inf(duration):
		_lock_bar.visible = false
		return
	_lock_bar.configure(LOCK_COLORS[state_id], false)
	_lock_bar.visible = true
	_lock_tween = create_tween()
	_lock_tween.tween_method(func(t: float) -> void: _lock_bar.set_values(1.0 - t, 1.0, false), 0.0, 1.0, maxf(duration, 0.01))
	_lock_tween.tween_callback(func() -> void: _lock_bar.visible = false)
	if state_id == &"staggered":
		_fx.shake(8.0)

func _enemy_focus() -> Vector2:
	return _rig.part_center(&"head") if _rig.has_part(&"head") else _rig.global_position

func _weapon_point() -> Vector2:
	# Weaponless rigs (crow, wings and beak) ring the body, never the rig origin.
	for part: StringName in [&"weapon", &"body", &"torso", &"head"]:
		if _rig.has_part(part):
			return _rig.part_center(part)
	return _rig.global_position

func _load_background(background_name: StringName) -> void:
	var path := BattlePaths.background(background_name)
	if ResourceLoader.exists(path):
		_background.texture = load(path) as Texture2D
		return
	var gradient := Gradient.new()
	gradient.set_color(0, BACK_GRADIENT_TOP)
	gradient.set_color(1, BACK_GRADIENT_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	_background.texture = texture

func _build_hud() -> void:
	_enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_enemy_name.add_theme_font_size_override("font_size", NAME_FONT)
	_enemy_name.add_theme_color_override("font_outline_color", Color.BLACK)
	_enemy_name.add_theme_constant_override("outline_size", 8)
	_hud.add_child(_enemy_name)
	_enemy_bar.configure(Color(0.72, 0.14, 0.14))
	_player_bar.configure(Color(0.3, 0.72, 0.35))
	_stamina_bar.configure(Color(0.92, 0.76, 0.25))
	_telegraph_bar.configure(Color.WHITE, false)
	_telegraph_bar.visible = false
	_lock_bar.visible = false
	for bar: StatBar in [_enemy_bar, _telegraph_bar, _player_bar, _stamina_bar, _lock_bar]:
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.z_index = BARS_Z
		_hud.add_child(bar)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	_hint.add_theme_font_size_override("font_size", HINT_FONT)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 10)
	_hint.z_index = BARS_Z
	_hud.add_child(_hint)
	_build_combo()
	_build_chrome()

func _build_combo() -> void:
	_combo_box.size = COMBO_BOX
	_combo_box.pivot_offset = COMBO_BOX * 0.5
	_combo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_box.modulate.a = 0.0
	_combo_box.z_index = BARS_Z
	_hud.add_child(_combo_box)
	for entry: Array in [[_combo_count, COMBO_COUNT_FONT, Vector2(0, 0), 100.0], [_combo_mult, COMBO_MULT_FONT, Vector2(0, 100), 46.0]]:
		var label := entry[0] as Label
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", entry[1])
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 12)
		label.position = entry[2]
		label.size = Vector2(COMBO_BOX.x, entry[3])
		_combo_box.add_child(label)

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	_landscape = size.x > size.y
	var reserved := _scheme.reserved_height(size) if _scheme != null else 0.0
	var bars_height := LANDSCAPE_BARS_HEIGHT if _landscape else PORTRAIT_BARS_HEIGHT
	var bars_bottom := size.y * (1.0 - BARS_BOTTOM_PAD) - reserved
	var bars_top := bars_bottom - bars_height
	var ground_y := bars_top - BARS_GAP
	var top_limit := size.y * TOP_HUD_SHARE + TOP_HUD_HEIGHT
	var rig_scale := clampf((ground_y - top_limit) / RIG_INK_HEIGHT, 0.1, PORTRAIT_MAX_RIG_SCALE)
	if _landscape:
		rig_scale = minf(rig_scale, size.y * LANDSCAPE_INK_SHARE / RIG_INK_HEIGHT)
	var bg_scale := maxf(maxf(size.x / BG_SIZE.x, ground_y / BG_GROUND_Y), (size.y - ground_y) / BG_BELOW_GROUND)
	_background.visible = _road == null
	_background.position = Vector2((size.x - BG_SIZE.x * bg_scale) * 0.5, ground_y - BG_GROUND_Y * bg_scale)
	_background.size = BG_SIZE * bg_scale
	if _rig != null:
		var near_y := ground_y
		if _road != null:
			rig_scale *= ROAD_RIG_SHARE
			near_y = size.y * ROAD_FEET_Y_SHARE
		var far_y := lerpf(size.y * RoadScene.HORIZON, near_y, 0.5)
		var feet_y := lerpf(far_y, near_y, inverse_lerp(STEP_FAR_SCALE, 1.0, _step))
		var shown := rig_scale * _step
		_rig.position = Vector2(size.x * 0.5 - 512.0 * shown, feet_y - RIG_FEET_Y * shown)
		_rig.scale = Vector2.ONE * shown
		if _shadow != null:
			_shadow.position = Vector2(size.x * 0.5, feet_y)
			_shadow.scale = Vector2(SHADOW_HALF_WIDTH, SHADOW_HALF_HEIGHT) * shown
	_layout_hud(size, bars_top)
	if _scheme != null:
		_scheme.layout(size)
	_update_exclusions()

func _layout_hud(size: Vector2, bars_top: float) -> void:
	var margin := size.x * MARGIN_SHARE
	var top_width := size.x * (0.5 if _landscape else 1.0) - margin * 2.0
	var top_x := (size.x - top_width) * 0.5
	var top_y := size.y * TOP_HUD_SHARE
	_place(_pause_button, Vector2(margin, top_y), Vector2.ONE * PAUSE_BUTTON_SIZE)
	_place(_souls_label, Vector2(margin, top_y + 118.0), Vector2(size.x * 0.4, 44))
	_shop.layout(size, size.y * TOP_HUD_SHARE + TOP_HUD_HEIGHT + SHOP_TOP_GAP, bars_top - BARS_GAP)
	_place(_enemy_name, Vector2(top_x + PAUSE_BUTTON_SIZE, top_y), Vector2(top_width - PAUSE_BUTTON_SIZE * 2.0, 52))
	# Bars start right of the pause button when they would run under it (portrait).
	var bar_x := maxf(top_x, margin + PAUSE_BUTTON_SIZE + margin * 0.5)
	var bar_width := top_x + top_width - bar_x
	_place(_enemy_bar, Vector2(bar_x, top_y + 58), Vector2(bar_width, 36))
	_place(_telegraph_bar, Vector2(bar_x, top_y + 100), Vector2(bar_width, 14))
	var bars_width := size.x * LANDSCAPE_BARS_WIDTH_SHARE if _landscape else size.x - margin * 2.0
	var bars_x := (size.x - bars_width) * 0.5
	var player_height := 36.0 if _landscape else 40.0
	var stamina_height := 26.0 if _landscape else 28.0
	_place(_player_bar, Vector2(bars_x, bars_top), Vector2(bars_width, player_height))
	_place(_stamina_bar, Vector2(bars_x, bars_top + player_height + 6.0), Vector2(bars_width, stamina_height))
	_place(_lock_bar, Vector2(bars_x, bars_top + player_height + stamina_height + 12.0), Vector2(bars_width, 10.0))
	_combo_home = Vector2(size.x - margin - COMBO_BOX.x - SHOP_COLUMN_CLEARANCE, top_y + 130.0) if not _landscape else Vector2(size.x * 0.5 + size.x * 0.12, size.y * 0.3)
	_combo_box.position = _combo_home
	_hit_point = Vector2(size.x * 0.5, bars_top - HIT_NUMBER_LIFT)
	_ring.radius_scale = clampf(minf(size.x, size.y) / RING_SCALE_REF * 1.5, RING_SCALE_MIN, RING_SCALE_MAX)
	if _landscape:
		var column := size.x * LANDSCAPE_HINT_WIDTH_SHARE
		_place(_hint, Vector2(margin, size.y * LANDSCAPE_HINT_Y_SHARE), Vector2(column, LANDSCAPE_HINT_HEIGHT))
		return
	var hint_width := size.x * HINT_WIDTH_SHARE
	_place(_hint, Vector2((size.x - hint_width) * 0.5, bars_top - 190.0), Vector2(hint_width, 110.0))

static func _place(control: Control, at: Vector2, extent: Vector2) -> void:
	control.position = at
	control.size = extent

static func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()

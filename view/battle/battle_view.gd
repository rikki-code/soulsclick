## The duel screen: background, enemy rig, HUD, buttons, effects and end overlays. It only reacts to events it is
## handed (on_* methods) and never reads the duel; GameRoot wires the signals.
class_name BattleView
extends Control

signal continue_pressed
signal revive_pressed
signal menu_pressed

const BG_SIZE := Vector2(1080, 1920)
const BG_GROUND_Y := 1500.0
const RIG_ORIGIN_IN_BG := Vector2(28, 560)
const RIG_FEET_Y := 975.0
const RIG_INK_HEIGHT := 915.0
const LANDSCAPE_INK_SHARE := 0.66
const PORTRAIT_MAX_RIG_SCALE := 1.3
const BG_BELOW_GROUND := 420.0
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
const BACK_GRADIENT_TOP := Color(0.1, 0.08, 0.12)
const BACK_GRADIENT_BOTTOM := Color(0.03, 0.03, 0.04)
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

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	var fx_layer := CanvasLayer.new()
	fx_layer.layer = 3
	add_child(fx_layer)
	fx_layer.add_child(_fx)
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.setup(_stage)
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 4
	add_child(overlay_layer)
	overlay_layer.add_child(_overlay)
	_overlay.continue_pressed.connect(continue_pressed.emit)
	_overlay.revive_pressed.connect(revive_pressed.emit)
	_overlay.menu_pressed.connect(menu_pressed.emit)
	get_viewport().size_changed.connect(_layout)

## Starts (or restarts after a revive) the view for a fresh duel; reads the initial numbers once.
func begin(definition: EnemyDefinition, enemy: Fighter, player: Fighter) -> void:
	_definition = definition
	_enemy_max = enemy.max_hp
	_player_max = player.max_hp
	_telegraphing = false
	_enemy_staggered = false
	_overlay.hide_overlay()
	_kill(_telegraph_tween)
	_kill(_lock_tween)
	_telegraph_bar.visible = false
	_lock_bar.visible = false
	_enemy_name.text = tr(definition.name_key)
	_enemy_bar.set_values(enemy.hp, enemy.max_hp, false)
	_player_bar.set_values(player.hp, player.max_hp, false)
	_stamina_bar.set_values(player.stamina, player.max_stamina, false)
	if _rig != null:
		_rig.queue_free()
	_rig = EnemyRig.new()
	_stage.add_child(_rig)
	_rig.setup(RigSpec.load_for(definition.id, Color(0.9, 0.3, 0.2)))
	_load_background(definition.id)
	set_input_enabled(true)
	_layout()

## Puts the active input scheme into the HUD (below the bars); call before begin().
func mount_scheme(scheme: InputScheme) -> void:
	if _scheme != null:
		_scheme.queue_free()
	_scheme = scheme
	_hud.add_child(scheme)
	_hud.move_child(scheme, 0)
	_layout()

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

func show_victory(souls: int) -> void:
	_overlay.show_victory(souls, END_DELAY)

func show_death(can_revive: bool) -> void:
	_overlay.show_death(can_revive, END_DELAY)

func on_telegraph_started(kind_id: StringName, duration: float, _index: int) -> void:
	_telegraphing = true
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

func on_strike_resolved(result: StrikeResult) -> void:
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

func on_player_attacked(damage: int, enemy_hp: int) -> void:
	_enemy_bar.set_values(enemy_hp, _enemy_max)
	var focus := _enemy_focus()
	_fx.number(focus, str(damage), PUNISH_COLOR if _enemy_staggered else Color.WHITE, 1.4 if _enemy_staggered else 1.0)
	_fx.burst(focus, Color.WHITE, 0.6)
	_rig.flash(0.15)
	Audio.play(&"attack")
	if _telegraphing:
		_rig.nudge(14.0)
		return
	var rest := &"staggered" if _enemy_staggered else RigSpec.IDLE
	_rig.play_sequence([[&"hurt", HURT_SECONDS], [rest, SETTLE_SECONDS]])

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
	return _rig.part_center(&"weapon") if _rig.has_part(&"weapon") else _rig.global_position

func _load_background(enemy_id: StringName) -> void:
	var path := BattlePaths.background(enemy_id)
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
	_background.position = Vector2((size.x - BG_SIZE.x * bg_scale) * 0.5, ground_y - BG_GROUND_Y * bg_scale)
	_background.size = BG_SIZE * bg_scale
	if _rig != null:
		_rig.position = Vector2(size.x * 0.5 - 512.0 * rig_scale, ground_y - RIG_FEET_Y * rig_scale)
		_rig.scale = Vector2.ONE * rig_scale
	_layout_hud(size, bars_top)
	if _scheme != null:
		_scheme.layout(size)

func _layout_hud(size: Vector2, bars_top: float) -> void:
	var margin := size.x * MARGIN_SHARE
	var top_width := size.x * (0.5 if _landscape else 1.0) - margin * 2.0
	var top_x := (size.x - top_width) * 0.5
	var top_y := size.y * TOP_HUD_SHARE
	_place(_enemy_name, Vector2(top_x, top_y), Vector2(top_width, 52))
	_place(_enemy_bar, Vector2(top_x, top_y + 58), Vector2(top_width, 36))
	_place(_telegraph_bar, Vector2(top_x, top_y + 100), Vector2(top_width, 14))
	var bars_width := size.x * LANDSCAPE_BARS_WIDTH_SHARE if _landscape else size.x - margin * 2.0
	var bars_x := (size.x - bars_width) * 0.5
	var player_height := 36.0 if _landscape else 40.0
	var stamina_height := 26.0 if _landscape else 28.0
	_place(_player_bar, Vector2(bars_x, bars_top), Vector2(bars_width, player_height))
	_place(_stamina_bar, Vector2(bars_x, bars_top + player_height + 6.0), Vector2(bars_width, stamina_height))
	_place(_lock_bar, Vector2(bars_x, bars_top + player_height + stamina_height + 12.0), Vector2(bars_width, 10.0))
	_hit_point = Vector2(size.x * 0.5, bars_top - HIT_NUMBER_LIFT)
	var hint_width := size.x * HINT_WIDTH_SHARE
	_place(_hint, Vector2((size.x - hint_width) * 0.5, bars_top - 190.0), Vector2(hint_width, 110.0))

static func _place(control: Control, at: Vector2, extent: Vector2) -> void:
	control.position = at
	control.size = extent

static func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()

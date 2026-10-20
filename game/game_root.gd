## Composition root of the duel scene: builds the Duel from GameSession data, drives it from _process, wires its
## signals to BattleView and the player's input to try_attack / try_block, and owns the end-of-fight flow.
class_name GameRoot
extends Control

const TUNING_PATH := "res://data/tuning/default_tuning.tres"
const ATTACK_KEYS: Array[Key] = [KEY_RIGHT, KEY_D, KEY_J]
const BLOCK_KEYS: Array[Key] = [KEY_LEFT, KEY_A, KEY_F]
const MAX_FRAME := 0.1

var _tuning: CombatTuning
var _duel: Duel
var _view: BattleView
var _scheme: InputScheme
var _gameplay_active := false
var _seed := 0

func _ready() -> void:
	UiScale.fit(get_window())
	get_tree().root.size_changed.connect(func() -> void: UiScale.fit(get_window()))
	add_child(MenuKit.background())
	_tuning = load(TUNING_PATH) as CombatTuning
	_view = BattleView.new()
	add_child(_view)
	_view.continue_pressed.connect(_on_continue)
	_view.revive_pressed.connect(_on_revive)
	_view.menu_pressed.connect(_to_menu)
	var shot := DevShot.install(self)
	_mount_scheme(shot != null)
	if shot != null:
		shot.act_requested.connect(_on_dev_act)
	_seed = int(Time.get_unix_time_from_system())
	_start_duel(GameSession.current_enemy(), -1)
	Audio.play_music(&"battle")

func _exit_tree() -> void:
	_set_gameplay(false)

func _process(delta: float) -> void:
	if _duel != null and not _duel.finished:
		_duel.advance(minf(delta, MAX_FRAME))

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_ESCAPE:
		_to_menu()
	elif ATTACK_KEYS.has(key.keycode):
		_on_attack()
	elif BLOCK_KEYS.has(key.keycode):
		_on_block()

func _mount_scheme(dev_shot: bool) -> void:
	var saved := DevShot.scheme_override if DevShot.scheme_override != "" else GameSession.profile().input_scheme
	var scheme_id := InputSchemeCatalog.resolve(saved)
	_scheme = InputSchemeCatalog.make(scheme_id)
	_scheme.attack_requested.connect(_on_attack)
	_scheme.block_requested.connect(_on_block)
	_view.mount_scheme(_scheme)
	_show_first_hint(scheme_id, dev_shot)

func _show_first_hint(scheme_id: StringName, dev_shot: bool) -> void:
	var profile := GameSession.profile()
	if profile.was_hinted(scheme_id) and not dev_shot:
		return
	if not dev_shot:
		profile.mark_hinted(scheme_id)
		GameSession.save_profile()
	_view.show_hint(tr(InputSchemeCatalog.hint_key(scheme_id)))

func _on_dev_act(action_id: StringName) -> void:
	if action_id == Duel.ACTION_ATTACK:
		_on_attack()
	else:
		_on_block()

func _start_duel(definition: EnemyDefinition, enemy_hp: int) -> void:
	_seed += 1
	_duel = Duel.new(_tuning, definition, _seed)
	if enemy_hp > 0:
		_duel.enemy.hp = enemy_hp
	_wire(_duel)
	_view.begin(definition, _duel.enemy, _duel.player)
	_set_gameplay(true)

func _wire(duel: Duel) -> void:
	duel.telegraph_started.connect(_view.on_telegraph_started)
	duel.strike_resolved.connect(_view.on_strike_resolved)
	duel.player_attacked.connect(_view.on_player_attacked)
	duel.stamina_changed.connect(_view.on_stamina_changed)
	duel.fighter_state_timed.connect(_view.on_fighter_state_timed)
	duel.action_rejected.connect(_view.on_action_rejected)
	duel.duel_finished.connect(_on_duel_finished)

func _on_attack() -> void:
	_press(Duel.ACTION_ATTACK, _duel.try_attack())

func _on_block() -> void:
	_press(Duel.ACTION_BLOCK, _duel.try_block())

func _press(action_id: StringName, accepted: bool) -> void:
	if accepted:
		_view.press_feedback(action_id)

func _on_duel_finished(winner_side: StringName) -> void:
	_set_gameplay(false)
	_view.on_duel_finished(winner_side)
	if winner_side != Fighter.PLAYER:
		_view.show_death(GameSession.can_revive() and Platform.is_rewarded_available())
		return
	var souls := CombatScaling.new(_tuning).souls(_duel.definition.souls_reward)
	var profile := GameSession.profile()
	profile.souls += souls
	GameSession.save_profile()
	_view.show_victory(souls)

func _on_continue() -> void:
	if GameSession.has_next_enemy():
		GameSession.advance_run()
		SceneRouter.to_game()
		return
	_to_menu()

func _on_revive() -> void:
	if not GameSession.can_revive():
		return
	var granted: bool = await Platform.show_rewarded()
	if not granted:
		return
	GameSession.use_revive()
	_start_duel(_duel.definition, _duel.enemy.hp)

func _to_menu() -> void:
	GameSession.reset_run()
	SceneRouter.to_menu()

func _set_gameplay(active: bool) -> void:
	if active == _gameplay_active:
		return
	_gameplay_active = active
	if active:
		Platform.gameplay_started()
	else:
		Platform.gameplay_stopped()

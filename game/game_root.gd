## Composition root of the game scene: owns the `Run`, shows the run screens (omen, doors, rest, level-up, summary), plays each
## fight room as a `Duel` through `BattleView`, saves the run at every room boundary and banks Embers when it ends.
class_name GameRoot
extends Control

const TUNING_PATH := "res://data/tuning/default_tuning.tres"
const ATTACK_KEYS: Array[Key] = [KEY_RIGHT, KEY_D, KEY_J]
const BLOCK_KEYS: Array[Key] = [KEY_LEFT, KEY_A, KEY_F]
const MAX_FRAME := 0.1
const REVIVE_HP_FRACTION := 0.5
const SAVE_HALF_RATE := 0.5
const SCREEN_FLAG := "--screen="
const DEPTH_SOURCE := &"depth"
const BEST_DEPTH := &"best_depth"
const REALM_BACKGROUNDS := 4
## Semitone shift of each realm's battle theme (gen_audio battle_1..4); tonal SFX follow it.
const REALM_KEY_SHIFTS: Array[float] = [0.0, -1.0, -3.0, -5.0]
## Pause between the death of a wave enemy and the next one stepping in.
const WAVE_PAUSE := 0.8

var _tuning: CombatTuning
var _run: Run
var _run_levels: StatLevels
var _inventory := Inventory.new()
var _paused := false
## Depth whose crossroads the player already answered with "go deeper".
var _crossroads_depth := -1
var _duel: Duel
var _wave_index := 0
var _view: BattleView
var _scheme: InputScheme
var _screen: Control
var _gameplay_active := false
var _reviving := false
var _embers_banked := false
var _dev := false
var _summary_screen: SummaryScreen

func _ready() -> void:
	UiScale.fit(get_window())
	get_tree().root.size_changed.connect(func() -> void: UiScale.fit(get_window()))
	add_child(MenuKit.background())
	_tuning = load(TUNING_PATH) as CombatTuning
	_dev = DevShot.install(self) != null
	_run_levels = StatLevels.new(GameSession.run_table())
	if GameSession.launch == GameSession.Launch.CONTINUE_RUN and _load_saved_run():
		pass
	else:
		_new_run()
	var dev_screen := _dev_screen()
	if dev_screen != "":
		_show_dev_screen(dev_screen)
	else:
		_show_phase()

func _exit_tree() -> void:
	_set_gameplay(false)

func _process(delta: float) -> void:
	if _duel != null and not _duel.finished and not _paused:
		_duel.advance(minf(delta, MAX_FRAME))

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.echo:
		return
	if not key.pressed:
		if BLOCK_KEYS.has(key.keycode):
			_on_block_release()
		return
	if key.keycode == KEY_ESCAPE:
		if _view != null:
			_view.toggle_pause()
		else:
			_to_menu()
	elif _view != null and ATTACK_KEYS.has(key.keycode):
		_on_attack()
	elif _view != null and BLOCK_KEYS.has(key.keycode):
		_on_block()

# --- run setup and saves ---------------------------------------------------------------------------------------

func _new_run() -> void:
	GameSession.revives_used = 0
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var config := RunConfig.new(SeedCode.random_seed(rng))
	config.max_hp = PlayerBuilder.build(_tuning, _permanent(), _run_levels).max_hp
	_run = Run.new(config, RealmCatalog.default_realms())

func _load_saved_run() -> bool:
	var envelope := SaveStore.load_run()
	var data: Variant = envelope.get("run")
	if not (data is Dictionary):
		return false
	var run := Run.from_dict(data, RealmCatalog.default_realms())
	if run == null or run.is_ended():
		return false
	_run = run
	_run_levels.from_dict(envelope.get("levels", {}))
	_inventory.from_dict(envelope.get("inventory", {}))
	# Old saves carried a bool `revive_used`.
	GameSession.revives_used = int(envelope.get("revives_used", 1 if bool(envelope.get("revive_used", false)) else 0))
	return true

func _save_run() -> void:
	if _dev or _run == null or _run.is_ended():
		return
	SaveStore.save_run({"run": _run.to_dict(), "levels": _run_levels.to_dict(), "inventory": _inventory.to_dict(), "revives_used": GameSession.revives_used})

func _permanent() -> StatLevels:
	return GameSession.profile().permanent(GameSession.permanent_table())

# --- screens ---------------------------------------------------------------------------------------------------

func _show_phase() -> void:
	match _run.phase:
		Run.PHASE_OMEN:
			# Omens only steer the relic pool and runs offer no relics yet: take the first one silently.
			# Bring OmenScreen back here when relic rewards exist.
			_on_omen_picked(0)
		Run.PHASE_DOORS:
			_save_run()
			if _run.at_crossroads() and _crossroads_depth != _run.depth:
				_show_crossroads()
				return
			# A single door is no choice: walk through it.
			if _run.offer.doors.size() == 1:
				_on_door_picked(0)
				return
			var doors := DoorsScreen.new().setup(_run)
			doors.door_picked.connect(_on_door_picked)
			_show(doors)
		Run.PHASE_ROOM:
			_enter_room()
		_:
			_finish_run()

func _show_crossroads() -> void:
	var screen := CrossroadsScreen.new().setup(_run)
	screen.retire_requested.connect(func() -> void:
		_run.retire()
		_finish_run())
	screen.deeper_requested.connect(func() -> void:
		_crossroads_depth = _run.depth
		_show_phase())
	_show(screen)

func _show(screen: Control) -> void:
	_free_view()
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)
	Audio.play_music(&"menu")

func _on_omen_picked(index: int) -> void:
	_run.choose_omen(index)
	_show_phase()

func _on_door_picked(index: int) -> void:
	_run.choose_door(index)
	_show_phase()

func _enter_room() -> void:
	_save_run()
	var plan := _run.plan
	if plan.is_combat:
		_start_fight(plan)
		return
	# The bonfire has one sensible action: rest without asking.
	if plan.kind_id == BonfireRoom.ID:
		_on_place_finished(BonfireRoom.HEAL)
		return
	if plan.kind_id == AltarRoom.ID:
		_show_altar()
		return
	var panel := PlacePanel.new().setup(_run, plan)
	panel.finished.connect(_on_place_finished)
	_show(panel)

## Altar: stat levels and run buffs for Souls; rebuilt after every purchase so prices and Souls stay current.
func _show_altar() -> void:
	var levels: Array[Dictionary] = []
	for stat in _run_levels.table.stat_ids():
		var cost := _run_levels.cost_of(stat)
		if cost < 0:
			continue
		var value := _stat_value(stat)
		levels.append({"id": stat, "name": RunScreen.stat_name(stat), "value": RunScreen.stat_text(value),
			"next": RunScreen.stat_text(value + _run_levels.table.def_of(stat).increment), "price": cost,
			"affordable": cost <= _run.souls, "ad": cost > _run.souls and Platform.is_rewarded_available()})
	var buffs: Array[Dictionary] = []
	for def in ShopStock.list(_inventory):
		if def.is_consumable():
			continue
		buffs.append({"id": def.id, "name": tr(def.name_key), "info": tr(def.desc_key), "price": _inventory.price_of(def),
			"affordable": _inventory.can_buy(def, _run.souls), "ad": _item_ad_offer(def)})
	var altar := AltarScreen.new().setup(_run, levels, buffs)
	altar.level_requested.connect(func(stat: StringName) -> void:
		if await _buy_run_level_or_ad(stat):
			_save_run()
		_show_altar())
	altar.buff_requested.connect(func(item_id: StringName) -> void:
		await _on_buy_item_requested(item_id)
		_show_altar())
	altar.leave_requested.connect(_on_place_finished.bind(&""))
	_show(altar)

func _on_place_finished(choice: StringName) -> void:
	var result := RoomResult.victory()
	result.choice = choice
	_complete(result)

## Reports the room to the run and moves on to the next screen (or the summary).
func _complete(result: RoomResult) -> void:
	_run.complete_room(result)
	if _run.is_ended():
		_finish_run()
	else:
		_show_phase()

func _stat_value(stat: StringName) -> float:
	return PlayerBuilder.stat_value(_tuning, _permanent(), _run_levels, stat)

## In-battle shop hook: the view asks to buy a run level with the live Souls.
func _on_buy_level_requested(stat: StringName) -> void:
	if not _buy_run_level(stat) or _duel == null:
		return
	var def := _run_levels.table.def_of(stat)
	_duel.player.mods.add(StatModifier.new(stat, Modifier.Stage.ADD, def.increment, PlayerBuilder.RUN_SOURCE))
	_sync_view_shop()
	_save_run()

## Pushes the live Souls and the shop stock (items, run levels) to the view.
func _sync_view_shop() -> void:
	if _view == null:
		return
	# Battle sells consumables only; levels and run buffs are bought at altars.
	var no_levels: Array[Dictionary] = []
	_view.set_shop(_shop_items(), no_levels, _run.souls)

## Shop rows for items: owned consumables show their charges and a Use button.
func _shop_items() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for def in ShopStock.list(_inventory):
		if not def.is_consumable():
			continue
		var price := _inventory.price_of(def)
		rows.append({"id": def.id, "name": tr(def.name_key), "icon_path": "", "price": price, "info": tr(def.desc_key),
			"affordable": _inventory.can_buy(def, _run.souls), "ad": _item_ad_offer(def), "count": _inventory.charges(def.id),
			"usable": def.is_consumable()})
	return rows

## True when the item is unaffordable only for lack of Souls and a rewarded ad can stand in for the price.
func _item_ad_offer(def: ItemDefinition) -> bool:
	return Platform.is_rewarded_available() and not _inventory.can_buy(def, _run.souls) \
			and _inventory.can_buy(def, _inventory.price_of(def))

func _on_buy_item_requested(item_id: StringName) -> void:
	var def := ItemCatalog.get_def(item_id)
	if def == null:
		return
	if _inventory.can_buy(def, _run.souls):
		_run.add_souls(_inventory.buy(def, _run.souls) - _run.souls)
	elif _item_ad_offer(def):
		if not await _watch_ads(1):
			return
		# Free purchase: the Inventory is paid with Souls that are not taken from the run.
		_inventory.buy(def, _inventory.price_of(def))
	else:
		return
	# A healing flask is drunk at once when HP is not full; the rest stays stored.
	if _duel != null and def is ConsumableItem and (def as ConsumableItem).heal_share > 0.0 \
			and _duel.player.hp < _duel.player.max_hp:
		_duel.use_item(item_id)
	_sync_view_shop()
	_save_run()

## Watches `count` rewarded ads in a row; the duel clock stops meanwhile. Any refusal cancels (false).
func _watch_ads(count: int) -> bool:
	var was_paused := _paused
	_paused = true
	var granted := true
	for i in count:
		if not await Platform.show_rewarded():
			granted = false
			break
	_paused = was_paused
	return granted

func _on_use_item_requested(item_id: StringName) -> void:
	if _duel != null and _duel.use_item(item_id):
		_sync_view_shop()

func _on_souls_earned(amount: int, _source: StringName) -> void:
	_run.add_souls(amount)
	_view.on_souls_earned(amount)
	_sync_view_shop()

func _on_pause_requested() -> void:
	_paused = true

func _on_resume_requested() -> void:
	_paused = false

## Pause menu "Abandon": the run ends now (banked like a death).
func _on_abandon_requested() -> void:
	_paused = false
	_free_view()
	_run.abandon()
	_finish_run()

## Pause menu "Main menu": the run stays saved; Continue restarts this room's fight.
func _on_menu_requested() -> void:
	_paused = false
	_save_run()
	_to_menu()

## Per stat: {stat, value, increment, cost, level} for the view's level buttons.
func _shop_levels() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for stat in _run_levels.table.stat_ids():
		var cost := _run_levels.cost_of(stat)
		var increment: float = _run_levels.table.def_of(stat).increment
		rows.append({"id": stat, "name": tr("STAT_%s" % String(stat).to_upper()), "price": cost,
			"info": "%s → +%s" % [_stat_value(stat), increment], "affordable": cost >= 0 and cost <= _run.souls,
			"level": _run_levels.level_of(stat)})
	return rows

## Altar level: pays Souls, or one rewarded ad when the Souls are short.
func _buy_run_level_or_ad(stat: StringName) -> bool:
	var cost := _run_levels.cost_of(stat)
	if cost < 0 or cost <= _run.souls:
		return _buy_run_level(stat)
	if not Platform.is_rewarded_available() or not await _watch_ads(1):
		return false
	return _buy_run_level(stat, true)

## Pays Souls for the next run level; a max hp level also raises the run's hp cap and heals the gain.
func _buy_run_level(stat: StringName, free := false) -> bool:
	var cost := _run_levels.cost_of(stat)
	if cost < 0 or (not free and cost > _run.souls):
		return false
	if not free:
		_run.add_souls(-cost)
	_run_levels.level_up(stat)
	var new_max := PlayerBuilder.build(_tuning, _permanent(), _run_levels).max_hp
	var gain := new_max - _run.config.max_hp
	_run.config.max_hp = new_max
	if gain > 0:
		_run.heal(gain)
	return true

# --- fights ----------------------------------------------------------------------------------------------------

func _start_fight(plan: RoomPlan) -> void:
	_free_view()
	if _screen != null:
		_screen.queue_free()
		_screen = null
	_view = BattleView.new()
	_view.background_id = _realm_background(plan)
	add_child(_view)
	_view.continue_pressed.connect(_on_victory_continue)
	_view.revive_pressed.connect(_on_revive)
	_view.menu_pressed.connect(_on_give_up)
	_view.buy_level_requested.connect(_on_buy_level_requested)
	_view.buy_item_requested.connect(_on_buy_item_requested)
	_view.use_item_requested.connect(_on_use_item_requested)
	_view.pause_requested.connect(_on_pause_requested)
	_view.resume_requested.connect(_on_resume_requested)
	_view.abandon_requested.connect(_on_abandon_requested)
	_view.menu_requested.connect(_on_menu_requested)
	var player := PlayerBuilder.build(_tuning, _permanent(), _run_levels)
	player.hp = clampi(plan.player_hp, 1, player.max_hp)
	_wave_index = 0
	GameSession.begin_fight()
	_duel = _make_duel(plan, 0, player)
	_inventory.begin_fight(_duel)
	_wire(_duel)
	_mount_scheme()
	_view.begin(_view_definition(plan, 0), _duel.enemy, _duel.player)
	_sync_view_shop()
	_set_gameplay(true)
	var realm_slot := _run.depth % REALM_BACKGROUNDS
	Audio.play_music(StringName("battle_%d" % (realm_slot + 1)))
	Audio.set_key_shift(REALM_KEY_SHIFTS[realm_slot])

## Duel against the wave's enemy `index`, fought by `player` (the same Fighter all wave long).
func _make_duel(plan: RoomPlan, index: int, player: Fighter) -> Duel:
	var duel := Duel.new(_tuning, plan.enemy_at(index), plan.combat_seed + index, plan.combat_level, player)
	_apply_room_scaling(duel.enemy, plan, index)
	return duel

## Realm backgrounds cycle with depth (realm_1..realm_4); boss rooms use the realm's boss set.
func _realm_background(plan: RoomPlan) -> StringName:
	var realm_number := _run.depth % REALM_BACKGROUNDS + 1
	return StringName("realm_%d%s" % [realm_number, "_boss" if plan.kind_id == BossRoom.ID else ""])

func _apply_room_scaling(enemy: Fighter, plan: RoomPlan, index := 0) -> void:
	for affix_id in plan.affixes_at(index):
		if ModifierCatalog.has(affix_id):
			enemy.mods.add(ModifierCatalog.create(affix_id))
	var damage := plan.damage_multiplier_at(index)
	var hp := plan.hp_multiplier_at(index)
	if not is_equal_approx(damage, 1.0):
		enemy.mods.add(StatModifier.new(CombatStats.ATTACK_DAMAGE, Modifier.Stage.MUL, damage, DEPTH_SOURCE))
	if not is_equal_approx(hp, 1.0):
		enemy.max_hp = roundi(enemy.max_hp * hp)
	enemy.reset_pools()

## What the view gets: in a wave the name carries the progress ("Wolf 2/3"; an unknown key is shown as is).
func _view_definition(plan: RoomPlan, index: int) -> EnemyDefinition:
	var definition := plan.enemy_at(index)
	if plan.wave_size() <= 1:
		return definition
	var shown := definition.duplicate() as EnemyDefinition
	shown.name_key = "%s %d/%d" % [tr(definition.name_key), index + 1, plan.wave_size()]
	return shown

func _mount_scheme() -> void:
	var saved := DevShot.scheme_override if DevShot.scheme_override != "" else GameSession.profile().input_scheme
	var scheme_id := InputSchemeCatalog.resolve(saved)
	_scheme = InputSchemeCatalog.make(scheme_id, PlayerLoadoutView.from_equipment(PlayerBuilder.START_SHIELD, PlayerBuilder.START_WEAPON))
	_scheme.attack_requested.connect(_on_attack)
	_scheme.block_requested.connect(_on_block)
	_scheme.block_released.connect(_on_block_release)
	_view.mount_scheme(_scheme)
	_show_first_hint(scheme_id)

func _show_first_hint(scheme_id: StringName) -> void:
	var profile := GameSession.profile()
	if profile.was_hinted(scheme_id) and not _dev:
		return
	if not _dev:
		profile.mark_hinted(scheme_id)
		GameSession.save_profile()
	_view.show_hint(tr(InputSchemeCatalog.hint_key(scheme_id)))

func _wire(duel: Duel) -> void:
	duel.strike_timing.connect(_view.on_strike_timing)
	duel.telegraph_started.connect(_view.on_telegraph_started)
	duel.strike_resolved.connect(_view.on_strike_resolved)
	duel.player_attacked.connect(_view.on_player_attacked)
	duel.stamina_changed.connect(_view.on_stamina_changed)
	duel.fighter_state_timed.connect(_view.on_fighter_state_timed)
	duel.action_rejected.connect(_view.on_action_rejected)
	duel.duel_finished.connect(_on_duel_finished)
	duel.combo_changed.connect(_view.on_combo_changed)
	duel.player_hit.connect(_view.on_player_hit)
	duel.souls_earned.connect(_on_souls_earned)

func _on_attack() -> void:
	if _duel != null:
		_press(Duel.ACTION_ATTACK, _duel.try_attack())

func _on_block() -> void:
	if _duel != null:
		_press(Duel.ACTION_BLOCK, _duel.try_block())

## Never gated: a finger lifted after the duel ended must still drop the guard.
func _on_block_release() -> void:
	if _duel != null:
		_duel.try_block_release()

func _press(action_id: StringName, accepted: bool) -> void:
	if accepted and _view != null:
		_view.press_feedback(action_id)

func _on_duel_finished(winner_side: StringName) -> void:
	_set_gameplay(false)
	_view.on_duel_finished(winner_side)
	if winner_side == Fighter.PLAYER:
		if _wave_index + 1 < _run.plan.wave_size():
			_next_wave_enemy()
		else:
			_view.show_victory(_run.plan.souls_reward)
		return
	_view.show_death(GameSession.can_revive() and Platform.is_rewarded_available())

## Next enemy of the wave steps in after a short beat; player hp, stamina, mods, items and combo carry over.
func _next_wave_enemy() -> void:
	var previous := _duel
	await get_tree().create_timer(WAVE_PAUSE).timeout
	if _duel != previous or _view == null or _view.is_queued_for_deletion():
		return
	var plan := _run.plan
	var player := previous.player
	previous.enter_state(player, IdleState.new())
	player.holding_block = false
	_wave_index += 1
	_duel = _make_duel(plan, _wave_index, player)
	_duel.combo = previous.combo
	_inventory.begin_fight(_duel)
	_wire(_duel)
	_view.begin(_view_definition(plan, _wave_index), _duel.enemy, _duel.player)
	if _duel.combo > 0:
		_view.on_combo_changed(_duel.combo, _duel.combo_multiplier())
	_sync_view_shop()
	_set_gameplay(true)

func _on_victory_continue() -> void:
	var hp_after := _duel.player.hp
	_free_view()
	_complete(RoomResult.victory(hp_after))

## Rewarded revive: the same duel continues, the view restarts on its numbers.
func _on_revive() -> void:
	if _reviving or not GameSession.can_revive() or _duel == null:
		return
	_reviving = true
	var granted := await _watch_ads(GameSession.revive_ads())
	_reviving = false
	if not granted or _duel == null or not _duel.revive_player(REVIVE_HP_FRACTION):
		return
	GameSession.use_revive()
	_save_run()
	_view.begin(_view_definition(_run.plan, _wave_index), _duel.enemy, _duel.player)
	_set_gameplay(true)

## Death panel "Back": no revive, the run ends here.
func _on_give_up() -> void:
	_free_view()
	_complete(RoomResult.defeat())

func _free_view() -> void:
	_set_gameplay(false)
	_inventory.end_fight()
	_duel = null
	_scheme = null
	if _view != null:
		_view.queue_free()
		_view = null

# --- end of run ------------------------------------------------------------------------------------------------

func _finish_run() -> void:
	var summary := _run.summary
	if not _embers_banked:
		_embers_banked = true
		if not _dev:
			GameSession.profile().embers += summary.embers
			GameSession.profile().record_best(BEST_DEPTH, summary.depth_reached)
			GameSession.save_profile()
			SaveStore.delete_run()
	var can_save_half := not summary.victory and floori(summary.souls * SAVE_HALF_RATE) > 0 and Platform.is_rewarded_available()
	_summary_screen = SummaryScreen.new().setup(summary, can_save_half)
	_summary_screen.again_pressed.connect(func() -> void:
		GameSession.launch = GameSession.Launch.NEW_RUN
		SceneRouter.to_game())
	_summary_screen.menu_pressed.connect(_to_menu)
	_summary_screen.save_half_pressed.connect(_on_save_half)
	_show(_summary_screen)

## Rewarded "save half": a dead run banks half of its Souls as Embers after all.
func _on_save_half() -> void:
	if _reviving:
		return
	_reviving = true
	var granted := await _watch_ads(GameSession.revive_ads())
	_reviving = false
	var summary := _run.summary
	if not granted or summary.bank_rate >= SAVE_HALF_RATE or _summary_screen == null:
		return
	var extra := floori(summary.souls * SAVE_HALF_RATE) - summary.embers
	summary.bank_rate = SAVE_HALF_RATE
	summary.embers += extra
	GameSession.profile().embers += extra
	GameSession.save_profile()
	_summary_screen.hide_save_half()
	_summary_screen.count_to(summary.embers)

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

# --- dev -------------------------------------------------------------------------------------------------------

## `-- --screen=<doors|fight>` skips the omen pick (with some Souls) and shows the doors or enters the first door; combine with `--shot`.
func _dev_screen() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(SCREEN_FLAG):
			return arg.trim_prefix(SCREEN_FLAG)
	return ""

func _show_dev_screen(screen_id: String) -> void:
	_run.choose_omen(0)
	_run.add_souls(200)
	if screen_id == "fight":
		_run.choose_door(0)
	elif screen_id == "altar":
		_show_altar()
		return
	_show_phase()

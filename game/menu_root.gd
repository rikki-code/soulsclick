## Entry scene: title, Play and Settings pages.
class_name MenuRoot
extends Control

var _content: CenterContainer

func _ready() -> void:
	_fit()
	get_tree().root.size_changed.connect(_fit)
	LanguageSettings.apply(GameSession.profile().language)
	add_child(MenuKit.background())
	_content = CenterContainer.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.theme = MenuKit.big_text_theme()
	add_child(_content)
	_show_main()
	Audio.play_music(&"menu")
	_notify_platform_ready()

func _show_main() -> void:
	var page := _new_page(tr("GAME_TITLE"))
	page.add_child(MenuKit.label(tr("EMBERS_LINE") % GameSession.profile().embers, 40))
	if SaveStore.has_run():
		MenuKit.button(page, tr("MENU_CONTINUE_RUN"), _start_game.bind(GameSession.Launch.CONTINUE_RUN))
	MenuKit.button(page, tr("MENU_NEW_RUN"), _start_game.bind(GameSession.Launch.NEW_RUN))
	MenuKit.button(page, tr("MENU_UPGRADES"), _show_upgrades)
	MenuKit.button(page, tr("MENU_SETTINGS"), _show_settings)
	if not OS.has_feature("web"):
		MenuKit.button(page, tr("MENU_QUIT"), func() -> void: get_tree().quit())

func _start_game(launch: GameSession.Launch) -> void:
	GameSession.launch = launch
	SceneRouter.to_game()

## Permanent levels bought with Embers: HP, stamina, damage, stamina regen.
func _show_upgrades() -> void:
	var page := _new_page(tr("UPGRADES_TITLE"))
	var profile := GameSession.profile()
	var table := GameSession.permanent_table()
	page.add_child(MenuKit.label(tr("EMBERS_LINE") % profile.embers, 40))
	var levels := profile.permanent(table)
	for stat in table.stat_ids():
		var def := table.def_of(stat)
		var cost := levels.cost_of(stat)
		var button := MenuKit.button(page, tr("UPGRADES_ROW") % [RunScreen.stat_name(stat), RunScreen.stat_text(def.increment), levels.level_of(stat), cost], _buy_upgrade.bind(stat))
		button.custom_minimum_size.y = 130.0
		button.disabled = cost > profile.embers
	MenuKit.button(page, tr("MENU_BACK"), _show_main)

func _buy_upgrade(stat: StringName) -> void:
	if GameSession.profile().buy_level(GameSession.permanent_table(), stat):
		GameSession.save_profile()
		Audio.play(&"souls_gain")
	_show_upgrades()

func _show_settings() -> void:
	var page := _new_page(tr("SETTINGS_TITLE"))
	SettingsPage.add_to(page, _show_main, _show_settings)

func _new_page(title: String) -> VBoxContainer:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	return MenuKit.page(_content, title)

func _notify_platform_ready() -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform != null and platform.has_method("game_ready"):
		platform.call("game_ready")

func _fit() -> void:
	UiScale.fit(get_window())

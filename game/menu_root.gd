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
	MenuKit.button(page, tr("MENU_PLAY"), SceneRouter.to_game)
	MenuKit.button(page, tr("MENU_SETTINGS"), _show_settings)
	if not OS.has_feature("web"):
		MenuKit.button(page, tr("MENU_QUIT"), func() -> void: get_tree().quit())

func _show_settings() -> void:
	var page := _new_page(tr("SETTINGS_TITLE"))
	SoundSettings.add_to(page)
	_add_language_row(page)
	_add_controls_row(page)
	MenuKit.button(page, tr("MENU_BACK"), _show_main)

func _add_language_row(page: Control) -> void:
	var codes := LanguageSettings.codes()
	var names: Array[String] = []
	for code in codes:
		names.append(LanguageSettings.label_for(code, tr("LANGUAGE_AUTO")))
	var option := MenuKit.option(names, codes.find(GameSession.profile().language))
	option.item_selected.connect(func(index: int) -> void: _on_language_picked(codes[index]))
	page.add_child(MenuKit.row(tr("SETTINGS_LANGUAGE"), option))

func _add_controls_row(page: Control) -> void:
	var ids := InputSchemeCatalog.ids()
	var names: Array[String] = []
	for id in ids:
		names.append(tr(InputSchemeCatalog.label_key(id)))
	var current := InputSchemeCatalog.resolve(GameSession.profile().input_scheme)
	var option := MenuKit.option(names, ids.find(current))
	option.item_selected.connect(func(index: int) -> void: _on_controls_picked(ids[index]))
	page.add_child(MenuKit.row(tr("SETTINGS_CONTROLS"), option))

func _on_controls_picked(id: StringName) -> void:
	GameSession.profile().input_scheme = String(id)
	GameSession.save_profile()

func _on_language_picked(code: String) -> void:
	GameSession.profile().language = code
	GameSession.save_profile()
	LanguageSettings.apply(code)
	_show_settings.call_deferred()

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

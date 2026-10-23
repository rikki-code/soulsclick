## The settings rows (volumes, language, controls) shared by the main menu and the in-battle pause menu.
class_name SettingsPage
extends RefCounted

## Fills `page` with a sound panel, a game panel (language, controls, tutorial) and a Back button. `on_rebuild` is
## called (deferred) after a language change so the caller can rebuild its texts in the new language.
static func add_to(page: Control, on_back: Callable, on_rebuild: Callable) -> void:
	page.custom_minimum_size.x = MenuKit.WIDE_PAGE_WIDTH
	SoundSettings.add_to(page)
	var group := MenuKit.group(page)
	_add_language_row(group, on_rebuild)
	_add_controls_row(group)
	_add_tutorial_rows(group)
	MenuKit.accent_button(page, page.tr("MENU_BACK"), on_back)

static func _add_language_row(group: Control, on_rebuild: Callable) -> void:
	var codes := LanguageSettings.codes()
	var names: Array[String] = []
	for code in codes:
		names.append(LanguageSettings.label_for(code, group.tr("LANGUAGE_AUTO")))
	var option := MenuKit.option(names, codes.find(GameSession.profile().language))
	option.item_selected.connect(func(index: int) -> void:
		GameSession.profile().language = codes[index]
		GameSession.save_profile()
		LanguageSettings.apply(codes[index])
		on_rebuild.call_deferred())
	group.add_child(MenuKit.row(group.tr("SETTINGS_LANGUAGE"), option))

## A scheme picked from the pause menu applies as soon as the pause closes; from the main menu, in the next battle.
static func _add_controls_row(group: Control) -> void:
	var ids := InputSchemeCatalog.ids()
	var names: Array[String] = []
	for id in ids:
		names.append(group.tr(InputSchemeCatalog.label_key(id)))
	var current := InputSchemeCatalog.resolve(GameSession.profile().input_scheme)
	var option := MenuKit.option(names, ids.find(current))
	option.item_selected.connect(func(index: int) -> void:
		GameSession.profile().input_scheme = String(ids[index])
		GameSession.save_profile())
	group.add_child(MenuKit.row(group.tr("SETTINGS_CONTROLS"), option))

## Re-arms or skips the first-run tutorial (two buttons side by side); it takes effect from the next new game.
static func _add_tutorial_rows(group: Control) -> void:
	var status := MenuKit.hint("")
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", MenuKit.TILE_GAP)
	group.add_child(buttons)
	var show := MenuKit.tile_button(buttons, group.tr("SETTINGS_TUT_SHOW"), func() -> void:
		_set_tutorial_done(false, status, group.tr("SETTINGS_TUT_SHOW_DONE")))
	var skip := MenuKit.tile_button(buttons, group.tr("SETTINGS_TUT_SKIP"), func() -> void:
		_set_tutorial_done(true, status, group.tr("SETTINGS_TUT_SKIP_DONE")))
	for button: Button in [show, skip]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = MenuKit.TILE_HEIGHT
	group.add_child(status)

static func _set_tutorial_done(done: bool, status: Label, message: String) -> void:
	GameSession.profile().tutorial_done = done
	GameSession.save_profile()
	status.text = message

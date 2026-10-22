## The settings rows (volumes, language, controls) shared by the main menu and the in-battle pause menu.
class_name SettingsPage
extends RefCounted

## Fills `page` with the rows and a Back button. `on_rebuild` is called (deferred) after a language change so the
## caller can rebuild its texts in the new language.
static func add_to(page: Control, on_back: Callable, on_rebuild: Callable) -> void:
	SoundSettings.add_to(page)
	_add_language_row(page, on_rebuild)
	_add_controls_row(page)
	_add_tutorial_rows(page)
	MenuKit.button(page, page.tr("MENU_BACK"), on_back)

static func _add_language_row(page: Control, on_rebuild: Callable) -> void:
	var codes := LanguageSettings.codes()
	var names: Array[String] = []
	for code in codes:
		names.append(LanguageSettings.label_for(code, page.tr("LANGUAGE_AUTO")))
	var option := MenuKit.option(names, codes.find(GameSession.profile().language))
	option.item_selected.connect(func(index: int) -> void:
		GameSession.profile().language = codes[index]
		GameSession.save_profile()
		LanguageSettings.apply(codes[index])
		on_rebuild.call_deferred())
	page.add_child(MenuKit.row(page.tr("SETTINGS_LANGUAGE"), option))

## A scheme picked from the pause menu applies as soon as the pause closes; from the main menu, in the next battle.
static func _add_controls_row(page: Control) -> void:
	var ids := InputSchemeCatalog.ids()
	var names: Array[String] = []
	for id in ids:
		names.append(page.tr(InputSchemeCatalog.label_key(id)))
	var current := InputSchemeCatalog.resolve(GameSession.profile().input_scheme)
	var option := MenuKit.option(names, ids.find(current))
	option.item_selected.connect(func(index: int) -> void:
		GameSession.profile().input_scheme = String(ids[index])
		GameSession.save_profile())
	page.add_child(MenuKit.row(page.tr("SETTINGS_CONTROLS"), option))

## Re-arms or skips the first-run tutorial; it takes effect from the next new game.
static func _add_tutorial_rows(page: Control) -> void:
	var status := MenuKit.label("", MenuKit.FONT_SIZE)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MenuKit.button(page, page.tr("SETTINGS_TUT_SHOW"), func() -> void:
		_set_tutorial_done(false, status, page.tr("SETTINGS_TUT_SHOW_DONE")))
	MenuKit.button(page, page.tr("SETTINGS_TUT_SKIP"), func() -> void:
		_set_tutorial_done(true, status, page.tr("SETTINGS_TUT_SKIP_DONE")))
	page.add_child(status)

static func _set_tutorial_done(done: bool, status: Label, message: String) -> void:
	GameSession.profile().tutorial_done = done
	GameSession.save_profile()
	status.text = message

## Headless checks of the Platform facade: adapter choice, ad pause/mute restore, locale fallback, translations.
extends SceneTree

var _failures := 0
var _seen_paused := false
var _seen_muted := false

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		_failures += 1
		print("PLATFORM FAIL: ", label)

func _run() -> void:
	var service := PlatformService.new()
	root.add_child(service)
	await process_frame
	var master := AudioServer.get_bus_index(&"Master")

	_check(PlatformCatalog.detect() == &"null", "desktop selects the null adapter")
	_check(service.adapter_id() == &"null", "service uses the null adapter")
	_check(PlatformCatalog.create(&"unknown").id() == &"null", "unknown id falls back to null")

	service.ad_started.connect(_on_ad_started.bind(master))
	await _check_ad_restores_state(service, master, false, false)
	await _check_ad_restores_state(service, master, true, true)

	_check(service.is_rewarded_available() == OS.is_debug_build(), "rewarded availability follows the build type")

	_check(PlatformService.resolve_locale("de") == "en", "unsupported language falls back to en")
	_check(PlatformService.resolve_locale("") == "en", "empty language falls back to en")
	_check(PlatformService.resolve_locale("ru_RU") == "ru", "ru_RU resolves to ru")
	_check(PlatformService.resolve_locale("EN-us") == "en", "EN-us resolves to en")
	_check(PlatformService.resolve_locale("uk") == "ru", "uk maps to ru")
	_check(not service.locale().is_empty(), "locale is never empty")
	service.set_locale_override("ru")
	_check(service.locale() == "ru" and TranslationServer.get_locale() == "ru", "override applies to TranslationServer")
	_check(TranslationServer.translate("MENU_PLAY") == "Играть", "ru translation of MENU_PLAY")
	service.set_locale_override("en")
	_check(TranslationServer.translate("MENU_PLAY") == "Play", "en translation of MENU_PLAY")
	service.set_locale_override("de")
	_check(service.locale() != "de", "unsupported override is ignored")

	service.free()
	print("PLATFORM ", "PASS" if _failures == 0 else "FAIL (%d)" % _failures)
	quit(0 if _failures == 0 else 1)

func _on_ad_started(_kind: StringName, master: int) -> void:
	_seen_paused = paused
	_seen_muted = AudioServer.is_bus_mute(master)

func _check_ad_restores_state(service: PlatformService, master: int, paused_before: bool, muted_before: bool) -> void:
	var label := "(paused=%s, muted=%s)" % [paused_before, muted_before]
	paused = paused_before
	AudioServer.set_bus_mute(master, muted_before)
	_seen_paused = false
	_seen_muted = false
	var rewarded := await service.show_rewarded()
	_check(_seen_paused and _seen_muted, "rewarded pauses and mutes " + label)
	_check(rewarded == OS.is_debug_build(), "rewarded result follows the build type " + label)
	_check(paused == paused_before and AudioServer.is_bus_mute(master) == muted_before, "rewarded restores state " + label)
	_seen_paused = false
	_seen_muted = false
	await service.show_interstitial()
	_check(_seen_paused and _seen_muted, "interstitial pauses and mutes " + label)
	_check(paused == paused_before and AudioServer.is_bus_mute(master) == muted_before, "interstitial restores state " + label)
	_check(not service.is_ad_active(), "no ad active afterwards " + label)
	paused = false
	AudioServer.set_bus_mute(master, false)

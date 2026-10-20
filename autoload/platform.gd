## The one entry point to portal features, autoloaded as `Platform`: ads, scores, language, lifecycle hints.
## Ads pause the tree and mute Master; losing window focus mutes Master (portal requirement).
class_name PlatformService
extends Node

signal initialized
signal ad_started(kind: StringName)
signal ad_finished(kind: StringName)

const FALLBACK_LOCALE := "en"
const SUPPORTED_LOCALES: PackedStringArray = ["en", "ru"]
const LOCALE_ALIASES := {"be": "ru", "kk": "ru", "uk": "ru", "uz": "ru"}
const MASTER_BUS := &"Master"
const REASON_AD := &"ad"
const REASON_FOCUS := &"focus"
const KIND_INTERSTITIAL := &"interstitial"
const KIND_REWARDED := &"rewarded"

var _adapter: PlatformAdapter
var _locale_override := ""
var _ad_active := false
var _paused_before_ad := false
var _gameplay_running := false
var _mute_reasons: Dictionary = {}  # StringName -> true
var _master_muted_before := false

func _ready() -> void:
	# Must keep running while the tree is paused by an ad.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_adapter = PlatformCatalog.create(PlatformCatalog.detect())
	_adapter.attach(get_tree())
	_apply_locale()
	await _adapter.initialize()
	_apply_locale()
	initialized.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_mute_reason(REASON_FOCUS, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_set_mute_reason(REASON_FOCUS, false)

func adapter_id() -> StringName:
	return _adapter.id()

func is_ad_active() -> bool:
	return _ad_active

func show_interstitial() -> void:
	if _ad_active:
		return
	_begin_ad(KIND_INTERSTITIAL)
	await _adapter.show_interstitial()
	_end_ad(KIND_INTERSTITIAL)

## True only when the reward was earned.
func show_rewarded() -> bool:
	if _ad_active:
		return false
	_begin_ad(KIND_REWARDED)
	var rewarded: bool = await _adapter.show_rewarded()
	_end_ad(KIND_REWARDED)
	return rewarded

func is_rewarded_available() -> bool:
	return _adapter.is_rewarded_available()

func submit_score(board_id: StringName, value: int) -> void:
	_adapter.submit_score(board_id, value)

func gameplay_started() -> void:
	_gameplay_running = true
	_adapter.gameplay_started()

func gameplay_stopped() -> void:
	_gameplay_running = false
	_adapter.gameplay_stopped()

func game_ready() -> void:
	_adapter.game_ready()

func purchase(product_id: StringName) -> bool:
	return await _adapter.purchase(product_id)

func owns(product_id: StringName) -> bool:
	return _adapter.owns(product_id)

## Supported language code: manual override, else the portal language, else the OS language, else `en`.
func locale() -> String:
	if not _locale_override.is_empty():
		return _locale_override
	var from_portal := normalize_locale(_adapter.language())
	if not from_portal.is_empty():
		return from_portal
	return resolve_locale(OS.get_locale_language())

## Empty or unsupported code returns to automatic detection.
func set_locale_override(code: String) -> void:
	_locale_override = normalize_locale(code)
	_apply_locale()

## Supported two-letter code for any language tag ("ru_RU", "uk"), empty when unsupported.
static func normalize_locale(code: String) -> String:
	var language := code.to_lower().replace("-", "_").get_slice("_", 0)
	language = LOCALE_ALIASES.get(language, language)
	return language if SUPPORTED_LOCALES.has(language) else ""

static func resolve_locale(code: String) -> String:
	var normalized := normalize_locale(code)
	return normalized if not normalized.is_empty() else FALLBACK_LOCALE

func _apply_locale() -> void:
	TranslationServer.set_locale(locale())

func _begin_ad(kind: StringName) -> void:
	_ad_active = true
	_paused_before_ad = get_tree().paused
	get_tree().paused = true
	_set_mute_reason(REASON_AD, true)
	if _gameplay_running:
		_adapter.gameplay_stopped()
	ad_started.emit(kind)

func _end_ad(kind: StringName) -> void:
	get_tree().paused = _paused_before_ad
	_set_mute_reason(REASON_AD, false)
	if _gameplay_running:
		_adapter.gameplay_started()
	_ad_active = false
	ad_finished.emit(kind)

# Master is muted while any reason is active; its previous mute state returns with the last reason.
func _set_mute_reason(reason: StringName, active: bool) -> void:
	var was_muted := not _mute_reasons.is_empty()
	if active:
		_mute_reasons[reason] = true
	else:
		_mute_reasons.erase(reason)
	var muted := not _mute_reasons.is_empty()
	if muted == was_muted:
		return
	var bus := AudioServer.get_bus_index(MASTER_BUS)
	if muted:
		_master_muted_before = AudioServer.is_bus_mute(bus)
	AudioServer.set_bus_mute(bus, true if muted else _master_muted_before)

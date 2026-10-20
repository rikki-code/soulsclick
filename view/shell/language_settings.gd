## Language choice: Auto (platform or OS language), English, Russian. The code is kept in ProfileData.
class_name LanguageSettings
extends RefCounted

const AUTO := ""
const NATIVE_NAMES := {"en": "English", "ru": "Русский"}

static func codes() -> Array[String]:
	var result: Array[String] = [AUTO]
	for code: String in NATIVE_NAMES:
		result.append(code)
	return result

## Auto is translated; real languages are shown in their own language.
static func label_for(code: String, auto_label: String) -> String:
	return auto_label if code == AUTO else NATIVE_NAMES[code]

## Platform owns detection (override, portal language, OS language, fallback) and applies the locale.
static func apply(code: String) -> void:
	Platform.set_locale_override(code)

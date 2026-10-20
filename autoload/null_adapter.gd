## Desktop, itch.io and dev builds: no portal. Debug builds fake a rewarded ad so the revive flow can be exercised.
class_name NullAdapter
extends PlatformAdapter

const FAKE_AD_SECONDS := 0.15

func id() -> StringName:
	return &"null"

func show_rewarded() -> bool:
	if not OS.is_debug_build():
		return false
	await _wait(FAKE_AD_SECONDS)
	return true

func is_rewarded_available() -> bool:
	return OS.is_debug_build()

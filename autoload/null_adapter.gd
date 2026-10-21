## Desktop, itch.io and dev builds: no portal. Debug builds fake a rewarded ad so the revive flow can be exercised.
class_name NullAdapter
extends PlatformAdapter

const AD_LAYER := 100

## Debug builds and the web demo have no portal SDK yet: the "ad" is the FakeAd animation.
static func _fake_ads() -> bool:
	return OS.is_debug_build() or OS.has_feature("web")

func id() -> StringName:
	return &"null"

func show_rewarded() -> bool:
	if not _fake_ads():
		return false
	var layer := CanvasLayer.new()
	layer.layer = AD_LAYER
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var ad := FakeAd.new()
	layer.add_child(ad)
	(Engine.get_main_loop() as SceneTree).root.add_child(layer)
	await ad.finished
	layer.queue_free()
	return true

func is_rewarded_available() -> bool:
	return _fake_ads()

## Content scale shared by every top-level scene.
class_name UiScale
extends RefCounted

## Enlarges all 2D UI (text, buttons, bars) for touch; layout code works in the scaled canvas.
const FACTOR := 1.25

## The project base size is portrait; a landscape window gets it turned landscape, so the UI is
## never shrunk to fit a 1080-wide canvas on a wide screen.
static func fit(window: Window) -> void:
	var base := Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	var landscape := window.size.x > window.size.y
	var wanted := Vector2i(maxi(base.x, base.y), mini(base.x, base.y)) if landscape else Vector2i(mini(base.x, base.y), maxi(base.x, base.y))
	if window.content_scale_size != wanted:
		window.content_scale_size = wanted
	window.content_scale_factor = FACTOR

## Dev panel with engine counters (fps, frame time, objects, nodes, orphan nodes, resources, memory, draw calls), shown on screen and printed to the console every few seconds. Enabled by the user arg `--perf` or, in the web build, the URL query `?perf`.
class_name PerfOverlay
extends CanvasLayer

const LAYER := 200
const REFRESH_SECONDS := 0.5
const LOG_SECONDS := 10.0
const FONT_SIZE := 26
const OUTLINE_SIZE := 6
const LABEL_POSITION := Vector2(10, 10)
const MB := 1048576.0
const MS_PER_SECOND := 1000.0
const USER_ARG := "--perf"
const WEB_QUERY_JS := "new URLSearchParams(window.location.search).has('perf')"

var _label: Label
var _refresh_left := 0.0
var _log_left := LOG_SECONDS


static func wanted() -> bool:
	if OS.get_cmdline_user_args().has(USER_ARG):
		return true
	return OS.has_feature("web") and bool(JavaScriptBridge.eval(WEB_QUERY_JS))


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.position = LABEL_POSITION
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	add_child(_label)


func _process(delta: float) -> void:
	_refresh_left -= delta
	_log_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = REFRESH_SECONDS
	var text := _build_text()
	_label.text = text
	if _log_left <= 0.0:
		_log_left = LOG_SECONDS
		print("[perf] " + text.replace("\n", "  "))


func _build_text() -> String:
	var lines: PackedStringArray = [
		"fps %d  frame %.1f ms" % [_mon(Performance.TIME_FPS), _mon(Performance.TIME_PROCESS) * MS_PER_SECOND],
		"objects %d  nodes %d  orphans %d  res %d" % [_mon(Performance.OBJECT_COUNT), _mon(Performance.OBJECT_NODE_COUNT), _mon(Performance.OBJECT_ORPHAN_NODE_COUNT), _mon(Performance.OBJECT_RESOURCE_COUNT)],
		"mem %.0f MB  tex %.0f MB  buf %.0f MB" % [_mon(Performance.MEMORY_STATIC) / MB, _mon(Performance.RENDER_TEXTURE_MEM_USED) / MB, _mon(Performance.RENDER_BUFFER_MEM_USED) / MB],
		"draws %d  prims %d" % [_mon(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), _mon(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)],
	]
	return "\n".join(lines)


func _mon(monitor: Performance.Monitor) -> float:
	return Performance.get_monitor(monitor)

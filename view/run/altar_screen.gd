## Altar room: spend run Souls on stat levels and run-long buffs, then leave. GameRoot owns the purchases and
## rebuilds the screen after each one, so the scroll offset and the last bought tile survive in statics.
class_name AltarScreen
extends RunScreen

signal level_requested(stat: StringName)
signal buff_requested(item_id: StringName)
signal item_use_requested(item_id: StringName)
signal leave_requested

const GOLD := Color(1.0, 0.82, 0.38)
const TILE_HEIGHT := 130.0
const MARGIN := 16
const GAP := 10
const MAX_WIDTH := 1100.0
const WIDE_LAYOUT := 1100.0
const LEAVE_HEIGHT := 110.0

static var _saved_scroll := 0
static var _last_bought := &""

var _scroll: ScrollContainer
var _grid: GridContainer
var _tiles := {}

## `levels` rows: {id, name, value, next, price, affordable, ad}; `buffs` rows: {id, name, info, price, affordable, ad}.
func setup(run: Run, levels: Array[Dictionary], buffs: Array[Dictionary], items: Array[Dictionary] = []) -> AltarScreen:
	add_child(MenuKit.background())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP)
	margin.add_child(column)
	margin.resized.connect(func() -> void:
		var side := maxi(MARGIN, int((margin.size.x - MAX_WIDTH) * 0.5))
		margin.add_theme_constant_override("margin_left", side)
		margin.add_theme_constant_override("margin_right", side))
	_header(column, run)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	column.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", GAP)
	_grid.add_theme_constant_override("v_separation", GAP)
	_scroll.add_child(_grid)
	_scroll.resized.connect(func() -> void: _grid.columns = 3 if _scroll.size.x >= WIDE_LAYOUT - 1.0 else 2)
	for row in levels:
		var detail := "%s  →  %s" % [row["value"], row["next"]]
		_tile(row, row["name"], detail, level_requested.emit.bind(row["id"]))
	for row in buffs:
		_tile(row, row["name"], row["info"], buff_requested.emit.bind(row["id"]))
	for row in items:
		_tile(row, row["name"], row["info"], buff_requested.emit.bind(row["id"]))
	var leave := Button.new()
	leave.text = tr("ALTAR_LEAVE")
	leave.custom_minimum_size.y = LEAVE_HEIGHT
	leave.add_theme_font_size_override("font_size", 36)
	leave.add_theme_color_override("font_color", GOLD)
	leave.add_theme_stylebox_override("normal", _style(Color(0.16, 0.12, 0.08), GOLD.darkened(0.2), 3))
	leave.add_theme_stylebox_override("hover", _style(Color(0.2, 0.15, 0.1), GOLD, 3))
	leave.add_theme_stylebox_override("pressed", _style(Color(0.26, 0.19, 0.1), GOLD, 3))
	leave.pressed.connect(func() -> void:
		_saved_scroll = 0
		_last_bought = &""
		leave_requested.emit())
	column.add_child(leave)
	return self

func _ready() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_scroll.scroll_vertical = _saved_scroll
	_scroll.get_v_scroll_bar().value_changed.connect(func(value: float) -> void: _saved_scroll = int(value))
	if _tiles.has(_last_bought):
		_pulse(_tiles[_last_bought])
	_last_bought = &""

func _header(parent: Control, run: Run) -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	parent.add_child(box)
	box.add_child(SoulGlyph.make(40.0, GOLD))
	var souls := MenuKit.label(str(run.souls), 60)
	souls.add_theme_color_override("font_color", GOLD)
	box.add_child(souls)
	var life := MenuKit.label("%s %d/%d" % [tr("ALTAR_HP"), run.hp, run.config.max_hp], 36)
	life.add_theme_color_override("font_color", Color(0.95, 0.4, 0.45))
	box.add_child(life)
	var hint := _tile_label(tr("ALTAR_HINT"), 20, MUTED, 2)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(hint)

func _tile(row: Dictionary, title: String, detail: String, on_pressed: Callable) -> void:
	var ad := bool(row.get("ad", false))
	var affordable := bool(row["affordable"])
	var usable := affordable or ad
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(0, TILE_HEIGHT)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.clip_contents = true
	tile.disabled = not usable
	var edge := GOLD.darkened(0.25) if affordable else (Color(0.4, 0.75, 0.85) if ad else Color(0.25, 0.22, 0.26))
	for state in ["normal", "disabled"]:
		tile.add_theme_stylebox_override(state, _style(Color(0.11, 0.09, 0.13), edge, 2))
	tile.add_theme_stylebox_override("hover", _style(Color(0.16, 0.13, 0.17), edge.lightened(0.2), 2))
	tile.add_theme_stylebox_override("pressed", _style(Color(0.22, 0.17, 0.12), GOLD, 3))
	tile.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var inner := MarginContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		inner.add_theme_constant_override("margin_" + side, 10)
	tile.add_child(inner)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 8)
	inner.add_child(line)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	line.add_child(box)
	box.add_child(_tile_label(title, 28, Color.WHITE, 1))
	box.add_child(_tile_label(detail, 20, MUTED, 2))
	line.add_child(_price_row(int(row["price"]), affordable, ad))
	var use_button: Button = null
	if bool(row.get("can_use", false)):
		use_button = Button.new()
		use_button.text = "%s x%d" % [tr("ALTAR_USE"), int(row["count"])]
		use_button.custom_minimum_size = Vector2(110, 0)
		use_button.add_theme_font_size_override("font_size", 24)
		use_button.add_theme_color_override("font_color", Color(0.55, 0.85, 0.6))
		use_button.pressed.connect(func() -> void:
			_last_bought = row["id"]
			item_use_requested.emit(row["id"]))
		line.add_child(use_button)
	inner.modulate = Color.WHITE if usable else Color(1, 1, 1, 0.45)
	tile.pressed.connect(func() -> void:
		_last_bought = row["id"]
		_pulse(tile)
		on_pressed.call())
	_tiles[row["id"]] = tile
	_grid.add_child(tile)

func _tile_label(text: String, size: int, color: Color, lines: int) -> Label:
	var label := MenuKit.label(text, size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = lines
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	return label

func _price_row(price: int, affordable: bool, ad: bool) -> Control:
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	var amount := _tile_label(str(price), 30, GOLD if affordable else MUTED.darkened(0.3), 1)
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(amount)
	row.add_child(SoulGlyph.make(26.0, GOLD if affordable else GOLD.darkened(0.4)))
	if ad and not affordable:
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.size_flags_horizontal = Control.SIZE_SHRINK_END
		badge.add_theme_stylebox_override("panel", _style(Color(0.1, 0.3, 0.36), Color(0.4, 0.75, 0.85), 2, 6))
		var text := _tile_label("AD", 20, Color(0.75, 0.95, 1.0), 1)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.custom_minimum_size.x = 44
		badge.add_child(text)
		col.add_child(badge)
	return col

func _pulse(tile: Control) -> void:
	tile.pivot_offset = tile.size * 0.5
	tile.modulate = Color(2.0, 1.7, 1.1)
	var tween := tile.create_tween().set_parallel(true)
	tween.tween_property(tile, "modulate", Color.WHITE, 0.45)
	tween.tween_property(tile, "scale", Vector2.ONE, 0.45).from(Vector2(1.07, 1.07)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func _style(fill: Color, border: Color, width: int, radius := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

## Small flame-like soul mark, drawn so it needs no font glyph or texture.
class SoulGlyph extends Control:
	var color := Color.WHITE

	static func make(size: float, tint: Color) -> SoulGlyph:
		var glyph := SoulGlyph.new()
		glyph.color = tint
		glyph.custom_minimum_size = Vector2(size * 0.7, size)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return glyph

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var radius := w * 0.5
		draw_circle(Vector2(w * 0.5, h - radius), radius, color)
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.5, 0.0), Vector2(w, h - radius), Vector2(0.0, h - radius)]), color)
		draw_circle(Vector2(w * 0.5, h - radius * 1.1), radius * 0.38, color.darkened(0.65))

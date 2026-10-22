## In-battle consumable slots: an always-visible column of big round slots on the right edge, one tap = one action
## (owned: use; count 0 and affordable or ad: buy, the game layer uses it at once). Long-press shows name + info.
## Pure view: the game layer owns prices and logic and answers with set_shop / set_souls.
class_name ShopPanel
extends Control

signal buy_item_requested(item_id: StringName)
signal buy_level_requested(stat_id: StringName)
signal use_item_requested(item_id: StringName)
## The button column moved; BattleView refreshes the input exclusion rects.
signal rects_changed

const BUTTON_SIZE := 160.0
const MIN_BUTTON_SIZE := 150.0
const COOLDOWN_SECONDS := 0.7
const BUTTON_GAP := 12.0
const EDGE_GAP := 10.0
const LONG_PRESS_SECONDS := 0.4
const GLYPH_FONT := 44
const PRICE_FONT := 32
const BADGE_FONT := 28
const TIP_FONT := 24
const TIP_WIDTH := 380.0
const FILL_COLOR := Color(0.06, 0.05, 0.07, 0.88)
const BORDER_COLOR := Color(0.45, 0.48, 0.55, 0.9)
const GOLD := Color(1.0, 0.82, 0.3)
const GREEN := Color(0.55, 1.0, 0.6)
const GREY := Color(0.5, 0.5, 0.52, 0.8)
const PULSE_SPEED := 5.0

## One round button; the panel pushes data in, it only draws.
class ShopButton extends Button:
	var glyph := ""
	var price := 0
	var count := 0
	var is_item := false
	var can_act := false
	var maxed := false
	var ad := false
	var icon_tex: Texture2D
	var pulse := 0.0
	## 1 -> 0 after a tap: radial wipe.
	var cooldown := 0.0

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 3.0
		draw_circle(c, r, FILL_COLOR)
		var owned := is_item and count > 0
		var ring := GREY
		if can_act:
			ring = GREEN if owned else GOLD.lerp(Color.WHITE, pulse * 0.6)
		draw_arc(c, r, 0.0, TAU, 48, ring, 3.0 + (pulse * 3.0 if can_act else 0.0), true)
		if can_act:
			draw_arc(c, r + 3.0 + pulse * 4.0, 0.0, TAU, 48, Color(ring, 0.5 * (1.0 - pulse)), 2.0, true)
		var tint := Color.WHITE if (can_act or ad) else GREY
		var font := ThemeDB.fallback_font
		var show_price := not owned
		var price_text := "MAX" if maxed else str(price)
		var glyph_y := c.y + (2.0 if show_price else 10.0)
		if icon_tex != null:
			var icon_size := r * (1.0 if show_price else 1.3)
			draw_texture_rect(icon_tex, Rect2(c.x - icon_size * 0.5, c.y - icon_size * (0.62 if show_price else 0.5), icon_size, icon_size), false, tint)
		else:
			var gfont := GLYPH_FONT if glyph.length() <= 2 else GLYPH_FONT - 6
			draw_string(font, Vector2(0.0, glyph_y - (8.0 if show_price else 0.0)), glyph, HORIZONTAL_ALIGNMENT_CENTER, size.x, gfont, tint)
		if show_price:
			if ad:
				draw_string(font, Vector2(0.0, c.y + r * 0.62), BattleText.text("AD_BADGE", "AD"), HORIZONTAL_ALIGNMENT_CENTER, size.x, PRICE_FONT, GREEN)
			else:
				draw_string(font, Vector2(0.0, c.y + r * 0.62), price_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, PRICE_FONT, GOLD if can_act else GREY)
		if cooldown > 0.0:
			var pts := PackedVector2Array([c])
			var steps := 32
			for i in steps + 1:
				pts.append(c + Vector2.from_angle(-PI * 0.5 + TAU * cooldown * i / steps) * (r - 2.0))
			draw_colored_polygon(pts, Color(1, 1, 1, 0.3))
		if is_item and count > 0:
			var b := Vector2(size.x - 30.0, 30.0)
			draw_circle(b, 30.0, GREEN)
			draw_string(font, Vector2(b.x - 30.0, b.y + 10.0), "x%d" % count, HORIZONTAL_ALIGNMENT_CENTER, 60.0, BADGE_FONT, Color.BLACK)

var _souls := 0
var _buttons: Array[ShopButton] = []
var _keys: Array[String] = []
var _entries: Array[Dictionary] = []
var _tip := PanelContainer.new()
var _tip_label := Label.new()
var _hold: ShopButton
var _hold_time := 0.0
var _long_fired := false
var _time := 0.0
var _view_size := Vector2(1080, 1920)
var _band := Vector2(0, 1000)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.07, 0.95)
	style.border_color = BORDER_COLOR
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	_tip.add_theme_stylebox_override("panel", style)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	_tip.z_index = 10
	_tip_label.add_theme_font_size_override("font_size", TIP_FONT)
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.custom_minimum_size.x = TIP_WIDTH
	_tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_child(_tip_label)
	add_child(_tip)

func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * PULSE_SPEED)
	for btn in _buttons:
		if btn.cooldown > 0.0:
			btn.cooldown = maxf(btn.cooldown - delta / COOLDOWN_SECONDS, 0.0)
			btn.queue_redraw()
		if btn.can_act:
			btn.pulse = pulse
			btn.queue_redraw()
	if _hold != null and not _long_fired:
		_hold_time += delta
		if _hold_time >= LONG_PRESS_SECONDS:
			_long_fired = true
			_show_tip(_hold)

## `top` / `bottom`: vertical band the column may use (below the top HUD, above the player bars).
func layout(view_size: Vector2, top: float, bottom: float) -> void:
	_view_size = view_size
	_band = Vector2(top, bottom)
	_place_buttons()

## Screen rects that swallow presses: every button.
func input_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for btn in _buttons:
		rects.append(Rect2(btn.global_position, btn.size).grow(6.0))
	return rects

## Screen rect of a slot for the tutorial pointer: `slot_<item id>` for a consumable, `shop` for the first slot. Empty rect when absent.
func rect_of(target: StringName) -> Rect2:
	var index := 0 if target == &"shop" else _keys.find("consumable:%s" % String(target).trim_prefix("slot_"))
	if index < 0 or index >= _buttons.size():
		return Rect2()
	return Rect2(_buttons[index].global_position, _buttons[index].size)

## items / levels: dictionaries {id, name, icon_path, price, info, affordable}; items may also carry `count` (owned) and
## `ad` (unaffordable but a rewarded ad grants it: tap still emits the buy signal), `usable` (consumable: a tap uses it while count > 0). Levels with price < 0 are maxed.
func set_shop(items: Array[Dictionary], levels: Array[Dictionary], souls: int) -> void:
	_souls = souls
	var entries: Array[Dictionary] = []
	var keys: Array[String] = []
	for entry in levels:
		entries.append(_with_kind(entry, &"level"))
	for entry in items:
		if bool(entry.get("usable", false)):
			entries.append(_with_kind(entry, &"consumable"))
	for entry in items:
		if not bool(entry.get("usable", false)):
			entries.append(_with_kind(entry, &"buff"))
	for entry in entries:
		keys.append("%s:%s" % [entry["kind"], entry.get("id", "")])
	_entries = entries
	if keys != _keys:
		_keys = keys
		_rebuild()
	_refresh()

func set_souls(souls: int) -> void:
	_souls = souls
	_refresh()

static func _with_kind(entry: Dictionary, kind: StringName) -> Dictionary:
	var copy := entry.duplicate()
	copy["kind"] = kind
	return copy

# Buttons are rebuilt only when the set of entries changes, so a press or long-press survives data refreshes.
func _rebuild() -> void:
	_stop_hold()
	for btn in _buttons:
		btn.queue_free()
	_buttons.clear()
	for i in _entries.size():
		var btn := ShopButton.new()
		btn.button_down.connect(_on_down.bind(btn))
		btn.button_up.connect(_on_up)
		btn.pressed.connect(_on_pressed.bind(i))
		add_child(btn)
		_buttons.append(btn)
	_place_buttons()

func _refresh() -> void:
	for i in _buttons.size():
		var entry := _entries[i]
		var btn := _buttons[i]
		var kind := StringName(entry["kind"])
		var price := int(entry.get("price", 0))
		btn.is_item = kind != &"level"
		btn.price = price
		btn.count = int(entry.get("count", 0)) if kind == &"consumable" else 0
		btn.maxed = price < 0
		var affordable := not btn.maxed and _souls >= price and bool(entry.get("affordable", true))
		btn.ad = not affordable and btn.count == 0 and not btn.maxed and bool(entry.get("ad", false))
		btn.can_act = affordable or btn.count > 0 or btn.ad
		btn.glyph = _glyph_of(entry)
		var icon_path := str(entry.get("icon_path", ""))
		btn.icon_tex = load(icon_path) as Texture2D if icon_path != "" and ResourceLoader.exists(icon_path) else null
		if not btn.can_act:
			btn.pulse = 0.0
		btn.queue_redraw()
	if _hold != null and _tip.visible:
		_show_tip(_hold)

## Short button label from the locale table (GLYPH_<ID>), else the first letters of the translated name.
static func _glyph_of(entry: Dictionary) -> String:
	var fallback := str(entry.get("name", "?")).left(2).to_upper()
	return BattleText.text("GLYPH_" + str(entry.get("id", "")).to_upper(), fallback)

func _place_buttons() -> void:
	var count := _buttons.size()
	if count == 0:
		rects_changed.emit()
		return
	var avail := maxf(_band.y - _band.x, 100.0)
	var side := clampf((avail - BUTTON_GAP * (count - 1)) / count, MIN_BUTTON_SIZE, BUTTON_SIZE)
	# Too many for one column even at the minimum size: spill into a second column to the left.
	var per_column := maxi(int(floor((avail + BUTTON_GAP) / (side + BUTTON_GAP))), 1)
	for i in count:
		@warning_ignore("integer_division")
		var col := i / per_column
		var row := i % per_column
		var btn := _buttons[i]
		btn.size = Vector2.ONE * side
		btn.pivot_offset = btn.size * 0.5
		btn.position = Vector2(_view_size.x - EDGE_GAP - side - col * (side + BUTTON_GAP), _band.x + row * (side + BUTTON_GAP))
		btn.queue_redraw()
	rects_changed.emit()

func _on_down(btn: ShopButton) -> void:
	_hold = btn
	_hold_time = 0.0
	_long_fired = false

func _on_up() -> void:
	# `pressed` fires right after button_up; keep _long_fired until it has been consumed.
	_hold = null
	_tip.visible = false

func _stop_hold() -> void:
	_hold = null
	_long_fired = false
	_tip.visible = false

func _on_pressed(index: int) -> void:
	if _long_fired:
		_long_fired = false
		return
	if index >= _entries.size():
		return
	var entry := _entries[index]
	var id := StringName(str(entry.get("id", "")))
	if index < _buttons.size() and _buttons[index].can_act:
		_buttons[index].cooldown = 1.0
	match StringName(entry["kind"]):
		&"level":
			buy_level_requested.emit(id)
		&"consumable":
			if int(entry.get("count", 0)) > 0:
				use_item_requested.emit(id)
			else:
				buy_item_requested.emit(id)
		_:
			buy_item_requested.emit(id)

func _show_tip(btn: ShopButton) -> void:
	var index := _buttons.find(btn)
	if index < 0:
		return
	var entry := _entries[index]
	_tip_label.text = "%s\n%s" % [str(entry.get("name", "")), str(entry.get("info", ""))]
	_tip.reset_size()
	_tip.visible = true
	var pos := Vector2(btn.position.x - _tip.size.x - 12.0, btn.position.y + btn.size.y * 0.5 - _tip.size.y * 0.5)
	pos.x = maxf(pos.x, 8.0)
	pos.y = clampf(pos.y, 8.0, maxf(_view_size.y - _tip.size.y - 8.0, 8.0))
	_tip.position = pos

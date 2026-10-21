## After a boss: a stone-ringed HOME gate glows on the left of the road (pale blue-white light, ground glow); DEEPER is
## the road itself, running on into the distance with a faint glow and tiny silhouettes of the next realm on the
## horizon. Drawn procedurally over a RoadScene in muted road colours. Tap the gate = home, tap the road ahead = deeper.
class_name PortalView
extends Control

signal home_picked
signal deeper_picked

const Z := 0.04 ## road depth of the gate base
const LANE := -0.72 ## gate lateral offset in road half-widths
const GATE_K := 0.13 ## gate unit, fraction of the screen width
const RIM_IN := Vector2(0.95, 1.6) ## inner ellipse radii, units
const RIM_OUT := Vector2(1.22, 1.9) ## outer ellipse radii (stone ring)
const BLOCKS := 20
const GLOW := Color(0.74, 0.86, 1.0)
const WARM := Color(1.0, 0.84, 0.6)
const EMBER := Color(0.9, 0.3, 0.16)

var _souls := 0
var _depth := 1
var _grow := 1.0
var _time := 0.0
var _hover := -1
var _pressed := -1
var _act: Array[float] = [0.0, 0.0]
var _tween: Tween
var _road: RoadScene
var _road_checked := false
static var _table: Array[float] = [] ## fixed per-piece randomness (stones, moss, motes)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void: _hover = -1)


func setup(souls: int, next_depth: int) -> PortalView:
	_souls = souls
	_depth = next_depth
	queue_redraw()
	return self


## The gate and the far glow fade in out of the dusk.
func reveal(duration := 1.1) -> void:
	if _tween:
		_tween.kill()
	_grow = 0.0
	_tween = create_tween()
	_tween.tween_method(_set_grow, 0.0, 1.0, duration)
	queue_redraw()


func _set_grow(v: float) -> void:
	_grow = v
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	var focus := _pressed if _pressed >= 0 else _hover
	for i in 2:
		_act[i] = move_toward(_act[i], 1.0 if i == focus else 0.0, delta * 6.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover = _hit(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed = _hit(event.position)
			if _pressed >= 0:
				accept_event()
		else:
			var i := _hit(event.position)
			var was := _pressed
			_pressed = -1
			if i >= 0 and i == was and _grow > 0.5:
				accept_event()
				if i == 0:
					home_picked.emit()
				else:
					deeper_picked.emit()


## 0 = the gate (generous ellipse), 1 = the road ahead to the right of it, -1 = nothing.
func _hit(p: Vector2) -> int:
	var k := _unit()
	var c := _base() - Vector2(0.0, k * RIM_OUT.y)
	if Vector2((p.x - c.x) / (k * 1.7), (p.y - c.y) / (k * 2.4)).length() < 1.0:
		return 0
	if p.x > c.x + k * 1.2 and p.y > size.y * 0.25 and p.y < size.y * 0.9:
		return 1
	return -1


# -- geometry ----------------------------------------------------------------------------------------

func _find_road() -> void:
	_road_checked = true
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is RoadScene:
			_road = n
			return
		stack.append_array(n.get_children())


func _unit() -> float:
	return size.x * GATE_K


func _shift(z: float) -> float:
	return _road._shift(z) if is_instance_valid(_road) else 0.0


func _ground(z: float, lane := 0.0) -> Vector2:
	var s := 1.0 / (1.0 + RoadScene.DEPTH_K * z)
	var hy := size.y * RoadScene.HORIZON
	return Vector2(size.x * 0.5 + _shift(z) + lane * size.x * RoadScene.ROAD_HALF * s, hy + (size.y - hy) * s)


func _base() -> Vector2:
	return _ground(Z, LANE)


static func _ell(c: Vector2, rx: float, ry: float, a0 := 0.0, a1 := TAU, n := 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n + 1:
		var a := lerpf(a0, a1, float(k) / float(n))
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Filled ellipse as a triangle fan: `inner` colour at the centre fading to `outer` at the rim.
static func _fan(ci: CanvasItem, c: Vector2, rx: float, ry: float, inner: Color, outer: Color, _boost := 1.0) -> void:
	var n := 32
	var prev := c + Vector2(rx, 0.0)
	for j in range(1, n + 1):
		var ang := float(j) / float(n) * TAU
		var cur := c + Vector2(cos(ang) * rx, sin(ang) * ry)
		ci.draw_polygon(PackedVector2Array([c, prev, cur]), PackedColorArray([inner, outer, outer]))
		prev = cur


func _r(i: int) -> float:
	return _rv(i)


static func _rv(i: int) -> float:
	if _table.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		for k in 160:
			_table.append(rng.randf())
	return _table[absi(i) % _table.size()]


# -- drawing -----------------------------------------------------------------------------------------

func _draw() -> void:
	if size.x <= 0.0:
		return
	if not _road_checked and is_inside_tree():
		_find_road()
	var a := smoothstep(0.0, 1.0, _grow)
	var a1 := smoothstep(0.0, 1.0, clampf(_grow * 1.5 - 0.3, 0.0, 1.0))
	_draw_far(a1, 1.0 + 0.5 * _act[1])
	_draw_gate(a, 1.0 + 0.3 * _act[0])
	_draw_label(0, a)
	_draw_label(1, a1)


# -- home gate ---------------------------------------------------------------------------------------

func _draw_gate(a: float, g: float) -> void:
	if a > 0.01:
		draw_gate(self, _base(), _unit(), _time, a, g)


## The stone-ringed gate (base point `b`, unit `k` px, time `t`) on any canvas item.
static func draw_gate(ci: CanvasItem, b: Vector2, k: float, t: float, a: float, g: float) -> void:
	if a <= 0.01:
		return
	k *= lerpf(0.94, 1.0, a)
	var pulse := 0.85 + 0.1 * sin(t * 1.7) + 0.05 * sin(t * 3.1 + 1.0)
	var c := b - Vector2(0.0, k * RIM_OUT.y)
	# soft glow on the ground, pale with a warm core
	for j in 6:
		var f := 1.0 - float(j) * 0.15
		ci.draw_colored_polygon(_ell(b, k * 2.5 * f, k * 0.5 * f), Color(GLOW.lerp(WARM, float(j) / 7.0), 0.045 * pulse * g * a))
	# air glow around the gate
	for j in 6:
		var f := 1.0 + float(5 - j) * 0.09
		ci.draw_colored_polygon(_ell(c, k * RIM_OUT.x * f, k * RIM_OUT.y * f), Color(GLOW, 0.018 * pulse * g * a))
	# interior: dark at the rim, pale light toward the middle (smooth radial gradient)
	var cc := c + Vector2(0, k * 0.1)
	_fan(ci, cc, k * RIM_IN.x, k * RIM_IN.y, Color(0.78 * pulse + 0.1, 0.87 * pulse + 0.1, 1.0, 0.92 * a), Color(0.13, 0.17, 0.25, 0.97 * a), 1.0 * g)
	_fan(ci, cc, k * RIM_IN.x * 0.55, k * RIM_IN.y * 0.6, Color(1, 1, 1, 0.4 * pulse * g * a), Color(GLOW, 0.0), 1.0)
	# slow rising light motes inside the gate
	for j in 10:
		var ph := fposmod(t * (0.06 + _rv(j) * 0.08) + _rv(j + 20), 1.0)
		var y := lerpf(-RIM_IN.y * 0.85, RIM_IN.y * 0.9, ph)
		var hw := RIM_IN.x * sqrt(maxf(1.0 - pow(y / RIM_IN.y, 2.0), 0.0)) * 0.8
		var x := (_rv(j + 40) * 2.0 - 1.0) * hw + sin(t * 0.8 + float(j)) * k * 0.0
		ci.draw_circle(c + Vector2(x * k, -y * k), maxf(1.2, k * 0.022), Color(0.95, 0.98, 1.0, 0.7 * sin(ph * PI) * g * a))
	# stone ring: blocks between the two ellipses, lit on the inner edge
	for j in BLOCKS:
		var a0 := float(j) / float(BLOCKS) * TAU
		var a1 := float(j + 1) / float(BLOCKS) * TAU - 0.012
		var grow := 1.0 + (_rv(j + 60) - 0.5) * 0.08
		var q := PackedVector2Array()
		for s in 4:
			var ang := lerpf(a0, a1, float(s) / 3.0)
			q.append(c + Vector2(cos(ang) * RIM_IN.x, sin(ang) * RIM_IN.y) * k)
		for s in range(3, -1, -1):
			var ang := lerpf(a0, a1, float(s) / 3.0)
			q.append(c + Vector2(cos(ang) * RIM_OUT.x * grow, sin(ang) * RIM_OUT.y * grow) * k)
		var sh := 0.1 + _rv(j + 80) * 0.07
		ci.draw_colored_polygon(q, Color(sh * 0.85, sh * 0.85, sh * 0.95, a))
		ci.draw_polyline(q.slice(0, 4), Color(GLOW, 0.3 * pulse * g * a), maxf(1.0, k * 0.02), true)
		ci.draw_line(q[0], q[7], Color(0.01, 0.01, 0.015, 0.9 * a), maxf(1.0, k * 0.016))
		if _rv(j + 100) > 0.6:
			ci.draw_line(q[3], q[4], Color(1, 1, 1, 0.05 * a), maxf(1.0, k * 0.012))
	# standing stones at the foot and moss on top
	var foot_l := PackedVector2Array([b + Vector2(-k * 1.5, k * 0.06), b + Vector2(-k * 1.4, -k * 0.35), b + Vector2(-k * 0.85, -k * 0.3), b + Vector2(-k * 0.75, k * 0.08)])
	var foot_r := PackedVector2Array([b + Vector2(k * 0.8, k * 0.08), b + Vector2(k * 0.9, -k * 0.3), b + Vector2(k * 1.45, -k * 0.34), b + Vector2(k * 1.5, k * 0.05)])
	ci.draw_colored_polygon(foot_l, Color(0.07, 0.07, 0.085, a))
	ci.draw_colored_polygon(foot_r, Color(0.06, 0.06, 0.075, a))
	for j in 6:
		var ang := deg_to_rad(250.0 + float(j) * 7.0)
		var p0 := c + Vector2(cos(ang) * RIM_OUT.x, sin(ang) * RIM_OUT.y) * k
		var len := (0.2 + _rv(j + 110) * 0.35) * k
		var strand := PackedVector2Array()
		for s in 5:
			var u := float(s) / 4.0
			strand.append(p0 + Vector2(sin(t * 0.9 + float(j) + u * 2.0) * k * 0.03 * u, u * len))
		ci.draw_polyline(strand, Color(0.14, 0.18, 0.12, 0.9 * a), maxf(1.5, k * 0.03), true)
	# pale mist spilling from the foot
	for j in 5:
		var dx := sin(t * 0.3 + float(j) * 1.5) * 0.3 + (float(j) - 2.0) * 0.12
		ci.draw_colored_polygon(_ell(b + Vector2(dx * k, k * (0.1 + float(j) * 0.07)), k * (1.35 - float(j) * 0.12), k * 0.15), Color(GLOW, 0.05 * pulse * g * a))


# -- the road ahead: deeper ---------------------------------------------------------------------------

func _draw_far(a: float, g: float) -> void:
	if a <= 0.01:
		return
	var hy := size.y * RoadScene.HORIZON
	var e := _ground(0.9)
	var w := size.x
	var pulse := 0.85 + 0.15 * sin(_time * 1.1)
	# faint distant glow and fog on the horizon at the end of the road
	for j in 6:
		var f := 1.0 - float(j) * 0.15
		draw_colored_polygon(_ell(Vector2(e.x, hy), w * 0.34 * f, size.y * 0.05 * f), Color(0.55, 0.28, 0.32, 0.035 * pulse * g * a))
	draw_colored_polygon(_ell(Vector2(e.x, hy + 2.0), w * 0.2, size.y * 0.014), Color(0.75, 0.72, 0.78, 0.07 * pulse * g * a))
	# tiny silhouettes of the next realm: ragged spires and a dead tree
	for j in 9:
		var x := e.x + (float(j) - 4.0) * w * 0.028 + (_r(j + 130) - 0.5) * w * 0.012
		var h := size.y * (0.006 + pow(_r(j + 140), 2.0) * 0.03)
		var ww := w * (0.004 + _r(j + 150) * 0.004)
		draw_colored_polygon(PackedVector2Array([Vector2(x - ww, hy + 3.0), Vector2(x - ww * 0.3, hy - h), Vector2(x + ww * 0.2, hy - h * 0.8), Vector2(x + ww, hy + 3.0)]), Color(0.035, 0.02, 0.045, 0.85 * a))
	# embers drifting off down the road
	for j in 7:
		var ph := fposmod(_time * (0.08 + _r(j + 10) * 0.08) + _r(j + 30), 1.0)
		var p := _ground(lerpf(0.08, 0.7, ph), (_r(j + 50) - 0.5) * 1.2)
		p.y -= (1.0 - ph) * size.y * 0.05 + ph * size.y * 0.02
		draw_circle(p, maxf(1.0, w * 0.004 * (1.0 - ph * 0.6)), Color(EMBER.lightened(0.2), 0.7 * sin(ph * PI) * g * a))


# -- labels ------------------------------------------------------------------------------------------

func _draw_label(i: int, a: float) -> void:
	if a <= 0.01:
		return
	var home := i == 0
	var title := tr("PORTAL_HOME") if home else tr("PORTAL_DEEPER")
	var line := tr("PORTAL_HOME_LINE") % _souls if home else tr("PORTAL_DEEPER_LINE") % _depth
	var tcol := Color(0.86, 0.92, 1.0) if home else Color(0.95, 0.72, 0.62)
	var font := get_theme_default_font()
	var fs0 := int(roundf(clampf(size.x * 0.044, 13.0, 40.0)))
	var fs1 := int(roundf(fs0 * 0.66))
	var maxw := size.x * 0.4
	var anchor: Vector2
	if home:
		anchor = _base() - Vector2(0.0, _unit() * (RIM_OUT.y * 2.0 + 0.35))
	else:
		anchor = Vector2(size.x * 0.72, size.y * RoadScene.HORIZON - size.y * 0.035)
	var x := clampf(anchor.x, maxw * 0.5 + 6.0, size.x - maxw * 0.5 - 6.0)
	var sub_h := font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs1).y
	var y_sub := anchor.y - sub_h + font.get_ascent(fs1) + sin(_time * 1.3 + float(i)) * 2.0
	var lift := 1.0 + 0.3 * _act[i]
	tcol = Color(minf(tcol.r * lift, 1.0), minf(tcol.g * lift, 1.0), minf(tcol.b * lift, 1.0), a)
	var dark := Color(0.02, 0.02, 0.03, a * 0.95)
	var pos := Vector2(x - maxw * 0.5, y_sub)
	draw_multiline_string_outline(font, pos, line, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs1, -1, maxi(3, fs1 / 4), dark)
	draw_multiline_string(font, pos, line, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs1, -1, Color(0.84, 0.84, 0.86, a))
	var tpos := Vector2(x - maxw * 0.5, y_sub - fs1 * 1.35)
	draw_string_outline(font, tpos, title, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs0, maxi(3, fs0 / 5), dark)
	draw_string(font, tpos, title, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs0, tcol)

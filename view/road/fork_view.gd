## Fork in the road drawn over a RoadScene: the road splits into 2-3 narrower trails that curve apart toward the
## horizon; each ends in a landmark silhouette (ForkLandmarks) with a small floating label. Tap a trail or its
## landmark to pick it; the hovered / pressed trail brightens and the others dim.
class_name ForkView
extends Control

signal trail_picked(index: int)

const Z_SPLIT := 0.0 ## road depth where the road splits
const SEGS := 22
const LAND_K := 1.0 ## landmark unit height as a fraction of the screen height at scale 1

var _doors: Array[Door] = []
var _look: SceneryCatalog.Look = SceneryCatalog.look(0)
var _grow := 1.0
var _sel := -1
var _hover := -1
var _pressed := -1
var _time := 0.0
var _tween: Tween
var _act: Array[float] = [0.0, 0.0, 0.0] ## 1 = highlighted
var _dim: Array[float] = [0.0, 0.0, 0.0] ## 1 = dimmed
var _hits: Array[Dictionary] = [] ## per trail: {"polys", "ys", "xs", "hws"}
var _road: RoadScene
var _road_checked := false
var _noise := FastNoiseLite.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func() -> void: _hover = -1)
	_noise.seed = 11
	_noise.frequency = 1.0


func setup(offer: DoorOffer) -> ForkView:
	_doors = offer.doors.duplicate()
	_look = SceneryCatalog.look(offer.realm_index)
	_sel = -1
	_hover = -1
	_pressed = -1
	_grow = 1.0
	queue_redraw()
	return self


## Trails and landmarks grow in, staggered per trail.
func reveal(duration := 0.9) -> void:
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
	if _doors.is_empty() or not is_visible_in_tree():
		return
	_time += delta
	var focus := _pressed if _pressed >= 0 else (_sel if _sel >= 0 else _hover)
	for i in 3:
		_act[i] = move_toward(_act[i], 1.0 if i == focus else 0.0, delta * 6.0)
		_dim[i] = move_toward(_dim[i], 1.0 if focus >= 0 and i != focus else 0.0, delta * 4.0)
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
			if i >= 0 and i == was:
				_sel = i
				accept_event()
				trail_picked.emit(i)


## Trail under the point (polygon around the trail or the landmark + label box); nearest centre wins.
func _hit(p: Vector2) -> int:
	var best := -1
	var best_m := INF
	for i in _hits.size():
		var hit: Dictionary = _hits[i]
		var m := INF
		for poly: PackedVector2Array in hit["polys"]:
			if Geometry2D.is_point_in_polygon(p, poly):
				m = 0.5
				break
		if m == INF:
			continue
		var ys: PackedFloat32Array = hit["ys"]
		var k := 0
		for j in ys.size():
			if absf(ys[j] - p.y) < absf(ys[k] - p.y):
				k = j
		m = absf(p.x - (hit["xs"] as PackedFloat32Array)[k]) / maxf((hit["hws"] as PackedFloat32Array)[k], 1.0)
		if m < best_m:
			best_m = m
			best = i
	return best


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


func _lane_end(i: int, n: int) -> float:
	if n == 2:
		return -2.5 if i == 0 else 2.5
	return [-3.4, 0.0, 3.4][i]


func _z_end(i: int, n: int) -> float:
	return 0.3 if n == 3 and i == 1 else (0.24 if n == 2 else 0.22)


func _lane0(i: int, n: int) -> float:
	return (float(i) - float(n - 1) * 0.5) * (1.1 if n == 2 else 1.05)


## Half width in road half-widths: each trail starts at ~60% of the road width and tapers slowly.
func _hw(i: int, n: int, k: float) -> float:
	if n == 3 and i == 1:
		return lerpf(0.56, 0.62, k)
	return lerpf(0.6 if n == 2 else 0.56, 0.95 if n == 2 else 0.8, k) # grows in lane units to offset perspective


## Point on trail i at u in 0..1: (x, y, half width in px).
func _geom(i: int, n: int, u: float) -> Vector3:
	var w := size.x
	var h := size.y
	var hy := h * RoadScene.HORIZON
	var z := lerpf(Z_SPLIT, _z_end(i, n), u)
	var s := 1.0 / (1.0 + RoadScene.DEPTH_K * z)
	var k := smoothstep(0.2, 1.0, u)
	var lane := lerpf(_lane0(i, n), _lane_end(i, n), k)
	var rh := w * RoadScene.ROAD_HALF
	# road locally straightened: branches start at the road centre at the split and only bend outward
	var sh := _road._shift(Z_SPLIT) if is_instance_valid(_road) else 0.0
	return Vector3(w * 0.5 + sh + lane * rh * s, hy + (h - hy) * s, _hw(i, n, k) * rh * s)


func _unit(i: int, n: int, kind: StringName) -> float:
	var s := 1.0 / (1.0 + RoadScene.DEPTH_K * _z_end(i, n))
	return size.y * LAND_K * s * ForkLandmarks.scale_of(kind)


func _trail_t(i: int) -> float:
	return clampf(_grow * 1.6 - float(i) * 0.3, 0.0, 1.0)


func _build_hits(n: int) -> void:
	_hits.clear()
	for i in n:
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var ys := PackedFloat32Array()
		var xs := PackedFloat32Array()
		var hws := PackedFloat32Array()
		for s in 13:
			var g := _geom(i, n, float(s) / 12.0)
			var pad := g.z * (1.0 + 0.5 * float(s) / 12.0) + 10.0
			left.append(Vector2(g.x - pad, g.y))
			right.append(Vector2(g.x + pad, g.y))
			ys.append(g.y)
			xs.append(g.x)
			hws.append(g.z)
		var poly := PackedVector2Array(left)
		for s in range(right.size() - 1, -1, -1):
			poly.append(right[s])
		var kind := _doors[i].kind_id
		var e := _geom(i, n, 1.0)
		var u := _unit(i, n, kind)
		var hgt := ForkLandmarks.height_of(kind) * u
		var half := maxf(u * 0.55, size.x * 0.08)
		var box := PackedVector2Array([Vector2(e.x - half, e.y - hgt - 110.0), Vector2(e.x + half, e.y - hgt - 110.0),
			Vector2(e.x + half, e.y + 24.0), Vector2(e.x - half, e.y + 24.0)])
		_hits.append({"polys": [poly, box], "ys": ys, "xs": xs, "hws": hws})


# -- drawing -----------------------------------------------------------------------------------------

func _draw() -> void:
	var n := mini(_doors.size(), 3)
	if n == 0 or size.x <= 0.0:
		return
	if not _road_checked and is_inside_tree():
		_find_road()
	_build_hits(n)
	_draw_cover()
	for i in n:
		_draw_trail(i, n)
	var order: Array[int] = []
	for i in n:
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return _z_end(a, n) > _z_end(b, n))
	for i in order:
		_draw_landmark(i, n)
	for i in n:
		_draw_label(i, n)


func _tint(c: Color, i: int) -> Color:
	var f := 1.0 + 0.4 * _act[i] - 0.4 * _dim[i]
	return Color(minf(c.r * f, 1.0), minf(c.g * f, 1.0), minf(c.b * f, 1.0), c.a)


## Ground-coloured patch over the part of the old road beyond the split, so only the trails remain.
func _draw_cover() -> void:
	var w := size.x
	var h := size.y
	var hy := h * RoadScene.HORIZON
	var rh := w * RoadScene.ROAD_HALF
	var rows := 14
	var top := _look.fog.lerp(_look.ground, 0.5)
	var prev: Array = []
	for k in rows + 1:
		var z := lerpf(Z_SPLIT, 1.0, pow(float(k) / float(rows), 1.5))
		var s := 1.0 / (1.0 + RoadScene.DEPTH_K * z)
		var y := hy + (h - hy) * s
		var cx := w * 0.5 + (_road._shift(z) if is_instance_valid(_road) else 0.0)
		var c := top.lerp(_look.ground, (y - hy) / (h - hy)).darkened(0.1)
		c.a = _grow * 0.96 * smoothstep(0.0, 0.25, float(k) / float(rows))
		var c0 := Color(c, 0.0)
		var row := [[Vector2(cx - rh * s * 1.5, y), c0], [Vector2(cx - rh * s * 1.12, y), c],
			[Vector2(cx + rh * s * 1.12, y), c], [Vector2(cx + rh * s * 1.5, y), c0]]
		if not prev.is_empty():
			for j in 3:
				draw_polygon(PackedVector2Array([prev[j][0], prev[j + 1][0], row[j + 1][0], row[j][0]]),
					PackedColorArray([prev[j][1], prev[j + 1][1], row[j + 1][1], row[j][1]]))
		prev = row


func _draw_trail(i: int, n: int) -> void:
	var tmax := _trail_t(i)
	if tmax <= 0.01:
		return
	var rd := is_instance_valid(_road)
	var lk: SceneryCatalog.Look = _road._look if rd else _look
	var nz: FastNoiseLite = _road._noise if rd else _noise
	var travel: float = _road._travel if rd else 0.0
	var col := PathView.kind_color(_doors[i].kind_id)
	var cols := [-1.0, -0.93, -0.78, 0.0, 0.78, 0.93, 1.0]
	var rh := size.x * RoadScene.ROAD_HALF
	var prev: Array = []
	for k in SEGS + 1:
		var u := tmax * float(k) / float(SEGS)
		var kk := smoothstep(0.2, 1.0, u)
		var z := lerpf(Z_SPLIT, _z_end(i, n), u)
		var s := 1.0 / (1.0 + RoadScene.DEPTH_K * z)
		var g := _geom(i, n, u)
		var lane := (g.x - size.x * 0.5 - (_road._shift(Z_SPLIT) if rd else 0.0)) / (rh * s)
		var hw := g.z / (rh * s)
		var wz := z + travel
		var fog_t := pow(clampf(z, 0.0, 1.0), 0.7) * 0.85
		var mid := lk.road.lerp(lk.road_far, fog_t).lerp(col, 0.05)
		var edge := lk.edge.lerp(lk.fog, fog_t)
		var a := smoothstep(0.0, 0.1, u)
		var ramp := smoothstep(0.0, 0.4, u)
		var row: Array = []
		for j in cols.size():
			var cj: float = cols[j]
			var inner := (cj < 0.0 and i > 0) or (cj > 0.0 and i < n - 1)
			var ew := ramp if inner else 1.0
			var xabs := lane + cj * hw
			var side := -1.0 if xabs < 0.0 else 1.0
			var mult := 1.0
			if rd and not inner:
				mult = lerpf(_road._edge(wz, side), 1.0, smoothstep(0.0, 0.6, u))
			elif inner:
				mult = 1.0 + _noise.get_noise_1d(u * 9.0 + float(i) * 10.0 + cj * 50.0) * 0.1 * ramp
			var ax := absf(cj)
			var c: Color
			if ax >= 0.99:
				c = Color(mid.darkened(0.3 * ew), a * (1.0 - ew * 0.9))
			elif ax > 0.9:
				c = Color(mid.darkened(0.3 * ew), a)
			else:
				var m := nz.get_noise_2d(xabs * 2.5 + 50.0, wz * 11.0) * 0.5 + nz.get_noise_2d(xabs * 7.0, wz * 30.0) * 0.2
				var cc := mid.lightened(m * 0.35) if m > 0.0 else mid.darkened(-m * 0.35)
				c = Color(cc.darkened(0.12 * ew) if ax > 0.6 else cc, a)
			row.append([Vector2(g.x + (cj * hw) * rh * s * mult, g.y), _tint(c, i)])
		if not prev.is_empty():
			for j in cols.size() - 1:
				if prev[j + 1][0].x <= prev[j][0].x + 0.1 or row[j + 1][0].x <= row[j][0].x + 0.1:
					continue
				draw_polygon(PackedVector2Array([prev[j][0], prev[j + 1][0], row[j + 1][0], row[j][0]]),
					PackedColorArray([prev[j][1], prev[j + 1][1], row[j + 1][1], row[j][1]]))
		prev = row
		if k == SEGS and tmax > 0.99:
			_draw_cap(i, Vector2(g.x, g.y), g.z, mid, a)
	if tmax > 0.2:
		_draw_crotch(i, n, tmax)


## Wide rounded end of the trail under the landmark, same dirt colour with a thin dark rim.
func _draw_cap(i: int, c: Vector2, rx: float, mid: Color, a: float) -> void:
	for layer in 2:
		var r := rx * (1.0 if layer == 0 else 0.9)
		var pts := PackedVector2Array()
		for q in 20:
			var ang := TAU * float(q) / 20.0
			pts.append(c + Vector2(cos(ang) * r, sin(ang) * r * 0.3))
		draw_colored_polygon(pts, _tint(Color(mid.darkened(0.3) if layer == 0 else mid, a), i))


## Soft shadow and mist where two neighbouring trails part (rounded crotch, no outline).
func _draw_crotch(i: int, n: int, tmax: float) -> void:
	if i >= n - 1:
		return
	var a := _geom(i, n, 0.2)
	var b := _geom(i + 1, n, 0.2)
	var c := Vector2((a.x + b.x) * 0.5, a.y)
	var r := (b.x - a.x) * 0.5
	var al := smoothstep(0.2, 0.6, tmax) * _grow
	for k in 5:
		var f := 1.0 - float(k) * 0.18
		var pts := PackedVector2Array()
		for q in 14:
			var ang := TAU * float(q) / 14.0
			pts.append(c + Vector2(cos(ang) * r * 1.3 * f, sin(ang) * r * 0.5 * f))
		draw_colored_polygon(pts, Color(_look.ground.darkened(0.2), 0.1 * al))
		draw_colored_polygon(pts, Color(_look.fog, 0.035 * al))


func _state(i: int, n: int) -> Dictionary:
	var door := _doors[i]
	var kcol := PathView.kind_color(door.kind_id)
	var tr := _trail_t(i)
	var fogm := 0.15 + _z_end(i, n) * 0.5
	var body := _look.silhouette.lerp(_look.fog, fogm).lerp(kcol, 0.06)
	body = body.lightened(0.12 * _act[i]).darkened(0.3 * _dim[i])
	return {
		"body": body, "glow": kcol, "eye": _look.accent.lightened(0.35),
		"bone": _look.fog.lerp(Color(0.85, 0.82, 0.75), 0.6),
		"t": _time + float(i) * 1.7,
		"a": smoothstep(0.55, 1.0, tr) * lerpf(1.0, 0.5, _dim[i]),
		"g": 0.85 + 0.7 * _act[i] - 0.35 * _dim[i],
	}


func _draw_landmark(i: int, n: int) -> void:
	var st := _state(i, n)
	if float(st["a"]) <= 0.01:
		return
	var kind := _doors[i].kind_id
	var e := _geom(i, n, 1.0)
	var grow := _back(clampf((_trail_t(i) - 0.5) * 2.0, 0.0, 1.0))
	ForkLandmarks.draw(self, kind, Vector2(e.x, e.y), _unit(i, n, kind) * grow, st)


func _draw_label(i: int, n: int) -> void:
	var door := _doors[i]
	var a := smoothstep(0.7, 1.0, _trail_t(i)) * lerpf(1.0, 0.5, _dim[i])
	if a <= 0.01:
		return
	var kcol := PathView.kind_color(door.kind_id)
	var e := _geom(i, n, 1.0)
	var texts := fork_text(door)
	var font := get_theme_default_font()
	var unit := _unit(i, n, door.kind_id)
	var fs0 := int(roundf(clampf(size.x * 0.03, 12.0, 40.0)))
	var maxw := size.x * (0.3 if n == 3 else 0.42)
	var lines: Array = [
		[texts[0], fs0, kcol.lightened(0.55)],
		[texts[1], int(fs0 * 0.76), Color(0.82, 0.82, 0.85)],
		[texts[2], int(fs0 * 0.66), kcol.lightened(0.4)],
	]
	var y := e.y - ForkLandmarks.height_of(door.kind_id) * unit - fs0 * 0.5 + sin(_time * 1.3 + float(i)) * 3.0
	var x := clampf(e.x, maxw * 0.5 + 4.0, size.x - maxw * 0.5 - 4.0)
	for k in range(2, -1, -1):
		var line: Array = lines[k]
		var text: String = line[0]
		if text == "":
			continue
		var fs: int = line[1]
		while fs > 10 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw:
			fs -= 1
		var c: Color = line[2]
		c.a = a
		var pos := Vector2(x - maxw * 0.5, y)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs, maxi(3, fs / 5), Color(0.02, 0.02, 0.03, a * 0.95))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs, _tint(c, i))
		y -= fs * 1.25


static func _back(t: float) -> float:
	var c := 1.70158
	var u := t - 1.0
	return clampf(1.0 + (c + 1.0) * u * u * u + c * u * u, 0.0, 1.2) if t > 0.0 else 0.0


## [title, hint (affix or enemy name), reward] - short, any may be "".
static func fork_text(door: Door) -> Array[String]:
	var hint := ""
	if not door.affix_ids.is_empty():
		hint = RunScreen.affix_name(door.affix_ids[0])
	elif door.preview.has("name_key"):
		hint = TranslationServer.translate(door.preview["name_key"])
	if door.preview.has("hint"):
		hint = String(door.preview["hint"])
	var rewards: Array[String] = []
	for reward: Dictionary in door.preview.get("rewards", []):
		var text := DoorsScreen.reward_text(reward)
		if text != "":
			rewards.append(text)
	var out: Array[String] = [RunScreen.kind_name(door.kind_id), hint, ", ".join(rewards.slice(0, 2))]
	return out

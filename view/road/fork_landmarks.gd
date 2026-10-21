## Landmark silhouettes standing at the end of a fork trail. Unit coords: base at (0,0), height 1 = -y.
## `st`: body, glow (kind colour), eye, bone: Color; t: time; a: alpha; g: glow strength.
class_name ForkLandmarks
extends RefCounted

const HEIGHTS := {&"fight": 1.0, &"elite": 1.22, &"altar": 0.8, &"bonfire": 1.0, &"shop": 0.9, &"boss": 1.5, &"home": 1.2, &"deeper": 1.0}
const SCALES := {&"fight": 0.9, &"elite": 0.95, &"altar": 1.1, &"bonfire": 1.05, &"shop": 1.0, &"boss": 0.78, &"home": 1.0, &"deeper": 1.0}
const RED := Color(1.0, 0.18, 0.12)
const FIRE := Color(1.0, 0.55, 0.18)


static func height_of(kind: StringName) -> float:
	return HEIGHTS.get(kind, 1.0)


static func scale_of(kind: StringName) -> float:
	return SCALES.get(kind, 1.0)


static func draw(ci: CanvasItem, kind: StringName, base: Vector2, unit: float, st: Dictionary) -> void:
	var a: float = st["a"]
	var g: float = st["g"]
	var glow: Color = st["glow"]
	ci.draw_set_transform(base, 0.0, Vector2(unit, unit))
	if kind == &"home":
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_home(ci, st, base, unit)
		return
	var hgt := height_of(kind)
	# light pool on the ground + soft aura behind the figure
	ci.draw_colored_polygon(_ellipse(Vector2(0, 0.01), 0.75, 0.1), Color(glow, 0.1 * g * a))
	ci.draw_colored_polygon(_ellipse(Vector2(0, 0.01), 0.45, 0.06), Color(glow, 0.12 * g * a))
	_halo(ci, Vector2(0, -hgt * 0.5), hgt * 0.5, glow, 0.16 * g * a)
	match kind:
		&"fight": _fight(ci, st)
		&"elite": _elite(ci, st)
		&"altar": _altar(ci, st)
		&"bonfire": _bonfire(ci, st)
		&"shop": _shop(ci, st)
		&"boss": _boss(ci, st)
		_: _fight(ci, st)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# -- kinds -------------------------------------------------------------------------------------------

static func _fight(ci: CanvasItem, st: Dictionary) -> void:
	var b: Color = _col(st, "body")
	var pulse := 0.55 + 0.45 * sin(float(st["t"]) * 2.3)
	ci.draw_colored_polygon(_sym([0.05, -0.92, 0.09, -0.74, 0.1, -0.62, 0.15, -0.5, 0.17, -0.2, 0.2, 0.0,
		0.1, 0.02, 0.0, -0.03]), b)
	ci.draw_colored_polygon(_pts([0.13, -0.5, 0.2, -0.42, 0.21, -0.34, 0.17, -0.36, 0.12, -0.42]), b)
	ci.draw_colored_polygon(_pts([0.2, -0.34, 0.225, -0.34, 0.29, -0.02, 0.265, -0.01]), b.lightened(0.3))
	_eyes(ci, st, Vector2(0.035, -0.78), 0.011, pulse)


static func _elite(ci: CanvasItem, st: Dictionary) -> void:
	var b: Color = _col(st, "body")
	var g: float = st["g"]
	var a: float = st["a"]
	var t: float = st["t"]
	var pulse := 0.6 + 0.4 * sin(t * 2.0)
	_halo(ci, Vector2(0, -0.55), 0.75, RED, 0.3 * g * a)
	ci.draw_polyline(_ellipse(Vector2(0, 0.0), 0.5, 0.08), Color(RED, 0.5 * a * g), 0.014)
	# body
	ci.draw_colored_polygon(_sym([0.07, -0.86, 0.08, -0.76, 0.12, -0.72, 0.3, -0.68, 0.32, -0.55, 0.26, -0.3,
		0.3, -0.1, 0.32, 0.0]), b)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		ci.draw_colored_polygon(_flip([0.3, -0.68, 0.36, -0.9, 0.42, -0.64], s), b)
		ci.draw_colored_polygon(_flip([0.07, -0.84, 0.15, -0.9, 0.22, -1.02, 0.26, -1.22, 0.17, -1.08, 0.1, -0.99], s), b)
	# skull on a pole
	var sk: Color = st["bone"]
	ci.draw_colored_polygon(_pts([0.485, 0.0, 0.505, 0.0, 0.505, -0.92, 0.485, -0.92]), b)
	_halo(ci, Vector2(0.495, -0.98), 0.17, RED, 0.35 * g * a)
	ci.draw_circle(Vector2(0.495, -0.99), 0.07, Color(sk, 0.8 * a))
	ci.draw_colored_polygon(_pts([0.46, -0.96, 0.53, -0.96, 0.52, -0.9, 0.47, -0.9]), Color(sk, 0.8 * a))
	ci.draw_circle(Vector2(0.47, -0.995), 0.016, Color(0.04, 0.0, 0.0, a))
	ci.draw_circle(Vector2(0.52, -0.995), 0.016, Color(0.04, 0.0, 0.0, a))
	for sx in [-1.0, 1.0]:
		var s: float = sx
		var e := Vector2(0.05 * s, -0.8)
		_halo(ci, e, 0.07, RED, 0.5 * pulse * a)
		ci.draw_circle(e, 0.014, Color(1.0, 0.35, 0.25, a * pulse))


static func _altar(ci: CanvasItem, st: Dictionary) -> void:
	var b: Color = _col(st, "body")
	var g: float = st["g"]
	var a: float = st["a"]
	var t: float = st["t"]
	var glow: Color = st["glow"]
	ci.draw_colored_polygon(_pts([-0.34, 0.0, 0.34, 0.0, 0.31, -0.09, -0.31, -0.09]), b)
	ci.draw_colored_polygon(_pts([-0.26, -0.09, 0.26, -0.09, 0.24, -0.19, -0.24, -0.19]), b)
	ci.draw_colored_polygon(_pts([-0.17, -0.19, 0.17, -0.19, 0.15, -0.42, -0.15, -0.42]), b)
	ci.draw_colored_polygon(_pts([-0.24, -0.42, 0.24, -0.42, 0.24, -0.48, -0.24, -0.48]), b.lightened(0.08))
	for sx in [-1.0, 1.0]:
		var s: float = sx
		ci.draw_colored_polygon(_flip([0.36, 0.0, 0.42, -0.5, 0.47, 0.0], s), b)
		ci.draw_circle(Vector2(0.415 * s, -0.3), 0.012, Color(glow, 0.7 * g * a))
	var f := 0.9 + 0.1 * sin(t * 9.0)
	_halo(ci, Vector2(0, -0.62), 0.5, glow, 0.38 * g * a)
	_flame(ci, Vector2(0, -0.62), 0.17 * f, t, 1.0, Color(glow.lerp(FIRE, 0.4), 0.9 * a))
	_flame(ci, Vector2(0, -0.58), 0.09 * f, t, 2.0, Color(1.0, 0.95, 0.7, 0.9 * a))


static func _bonfire(ci: CanvasItem, st: Dictionary) -> void:
	var b: Color = _col(st, "body")
	var g: float = st["g"]
	var a: float = st["a"]
	var t: float = st["t"]
	# light cone and halo
	var cone_a := 0.16 * g * a
	ci.draw_polygon(_pts([-0.04, -0.3, 0.04, -0.3, 0.55, -1.15, -0.55, -1.15]),
		PackedColorArray([Color(FIRE, cone_a), Color(FIRE, cone_a), Color(FIRE, 0.0), Color(FIRE, 0.0)]))
	ci.draw_colored_polygon(_ellipse(Vector2(0, 0.01), 0.95, 0.15), Color(FIRE, 0.1 * g * a))
	_halo(ci, Vector2(0, -0.3), 0.6, FIRE, 0.38 * g * a)
	# ash mound + coiled sword
	ci.draw_colored_polygon(_pts([-0.32, 0.0, -0.2, -0.08, 0.0, -0.12, 0.2, -0.08, 0.32, 0.0]), b)
	ci.draw_colored_polygon(_pts([-0.028, -0.1, -0.028, -0.86, 0.0, -1.0, 0.028, -0.86, 0.028, -0.1]), b.lightened(0.12))
	ci.draw_colored_polygon(_pts([-0.11, -0.8, 0.11, -0.8, 0.11, -0.77, -0.11, -0.77]), b.lightened(0.12))
	var coil := PackedVector2Array()
	for k in 20:
		var u := float(k) / 19.0
		coil.append(Vector2(sin(u * TAU * 3.0) * 0.065, -0.13 - u * 0.5))
	ci.draw_polyline(coil, Color(b.lightened(0.22), a), 0.014)
	var f := 0.92 + 0.08 * sin(t * 11.0)
	_flame(ci, Vector2(-0.07, -0.2), 0.14 * f, t, 0.5, Color(1.0, 0.4, 0.1, 0.85 * a))
	_flame(ci, Vector2(0.07, -0.2), 0.12 * f, t, 3.1, Color(1.0, 0.45, 0.1, 0.85 * a))
	_flame(ci, Vector2(0, -0.24), 0.22 * f, t, 1.7, Color(1.0, 0.55, 0.15, 0.9 * a))
	_flame(ci, Vector2(0, -0.2), 0.11 * f, t, 4.2, Color(1.0, 0.92, 0.6, 0.95 * a))


static func _shop(ci: CanvasItem, st: Dictionary) -> void:
	var b: Color = _col(st, "body")
	var g: float = st["g"]
	var a: float = st["a"]
	var t: float = st["t"]
	var lamp := FIRE.lerp(st["glow"], 0.35)
	# merchant (hooded, hunched) with a lantern on a hooked staff
	ci.draw_colored_polygon(_pts([-0.1, -0.7, -0.03, -0.72, 0.04, -0.62, 0.05, -0.45, 0.08, -0.2, 0.1, 0.0,
		-0.28, 0.0, -0.24, -0.25, -0.2, -0.5, -0.16, -0.62]), b)
	ci.draw_colored_polygon(_pts([-0.34, 0.0, -0.32, 0.0, -0.32, -0.8, -0.2, -0.8, -0.2, -0.84, -0.34, -0.84]), b)
	var fl := 0.85 + 0.15 * sin(t * 6.0 + 1.0)
	_halo(ci, Vector2(-0.21, -0.72), 0.3, lamp, 0.45 * g * fl * a)
	ci.draw_colored_polygon(_pts([-0.24, -0.82, -0.18, -0.82, -0.17, -0.64, -0.25, -0.64]), b)
	ci.draw_colored_polygon(_pts([-0.23, -0.79, -0.19, -0.79, -0.19, -0.67, -0.23, -0.67]), Color(lamp.lightened(0.25), 0.95 * a))
	ci.draw_circle(Vector2(-0.065, -0.62), 0.008, Color(st["eye"], 0.7 * a))
	# cart with canopy
	ci.draw_colored_polygon(_pts([0.14, -0.2, 0.5, -0.2, 0.46, -0.38, 0.17, -0.38]), b)
	ci.draw_colored_polygon(_pts([0.16, -0.38, 0.17, -0.62, 0.19, -0.62, 0.19, -0.38]), b)
	ci.draw_colored_polygon(_pts([0.44, -0.38, 0.44, -0.62, 0.46, -0.62, 0.46, -0.38]), b)
	ci.draw_colored_polygon(_pts([0.1, -0.6, 0.31, -0.78, 0.52, -0.6, 0.31, -0.64]), b)
	ci.draw_colored_polygon(_pts([0.14, -0.3, 0.02, -0.18, 0.03, -0.16, 0.14, -0.26]), b)
	ci.draw_arc(Vector2(0.3, -0.12), 0.12, 0.0, TAU, 18, Color(b.lightened(0.1), a), 0.022)
	ci.draw_circle(Vector2(0.3, -0.12), 0.025, Color(b.lightened(0.1), a))
	for k in 4:
		var ang := float(k) * PI * 0.5 + 0.3
		ci.draw_line(Vector2(0.3, -0.12), Vector2(0.3, -0.12) + Vector2(cos(ang), sin(ang)) * 0.11, Color(b.lightened(0.1), a), 0.012)
	_halo(ci, Vector2(0.33, -0.3), 0.16, lamp, 0.22 * g * a)


static func _boss(ci: CanvasItem, st: Dictionary) -> void:
	var b: Color = _col(st, "body")
	var g: float = st["g"]
	var a: float = st["a"]
	var t: float = st["t"]
	var pulse := 0.6 + 0.4 * sin(t * 1.7)
	var cy := -0.8
	# void inside the arch with a red glow rising from the floor
	var inner := PackedVector2Array([Vector2(-0.3, 0.0), Vector2(-0.3, cy)])
	var cols := PackedColorArray([Color(0.7, 0.05, 0.08, 0.55 * g * a), Color(0.05, 0.0, 0.02, 0.92 * a)])
	for k in 13:
		var ang := PI - PI * float(k) / 12.0
		inner.append(Vector2(cos(ang) * 0.3, cy - sin(ang) * 0.3))
		cols.append(Color(0.05, 0.0, 0.02, 0.92 * a))
	inner.append(Vector2(0.3, 0.0))
	cols.append(Color(0.7, 0.05, 0.08, 0.55 * g * a))
	ci.draw_polygon(inner, cols)
	_halo(ci, Vector2(0, -0.45), 0.55, RED, 0.22 * g * pulse * a)
	# frame
	var ring := PackedVector2Array([Vector2(-0.52, 0.0), Vector2(-0.52, cy)])
	for k in 13:
		var ang := PI - PI * float(k) / 12.0
		ring.append(Vector2(cos(ang) * 0.52, cy - sin(ang) * 0.52))
	ring.append(Vector2(0.52, 0.0))
	ring.append(Vector2(0.3, 0.0))
	for k in 13:
		var ang := PI * float(k) / 12.0
		ring.append(Vector2(cos(ang) * 0.3, cy - sin(ang) * 0.3))
	ring.append(Vector2(-0.3, 0.0))
	ci.draw_colored_polygon(ring, b)
	ci.draw_colored_polygon(_pts([-0.64, 0.0, 0.64, 0.0, 0.6, -0.07, -0.6, -0.07]), b)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		ci.draw_colored_polygon(_flip([0.4, -0.8, 0.46, -1.12, 0.53, -0.8], s), b)
		ci.draw_colored_polygon(_flip([0.08, -1.3, 0.15, -1.46, 0.22, -1.24], s), b)
	ci.draw_colored_polygon(_pts([-0.07, -1.3, 0.0, -1.5, 0.07, -1.3]), b)
	# eyes in the void
	for sx in [-1.0, 1.0]:
		var s: float = sx
		var c := Vector2(0.13 * s, -0.7)
		_halo(ci, c, 0.12, RED, 0.5 * pulse * a)
		ci.draw_colored_polygon(_flip([0.05, -0.72, 0.19, -0.77, 0.17, -0.68, 0.06, -0.68], s), Color(1.0, 0.25, 0.18, a * (0.6 + 0.4 * pulse)))


## The HOME gate of the crossroads (PortalView's stone ring), drawn in pixels: the caller resets the transform.
static func _home(ci: CanvasItem, st: Dictionary, base: Vector2, unit: float) -> void:
	var a: float = st["a"]
	var g: float = st["g"]
	var glow: Color = st["glow"]
	var k := unit * 0.3
	ci.draw_colored_polygon(_ell_px(base, unit * 0.9, unit * 0.12), Color(glow, 0.1 * g * a))
	PortalView.draw_gate(ci, base, k, float(st["t"]), a, g)


## DEEPER: the road goes on into the fog, a distant violet glow of the next realm, tiny spires on the horizon.
static func _deeper(ci: CanvasItem, st: Dictionary) -> void:
	var b: Color = _col(st, "body")
	var g: float = st["g"]
	var a: float = st["a"]
	var t: float = st["t"]
	var glow: Color = st["glow"]
	var pulse := 0.85 + 0.15 * sin(t * 1.1)
	# the road narrowing into the fog, fading out with distance
	var road_c := b.lerp(Color(0.55, 0.52, 0.6), 0.5)
	ci.draw_polygon(_pts([-0.5, 0.0, 0.5, 0.0, 0.07, -0.85, -0.07, -0.85]),
		PackedColorArray([Color(road_c, 0.55 * a), Color(road_c, 0.55 * a), Color(road_c, 0.0), Color(road_c, 0.0)]))
	# glow of the next realm at the end of it
	for j in 6:
		var f := 1.0 - float(j) * 0.15
		ci.draw_colored_polygon(_ellipse(Vector2(0, -0.85), 0.8 * f, 0.22 * f), Color(glow, 0.06 * pulse * g * a))
	ci.draw_colored_polygon(_ellipse(Vector2(0, -0.84), 0.5, 0.04), Color(0.85, 0.8, 0.95, 0.1 * pulse * a))
	# tiny silhouettes: ragged spires and a dead tree
	var spires := [[-0.42, 0.14], [-0.3, 0.07], [-0.2, 0.2], [-0.1, 0.09], [0.0, 0.26], [0.11, 0.1], [0.21, 0.17], [0.31, 0.08], [0.43, 0.15]]
	for sp in spires:
		var x: float = sp[0]
		var h: float = sp[1]
		ci.draw_colored_polygon(_pts([x - 0.025, -0.83, x - 0.007, -0.83 - h, x + 0.006, -0.83 - h * 0.8, x + 0.025, -0.83]), Color(0.035, 0.02, 0.045, 0.85 * a))
	ci.draw_polyline(_pts([0.6, -0.1, 0.6, -0.5, 0.52, -0.62, 0.6, -0.5, 0.68, -0.66]), Color(0.035, 0.02, 0.045, 0.8 * a), 0.02)
	# embers drifting off down the road
	for j in 6:
		var ph := fposmod(t * (0.08 + float(j) * 0.015) + float(j) * 0.17, 1.0)
		var p := Vector2((float(j % 3) - 1.0) * 0.14 * (1.0 - ph), -ph * 0.85)
		ci.draw_circle(p, 0.012, Color(0.95, 0.5, 0.35, 0.7 * sin(ph * PI) * g * a))


# -- helpers -----------------------------------------------------------------------------------------

static func _col(st: Dictionary, key: String) -> Color:
	var c: Color = st[key]
	return Color(c, c.a * float(st["a"]))


static func _eyes(ci: CanvasItem, st: Dictionary, at: Vector2, r: float, pulse: float) -> void:
	var a: float = st["a"]
	var e: Color = st["eye"]
	for sx in [-1.0, 1.0]:
		var s: float = sx
		var c := Vector2(at.x * s, at.y)
		_halo(ci, c, r * 4.0, e, 0.45 * pulse * a)
		ci.draw_circle(c, r, Color(e.lightened(0.3), a * pulse))


static func _pts(f: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, f.size(), 2):
		out.append(Vector2(f[i], f[i + 1]))
	return out


## Right half (top to bottom) mirrored into a closed outline.
static func _sym(f: Array) -> PackedVector2Array:
	var half := _pts(f)
	var out := PackedVector2Array(half)
	for i in range(half.size() - 1, -1, -1):
		if half[i].x != 0.0:
			out.append(Vector2(-half[i].x, half[i].y))
	return out


static func _flip(f: Array, sx: float) -> PackedVector2Array:
	var src := _pts(f)
	if sx > 0.0:
		return src
	var out := PackedVector2Array()
	for i in range(src.size() - 1, -1, -1):
		out.append(Vector2(-src[i].x, src[i].y))
	return out


static func _ellipse(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in 16:
		var ang := TAU * float(k) / 16.0
		out.append(c + Vector2(cos(ang) * rx, sin(ang) * ry))
	return out


static func _ell_px(c: Vector2, rx: float, ry: float) -> PackedVector2Array:
	return _ellipse(c, rx, ry)


static func _halo(ci: CanvasItem, c: Vector2, r: float, col: Color, a: float) -> void:
	for k in 12:
		ci.draw_circle(c, r * (1.0 - float(k) * 0.08), Color(col, a * 0.1))


static func _flame(ci: CanvasItem, c: Vector2, r: float, t: float, seed: float, col: Color) -> void:
	var f1 := sin(t * 8.0 + seed * 3.0) * 0.14
	var f2 := sin(t * 11.0 + seed * 2.3)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(f1 * r, -r * (1.05 + 0.12 * f2)), c + Vector2(r * 0.42, -r * 0.4), c + Vector2(r * 0.52, r * 0.15),
		c + Vector2(r * 0.25, r * 0.5), c + Vector2(-r * 0.25, r * 0.5), c + Vector2(-r * 0.52, r * 0.15),
		c + Vector2(-r * 0.4, -r * (0.45 + f1))]), col)

## The fork world object of RoadScene: a junction at world depth `z` where the road splits into 2-3 trails, each with
## a landmark at its far end. Trails use the road's own colours / mottling / rim, so it reads as one road.
## Lanes are in road half-widths from the (pre-split) road centre; `w` = depth beyond the split.
class_name RoadFork
extends RefCounted

const W_END := 0.24 ## depth after the split where the trails reach their final lane and width
const ROWS := 28
## The trunk runs this far under the trails and the trails fade in over it, so the junction has no seam.
const BLEND_Z := 0.022
const LAND_K := 0.9
## Narrow soft edge zone (the trunk's is wider): crisp trails, not blurry fingers.
const COLS := [-1.0, -0.96, -0.5, 0.0, 0.5, 0.96, 1.0]
const LABEL_FAR := 0.5
const LABEL_NEAR := 0.3

var z := 0.9
var doors: Array[Door] = []
var n := 0
var picked := -1
var steer := 0.0
var ext := 0.0
var appear := 0.0
var hover := -1
var pressed := -1
var reached := false
var fade: Array[float] = [1.0, 1.0, 1.0] ## trail alpha
var lm: Array[float] = [1.0, 1.0, 1.0] ## landmark alpha
var act: Array[float] = [0.0, 0.0, 0.0]
var dim: Array[float] = [0.0, 0.0, 0.0]
var out_k := 1.0 ## fork-wide alpha while fading out (fade_fork)
var gone := false ## fade finished: RoadScene removes the fork
var arrived := false ## walk finished: the chosen trail straightens into a plain road
var settle := 0.0
var settle_lane := 0.0
var _out_time := 0.0
var _time := 0.0
var _wc: Array[float] = [] ## per neighbour pair: depth where the inner edges part (the crotch)


func _init(offer: DoorOffer, start_z: float) -> void:
	z = start_z
	set_offer(offer)


func set_offer(offer: DoorOffer) -> void:
	var old := n
	doors = offer.doors.duplicate()
	n = clampi(doors.size(), 0, 3)
	if n != old:
		_calc_crotch()


func tick(delta: float) -> void:
	_time += delta
	appear = minf(appear + delta / 1.2, 1.0)
	if picked >= 0:
		steer = minf(steer + delta / 0.6, 1.0)
		ext = minf(ext + delta / 0.9, 1.0)
	if arrived:
		settle = minf(settle + delta / 0.35, 1.0)
	if _out_time > 0.0:
		out_k = maxf(out_k - delta / _out_time, 0.0)
		gone = out_k <= 0.0
	var focus := pressed if pressed >= 0 else hover
	for i in 3:
		var other := picked >= 0 and i != picked
		fade[i] = move_toward(fade[i], 0.0 if other else 1.0, delta / 1.0)
		lm[i] = move_toward(lm[i], 0.0 if other else 1.0, delta / 0.8)
		var f := focus if picked < 0 else -1
		act[i] = move_toward(act[i], 1.0 if i == f else 0.0, delta * 6.0)
		dim[i] = move_toward(dim[i], 1.0 if f >= 0 and i != f else 0.0, delta * 4.0)


# -- shape (lane units) ----------------------------------------------------------------------------

func l0(i: int) -> float:
	return 0.0 ## every trail starts on the road itself, as wide as the road, so the split reads as the road branching


func l_end(i: int) -> float:
	return (-3.2 if i == 0 else 3.2) if n == 2 else [-4.6, 0.0, 4.6][i]


func length(i: int) -> float:
	return 0.26 if n == 2 else (0.32 if i == 1 else 0.22)


func start_fade(seconds: float) -> void:
	_out_time = maxf(seconds, 0.01)


func _k(w: float) -> float:
	var t := clampf(w / W_END, 0.0, 1.0)
	return 1.0 - (1.0 - t) * (1.0 - t)


func lane_raw(i: int, w: float) -> float:
	return lerpf(l0(i), l_end(i), _k(w))


## After arrival the chosen trail relaxes to a straight, full-width road at the camera lane (= the trunk after rebase).
func lane(i: int, w: float) -> float:
	var v := lane_raw(i, w)
	if i == picked and settle > 0.0:
		v = lerpf(v, settle_lane, smoothstep(0.0, 1.0, settle))
	return v


func hw(i: int, w: float) -> float:
	var v := lerpf(1.0, 0.85 if (n == 3 and i == 1) else 1.0, _k(w))
	if i == picked and settle > 0.0:
		v = lerpf(v, 1.0, smoothstep(0.0, 1.0, settle))
	return v


func arrive() -> void:
	settle_lane = cam_lane()
	arrived = true
	ext = 1.0


func _calc_crotch() -> void:
	_wc.clear()
	for i in maxi(n - 1, 0):
		var wc := W_END
		for s in 240:
			var w := float(s) * 0.001
			if lane(i + 1, w) - hw(i + 1, w) > lane(i, w) + hw(i, w):
				wc = w
				break
		_wc.append(wc)


## Camera lateral shift (lanes) once a trail is picked.
func cam_lane() -> float:
	if picked < 0:
		return 0.0
	var back := maxf(-z, 0.0)
	## looks ahead by the arrival depth so that at arrival the camera is centred on the landmark's lane
	return lane_raw(picked, back + RoadScene.ARRIVE_Z * smoothstep(0.0, 0.1, back)) * smoothstep(0.0, 1.0, steer)


func landmark_z(i: int) -> float:
	return z + length(i)


## Trail indices, farthest landmark first.
func landmark_order() -> Array[int]:
	var out: Array[int] = []
	for i in n:
		out.append(i)
	out.sort_custom(func(a: int, b: int) -> bool: return length(a) > length(b))
	return out


## Pushes a prop's x out of the trail corridors (props standing beyond the split).
func fit_prop(x: float, w: float) -> float:
	var lo := INF
	var hi := -INF
	for i in n:
		lo = minf(lo, lane(i, w) - hw(i, w))
		hi = maxf(hi, lane(i, w) + hw(i, w))
	if x > lo - 0.7 and x < hi + 0.7:
		return (1.0 if x >= 0.0 else -1.0) * (maxf(absf(lo), absf(hi)) + 0.8 + fposmod(absf(x) * 7.3, 1.0))
	return x


## A decal beyond the split sits on a random trail (or far away if no trail reaches that depth).
func fit_decal(w: float, rng: RandomNumberGenerator) -> float:
	var ok: Array[int] = []
	for i in n:
		if length(i) >= w:
			ok.append(i)
	if ok.is_empty():
		return 99.0
	var i: int = ok[rng.randi() % ok.size()]
	return lane(i, w) + (rng.randf() - 0.5) * 1.1 * hw(i, w)


# -- projection -------------------------------------------------------------------------------------

## Trail centre line rows near to far: pts = (x, y, half width px), zs = depth.
func _rows(r: RoadScene, i: int) -> Dictionary:
	var w := r.size.x
	var h := r.size.y
	var hy := h * RoadScene.HORIZON
	var rh := w * RoadScene.ROAD_HALF
	var z_a := maxf(z, 0.0)
	var l := length(i)
	var z_b := lerpf(z + l, maxf(z + l, 1.05), ext) if i == picked else z + l
	var pts := PackedVector3Array()
	var zs := PackedFloat32Array()
	if z_b <= z_a + 0.002:
		return {"pts": pts, "zs": zs}
	var s_a := r._scale_at(z_a)
	var s_b := r._scale_at(z_b)
	for k in ROWS + 1:
		var s := lerpf(s_a, s_b, float(k) / float(ROWS))
		var zr := (1.0 / s - 1.0) / RoadScene.DEPTH_K
		var wr := maxf(zr - z, 0.0)
		pts.append(Vector3(w * 0.5 + r._shift(zr) + lane(i, wr) * rh * s, hy + (h - hy) * s, hw(i, wr) * rh * s))
		zs.append(zr)
	return {"pts": pts, "zs": zs}


func hit(r: RoadScene, p: Vector2) -> int:
	if picked >= 0 or n == 0:
		return -1
	var best := -1
	var best_m := INF
	for i in n:
		var rows := _rows(r, i)
		var pts: PackedVector3Array = rows["pts"]
		var m := INF
		if pts.size() > 0:
			var left := PackedVector2Array()
			var right := PackedVector2Array()
			var k_near := 0
			for k in pts.size():
				var g := pts[k]
				var pad := g.z * 1.1 + 14.0
				left.append(Vector2(g.x - pad, g.y))
				right.append(Vector2(g.x + pad, g.y))
				if absf(g.y - p.y) < absf(pts[k_near].y - p.y):
					k_near = k
			for k in range(right.size() - 1, -1, -1):
				left.append(right[k])
			if Geometry2D.is_point_in_polygon(p, left):
				m = absf(p.x - pts[k_near].x) / maxf(pts[k_near].z, 1.0)
		var lp := _lm_geom(r, i)
		if lp.z > 0.0:
			var half := maxf(lp.z * 0.55, r.size.x * 0.06)
			var top := lp.y - ForkLandmarks.height_of(doors[i].kind_id) * lp.z - 90.0
			if Rect2(lp.x - half, top, half * 2.0, lp.y + 24.0 - top).has_point(p):
				m = minf(m, 0.3)
		if m < best_m:
			best_m = m
			best = i
	return best


## (x, y base, unit px) of the landmark; unit 0 = gone.
func _lm_geom(r: RoadScene, i: int) -> Vector3:
	var zl := z + length(i)
	if zl < -0.01:
		return Vector3.ZERO
	var w := r.size.x
	var h := r.size.y
	var s := r._scale_at(maxf(zl, RoadScene.Z_MIN))
	var rh := w * RoadScene.ROAD_HALF
	return Vector3(w * 0.5 + r._shift(zl) + lane(i, length(i)) * rh * s,
		h * RoadScene.HORIZON + (h - h * RoadScene.HORIZON) * s,
		h * LAND_K * s * ForkLandmarks.scale_of(doors[i].kind_id))


# -- drawing ----------------------------------------------------------------------------------------

func _tint(c: Color, i: int) -> Color:
	var f := 1.0 + 0.35 * act[i] - 0.35 * dim[i]
	return Color(minf(c.r * f, 1.0), minf(c.g * f, 1.0), minf(c.b * f, 1.0), c.a)


func draw_trails(r: RoadScene) -> void:
	if n == 0:
		return
	for i in n:
		if fade[i] > 0.01:
			_draw_trail(r, i)
	_draw_junction_mist(r)


func _trail_colors(r: RoadScene, i: int, w: float, zr: float, wz: float, a: float) -> Array[Color]:
	var fog_t := pow(clampf(zr, 0.0, 1.0), 0.7) * 0.85
	var base: Array[Color] = r._road_colors(fog_t, wz, COLS) # exactly the trunk's texture
	var plain: Array[Color] = []
	var out: Array[Color] = []
	for j in COLS.size():
		var cj: float = COLS[j]
		var res := base[j]
		if (cj < 0.0 and i > 0) or (cj > 0.0 and i < n - 1):
			# inner side: no rim before the crotch, then the trunk's edge treatment
			if plain.is_empty():
				var flat: Array = []
				for q in COLS.size():
					flat.append(COLS[q] * 0.4)
				plain = r._road_colors(fog_t, wz, flat)
			var wc: float = _wc[i - 1] if cj < 0.0 else _wc[i]
			res = plain[j].lerp(base[j], smoothstep(wc, wc + 0.03, w))
		res.a *= a
		out.append(_tint(res, i))
	return out


func _draw_trail(r: RoadScene, i: int) -> void:
	var rows := _rows(r, i)
	var pts: PackedVector3Array = rows["pts"]
	var zs: PackedFloat32Array = rows["zs"]
	if pts.size() < 2:
		return
	var a := smoothstep(0.0, 1.0, fade[i]) * smoothstep(0.0, 0.5, appear)
	var rh := r.size.x * RoadScene.ROAD_HALF
	var prev: Array = []
	var last_mid := Color.WHITE
	for k in pts.size():
		var g := pts[k]
		var zr := zs[k]
		var wr := maxf(zr - z, 0.0)
		var s := r._scale_at(zr)
		var wz := zr + r._travel
		var cols := _trail_colors(r, i, wr, zr, wz, a)
		var ramp := 1.0 if picked >= 0 else smoothstep(0.0, BLEND_Z * 0.8, wr)
		for cj in cols.size():
			cols[cj].a *= ramp
		var d := 1.0 - smoothstep(0.0, 0.1, wr)
		var ln := lane(i, wr)
		var wd := hw(i, wr)
		var lane_fix: float = ln * (r._edge(wz, -1.0 if ln < 0.0 else 1.0) - 1.0) * d
		var row: Array = []
		for j in COLS.size():
			var cj: float = COLS[j]
			var m: float = r._edge(wz, -1.0 if cj < 0.0 else 1.0)
			var dx := (lane_fix + cj * wd * (m - 1.0)) * rh * s
			row.append([Vector2(g.x + dx + cj * g.z, g.y), cols[j]])
		if k == pts.size() - 1:
			last_mid = cols[3]
		if not prev.is_empty():
			for j in COLS.size() - 1:
				if prev[j + 1][0].x <= prev[j][0].x + 0.1 or row[j + 1][0].x <= row[j][0].x + 0.1:
					continue
				r.draw_polygon(PackedVector2Array([prev[j][0], prev[j + 1][0], row[j + 1][0], row[j][0]]),
					PackedColorArray([prev[j][1], prev[j + 1][1], row[j + 1][1], row[j][1]]))
		prev = row
	_draw_ruts(r, pts, zs, a)
	if ext < 0.5:
		var e := pts[pts.size() - 1]
		_draw_cap(r, Vector2(e.x, e.y), e.z, last_mid, a * (1.0 - ext * 2.0), i)


## Same faint wheel ruts as the trunk, along the trail centre line.
func _draw_ruts(r: RoadScene, pts: PackedVector3Array, zs: PackedFloat32Array, a: float) -> void:
	for side in [-1.0, 1.0]:
		for k in range(1, pts.size()):
			var ga := pts[k - 1]
			var gb := pts[k]
			var wa: float = r._noise.get_noise_1d((zs[k - 1] + r._travel) * 9.0 + side * 40.0) * 0.06
			var wb: float = r._noise.get_noise_1d((zs[k] + r._travel) * 9.0 + side * 40.0) * 0.06
			var xa: float = ga.x + (side * 0.4 + wa) * ga.z
			var xb: float = gb.x + (side * 0.4 + wb) * gb.z
			var ra := ga.z * 0.2
			var rb := gb.z * 0.2
			# Ruts fade in after the split instead of starting at the seam.
			var al := 0.3 * (1.0 - clampf(zs[k - 1], 0.0, 1.0)) * a * smoothstep(0.0, 0.14, maxf(zs[k - 1] - z, 0.0))
			var c1 := Color(r._look.rut, al)
			var c0 := Color(r._look.rut, 0.0)
			r.draw_polygon(PackedVector2Array([Vector2(xa - ra, ga.y), Vector2(xa, ga.y), Vector2(xb, gb.y),
				Vector2(xb - rb, gb.y)]), PackedColorArray([c0, c1, c1, c0]))
			r.draw_polygon(PackedVector2Array([Vector2(xa, ga.y), Vector2(xa + ra, ga.y), Vector2(xb + rb, gb.y),
				Vector2(xb, gb.y)]), PackedColorArray([c1, c0, c0, c1]))


func _draw_cap(r: RoadScene, c: Vector2, rx: float, mid: Color, a: float, i: int) -> void:
	mid.a = 1.0
	for layer in 2:
		var rr := rx * (1.0 if layer == 0 else 0.9)
		var poly := PackedVector2Array()
		for q in 20:
			var ang := TAU * float(q) / 20.0
			poly.append(c + Vector2(cos(ang) * rr, sin(ang) * rr * 0.3))
		r.draw_colored_polygon(poly, _tint(Color(mid.darkened(0.25) if layer == 0 else mid, a), i))


## A bit of mist over the split and in each crotch.
func _draw_junction_mist(r: RoadScene) -> void:
	var look: SceneryCatalog.Look = r._look
	var w := r.size.x
	var h := r.size.y
	var hy := h * RoadScene.HORIZON
	var rh := w * RoadScene.ROAD_HALF
	var a := smoothstep(0.0, 0.8, appear) * clampf(1.0 - ext, 0.0, 1.0)
	var spots: Array[Vector3] = [] # x, y, radius px
	if z > 0.0:
		var s := r._scale_at(z)
		spots.append(Vector3(w * 0.5 + r._shift(z), hy + (h - hy) * s, rh * s * 1.5))
	for i in maxi(n - 1, 0):
		var wv: float = _wc[i] + 0.012
		var zc := z + wv
		var sc := r._scale_at(zc)
		var xa := (lane(i, wv) + hw(i, wv) + lane(i + 1, wv) - hw(i + 1, wv)) * 0.5
		spots.append(Vector3(w * 0.5 + r._shift(zc) + xa * rh * sc, hy + (h - hy) * sc, rh * sc * 0.9))
	for sp in spots:
		for k in 4:
			var f := 1.0 - float(k) * 0.22
			var poly := PackedVector2Array()
			for q in 16:
				var ang := TAU * float(q) / 16.0
				poly.append(Vector2(sp.x + cos(ang) * sp.z * f, sp.y + sin(ang) * sp.z * 0.28 * f))
			r.draw_colored_polygon(poly, Color(look.fog.lightened(0.05), 0.025 * a))


func draw_landmark(r: RoadScene, i: int) -> void:
	var a := lm[i] * out_k * smoothstep(0.3, 0.9, appear) * lerpf(1.0, 0.55, dim[i])
	if a <= 0.01:
		return
	var g := _lm_geom(r, i)
	if g.z <= 0.0:
		return
	var look: SceneryCatalog.Look = r._look
	var kind := doors[i].kind_id
	var kcol := PathView.kind_color(kind)
	var zl := clampf(z + length(i), 0.0, 1.1)
	var body := look.silhouette.lerp(look.fog, 0.1 + 0.5 * zl).lerp(kcol, 0.06)
	body = body.lightened(0.12 * act[i]).darkened(0.3 * dim[i])
	var st := {
		"body": body, "glow": kcol, "eye": look.accent.lightened(0.35),
		"bone": look.fog.lerp(Color(0.85, 0.82, 0.75), 0.6),
		"t": _time + float(i) * 1.7, "a": a, "g": (0.85 + 0.7 * zl) + 0.7 * act[i] - 0.35 * dim[i],
	}
	ForkLandmarks.draw(r, kind, Vector2(g.x, g.y), g.z, st)


func draw_labels(r: RoadScene) -> void:
	var la := 1.0 - smoothstep(LABEL_NEAR, LABEL_FAR, z)
	if la <= 0.01 or picked >= 0:
		return
	var font := r.get_theme_default_font()
	var fs0 := int(roundf(clampf(r.size.x * 0.026, 11.0, 28.0)))
	var maxw := r.size.x * (0.27 if n == 3 else 0.4)
	for i in n:
		var g := _lm_geom(r, i)
		if g.z <= 0.0:
			continue
		var a := la * lm[i] * smoothstep(0.7, 1.0, appear) * lerpf(1.0, 0.5, dim[i])
		var door := doors[i]
		var kcol := PathView.kind_color(door.kind_id)
		var texts := ForkView.fork_text(door)
		var lines: Array = [
			[texts[0], fs0, kcol.lightened(0.55)],
			[texts[1], int(fs0 * 0.78), Color(0.82, 0.82, 0.85)],
			[texts[2], int(fs0 * 0.68), kcol.lightened(0.4)],
		]
		var y := g.y - ForkLandmarks.height_of(door.kind_id) * g.z - fs0 * 0.6 + sin(_time * 1.3 + float(i)) * 2.0
		var x := clampf(g.x, maxw * 0.5 + 4.0, r.size.x - maxw * 0.5 - 4.0)
		for k in range(2, -1, -1):
			var line: Array = lines[k]
			var text: String = line[0]
			if text == "":
				continue
			var fs: int = line[1]
			while fs > 9 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw:
				fs -= 1
			var c: Color = line[2]
			c.a = a
			var pos := Vector2(x - maxw * 0.5, y)
			r.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs, maxi(3, fs / 5),
				Color(0.02, 0.02, 0.03, a * 0.95))
			r.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, maxw, fs, _tint(c, i))
			y -= fs * 1.25

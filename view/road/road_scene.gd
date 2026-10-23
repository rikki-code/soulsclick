## Procedural pseudo-3D road (no textures). `setup` picks the realm look and seeds the scenery,
## `scroll` / `set_speed` move the camera forward. Props have depth z in [0, 1]: 0 = camera, 1 = horizon.
class_name RoadScene
extends Control

const HORIZON := 0.38
const DEPTH_K := 24.0 ## scale = 1 / (1 + DEPTH_K * z)
const PROP_COUNT := 40
const UNIT_FRAC := 0.45
const ROAD_HALF := 0.46 ## of the width at the camera plane
const DECAL_COUNT := 22
const ROWS := 40
const BEND := 1.0 ## road bend strength (1 = about 0.2 of the width at mid distance)
const Z_MIN := -0.025
const FADE_START := 0.9
const FORK_FAR_Z := 0.9
const FORK_STOP_Z := 0.05
const MTN_COLS := 48
const CORRIDOR := 1.7 ## props keep this many road half-widths from the road centre line
const ARRIVE_Z := 0.12 ## depth of the chosen landmark where the walk stops
const WEB_REDRAW_STEP := 1.0 / 30.0 ## web/mobile redraw cap (seconds); other platforms redraw every frame

signal fork_reached
signal trail_picked(index: int)
signal trail_arrived(index: int)

class Prop extends RefCounted:
	var kind: SceneryKind
	var x := 0.0 ## in road half-widths, sign = side
	var z := 1.0
	var mul := 1.0
	var flip := 1.0
	var decal := false

var _look: SceneryCatalog.Look = SceneryCatalog.look(0)
var _kinds: Array[SceneryKind] = []
var _props: Array[Prop] = []
var _decals: Array[Prop] = []
var _dkinds: Array[SceneryKind] = []
var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _mountains: Array[PackedVector2Array] = [] ## normalized: x 0..1, y = peak height factor
var _travel := 0.0
var _speed := 0.0
var _fork: RoadFork
var _bend_k := 1.0 ## road bend factor (tweens to 0 near a fork)
var _cam_x := 0.0 ## camera lateral shift in road half-widths (steering into a trail)
var _to_fork := false
var _to_trail := false ## walking along the picked trail to its landmark
var _tr_time := 0.0 ## realm transition: total seconds (0 = none) and progress 0..1
var _tr_t := 0.0
var _tr_from: SceneryCatalog.Look
var _tr_to: SceneryCatalog.Look
var _tr_mtn_from: Array[PackedFloat32Array] = []
var _tr_mtn_to: Array[PackedFloat32Array] = []
var _redraw_wait := 0.0
var _redraw_pending := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	setup(0, 1)


## Rebuilds look and scenery. Same (realm, seed) gives the same road.
func setup(realm_index: int, seed: int) -> void:
	_look = SceneryCatalog.look(realm_index)
	_kinds = SceneryCatalog.kinds_for(realm_index)
	_dkinds = SceneryCatalog.decals_for(realm_index)
	_rng.seed = hash(seed * 31 + realm_index)
	_noise.seed = seed * 7 + realm_index
	_noise.frequency = 1.0
	_noise.fractal_octaves = 3
	_tr_time = 0.0
	_travel = 0.0
	_props.clear()
	for i in PROP_COUNT:
		var p := Prop.new()
		_respawn(p)
		p.z = (float(i) + _rng.randf()) / float(PROP_COUNT)
		_props.append(p)
	_decals.clear()
	for i in DECAL_COUNT:
		var d := Prop.new()
		d.decal = true
		_respawn(d)
		d.z = (float(i) + _rng.randf()) / float(DECAL_COUNT)
		_decals.append(d)
	_mountains.clear()
	for layer in _look.mountains.size():
		var pts := PackedVector2Array([Vector2(0, 0)])
		var n := _look.peaks * (layer + 1)
		for i in n + 1:
			var jag := 0.35 + 0.65 * _rng.randf()
			pts.append(Vector2(float(i) / float(n), jag * (1.0 - 0.35 * layer)))
		pts.append(Vector2(1, 0))
		_mountains.append(pts)
	queue_redraw()


## Eases into another realm without a pop: the look blends over `seconds` while the road keeps scrolling, props that
## respawn at the horizon are already of the new realm. Same (realm, seed) gives the same result.
func transition_to_realm(realm_index: int, seed: int, seconds: float) -> void:
	_tr_from = _look
	_tr_to = SceneryCatalog.look(realm_index)
	_kinds = SceneryCatalog.kinds_for(realm_index)
	_dkinds = SceneryCatalog.decals_for(realm_index)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed * 31 + realm_index)
	_tr_mtn_from.clear()
	_tr_mtn_to.clear()
	for layer in _tr_to.mountains.size():
		_tr_mtn_from.append(_sample_layer(_mountains[mini(layer, _mountains.size() - 1)]))
		var pts := _make_layer(_tr_to, layer, rng)
		_tr_mtn_to.append(_sample_layer(pts))
	_tr_t = 0.0
	_tr_time = maxf(seconds, 0.01)
	queue_redraw()


func _make_layer(look: SceneryCatalog.Look, layer: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(0, 0)])
	var n := look.peaks * (layer + 1)
	for i in n + 1:
		var jag := 0.35 + 0.65 * rng.randf()
		pts.append(Vector2(float(i) / float(n), jag * (1.0 - 0.35 * layer)))
	pts.append(Vector2(1, 0))
	return pts


## Height of the layer outline at MTN_COLS + 1 even columns.
func _sample_layer(pts: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for c in MTN_COLS + 1:
		var x := float(c) / float(MTN_COLS)
		var y := 0.0
		for i in pts.size() - 1:
			if x >= pts[i].x and x <= pts[i + 1].x:
				var d := pts[i + 1].x - pts[i].x
				y = pts[i].y if d <= 0.0 else lerpf(pts[i].y, pts[i + 1].y, (x - pts[i].x) / d)
				break
		out.append(y)
	return out


func _step_transition(delta: float) -> void:
	_tr_t = minf(_tr_t + delta / _tr_time, 1.0)
	var k := smoothstep(0.0, 1.0, _tr_t)
	_look = _tr_from.lerp_to(_tr_to, k)
	_mountains.clear()
	for layer in _tr_mtn_to.size():
		var pts := PackedVector2Array()
		for c in MTN_COLS + 1:
			pts.append(Vector2(float(c) / float(MTN_COLS), lerpf(_tr_mtn_from[layer][c], _tr_mtn_to[layer][c], k)))
		pts.append(Vector2(1, 0))
		_mountains.append(pts)
	if _tr_t >= 1.0:
		_tr_time = 0.0
		_look = _tr_to
	_request_redraw()


## Moves the camera forward by `distance` (1.0 = one horizon-to-camera depth cycle).
func scroll(distance: float) -> void:
	_travel += distance
	if _fork:
		_fork.z -= distance
	for pool in [_props, _decals]:
		for p: Prop in pool:
			p.z -= distance
			if p.z < Z_MIN:
				var over := p.z - Z_MIN
				_respawn(p)
				p.z = minf(1.0, 1.0 + Z_MIN + over) # far end, keeps the overshoot
				_fit_fork(p)
	_sync_fork()
	_request_redraw()


## Places the junction at `FORK_FAR_Z` (a world object: it approaches with `scroll` like props).
func show_fork(offer: DoorOffer) -> void:
	if _fork:
		clear_fork()
	_fork = RoadFork.new(offer, FORK_FAR_Z)
	_to_fork = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	for p: Prop in _props:
		_fit_fork(p)
	for p: Prop in _decals:
		_fit_fork(p)
	_sync_fork()
	queue_redraw()


## Walks (speed eased) until the fork is at `FORK_STOP_Z`, then stops and emits `fork_reached`.
func walk_to_fork() -> void:
	if _fork == null:
		get_tree().create_timer(0.05).timeout.connect(func() -> void: fork_reached.emit())
		return
	_to_fork = true


func update_fork(offer: DoorOffer) -> void:
	if _fork:
		_fork.set_offer(offer)
		queue_redraw()


## Removes the fork at once; props keep their screen place, the road bend restores smoothly.
func clear_fork() -> void:
	if _fork == null:
		return
	for pool in [_props, _decals]:
		for p: Prop in pool:
			if absf(p.x) < 50.0:
				p.x -= _cam_x
	_fork = null
	for p: Prop in _props:
		if absf(p.x) < CORRIDOR: # safety: nothing stands on the road after the rebase
			p.x = (1.0 if p.x >= 0.0 else -1.0) * (CORRIDOR + fposmod(absf(p.x) * 7.3, 1.0))
	_cam_x = 0.0
	_to_fork = false
	_to_trail = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


## Camera steers into trail `index` (only after `fork_reached`); emits `trail_picked`.
func pick_trail(index: int) -> void:
	if _fork == null or _fork.picked >= 0 or not _fork.reached or index < 0 or index >= _fork.n:
		return
	_fork.picked = index
	_fork.hover = -1
	_fork.pressed = -1
	_to_trail = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	trail_picked.emit(index)


## Fades the landmark out over `seconds` (the road stays), then removes the fork; the trunk continues from the same spot.
func fade_fork(seconds: float) -> void:
	if _fork:
		_fork.start_fade(seconds)


func _has_point(point: Vector2) -> bool:
	return _fork != null and _fork.hit(self, point) >= 0


func _gui_input(event: InputEvent) -> void:
	if _fork == null:
		return
	if event is InputEventMouseMotion:
		_fork.hover = _fork.hit(self, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_fork.pressed = _fork.hit(self, event.position)
			if _fork.pressed >= 0:
				accept_event()
		else:
			var i := _fork.hit(self, event.position)
			var was := _fork.pressed
			_fork.pressed = -1
			if i >= 0 and i == was:
				accept_event()
				pick_trail(i)


## Props that would stand on the road you now walk (the chosen trail, straightened at arrival) go away: near ones
## respawn far, the others are pushed sideways. x is in the fork frame (lane 0 = trunk centre).
func _clear_road_props() -> void:
	var c := _fork.settle_lane
	for p: Prop in _props:
		var w := maxf(p.z - _fork.z, 0.0)
		var raw := _fork.lane_raw(_fork.picked, w)
		var lo := minf(raw, c) - CORRIDOR
		var hi := maxf(raw, c) + CORRIDOR
		if p.x <= lo or p.x >= hi:
			continue
		if p.z < 0.4:
			_respawn(p)
			p.x += c
		else:
			var side := 1.0 if p.x >= (lo + hi) * 0.5 else -1.0
			p.x = (hi if side > 0.0 else lo) + side * fposmod(absf(p.x) * 7.3, 1.0) * 0.8


func _fit_fork(p: Prop) -> void:
	if _fork == null or p.z <= _fork.z:
		return
	if _fork.arrived: # the road is the straightened chosen trail
		p.x += _fork.settle_lane
		return
	var wv := p.z - _fork.z
	p.x = _fork.fit_decal(wv, _rng) if p.decal else _fork.fit_prop(p.x, wv)


## Bend straightening, camera steer and end of the pick transition.
func _sync_fork() -> void:
	if _fork == null:
		return
	_bend_k = smoothstep(0.3, 0.75, _fork.z)
	_cam_x = _fork.cam_lane()
	if _fork.gone:
		clear_fork()


## Continuous walking speed in depth cycles per second (0 = stand).
func set_speed(v: float) -> void:
	_speed = v


## Marks the road dirty; the actual redraw happens in _process, at most once per redraw step on web.
func _request_redraw() -> void:
	_redraw_pending = true


func _process(delta: float) -> void:
	_advance(delta)
	_redraw_wait += delta
	var step := WEB_REDRAW_STEP if OS.has_feature("web") else 0.0
	if _redraw_pending and _redraw_wait >= step:
		_redraw_wait = 0.0
		_redraw_pending = false
		queue_redraw()


func _advance(delta: float) -> void:
	if _tr_time > 0.0:
		_step_transition(delta)
	if _fork:
		_fork.tick(delta)
		if _fork.gone:
			clear_fork()
			_request_redraw()
			return
		if _to_trail:
			var remain_t := _fork.landmark_z(_fork.picked) - ARRIVE_Z
			_speed = move_toward(_speed, clampf(remain_t * 2.2, 0.05, 0.38), delta * 0.9)
			if _speed * delta >= remain_t:
				_speed = 0.0
				_to_trail = false
				scroll(maxf(remain_t, 0.0))
				_fork.arrive()
				_clear_road_props()
				trail_arrived.emit(_fork.picked)
				return
		if _to_fork:
			var remain := _fork.z - FORK_STOP_Z
			_speed = move_toward(_speed, clampf(remain * 2.2, 0.05, 0.38), delta * 0.9)
			if _speed * delta >= remain:
				_speed = 0.0
				_to_fork = false
				scroll(maxf(remain, 0.0))
				_fork.reached = true
				fork_reached.emit()
				return
		_request_redraw()
	elif _bend_k < 1.0:
		_bend_k = move_toward(_bend_k, 1.0, delta * 0.6)
		_request_redraw()
	if _speed != 0.0:
		scroll(_speed * delta)


func _respawn(p: Prop) -> void:
	if p.decal:
		p.kind = _dkinds[_rng.randi() % _dkinds.size()]
		p.x = _rng.randf_range(-0.85, 0.85) if p.kind.size < 0.15 else _rng.randf_range(-0.5, 0.5)
		p.z = 1.0
		p.mul = 0.6 + _rng.randf() * 0.9
		p.flip = -1.0 if _rng.randf() < 0.5 else 1.0
		return
	p.kind = _kinds[_rng.randi() % _kinds.size()]
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	p.x = side * (1.25 + _rng.randf() * (1.2 if p.kind.size < 0.5 else 3.5))
	p.z = 1.0
	p.mul = 0.8 + _rng.randf() * 0.5
	p.flip = -1.0 if _rng.randf() < 0.5 else 1.0


func _scale_at(z: float) -> float:
	return 1.0 / (1.0 + DEPTH_K * z)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var hy := h * HORIZON
	var cx := w * 0.5
	_draw_sky(w, hy)
	_draw_mountains(w, hy)
	_draw_ground(w, h, hy)
	_draw_road(w, h, hy, cx)
	_draw_props(w, h, hy, cx)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sky(w: float, hy: float) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, hy), Vector2(0, hy)]),
		PackedColorArray([_look.sky_top, _look.sky_top, _look.sky_low, _look.sky_low]))
	var m := Vector2(w * 0.72, hy * 0.5)
	for i in 4:
		draw_circle(m, w * (0.09 - 0.016 * i), Color(_look.moon, _look.moon.a * (0.12 + 0.2 * i)))


func _draw_mountains(w: float, hy: float) -> void:
	for layer in _mountains.size():
		var src := _mountains[layer]
		var pts := PackedVector2Array()
		for p in src:
			pts.append(Vector2(p.x * w, hy - p.y * _look.peak_height * size.y * 2.0 * (layer + 1) * 0.6))
		draw_colored_polygon(pts, _look.mountains[layer])
		# base line sits on the horizon; first and last points have y = 0 -> hy
	draw_rect(Rect2(0, hy - 2.0, w, 4.0), _look.fog)


func _draw_ground(w: float, h: float, hy: float) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, hy), Vector2(w, hy), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([_look.fog.lerp(_look.ground, 0.5), _look.fog.lerp(_look.ground, 0.5), _look.ground,
			_look.ground]))


func _edge(world_z: float, side: float) -> float:
	return 1.0 + _noise.get_noise_1d(world_z * 14.0 + side * 100.0) * _look.ragged * 2.0


## Screen-space lateral shift of the road centre at depth z: 0 at the camera plane, bends approach with travel.
func _shift(z_in: float) -> float:
	var z := z_in
	if _fork:
		z = minf(z, maxf(_fork.z, 0.0)) # straight beyond the junction
	var u := z + _travel
	var u0 := _travel
	var g := 0.12 * sin(u * TAU * 1.3 + 0.7) + 0.07 * sin(u * TAU * 2.3 + 2.1) + 0.05 * _noise.get_noise_1d(u * 1.6 + 300.0)
	var g0 := 0.12 * sin(u0 * TAU * 1.3 + 0.7) + 0.07 * sin(u0 * TAU * 2.3 + 2.1) + 0.05 * _noise.get_noise_1d(u0 * 1.6 + 300.0)
	var env := (1.0 - exp(-clampf(z, 0.0, 1.5) * 8.0)) * (1.0 - 0.65 * clampf(z, 0.0, 1.0))
	return size.x * BEND * (g - g0) * env * _bend_k - _cam_x * size.x * ROAD_HALF * _scale_at(z_in)


func _draw_road(w: float, h: float, hy: float, cx: float) -> void:
	var rh := w * ROAD_HALF
	var z_top := 1.0 if _fork == null else minf(_fork.z + RoadFork.BLEND_Z, 1.0)
	if _fork and _fork.picked >= 0 and _fork.z <= 0.0:
		z_top = 0.0 # junction is behind the camera: the chosen trail alone covers the road
	if z_top > 0.004:
		_draw_trunk(w, h, hy, cx, z_top)
	if _fork:
		_fork.draw_trails(self)
	_draw_decals(w, h, hy, cx, rh)


func _draw_trunk(w: float, h: float, hy: float, cx: float, z_top: float) -> void:
	var rh := w * ROAD_HALF
	var sfar := _scale_at(z_top)
	var ys := PackedFloat32Array()
	var zs := PackedFloat32Array()
	var hl := PackedFloat32Array()
	var hr := PackedFloat32Array()
	var hs := PackedFloat32Array()
	var sh := PackedFloat32Array()
	var rowcols: Array = []
	var cols := [-1.0, -0.9, -0.5, 0.0, 0.5, 0.9, 1.0]
	var rows := ROWS
	for i in rows + 1:
		var t := pow(float(i) / float(rows), 2.0)
		var s := sfar + (1.0 - sfar) * t
		var z := (1.0 / s - 1.0) / DEPTH_K
		var wz := z + _travel
		zs.append(z)
		ys.append(hy + (h - hy) * s)
		hs.append(rh * s)
		hl.append(rh * s * _edge(wz, -1.0))
		hr.append(rh * s * _edge(wz, 1.0))
		sh.append(_shift(z))
		rowcols.append(_road_colors(pow(clampf(z, 0.0, 1.0), 0.7) * 0.85, wz, cols))
	# soft-edged trail: ragged dark rim -> mottled dirt, fogged with distance. The whole trunk (dirt and ruts)
	# is one triangle batch: hundreds of separate draw_polygon calls were the main cost of a road frame.
	var verts := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for i in rows:
		var ca: Array = rowcols[i + 1]
		var cb: Array = rowcols[i]
		for j in 6:
			var xa0: float = hl[i + 1] if cols[j] < 0.0 else hr[i + 1]
			var xa1: float = hl[i + 1] if cols[j + 1] < 0.0 else hr[i + 1]
			var xb0: float = hl[i] if cols[j] < 0.0 else hr[i]
			var xb1: float = hl[i] if cols[j + 1] < 0.0 else hr[i]
			var ca_x := cx + sh[i + 1]
			var cb_x := cx + sh[i]
			_add_quad(verts, colors, indices,
				Vector2(ca_x + cols[j] * absf(xa0), ys[i + 1]), Vector2(ca_x + cols[j + 1] * absf(xa1), ys[i + 1]),
				Vector2(cb_x + cols[j + 1] * absf(xb1), ys[i]), Vector2(cb_x + cols[j] * absf(xb0), ys[i]),
				ca[j], ca[j + 1], cb[j + 1], cb[j])
	# faint soft wheel ruts
	for side in [-1.0, 1.0]:
		for i in rows:
			var wa := _noise.get_noise_1d((zs[i + 1] + _travel) * 9.0 + side * 40.0) * 0.06
			var wb := _noise.get_noise_1d((zs[i] + _travel) * 9.0 + side * 40.0) * 0.06
			var ca: float = cx + sh[i + 1] + (side * 0.4 + wa) * hs[i + 1]
			var cb: float = cx + sh[i] + (side * 0.4 + wb) * hs[i]
			var ra := hs[i + 1] * 0.2
			var rb := hs[i] * 0.2
			var al := 0.3 * (1.0 - clampf(zs[i], 0.0, 1.0))
			var c1 := Color(_look.rut, al)
			var c0 := Color(_look.rut, 0.0)
			_add_quad(verts, colors, indices, Vector2(ca - ra, ys[i + 1]), Vector2(ca, ys[i + 1]),
				Vector2(cb, ys[i]), Vector2(cb - rb, ys[i]), c0, c1, c1, c0)
			_add_quad(verts, colors, indices, Vector2(ca, ys[i + 1]), Vector2(ca + ra, ys[i + 1]),
				Vector2(cb + rb, ys[i]), Vector2(cb, ys[i]), c1, c0, c0, c1)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, verts, colors)


## Appends a convex quad (corners in order) with per-corner colors to a triangle batch.
static func _add_quad(verts: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array,
		p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, c0: Color, c1: Color, c2: Color, c3: Color) -> void:
	var base := verts.size()
	verts.append(p0)
	verts.append(p1)
	verts.append(p2)
	verts.append(p3)
	colors.append(c0)
	colors.append(c1)
	colors.append(c2)
	colors.append(c3)
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base)
	indices.append(base + 2)
	indices.append(base + 3)


func _road_colors(fog_t: float, wz: float, cols: Array) -> Array[Color]:
	var mid := _look.road.lerp(_look.road_far, fog_t)
	var edge := _look.edge.lerp(_look.fog, fog_t)
	var out: Array[Color] = []
	for j in cols.size():
		var x: float = cols[j]
		var ax := absf(x)
		if ax >= 0.99:
			out.append(Color(edge, 0.0))
		elif ax > 0.85:
			out.append(edge.lerp(mid, 0.2))
		else:
			var m := _noise.get_noise_2d(x * 2.5 + 50.0, wz * 11.0) * 0.5 + _noise.get_noise_2d(x * 7.0, wz * 30.0) * 0.2
			var c := mid.lightened(m * 0.35) if m > 0.0 else mid.darkened(-m * 0.35)
			out.append(edge.lerp(c, 0.75) if ax > 0.45 else c)
	return out


## Same result as draw_colored_polygon, with the triangulation cached on the kind.
func _draw_cached(kind: SceneryKind, poly: PackedVector2Array, color: Color) -> void:
	var indices := kind.triangles(poly)
	if indices.is_empty():
		return
	var colors := PackedColorArray()
	colors.resize(poly.size())
	colors.fill(color)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, poly, colors)


func _decal_color(role: int) -> Color:
	match role:
		1: return _look.stone
		2: return _look.bone
		3: return _look.patch
	return _look.rut


func _draw_decals(_w: float, h: float, hy: float, cx: float, rh: float) -> void:
	var sorted := _decals.duplicate()
	sorted.sort_custom(func(a: Prop, b: Prop) -> bool: return a.z > b.z)
	for p: Prop in sorted:
		if absf(p.x) > 50.0:
			continue
		var z := maxf(p.z, Z_MIN)
		var s := _scale_at(z)
		var pos := Vector2(cx + _shift(z) + p.x * rh * s, hy + (h - hy) * s)
		var px := h * UNIT_FRAC * p.kind.size * p.mul * s * 1.7
		var t := clampf(z, 0.0, 1.0)
		var fade := 1.0 - clampf((t - FADE_START) / (1.0 - FADE_START), 0.0, 1.0)
		var col := Color(_decal_color(p.kind.role).lerp(_look.fog, pow(t, 0.7) * 0.85), fade)
		draw_set_transform(pos, 0.0, Vector2(px * p.flip, px * 0.6))
		for poly in p.kind.body:
			_draw_cached(p.kind, poly, col)
		for poly in p.kind.cut:
			_draw_cached(p.kind, poly, Color(_look.rut, fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_mist(hy: float, h: float) -> void:
	var k := h / 1920.0
	var bands := [[-0.04, 120.0, 0.3], [0.02, 150.0, 0.26], [0.07, 190.0, 0.2], [0.14, 240.0, 0.12]]
	for b in bands:
		var y: float = hy + (h - hy) * b[0]
		var th: float = b[1] * k
		var c := Color(_look.fog.lightened(0.08), b[2])
		var c0 := Color(c, 0.0)
		draw_polygon(PackedVector2Array([Vector2(0, y - th), Vector2(size.x, y - th), Vector2(size.x, y),
			Vector2(0, y)]), PackedColorArray([c0, c0, c, c]))
		draw_polygon(PackedVector2Array([Vector2(0, y), Vector2(size.x, y), Vector2(size.x, y + th),
			Vector2(0, y + th)]), PackedColorArray([c, c, c0, c0]))


func _draw_props(w: float, h: float, hy: float, cx: float) -> void:
	var rh := w * ROAD_HALF
	var sorted := _props.duplicate()
	sorted.sort_custom(func(a: Prop, b: Prop) -> bool: return a.z > b.z)
	var misted := false
	var lms: Array[int] = []
	if _fork:
		lms.assign(_fork.landmark_order())
	var li := 0
	for p: Prop in sorted:
		while li < lms.size() and _fork.landmark_z(lms[li]) >= p.z:
			_fork.draw_landmark(self, lms[li])
			li += 1
		if not misted and p.z < 0.3:
			misted = true
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			_draw_mist(hy, h)
		var z := maxf(p.z, Z_MIN)
		var s := _scale_at(z)
		var pos := Vector2(cx + _shift(z) + p.x * rh * s, hy + (h - hy) * s)
		var px := h * UNIT_FRAC * p.kind.size * p.mul * s
		if pos.x + px < 0.0 or pos.x - px > w:
			continue
		var t := clampf(z, 0.0, 1.0)
		var fade := 1.0 - clampf((t - FADE_START) / (1.0 - FADE_START), 0.0, 1.0)
		var col := Color(_look.silhouette.lerp(_look.fog, pow(t, 0.7) * 0.9), fade)
		draw_set_transform(pos, 0.0, Vector2(px * p.flip, px))
		for poly in p.kind.body:
			_draw_cached(p.kind, poly, col)
		var gcol := Color(_look.accent, 0.85 * (1.0 - t) * fade)
		for poly in p.kind.glow:
			_draw_cached(p.kind, poly, gcol)
	while li < lms.size():
		_fork.draw_landmark(self, lms[li])
		li += 1
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _fork:
		_fork.draw_labels(self)

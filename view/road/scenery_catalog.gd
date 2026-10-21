## Props and per-realm look of the road. `kinds_for(realm)` is a weighted pick list (repeats = weight).
class_name SceneryCatalog
extends RefCounted

const REALMS := 4


class Pine extends SceneryKind:
	func _init() -> void:
		size = 1.3
		body = [sym([Vector2(0, -1), Vector2(0.09, -0.72), Vector2(0.05, -0.72), Vector2(0.13, -0.48),
			Vector2(0.07, -0.48), Vector2(0.19, -0.2), Vector2(0.03, -0.2), Vector2(0.03, 0)])]


class RoundTree extends SceneryKind:
	func _init() -> void:
		size = 1.0
		body = [sym([Vector2(0.04, -0.5), Vector2(0.06, 0)]), blob(Vector2(0, -0.72), 0.3, 3.0, 0.7)]


class DeadTree extends SceneryKind:
	func _init() -> void:
		size = 1.1
		body = [sym([Vector2(0, -0.85), Vector2(0.03, -0.6), Vector2(0.06, 0)]),
			poly([0.02, -0.5, 0.3, -0.78, 0.05, -0.38]), poly([-0.02, -0.62, -0.26, -0.9, -0.04, -0.44]),
			poly([0.02, -0.74, 0.12, -0.98, 0.04, -0.62])]


class Tower extends SceneryKind:
	func _init() -> void:
		size = 1.9
		body = [poly([-0.1, 0, -0.1, -0.8, -0.06, -0.85, -0.03, -0.8, 0.0, -0.95, 0.04, -0.88, 0.07, -1.0,
			0.1, -0.9, 0.1, 0])]
		glow = [poly([-0.02, -0.6, 0.02, -0.6, 0.02, -0.52, -0.02, -0.52])]


class Ruin extends SceneryKind:
	func _init() -> void:
		size = 1.0
		body = [poly([-0.3, 0, -0.3, -0.4, -0.22, -0.5, -0.18, -0.38, -0.1, -0.55, -0.02, -0.45, 0.05, -0.7,
			0.12, -0.5, 0.2, -0.58, 0.3, -0.3, 0.3, 0])]
		glow = [poly([-0.2, -0.22, -0.15, -0.22, -0.15, -0.12, -0.2, -0.12])]


class Gravestone extends SceneryKind:
	func _init() -> void:
		size = 0.26
		body = [poly([-0.08, 0, -0.08, -0.7, -0.06, -0.9, 0, -1, 0.06, -0.9, 0.08, -0.7, 0.08, 0])]


class Cross extends SceneryKind:
	func _init() -> void:
		size = 0.4
		body = [poly([-0.025, 0, -0.025, -0.65, -0.1, -0.65, -0.1, -0.78, -0.025, -0.78, -0.025, -1,
			0.025, -1, 0.025, -0.78, 0.1, -0.78, 0.1, -0.65, 0.025, -0.65, 0.025, 0])]


class Spire extends SceneryKind:
	func _init() -> void:
		size = 1.5
		body = [poly([-0.15, 0, -0.08, -0.5, -0.03, -0.7, 0, -1, 0.04, -0.6, 0.1, -0.75, 0.12, -0.3, 0.2, 0])]
		glow = [poly([0, -0.9, 0.02, -0.5, 0, -0.2, -0.02, -0.5])]


class Stone extends SceneryKind:
	func _init() -> void:
		size = 0.05
		role = 1
		body = [blob(Vector2(0, -0.35), 0.5, 2.0, randf() * 6.0)]


class Skull extends SceneryKind:
	func _init() -> void:
		size = 0.075
		role = 2
		body = [blob(Vector2(0, -0.6), 0.5, 2.0, 1.0), poly([-0.28, -0.25, 0.28, -0.25, 0.2, 0, -0.2, 0])]
		cut = [blob(Vector2(-0.2, -0.62), 0.12, 1.0, 0.0), blob(Vector2(0.2, -0.62), 0.12, 1.0, 0.0)]


class Bone extends SceneryKind:
	func _init() -> void:
		size = 0.11
		role = 2
		body = [poly([-0.5, -0.2, 0.45, -0.04, 0.5, -0.12, -0.45, -0.28]), blob(Vector2(-0.52, -0.3), 0.1, 1.0, 0.0),
			blob(Vector2(-0.5, -0.12), 0.1, 1.0, 0.0), blob(Vector2(0.52, -0.2), 0.1, 1.0, 0.0),
			blob(Vector2(0.48, -0.02), 0.1, 1.0, 0.0)]


class Root extends SceneryKind:
	func _init() -> void:
		size = 0.2
		body = [poly([-0.9, -0.1, -0.4, -0.25, 0.1, -0.12, 0.7, -0.3, 0.95, -0.22, 0.7, -0.18, 0.1, -0.04,
			-0.4, -0.14, -0.9, 0])]


class Tuft extends SceneryKind:
	func _init() -> void:
		size = 0.09
		role = 3
		body = [poly([-0.5, 0, -0.4, -0.5, -0.3, -0.1, -0.2, -0.7, -0.1, -0.15, 0, -0.55, 0.1, -0.1, 0.25, -0.8,
			0.3, -0.1, 0.45, -0.4, 0.5, 0])]


class AshPatch extends SceneryKind:
	func _init() -> void:
		size = 0.2
		role = 3
		body = [blob(Vector2(0, -0.2), 0.5, 3.0, randf() * 6.0)]


## Colors and scenery of one realm.
class Look extends RefCounted:
	var sky_top: Color
	var sky_low: Color
	var ground: Color
	var ground_alt: Color
	var road: Color
	var road_far: Color
	var edge: Color
	var line: Color
	var fog: Color
	var silhouette: Color
	var accent: Color
	var mountains: Array[Color] = []
	var peaks := 7
	var peak_height := 0.08
	var moon := Color(0.6, 0.66, 0.78, 0.5)
	var rut: Color
	var stone: Color
	var bone: Color
	var patch: Color
	var ragged := 0.12 ## trail edge wobble, fraction of half-width

	## Look blended `t` of the way from this one to `other` (colours, peaks, wobble); mountain layers pair by index.
	func lerp_to(other: Look, t: float) -> Look:
		var l := Look.new()
		for prop in ["sky_top", "sky_low", "ground", "ground_alt", "road", "road_far", "edge", "line", "fog",
				"silhouette", "accent", "moon", "rut", "stone", "bone", "patch"]:
			l.set(prop, (get(prop) as Color).lerp(other.get(prop), t))
		for i in other.mountains.size():
			var from: Color = mountains[mini(i, mountains.size() - 1)] if not mountains.is_empty() else other.mountains[i]
			l.mountains.append(from.lerp(other.mountains[i], t))
		l.peaks = other.peaks if t >= 0.5 else peaks
		l.peak_height = lerpf(peak_height, other.peak_height, t)
		l.ragged = lerpf(ragged, other.ragged, t)
		return l


static func look(realm: int) -> Look:
	var l := Look.new()
	match posmod(realm, REALMS):
		0: # hollow forest road: cold blue-gray
			l.sky_top = Color("#080b12"); l.sky_low = Color("#222e40"); l.ground = Color("#0d1117")
			l.ground_alt = Color("#10151c"); l.road = Color("#1a212b"); l.road_far = Color("#2a3646")
			l.edge = Color("#4a586c"); l.line = Color("#7686a0"); l.fog = Color("#222e40")
			l.silhouette = Color("#0a0c10"); l.accent = Color("#8fe04a")
			l.mountains = [Color("#161d28"), Color("#101620")]; l.peaks = 6; l.peak_height = 0.07
		1: # graveyard: violet haze
			l.sky_top = Color("#0b0912"); l.sky_low = Color("#33284a"); l.ground = Color("#100d16")
			l.ground_alt = Color("#140f1b"); l.road = Color("#1f1a29"); l.road_far = Color("#3a2f4d")
			l.edge = Color("#5a4c72"); l.line = Color("#8a7aa8"); l.fog = Color("#33284a")
			l.silhouette = Color("#0a080e"); l.accent = Color("#b57bff")
			l.mountains = [Color("#1f1830"), Color("#16111f")]; l.peaks = 4; l.peak_height = 0.045
			l.moon = Color(0.74, 0.66, 0.9, 0.55)
		2: # ruined city: ash and rust
			l.sky_top = Color("#0f0a0a"); l.sky_low = Color("#4a2a22"); l.ground = Color("#130d0c")
			l.ground_alt = Color("#171010"); l.road = Color("#241a18"); l.road_far = Color("#4a3430")
			l.edge = Color("#6d4a40"); l.line = Color("#a07a68"); l.fog = Color("#4a2a22")
			l.silhouette = Color("#0c0808"); l.accent = Color("#ff9a1f")
			l.mountains = [Color("#2a1a17"), Color("#1c1210")]; l.peaks = 12; l.peak_height = 0.05
			l.moon = Color(0.9, 0.55, 0.35, 0.4)
		_: # ember void: black with a red glow
			l.sky_top = Color("#050405"); l.sky_low = Color("#3a0f0f"); l.ground = Color("#0a0606")
			l.ground_alt = Color("#0e0808"); l.road = Color("#190d0d"); l.road_far = Color("#3a1616")
			l.edge = Color("#6a2a24"); l.line = Color("#ff4a3d"); l.fog = Color("#3a0f0f")
			l.silhouette = Color("#060404"); l.accent = Color("#ff4a3d")
			l.mountains = [Color("#240b0b"), Color("#150707")]; l.peaks = 9; l.peak_height = 0.11
			l.moon = Color(1.0, 0.3, 0.2, 0.45)

	match posmod(realm, REALMS): # dirt trail tones: mud, bone-ash, blood-rust, black-stone
		0:
			l.road = Color("#3b3024"); l.road_far = Color("#3a3a3a"); l.edge = Color("#0c0a07")
			l.rut = Color("#150f09"); l.stone = Color("#5a5348"); l.bone = Color("#b8b09a"); l.patch = Color("#2c4a22")
			l.ragged = 0.14
		1:
			l.road = Color("#4c4854"); l.road_far = Color("#4a4256"); l.edge = Color("#0e0b13")
			l.rut = Color("#201c28"); l.stone = Color("#6a6678"); l.bone = Color("#d6d0bc"); l.patch = Color("#3a3640")
			l.ragged = 0.1
		2:
			l.road = Color("#4d2c24"); l.road_far = Color("#4a2a22"); l.edge = Color("#120807")
			l.rut = Color("#220e0b"); l.stone = Color("#6a4438"); l.bone = Color("#cbb89c"); l.patch = Color("#3a3029")
			l.ragged = 0.17
		_:
			l.road = Color("#1f1a1c"); l.road_far = Color("#3a1616"); l.edge = Color("#030202")
			l.rut = Color("#0a0607"); l.stone = Color("#352b2e"); l.bone = Color("#8c6a60"); l.patch = Color("#1a1213")
			l.ragged = 0.2
	return l


static func kinds_for(realm: int) -> Array[SceneryKind]:
	var out: Array[SceneryKind] = []
	match posmod(realm, REALMS):
		0:
			out = [Pine.new(), Pine.new(), Pine.new(), RoundTree.new(), RoundTree.new(), DeadTree.new(),
				Ruin.new(), Gravestone.new()]
		1:
			out = [Gravestone.new(), Gravestone.new(), Gravestone.new(), Cross.new(), Cross.new(),
				DeadTree.new(), DeadTree.new(), Ruin.new(), Tower.new()]
		2:
			out = [Ruin.new(), Ruin.new(), Ruin.new(), Tower.new(), Tower.new(), Spire.new(), DeadTree.new(),
				Gravestone.new()]
		_:
			out = [Spire.new(), Spire.new(), Spire.new(), DeadTree.new(), DeadTree.new(), Tower.new(), Cross.new()]
	return out


## Flat things lying on the trail.
static func decals_for(realm: int) -> Array[SceneryKind]:
	var out: Array[SceneryKind] = []
	match posmod(realm, REALMS):
		0:
			out = [Stone.new(), Stone.new(), Stone.new(), Tuft.new(), Tuft.new(), Root.new(), Bone.new(), Skull.new()]
		1:
			out = [Stone.new(), Stone.new(), Bone.new(), Bone.new(), Skull.new(), Skull.new(), AshPatch.new(), Root.new()]
		2:
			out = [Stone.new(), Stone.new(), Bone.new(), Skull.new(), AshPatch.new(), AshPatch.new(), Root.new()]
		_:
			out = [Stone.new(), Stone.new(), Stone.new(), Stone.new(), Stone.new(), AshPatch.new(), Skull.new(),
				Bone.new()]
	return out

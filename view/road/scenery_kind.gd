## One kind of roadside prop: unit-height polygons (origin = base center, y up is negative, height 1).
class_name SceneryKind
extends RefCounted

## Height at the camera plane as a fraction of `RoadScene.UNIT_FRAC` of the viewport height.
var size := 1.0
var body: Array[PackedVector2Array] = []
var glow: Array[PackedVector2Array] = []
## Darker holes drawn over the body (eye sockets).
var cut: Array[PackedVector2Array] = []
## Road decals only: 0 = silhouette, 1 = stone, 2 = bone, 3 = grass / ash patch.
var role := 0


## Builds a closed polygon from the right half (top to bottom, x >= 0) by mirroring it.
static func sym(right: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in right:
		out.append(p)
	for i in range(right.size() - 1, -1, -1):
		var p: Vector2 = right[i]
		if p.x > 0.0:
			out.append(Vector2(-p.x, p.y))
	return out


static func poly(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


static func blob(center: Vector2, radius: float, bumps: float, phase: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 12:
		var a := TAU * float(i) / 12.0
		var r := radius * (1.0 + 0.16 * sin(a * bumps + phase))
		out.append(center + Vector2(cos(a) * r, sin(a) * r * 0.85))
	return out

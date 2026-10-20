## Weighted index choice over a stream; the single place that turns weights into a pick.
class_name WeightedPick
extends RefCounted

## Returns -1 when the list is empty or all weights are not positive.
static func index(rng: RandomNumberGenerator, weights: Array[float]) -> int:
	var total := 0.0
	for weight in weights:
		total += maxf(weight, 0.0)
	if total <= 0.0:
		return -1
	var roll := rng.randf() * total
	for i in weights.size():
		roll -= maxf(weights[i], 0.0)
		if roll < 0.0:
			return i
	return weights.size() - 1

## Stateless random streams: every stream is derived from the run seed, a purpose and up to three
## coordinates, so the same seed yields the same content whatever order the player picks things in.
class_name RunRng
extends RefCounted

const MAP := &"map"
const OMEN := &"omen"
const REWARD := &"reward"
const COMBAT := &"combat"

const _MIX_A := 0x2545F4914F6CDD1D
const _MIX_B := 0x1CE4E5B9BF58476D
const _SHIFT := 29
const _SHIFT_MASK := 0x7FFFFFFFF
const _SEED_MASK := 0x7FFFFFFFFFFFFFFF

static func seed_for(run_seed: int, purpose: StringName, a := 0, b := 0, c := 0) -> int:
	var x := _mix(run_seed + 1)
	x = _mix(x ^ String(purpose).hash())
	x = _mix(x ^ (a + 1))
	x = _mix(x ^ (b + 1))
	x = _mix(x ^ (c + 1))
	return x & _SEED_MASK

static func stream(run_seed: int, purpose: StringName, a := 0, b := 0, c := 0) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_for(run_seed, purpose, a, b, c)
	return rng

static func _mix(value: int) -> int:
	var x := value * _MIX_A
	x = (x ^ ((x >> _SHIFT) & _SHIFT_MASK)) * _MIX_B
	return x ^ ((x >> _SHIFT) & _SHIFT_MASK)

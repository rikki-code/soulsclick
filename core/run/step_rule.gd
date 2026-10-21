## Door table of one realm step: which room kinds may appear, which must, how many doors.
class_name StepRule
extends Resource

## Room kind id -> weight.
@export var kind_weights: Dictionary = {}
## Kinds that always get a door at this step (the realm guarantees: elite, recovery, relic source, boss).
@export var required_kinds: Array[StringName] = []
## Door count -> weight.
@export var door_count_weights: Dictionary = {2: 1.0}
## Extra enemies added to the wave of a combat room at this step (road stretches).
@export var wave_bonus := 0

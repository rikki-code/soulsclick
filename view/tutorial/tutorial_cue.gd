## Where and how the tutorial points at an input control: the arrow's tip `anchor` (screen coordinates), the direction
## the arrow points (`dir`), and whether it slides along `dir` over and over (a swipe) instead of bobbing in place.
class_name TutorialCue
extends RefCounted

var anchor := Vector2.ZERO
var dir := Vector2.DOWN
var travel := false

static func of(p_anchor: Vector2, p_dir: Vector2, p_travel := false) -> TutorialCue:
	var cue := TutorialCue.new()
	cue.anchor = p_anchor
	cue.dir = p_dir
	cue.travel = p_travel
	return cue

## Waiting helpers for lessons. Await them: `await TutorialWait.count(duel.player_attacked, 3)`.
class_name TutorialWait
extends RefCounted

signal reached

var _left: int
var _accept: Callable

## Coroutine. Returns after `sig` was emitted `times` times. `accept` (optional) receives the signal's arguments and
## returns false to ignore an emission, e.g. `func(result: StrikeResult) -> bool: return result.outcome == StrikeResult.BLOCKED`.
static func count(sig: Signal, times: int, accept := Callable()) -> void:
	var waiter := TutorialWait.new()
	waiter._left = times
	waiter._accept = accept
	sig.connect(waiter._on_emit)
	await waiter.reached
	sig.disconnect(waiter._on_emit)

## Coroutine. Returns the next time `sig` is emitted with `accept` returning true (no filter: the next emission).
static func once(sig: Signal, accept := Callable()) -> void:
	await count(sig, 1, accept)

func _on_emit(...args: Array) -> void:
	if _accept.is_valid() and not _accept.callv(args):
		return
	_left -= 1
	if _left <= 0:
		reached.emit()

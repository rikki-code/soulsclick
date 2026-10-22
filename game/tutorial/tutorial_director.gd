## Plays the tutorial lessons in order. Lessons are coroutines on a TutorialHost; the director only sequences them and
## says when the whole tutorial is done. Skipping is handled by GameRoot (it ends the tutorial; parked lessons never resume).
class_name TutorialDirector
extends RefCounted

signal finished

const LESSON_GAP := 0.6

## The lessons in teaching order. A new lesson = one file in game/tutorial/lessons/ plus one line here.
func lessons() -> Array[TutorialLesson]:
	return [
		Lesson02Stamina.new(),
		Lesson03Slime.new(),
		Lesson05Knight.new(),
		Lesson06Finale.new(),
	]

## Coroutine: runs every lesson, then emits `finished`.
func run(host: TutorialHost) -> void:
	for lesson in lessons():
		await lesson.play(host)
		await host.pause(LESSON_GAP)
	finished.emit()

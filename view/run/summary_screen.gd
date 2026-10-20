## End of a run: outcome, progress, Souls, Embers (counted up), killer and seed; Again, Menu and the "save half" ad on death.
class_name SummaryScreen
extends RunScreen

signal again_pressed
signal menu_pressed
signal save_half_pressed

const COUNT_SECONDS := 1.2

var _embers_label: Label
var _save_button: Button
var _shown_embers := 0

func setup(summary: RunSummary, can_save_half: bool) -> SummaryScreen:
	_build(tr("SUMMARY_VICTORY") if summary.victory else (tr("SUMMARY_ABANDON") if summary.outcome_id == &"abandon" else tr("SUMMARY_DEATH")))
	_text(tr("SUMMARY_PROGRESS") % [summary.realm_reached, summary.realm_count, summary.rooms_cleared])
	_text(tr("SUMMARY_SOULS") % summary.souls, 40, Color(0.95, 0.85, 0.5))
	_embers_label = _text("", 48, Color(1.0, 0.6, 0.3))
	if summary.killer_enemy_id != &"":
		_text(tr("SUMMARY_KILLER") % tr("ENEMY_" + String(summary.killer_enemy_id).to_upper()), 30, MUTED)
	_text(tr("SUMMARY_SEED") % summary.seed_code, 30, MUTED)
	if can_save_half:
		_save_button = _button(tr("SUMMARY_SAVE_HALF"), save_half_pressed.emit, 120.0)
	_button(tr("SUMMARY_AGAIN"), again_pressed.emit, 120.0)
	_button(tr("MENU_BACK"), menu_pressed.emit)
	count_to(summary.embers)
	return self

func hide_save_half() -> void:
	if _save_button != null:
		_save_button.visible = false

## Counts the Embers line up (or further up after the ad) to `target`.
func count_to(target: int) -> void:
	var tween := create_tween()
	tween.tween_method(_show_embers, _shown_embers, target, COUNT_SECONDS if target > _shown_embers else 0.0)

func _show_embers(value: float) -> void:
	_shown_embers = roundi(value)
	_embers_label.text = tr("SUMMARY_EMBERS") % _shown_embers

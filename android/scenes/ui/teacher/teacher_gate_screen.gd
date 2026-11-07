class_name TeacherGateScreen
extends Control
## Entrada al modo docente con el PIN (RF-03). Tras 5 fallos se bloquea 5 minutos.

signal unlocked
signal back_requested

var _presenter: TeacherGatePresenter
var _quipu := QuipuPin.new()
var _pad := PinPad.new()
var _feedback_title: Label
var _feedback_text: Label
var _lock_left := 0.0
var _last_second := -1


func setup(presenter: TeacherGatePresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := SierraBackdrop.new()
	backdrop.veil = 0.35
	add_child(backdrop)
	var view_model := _presenter.screen()
	var back := Ui.button(view_model.back_label, "back", &"SoftButton")
	back.size = back.get_combined_minimum_size()
	back.position = Vector2(24, 22)
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)

	var card := PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var info := Ui.vbox(12)
	info.custom_minimum_size.x = 380
	info.add_child(_lock_badge())
	info.add_child(Ui.label(view_model.title, &"TitleLabel"))
	var prompt := Ui.label(view_model.prompt, &"HeadingLabel")
	prompt.add_theme_font_size_override("font_size", 26)
	info.add_child(prompt)
	_quipu.slots = view_model.pin_max_length
	info.add_child(_quipu)
	_feedback_title = Ui.label("", &"ErrorLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 380)
	_feedback_text = Ui.label(view_model.hint, &"HintLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 380)
	info.add_child(_feedback_title)
	info.add_child(_feedback_text)
	_pad.auto_submit = false
	_pad.min_length = view_model.pin_min_length
	_pad.max_length = view_model.pin_max_length
	_pad.changed.connect(_quipu.set_filled)
	_pad.submitted.connect(_on_submitted)
	card.add_child(Ui.hbox(40, [info, _pad]))
	add_child(card)
	Ui.pop_in(card, 0.05)


func _process(delta: float) -> void:
	if _lock_left <= 0.0:
		return
	_lock_left -= delta
	var second := ceili(_lock_left)
	if second != _last_second:
		_last_second = second
		_feedback_text.text = _presenter.locked_message(second)
	if _lock_left <= 0.0:
		_feedback_title.text = ""
		_feedback_text.text = ""
		_pad.set_enabled(true)


## Para el modo demostración.
func type_pin(pin: String) -> void:
	for digit in pin:
		_pad._press(digit)
	_pad._submit()


func _lock_badge() -> Control:
	var badge := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1F7A70")
	style.set_corner_radius_all(34)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	badge.add_theme_stylebox_override("panel", style)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var lock := TextureRect.new()
	lock.texture = Ui.icon("lock")
	lock.custom_minimum_size = Vector2(40, 40)
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.add_child(lock)
	return badge


func _on_submitted(pin: String) -> void:
	var feedback := _presenter.unlock(pin)
	if feedback.ok:
		_pad.set_enabled(false)
		_quipu.shine()
		var later := create_tween()
		later.tween_interval(0.7)
		later.tween_callback(func() -> void: unlocked.emit())
		return
	_quipu.shake_and_drop()
	_pad.clear()
	_feedback_title.text = feedback.title
	_feedback_text.text = feedback.message
	if feedback.locked:
		_pad.set_enabled(false)
		_lock_left = feedback.locked_seconds
		_last_second = -1

class_name SetupScreen
extends Control
## Asistente de configuración inicial (RF-01 y CU-01): el docente registra su institución,
## sus secciones y su acceso, paso a paso. Un quipu muestra el avance: un nudo por paso.

signal finished
signal cancelled

const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")
const STEPS := 4

var _presenter: SetupPresenter
var _view_model: SetupViewModel
## -1 es la bienvenida; 0, 1 y 2 son formularios; 3 es «¡Todo listo!».
var _step := -1
var _data := {}
var _sections: Array[String] = []
var _inputs := {}
var _errors := {}
var _card: PanelContainer
var _body: VBoxContainer
var _progress := QuipuPin.new()
var _progress_label: Label
var _back: Button
var _next: Button
var _quwi: QuwiCharacter
var _section_chips: HFlowContainer
var _grade_group: ButtonGroup
var _busy := false


func setup(presenter: SetupPresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := SierraBackdrop.new()
	backdrop.veil = 0.18
	add_child(backdrop)
	_view_model = _presenter.screen()
	_data = {"grade": _view_model.default_grade, "school_year": _view_model.default_school_year}
	_quwi = QUWI.instantiate()
	_quwi.scale = Vector2(0.95, 0.95)
	add_child(_quwi)

	var top := Ui.vbox(4)
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.offset_top = 6
	_progress.slots = STEPS
	_progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_progress_label = Ui.label("", &"SubtitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_progress_label.add_theme_font_size_override("font_size", 24)
	top.add_child(_progress)
	top.add_child(_progress_label)
	add_child(top)

	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	_card.custom_minimum_size = Vector2(760, 0)
	_body = Ui.vbox(16)
	_back = Ui.compact(Ui.button(_view_model.back_label, "back", &"SoftButton"), 24)
	_back.pressed.connect(_on_back)
	_next = Ui.compact(Ui.button(_view_model.next_label, "check"), 24)
	_next.pressed.connect(_on_next)
	var footer := Ui.hbox(16, [_back, Ui.spacer(), _next])
	_card.add_child(Ui.vbox(22, [_body, footer]))
	add_child(_card)
	var avoider := KeyboardAvoider.new()
	avoider.target = _card
	avoider.top_margin = 168.0
	add_child(avoider)
	resized.connect(_place_quwi)
	_show_step(-1)


## Para el modo demostración: llena el paso actual y avanza.
func fill_and_next(values: Dictionary) -> void:
	for field: String in values:
		if field == "sections":
			_sections.assign(values[field])
			_refresh_section_chips()
		elif _inputs.has(field):
			(_inputs[field] as LineEdit).text = str(values[field])
	_on_next()


func _place_quwi() -> void:
	var view := size
	_quwi.position = Vector2(view.x * 0.5 - 510, view.y - 30) if _step < 0 or _step == 3 else Vector2(-200, view.y + 200)


# --- Pasos ---

func _show_step(step: int) -> void:
	_step = step
	_inputs.clear()
	_errors.clear()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	match step:
		-1:
			_build_welcome()
		0:
			_build_institution()
		1:
			_build_sections()
		2:
			_build_access()
		3:
			_build_done()
	_back.visible = step != 3
	_back.text = _view_model.back_label
	_next.visible = step != 3
	_next.text = _view_model.start_label if step == -1 else (_view_model.finish_label if step == 2 else _view_model.next_label)
	_progress.set_filled(step + 1 if step >= 0 else 0)
	_progress_label.text = "" if step < 0 else "Paso %d de %d · %s" % [step + 1, STEPS, _view_model.step_titles[step]]
	if step == 3:
		_progress.shine()
	_place_quwi()
	if step == -1 or step == 3:
		_quwi.enter_from(-260.0, 2)
		var later := create_tween()
		later.tween_interval(0.9)
		later.tween_callback(_quwi.wave if step == -1 else _quwi.celebrate)
	Ui.pop_in(_card)


func _heading(title: String, hint: String) -> void:
	_body.add_child(Ui.label(title, &"TitleLabel"))
	if not hint.is_empty():
		_body.add_child(Ui.label(hint, &"HintLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 680))


func _build_welcome() -> void:
	_heading(_view_model.welcome_title, "")
	var text := Ui.label(_view_model.welcome_text, &"ReadingLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 680)
	_body.add_child(text)


func _field(field: String, numeric: bool = false, secret: bool = false) -> VBoxContainer:
	var input := Ui.field(_view_model.placeholders.get(field, ""), numeric, secret, _view_model.max_lengths.get(field, 0))
	input.text = str(_data.get(field, ""))
	input.text_submitted.connect(func(_text: String) -> void: _focus_next(field))
	_inputs[field] = input
	var error := Ui.label("", &"ErrorLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 300)
	_errors[field] = error
	return Ui.field_block(_view_model.labels.get(field, field), input, error)


func _build_institution() -> void:
	_heading(_view_model.step_titles[0], _view_model.step_hints[0])
	_body.add_child(_field("institution_name"))
	var code := _field("modular_code", true)
	var year := _field("school_year", true)
	code.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	year.custom_minimum_size.x = 220
	_body.add_child(Ui.hbox(20, [code, year]))
	_grade_group = ButtonGroup.new()
	var grades := Ui.hbox(10)
	for grade in _view_model.grades:
		var chip := Ui.chip("%d.°" % grade, _grade_group)
		chip.custom_minimum_size.x = 84
		chip.set_pressed_no_signal(grade == int(_data.get("grade", 6)))
		chip.toggled.connect(func(on: bool) -> void:
			if on:
				_data["grade"] = grade)
		grades.add_child(chip)
	var grade_error := Ui.label("", &"ErrorLabel")
	_errors["grade"] = grade_error
	_body.add_child(Ui.field_block(_view_model.labels["grade"], grades, grade_error))


func _build_sections() -> void:
	_heading(_view_model.step_titles[1], _view_model.step_hints[1])
	_section_chips = HFlowContainer.new()
	_section_chips.add_theme_constant_override("h_separation", 12)
	_section_chips.add_theme_constant_override("v_separation", 12)
	var error := Ui.label("", &"ErrorLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 680)
	_errors["sections"] = error
	_body.add_child(Ui.field_block(_view_model.labels["sections"], _section_chips, error))
	var suggestions := Ui.hbox(10)
	for suggestion in _view_model.suggested_sections:
		var quick := Ui.button("+ %s" % suggestion, "", &"SoftButton")
		quick.custom_minimum_size = Vector2(88, 60)
		quick.pressed.connect(_add_section.bind(suggestion))
		suggestions.add_child(quick)
	_body.add_child(suggestions)
	var input := Ui.field(_view_model.placeholders["section_new"], false, false, _view_model.max_lengths.get("section_new", 0))
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.text_submitted.connect(func(text: String) -> void:
		_add_section(text)
		input.clear())
	input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var add := Ui.compact(Ui.button("Agregar", "plus", &"SoftButton"), 24)
	add.pressed.connect(func() -> void:
		_add_section(input.text)
		input.clear())
	_body.add_child(Ui.vbox(6, [Ui.label(_view_model.labels["section_new"], &"FieldLabel"), Ui.hbox(12, [input, add])]))
	_refresh_section_chips()


func _add_section(raw_name: String) -> void:
	var clean := raw_name.strip_edges()
	if clean.is_empty():
		return
	clean = clean[0].to_upper() + clean.substr(1)
	for existing in _sections:
		if existing.to_lower() == clean.to_lower():
			return
	_sections.append(clean)
	_refresh_section_chips()


func _refresh_section_chips() -> void:
	if _section_chips == null:
		return
	for child in _section_chips.get_children():
		child.queue_free()
	for section_name in _sections:
		var chip := Ui.button("%s  ✕" % section_name, "", &"ChipButton")
		chip.toggle_mode = true
		chip.set_pressed_no_signal(true)
		chip.custom_minimum_size.y = 60
		chip.tooltip_text = "Quitar"
		chip.pressed.connect(func() -> void:
			_sections.erase(section_name)
			_refresh_section_chips())
		_section_chips.add_child(chip)
	if _sections.is_empty():
		_section_chips.add_child(Ui.label("Todavía no hay secciones.", &"HintLabel"))


func _build_access() -> void:
	_heading(_view_model.step_titles[2], _view_model.step_hints[2])
	_body.add_child(_field("teacher_name"))
	var pin := _field("teacher_pin", true, true)
	var again := _field("teacher_pin_confirmation", true, true)
	pin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(Ui.hbox(20, [pin, again]))
	_body.add_child(_field("teacher_code"))


func _build_done() -> void:
	_heading(_view_model.done_title, "")
	_body.add_child(Ui.label(_view_model.done_text, &"ReadingLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 680))
	var summary := Ui.vbox(4)
	summary.add_child(Ui.label("• %s" % _data.get("institution_name", ""), &"HeadingLabel"))
	summary.add_child(Ui.label("• %d.° grado · %s" % [int(_data.get("grade", 6)), ", ".join(_sections)], &"HintLabel"))
	_body.add_child(summary)
	var go := Ui.compact(Ui.button(_view_model.done_button, "students"), 26)
	go.size_flags_horizontal = Control.SIZE_SHRINK_END
	go.pressed.connect(func() -> void: finished.emit())
	_body.add_child(go)


# --- Navegación ---

func _collect() -> void:
	for field: String in _inputs:
		_data[field] = (_inputs[field] as LineEdit).text
	_data["sections"] = _sections.duplicate()


func _show_errors(messages: Dictionary) -> void:
	for field: String in _errors:
		var input := _inputs.get(field) as LineEdit
		Ui.show_error(input, _errors[field], messages.get(field, ""))
	for field: String in messages:
		if _inputs.has(field):
			(_inputs[field] as LineEdit).grab_focus()
			break


func _on_next() -> void:
	if _busy:
		return
	if _step == -1:
		_show_step(0)
		return
	_collect()
	var messages := _presenter.validate_step(_step, _data)
	_show_errors(messages)
	if not messages.is_empty():
		_shake_card()
		return
	if _step < 2:
		_show_step(_step + 1)
		return
	var feedback := _presenter.submit(_data)
	if feedback.ok:
		_show_step(3)
		return
	var step := _presenter.first_step_with_errors(feedback.errors)
	_show_step(step)
	_show_errors(feedback.errors)


func _on_back() -> void:
	if _step <= -1:
		cancelled.emit()
		return
	_collect()
	_show_step(_step - 1)


func _focus_next(field: String) -> void:
	var fields := _inputs.keys()
	var index := fields.find(field)
	if index >= 0 and index + 1 < fields.size():
		(_inputs[fields[index + 1]] as LineEdit).grab_focus()
	else:
		get_viewport().gui_release_focus()


func _shake_card() -> void:
	var start := _card.position.x
	var tween := create_tween()
	for offset in [14.0, -12.0, 8.0, -5.0, 0.0]:
		tween.tween_property(_card, "position:x", start + offset, 0.05)

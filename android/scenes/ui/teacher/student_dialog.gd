class_name StudentDialog
extends Control
## Diálogo del modo docente para registrar a un estudiante o gestionar uno existente:
## corregir sus datos, darle un PIN nuevo (RF-17) o desactivarlo sin perder sus resultados (RN-07).

## Algo se guardó: el panel recarga la lista y muestra el aviso.
signal saved(notice: String)
signal closed

var _presenter: TeacherPanelPresenter
var _sections: Array[SectionTabViewModel] = []
var _row: StudentRowViewModel
var _card: PanelContainer
var _name: LineEdit
var _name_error: Label
var _section_group := ButtonGroup.new()
var _section_error: Label
var _pin: LineEdit
var _pin_error: Label
var _general_error: Label


func open_new(presenter: TeacherPanelPresenter, sections: Array[SectionTabViewModel], section_id: String) -> void:
	_presenter = presenter
	_sections = sections
	_build("Agregar estudiante", section_id, "")


func open_manage(presenter: TeacherPanelPresenter, sections: Array[SectionTabViewModel], row: StudentRowViewModel) -> void:
	_presenter = presenter
	_sections = sections
	_row = row
	_build(row.name, row.section_id, row.name)


func _build(title: String, section_id: String, student_name: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.13, 0.1, 0.09, 0.55)
	add_child(veil)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	_card.custom_minimum_size.x = 700
	var content := Ui.vbox(14)
	var close := Ui.compact(Ui.button("Cerrar", "", &"SoftButton"))
	close.pressed.connect(_close)
	var heading := Ui.hbox(16)
	if _row:
		var badge := AvatarBadge.new()
		badge.show_look(_row.look)
		heading.add_child(badge)
	var title_label := Ui.label(title, &"TitleLabel")
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.add_child(title_label)
	heading.add_child(close)
	content.add_child(heading)

	_name = Ui.field("Nombre y apellidos", false, false, 40)
	_name.text = student_name
	_name_error = Ui.label("", &"ErrorLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 620)
	content.add_child(Ui.field_block("Nombre", _name, _name_error))
	var chips := Ui.hbox(10)
	for tab in _sections:
		var chip := Ui.chip(tab.label, _section_group)
		chip.set_meta("section_id", tab.id)
		chip.set_pressed_no_signal(tab.id == section_id)
		chips.add_child(chip)
	_section_error = Ui.label("", &"ErrorLabel")
	content.add_child(Ui.field_block("Sección", chips, _section_error))

	_pin = Ui.field("4 números", true, false, 4)
	_pin.text = _presenter.suggest_pin()
	_pin.custom_minimum_size.x = 200
	_pin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pin_error = Ui.label("", &"ErrorLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 620)
	var another := Ui.compact(Ui.button("Otro PIN", "dice", &"SoftButton"))
	another.pressed.connect(func() -> void: _pin.text = _presenter.suggest_pin())
	_general_error = Ui.label("", &"ErrorLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 620)
	_general_error.visible = false

	if _row == null:
		content.add_child(Ui.field_block("PIN del estudiante", Ui.hbox(12, [_pin, another]), _pin_error))
		content.add_child(Ui.label("Anota el PIN y entrégaselo al estudiante. Lo puedes cambiar cuando quieras.", &"HintLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 620))
		var save := Ui.compact(Ui.button("Guardar", "check"), 24)
		save.pressed.connect(_on_register)
		content.add_child(_general_error)
		content.add_child(Ui.hbox(16, [Ui.spacer(), save]))
	else:
		var save_data := Ui.compact(Ui.button("Guardar cambios", "check"))
		save_data.pressed.connect(_on_update)
		content.add_child(Ui.hbox(16, [Ui.spacer(), save_data]))
		content.add_child(HSeparator.new())
		var save_pin := Ui.compact(Ui.button("Guardar PIN", "key", &"SoftButton"))
		save_pin.pressed.connect(_on_reset_pin)
		content.add_child(Ui.field_block("¿Olvidó su PIN? Dale uno nuevo", Ui.hbox(12, [_pin, another, Ui.spacer(), save_pin]), _pin_error))
		content.add_child(HSeparator.new())
		var toggle: Button
		if _row.active:
			toggle = Ui.compact(Ui.button("Desactivar", "person_off", &"DangerButton"))
		else:
			toggle = Ui.compact(Ui.button("Reactivar", "person_on"))
		toggle.pressed.connect(_on_toggle_active)
		var note := Ui.label("Sus estrellas y resultados se conservan siempre." if _row.active else "Volverá a aparecer en la pantalla de perfiles.", &"HintLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 360)
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(_general_error)
		content.add_child(Ui.hbox(16, [note, toggle]))
	_card.add_child(content)
	add_child(_card)
	var avoider := KeyboardAvoider.new()
	avoider.target = _card
	add_child(avoider)
	Ui.pop_in(_card)


func _selected_section() -> String:
	var pressed := _section_group.get_pressed_button()
	return str(pressed.get_meta("section_id")) if pressed else ""


func _show(feedback: FormFeedbackViewModel) -> bool:
	Ui.show_error(_name, _name_error, feedback.errors.get("name", ""))
	Ui.show_error(null, _section_error, feedback.errors.get("section", ""))
	Ui.show_error(_pin, _pin_error, feedback.errors.get("pin", ""))
	Ui.show_error(null, _general_error, feedback.errors.get("general", ""))
	if feedback.ok:
		saved.emit(feedback.notice)
		_close()
	return feedback.ok


func _on_register() -> void:
	_show(_presenter.register(_name.text, _selected_section(), _pin.text))


func _on_update() -> void:
	_show(_presenter.update(_row.id, _name.text, _selected_section()))


func _on_reset_pin() -> void:
	var feedback := _presenter.reset_pin(_row.id, _pin.text)
	Ui.show_error(_pin, _pin_error, feedback.errors.get("pin", ""))
	Ui.show_error(null, _general_error, feedback.errors.get("general", ""))
	if feedback.ok:
		saved.emit(feedback.notice)
		_close()


func _on_toggle_active() -> void:
	saved.emit(_presenter.set_active(_row.id, not _row.active))
	_close()


func _close() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func() -> void:
		closed.emit()
		queue_free())

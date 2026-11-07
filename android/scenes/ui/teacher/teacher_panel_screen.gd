class_name TeacherPanelScreen
extends Control
## Modo docente (RF-04, RF-17 y RN-06): estudiantes por sección y pestañas de lo que viene.
## Se cierra solo tras unos minutos sin uso.

signal exit_requested

const ICONS := {"students": "students", "packages": "packages", "enable": "toggle", "reports": "reports", "settings": "settings"}

var _presenter: TeacherPanelPresenter
var _view_model: TeacherPanelViewModel
var _section_id := ""
var _section_group := ButtonGroup.new()
var _list := Ui.vbox(12)
var _empty: Label
var _scroll: ScrollContainer
var _count: Label
var _toast := Toast.new()
var _idle := 0.0
var _dialog: StudentDialog


func setup(presenter: TeacherPanelPresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view_model = _presenter.panel()
	var paper := ColorRect.new()
	paper.color = Color("#F4ECDF")
	paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(paper)
	add_child(_build_sidebar())
	add_child(_build_main())
	add_child(_toast)
	if not _view_model.sections.is_empty():
		_show_section(_view_model.sections[0].id)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch:
		_idle = 0.0


func _process(delta: float) -> void:
	_idle += delta
	if _idle >= _view_model.auto_lock_seconds:
		_idle = 0.0
		exit_requested.emit()


## Para el modo demostración: abre el formulario de un estudiante nuevo.
func open_add_dialog() -> StudentDialog:
	_on_add()
	return _dialog


func _build_sidebar() -> Control:
	var bar := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1F7A70")
	style.border_color = Color("#145550")
	style.border_width_right = 6
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	bar.add_theme_stylebox_override("panel", style)
	bar.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	bar.offset_right = 262
	var column := Ui.vbox(8)
	var brand := Ui.label("EduKids", &"HeaderTitleLabel")
	brand.add_theme_font_size_override("font_size", 34)
	column.add_child(brand)
	column.add_child(Ui.label("Modo docente", &"HeaderSubtitleLabel"))
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	column.add_child(gap)
	for tab: Dictionary in _view_model.tabs:
		var nav := Ui.button(tab["label"], ICONS.get(tab["id"], "students"), &"NavButton")
		nav.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nav.custom_minimum_size.y = 64
		if tab["enabled"]:
			nav.toggle_mode = true
			nav.set_pressed_no_signal(tab["id"] == "students")
		else:
			# Lo que llega en otros sprints se ve tenue y avisa cuándo estará listo.
			nav.modulate.a = 0.62
			var notice := "%s llega en el %s." % [tab["label"], tab["soon"]]
			nav.pressed.connect(func() -> void: _toast.show_message(notice))
		column.add_child(nav)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grow)
	var hint := Ui.label("Se cierra solo tras 5 minutos sin uso.", &"HeaderSubtitleLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 220)
	column.add_child(hint)
	bar.add_child(column)
	return bar


func _build_main() -> Control:
	var main := Ui.margin(32, 26, 32, 20)
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.offset_left = 262
	var column := Ui.vbox(16)
	var title := Ui.label(_view_model.title, &"TitleLabel")
	title.add_theme_font_size_override("font_size", 38)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var heading := Ui.vbox(2, [title, Ui.label(_view_model.subtitle, &"HintLabel")])
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var exit := Ui.compact(Ui.button(_view_model.exit_label, "exit", &"SoftButton"))
	exit.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	exit.pressed.connect(func() -> void: exit_requested.emit())
	column.add_child(Ui.hbox(16, [heading, exit]))
	var sections := Ui.hbox(10)
	for tab in _view_model.sections:
		var chip := Ui.chip(tab.label, _section_group)
		chip.toggled.connect(func(on: bool) -> void:
			if on:
				_show_section(tab.id))
		chip.set_pressed_no_signal(tab.id == (_view_model.sections[0].id if not _view_model.sections.is_empty() else ""))
		sections.add_child(chip)
	_count = Ui.label("", &"HintLabel")
	var add := Ui.compact(Ui.button(_view_model.add_label, "plus"), 24)
	add.pressed.connect(_on_add)
	column.add_child(Ui.hbox(14, [sections, _count, Ui.spacer(), add]))
	_scroll = ScrollContainer.new()
	var scroll := _scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	column.add_child(scroll)
	_empty = Ui.label(_view_model.empty_message, &"HintLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 600)
	_empty.add_theme_font_size_override("font_size", 24)
	_empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	column.add_child(_empty)
	main.add_child(column)
	return main


func _show_section(section_id: String) -> void:
	_section_id = section_id
	for child in _list.get_children():
		child.queue_free()
	var rows := _presenter.students(section_id)
	var active := rows.filter(func(row: StudentRowViewModel) -> bool: return row.active).size()
	_count.text = "%d estudiantes" % active if active != 1 else "1 estudiante"
	_empty.visible = rows.is_empty()
	_scroll.visible = not rows.is_empty()
	for i in rows.size():
		var row := _make_row(rows[i])
		_list.add_child(row)
		Ui.pop_in(row, 0.03 * i)


func _make_row(row: StudentRowViewModel) -> Control:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"RowPanel" if row.active else &"RowPanelInactive"
	var badge := AvatarBadge.new()
	badge.show_look(row.look)
	var name_label := Ui.label(row.name, &"HeadingLabel")
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var detail := Ui.label(row.detail, &"HintLabel")
	var texts := Ui.vbox(0, [name_label, detail])
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var status := PanelContainer.new()
	status.theme_type_variation = {&"ok": &"Badge", &"muted": &"BadgeMuted", &"alert": &"BadgeAlert"}[row.status_kind]
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.add_child(Ui.label(row.status, &"BadgeLabel"))
	var manage := Ui.compact(Ui.button("Gestionar", "edit", &"SoftButton"))
	manage.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	manage.pressed.connect(_on_manage.bind(row))
	panel.add_child(Ui.hbox(18, [badge, texts, status, manage]))
	if not row.active:
		badge.modulate = Color(1, 1, 1, 0.55)
	return panel


func _on_add() -> void:
	_dialog = StudentDialog.new()
	add_child(_dialog)
	_dialog.open_new(_presenter, _view_model.sections, _section_id)
	_dialog.saved.connect(_on_saved)


func _on_manage(row: StudentRowViewModel) -> void:
	_dialog = StudentDialog.new()
	add_child(_dialog)
	_dialog.open_manage(_presenter, _view_model.sections, row)
	_dialog.saved.connect(_on_saved)


func _on_saved(notice: String) -> void:
	_show_section(_section_id)
	if not notice.is_empty():
		_toast.show_message(notice, 4.0)

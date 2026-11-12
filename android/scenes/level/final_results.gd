class_name FinalResults
extends Control
## Calificación del desafío final (RN-12 y RF-30): primero el quipu se revisa nudo por nudo,
## luego cae el sello con AD, A, B o C, el porcentaje y la cuerda recuperada (con nudo dorado
## si es AD o A). A la derecha, cada pregunta con su explicación y la respuesta correcta.

signal replay_requested
signal continue_requested

const STAMP_SIZE := 140.0

var _result: LevelResultViewModel
var _card: PanelContainer
var _stamp: _GradeStamp
var _quipu: QuipuProgress
var _reveal_box: VBoxContainer
var _checking: Label
var _buttons: HBoxContainer


func _init(result: LevelResultViewModel = null) -> void:
	_result = result


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color(0.16, 0.13, 0.12, 0.45)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	add_child(_card)
	var row := Ui.hbox(22)
	_card.add_child(row)
	row.add_child(_summary_column())
	row.add_child(_review_column())
	_layout.call_deferred()
	resized.connect(_layout)
	Ui.pop_in(_card, 0.05)
	_reveal()


func _layout() -> void:
	_card.reset_size()
	var card_size := _card.get_combined_minimum_size()
	card_size.y = minf(card_size.y, size.y - 40.0)
	_card.size = card_size
	# Corrida a la derecha para dejar a Quwi a la vista en la esquina.
	_card.position = Vector2(minf((size.x - card_size.x) * 0.5 + 90.0, size.x - card_size.x - 16.0), (size.y - card_size.y) * 0.5)
	_card.pivot_offset = card_size * 0.5


func press_continue() -> void:
	continue_requested.emit()


func _summary_column() -> Control:
	var column := Ui.vbox(8)
	column.custom_minimum_size.x = 350
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var heading := Ui.label(_result.heading, &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	heading.add_theme_font_size_override("font_size", 36)
	column.add_child(heading)
	if not _result.title.is_empty():
		column.add_child(Ui.label(_result.title, &"HintLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 340))
	_quipu = QuipuProgress.new()
	_quipu.step = 26.0
	_quipu.accent = _result.area.deep
	var hidden: Array[StringName] = []
	for state in _result.progress:
		hidden.append(&"answered")
	_quipu.set_states(hidden)
	_quipu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_quipu)
	_checking = ActivityStyle.label("Revisando tus respuestas…", 22, ActivityStyle.MUTED, false)
	_checking.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_checking)
	_reveal_box = Ui.vbox(10)
	_reveal_box.modulate.a = 0.0
	column.add_child(_reveal_box)
	_stamp = _GradeStamp.new()
	_stamp.grade = _result.grade
	_stamp.color = _result.grade_color
	_stamp.custom_minimum_size = Vector2(STAMP_SIZE, STAMP_SIZE)
	_stamp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reveal_box.add_child(_stamp)
	var description := Ui.label(_result.grade_description, &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	description.add_theme_color_override("font_color", _result.grade_color.darkened(0.15))
	_reveal_box.add_child(description)
	var percent := ActivityStyle.label("%s · %s" % [_result.percent_label, _result.lines[0] if not _result.lines.is_empty() else ""], 21, ActivityStyle.INK, true, 340)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_box.add_child(percent)
	var cord := _CordRibbon.new()
	cord.text = _result.cord_label
	cord.color = _result.area.color
	cord.golden = _result.golden_knot
	cord.custom_minimum_size = Vector2(340, 58)
	_reveal_box.add_child(cord)
	if not _result.guide_line.is_empty():
		_reveal_box.add_child(ActivityStyle.label(_result.guide_line, 19, ActivityStyle.BROWN, true, 340))
	_reveal_box.add_child(ActivityStyle.label(_result.attempts_label, 18, ActivityStyle.MUTED, true, 340))
	if not _result.warning.is_empty():
		_reveal_box.add_child(Ui.label(_result.warning, &"ErrorLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 340))
	return column


func _review_column() -> Control:
	var column := Ui.vbox(10)
	column.custom_minimum_size = Vector2(500, 540)
	column.add_child(Ui.label(_result.review_title, &"HeadingLabel"))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := Ui.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for item in _result.review:
		list.add_child(_review_row(item))
	# Los botones van debajo de la revisión, para que la columna de la calificación no crezca.
	_buttons = Ui.hbox(14)
	_buttons.alignment = BoxContainer.ALIGNMENT_END
	_buttons.modulate.a = 0.0
	if _result.can_replay:
		var replay := Ui.compact(Ui.button(_result.replay_label, "replay", &"SoftButton"), 22)
		replay.pressed.connect(func() -> void: replay_requested.emit())
		_buttons.add_child(replay)
	var back := Ui.compact(Ui.button(_result.continue_label, "back"), 22)
	back.pressed.connect(func() -> void: continue_requested.emit())
	_buttons.add_child(back)
	column.add_child(_buttons)
	return column


func _review_row(item: ReviewItemViewModel) -> Control:
	var tone := ActivityStyle.SUCCESS if item.correct else ActivityStyle.ERROR
	var panel := PanelContainer.new()
	var style := ActivityStyle.box(tone.lerp(Color.WHITE, 0.88), tone.lerp(Color.WHITE, 0.4), 3, 16, 2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	var row := Ui.hbox(12)
	panel.add_child(row)
	var badge := MarkBadge.new("", tone, false, 34.0)
	badge.state = ActivityStyle.RIGHT if item.correct else ActivityStyle.WRONG
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(badge)
	var texts := Ui.vbox(4)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var prompt := ActivityStyle.label("%d. %s" % [item.number, item.prompt], 19, ActivityStyle.INK, true, 400)
	prompt.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	texts.add_child(prompt)
	if not item.feedback.is_empty():
		texts.add_child(ActivityStyle.label(item.feedback, 18, ActivityStyle.BROWN, true, 400))
	if not item.solution.is_empty():
		texts.add_child(ActivityStyle.label(item.solution, 18, tone.darkened(0.25), true, 400))
	row.add_child(texts)
	return panel


## Revela el quipu nudo por nudo y después estampa la calificación.
func _reveal() -> void:
	var tween := create_tween()
	tween.tween_interval(0.7)
	var shown: Array[StringName] = []
	for state in _result.progress:
		shown.append(&"answered")
	for index in _result.progress.size():
		tween.tween_callback(func() -> void:
			shown[index] = _result.progress[index]
			_quipu.set_states(shown))
		tween.tween_interval(0.16)
	tween.tween_interval(0.3)
	tween.tween_callback(func() -> void:
		_checking.visible = false
		_stamp.scale = Vector2(2.2, 2.2)
		_stamp.pivot_offset = _stamp.custom_minimum_size * 0.5)
	tween.tween_property(_reveal_box, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(_buttons, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(_stamp, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		if _result.golden_knot:
			StageFx.burst(self, _stamp.get_global_rect().get_center() - get_global_rect().position, &"sparkle", 40))


func demo_reveal_seconds() -> float:
	return 1.6 + 0.16 * _result.progress.size()


## Sello redondo con la calificación, como los de un tejido.
class _GradeStamp:
	extends Control
	var grade := ""
	var color := Color.WHITE
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5 - 4.0
		for i in 16:
			var angle := TAU * i / 16.0 + _time * 0.2
			draw_circle(center + Vector2.from_angle(angle) * radius, 9.0, color.lightened(0.25))
		draw_circle(center, radius, color.darkened(0.25))
		draw_circle(center, radius - 6.0, color)
		draw_arc(center, radius - 16.0, 0.0, TAU, 48, Color(1, 1, 1, 0.55), 3.0, true)
		var font := ThemeDB.get_project_theme().get_font("font", &"Button")
		var font_size := 78 if grade.length() > 1 else 92
		var text_size := font.get_string_size(grade, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var baseline := center + Vector2(-text_size.x * 0.5, font_size * 0.34)
		draw_string_outline(font, baseline, grade, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, color.darkened(0.45))
		draw_string(font, baseline, grade, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


## La cuerda del área que vuelve al quipu, con su nudo (dorado si es AD o A).
class _CordRibbon:
	extends Control
	var text := ""
	var color := Color.WHITE
	var golden := false
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var y := 18.0
		var points := PackedVector2Array()
		for i in 25:
			var x := 20.0 + (size.x - 40.0) * i / 24.0
			points.append(Vector2(x, y + sin(i * 0.6 + _time * 2.0) * 3.0))
		draw_polyline(points, color.darkened(0.35), 9.0, true)
		draw_polyline(points, color, 6.0, true)
		var knot := Vector2(size.x * 0.5, y + sin(12 * 0.6 + _time * 2.0) * 3.0)
		var fill := Color("#F2C14E") if golden else color.lightened(0.2)
		if golden:
			draw_circle(knot, 20.0 + sin(_time * 4.0) * 2.0, Color(1.0, 0.85, 0.3, 0.35))
		draw_circle(knot, 13.0, Color("#5A2E16"))
		draw_circle(knot, 11.0, fill)
		draw_arc(knot, 6.0, -0.6, 2.4, 10, Color(1, 1, 1, 0.6), 3.0, true)
		var font := ThemeDB.get_project_theme().get_font("font", &"Button")
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21)
		draw_string(font, Vector2((size.x - text_size.x) * 0.5, y + 42.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, ActivityStyle.BROWN)

class_name FeedbackPanel
extends PanelContainer
## Retroalimentación que sube desde abajo: ✓ o ✗ grande, un título amable, la explicación
## y el botón para seguir. Bien y mal se distinguen por icono, color y palabras.

signal continue_requested

var _mark: MarkBadge
var _title: Label
var _message: Label
var _notes: VBoxContainer
var _button: Button
var _streak: PanelContainer
var _streak_label: Label
var _shown := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	add_child(row)
	_mark = MarkBadge.new("", ActivityStyle.PRIMARY, false, 76)
	row.add_child(_mark)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	_title = ActivityStyle.label("", 34, ActivityStyle.INK, false)
	_title.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	heading.add_child(_title)
	# «¡Racha de 3!»: una cinta naranja cuando se encadenan aciertos.
	_streak = PanelContainer.new()
	var ribbon := ActivityStyle.box(Color("#F28C28"), Color("#B4561A"), 4, 16, 0)
	ribbon.content_margin_left = 12
	ribbon.content_margin_right = 12
	ribbon.content_margin_top = 2
	ribbon.content_margin_bottom = 4
	_streak.add_theme_stylebox_override("panel", ribbon)
	_streak.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_streak_label = ActivityStyle.label("", 21, Color.WHITE, false)
	_streak.add_child(_streak_label)
	heading.add_child(_streak)
	column.add_child(heading)
	_message = ActivityStyle.label("", 25, ActivityStyle.INK, true, 420)
	column.add_child(_message)
	_notes = VBoxContainer.new()
	_notes.add_theme_constant_override("separation", 2)
	column.add_child(_notes)
	_button = Ui.button("", "play")
	_button.custom_minimum_size = Vector2(220, 72)
	_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_button.pressed.connect(func() -> void:
		if _shown:
			continue_requested.emit())
	row.add_child(_button)


## Llena el panel; después, `slide_in` lo hace subir hasta su lugar.
func fill(feedback: FeedbackViewModel) -> void:
	var color := ActivityStyle.SUCCESS if feedback.correct else ActivityStyle.ERROR
	var style := ActivityStyle.box(ActivityStyle.SUCCESS_SOFT if feedback.correct else ActivityStyle.ERROR_SOFT,
		color, 10, 30, 4)
	style.border_width_top = 8
	style.content_margin_left = 26
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0.16, 0.13, 0.12, 0.25)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, -4)
	add_theme_stylebox_override("panel", style)
	_mark.state = ActivityStyle.RIGHT if feedback.correct else ActivityStyle.WRONG
	_title.text = feedback.title
	_streak.visible = not feedback.streak_label.is_empty()
	_streak_label.text = feedback.streak_label
	if _streak.visible:
		_streak.pivot_offset = _streak.get_combined_minimum_size() * 0.5
		ActivityStyle.pop(_streak, 0.35)
	_title.add_theme_color_override("font_color", color.darkened(0.25))
	_message.text = feedback.message
	for child in _notes.get_children():
		child.queue_free()
	var lines := feedback.notes.duplicate()
	if not feedback.warning.is_empty():
		lines.append(feedback.warning)
	for note: String in lines:
		_notes.add_child(ActivityStyle.label("• " + note, 22, ActivityStyle.BROWN, true, 420))
	_button.text = feedback.continue_label


func slide_in(target: Vector2, origin_y: float) -> void:
	visible = true
	_shown = false
	position = Vector2(target.x, origin_y)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", target.y, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.chain().tween_callback(func() -> void: _shown = true)
	ActivityStyle.pop(_mark, 0.25)


func dismiss() -> void:
	_shown = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(hide)


func is_shown() -> bool:
	return _shown


func press_continue() -> void:
	if _shown:
		continue_requested.emit()

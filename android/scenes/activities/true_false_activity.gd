class_name TrueFalseActivity
extends ActivityView
## Verdadero o falso: cada afirmación en su fila, con dos botones grandes.
## Respuesta: diccionario id de la afirmación → true o false.

var _choice := {}
var _buttons := {}
var _rows := {}
var _marks := {}


func build() -> void:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	center(list)
	add_child(list)
	var statements: Array = step.data["statements"]
	for index in statements.size():
		var statement: Dictionary = statements[index]
		var row := PanelContainer.new()
		var style := ActivityStyle.box(ActivityStyle.CREAM, ActivityStyle.LINE, 6, 20)
		style.content_margin_left = 20
		row.add_theme_stylebox_override("panel", style)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		var number := MarkBadge.new(str(index + 1), accent(), false, 36.0 if compact() else 40.0)
		line.add_child(number)
		var text := ActivityStyle.label(statement["text"], 23 if compact() else 26, ActivityStyle.INK, true, 200)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		# En la columna angosta de una lectura, los botones van debajo de la afirmación.
		var content: Control = line
		var buttons := line
		if compact():
			var stack := VBoxContainer.new()
			stack.add_theme_constant_override("separation", 6)
			stack.add_child(line)
			buttons = HBoxContainer.new()
			buttons.add_theme_constant_override("separation", 12)
			buttons.alignment = BoxContainer.ALIGNMENT_END
			stack.add_child(buttons)
			content = stack
		var pair := {}
		for value: bool in [true, false]:
			var button := TapCard.new()
			button.accent = accent()
			button.radius = 30
			button.depth = 6
			button.custom_minimum_size = Vector2(136, 52) if compact() else Vector2(148, 62)
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			var caption := ActivityStyle.label(step.labels["true" if value else "false"], 24, ActivityStyle.INK, false)
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.add_child(caption)
			button.tapped.connect(_choose.bind(statement["id"], value))
			buttons.add_child(button)
			pair[value] = button
		_buttons[statement["id"]] = pair
		_marks[statement["id"]] = number
		row.add_child(content)
		list.add_child(row)
		_rows[statement["id"]] = row
		Ui.pop_in(row, 0.06 * index)


func _choose(statement_id: String, value: bool) -> void:
	if locked:
		return
	_choice[statement_id] = value
	for option: bool in _buttons[statement_id]:
		_buttons[statement_id][option].state = ActivityStyle.SELECTED if option == value else ActivityStyle.NORMAL
	changed.emit()


func answer() -> Variant:
	return _choice.duplicate()


func is_complete() -> bool:
	return _choice.size() == _buttons.size()


func show_result(parts: Dictionary) -> void:
	for statement_id: String in _buttons:
		for option: bool in _buttons[statement_id]:
			_buttons[statement_id][option].disabled = true
		if not parts.has(statement_id):
			continue
		var state := ActivityStyle.RIGHT if parts[statement_id] else ActivityStyle.WRONG
		_buttons[statement_id][_choice[statement_id]].state = state
		_marks[statement_id].state = state
		if not parts[statement_id]:
			ActivityStyle.shake(_rows[statement_id])


func apply_answer(value: Variant) -> void:
	var delay := 0.0
	for statement_id: Variant in value:
		get_tree().create_timer(delay).timeout.connect(_choose.bind(str(statement_id), bool(value[statement_id])))
		delay += 0.5

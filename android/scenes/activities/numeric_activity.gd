class_name NumericActivity
extends ActivityView
## Respuesta numérica: una pizarra muestra lo que se escribe y al lado está el teclado grande
## del juego. Las teclas de coma y de fracción solo aparecen si el ítem acepta ese formato.
## Respuesta: el texto escrito («540», «0,5» o «1/2»).

const MAX_LENGTH := 9
const CHALK := Color("#FDF8EC")
const BOARD := Color("#2F5446")
const FRAME := Color("#8A5A32")
const BACKSPACE := "⌫"

var _text := ""
var _board: PanelContainer
var _value: Label
var _mark: MarkBadge
var _caret: ColorRect
var _keys: Array[Button] = []
var _unit := ""
var _unit_first := false


func build() -> void:
	_unit = step.data.get("unit", "")
	_unit_first = step.data.get("unit_first", false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16 if compact() else 34)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center(row)
	add_child(row)
	row.add_child(_make_board())
	row.add_child(_make_keypad())
	_render()


func _make_board() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var caption := ActivityStyle.label(step.labels.get("answer", ""), 22, ActivityStyle.MUTED, false)
	column.add_child(caption)
	_board = PanelContainer.new()
	var style := ActivityStyle.box(BOARD, FRAME, 14, 18, 10)
	style.content_margin_left = 16 if compact() else 30
	style.content_margin_right = 16 if compact() else 30
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	_board.add_theme_stylebox_override("panel", style)
	_board.custom_minimum_size = Vector2(196, 110) if compact() else Vector2(380, 150)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 6)
	_value = ActivityStyle.label("", 40 if compact() else 58, CHALK, false)
	_value.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.08))
	_value.add_theme_constant_override("outline_size", 4)
	line.add_child(_value)
	_caret = ColorRect.new()
	_caret.color = CHALK
	_caret.custom_minimum_size = Vector2(4, 40) if compact() else Vector2(5, 56)
	_caret.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_caret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(_caret)
	_board.add_child(line)
	_mark = MarkBadge.new("", accent(), false, 40.0 if compact() else 54.0)
	_mark.visible = false
	line.add_child(_mark)
	column.add_child(_board)
	var blink := create_tween().set_loops()
	blink.tween_property(_caret, "modulate:a", 0.0, 0.45).set_delay(0.35)
	blink.tween_property(_caret, "modulate:a", 1.0, 0.15)
	return column


func _make_keypad() -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8 if compact() else 12)
	grid.add_theme_constant_override("v_separation", 8 if compact() else 12)
	var keys: Array[String] = ["7", "8", "9", "4", "5", "6", "1", "2", "3"]
	keys.append("," if step.data.get("decimal", true) else "")
	keys.append("0")
	keys.append(BACKSPACE)
	if step.data.get("fraction", false):
		keys.append_array(["", "/", ""])
	for key in keys:
		if key.is_empty():
			grid.add_child(Control.new())
			continue
		var button := Ui.button("" if key == BACKSPACE else key, "backspace" if key == BACKSPACE else "", &"KeyButton")
		button.custom_minimum_size = Vector2(68, 54) if compact() else Vector2(92, 64)
		button.add_theme_font_size_override("font_size", 28 if compact() else 34)
		if key == BACKSPACE:
			button.add_theme_color_override("icon_normal_color", ActivityStyle.BROWN)
			button.add_theme_color_override("icon_pressed_color", ActivityStyle.BROWN)
			button.add_theme_color_override("icon_hover_color", ActivityStyle.BROWN)
			button.add_theme_constant_override("icon_max_width", 36)
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_press.bind(key))
		grid.add_child(button)
		_keys.append(button)
	return grid


func _press(key: String) -> void:
	if locked:
		return
	if key == BACKSPACE:
		_text = _text.left(-1)
	elif _text.length() < MAX_LENGTH and _allowed(key):
		_text += key
	else:
		ActivityStyle.shake(_board)
		return
	_render()
	changed.emit()


## Evita escrituras imposibles: dos comas, dos barras, coma y barra juntas o empezar con «/».
func _allowed(key: String) -> bool:
	if key == ",":
		return not _text.contains(",") and not _text.contains("/")
	if key == "/":
		return not _text.is_empty() and not _text.contains("/") and not _text.contains(",")
	return true


func _render() -> void:
	var shown := _text if not _text.is_empty() else "?"
	if not _unit.is_empty():
		shown = ("%s %s" % [_unit, shown]) if _unit_first else ("%s %s" % [shown, _unit])
	_value.text = shown
	_value.modulate.a = 1.0 if not _text.is_empty() else 0.45
	ActivityStyle.pop(_value, 0.04)


func _unhandled_key_input(event: InputEvent) -> void:
	if locked or not (event is InputEventKey) or not event.pressed:
		return
	var character := char(event.unicode) if event.unicode > 0 else ""
	if character in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", "/"]:
		_press(character)
	elif character == ".":
		_press(",")
	elif event.keycode == KEY_BACKSPACE:
		_press(BACKSPACE)


func answer() -> Variant:
	return _text


func is_complete() -> bool:
	return not _text.is_empty() and not _text.ends_with(",") and not _text.ends_with("/")


func show_result(parts: Dictionary) -> void:
	for key in _keys:
		key.disabled = true
	_caret.visible = false
	var right: bool = parts.get("value", false)
	var style := (_board.get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	style.border_color = ActivityStyle.SUCCESS if right else ActivityStyle.ERROR
	_board.add_theme_stylebox_override("panel", style)
	_mark.state = ActivityStyle.RIGHT if right else ActivityStyle.WRONG
	_mark.visible = true
	ActivityStyle.pop(_mark, 0.2)
	if not right:
		ActivityStyle.shake(_board)


func apply_answer(value: Variant) -> void:
	var text := str(value)
	for index in text.length():
		get_tree().create_timer(0.3 * index).timeout.connect(_press.bind(text[index]))

class_name PinPad
extends VBoxContainer
## Teclado numérico grande para escribir un PIN (RNF-03: teclas de más de 64 dp).
## Con auto_submit, el PIN se envía solo al llegar a max_length (estudiantes);
## si no, aparece la tecla de confirmar (docente).

signal changed(length: int)
signal submitted(pin: String)

const ERASE_ICON := preload("res://assets/art/ui/ui_icon_erase.svg")
const CHECK_ICON := preload("res://assets/art/ui/ui_icon_check.svg")
const KEY_SIZE := Vector2(112, 84)

@export var max_length := 4
@export var min_length := 4
@export var auto_submit := true

var _digits := ""
var _keys: Array[Button] = []
var _ok: Button
var _enabled := true


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var rows := [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", ""]]
	for row in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(line)
		for i in 3:
			var label: String = row[i]
			if label.is_empty():
				line.add_child(_special_key(i == 0))
			else:
				line.add_child(_digit_key(label))
	_refresh()


func pin_length() -> int:
	return _digits.length()


func clear() -> void:
	_digits = ""
	_refresh()
	changed.emit(0)


func set_enabled(value: bool) -> void:
	_enabled = value
	for key in _keys:
		key.disabled = not value
	_refresh()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _enabled or not is_visible_in_tree() or not event.is_pressed():
		return
	var key := event as InputEventKey
	if key.keycode >= KEY_0 and key.keycode <= KEY_9:
		_press(str(key.keycode - KEY_0))
	elif key.keycode >= KEY_KP_0 and key.keycode <= KEY_KP_9:
		_press(str(key.keycode - KEY_KP_0))
	elif key.keycode == KEY_BACKSPACE:
		_erase()
	elif key.keycode in [KEY_ENTER, KEY_KP_ENTER] and not auto_submit:
		_submit()
	else:
		return
	get_viewport().set_input_as_handled()


func _digit_key(label: String) -> Button:
	var key := _make_key()
	key.text = label
	key.pressed.connect(_press.bind(label))
	return key


## Tecla de la esquina: borrar o confirmar. Con auto_submit, la izquierda queda vacía.
func _special_key(is_left: bool) -> Control:
	if auto_submit and is_left:
		var gap := Control.new()
		gap.custom_minimum_size = KEY_SIZE
		return gap
	var key := _make_key()
	key.expand_icon = false
	key.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if is_left or auto_submit:
		key.icon = ERASE_ICON
		key.tooltip_text = "Borrar"
		key.pressed.connect(_erase)
	else:
		key.icon = CHECK_ICON
		key.tooltip_text = "Entrar"
		key.theme_type_variation = &"Button"
		var theme := ThemeDB.get_project_theme()
		for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var box := theme.get_stylebox(state, &"Button").duplicate() as StyleBoxFlat
			box.content_margin_left = 8
			box.content_margin_right = 8
			box.set_corner_radius_all(26)
			box.shadow_size = 0
			key.add_theme_stylebox_override(state, box)
		key.pressed.connect(_submit)
		_ok = key
	return key


func _make_key() -> Button:
	var key := Button.new()
	key.theme_type_variation = &"KeyButton"
	key.custom_minimum_size = KEY_SIZE
	key.focus_mode = Control.FOCUS_NONE
	key.pivot_offset = KEY_SIZE * 0.5
	key.button_down.connect(func() -> void:
		var tween := key.create_tween()
		tween.tween_property(key, "scale", Vector2(0.92, 0.92), 0.05))
	key.button_up.connect(func() -> void:
		var tween := key.create_tween()
		tween.tween_property(key, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	_keys.append(key)
	return key


func _press(digit: String) -> void:
	if not _enabled or _digits.length() >= max_length:
		return
	_digits += digit
	_refresh()
	changed.emit(_digits.length())
	if auto_submit and _digits.length() == max_length:
		_submit()


func _erase() -> void:
	if not _enabled or _digits.is_empty():
		return
	_digits = _digits.substr(0, _digits.length() - 1)
	_refresh()
	changed.emit(_digits.length())


func _submit() -> void:
	if not _enabled or _digits.length() < min_length:
		return
	var pin := _digits
	submitted.emit(pin)


func _refresh() -> void:
	if _ok:
		_ok.disabled = not _enabled or _digits.length() < min_length

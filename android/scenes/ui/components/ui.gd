class_name Ui
extends RefCounted
## Atajos para armar interfaces con el tema de EduKids desde código.


static func icon(name: String) -> Texture2D:
	return load("res://assets/art/ui/ui_icon_%s.svg" % name)


## Con wrap, conviene indicar un ancho mínimo: sin él, la etiqueta se mide con ancho cero
## y pide una altura enorme a su contenedor.
static func label(text: String, variation: StringName = &"", align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false, min_width: float = 0.0) -> Label:
	var result := Label.new()
	result.text = text
	result.theme_type_variation = variation
	result.horizontal_alignment = align
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size.x = min_width
	return result


static func button(text: String, icon_name: String = "", variation: StringName = &"") -> Button:
	var result := Button.new()
	result.text = text
	result.theme_type_variation = variation
	result.focus_mode = Control.FOCUS_NONE
	if not icon_name.is_empty():
		result.icon = icon(icon_name)
	result.pressed.connect(Sounds.play.bind(&"tap", 1.0, -4.0))
	return result


## Versión más pequeña de un botón (pantallas del docente): menos relleno, texto e icono menores.
static func compact(target: Button, font_size: int = 22) -> Button:
	var theme := ThemeDB.get_project_theme()
	var type := target.theme_type_variation if target.theme_type_variation != &"" else &"Button"
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		if not theme.has_stylebox(state, type):
			continue
		var box := theme.get_stylebox(state, type).duplicate() as StyleBoxFlat
		if box == null:
			continue
		var pressed: bool = state.contains("pressed")
		box.content_margin_left = 16
		box.content_margin_right = 20
		box.content_margin_top = 10 if pressed else 6
		box.content_margin_bottom = 6 if pressed else 10
		box.set_corner_radius_all(24)
		box.border_width_bottom = mini(box.border_width_bottom, 3 if pressed else 6)
		box.shadow_size = mini(box.shadow_size, 6)
		box.shadow_offset = Vector2(0, mini(int(box.shadow_offset.y), 3))
		target.add_theme_stylebox_override(state, box)
	target.add_theme_font_size_override("font_size", font_size)
	target.add_theme_constant_override("icon_max_width", 28)
	target.add_theme_constant_override("h_separation", 8)
	return target


## Botón que se puede dejar activado (secciones, sexo del avatar, grado).
static func chip(text: String, group: ButtonGroup = null) -> Button:
	var result := button(text, "", &"ChipButton")
	result.toggle_mode = true
	result.button_group = group
	result.custom_minimum_size.y = 60
	return result


static func hbox(separation: int = 12, children: Array = []) -> HBoxContainer:
	var result := HBoxContainer.new()
	result.add_theme_constant_override("separation", separation)
	for child: Control in children:
		result.add_child(child)
	return result


static func vbox(separation: int = 12, children: Array = []) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override("separation", separation)
	for child: Control in children:
		result.add_child(child)
	return result


static func margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var result := MarginContainer.new()
	result.add_theme_constant_override("margin_left", left)
	result.add_theme_constant_override("margin_top", top)
	result.add_theme_constant_override("margin_right", right)
	result.add_theme_constant_override("margin_bottom", bottom)
	return result


static func spacer(min_width: float = 0.0) -> Control:
	var result := Control.new()
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.custom_minimum_size.x = min_width
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func field(placeholder: String, numeric: bool = false, secret: bool = false, max_length: int = 0) -> LineEdit:
	var result := LineEdit.new()
	result.placeholder_text = placeholder
	result.secret = secret
	result.max_length = max_length
	result.custom_minimum_size.y = 62
	result.caret_blink = true
	result.select_all_on_focus = true
	if numeric:
		result.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	return result


## Etiqueta, campo y mensaje de error, uno debajo del otro.
static func field_block(caption: String, input: Control, error: Label) -> VBoxContainer:
	error.visible = false
	return vbox(6, [label(caption, &"FieldLabel"), input, error])


static func show_error(input: LineEdit, error: Label, message: String) -> void:
	error.text = message
	error.visible = not message.is_empty()
	if input:
		input.theme_type_variation = &"FieldError" if not message.is_empty() else &""


## Pequeño rebote al aparecer.
static func pop_in(control: Control, delay: float = 0.0) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(0.85, 0.85)
	control.modulate.a = 0.0
	var tween := control.create_tween().set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE, 0.35).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, 0.2).set_delay(delay)

class_name TapCard
extends PanelContainer
## Tarjeta que se toca: opciones, elementos, palabras y espacios. Cambia de estilo según su
## estado (normal, elegida, bien o mal) y, si tiene `drag_data`, también se puede arrastrar.
## Si `accepts` y `on_drop` están definidos, recibe lo que le sueltan encima.

signal tapped
signal drag_started

var accent := ActivityStyle.PRIMARY
var state: StringName = ActivityStyle.NORMAL:
	set(value):
		state = value
		_apply()
var disabled := false
var radius := 22
var depth := 8
## Borde en reposo distinto del habitual (por ejemplo, el color del área); transparente si no.
var border_override := Color(0, 0, 0, 0)
## Datos que lleva al arrastrarse; null si no se arrastra.
var drag_data: Variant = null
## Texto de la copia que sigue al dedo mientras se arrastra.
var preview_text := ""
## Si se define, arma otra figura para seguir al dedo (por ejemplo, un nudo).
var preview_builder: Callable
var accepts: Callable
var on_drop: Callable

var _pressed := false
var _hovered_drop := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	_apply()


func _apply() -> void:
	if not is_inside_tree():
		return
	var colors := ActivityStyle.colors_for(state, accent)
	if state == ActivityStyle.NORMAL and border_override.a > 0.0:
		colors[1] = border_override
	var border: Color = accent if _hovered_drop else colors[1]
	var width := 3 if state == ActivityStyle.NORMAL and not _hovered_drop else 4
	var style := ActivityStyle.box(colors[0], border, 4 if _pressed else depth, radius, width)
	if _pressed:
		style.content_margin_top += depth - 4
	if _hovered_drop:
		style.bg_color = accent.lerp(Color.WHITE, 0.9)
	add_theme_stylebox_override("panel", style)


func _gui_input(event: InputEvent) -> void:
	if disabled or not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_set_pressed(true)
		accept_event()
	elif _pressed:
		_set_pressed(false)
		accept_event()
		if Rect2(Vector2.ZERO, size).has_point(event.position):
			ActivityStyle.pop(self, 0.05)
			tapped.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate.a = 1.0
		_set_pressed(false)
		if _hovered_drop:
			_hovered_drop = false
			_apply()
	elif what == NOTIFICATION_MOUSE_EXIT and _hovered_drop:
		_hovered_drop = false
		_apply()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or drag_data == null:
		return null
	_set_pressed(false)
	if preview_builder.is_valid():
		set_drag_preview(preview_builder.call())
	else:
		set_drag_preview(_preview())
		modulate.a = 0.35
	drag_started.emit()
	return drag_data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = not disabled and accepts.is_valid() and accepts.call(data)
	if ok != _hovered_drop:
		_hovered_drop = ok
		_apply()
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_hovered_drop = false
	_apply()
	if on_drop.is_valid():
		on_drop.call(data)


func _set_pressed(value: bool) -> void:
	if _pressed == value:
		return
	_pressed = value
	_apply()


## Copia de la tarjeta, centrada en el dedo, un poco inclinada.
func _preview() -> Control:
	var holder := Control.new()
	var card := PanelContainer.new()
	var style := ActivityStyle.box(accent.lerp(Color.WHITE, 0.84), accent, depth, radius, 4)
	style.shadow_color = Color(0.16, 0.13, 0.12, 0.3)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 8)
	card.add_theme_stylebox_override("panel", style)
	card.add_child(ActivityStyle.label(preview_text, 26, ActivityStyle.INK, false))
	holder.add_child(card)
	card.position = -card.get_combined_minimum_size() * 0.5
	card.rotation = -0.05
	return holder

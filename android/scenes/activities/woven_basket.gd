class_name WovenBasket
extends Control
## Canasta tejida para clasificar: se dibuja con código, con franjas de colores de la Sierra
## y su nombre en una cinta. Recibe tarjetas que se sueltan encima o se tocan.

signal tapped

const RIM := Color("#8A5A32")
const WOOD := Color("#C98E55")
const OUTLINE := Color("#5A2E16")
const RIBBON_HEIGHT := 46.0

var title := ""
var stripe := ActivityStyle.THREADS[0]
var accepts: Callable
var on_drop: Callable
var highlighted := false:
	set(value):
		highlighted = value
		queue_redraw()
var disabled := false

var _flow: HFlowContainer
var _ribbon: Label


func _init(basket_title: String = "", stripe_color: Color = ActivityStyle.THREADS[0]) -> void:
	title = basket_title
	stripe = stripe_color
	custom_minimum_size = Vector2(200, 230)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	_flow = HFlowContainer.new()
	_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_flow.add_theme_constant_override("h_separation", 8)
	_flow.add_theme_constant_override("v_separation", 8)
	add_child(_flow)
	_ribbon = ActivityStyle.label(title, 24, Color.WHITE, false)
	_ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ribbon.add_theme_color_override("font_outline_color", stripe.darkened(0.45))
	_ribbon.add_theme_constant_override("outline_size", 6)
	add_child(_ribbon)
	resized.connect(_layout)
	_layout()


func holder() -> Container:
	return _flow


func _layout() -> void:
	_ribbon.position = Vector2(0, 0)
	_ribbon.size = Vector2(size.x, RIBBON_HEIGHT)
	_flow.position = Vector2(26, RIBBON_HEIGHT + 22)
	_flow.size = Vector2(size.x - 52, size.y - RIBBON_HEIGHT - 40)
	queue_redraw()


func _draw() -> void:
	var top := RIBBON_HEIGHT + 8.0
	var bottom := size.y - 4.0
	var inset := 18.0
	if highlighted:
		draw_rect(Rect2(Vector2(-6, top - 10), Vector2(size.x + 12, bottom - top + 16)), Color(stripe, 0.22))
	var body := PackedVector2Array([Vector2(4, top + 6), Vector2(size.x - 4, top + 6),
		Vector2(size.x - inset, bottom - 14), Vector2(size.x - inset - 14, bottom),
		Vector2(inset + 14, bottom), Vector2(inset, bottom - 14)])
	draw_colored_polygon(body, WOOD)
	# Franjas tejidas y varillas.
	var band := 26.0
	var y := top + 30.0
	var row := 0
	while y < bottom - 18.0:
		var t := (y - top) / (bottom - top)
		var left := lerpf(4.0, inset, t) + 2.0
		var right := lerpf(size.x - 4.0, size.x - inset, t) - 2.0
		var color: Color = [stripe, Color("#F2C14E"), Color("#FFF1DA")][row % 3]
		draw_rect(Rect2(Vector2(left, y), Vector2(right - left, 9.0)), Color(color, 0.92))
		var x := left + (row % 2) * 14.0
		while x < right - 6.0:
			draw_rect(Rect2(Vector2(x, y + 2.0), Vector2(6.0, 5.0)), Color(OUTLINE, 0.25))
			x += 28.0
		y += band
		row += 1
	draw_polyline(body + PackedVector2Array([body[0]]), OUTLINE, 4.0, true)
	# Borde de arriba.
	var rim := StyleBoxFlat.new()
	rim.bg_color = RIM
	rim.border_color = OUTLINE
	rim.set_border_width_all(3)
	rim.set_corner_radius_all(12)
	rim.anti_aliasing = true
	draw_style_box(rim, Rect2(Vector2(0, top - 4), Vector2(size.x, 22)))
	# Cinta con el nombre.
	var ribbon := StyleBoxFlat.new()
	ribbon.bg_color = stripe
	ribbon.border_color = stripe.darkened(0.35)
	ribbon.set_border_width_all(3)
	ribbon.border_width_bottom = 6
	ribbon.set_corner_radius_all(16)
	ribbon.anti_aliasing = true
	var font := get_theme_default_font()
	var text_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 44.0
	var ribbon_width := clampf(text_width, 120.0, size.x)
	draw_style_box(ribbon, Rect2(Vector2((size.x - ribbon_width) * 0.5, 0), Vector2(ribbon_width, RIBBON_HEIGHT)))


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		tapped.emit()
		accept_event()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = not disabled and accepts.is_valid() and accepts.call(data)
	if ok != highlighted:
		highlighted = ok
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	highlighted = false
	if on_drop.is_valid():
		on_drop.call(data)


func _notification(what: int) -> void:
	if (what == NOTIFICATION_DRAG_END or what == NOTIFICATION_MOUSE_EXIT) and highlighted:
		highlighted = false

class_name DangerMeterView
extends Control
## Medidor de peligro (RN-13): segmentos que se llenan con cada acierto y se vacían con cada
## error. Todos toman el color del momento (verde lejos del peligro, rojo muy cerca), así que
## se lee por la cantidad y por el color. Un icono dice quién acecha: Atoq, Coco o el río.

const SEGMENT_HEIGHT := 22.0
const GAP := 6.0
const COLORS := [Color("#D1495B"), Color("#F28C28"), Color("#F2C14E"), Color("#2E9E5B")]
const LINE := Color("#5A2E16")

## fox, caiman o river.
var icon: StringName = &"fox"
## Ancho de cada segmento (más angosto en la columna de la mecánica clásica).
var segment_width := 30.0:
	set(value):
		segment_width = value
		_resize()
var _value := 2
var _maximum := 4
var _shown := 2.0
var _time := 0.0
var _flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize()


func set_value(value: int, maximum: int, animate: bool = true) -> void:
	_flash = 1.0 if animate and value < _value else _flash
	_value = value
	_maximum = maxi(1, maximum)
	if not animate:
		_shown = value
	_resize()


func _resize() -> void:
	custom_minimum_size = Vector2(56.0 + _maximum * (segment_width + GAP) + 10.0, 46.0)
	size = custom_minimum_size


func _process(delta: float) -> void:
	_time += delta
	_shown = move_toward(_shown, float(_value), delta * 4.0)
	_flash = maxf(0.0, _flash - delta * 1.8)
	queue_redraw()


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#FFF8EC")
	panel.border_color = LINE
	panel.set_border_width_all(3)
	panel.border_width_bottom = 5
	panel.set_corner_radius_all(23)
	draw_style_box(panel, box)
	var level := clampi(int(ceil(_shown)), 1, COLORS.size()) if _maximum == COLORS.size() \
		else clampi(int(ceil(_shown * COLORS.size() / _maximum)), 1, COLORS.size())
	var color: Color = COLORS[level - 1]
	if _flash > 0.0:
		color = color.lerp(Color.WHITE, 0.5 * absf(sin(_flash * 12.0)))
	var danger_pulse := 0.5 + 0.5 * sin(_time * 7.0) if _value <= 1 else 0.0
	_draw_icon(Vector2(26.0, size.y * 0.5), danger_pulse)
	for index in _maximum:
		var rect := Rect2(Vector2(52.0 + index * (segment_width + GAP), (size.y - SEGMENT_HEIGHT) * 0.5), Vector2(segment_width, SEGMENT_HEIGHT))
		var fill := clampf(_shown - index, 0.0, 1.0)
		var slot := StyleBoxFlat.new()
		slot.bg_color = Color("#EADCC8")
		slot.set_corner_radius_all(8)
		draw_style_box(slot, rect)
		if fill > 0.0:
			var bar := StyleBoxFlat.new()
			bar.bg_color = color
			bar.set_corner_radius_all(8)
			bar.border_color = color.darkened(0.3)
			bar.border_width_bottom = 3
			draw_style_box(bar, Rect2(rect.position, Vector2(rect.size.x * fill, rect.size.y)))
			draw_line(rect.position + Vector2(6, 5), rect.position + Vector2(rect.size.x * fill - 6, 5), Color(1, 1, 1, 0.45), 2.0)


func _draw_icon(center: Vector2, pulse: float) -> void:
	if pulse > 0.0:
		draw_circle(center, 21.0 + pulse * 3.0, Color(0.82, 0.29, 0.36, 0.25 * pulse))
	match icon:
		&"caiman":
			draw_rect(Rect2(center + Vector2(-17, -4), Vector2(30, 13)), Color("#4FA35A"))
			draw_circle(center + Vector2(6, -6), 7.0, Color("#4FA35A"))
			draw_circle(center + Vector2(7, -7), 3.6, Color.WHITE)
			draw_circle(center + Vector2(6, -6.5), 2.0, Color("#1E2A1C"))
			for i in 4:
				draw_colored_polygon(PackedVector2Array([center + Vector2(-14 + i * 7, 3), center + Vector2(-11 + i * 7, 7), center + Vector2(-8 + i * 7, 3)]), Color.WHITE)
		&"river":
			for row in 3:
				var points := PackedVector2Array()
				for i in 9:
					points.append(center + Vector2(-16 + i * 4, -8 + row * 8 + sin(i * 1.4 + _time * 3.0) * 2.0))
				draw_polyline(points, Color("#3E8FB0"), 3.0, true)
		_:
			var head := PackedVector2Array([center + Vector2(-15, -5), center + Vector2(-13, -16), center + Vector2(-5, -8),
				center + Vector2(5, -8), center + Vector2(13, -16), center + Vector2(15, -5), center + Vector2(0, 14)])
			draw_colored_polygon(head, Color("#C9682F"))
			draw_colored_polygon(PackedVector2Array([center + Vector2(-9, 2), center + Vector2(9, 2), center + Vector2(0, 14)]), Color("#F6EAD8"))
			draw_circle(center + Vector2(0, 12), 3.0, Color("#2E211B"))
			draw_circle(center + Vector2(-6, -2), 2.2, Color("#2E211B"))
			draw_circle(center + Vector2(6, -2), 2.2, Color("#2E211B"))
			head.append(head[0])
			draw_polyline(head, LINE, 2.0, true)

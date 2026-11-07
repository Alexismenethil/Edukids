class_name StarShape
extends Control
## Estrella dibujada con código: dorada si se ganó, vacía si no. Brilla al aparecer.

const GOLD := Color("#F2C14E")
const GOLD_DEEP := Color("#C48A12")
const EMPTY := Color("#EFE4D3")
const EMPTY_LINE := Color("#C9B79F")

var earned := false:
	set(value):
		earned = value
		queue_redraw()
var shine := 0.0:
	set(value):
		shine = value
		queue_redraw()


func _init(diameter: float = 96.0) -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := size * 0.5
	var outer := minf(size.x, size.y) * 0.5 - 4.0
	var points := PackedVector2Array()
	for index in 10:
		var angle := -PI * 0.5 + index * PI / 5.0
		var radius := outer if index % 2 == 0 else outer * 0.47
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	if earned and shine > 0.0:
		draw_circle(center, outer * (1.1 + shine * 0.35), Color(1.0, 0.92, 0.6, 0.35 * shine))
	draw_colored_polygon(points, GOLD if earned else EMPTY)
	if earned:
		var inner := PackedVector2Array()
		for point in points:
			inner.append(center + (point - center) * 0.55 + Vector2(-outer * 0.08, -outer * 0.1))
		draw_colored_polygon(inner, Color(1, 1, 1, 0.28))
	points.append(points[0])
	draw_polyline(points, GOLD_DEEP if earned else EMPTY_LINE, 4.0, true)

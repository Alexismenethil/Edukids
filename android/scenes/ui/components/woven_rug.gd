class_name WovenRug
extends Node2D
## Tapete tejido (aguayo) en forma de óvalo, donde se para un avatar. Se dibuja con código.

const STRIPES := [Color("#C2185B"), Color("#F28C28"), Color("#1FA2A6"), Color("#F2C14E"), Color("#3B7DD8")]
const OUTLINE := Color("#5A2E16")

@export var radius := Vector2(92, 22)
## Primer color de las franjas; cambia el carácter de cada tapete.
@export var palette_shift := 0:
	set(value):
		palette_shift = value
		queue_redraw()
@export var highlighted := false:
	set(value):
		highlighted = value
		queue_redraw()


func _draw() -> void:
	var rings := 5
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, radius.y / radius.x))
	if highlighted:
		draw_circle(Vector2.ZERO, radius.x + 16.0, Color(1.0, 0.95, 0.7, 0.55))
	draw_circle(Vector2(0, 6.0 * radius.x / radius.y), radius.x + 2.0, Color(0.2, 0.12, 0.05, 0.18))
	draw_circle(Vector2.ZERO, radius.x + 3.0, OUTLINE)
	for ring in rings:
		var r := radius.x * (1.0 - ring / float(rings))
		draw_circle(Vector2.ZERO, r, STRIPES[(ring + palette_shift) % STRIPES.size()])
	# Rombos en la franja exterior.
	var count := 18
	for i in count:
		var angle := TAU * i / count
		var center := Vector2(cos(angle), sin(angle)) * radius.x * 0.9
		var size := 6.0
		var points := PackedVector2Array([center + Vector2(0, -size), center + Vector2(size, 0), center + Vector2(0, size), center + Vector2(-size, 0)])
		draw_colored_polygon(points, Color("#FFF1DA"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

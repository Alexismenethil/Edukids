class_name KnotSprite
extends Node2D
## Un nudo de quipu: bolita de cuerda con su vuelta y una puntita colgando.

var color := Color("#E8833A")
var radius := 11.0


func _draw() -> void:
	var line := color.darkened(0.45)
	draw_line(Vector2(0, radius * 0.6), Vector2(radius * 0.3, radius * 2.0), line, 4.0, true)
	draw_circle(Vector2.ZERO, radius + 2.0, line, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius, color, true, -1.0, true)
	draw_arc(Vector2.ZERO, radius * 0.55, -0.6, 2.4, 10, color.lightened(0.35), 3.0, true)
	draw_line(Vector2(-radius * 0.7, -radius * 0.2), Vector2(radius * 0.7, radius * 0.3), line, 2.0, true)

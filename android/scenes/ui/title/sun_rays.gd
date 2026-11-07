class_name SunRays
extends Node2D
## Rayos de sol suaves que giran lentamente detrás del logotipo. Se dibujan sin texturas.

@export var ray_count := 16
@export var radius := 1150.0
@export var color := Color(1.0, 0.98, 0.86, 0.22)
@export var speed := 0.03


func _process(delta: float) -> void:
	rotation += speed * delta


func _draw() -> void:
	var step := TAU / ray_count
	var outer := Color(color, 0.0)
	for i in ray_count:
		var angle := i * step
		var points := PackedVector2Array([
			Vector2.ZERO,
			Vector2.from_angle(angle - step * 0.2) * radius,
			Vector2.from_angle(angle + step * 0.2) * radius,
		])
		draw_polygon(points, PackedColorArray([color, outer, outer]))

class_name QuipuProp
extends Node2D
## El quipu de los saberes: una cuerda madre con cuerdas de colores que cuelgan y sus nudos. Se
## mece solo. Puede seguir a un personaje (`hold`) y soltar sus nudos (`take_knots`).

const CORDS := [Color("#E8833A"), Color("#3B7DD8"), Color("#3FA34D"), Color("#C2185B"), Color("#F2C14E"), Color("#22AEB2")]
const ROPE := Color("#C9A26B")
const ROPE_LINE := Color("#7A5A32")

## Ancho de la cuerda madre.
var width := 150.0
## Largo de las cuerdas que cuelgan.
var drop := 92.0
## Se ven los nudos (falso después de que vuelan).
var knotted := true:
	set(value):
		knotted = value
		queue_redraw()
## Cuánto se agita (sube cuando lo jalan).
var flutter := 1.0

var _time := 0.0
var _holder: Node2D
var _offset := Vector2.ZERO


## Sigue a un nodo con un desplazamiento (en el espacio del padre del quipu).
func hold(holder: Node2D, offset: Vector2) -> void:
	_holder = holder
	_offset = offset


func release() -> void:
	_holder = null


## Posiciones de los nudos, en el espacio del padre (para hacerlos volar desde ahí).
func knot_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for cord in CORDS.size():
		for knot in 2:
			points.append(position + _cord_point(cord, 0.45 + knot * 0.38))
	return points


func knot_color(index: int) -> Color:
	return CORDS[(index / 2) % CORDS.size()]


func _process(delta: float) -> void:
	_time += delta
	if _holder and is_instance_valid(_holder):
		position = _holder.position + _offset
	queue_redraw()


func _cord_point(cord: int, t: float) -> Vector2:
	var x := -width * 0.5 + width * (cord + 0.5) / CORDS.size()
	var swing := sin(_time * 2.0 + cord * 0.9) * 7.0 * flutter * t
	return Vector2(x + swing, 6.0 + drop * t * (0.82 + 0.18 * sin(cord * 2.1 + 1.0)))


func _draw() -> void:
	for cord in CORDS.size():
		var line := PackedVector2Array()
		for i in 9:
			line.append(_cord_point(cord, i / 8.0))
		draw_polyline(line, CORDS[cord].darkened(0.45), 7.0, true)
		draw_polyline(line, CORDS[cord], 4.0, true)
		if knotted:
			for knot in 2:
				var at := _cord_point(cord, 0.45 + knot * 0.38)
				draw_circle(at, 8.5, CORDS[cord].darkened(0.45), true, -1.0, true)
				draw_circle(at, 6.5, CORDS[cord], true, -1.0, true)
				draw_circle(at + Vector2(-2, -2), 2.2, CORDS[cord].lightened(0.45), true, -1.0, true)
	var rope := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		rope.append(Vector2(lerpf(-width * 0.5 - 8.0, width * 0.5 + 8.0, t), 4.0 * sin(t * PI) + 1.5 * sin(_time * 2.4 + t * 5.0) * flutter))
	draw_polyline(rope, ROPE_LINE, 11.0, true)
	draw_polyline(rope, ROPE, 7.0, true)

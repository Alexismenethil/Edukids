class_name QuipuProgress
extends Control
## Avance del nivel como un quipu: una cuerda principal con un nudo colgante por pregunta.
## Verde con ✓ si acertó, coral con un hueco si volverá al final, dorado si la corrigió en el
## repaso y gris si no salió; la pregunta actual brilla con el color del área. En el desafío
## final, las respondidas quedan lilas hasta entregar.

const CORD := Color("#7A4A2A")
const STEP := 40.0
const KNOT := 13.0
const DROP := 32.0

var accent := ActivityStyle.PRIMARY
## Distancia entre nudos (más corta en la calificación del desafío final).
var step := STEP
var states: Array[StringName] = []
var _pulse := 0.0
var _flash := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_states(new_states: Array[StringName]) -> void:
	for index in new_states.size():
		if index < states.size() and states[index] != new_states[index] and new_states[index] != &"pending":
			_flash[index] = 1.0
	states = new_states.duplicate()
	custom_minimum_size = Vector2(maxf(step * states.size() + 30.0, 120.0), 72.0)
	queue_redraw()


func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta * 2.4, TAU)
	for index: int in _flash.keys():
		_flash[index] = maxf(0.0, _flash[index] - delta * 1.6)
		if _flash[index] <= 0.0:
			_flash.erase(index)
	queue_redraw()


func _draw() -> void:
	if states.is_empty():
		return
	var start := Vector2(10.0, 14.0)
	var finish := Vector2(size.x - 10.0, 14.0)
	draw_line(start, finish, CORD.darkened(0.3), 8.0, true)
	draw_line(start, finish, CORD, 5.0, true)
	var x := start.x + 6.0
	while x < finish.x - 4.0:
		draw_line(Vector2(x, 11.5), Vector2(x + 4.0, 16.5), CORD.lightened(0.35), 1.6, true)
		x += 7.0
	var first := (size.x - step * (states.size() - 1)) * 0.5
	for index in states.size():
		var top := Vector2(first + index * step, 14.0)
		var knot := top + Vector2(0.0, DROP)
		var state := states[index]
		var thread := CORD.lightened(0.15) if state == &"pending" else _color(state)
		draw_line(top, knot + Vector2(0, 14.0), thread.darkened(0.2), 3.0, true)
		var radius := KNOT
		if state == &"current":
			radius += 2.0 + sin(_pulse) * 1.5
			draw_circle(knot, radius + 7.0, Color(accent, 0.22 + 0.1 * sin(_pulse)))
		var flash: float = _flash.get(index, 0.0)
		if flash > 0.0:
			radius += flash * 6.0
			draw_circle(knot, radius + 10.0 * flash, Color(1.0, 0.95, 0.7, 0.5 * flash))
		_knot(knot, radius, state)


func _color(state: StringName) -> Color:
	match state:
		&"current":
			return accent
		&"right":
			return ActivityStyle.SUCCESS
		&"missed":
			return ActivityStyle.ERROR
		&"fixed":
			return Color("#E0A526")
		&"wrong":
			return ActivityStyle.MUTED
		&"answered":
			return Color("#8B7AC0")
	return ActivityStyle.CREAM


func _knot(at: Vector2, radius: float, state: StringName) -> void:
	var fill := _color(state)
	draw_set_transform(at, 0.0, Vector2(1.0, 0.86))
	draw_circle(Vector2.ZERO, radius + 2.0, ActivityStyle.BROWN)
	draw_circle(Vector2.ZERO, radius, fill)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Vuelta del nudo.
	draw_arc(at + Vector2(0, 1), radius * 0.62, PI * 1.1, PI * 1.9, 8, Color(1, 1, 1, 0.45), 2.0, true)
	match state:
		&"right", &"fixed":
			draw_polyline(PackedVector2Array([at + Vector2(-5, 0), at + Vector2(-1.5, 4), at + Vector2(5.5, -4)]),
				Color.WHITE, 2.6, true)
		&"missed":
			draw_circle(at, 3.6, ActivityStyle.CREAM)
		&"answered":
			draw_circle(at, 3.2, Color.WHITE)
		&"wrong":
			draw_line(at + Vector2(-4, -4), at + Vector2(4, 4), Color.WHITE, 2.4, true)
			draw_line(at + Vector2(4, -4), at + Vector2(-4, 4), Color.WHITE, 2.4, true)

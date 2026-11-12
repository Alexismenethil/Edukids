class_name LivesHud
extends Control
## Vidas del nivel (RN-14): corazones grandes que laten. Al perder una vida, el corazón se
## parte en dos, cae y deja un hueco gris. No depende solo del color: el corazón perdido
## queda vacío y con borde punteado.

const SIZE := 34.0
const GAP := 10.0
const FULL := Color("#E8475F")
const DEEP := Color("#9E1F3A")
const EMPTY := Color("#EFE4D6")
const EMPTY_LINE := Color("#B9A894")

var _lives := 3
var _maximum := 3
var _time := 0.0
## Corazones que se están rompiendo: índice → segundos desde que empezó.
var _breaking := {}
var _pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resize()


func set_lives(lives: int, maximum: int) -> void:
	_lives = lives
	_maximum = maximum
	_resize()
	queue_redraw()


## Rompe el último corazón lleno.
func lose_one() -> void:
	Sounds.play(&"life")
	if _lives <= 0:
		return
	_lives -= 1
	_breaking[_lives] = 0.0


## Late una vez (por ejemplo, al empezar o al terminar con todas las vidas).
func beat() -> void:
	_pulse = 1.0


func _resize() -> void:
	custom_minimum_size = Vector2(_maximum * (SIZE + GAP), SIZE + 8.0)
	size = custom_minimum_size


func _process(delta: float) -> void:
	_time += delta
	_pulse = maxf(0.0, _pulse - delta * 2.5)
	for index: int in _breaking.keys():
		_breaking[index] += delta
		if _breaking[index] > 1.4:
			_breaking.erase(index)
	queue_redraw()


func _draw() -> void:
	for index in _maximum:
		var center := Vector2(index * (SIZE + GAP) + SIZE * 0.5, SIZE * 0.5 + 4.0)
		if _breaking.has(index):
			_draw_breaking(center, _breaking[index])
		elif index < _lives:
			var beat := 1.0 + 0.06 * maxf(0.0, sin(_time * 3.2 - index * 0.5)) + 0.18 * _pulse
			if _lives == 1:
				beat += 0.08 * absf(sin(_time * 6.0))
			_draw_heart(center, SIZE * beat, FULL, DEEP, true)
		else:
			_draw_heart(center, SIZE * 0.92, EMPTY, EMPTY_LINE, false)


func _draw_breaking(center: Vector2, t: float) -> void:
	var shake := Vector2(sin(t * 70.0) * 3.0, 0.0) if t < 0.25 else Vector2.ZERO
	if t < 0.25:
		_draw_heart(center + shake, SIZE * (1.0 + t), FULL, DEEP, true)
		return
	var fall := t - 0.25
	var alpha := clampf(1.0 - fall / 1.1, 0.0, 1.0)
	_draw_heart(center, SIZE * 0.92, Color(EMPTY, 1.0 - alpha), Color(EMPTY_LINE, 1.0 - alpha), false)
	for side in [-1.0, 1.0]:
		var offset := Vector2(side * (6.0 + fall * 40.0), fall * fall * 160.0)
		draw_set_transform(center + offset, side * fall * 1.6, Vector2.ONE)
		var points := _half(side)
		draw_colored_polygon(points, Color(FULL, alpha))
		points.append(points[0])
		draw_polyline(points, Color(DEEP, alpha), 2.5, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_heart(center: Vector2, width: float, fill: Color, line: Color, shiny: bool) -> void:
	var points := _heart_points(width)
	for i in points.size():
		points[i] += center
	draw_colored_polygon(points, fill)
	var outline := points.duplicate()
	outline.append(points[0])
	if shiny:
		draw_polyline(outline, line, 3.0, true)
		draw_circle(center + Vector2(-width * 0.2, -width * 0.12), width * 0.09, Color(1, 1, 1, 0.75))
		draw_circle(center + Vector2(-width * 0.08, -width * 0.2), width * 0.045, Color(1, 1, 1, 0.6))
	else:
		for i in range(0, outline.size() - 1, 2):
			draw_line(outline[i], outline[i + 1], line, 2.5, true)


## Corazón clásico (curva paramétrica), centrado y de ancho `width`.
static func _heart_points(width: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 40:
		points.append(_heart_at(TAU * i / 40.0, width))
	return points


static func _heart_at(t: float, width: float) -> Vector2:
	var x := 16.0 * pow(sin(t), 3)
	var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
	return Vector2(x, y + 1.5) * (width / 34.0)


## Una mitad del corazón partido: el lóbulo de su lado y la grieta en zigzag del centro.
## La mitad derecha baja por su lóbulo y sube por la grieta; la izquierda, al revés.
func _half(side: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var start := 0.0 if side > 0.0 else PI
	for i in 21:
		points.append(_heart_at(start + PI * i / 20.0, SIZE))
	var crack: Array[Vector2] = [Vector2(0, 15), Vector2(3, 9), Vector2(-2, 3), Vector2(2, -3)]
	if side < 0.0:
		crack.reverse()
	for point in crack:
		points.append(point * (SIZE / 34.0))
	return points

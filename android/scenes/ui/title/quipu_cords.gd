class_name QuipuCords
extends Node2D
## Quipu del logotipo: una soga principal con cuerdas colgantes de colores y nudos que se mecen.
## Naranja = números, azul = palabras y verde = naturaleza. Los nudos pueden salir volando
## (la travesura de Atoq) y volver a su lugar.

const CORD_COLORS: Array[Color] = [Color("#E8833A"), Color("#3B7DD8"), Color("#3FA34D")]
const OUTLINE := Color("#4A2618")
const ROPE := Color("#D9B98C")
const ROPE_DARK := Color("#A9824F")
const LENGTHS: Array[float] = [54.0, 80.0, 64.0, 92.0, 70.0, 88.0, 62.0, 82.0, 56.0]
const KNOTS: Array = [[0.62], [0.4, 0.78], [0.5, 0.84], [0.3, 0.56, 0.86], [0.45, 0.8], [0.34, 0.62, 0.9], [0.52, 0.84], [0.42, 0.76], [0.66]]
const TRAIL_LENGTH := 9

@export var half_width := 236.0
@export var sag := 9.0

## De 0 a 1: las cuerdas se desenrollan al entrar la pantalla.
var reveal := 1.0

var _time := 0.0
var _cords: Array[Dictionary] = []
var _knots: Array[Dictionary] = []


func _ready() -> void:
	for i in LENGTHS.size():
		var x := lerpf(-half_width + 26.0, half_width - 26.0, float(i) / float(LENGTHS.size() - 1))
		_cords.append({"x": x, "length": LENGTHS[i], "color": CORD_COLORS[i % CORD_COLORS.size()], "phase": i * 0.73})
		for t: float in KNOTS[i]:
			_knots.append({"cord": i, "t": t, "state": &"attached", "pos": Vector2.ZERO, "pop": 0.0, "trail": PackedVector2Array()})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Los nudos salen volando hacia los destinos indicados (coordenadas locales).
func scatter_knots(targets: Array[Vector2]) -> void:
	for i in _knots.size():
		var knot: Dictionary = _knots[i]
		if knot["state"] != &"attached":
			continue
		var start := _cord_point(_cords[knot["cord"]], knot["t"])
		var end := targets[i % targets.size()] + Vector2(randf_range(-90.0, 90.0), randf_range(-60.0, 60.0))
		var control := (start + end) * 0.5 + Vector2(randf_range(-120.0, 120.0), -randf_range(160.0, 300.0))
		knot["state"] = &"flying"
		knot["trail"] = PackedVector2Array()
		var tween := create_tween()
		tween.tween_interval(i * 0.045)
		tween.tween_method(_fly.bind(knot, start, control, end), 0.0, 1.0, randf_range(0.9, 1.25)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(func() -> void: knot["state"] = &"gone")


## Los nudos regresan a sus cuerdas con un pequeño destello.
func return_knots() -> void:
	for i in _knots.size():
		var knot: Dictionary = _knots[i]
		if knot["state"] == &"attached":
			continue
		var from: Vector2 = knot["pos"] if knot["state"] == &"gone" else knot["pos"]
		knot["state"] = &"returning"
		knot["trail"] = PackedVector2Array()
		var tween := create_tween()
		tween.tween_interval(i * 0.05)
		tween.tween_method(_come_back.bind(knot, from), 0.0, 1.0, randf_range(0.8, 1.1)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void:
			knot["state"] = &"attached"
			knot["pop"] = 1.0)
		tween.tween_method(func(value: float) -> void: knot["pop"] = value, 1.0, 0.0, 0.35)


func has_loose_knots() -> bool:
	return _knots.any(func(knot: Dictionary) -> bool: return knot["state"] != &"attached")


func _fly(progress: float, knot: Dictionary, start: Vector2, control: Vector2, end: Vector2) -> void:
	var a := start.lerp(control, progress)
	var b := control.lerp(end, progress)
	_move_knot(knot, a.lerp(b, progress))


func _come_back(progress: float, knot: Dictionary, from: Vector2) -> void:
	var target := _cord_point(_cords[knot["cord"]], knot["t"])
	var control := (from + target) * 0.5 + Vector2(0.0, -220.0)
	var a := from.lerp(control, progress)
	var b := control.lerp(target, progress)
	_move_knot(knot, a.lerp(b, progress))


func _move_knot(knot: Dictionary, position_now: Vector2) -> void:
	var trail: PackedVector2Array = knot["trail"]
	trail.append(position_now)
	if trail.size() > TRAIL_LENGTH:
		trail.remove_at(0)
	knot["trail"] = trail
	knot["pos"] = position_now


func _rope_y(x: float) -> float:
	var u := clampf(x / half_width, -1.0, 1.0)
	return sag * (1.0 - u * u)


func _cord_point(cord: Dictionary, t: float) -> Vector2:
	var length: float = cord["length"] * reveal
	var phase: float = cord["phase"]
	var sway := 7.0 * pow(t, 1.4) * sin(_time * 1.6 + phase) + 2.0 * t * sin(_time * 3.3 + phase * 1.7)
	return Vector2(cord["x"] + sway, _rope_y(cord["x"]) + t * length)


func _draw() -> void:
	if reveal <= 0.0:
		return
	for cord in _cords:
		var points := PackedVector2Array()
		for j in 10:
			points.append(_cord_point(cord, j / 9.0))
		draw_polyline(points, OUTLINE, 8.5, true)
		draw_polyline(points, cord["color"], 4.5, true)
		var tip := points[points.size() - 1]
		draw_circle(tip, 4.6, OUTLINE, true, -1.0, true)
		draw_circle(tip, 3.0, cord["color"], true, -1.0, true)

	var rope := PackedVector2Array()
	for k in 31:
		var x := lerpf(-half_width - 16.0, half_width + 16.0, k / 30.0)
		rope.append(Vector2(x, _rope_y(x)))
	draw_polyline(rope, OUTLINE, 14.0, true)
	draw_polyline(rope, ROPE, 8.5, true)
	for k in range(1, 44):
		var x := lerpf(-half_width - 10.0, half_width + 10.0, k / 44.0)
		var y := _rope_y(x)
		draw_line(Vector2(x - 2.6, y - 3.4), Vector2(x + 2.6, y + 3.4), ROPE_DARK, 2.0, true)
	for side in [-1.0, 1.0]:
		var end := Vector2((half_width + 18.0) * side, _rope_y(half_width) + 2.0)
		draw_circle(end, 9.0, OUTLINE, true, -1.0, true)
		draw_circle(end, 6.0, Color("#C2185B"), true, -1.0, true)

	for knot in _knots:
		var cord: Dictionary = _cords[knot["cord"]]
		var color: Color = cord["color"]
		match knot["state"]:
			&"attached":
				if reveal < knot["t"]:
					continue
				_draw_knot(_cord_point(cord, knot["t"]), color, 1.0 + 0.6 * knot["pop"])
				if knot["pop"] > 0.0:
					_draw_sparkle(_cord_point(cord, knot["t"]), 14.0 * knot["pop"] + 6.0, Color(1, 1, 0.85, knot["pop"]))
			&"flying", &"returning":
				var trail: PackedVector2Array = knot["trail"]
				for k in trail.size():
					var fade := float(k + 1) / trail.size()
					draw_circle(trail[k], 4.0 * fade, Color(color, 0.45 * fade), true, -1.0, true)
				if trail.size() > 2:
					_draw_sparkle(trail[0], 6.0, Color(1, 1, 0.9, 0.7))
				_draw_knot(knot["pos"], color, 1.15)


func _draw_knot(at: Vector2, color: Color, size: float) -> void:
	draw_circle(at, 7.5 * size, OUTLINE, true, -1.0, true)
	draw_circle(at, 5.4 * size, color.darkened(0.12), true, -1.0, true)
	draw_circle(at + Vector2(-1.8, -2.0) * size, 1.8 * size, Color(1, 1, 1, 0.8), true, -1.0, true)


func _draw_sparkle(at: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array([
		at + Vector2(0, -size), at + Vector2(size * 0.22, -size * 0.22), at + Vector2(size, 0),
		at + Vector2(size * 0.22, size * 0.22), at + Vector2(0, size), at + Vector2(-size * 0.22, size * 0.22),
		at + Vector2(-size, 0), at + Vector2(-size * 0.22, -size * 0.22),
	])
	draw_colored_polygon(points, color)

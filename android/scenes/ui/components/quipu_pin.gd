class_name QuipuPin
extends Control
## El PIN como un quipu: cada número escrito ata un nudo en una cuerda colgante, sin mostrar
## el número. Si el PIN es incorrecto, el quipu tiembla y los nudos caen; si es correcto,
## los nudos brillan como oro.

const CORD_COLORS := [Color("#E8833A"), Color("#3B7DD8"), Color("#3FA34D"), Color("#C2185B"), Color("#1FA2A6"), Color("#E0A930")]
const ROPE := Color("#7A4A2A")
const ROPE_LIGHT := Color("#B07A4C")
const GOLD := Color("#F7C948")
const SPACING := 66.0
const CORD_LENGTH := 74.0
const KNOT_AT := 46.0
const KNOT_RADIUS := 14.0

@export var slots := 4:
	set(value):
		slots = maxi(value, 1)
		_reset_knots()

var _filled := 0
var _scales: Array[float] = []
var _drops: Array[float] = []
var _glow := 0.0
var _shake := 0.0
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_knots()


func _get_minimum_size() -> Vector2:
	return Vector2(slots * SPACING + 40.0, CORD_LENGTH + 46.0)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Muestra n nudos atados; el último aparece con un pequeño rebote.
func set_filled(count: int) -> void:
	count = clampi(count, 0, slots)
	for i in slots:
		if i < count and i >= _filled:
			_drops[i] = 0.0
			_pop(i)
		elif i >= count:
			_scales[i] = 0.0
	_filled = count


## PIN incorrecto: el quipu tiembla y los nudos se sueltan y caen.
func shake_and_drop() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_method(func(value: float) -> void: _shake = value, 1.0, 0.0, 0.5)
	for i in _filled:
		tween.tween_method(_set_drop.bind(i), 0.0, 1.0, 0.45).set_delay(0.12 + i * 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void:
		_filled = 0
		for i in slots:
			_scales[i] = 0.0
			_drops[i] = 0.0)


## PIN correcto: los nudos brillan uno tras otro.
func shine() -> void:
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void: _glow = value, 0.0, 1.0, 0.35)
	for i in _filled:
		tween.parallel().tween_method(_set_scale.bind(i), 1.0, 1.3, 0.12).set_delay(i * 0.08)
	tween.tween_interval(0.1)
	for i in _filled:
		tween.parallel().tween_method(_set_scale.bind(i), 1.3, 1.0, 0.25).set_trans(Tween.TRANS_BACK)


func _reset_knots() -> void:
	_scales.resize(slots)
	_scales.fill(0.0)
	_drops.resize(slots)
	_drops.fill(0.0)
	_filled = mini(_filled, slots)
	update_minimum_size()


func _pop(index: int) -> void:
	var tween := create_tween()
	tween.tween_method(_set_scale.bind(index), 0.0, 1.3, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_scale.bind(index), 1.3, 1.0, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _set_scale(value: float, index: int) -> void:
	if index < _scales.size():
		_scales[index] = value


func _set_drop(value: float, index: int) -> void:
	if index < _drops.size():
		_drops[index] = value


func _draw() -> void:
	var width := size.x
	var top := 18.0
	var shake_x := sin(_time * 60.0) * 10.0 * _shake
	var left := Vector2(14.0 + shake_x, top)
	var right := Vector2(width - 14.0 + shake_x, top)
	# Cuerda principal con su torcido.
	var rope := PackedVector2Array()
	for step in 25:
		var t := step / 24.0
		var point := left.lerp(right, t)
		point.y += sin(t * PI) * 8.0
		rope.append(point)
	draw_polyline(rope, ROPE, 10.0, true)
	for step in range(1, 24):
		var a := rope[step]
		draw_line(a + Vector2(-3, -3), a + Vector2(3, 3), ROPE_LIGHT, 2.5, true)
	draw_circle(left, 7.0, ROPE)
	draw_circle(right, 7.0, ROPE)
	# Cuerdas colgantes con su nudo.
	var first_x := width * 0.5 - (slots - 1) * SPACING * 0.5
	for i in slots:
		var x := first_x + i * SPACING + shake_x
		var t := clampf((x - left.x) / maxf(right.x - left.x, 1.0), 0.0, 1.0)
		var anchor := Vector2(x, top + sin(t * PI) * 8.0)
		var sway := sin(_time * 1.6 + i * 0.9) * 0.05
		var direction := Vector2(sin(sway), cos(sway))
		var color: Color = CORD_COLORS[i % CORD_COLORS.size()]
		var tip := anchor + direction * CORD_LENGTH
		draw_line(anchor, tip, color.darkened(0.25), 7.0, true)
		draw_line(anchor, tip, color, 4.0, true)
		draw_circle(tip, 4.0, color.darkened(0.25))
		var knot := anchor + direction * KNOT_AT
		if _scales[i] <= 0.01:
			_draw_empty_slot(knot, color)
			continue
		var fall := _drops[i]
		var center := knot + Vector2(0, fall * 90.0)
		var alpha := 1.0 - fall
		var radius := KNOT_RADIUS * _scales[i]
		var fill := color.lerp(GOLD, _glow)
		if _glow > 0.0:
			draw_circle(center, radius + 9.0 * _glow, Color(GOLD, 0.35 * _glow * alpha))
		draw_circle(center, radius + 3.0, Color(color.darkened(0.45), alpha))
		draw_circle(center, radius, Color(fill, alpha))
		draw_arc(center, radius * 0.62, PI * 1.05, PI * 1.6, 8, Color(1, 1, 1, 0.65 * alpha), 3.0, true)
		draw_line(center + Vector2(-radius * 0.7, 0), center + Vector2(radius * 0.7, 0), Color(color.darkened(0.45), 0.5 * alpha), 2.0, true)


func _draw_empty_slot(at: Vector2, color: Color) -> void:
	var dots := 10
	for d in dots:
		var angle := TAU * d / dots + _time * 0.6
		draw_circle(at + Vector2(cos(angle), sin(angle)) * 11.0, 2.0, Color(color, 0.45))

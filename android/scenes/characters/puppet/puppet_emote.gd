class_name PuppetEmote
extends Node2D
## Un emote que aparece sobre la cabeza de un personaje: corazón, signo de sorpresa, pregunta,
## nota musical, estrella de idea, zzz, gota de apuro, marca de enojo, estrellas de mareo y
## brillitos. Se dibuja por código (vector limpio) y se borra solo.

const OUTLINE := Color("#3A2418")
const PAPER := Color("#FFFDF6")
const BUBBLE_KINDS: Array[StringName] = [&"heart", &"alert", &"question", &"note", &"idea"]

var kind: StringName = &"heart"
var life := 1.4
## Tamaño del emote (1 = burbuja de 34 px de radio).
var size := 1.0

var _age := 0.0
var _font: Font


func _ready() -> void:
	z_index = 20
	_font = ThemeDB.get_project_theme().get_font("font", &"Button") if ThemeDB.get_project_theme() else ThemeDB.fallback_font
	scale = Vector2.ZERO


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	var pop := PuppetEase.apply(&"back", clampf(_age / 0.24, 0.0, 1.0))
	var leave := clampf((life - _age) / 0.22, 0.0, 1.0)
	scale = Vector2.ONE * size * pop * (0.7 + 0.3 * leave)
	modulate.a = leave
	queue_redraw()


func _draw() -> void:
	var bob := sin(_age * 5.0) * 3.0
	if kind in BUBBLE_KINDS:
		_draw_bubble(Vector2(0, bob))
	match kind:
		&"heart":
			var beat := 1.0 + 0.12 * maxf(0.0, sin(_age * 9.0))
			_shape(_heart(Vector2(0, bob - 1.0), 1.25 * beat), Color("#F0566E"), 0.0)
			draw_circle(Vector2(-7, bob - 9.0), 3.2, Color(1, 1, 1, 0.75), true, -1.0, true)
		&"alert":
			_glyph("!", Vector2(0, bob), 50, Color("#F2A51D"))
		&"question":
			_glyph("?", Vector2(0, bob), 46, Color("#3B7DD8"))
		&"note":
			_draw_note(Vector2(0, bob), Color("#C2185B"))
		&"idea":
			_shape(_star(Vector2(0, bob), 20.0, 9.5, 5, _age * 1.2), Color("#F2C14E"), 3.0)
		&"zzz":
			for i in 3:
				var t := fposmod(_age * 0.55 + i * 0.33, 1.0)
				var at := Vector2(10.0 + t * 46.0 + sin(t * TAU) * 6.0, -t * 64.0)
				_glyph("z", at, int(18 + t * 26.0), Color(0.36, 0.6, 0.92, sin(t * PI)), 5)
		&"sweat":
			var fall := fposmod(_age * 0.9, 1.0)
			_shape(_drop(Vector2(0, fall * 34.0), 11.0), Color(0.55, 0.82, 0.97, 1.0 - fall * 0.7), 3.0)
		&"anger":
			var pulse := 1.0 + 0.16 * sin(_age * 14.0)
			for i in 4:
				var angle := TAU * i / 4.0 + PI * 0.25
				var center := Vector2.from_angle(angle) * 15.0 * pulse
				draw_arc(center, 9.0 * pulse, angle + PI * 0.55, angle + PI * 1.45, 10, OUTLINE, 9.0, true)
				draw_arc(center, 9.0 * pulse, angle + PI * 0.55, angle + PI * 1.45, 10, Color("#E5484D"), 5.0, true)
		&"dizzy":
			for i in 3:
				var angle := _age * 5.0 + TAU * i / 3.0
				var at := Vector2(cos(angle) * 44.0, sin(angle) * 11.0)
				var depth := 0.75 + 0.25 * sin(angle)
				_shape(_star(at, 12.0 * depth, 5.5 * depth, 5, angle), Color("#F2C14E"), 2.5)
		&"sparkle":
			for i in 4:
				var t := fposmod(_age * 1.3 + i * 0.27, 1.0)
				var at := Vector2(-48.0 + i * 32.0, -8.0 - 22.0 * sin(i * 2.1)) + Vector2(0, -t * 14.0)
				_shape(_star(at, 15.0 * sin(t * PI), 4.5 * sin(t * PI), 4, 0.0), Color(1.0, 0.95, 0.62, 1.0), 0.0)


func _draw_bubble(center: Vector2) -> void:
	var tail := PackedVector2Array([center + Vector2(-18, 22), center + Vector2(-30, 46), center + Vector2(-2, 31)])
	draw_circle(center, 37.5, OUTLINE, true, -1.0, true)
	draw_colored_polygon(_grow(tail, 4.5), OUTLINE)
	draw_circle(center, 33.5, PAPER, true, -1.0, true)
	draw_colored_polygon(tail, PAPER)


func _glyph(text: String, center: Vector2, font_size: int, color: Color, outline: int = 0) -> void:
	var extent := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var at := center + Vector2(-extent.x * 0.5, _font.get_ascent(font_size) - extent.y * 0.5)
	if outline > 0:
		draw_string_outline(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(PAPER, color.a))
	draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_note(center: Vector2, color: Color) -> void:
	draw_set_transform(center + Vector2(-6, 12), -0.35, Vector2(1.0, 0.72))
	draw_circle(Vector2.ZERO, 9.5, color, true, -1.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(center + Vector2(2, 10), center + Vector2(2, -18), color, 4.5, true)
	draw_colored_polygon(PackedVector2Array([center + Vector2(0, -20), center + Vector2(17, -12),
		center + Vector2(17, -2), center + Vector2(0, -9)]), color)


## Dibuja una forma rellena con su contorno oscuro.
func _shape(points: PackedVector2Array, color: Color, outline: float) -> void:
	if points.size() < 3 or color.a <= 0.01:
		return
	if outline > 0.0:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, Color(OUTLINE, color.a), outline * 2.0, true)
	draw_colored_polygon(points, color)


static func _heart(center: Vector2, scale_factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 28:
		var t := TAU * i / 28.0
		points.append(center + Vector2(16.0 * pow(sin(t), 3.0),
			-(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * scale_factor)
	return points


static func _star(center: Vector2, outer: float, inner: float, tips: int, turn: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if outer < 0.5:
		return points
	for i in tips * 2:
		var radius := outer if i % 2 == 0 else inner
		points.append(center + Vector2.from_angle(turn - PI * 0.5 + PI * i / tips) * radius)
	return points


static func _drop(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array([center + Vector2(0, -radius * 2.1)])
	for i in 13:
		var angle := -PI * 0.2 + PI * 1.4 * i / 12.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


static func _grow(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= points.size()
	var grown := PackedVector2Array()
	for point in points:
		grown.append(point + (point - center).normalized() * amount)
	return grown

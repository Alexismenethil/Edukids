class_name ToonBurst
extends Node2D
## Una ráfaga de formas de caricatura dibujadas por código: nubecitas de polvo, estrellas, gotas,
## hojas, corazones, papel picado, anillos y destellos de golpe. Formas nítidas y colores planos,
## como el resto del juego; un solo nodo por ráfaga para cuidar el rendimiento en la tablet.

enum Shape { PUFF, STAR, SPARK, DROP, LEAF, HEART, PAPER, CHUNK, RING, POW, STREAK }

var _bits: Array[Dictionary] = []
var _alive := true


## Agrega una forma. Claves: shape, pos, vel, gravity, drag, life, size, grow, color, spin, turn,
## delay y fade (desde qué fracción de su vida empieza a desvanecerse).
func add(bit: Dictionary) -> void:
	bit["age"] = -float(bit.get("delay", 0.0))
	_bits.append(bit)


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	var living := 0
	for bit in _bits:
		bit["age"] += delta
		var age: float = bit["age"]
		if age < 0.0:
			living += 1
			continue
		if age >= float(bit["life"]):
			continue
		living += 1
		var velocity: Vector2 = bit.get("vel", Vector2.ZERO)
		velocity.y += float(bit.get("gravity", 0.0)) * delta
		velocity *= maxf(0.0, 1.0 - float(bit.get("drag", 0.0)) * delta)
		bit["vel"] = velocity
		bit["pos"] = (bit["pos"] as Vector2) + velocity * delta
		bit["turn"] = float(bit.get("turn", 0.0)) + float(bit.get("spin", 0.0)) * delta
	if living == 0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	for bit in _bits:
		var age: float = bit["age"]
		var life: float = bit["life"]
		if age < 0.0 or age >= life:
			continue
		var t := age / life
		var fade_from: float = bit.get("fade", 0.6)
		var alpha := 1.0 - clampf((t - fade_from) / maxf(0.001, 1.0 - fade_from), 0.0, 1.0)
		var color: Color = bit["color"]
		color.a *= alpha
		var at: Vector2 = bit["pos"]
		var size := float(bit["size"]) * (1.0 + float(bit.get("grow", 0.0)) * PuppetEase.apply(&"out", t))
		var turn: float = bit.get("turn", 0.0)
		match bit["shape"]:
			Shape.PUFF:
				draw_circle(at, size, color, true, -1.0, true)
				draw_circle(at + Vector2(-size * 0.28, -size * 0.3), size * 0.42, Color(1, 1, 1, 0.35 * color.a), true, -1.0, true)
			Shape.STAR:
				_polygon(_star(at, size, size * 0.46, 5, turn), color, bit.get("outline", Color.TRANSPARENT), alpha)
			Shape.SPARK:
				var twinkle := sin(t * PI)
				_polygon(_star(at, size * twinkle, size * 0.28 * twinkle, 4, turn), color, Color.TRANSPARENT, alpha)
			Shape.DROP:
				var velocity: Vector2 = bit.get("vel", Vector2.DOWN)
				_polygon(_drop(at, size, velocity.angle() + PI * 0.5), color, Color.TRANSPARENT, alpha)
			Shape.LEAF:
				_polygon(_leaf(at, size, turn), color, Color.TRANSPARENT, alpha)
			Shape.HEART:
				_polygon(_heart(at, size / 16.0), color, Color.TRANSPARENT, alpha)
			Shape.PAPER:
				# Papel picado: un rectángulo que gira sobre su eje mientras cae.
				var flip := cos(turn * 2.3)
				var across := Vector2.from_angle(turn) * size
				var down := Vector2.from_angle(turn + PI * 0.5) * size * 0.55 * flip
				_polygon(PackedVector2Array([at - across - down, at + across - down, at + across + down, at - across + down]),
					color.darkened(0.18) if flip < 0.0 else color, Color.TRANSPARENT, alpha)
			Shape.CHUNK:
				_polygon(_star(at, size, size * 0.7, 3, turn), color, Color.TRANSPARENT, alpha)
			Shape.RING:
				var width := maxf(1.0, float(bit.get("width", 8.0)) * (1.0 - t))
				draw_set_transform(at, 0.0, Vector2(1.0, float(bit.get("flat", 1.0))))
				draw_arc(Vector2.ZERO, size, 0.0, TAU, 40, color, width, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			Shape.POW:
				# Destello de golpe: una estrella de muchas puntas que crece y se va.
				var pop := PuppetEase.apply(&"back", clampf(t / 0.35, 0.0, 1.0))
				var burst := _star(at, size * pop, size * 0.56 * pop, 9, turn)
				_polygon(burst, color, bit.get("outline", Color.TRANSPARENT), alpha)
				_polygon(_star(at, size * 0.6 * pop, size * 0.34 * pop, 9, turn + 0.35), Color(1, 1, 1, 0.9 * alpha), Color.TRANSPARENT, alpha)
			Shape.STREAK:
				var direction := Vector2.from_angle(turn)
				var head := at + direction * size * (0.4 + t)
				var tail := at + direction * size * (0.4 + t * 0.35)
				draw_line(tail, head, color, float(bit.get("width", 5.0)) * (1.0 - t * 0.6), true)


func _polygon(points: PackedVector2Array, color: Color, outline: Color, alpha: float) -> void:
	if points.size() < 3 or color.a <= 0.01:
		return
	if outline.a > 0.0:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, Color(outline, outline.a * alpha), 5.0, true)
	draw_colored_polygon(points, color)


static func _star(center: Vector2, outer: float, inner: float, tips: int, turn: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	if outer < 0.6:
		return points
	for i in tips * 2:
		var radius := outer if i % 2 == 0 else inner
		points.append(center + Vector2.from_angle(turn - PI * 0.5 + PI * i / tips) * radius)
	return points


static func _drop(center: Vector2, radius: float, turn: float) -> PackedVector2Array:
	var points := PackedVector2Array([center + Vector2(0, -radius * 2.2).rotated(turn)])
	for i in 9:
		var angle := -PI * 0.15 + PI * 1.3 * i / 8.0
		points.append(center + (Vector2(cos(angle), sin(angle)) * radius).rotated(turn))
	return points


static func _leaf(center: Vector2, size: float, turn: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var angle := TAU * i / 10.0
		points.append(center + Vector2(cos(angle) * size, sin(angle) * size * 0.42 * (1.0 + 0.4 * cos(angle))).rotated(turn))
	return points


static func _heart(center: Vector2, scale_factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 20:
		var t := TAU * i / 20.0
		points.append(center + Vector2(16.0 * pow(sin(t), 3.0),
			-(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * scale_factor)
	return points

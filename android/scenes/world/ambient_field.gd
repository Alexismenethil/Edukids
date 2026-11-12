class_name AmbientField
extends Node2D
## Lo que flota en el aire de la escena: motas de polen que brillan, pétalos de cantuta que caen
## o mariposas. Se dibujan a mano (son baratas) y respetan el paralaje de su profundidad.

enum Kind { MOTES, PETALS, BUTTERFLIES }

var world: ParallaxWorld
var kind := Kind.MOTES
var count := 30
var depth := 0.9
## Franja del mundo (y) donde aparecen.
var band := Vector2(260.0, 720.0)
var colors: PackedColorArray = PackedColorArray([Color("#FFF4C2"), Color("#FFE38A")])

var _items: Array[Dictionary] = []
var _last_cam := 0.0
var _time := 0.0


func setup(field_world: ParallaxWorld, field_kind: Kind, amount: int, field_depth: float, field_band: Vector2,
		palette: PackedColorArray = PackedColorArray()) -> AmbientField:
	world = field_world
	kind = field_kind
	count = amount
	depth = field_depth
	band = field_band
	if not palette.is_empty():
		colors = palette
	return self


func _ready() -> void:
	_last_cam = world.cam_x if world else 0.0
	var view := world.visible_rect() if world else Rect2(0, 0, 1280, 800)
	for i in count:
		_items.append({
			"x": view.position.x + randf() * maxf(view.size.x, 1400.0),
			"y": randf_range(band.x, band.y),
			"phase": randf() * TAU,
			"size": randf_range(0.7, 1.3),
			"speed": randf_range(0.6, 1.4),
			"color": colors[i % colors.size()],
		})


func _process(delta: float) -> void:
	if world == null:
		return
	_time += delta
	var shift := (world.cam_x - _last_cam) * depth
	_last_cam = world.cam_x
	var view := world.visible_rect().grow(60.0)
	for item in _items:
		var speed: float = item["speed"]
		match kind:
			Kind.MOTES:
				item["x"] += -shift + sin(_time * 0.5 + item["phase"]) * 6.0 * delta + 4.0 * delta
				item["y"] += sin(_time * 0.8 + item["phase"] * 1.7) * 7.0 * delta - 3.0 * speed * delta
			Kind.PETALS:
				item["x"] += -shift + (16.0 + sin(_time * 1.3 + item["phase"]) * 26.0) * delta
				item["y"] += 26.0 * speed * delta
			Kind.BUTTERFLIES:
				item["x"] += -shift + sin(_time * 0.7 + item["phase"]) * 40.0 * delta + 10.0 * delta
				item["y"] += cos(_time * 1.1 + item["phase"] * 2.0) * 30.0 * delta
		if item["x"] < view.position.x:
			item["x"] += view.size.x
		elif item["x"] > view.end.x:
			item["x"] -= view.size.x
		if item["y"] > band.y:
			item["y"] = band.x
			item["x"] = view.position.x + randf() * view.size.x
		elif item["y"] < band.x:
			item["y"] = band.y
	queue_redraw()


func _draw() -> void:
	for item in _items:
		var at := Vector2(item["x"], item["y"])
		var size: float = item["size"]
		var color: Color = item["color"]
		match kind:
			Kind.MOTES:
				var twinkle := 0.55 + 0.45 * sin(_time * 2.0 * float(item["speed"]) + float(item["phase"]))
				draw_circle(at, 6.0 * size, Color(color, 0.12 * twinkle), true, -1.0, true)
				draw_circle(at, 2.6 * size, Color(color, 0.75 * twinkle), true, -1.0, true)
			Kind.PETALS:
				var spin := _time * 2.2 * float(item["speed"]) + float(item["phase"])
				draw_set_transform(at, spin, Vector2(1.0, 0.45 + 0.4 * absf(sin(spin))))
				draw_circle(Vector2.ZERO, 5.0 * size, color, true, -1.0, true)
				draw_circle(Vector2(-1.5, -1.0), 2.2 * size, color.lightened(0.35), true, -1.0, true)
				draw_set_transform(Vector2.ZERO)
			Kind.BUTTERFLIES:
				var flap := absf(sin(_time * 14.0 * float(item["speed"]) + float(item["phase"])))
				var wing := Vector2(1.0, 0.25 + 0.75 * flap)
				draw_set_transform(at + Vector2(-5.0 * size, 0), -0.3, wing)
				draw_circle(Vector2.ZERO, 6.0 * size, color, true, -1.0, true)
				draw_set_transform(at + Vector2(5.0 * size, 0), 0.3, wing)
				draw_circle(Vector2.ZERO, 6.0 * size, color, true, -1.0, true)
				draw_set_transform(Vector2.ZERO)
				draw_line(at + Vector2(0, -4.0 * size), at + Vector2(0, 4.0 * size), Color("#4A3A3A"), 2.0, true)

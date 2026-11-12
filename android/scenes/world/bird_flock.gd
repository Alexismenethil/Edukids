class_name BirdFlock
extends Node2D
## Una bandada de pajaritos que cruza el cielo cada tanto, aleteando en formación.

var world: ParallaxWorld
var color := Color("#4C4F70")
## Franja del cielo (y del mundo) por donde pasan.
var band := Vector2(120.0, 300.0)

var _birds: Array[Vector3] = []
var _x := 0.0
var _y := 0.0
var _speed := 90.0
var _flying := false
var _wait := 2.5
var _time := 0.0


func _ready() -> void:
	for i in 7:
		var row := i / 2 + 1
		var side := -1.0 if i % 2 == 0 else 1.0
		_birds.append(Vector3(-row * 26.0, side * row * 13.0 if i > 0 else 0.0, randf() * TAU))


func _process(delta: float) -> void:
	if world == null:
		return
	_time += delta
	var view := world.visible_rect()
	if not _flying:
		_wait -= delta
		if _wait <= 0.0:
			_flying = true
			_x = view.position.x - 120.0
			_y = randf_range(band.x, band.y)
			_speed = randf_range(80.0, 120.0)
	else:
		_x += _speed * delta
		_y += sin(_time * 0.9) * 8.0 * delta
		if _x > view.end.x + 260.0:
			_flying = false
			_wait = randf_range(7.0, 13.0)
	queue_redraw()


func _draw() -> void:
	if not _flying:
		return
	for bird in _birds:
		var at := Vector2(_x + bird.x, _y + bird.y + sin(_time * 2.0 + bird.z) * 3.0)
		var flap := sin(_time * 9.0 + bird.z)
		var tip := 9.0
		var lift := -4.0 - flap * 5.0
		draw_polyline(PackedVector2Array([at + Vector2(-tip, lift), at + Vector2(-3, -1), at,
			at + Vector2(3, -1), at + Vector2(tip, lift)]), color, 2.4, true)

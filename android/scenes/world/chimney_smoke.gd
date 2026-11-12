class_name ChimneySmoke
extends Node2D
## Humo suave que sube de una chimenea: bolitas que crecen, se inclinan con el viento y se
## desvanecen. Ligero: unas pocas bolitas dibujadas con antialias.

@export var color := Color(0.98, 0.96, 0.93, 0.75)
## Segundos entre bolita y bolita.
@export var every := 0.7
## Altura que sube cada bolita antes de desaparecer.
@export var rise := 46.0
## Tamaño de la bolita al salir.
@export var size := 3.2

var _puffs: Array[Vector3] = []
var _wait := 0.0


func _ready() -> void:
	for i in 6:
		_puffs.append(Vector3(randf_range(-2.0, 2.0), 0.0, float(i) / 6.0))


func _process(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_wait = every * randf_range(0.8, 1.2)
		_puffs.append(Vector3(randf_range(-1.5, 1.5), 0.0, 0.0))
	for i in _puffs.size():
		var puff := _puffs[i]
		puff.z += delta / 4.2
		_puffs[i] = puff
	_puffs = _puffs.filter(func(puff: Vector3) -> bool: return puff.z < 1.0)
	queue_redraw()


func _draw() -> void:
	for puff in _puffs:
		var t := puff.z
		var at := Vector2(puff.x + t * t * 26.0 + sin(t * 6.0 + puff.x) * 2.0, -t * rise)
		var tint := Color(color, color.a * (1.0 - t) * minf(1.0, t * 6.0))
		draw_circle(at, size * (1.0 + t * 2.4), tint, true, -1.0, true)

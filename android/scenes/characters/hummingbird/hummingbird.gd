class_name Hummingbird
extends Node2D
## Picaflor que visita las flores de la cantuta: llega, se queda flotando con el pico
## en una flor, salta a otra y se va. Vuelve al rato.

## Boca de cada flor en coordenadas del padre.
@export var flowers: Array[Vector2] = []
@export var outside := Vector2(-140.0, 700.0)
@export var visits_per_trip := 3

const BEAK_TILT := -0.6
## Desde el centro del cuerpo hasta la punta del pico inclinado, con el picaflor a escala 0.68
## (con otra escala se ajusta solo).
const BEAK_REACH := Vector2(-23.5, 21.0)

@onready var _body: Sprite2D = $Body
@onready var _wing: Sprite2D = $Wing

var _time := 0.0
var _hovering := false
var _base_scale := Vector2.ONE


func _ready() -> void:
	_base_scale = scale
	visible = false
	if not flowers.is_empty():
		_trip.call_deferred(4.0)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	# Aleteo muy rápido, como un borrón.
	_wing.scale.y = 0.5 * sin(_time * TAU * 17.0)
	_body.position.y = (2.5 if _hovering else 1.0) * sin(_time * 7.0)
	_wing.position.y = -4.0 + _body.position.y


func _trip(delay: float) -> void:
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		position = outside
		visible = true)
	var order := flowers.duplicate()
	order.shuffle()
	var from := outside
	for i in mini(visits_per_trip, order.size()):
		var mouth: Vector2 = order[i]
		var facing_right := mouth.x >= from.x
		var reach := BEAK_REACH * absf(_base_scale.y) / 0.68
		var target := mouth + Vector2(reach.x * (1.0 if facing_right else -1.0), reach.y)
		tween.tween_callback(_face.bind(facing_right, false))
		tween.tween_property(self, "position", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_face.bind(facing_right, true))
		tween.tween_interval(randf_range(1.2, 2.2))
		from = target
	var away := outside + Vector2(0.0, -160.0)
	tween.tween_callback(_face.bind(away.x >= from.x, false))
	tween.tween_property(self, "position", away, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		visible = false
		_trip(randf_range(9.0, 15.0)))


## Mira hacia un lado; al alimentarse inclina el pico hacia la flor.
func _face(right: bool, feeding: bool) -> void:
	_hovering = feeding
	scale = Vector2(_base_scale.x * (1.0 if right else -1.0), _base_scale.y)
	rotation = (BEAK_TILT if feeding else -0.1) * (1.0 if right else -1.0)

class_name CondorFlight
extends Sprite2D
## Cóndor andino que planea sobre la cordillera de vez en cuando.

@export var start_x := 2080.0
@export var end_x := -160.0
@export var altitude := 470.0
@export var crossing_time := 24.0
@export var pause := 7.0
@export var first_delay := 2.5

var _time := 0.0
var _base_scale := Vector2.ONE


func _ready() -> void:
	_base_scale = scale
	visible = false
	_fly.call_deferred(first_delay)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	position.y = altitude + 26.0 * sin(_time * 0.35) + 6.0 * sin(_time * 1.1)
	rotation = -0.05 + 0.06 * sin(_time * 0.7)
	scale = Vector2(_base_scale.x, _base_scale.y * (1.0 + 0.1 * sin(_time * 1.9)))


func _fly(delay: float) -> void:
	position = Vector2(start_x, altitude)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void: visible = true)
	tween.tween_property(self, "position:x", end_x, crossing_time)
	tween.tween_callback(func() -> void:
		visible = false
		_fly(pause))

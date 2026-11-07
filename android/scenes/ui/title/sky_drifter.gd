class_name SkyDrifter
extends Sprite2D
## Nube que cruza el cielo despacio y vuelve a empezar por el otro lado.

@export var speed := 12.0
@export var wrap_from := -360.0
@export var wrap_to := 2280.0
@export var bob := 3.0

var _time := 0.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y
	_time = randf() * 10.0


func _process(delta: float) -> void:
	_time += delta
	position.x += speed * delta
	if position.x > wrap_to:
		position.x = wrap_from
	position.y = _base_y + bob * sin(_time * 0.4)

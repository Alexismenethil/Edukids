class_name DangerMeter
extends RefCounted
## Medidor de peligro de los niveles de práctica (RN-13).
##
## Empieza en 2 y su máximo es 4. Cada acierto suma 1 y cada error resta 1.
## Si llega a 0, Atoq alcanza al avatar: se pierde una vida y el medidor vuelve
## al valor inicial. El modo ayuda empieza en 3.

const DEFAULT_START := 2
const DEFAULT_MAX := 4
const HELP_MODE_START := 3

var value: int:
	get:
		return _value

var maximum: int:
	get:
		return _maximum

var start: int:
	get:
		return _start

var _value: int
var _start: int
var _maximum: int


func _init(start_value: int = DEFAULT_START, maximum_value: int = DEFAULT_MAX) -> void:
	_maximum = maxi(1, maximum_value)
	_start = clampi(start_value, 1, _maximum)
	_value = _start


## Crea un medidor validando la configuración del docente.
static func create(start_value: int, maximum_value: int) -> Result:
	if maximum_value < 1:
		return Result.fail(&"invalid_maximum", "El máximo del medidor debe ser 1 o más.")
	if start_value < 1 or start_value > maximum_value:
		return Result.fail(&"invalid_start", "El inicio debe estar entre 1 y el máximo.")
	return Result.ok(DangerMeter.new(start_value, maximum_value))


## Registra un acierto y devuelve el nuevo valor.
func register_hit() -> int:
	_value = mini(_value + 1, _maximum)
	return _value


## Registra un error. Devuelve true si Atoq alcanzó al avatar;
## en ese caso el medidor ya volvió a su valor inicial.
func register_miss() -> bool:
	_value -= 1
	if _value <= 0:
		_value = _start
		return true
	return false


## Fracción de seguridad entre 0 y 1, útil para ubicar a Atoq en la escena.
func safety_ratio() -> float:
	return float(_value) / float(_maximum)

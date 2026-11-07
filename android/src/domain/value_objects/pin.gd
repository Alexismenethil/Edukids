class_name Pin
extends RefCounted
## PIN numérico (RF-03 y RF-05). El del estudiante tiene 4 números; el del docente, de 4 a 6
## y no puede ser fácil de adivinar (1111, 1234, 9876). El PIN nunca se guarda en texto claro:
## solo sirve para calcular su hash con sal (RNF-08).

const STUDENT_LENGTH := 4
const TEACHER_MIN_LENGTH := 4
const TEACHER_MAX_LENGTH := 6

var digits: String:
	get:
		return _digits

var _digits: String


func _init(pin_digits: String) -> void:
	_digits = pin_digits


static func student(text: String) -> Result:
	var clean := text.strip_edges()
	if not has_only_digits(clean):
		return Result.fail(&"pin_not_digits", "El PIN solo lleva números.")
	if clean.length() != STUDENT_LENGTH:
		return Result.fail(&"pin_length", "El PIN del estudiante tiene 4 números.")
	return Result.ok(Pin.new(clean))


static func teacher(text: String) -> Result:
	var clean := text.strip_edges()
	if not has_only_digits(clean):
		return Result.fail(&"pin_not_digits", "El PIN solo lleva números.")
	if clean.length() < TEACHER_MIN_LENGTH or clean.length() > TEACHER_MAX_LENGTH:
		return Result.fail(&"pin_length", "El PIN docente tiene de 4 a 6 números.")
	if is_easy_to_guess(clean):
		return Result.fail(&"pin_too_easy", "El PIN docente no puede ser una serie fácil de adivinar.")
	return Result.ok(Pin.new(clean))


## Todos los números iguales (0000) o seguidos hacia arriba o hacia abajo (1234, 6543).
static func is_easy_to_guess(text: String) -> bool:
	if text.length() < 2:
		return true
	var same := true
	var up := true
	var down := true
	for i in range(1, text.length()):
		var step := text.unicode_at(i) - text.unicode_at(i - 1)
		same = same and step == 0
		up = up and step == 1
		down = down and step == -1
	return same or up or down


static func has_only_digits(text: String) -> bool:
	if text.is_empty():
		return false
	for i in text.length():
		var code := text.unicode_at(i)
		if code < 48 or code > 57:
			return false
	return true

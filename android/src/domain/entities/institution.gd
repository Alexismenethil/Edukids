class_name Institution
extends RefCounted
## Institución configurada en la tablet (RF-01 y ADR-008): ningún dato queda fijo en el código.

const NAME_MIN_LENGTH := 3
const NAME_MAX_LENGTH := 80
const MODULAR_CODE_LENGTH := 7
const MIN_GRADE := 1
const MAX_GRADE := 6
const MIN_SCHOOL_YEAR := 2020
const MAX_SCHOOL_YEAR := 2100

var id: String
var name: String
## Código modular del Minedu (7 números) o "" si no se registró.
var modular_code: String
var grade: int
var school_year: int
## Código de docente del panel web (6 caracteres) o "".
var teacher_code: String


func _init(institution_id: String, institution_name: String, code: String, institution_grade: int, year: int, code_of_teacher: String) -> void:
	id = institution_id
	name = institution_name
	modular_code = code
	grade = institution_grade
	school_year = year
	teacher_code = code_of_teacher


## Valida el nombre y lo devuelve limpio.
static func parse_name(text: String) -> Result:
	var clean := PersonName.normalize(text)
	if clean.length() < NAME_MIN_LENGTH:
		return Result.fail(&"institution_name_short", "Escribe el nombre de la institución.")
	if clean.length() > NAME_MAX_LENGTH:
		return Result.fail(&"institution_name_long", "El nombre tiene como máximo 80 caracteres.")
	return Result.ok(clean)


## El código modular es opcional; si se escribe, tiene 7 números.
static func parse_modular_code(text: String) -> Result:
	var clean := text.strip_edges().replace(" ", "")
	if clean.is_empty():
		return Result.ok("")
	if not Pin.has_only_digits(clean) or clean.length() != MODULAR_CODE_LENGTH:
		return Result.fail(&"modular_code_invalid", "El código modular tiene 7 números.")
	return Result.ok(clean)


static func is_valid_grade(value: int) -> bool:
	return value >= MIN_GRADE and value <= MAX_GRADE


static func is_valid_school_year(value: int) -> bool:
	return value >= MIN_SCHOOL_YEAR and value <= MAX_SCHOOL_YEAR

class_name Section
extends RefCounted
## Sección del grado (por ejemplo, «A»). Cada estudiante pertenece a una sola (RF-04).

const MAX_LENGTH := 12

var id: String
var name: String
var active: bool


func _init(section_id: String, section_name: String, is_active: bool = true) -> void:
	id = section_id
	name = section_name
	active = is_active


## Valida el nombre y lo devuelve con la primera letra en mayúscula: «a» → «A».
static func parse_name(text: String) -> Result:
	var clean := PersonName.normalize(text)
	if clean.is_empty():
		return Result.fail(&"section_empty", "Escribe el nombre de la sección.")
	if clean.length() > MAX_LENGTH:
		return Result.fail(&"section_long", "El nombre de la sección tiene como máximo 12 caracteres.")
	for i in clean.length():
		var code := clean.unicode_at(i)
		if not (PersonName.is_letter(code) or (code >= 48 and code <= 57) or code == 32):
			return Result.fail(&"section_invalid", "La sección solo lleva letras y números.")
	return Result.ok(clean[0].to_upper() + clean.substr(1))

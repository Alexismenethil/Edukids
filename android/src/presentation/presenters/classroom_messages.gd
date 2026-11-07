class_name ClassroomMessages
extends RefCounted
## Mensajes en español para los códigos de error del aula. Los del docente son precisos;
## los del estudiante, breves y amables.

const TEXTS := {
	&"institution_name_short": "Escribe el nombre de la institución.",
	&"institution_name_long": "El nombre es muy largo: máximo 80 caracteres.",
	&"modular_code_invalid": "El código modular tiene 7 números. Si no lo tienes a mano, déjalo vacío.",
	&"grade_invalid": "Elige un grado del 1.° al 6.°.",
	&"school_year_invalid": "Revisa el año escolar.",
	&"sections_empty": "Agrega al menos una sección.",
	&"sections_too_many": "Puedes registrar hasta 10 secciones.",
	&"section_duplicated": "Hay dos secciones con el mismo nombre.",
	&"section_empty": "Escribe el nombre de la sección.",
	&"section_long": "El nombre de la sección es muy largo: máximo 12 caracteres.",
	&"section_invalid": "La sección solo lleva letras y números.",
	&"section_not_found": "Elige una sección.",
	&"name_too_short": "Escribe el nombre (al menos 2 letras).",
	&"name_too_long": "El nombre es muy largo: máximo 40 caracteres.",
	&"name_invalid": "Usa solo letras, espacios, apóstrofos o guiones.",
	&"name_taken": "Ya hay un estudiante con ese nombre en esta sección.",
	&"name_taken_inactive": "Ese estudiante ya existe y está desactivado: reactívalo desde la lista.",
	&"pin_not_digits": "El PIN solo lleva números.",
	&"pin_length": "El PIN tiene 4 números.",
	&"pin_too_easy": "Elige un PIN más difícil de adivinar (no 1111 ni 1234).",
	&"pin_mismatch": "Los dos PIN no coinciden.",
	&"teacher_code_length": "El código de docente tiene 6 caracteres. Si no lo tienes, déjalo vacío.",
	&"teacher_code_invalid": "El código de docente solo lleva letras y números.",
	&"already_configured": "Esta tablet ya está configurada.",
	&"student_not_found": "No se encontró al estudiante.",
	&"save_failed": "No se pudo guardar. Inténtalo otra vez.",
}


static func text_for(code: StringName, field: String = "") -> String:
	if code == &"pin_length" and field == "teacher_pin":
		return "El PIN docente tiene de 4 a 6 números."
	return TEXTS.get(code, "Revisa este dato.")


## Convierte {campo: código} en {campo: mensaje}.
static func field_messages(errors: Dictionary) -> Dictionary:
	var messages := {}
	for field: String in errors:
		messages[field] = text_for(errors[field], field)
	return messages


## «4:05» a partir de segundos.
static func clock_text(seconds: int) -> String:
	seconds = maxi(seconds, 0)
	return "%d:%02d" % [seconds / 60, seconds % 60]


## Separa «Wayra Quispe Huamán» en «Wayra» y «Quispe Huamán» para las tarjetas.
static func split_name(full_name: String) -> PackedStringArray:
	var space := full_name.find(" ")
	if space < 0:
		return PackedStringArray([full_name, ""])
	return PackedStringArray([full_name.substr(0, space), full_name.substr(space + 1)])

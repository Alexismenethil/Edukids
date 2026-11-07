class_name TeacherCode
extends RefCounted
## Código de docente del panel web (RF-01 y RN-15): 6 letras o números. Es opcional;
## con él, la tablet muestra en el catálogo los retos de ese docente.

const LENGTH := 6


## Devuelve un Result con el código en mayúsculas, o con "" si se dejó vacío.
static func parse(text: String) -> Result:
	var clean := text.strip_edges().to_upper().replace(" ", "").replace("-", "")
	if clean.is_empty():
		return Result.ok("")
	if clean.length() != LENGTH:
		return Result.fail(&"teacher_code_length", "El código de docente tiene 6 caracteres.")
	for i in clean.length():
		var code := clean.unicode_at(i)
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90)):
			return Result.fail(&"teacher_code_invalid", "El código de docente solo lleva letras y números.")
	return Result.ok(clean)

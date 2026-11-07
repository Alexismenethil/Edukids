class_name FormResponse
extends RefCounted
## Respuesta de los casos de uso con formulario: si se guardó y, si no, el error de cada campo.

var ok := false
## Campo → código de error; por ejemplo {"name": &"name_too_short"}.
## El campo "general" se usa para errores que no son de un campo (no se pudo guardar).
var errors: Dictionary = {}
## Id del registro creado o actualizado.
var id := ""


static func success(record_id: String = "") -> FormResponse:
	var response := FormResponse.new()
	response.ok = true
	response.id = record_id
	return response


static func invalid(field_errors: Dictionary) -> FormResponse:
	var response := FormResponse.new()
	response.errors = field_errors
	return response

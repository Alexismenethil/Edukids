class_name Result
extends RefCounted
## Resultado explícito de una operación del dominio o de un caso de uso.
## Sustituye a push_error y a las excepciones del motor (regla 7 de Clean Architecture).

var value: Variant
var error: StringName = &""
var message: String = ""


static func ok(result_value: Variant = null) -> Result:
	var result := Result.new()
	result.value = result_value
	return result


static func fail(error_code: StringName, error_message: String = "") -> Result:
	var result := Result.new()
	result.error = error_code
	result.message = error_message
	return result


func is_ok() -> bool:
	return error == &""

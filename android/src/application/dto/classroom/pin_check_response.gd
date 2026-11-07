class_name PinCheckResponse
extends RefCounted
## Resultado de comprobar un PIN (RF-03, RF-05 y CU-03).

const WRONG_PIN := &"wrong_pin"
const LOCKED := &"locked"
const NOT_FOUND := &"not_found"
const INACTIVE := &"inactive"
const NOT_CONFIGURED := &"not_configured"

var ok := false
## Vacío si el PIN es correcto; si no, uno de los códigos de arriba.
var error: StringName = &""
## Intentos que quedan antes del bloqueo.
var attempts_left := 0
## Segundos que faltan para que termine el bloqueo.
var locked_seconds := 0
## Id y nombre de quien entró.
var id := ""
var name := ""
## Solo para estudiantes: si ya creó su personaje.
var has_avatar := false


static func success(person_id: String, person_name: String) -> PinCheckResponse:
	var response := PinCheckResponse.new()
	response.ok = true
	response.id = person_id
	response.name = person_name
	return response


static func failed(code: StringName) -> PinCheckResponse:
	var response := PinCheckResponse.new()
	response.error = code
	return response


## PIN incorrecto o acceso bloqueado, según cómo quedó el bloqueo.
static func rejected(lockout: PinLockout, now_ms: int) -> PinCheckResponse:
	var response := PinCheckResponse.new()
	response.locked_seconds = ceili(lockout.remaining_ms(now_ms) / 1000.0)
	response.error = LOCKED if lockout.is_locked(now_ms) else WRONG_PIN
	response.attempts_left = lockout.attempts_left(now_ms)
	return response

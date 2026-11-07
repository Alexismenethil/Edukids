class_name PinLockout
extends RefCounted
## Bloqueo temporal del PIN (CU-03 y RNF-08): tras 5 fallos seguidos, el acceso se bloquea
## 5 minutos. Un acierto reinicia la cuenta y, cuando el bloqueo termina, se empieza de cero.
## Es inmutable: cada cambio devuelve un objeto nuevo.

const MAX_FAILURES := 5
const LOCK_MS := 5 * 60 * 1000

var failures: int:
	get:
		return _failures

## Momento en que termina el bloqueo (milisegundos Unix); 0 si nunca hubo bloqueo.
var locked_until_ms: int:
	get:
		return _locked_until_ms

var _failures: int
var _locked_until_ms: int


func _init(failed: int = 0, locked_until: int = 0) -> void:
	_failures = maxi(failed, 0)
	_locked_until_ms = maxi(locked_until, 0)


func is_locked(now_ms: int) -> bool:
	return now_ms < _locked_until_ms


func remaining_ms(now_ms: int) -> int:
	return maxi(_locked_until_ms - now_ms, 0)


## Intentos que quedan antes de que se bloquee.
func attempts_left(now_ms: int) -> int:
	if is_locked(now_ms):
		return 0
	return MAX_FAILURES - _current_failures(now_ms)


func after_failure(now_ms: int) -> PinLockout:
	if is_locked(now_ms):
		return self
	var failed := _current_failures(now_ms) + 1
	if failed >= MAX_FAILURES:
		return PinLockout.new(0, now_ms + LOCK_MS)
	return PinLockout.new(failed, 0)


func after_success() -> PinLockout:
	return PinLockout.new()


func _current_failures(now_ms: int) -> int:
	if _locked_until_ms > 0 and now_ms >= _locked_until_ms:
		return 0
	return _failures

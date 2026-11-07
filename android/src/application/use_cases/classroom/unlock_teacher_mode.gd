class_name UnlockTeacherMode
extends RefCounted
## Caso de uso: entrar al modo docente con el PIN, sin internet (RF-03).
## Tras 5 fallos seguidos, el acceso se bloquea 5 minutos (RNF-08).

var _institutions: InstitutionRepository
var _hasher: PinHasher
var _clock: Clock


func _init(institutions: InstitutionRepository, hasher: PinHasher, clock: Clock) -> void:
	_institutions = institutions
	_hasher = hasher
	_clock = clock


func execute(pin_text: String) -> PinCheckResponse:
	var teacher := _institutions.load_teacher()
	if teacher == null:
		return PinCheckResponse.failed(PinCheckResponse.NOT_CONFIGURED)
	var now := _clock.now_unix_ms()
	if teacher.lockout.is_locked(now):
		return PinCheckResponse.rejected(teacher.lockout, now)
	if _hasher.verify(pin_text.strip_edges(), teacher.credential):
		if teacher.lockout.failures > 0:
			teacher.lockout = teacher.lockout.after_success()
			_institutions.save_teacher(teacher)
		return PinCheckResponse.success(teacher.id, teacher.name)
	teacher.lockout = teacher.lockout.after_failure(now)
	_institutions.save_teacher(teacher)
	return PinCheckResponse.rejected(teacher.lockout, now)

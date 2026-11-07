class_name LoginStudent
extends RefCounted
## Caso de uso: el estudiante elige su avatar y escribe su PIN (RF-05 y CU-03).
## Solo el PIN correcto abre su perfil; tras 5 fallos, se bloquea 5 minutos.

var _students: StudentRepository
var _hasher: PinHasher
var _clock: Clock


func _init(students: StudentRepository, hasher: PinHasher, clock: Clock) -> void:
	_students = students
	_hasher = hasher
	_clock = clock


func execute(student_id: String, pin_text: String) -> PinCheckResponse:
	var student := _students.find_student(student_id)
	if student == null:
		return PinCheckResponse.failed(PinCheckResponse.NOT_FOUND)
	if not student.active:
		return PinCheckResponse.failed(PinCheckResponse.INACTIVE)
	var now := _clock.now_unix_ms()
	if student.lockout.is_locked(now):
		return PinCheckResponse.rejected(student.lockout, now)
	if _hasher.verify(pin_text.strip_edges(), student.credential):
		if student.lockout.failures > 0:
			student.lockout = student.lockout.after_success()
			_students.save_student(student)
		var response := PinCheckResponse.success(student.id, student.name)
		response.has_avatar = student.has_avatar()
		return response
	student.lockout = student.lockout.after_failure(now)
	_students.save_student(student)
	return PinCheckResponse.rejected(student.lockout, now)

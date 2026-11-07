class_name GetStudentProfile
extends RefCounted
## Caso de uso: datos del perfil abierto (nombre y avatar). Devuelve null si no existe.

var _students: StudentRepository
var _clock: Clock


func _init(students: StudentRepository, clock: Clock) -> void:
	_students = students
	_clock = clock


func execute(student_id: String) -> StudentSummary:
	var student := _students.find_student(student_id)
	if student == null:
		return null
	return StudentSummary.from_student(student, _clock.now_unix_ms())

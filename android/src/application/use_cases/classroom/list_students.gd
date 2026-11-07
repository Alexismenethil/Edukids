class_name ListStudents
extends RefCounted
## Caso de uso: estudiantes de una sección, ordenados por nombre (perfiles y modo docente).

var _students: StudentRepository
var _clock: Clock


func _init(students: StudentRepository, clock: Clock) -> void:
	_students = students
	_clock = clock


func execute(section_id: String, include_inactive: bool = false) -> Array[StudentSummary]:
	var now := _clock.now_unix_ms()
	var found := _students.list_students(section_id, include_inactive)
	found.sort_custom(func(a: Student, b: Student) -> bool:
		return PersonName.comparison_key(a.name) < PersonName.comparison_key(b.name))
	var summaries: Array[StudentSummary] = []
	for student in found:
		summaries.append(StudentSummary.from_student(student, now))
	return summaries

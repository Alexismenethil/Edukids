class_name InMemoryStudentRepository
extends StudentRepository
## Adaptador de respaldo: estudiantes solo en memoria, si SQLite no está disponible.
## Devuelve copias, como lo haría una base de datos.

var _students := {}


func list_students(section_id: String, include_inactive: bool) -> Array[Student]:
	var found: Array[Student] = []
	for student: Student in _students.values():
		if student.section_id == section_id and (include_inactive or student.active):
			found.append(_copy(student))
	return found


func find_student(student_id: String) -> Student:
	return _copy(_students[student_id]) if _students.has(student_id) else null


func save_student(student: Student) -> Result:
	_students[student.id] = _copy(student)
	return Result.ok()


static func _copy(student: Student) -> Student:
	var copy := Student.new(student.id, student.section_id, student.name, student.credential)
	copy.code = student.code
	copy.avatar = student.avatar
	copy.lockout = student.lockout
	copy.active = student.active
	return copy

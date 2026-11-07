class_name SetStudentActive
extends RefCounted
## Caso de uso: desactivar o reactivar a un estudiante (RF-04). Nunca se elimina:
## así se conservan sus intentos y resultados (RN-07).

var _students: StudentRepository


func _init(students: StudentRepository) -> void:
	_students = students


func execute(student_id: String, active: bool) -> Result:
	var student := _students.find_student(student_id)
	if student == null:
		return Result.fail(&"student_not_found", "No se encontró al estudiante.")
	student.active = active
	return _students.save_student(student)

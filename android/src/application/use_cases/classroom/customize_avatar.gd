class_name CustomizeAvatar
extends RefCounted
## Caso de uso: el estudiante crea o cambia su personaje (RF-31 y CU-11). El avatar se guarda
## en su perfil. Los accesorios que se ganan con estrellas llegan con RF-32.

var _students: StudentRepository


func _init(students: StudentRepository) -> void:
	_students = students


func execute(student_id: String, traits: Dictionary) -> Result:
	var student := _students.find_student(student_id)
	if student == null:
		return Result.fail(&"student_not_found", "No se encontró al estudiante.")
	var avatar := Avatar.create(traits)
	if not avatar.is_ok():
		return avatar
	student.avatar = avatar.value
	return _students.save_student(student)

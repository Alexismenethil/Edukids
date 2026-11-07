class_name ResetStudentPin
extends RefCounted
## Caso de uso: el docente le da un PIN nuevo a un estudiante (RF-17). El anterior deja de
## funcionar y se quita cualquier bloqueo.

var _students: StudentRepository
var _hasher: PinHasher


func _init(students: StudentRepository, hasher: PinHasher) -> void:
	_students = students
	_hasher = hasher


func execute(student_id: String, pin_text: String) -> FormResponse:
	var student := _students.find_student(student_id)
	if student == null:
		return FormResponse.invalid({"general": &"student_not_found"})
	var pin := Pin.student(pin_text)
	if not pin.is_ok():
		return FormResponse.invalid({"pin": pin.error})
	var salt := _hasher.new_salt()
	student.credential = PinCredential.new(_hasher.hash_pin((pin.value as Pin).digits, salt), salt)
	student.lockout = PinLockout.new()
	if not _students.save_student(student).is_ok():
		return FormResponse.invalid({"general": &"save_failed"})
	return FormResponse.success(student.id)

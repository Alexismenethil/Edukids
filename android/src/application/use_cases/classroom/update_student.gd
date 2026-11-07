class_name UpdateStudent
extends RefCounted
## Caso de uso: el docente corrige el nombre de un estudiante o lo cambia de sección (RF-04).
## El PIN no cambia aquí: para eso está ResetStudentPin.

var _institutions: InstitutionRepository
var _students: StudentRepository


func _init(institutions: InstitutionRepository, students: StudentRepository) -> void:
	_institutions = institutions
	_students = students


func execute(form: StudentForm) -> FormResponse:
	var student := _students.find_student(form.student_id)
	if student == null:
		return FormResponse.invalid({"general": &"student_not_found"})
	var errors := {}
	var name := PersonName.parse(form.name)
	if not name.is_ok():
		errors["name"] = name.error
	if not ClassroomRules.is_active_section(_institutions, form.section_id):
		errors["section"] = &"section_not_found"
	if errors.is_empty():
		var taken := ClassroomRules.name_conflict(_students, form.section_id, name.value, student.id)
		if taken != &"":
			errors["name"] = taken
	if not errors.is_empty():
		return FormResponse.invalid(errors)
	student.name = name.value
	student.section_id = form.section_id
	if not _students.save_student(student).is_ok():
		return FormResponse.invalid({"general": &"save_failed"})
	return FormResponse.success(student.id)

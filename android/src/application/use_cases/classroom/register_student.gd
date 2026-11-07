class_name RegisterStudent
extends RefCounted
## Caso de uso: el docente registra a un estudiante con su nombre, su sección y su PIN (RF-04).
## Dos estudiantes de la misma sección no pueden llamarse igual: sería fácil confundirlos al elegir perfil.

var _institutions: InstitutionRepository
var _students: StudentRepository
var _hasher: PinHasher
var _ids: IdGenerator


func _init(institutions: InstitutionRepository, students: StudentRepository, hasher: PinHasher, ids: IdGenerator) -> void:
	_institutions = institutions
	_students = students
	_hasher = hasher
	_ids = ids


func execute(form: StudentForm) -> FormResponse:
	var errors := {}
	var name := PersonName.parse(form.name)
	if not name.is_ok():
		errors["name"] = name.error
	if not ClassroomRules.is_active_section(_institutions, form.section_id):
		errors["section"] = &"section_not_found"
	var pin := Pin.student(form.pin)
	if not pin.is_ok():
		errors["pin"] = pin.error
	if errors.is_empty():
		var taken := ClassroomRules.name_conflict(_students, form.section_id, name.value, "")
		if taken != &"":
			errors["name"] = taken
	if not errors.is_empty():
		return FormResponse.invalid(errors)
	var salt := _hasher.new_salt()
	var student := Student.new(_ids.next_id(), form.section_id, name.value,
		PinCredential.new(_hasher.hash_pin((pin.value as Pin).digits, salt), salt))
	if not _students.save_student(student).is_ok():
		return FormResponse.invalid({"general": &"save_failed"})
	return FormResponse.success(student.id)

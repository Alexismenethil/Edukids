class_name ConfigureInstitution
extends RefCounted
## Caso de uso: configuración inicial de la tablet (RF-01 y CU-01). El docente registra la
## institución, el grado, las secciones, su nombre, su PIN y, si lo tiene, su código de docente.
## Si falta un dato obligatorio, no se guarda nada.

const MAX_SECTIONS := 10

var _institutions: InstitutionRepository
var _hasher: PinHasher
var _ids: IdGenerator


func _init(institutions: InstitutionRepository, hasher: PinHasher, ids: IdGenerator) -> void:
	_institutions = institutions
	_hasher = hasher
	_ids = ids


## Revisa todos los datos y devuelve el error de cada campo (vacío si todo está bien).
## El asistente lo usa para validar cada paso antes de seguir.
func validate(request: SetupRequest) -> Dictionary:
	var errors := {}
	_check(errors, "institution_name", Institution.parse_name(request.institution_name))
	_check(errors, "modular_code", Institution.parse_modular_code(request.modular_code))
	if not Institution.is_valid_grade(request.grade):
		errors["grade"] = &"grade_invalid"
	if not Institution.is_valid_school_year(request.school_year):
		errors["school_year"] = &"school_year_invalid"
	var sections_error := _sections_error(request.section_names)
	if sections_error != &"":
		errors["sections"] = sections_error
	_check(errors, "teacher_name", PersonName.parse(request.teacher_name))
	var pin := Pin.teacher(request.teacher_pin)
	_check(errors, "teacher_pin", pin)
	if pin.is_ok() and request.teacher_pin_confirmation.strip_edges() != (pin.value as Pin).digits:
		errors["teacher_pin_confirmation"] = &"pin_mismatch"
	_check(errors, "teacher_code", TeacherCode.parse(request.teacher_code))
	return errors


func execute(request: SetupRequest) -> FormResponse:
	if _institutions.load_institution() != null:
		return FormResponse.invalid({"general": &"already_configured"})
	var errors := validate(request)
	if not errors.is_empty():
		return FormResponse.invalid(errors)
	var institution := Institution.new(
		_ids.next_id(),
		Institution.parse_name(request.institution_name).value,
		Institution.parse_modular_code(request.modular_code).value,
		request.grade,
		request.school_year,
		TeacherCode.parse(request.teacher_code).value,
	)
	var sections: Array[Section] = []
	for raw_name in request.section_names:
		sections.append(Section.new(_ids.next_id(), Section.parse_name(raw_name).value))
	var pin: Pin = Pin.teacher(request.teacher_pin).value
	var salt := _hasher.new_salt()
	var teacher := Teacher.new(_ids.next_id(), PersonName.parse(request.teacher_name).value,
		PinCredential.new(_hasher.hash_pin(pin.digits, salt), salt))
	var saved := _institutions.save_setup(institution, sections, teacher)
	if not saved.is_ok():
		return FormResponse.invalid({"general": &"save_failed"})
	return FormResponse.success(institution.id)


func _sections_error(names: PackedStringArray) -> StringName:
	if names.is_empty():
		return &"sections_empty"
	if names.size() > MAX_SECTIONS:
		return &"sections_too_many"
	var seen := {}
	for raw_name in names:
		var parsed := Section.parse_name(raw_name)
		if not parsed.is_ok():
			return parsed.error
		var key := PersonName.comparison_key(parsed.value)
		if seen.has(key):
			return &"section_duplicated"
		seen[key] = true
	return &""


static func _check(errors: Dictionary, field: String, result: Result) -> void:
	if not result.is_ok():
		errors[field] = result.error

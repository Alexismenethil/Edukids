class_name GetClassroom
extends RefCounted
## Caso de uso: saber si la tablet ya está configurada y con qué institución y secciones.

var _institutions: InstitutionRepository


func _init(institutions: InstitutionRepository) -> void:
	_institutions = institutions


func execute() -> ClassroomResponse:
	var response := ClassroomResponse.new()
	var institution := _institutions.load_institution()
	var teacher := _institutions.load_teacher()
	if institution == null or teacher == null:
		return response
	response.configured = true
	response.institution_name = institution.name
	response.modular_code = institution.modular_code
	response.grade = institution.grade
	response.school_year = institution.school_year
	response.teacher_name = teacher.name
	response.teacher_code = institution.teacher_code
	for section in _institutions.load_sections():
		if section.active:
			response.sections.append({"id": section.id, "name": section.name})
	return response

class_name ClassroomRules
extends RefCounted
## Comprobaciones que comparten los casos de uso del aula y que necesitan los repositorios.


static func is_active_section(institutions: InstitutionRepository, section_id: String) -> bool:
	for section in institutions.load_sections():
		if section.id == section_id:
			return section.active
	return false


## &"name_taken" si ya hay un estudiante activo con ese nombre en la sección;
## &"name_taken_inactive" si está desactivado (conviene reactivarlo); &"" si está libre.
static func name_conflict(students: StudentRepository, section_id: String, name: String, except_id: String) -> StringName:
	var key := PersonName.comparison_key(name)
	for student in students.list_students(section_id, true):
		if student.id != except_id and PersonName.comparison_key(student.name) == key:
			return &"name_taken" if student.active else &"name_taken_inactive"
	return &""

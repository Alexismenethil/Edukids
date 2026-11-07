class_name InMemoryInstitutionRepository
extends InstitutionRepository
## Adaptador de respaldo: guarda la configuración solo mientras el juego está abierto.
## Se usa si SQLite no está disponible. Devuelve copias, como lo haría una base de datos.

var _institution: Institution
var _sections: Array[Section] = []
var _teacher: Teacher


func load_institution() -> Institution:
	if _institution == null:
		return null
	return Institution.new(_institution.id, _institution.name, _institution.modular_code,
		_institution.grade, _institution.school_year, _institution.teacher_code)


func load_sections() -> Array[Section]:
	var copies: Array[Section] = []
	for section in _sections:
		copies.append(Section.new(section.id, section.name, section.active))
	copies.sort_custom(func(a: Section, b: Section) -> bool: return a.name.naturalnocasecmp_to(b.name) < 0)
	return copies


func load_teacher() -> Teacher:
	if _teacher == null:
		return null
	return Teacher.new(_teacher.id, _teacher.name, _teacher.credential, _teacher.lockout)


func save_setup(institution: Institution, sections: Array[Section], teacher: Teacher) -> Result:
	_institution = institution
	_sections.clear()
	for section in sections:
		_sections.append(Section.new(section.id, section.name, section.active))
	return save_teacher(teacher)


func save_teacher(teacher: Teacher) -> Result:
	_teacher = Teacher.new(teacher.id, teacher.name, teacher.credential, teacher.lockout)
	return Result.ok()

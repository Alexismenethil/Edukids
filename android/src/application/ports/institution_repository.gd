@abstract class_name InstitutionRepository
extends RefCounted
## Puerto: institución, secciones y docente de la tablet (tablas institution, section y teacher).


## Devuelve null si la tablet todavía no se configuró.
@abstract func load_institution() -> Institution


## Todas las secciones, activas o no, ordenadas por nombre.
@abstract func load_sections() -> Array[Section]


## Devuelve null si la tablet todavía no se configuró.
@abstract func load_teacher() -> Teacher


## Guarda la configuración inicial completa en una sola transacción.
@abstract func save_setup(institution: Institution, sections: Array[Section], teacher: Teacher) -> Result


@abstract func save_teacher(teacher: Teacher) -> Result

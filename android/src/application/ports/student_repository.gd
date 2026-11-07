@abstract class_name StudentRepository
extends RefCounted
## Puerto: estudiantes registrados en la tablet (tabla student).


## Estudiantes de una sección. Con include_inactive, también los desactivados.
@abstract func list_students(section_id: String, include_inactive: bool) -> Array[Student]


## Devuelve null si no existe.
@abstract func find_student(student_id: String) -> Student


## Registra o actualiza al estudiante.
@abstract func save_student(student: Student) -> Result

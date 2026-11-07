@abstract class_name AttemptRepository
extends RefCounted
## Puerto: intentos de los estudiantes y sus respuestas. Cada respuesta se guarda
## en el momento, en su propia transacción (RNF-06).


@abstract func create_attempt(attempt: Attempt) -> Result


@abstract func save_answer(answer: AttemptAnswer) -> Result


## Guarda el cierre del intento: estado, fecha de término, aciertos, porcentaje y estrellas.
@abstract func finish_attempt(attempt: Attempt) -> Result


## El intento sin terminar más reciente del estudiante en ese nivel, o null.
@abstract func find_open_attempt(student_id: String, level_key: String) -> Attempt


## Respuestas de un intento, en el orden en que se dieron.
@abstract func list_answers(attempt_id: String) -> Array[AttemptAnswer]


## Mejores estrellas del estudiante por nivel: «paquete/nivel» → estrellas.
@abstract func best_stars(student_id: String) -> Dictionary

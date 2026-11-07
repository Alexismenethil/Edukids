class_name InMemoryAttemptRepository
extends AttemptRepository
## Adaptador de respaldo: intentos y respuestas solo mientras el juego está abierto,
## si SQLite no está disponible. Devuelve copias, como lo haría una base de datos.

var _attempts: Array[Attempt] = []
var _answers: Array[AttemptAnswer] = []


func create_attempt(attempt: Attempt) -> Result:
	_attempts.append(_copy(attempt))
	return Result.ok()


func save_answer(answer: AttemptAnswer) -> Result:
	var copy := AttemptAnswer.new()
	for property in ["id", "attempt_id", "item_id", "is_correct", "first_try", "with_hint", "time_ms", "answered_at_ms"]:
		copy.set(property, answer.get(property))
	copy.value = answer.value.duplicate(true) if answer.value is Array or answer.value is Dictionary else answer.value
	_answers.append(copy)
	return Result.ok()


func finish_attempt(attempt: Attempt) -> Result:
	for index in _attempts.size():
		if _attempts[index].id == attempt.id:
			var stored := _attempts[index]
			attempt.started_at_ms = stored.started_at_ms
			_attempts[index] = _copy(attempt)
			return Result.ok()
	return Result.fail(&"attempt_not_found", "No existe el intento %s." % attempt.id)


func find_open_attempt(student_id: String, level_key: String) -> Attempt:
	for index in range(_attempts.size() - 1, -1, -1):
		var attempt := _attempts[index]
		if attempt.student_id == student_id and attempt.level_key == level_key and attempt.is_open():
			return _copy(attempt)
	return null


func list_answers(attempt_id: String) -> Array[AttemptAnswer]:
	var found: Array[AttemptAnswer] = []
	for answer in _answers:
		if answer.attempt_id == attempt_id:
			found.append(answer)
	return found


func best_stars(student_id: String) -> Dictionary:
	var best := {}
	for attempt in _attempts:
		if attempt.student_id == student_id and attempt.status == Attempt.COMPLETED:
			best[attempt.level_key] = maxi(best.get(attempt.level_key, 0), attempt.stars)
	return best


static func _copy(attempt: Attempt) -> Attempt:
	var copy := Attempt.new()
	for property in ["id", "student_id", "level_key", "package_version", "kind", "status", "started_at_ms",
			"finished_at_ms", "correct_count", "total_count", "percent", "stars", "cneb_grade", "lives_lost", "hints_used"]:
		copy.set(property, attempt.get(property))
	return copy

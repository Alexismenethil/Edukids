class_name FinishLevel
extends RefCounted
## Caso de uso: cierra el intento con sus aciertos, porcentaje y estrellas (RF-14, RF-25 y RN-11).

var _sessions: LevelSessionStore
var _attempts: AttemptRepository
var _clock: Clock


func _init(sessions: LevelSessionStore, attempts: AttemptRepository, clock: Clock) -> void:
	_sessions = sessions
	_attempts = attempts
	_clock = clock


func execute(attempt_id: String) -> Result:
	var session := _sessions.find(attempt_id)
	if session == null:
		return Result.fail(&"session_missing", "El nivel ya no está abierto.")
	if not session.is_finished():
		return Result.fail(&"level_unfinished", "Todavía quedan preguntas.")
	var summary := session.summary()
	var best_before: int = _attempts.best_stars(session.student_id).get(session.level.key(), 0)
	var attempt := Attempt.new()
	attempt.id = attempt_id
	attempt.student_id = session.student_id
	attempt.level_key = session.level.key()
	attempt.package_version = session.level.package_version
	attempt.complete(summary, _clock.now_unix_ms())
	var saved := _attempts.finish_attempt(attempt)
	_sessions.remove(attempt_id)
	var response := LevelSummaryResponse.new()
	response.title = session.level.title
	response.area = session.level.area
	response.total = summary.total
	response.correct = summary.correct
	response.valid_hits = summary.valid_hits
	response.fixed = summary.fixed
	response.hints_used = summary.hints_used
	response.percent = summary.percent
	response.stars = summary.stars
	response.time_ms = summary.time_ms
	response.best_before = best_before
	response.saved = saved.is_ok()
	return Result.ok(response)

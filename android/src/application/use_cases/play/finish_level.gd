class_name FinishLevel
extends RefCounted
## Caso de uso: cierra el intento con sus aciertos, porcentaje y estrellas (RF-14, RF-25 y RN-11),
## o en game over si se acabaron las vidas (RN-14). El desafío final se califica con la escala
## del CNEB y devuelve la revisión de cada pregunta (RN-10, RN-12 y RF-30).

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
	attempt.kind = Attempt.FINAL if summary.final else Attempt.PRACTICE
	attempt.complete(summary, _clock.now_unix_ms())
	var saved := _attempts.finish_attempt(attempt)
	_sessions.remove(attempt_id)
	var response := LevelSummaryResponse.new()
	response.title = session.level.title
	response.area = session.level.area
	response.mechanic = session.level.entry.mechanic
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
	response.game_over = summary.game_over
	response.lives_left = summary.lives_left
	response.lives_max = session.lives_max()
	response.lives_lost = summary.lives_lost
	response.best_streak = summary.best_streak
	response.final = summary.final
	response.progress = session.progress(false, true)
	if summary.final:
		response.grade = summary.grade.code()
		response.grade_description = summary.grade.description()
		for review in session.review():
			response.review.append(ReviewResponse.from_review(review))
		var records := LevelRecords.of(_attempts.list_attempts(session.student_id))
		response.max_attempts = session.level.entry.max_attempts
		response.attempts_left = TrailRule.attempts_left(session.level.entry, records.finals_used(session.level.key()))
	return Result.ok(response)

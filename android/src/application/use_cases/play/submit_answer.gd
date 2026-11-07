class_name SubmitAnswer
extends RefCounted
## Caso de uso: corrige la respuesta, la guarda en el momento (RNF-06) y devuelve la
## retroalimentación (RF-12).

var _sessions: LevelSessionStore
var _attempts: AttemptRepository
var _ids: IdGenerator
var _clock: Clock


func _init(sessions: LevelSessionStore, attempts: AttemptRepository, ids: IdGenerator, clock: Clock) -> void:
	_sessions = sessions
	_attempts = attempts
	_ids = ids
	_clock = clock


func execute(attempt_id: String, answer: Variant) -> Result:
	var session := _sessions.find(attempt_id)
	if session == null:
		return Result.fail(&"session_missing", "El nivel ya no está abierto.")
	var now := _clock.now_unix_ms()
	var outcome := session.submit(answer, now)
	var response := AnswerResponse.from_outcome(outcome)
	if not outcome.accepted:
		return Result.ok(response)
	var saved := _attempts.save_answer(AttemptAnswer.from_outcome(_ids.next_id(), attempt_id, outcome, answer, now))
	response.saved = saved.is_ok()
	response.progress = session.progress(false)
	return Result.ok(response)

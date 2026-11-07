class_name ContinueLevel
extends RefCounted
## Caso de uso: pasa a la siguiente pregunta después de leer la retroalimentación.
## Devuelve un Result con la StepResponse, o con null si ya no quedan preguntas.

var _sessions: LevelSessionStore
var _builder: StepBuilder
var _clock: Clock


func _init(sessions: LevelSessionStore, builder: StepBuilder, clock: Clock) -> void:
	_sessions = sessions
	_builder = builder
	_clock = clock


func execute(attempt_id: String) -> Result:
	var session := _sessions.find(attempt_id)
	if session == null:
		return Result.fail(&"session_missing", "El nivel ya no está abierto.")
	if session.is_finished():
		return Result.ok(null)
	session.begin_step(_clock.now_unix_ms())
	return Result.ok(_builder.build(session))

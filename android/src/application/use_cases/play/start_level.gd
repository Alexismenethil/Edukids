class_name StartLevel
extends RefCounted
## Caso de uso: empieza un nivel o continúa el intento que quedó abierto (RF-12 y RF-14).
## Si el contenido cambió de versión, empieza un intento nuevo (RN-05).

var _store: PackageStore
var _attempts: AttemptRepository
var _sessions: LevelSessionStore
var _registry: EvaluatorRegistry
var _builder: StepBuilder
var _ids: IdGenerator
var _clock: Clock


func _init(store: PackageStore, attempts: AttemptRepository, sessions: LevelSessionStore,
		registry: EvaluatorRegistry, builder: StepBuilder, ids: IdGenerator, clock: Clock) -> void:
	_store = store
	_attempts = attempts
	_sessions = sessions
	_registry = registry
	_builder = builder
	_ids = ids
	_clock = clock


func execute(student_id: String, package_id: String, level_id: String) -> Result:
	var loaded := _store.load_level(package_id, level_id)
	if not loaded.is_ok():
		return Result.fail(&"level_unavailable", loaded.message)
	var level: Level = loaded.value
	var now := _clock.now_unix_ms()
	var session := _resume(student_id, level)
	if session == null:
		var attempt := Attempt.start(_ids.next_id(), student_id, level, now)
		var created := _attempts.create_attempt(attempt)
		if not created.is_ok():
			return Result.fail(&"save_failed", created.message)
		session = LevelSession.new(level, _registry, attempt.id, student_id)
	session.begin_step(now)
	_sessions.put(session)
	var response := LevelStartResponse.new()
	response.attempt_id = session.attempt_id
	response.title = level.title
	response.package_title = level.package_title
	response.area = level.area
	response.kind = level.entry.kind
	response.mechanic = level.entry.mechanic
	response.guide_intro = level.guide_intro
	response.total = session.question_count()
	response.answered = session.answered_count()
	response.resumed = response.answered > 0
	response.step = _builder.build(session)
	return Result.ok(response)


func _resume(student_id: String, level: Level) -> LevelSession:
	var open := _attempts.find_open_attempt(student_id, level.key())
	if open == null or open.package_version != level.package_version:
		return null
	var session := LevelSession.new(level, _registry, open.id, student_id)
	return session if session.restore(_attempts.list_answers(open.id)) else null

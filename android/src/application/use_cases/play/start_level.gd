class_name StartLevel
extends RefCounted
## Caso de uso: empieza un nivel o continúa el intento que quedó abierto (RF-12 y RF-14).
## Si el contenido cambió de versión, empieza un intento nuevo (RN-05). Respeta el orden de
## los niveles del módulo (RN-18) y los intentos del desafío final.

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
	var records := LevelRecords.of(_attempts.list_attempts(student_id))
	var package := _package(package_id)
	if package and TrailRule.states(package.levels, records.completed_ids(package)).get(level_id) == TrailRule.LOCKED:
		return Result.fail(&"level_locked", "Este nivel se abre al completar el anterior.")
	var now := _clock.now_unix_ms()
	var session := _resume(student_id, level, now)
	if session == null:
		var used := records.finals_used(level.key())
		if level.entry.is_final() and TrailRule.attempts_left(level.entry, used) <= 0:
			return Result.fail(&"no_attempts_left", "Ya usaste los intentos de este desafío.")
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
	response.final = session.is_final()
	response.attempt_number = records.finals_used(level.key()) + 1
	response.max_attempts = level.entry.max_attempts if session.is_final() else 0
	response.lives = session.lives()
	response.lives_max = session.lives_max()
	response.danger = session.danger()
	response.danger_max = session.danger_max()
	response.streak = session.streak()
	response.step = _builder.build(session)
	return Result.ok(response)


func _package(package_id: String) -> ContentPackage:
	for package in _store.list_packages():
		if package.id == package_id:
			return package
	return null


## Rehace el intento abierto. Si al rehacerlo ya no quedaban vidas (la aplicación se cerró justo
## en el game over), lo cierra y empieza otro.
func _resume(student_id: String, level: Level, now: int) -> LevelSession:
	var open := _attempts.find_open_attempt(student_id, level.key())
	if open == null or open.package_version != level.package_version:
		return null
	var session := LevelSession.new(level, _registry, open.id, student_id)
	if not session.restore(_attempts.list_answers(open.id)):
		return null
	if session.is_game_over():
		open.complete(session.summary(), now)
		_attempts.finish_attempt(open)
		return null
	return session

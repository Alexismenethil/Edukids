extends GdUnitTestSuite
## Presentadores del motor de actividades: textos de Quwi, retroalimentación, pistas,
## resultados y la lista de niveles del inicio del estudiante.

const STUDENT := "stu-1"

var _store: FakePackageStore
var _attempts: InMemoryAttemptRepository
var _sessions: InMemoryLevelSessionStore
var _clock: FakeClock
var _ids: SequentialIds
var _session: PlaySession


func before_test() -> void:
	_store = FakePackageStore.new()
	_store.add("math", [SampleItems.multiple_choice("q1", "Mira el tablero."), SampleItems.matching("q2"),
		SampleItems.multi_select("q3")])
	_attempts = InMemoryAttemptRepository.new()
	_sessions = InMemoryLevelSessionStore.new()
	_clock = FakeClock.new()
	_ids = SequentialIds.new()
	_session = PlaySession.new()
	_session.student_id = STUDENT
	_session.choose_level("mod-math-6-00", "L01")


func _presenter(sessions: LevelSessionStore = _sessions) -> LevelPresenter:
	var registry := EvaluatorRegistry.standard()
	var builder := StepBuilder.new(ScriptedRandom.new([0]))
	return LevelPresenter.new(
		StartLevel.new(_store, _attempts, sessions, registry, builder, _ids, _clock),
		SubmitAnswer.new(sessions, _attempts, _ids, _clock),
		RequestHint.new(sessions),
		ContinueLevel.new(sessions, builder, _clock),
		FinishLevel.new(sessions, _attempts, _clock),
		_session)


func test_opening_a_level_greets_with_the_guide() -> void:
	var intro := _presenter().open()
	assert_str(intro.error).is_empty()
	assert_str(intro.title).is_equal("Nivel de prueba")
	assert_str(intro.area.name).is_equal("Matemática")
	assert_str(intro.area.icon).is_equal("area_math")
	assert_str(intro.dialogue.lines[0].text).is_equal("¡Hola!")
	assert_str(intro.dialogue.lines[0].speaker_name).is_equal("Quwi")
	var step := intro.step
	assert_str(step.counter).is_equal("Pregunta 1 de 3")
	assert_str(step.type).is_equal("multiple_choice")
	assert_str(step.check_label).is_equal("Comprobar")
	assert_str(step.labels["true"]).is_equal("Verdadero")
	assert_bool(step.hint_available).is_true()
	assert_int(step.index).is_equal(0)


func test_a_level_that_cannot_open_says_so() -> void:
	_session.choose_level("mod-math-6-00", "L09")
	var intro := _presenter().open()
	assert_str(intro.error).is_equal(PlayMessages.LEVEL_UNAVAILABLE)


func test_a_wrong_answer_explains_and_warns_it_will_return() -> void:
	var presenter := _presenter()
	presenter.open()
	var feedback := presenter.submit("a")
	assert_bool(feedback.accepted).is_true()
	assert_bool(feedback.correct).is_false()
	assert_str(feedback.title).is_equal("¡Casi!")
	assert_str(feedback.message).is_equal("Fíjate en la posición.")
	assert_array(feedback.notes).contains([PlayMessages.WILL_RETURN])
	assert_str(feedback.mood).is_equal("comfort")
	assert_str(feedback.continue_label).is_equal("Seguir")
	assert_int(feedback.index).is_equal(0)


func test_an_incomplete_answer_asks_to_finish_it() -> void:
	var presenter := _presenter()
	presenter.open()
	var feedback := presenter.submit("")
	assert_bool(feedback.accepted).is_false()
	assert_str(feedback.notice).is_equal(PlayMessages.INCOMPLETE)


func test_partial_answers_count_what_is_right() -> void:
	var presenter := _presenter()
	presenter.open()
	presenter.submit("b")
	presenter.next()
	var matching := presenter.submit({"l1": "r2", "l2": "r3"})
	assert_array(matching.notes).contains([PlayMessages.partial(1, 2)])
	presenter.next()
	var missing := presenter.submit(["a"])
	assert_array(missing.notes).contains([PlayMessages.missing(1)])


func test_the_opening_exclamation_becomes_the_title() -> void:
	_store.add("math", [{
		"id": "n1", "type": "numeric", "prompt": "¿Cuánto es 3 × 480?", "answer": 1440,
		"feedback": {"correct": "¡Exacto! 3 × 480 = 1 440.", "incorrect": "Multiplica."},
	}])
	var presenter := _presenter()
	presenter.open()
	var feedback := presenter.submit("1440")
	assert_str(feedback.title).is_equal("¡Exacto!")
	assert_str(feedback.message).is_equal("3 × 480 = 1%s440." % PlayMessages.NO_BREAK)
	assert_str(feedback.mood).is_equal("cheer")
	assert_str(feedback.continue_label).is_equal("Ver resultados")


func test_the_hint_is_a_line_of_the_guide() -> void:
	var presenter := _presenter()
	presenter.open()
	var hint := presenter.hint()
	assert_str(hint.lines[0].text).is_equal("Mira el tablero.")
	assert_str(hint.lines[0].mood).is_equal("think")
	assert_str(hint.skip_label).is_empty()
	presenter.submit("b")
	presenter.next()
	assert_object(presenter.hint()).is_null()


func test_a_closed_game_is_welcomed_back() -> void:
	var presenter := _presenter()
	presenter.open()
	presenter.submit("b")
	var again := _presenter(InMemoryLevelSessionStore.new()).open()
	assert_str(again.dialogue.lines[0].text).is_equal(PlayMessages.resumed(1, 3))
	assert_str(again.step.counter).is_equal("Pregunta 2 de 3")


func test_results_show_stars_lines_and_records() -> void:
	var presenter := _presenter()
	presenter.open()
	presenter.submit("b")
	presenter.next()
	presenter.submit({"l1": "r2", "l2": "r1"})
	presenter.next()
	presenter.submit(["a", "c"])
	var result := presenter.finish()
	assert_int(result.stars).is_equal(3)
	assert_str(result.heading).is_equal("¡Nivel completado!")
	assert_array(result.lines).contains(["Acertaste 3 de 3 al primer intento."])
	assert_bool(result.new_record).is_false()
	assert_str(result.replay_label).is_equal("Otra vez")
	_clock.advance(60_000)
	var second := _presenter()
	second.open()
	second.hint()
	second.submit("b")
	second.next()
	second.submit({"l1": "r2", "l2": "r1"})
	second.next()
	second.submit(["a", "c"])
	var lower := second.finish()
	assert_int(lower.stars).is_equal(1)
	assert_array(lower.lines).contains(["Usaste 1 pista."])
	assert_bool(lower.new_record).is_false()


func test_messages_for_time_and_counts() -> void:
	assert_str(PlayMessages.duration(45_200)).is_equal("45 s")
	assert_str(PlayMessages.duration(252_000)).is_equal("4 min 12 s")
	assert_str(PlayMessages.missing(2)).is_equal("Te faltó marcar 2 opciones.")
	assert_str(PlayMessages.opening_exclamation("¡Bien! Sigue así.")).is_equal("¡Bien!")
	assert_str(PlayMessages.opening_exclamation("¡Excelente lectura!")).is_empty()
	assert_str(PlayMessages.opening_exclamation("Revisa la tabla.")).is_empty()
	assert_str(PlayMessages.details(8, 10)).is_equal("8 preguntas · 10 min")


func test_the_home_lists_the_levels_with_stars() -> void:
	_store.add("science", [SampleItems.multiple_choice("c1")])
	var students := InMemoryStudentRepository.new()
	students.save_student(Student.new(STUDENT, "sec-a", "Killa Quispe", PinCredential.new("h", "s")))
	var presenter := StudentHomePresenter.new(GetStudentProfile.new(students, _clock),
		ListLevels.new(_store, _attempts), _session)
	var start := _presenter()
	start.open()
	start.submit("b")
	var home := presenter.home()
	assert_str(home.greeting).is_equal("¡Hola, Killa!")
	assert_int(home.levels.size()).is_equal(2)
	var math := home.levels[0]
	assert_str(math.details).is_equal("Matemática · 3 preguntas · 4 min")
	assert_str(math.action_label).is_equal("Seguir")
	assert_str(math.badge).is_equal("A medias")
	var science := home.levels[1]
	assert_str(science.action_label).is_equal("Jugar")
	assert_str(science.area.name).is_equal("Ciencia y Tecnología")
	presenter.choose(science)
	assert_str(_session.level_package).is_equal("mod-science-6-00")
	presenter.log_out()
	assert_str(_session.level_package).is_empty()


func test_numbers_never_break_across_lines() -> void:
	var nbsp := PlayMessages.NO_BREAK
	assert_str(PlayMessages.keep_numbers_together("Vale 50 000 en total.")).is_equal("Vale 50%s000 en total." % nbsp)
	assert_str(PlayMessages.keep_numbers_together("Cuesta S/ 45 cada uno.")).is_equal("Cuesta S/%s45 cada uno." % nbsp)
	assert_str(PlayMessages.keep_numbers_together("Son 3 y 4.")).is_equal("Son 3 y 4.")
	var tidy: Dictionary = PlayMessages.tidy({"id": "1 2", "options": [{"id": "a", "text": "1 254 300"}]})
	assert_str(tidy["id"]).is_equal("1 2")
	assert_str(tidy["options"][0]["text"]).is_equal("1%s254%s300" % [nbsp, nbsp])
	assert_bool(TextAnswer.matches("1%s440" % nbsp, ["1 440"])).is_true()

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


func _map() -> MapPresenter:
	var students := InMemoryStudentRepository.new()
	students.save_student(Student.new(STUDENT, "sec-a", "Killa Quispe", PinCredential.new("h", "s")))
	return MapPresenter.new(GetStudentProfile.new(students, _clock), GetChapterMap.new(_store, _attempts), _session)


func test_the_map_shows_the_stops_of_the_sierra() -> void:
	_store.add_module("mod-math-6-01", "math", [{"id": "L01", "mechanic": "chase"}, {"id": "DF", "kind": "final"}],
		[SampleItems.multiple_choice("m1")])
	var chapter := _map().chapter()
	assert_str(chapter.greeting).is_equal("¡Hola, Killa!")
	assert_str(chapter.chapter_title).is_equal("Las alturas de Ayacucho")
	assert_int(chapter.stops.size()).is_equal(4)
	assert_str(chapter.stops[0].name).is_equal("Huamanga")
	assert_bool(chapter.stops[0].available).is_true()
	assert_str(chapter.stops[0].icon).is_equal("stop_huamanga")
	assert_bool(chapter.stops[1].available).is_false()
	assert_str(chapter.stops[1].locked_text).is_equal(MapMessages.LOCKED)
	assert_str(chapter.stops[2].name).is_equal("Pampa Galeras")
	assert_int(chapter.current).is_equal(0)


func test_a_stop_shows_its_trails_and_what_opens_next() -> void:
	_store.add_module("mod-math-6-01", "math", [{"id": "L01", "mechanic": "chase"}, {"id": "L02", "mechanic": "caiman"},
		{"id": "DF", "kind": "final"}], [SampleItems.multiple_choice("m1")])
	var presenter := _map()
	var stop := presenter.stop("huamanga")
	assert_str(stop.name).is_equal("Huamanga")
	assert_str(_session.stop_id).is_equal("huamanga")
	var trail := stop.trails[0]
	assert_str(trail.title).is_equal("Sendero de Matemática")
	assert_str(trail.stars_label).is_equal("0 / 6")
	var chase := trail.nodes[0]
	assert_str(chase.mechanic_name).is_equal("Persecución")
	assert_str(chase.icon).is_equal("mech_chase")
	assert_str(chase.details).is_equal("1 preguntas · 4 min · 3 vidas")
	assert_bool(chase.next).is_true()
	assert_str(chase.action_label).is_equal(MapMessages.PLAY)
	var caiman := trail.nodes[1]
	assert_str(caiman.state).is_equal(TrailRule.LOCKED)
	assert_bool(caiman.playable).is_false()
	assert_str(caiman.locked_text).is_equal("Completa «Nivel L01» para abrir este nivel.")
	assert_bool(presenter.choose(caiman)).is_false()
	var final := trail.nodes[2]
	assert_bool(final.final).is_true()
	assert_str(final.mechanic_name).is_equal("Desafío final")
	assert_str(final.attempts_text).is_equal("Te quedan 2 de 2 intentos.")
	assert_bool(presenter.choose(chase)).is_true()
	assert_str(_session.level_package).is_equal("mod-math-6-01")
	presenter.log_out()
	assert_str(_session.stop_id).is_empty()


func test_losing_a_life_is_explained_and_game_over_is_kind() -> void:
	_store.add_module("mod-math-6-01", "math", [{"id": "L01", "mechanic": "caiman", "lives": 2}],
		[SampleItems.multiple_choice("m1"), SampleItems.multiple_choice("m2"), SampleItems.multiple_choice("m3"),
		SampleItems.multiple_choice("m4")])
	_session.choose_level("mod-math-6-01", "L01")
	var presenter := _presenter()
	var intro := presenter.open()
	assert_str(intro.mechanic).is_equal("caiman")
	assert_int(intro.lives).is_equal(2)
	assert_str(intro.dialogue.lines[-1].text).is_equal(PlayMessages.mechanic_intro(&"caiman"))
	presenter.submit("a")
	presenter.next()
	var lost := presenter.submit("a")
	assert_bool(lost.life_lost).is_true()
	assert_str(lost.notes[0]).is_equal(PlayMessages.life_lost(&"caiman"))
	assert_int(lost.lives).is_equal(1)
	presenter.next()
	presenter.submit("a")
	presenter.next()
	var over := presenter.submit("a")
	assert_bool(over.game_over).is_true()
	assert_bool(over.finished).is_true()
	assert_array(over.notes).not_contains([PlayMessages.WILL_RETURN])
	var result := presenter.finish()
	assert_bool(result.game_over).is_true()
	assert_str(result.heading).is_equal("¡Coco se comió tus nudos!")
	assert_str(result.replay_label).is_equal(PlayMessages.GAME_OVER_RETRY)
	assert_array(result.lines).contains(["Respondiste 4 de 4 preguntas."])


func test_the_final_challenge_hides_answers_until_the_grade() -> void:
	_store.add_module("mod-math-6-01", "math", [{"id": "DF", "kind": "final"}],
		[SampleItems.multiple_choice("m1"), SampleItems.multiple_choice("m2")])
	_session.choose_level("mod-math-6-01", "DF")
	var presenter := _presenter()
	var intro := presenter.open()
	assert_bool(intro.final).is_true()
	assert_str(intro.cover.attempt_label).is_equal("Intento 1 de 2")
	assert_str(intro.step.check_label).is_equal(PlayMessages.SAVE_ANSWER)
	assert_bool(intro.step.hint_available).is_false()
	var saved := presenter.submit("a")
	assert_bool(saved.final).is_true()
	assert_bool(saved.correct).is_false()
	assert_str(saved.title).is_equal(PlayMessages.ANSWER_SAVED)
	assert_str(saved.message).is_empty()
	presenter.next()
	presenter.submit("b")
	var result := presenter.finish()
	assert_bool(result.final).is_true()
	assert_str(result.grade).is_equal("C")
	assert_str(result.percent_label).is_equal("50 %")
	assert_str(result.cord_label).is_equal("¡Recuperaste la cuerda de los números!")
	assert_bool(result.golden_knot).is_false()
	assert_str(result.attempts_label).is_equal("Te queda 1 de 2 intentos.")
	assert_int(result.review.size()).is_equal(2)
	assert_str(result.review[0].solution).is_equal("La respuesta era: 50%s000" % PlayMessages.NO_BREAK)


func test_numbers_never_break_across_lines() -> void:
	var nbsp := PlayMessages.NO_BREAK
	assert_str(PlayMessages.keep_numbers_together("Vale 50 000 en total.")).is_equal("Vale 50%s000 en total." % nbsp)
	assert_str(PlayMessages.keep_numbers_together("Cuesta S/ 45 cada uno.")).is_equal("Cuesta S/%s45 cada uno." % nbsp)
	assert_str(PlayMessages.keep_numbers_together("Son 3 y 4.")).is_equal("Son 3 y 4.")
	var tidy: Dictionary = PlayMessages.tidy({"id": "1 2", "options": [{"id": "a", "text": "1 254 300"}]})
	assert_str(tidy["id"]).is_equal("1 2")
	assert_str(tidy["options"][0]["text"]).is_equal("1%s254%s300" % [nbsp, nbsp])
	assert_bool(TextAnswer.matches("1%s440" % nbsp, ["1 440"])).is_true()

extends GdUnitTestSuite
## Casos de uso del motor de actividades: empezar, responder, pedir pista, seguir, terminar
## y continuar un nivel que quedó a medias (RF-12, RF-14, RF-26, RF-29 y RNF-06).

const STUDENT := "stu-1"
const PACKAGE := "mod-math-6-00"

var _store: FakePackageStore
var _attempts: InMemoryAttemptRepository
var _sessions: InMemoryLevelSessionStore
var _registry: EvaluatorRegistry
var _builder: StepBuilder
var _ids: SequentialIds
var _clock: FakeClock


func before_test() -> void:
	_store = FakePackageStore.new()
	_store.add("math", [SampleItems.multiple_choice("q1", "Mira el tablero."), SampleItems.true_false("q2"),
		SampleItems.ordering("q3")])
	_attempts = InMemoryAttemptRepository.new()
	_sessions = InMemoryLevelSessionStore.new()
	_registry = EvaluatorRegistry.standard()
	_builder = StepBuilder.new(ScriptedRandom.new([0]))
	_ids = SequentialIds.new()
	_clock = FakeClock.new()


func _start(sessions: LevelSessionStore = _sessions) -> LevelStartResponse:
	var started := StartLevel.new(_store, _attempts, sessions, _registry, _builder, _ids, _clock).execute(
		STUDENT, PACKAGE, "L01")
	assert_bool(started.is_ok()).override_failure_message(started.message).is_true()
	return started.value


func _submit(attempt_id: String, answer: Variant) -> AnswerResponse:
	return SubmitAnswer.new(_sessions, _attempts, _ids, _clock).execute(attempt_id, answer).value


func _continue(attempt_id: String) -> StepResponse:
	return ContinueLevel.new(_sessions, _builder, _clock).execute(attempt_id).value


func test_start_creates_an_attempt_and_shows_the_first_question() -> void:
	var start := _start()
	assert_str(start.title).is_equal("Nivel de prueba")
	assert_array(start.guide_intro).is_equal(["¡Hola!"])
	assert_int(start.total).is_equal(3)
	assert_bool(start.resumed).is_false()
	var step := start.step
	assert_str(step.question_id).is_equal("q1")
	assert_str(step.type).is_equal("multiple_choice")
	assert_int(step.number).is_equal(1)
	assert_bool(step.hint_available).is_true()
	assert_array(step.progress).is_equal([&"current", &"pending", &"pending"])
	for option: Dictionary in step.data["options"]:
		assert_bool(option.has("correct")).is_false()
	var open := _attempts.find_open_attempt(STUDENT, "%s/L01" % PACKAGE)
	assert_str(open.id).is_equal(start.attempt_id)
	assert_str(open.package_version).is_equal("1.0.0")


func test_an_unknown_level_cannot_start() -> void:
	var started := StartLevel.new(_store, _attempts, _sessions, _registry, _builder, _ids, _clock).execute(
		STUDENT, PACKAGE, "L09")
	assert_str(started.error).is_equal("level_unavailable")


func test_each_answer_is_saved_with_its_feedback() -> void:
	var start := _start()
	_clock.advance(4000)
	var response := _submit(start.attempt_id, "a")
	assert_bool(response.accepted).is_true()
	assert_bool(response.correct).is_false()
	assert_str(response.feedback).is_equal("Fíjate en la posición.")
	assert_bool(response.will_return).is_true()
	assert_bool(response.saved).is_true()
	assert_array(response.progress).is_equal([&"missed", &"pending", &"pending"])
	var saved := _attempts.list_answers(start.attempt_id)
	assert_int(saved.size()).is_equal(1)
	assert_str(saved[0].item_id).is_equal("q1")
	assert_str(saved[0].value).is_equal("a")
	assert_int(saved[0].time_ms).is_equal(4000)


func test_an_incomplete_answer_is_not_saved() -> void:
	var start := _start()
	assert_bool(_submit(start.attempt_id, "zz").accepted).is_false()
	assert_array(_attempts.list_answers(start.attempt_id)).is_empty()


func test_a_hint_is_recorded_with_the_answer() -> void:
	var start := _start()
	assert_str(RequestHint.new(_sessions).execute(start.attempt_id)).is_equal("Mira el tablero.")
	_submit(start.attempt_id, "b")
	assert_bool(_attempts.list_answers(start.attempt_id)[0].with_hint).is_true()
	assert_str(RequestHint.new(_sessions).execute("otro")).is_empty()


func test_play_to_the_end_and_save_the_stars() -> void:
	var start := _start()
	_submit(start.attempt_id, "b")
	assert_str(_continue(start.attempt_id).question_id).is_equal("q2")
	_submit(start.attempt_id, {"s1": true, "s2": false})
	var third := _continue(start.attempt_id)
	assert_str(third.question_id).is_equal("q3")
	var last := _submit(start.attempt_id, ["y", "x", "z"])
	assert_bool(last.finished).is_true()
	assert_object(_continue(start.attempt_id)).is_null()
	var finished := FinishLevel.new(_sessions, _attempts, _clock).execute(start.attempt_id)
	var summary: LevelSummaryResponse = finished.value
	assert_int(summary.stars).is_equal(3)
	assert_int(summary.correct).is_equal(3)
	assert_float(summary.percent).is_equal(100.0)
	assert_int(summary.best_before).is_equal(0)
	assert_bool(summary.saved).is_true()
	assert_object(_attempts.find_open_attempt(STUDENT, "%s/L01" % PACKAGE)).is_null()
	assert_dict(_attempts.best_stars(STUDENT)).is_equal({"%s/L01" % PACKAGE: 3})
	assert_object(_sessions.find(start.attempt_id)).is_null()


func test_cannot_finish_with_questions_left() -> void:
	var start := _start()
	assert_str(FinishLevel.new(_sessions, _attempts, _clock).execute(start.attempt_id).error).is_equal("level_unfinished")


func test_a_closed_game_continues_where_it_stopped() -> void:
	var start := _start()
	_submit(start.attempt_id, "a")
	_continue(start.attempt_id)
	_submit(start.attempt_id, {"s1": true, "s2": false})
	var resumed := _start(InMemoryLevelSessionStore.new())
	assert_str(resumed.attempt_id).is_equal(start.attempt_id)
	assert_bool(resumed.resumed).is_true()
	assert_int(resumed.answered).is_equal(2)
	assert_str(resumed.step.question_id).is_equal("q3")
	assert_array(resumed.step.progress).is_equal([&"missed", &"right", &"current"])


func test_a_new_content_version_starts_a_new_attempt() -> void:
	var start := _start()
	_submit(start.attempt_id, "b")
	_store.add("math", [SampleItems.multiple_choice("q1"), SampleItems.true_false("q2")], "1.1.0")
	var again := _start(InMemoryLevelSessionStore.new())
	assert_str(again.attempt_id).is_not_equal(start.attempt_id)
	assert_bool(again.resumed).is_false()
	assert_int(again.total).is_equal(2)


func test_the_level_list_shows_stars_and_unfinished_levels() -> void:
	_store.add("science", [SampleItems.multiple_choice("c1")])
	var cards := ListLevels.new(_store, _attempts).execute(STUDENT)
	assert_int(cards.size()).is_equal(2)
	assert_str(cards[0].title).is_equal("Nivel de prueba")
	assert_int(cards[0].question_count).is_equal(3)
	assert_bool(cards[0].in_progress).is_false()
	var start := _start()
	_submit(start.attempt_id, "b")
	assert_bool(ListLevels.new(_store, _attempts).execute(STUDENT)[0].in_progress).is_true()


func test_bundled_packages_are_registered_with_their_levels() -> void:
	_store.add("science", [SampleItems.multiple_choice("c1")])
	var packages := InMemoryPackageRepository.new()
	assert_int(RegisterBundledPackages.new(_store, packages).execute()).is_equal(2)
	assert_array(packages.packages["mod-science-6-00"]).is_equal(["mod-science-6-00/L01"])


func test_ordering_never_starts_solved() -> void:
	_store.add("math", [SampleItems.ordering("q1")])
	for seed in [0, 1, 2]:
		_builder = StepBuilder.new(ScriptedRandom.new([seed]))
		var step := _start(InMemoryLevelSessionStore.new()).step
		var ids: Array = step.data["elements"].map(func(element: Dictionary) -> String: return element["id"])
		assert_array(ids).is_not_equal(["y", "x", "z"])


func test_step_data_per_type_hides_the_answers() -> void:
	_store.add("math", [SampleItems.fill_blank("q1"), SampleItems.numeric("q2"), SampleItems.matching("q3"),
		SampleItems.classification("q4"), SampleItems.reading_unit("ru")])
	var start := _start()
	var fill := start.step
	assert_array(fill.data["typed"]).is_equal(["2"])
	assert_int(fill.data["bank"].size()).is_equal(3)
	_submit(start.attempt_id, {"1": "pero", "2": "porque"})
	var number := _continue(start.attempt_id)
	assert_bool(number.data["fraction"]).is_true()
	assert_bool(number.data["unit_first"]).is_false()
	_submit(start.attempt_id, "1/2")
	var match_step := _continue(start.attempt_id)
	assert_int(match_step.data["right"].size()).is_equal(3)
	assert_bool(match_step.data.has("pairs")).is_false()
	_submit(start.attempt_id, {"l1": "r2", "l2": "r1"})
	var classify := _continue(start.attempt_id)
	for element: Dictionary in classify.data["elements"]:
		assert_bool(element.has("group")).is_false()
	_submit(start.attempt_id, {"n2": "even", "n7": "odd", "n10": "even"})
	var reading := _continue(start.attempt_id)
	assert_str(reading.unit["title"]).is_equal("La feria")
	assert_int(reading.unit["paragraphs"].size()).is_equal(2)
	assert_str(reading.question_id).is_equal("ru-1")

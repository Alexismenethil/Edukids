extends GdUnitTestSuite
## Integración: paquetes, niveles, intentos y respuestas en SQLite (RNF-06).

const MIGRATIONS := "res://src/infrastructure/sqlite/migrations"
const LEVEL := "mod-math-6-00/L01"

var _path := TestDatabase.path_for("sqlite_play")
var _db: SqliteDatabase
var _packages: SqlitePackageRepository
var _attempts: SqliteAttemptRepository
var _clock: FakeClock


func before_test() -> void:
	TestDatabase.remove(_path)
	_db = SqliteDatabase.open(_path).value
	SqliteMigrator.new(_db, MIGRATIONS).migrate()
	_clock = FakeClock.new()
	_packages = SqlitePackageRepository.new(_db, _clock)
	_attempts = SqliteAttemptRepository.new(_db)
	var sections: Array[Section] = [Section.new("sec-a", "A")]
	SqliteInstitutionRepository.new(_db).save_setup(Institution.new("ins-1", "Escuela de prueba", "", 6, 2026, ""),
		sections, Teacher.new("tea-1", "Rosa", PinCredential.new("h", "s")))
	SqliteStudentRepository.new(_db).save_student(Student.new("stu-1", "sec-a", "Killa", PinCredential.new("h", "s")))


func after_test() -> void:
	_db.close()
	TestDatabase.remove(_path)


func _register() -> Level:
	var level := SampleItems.level([SampleItems.multiple_choice("q1"), SampleItems.true_false("q2")])
	var package: ContentPackage = ContentPackage.parse(SampleItems.manifest()).value
	package.location = "res://content/packages/mod-math-6-00"
	var levels: Array[Level] = [level]
	assert_bool(_packages.save_package(package, levels).is_ok()).is_true()
	return level


func _attempt(attempt_id: String, level: Level) -> Attempt:
	var attempt := Attempt.start(attempt_id, "stu-1", level, _clock.now_unix_ms())
	assert_bool(_attempts.create_attempt(attempt).is_ok()).is_true()
	return attempt


func _answer(answer_id: String, attempt_id: String, item_id: String, value: Variant, correct: bool) -> AttemptAnswer:
	var answer := AttemptAnswer.new()
	answer.id = answer_id
	answer.attempt_id = attempt_id
	answer.item_id = item_id
	answer.value = value
	answer.is_correct = correct
	answer.time_ms = 3200
	answer.answered_at_ms = _clock.now_unix_ms()
	return answer


func test_registering_a_package_twice_keeps_one_row() -> void:
	_register()
	_register()
	var rows: Array = _db.query("SELECT id, title, position FROM level;").value
	assert_int(rows.size()).is_equal(1)
	assert_str(str(rows[0]["id"])).is_equal(LEVEL)
	assert_str(str(rows[0]["title"])).is_equal("Nivel de prueba")
	var packages: Array = _db.query("SELECT install_path FROM package;").value
	assert_str(str(packages[0]["install_path"])).is_equal("res://content/packages/mod-math-6-00")


func test_an_attempt_needs_a_registered_level() -> void:
	var level := SampleItems.level([SampleItems.multiple_choice("q1")])
	var attempt := Attempt.start("att-x", "stu-1", level, _clock.now_unix_ms())
	assert_bool(_attempts.create_attempt(attempt).is_ok()).is_false()


func test_answers_are_saved_and_read_in_order() -> void:
	var level := _register()
	_attempt("att-1", level)
	assert_bool(_attempts.save_answer(_answer("ans-1", "att-1", "q1", "a", false)).is_ok()).is_true()
	assert_bool(_attempts.save_answer(_answer("ans-2", "att-1", "q2", {"s1": true, "s2": false}, true)).is_ok()).is_true()
	var answers := _attempts.list_answers("att-1")
	assert_int(answers.size()).is_equal(2)
	assert_str(answers[0].item_id).is_equal("q1")
	assert_bool(answers[0].is_correct).is_false()
	assert_str(answers[0].value).is_equal("a")
	assert_dict(answers[1].value).is_equal({"s1": true, "s2": false})
	assert_int(answers[1].time_ms).is_equal(3200)


func test_the_open_attempt_is_the_latest_unfinished_one() -> void:
	var level := _register()
	_attempt("att-1", level)
	_clock.advance(60_000)
	_attempt("att-2", level)
	var open := _attempts.find_open_attempt("stu-1", LEVEL)
	assert_str(open.id).is_equal("att-2")
	assert_str(open.package_version).is_equal("1.0.0")
	assert_int(open.total_count).is_equal(2)
	assert_object(_attempts.find_open_attempt("stu-1", "otro/L01")).is_null()


func test_finishing_saves_the_result_and_the_best_stars() -> void:
	var level := _register()
	var first := _attempt("att-1", level)
	var summary := LevelSummary.new()
	summary.total = 2
	summary.correct = 1
	summary.percent = 50.0
	summary.stars = 1
	summary.hints_used = 1
	first.complete(summary, _clock.now_unix_ms() + 90_000)
	assert_bool(_attempts.finish_attempt(first).is_ok()).is_true()
	var second := _attempt("att-2", level)
	summary.stars = 3
	second.complete(summary, _clock.now_unix_ms() + 120_000)
	_attempts.finish_attempt(second)
	_attempt("att-3", level)
	assert_dict(_attempts.best_stars("stu-1")).is_equal({LEVEL: 3})
	var rows: Array = _db.query("SELECT status, percent, hints_used, finished_at FROM attempt WHERE id = 'att-1';").value
	assert_str(str(rows[0]["status"])).is_equal("completed")
	assert_float(float(rows[0]["percent"])).is_equal(50.0)
	assert_int(int(rows[0]["hints_used"])).is_equal(1)
	assert_str(str(rows[0]["finished_at"])).is_equal("2026-11-07T00:01:30Z")
	assert_str(_attempts.find_open_attempt("stu-1", LEVEL).id).is_equal("att-3")


func test_game_overs_and_final_grades_are_kept() -> void:
	var level := _register()
	var practice := Attempt.start("att-go", "stu-1", level, 1000)
	assert_bool(_attempts.create_attempt(practice).is_ok()).is_true()
	var lost := LevelSummary.new()
	lost.total = 2
	lost.game_over = true
	lost.lives_lost = 3
	practice.complete(lost, 2000)
	assert_bool(_attempts.finish_attempt(practice).is_ok()).is_true()
	var final := Attempt.start("att-df", "stu-1", level, 3000)
	final.kind = Attempt.FINAL
	assert_bool(_attempts.create_attempt(final).is_ok()).is_true()
	var graded := LevelSummary.new()
	graded.total = 2
	graded.correct = 2
	graded.percent = 100.0
	graded.final = true
	graded.grade = CnebGradeScale.new().grade(2, 2)
	final.complete(graded, 4000)
	assert_bool(_attempts.finish_attempt(final).is_ok()).is_true()
	var attempts := _attempts.list_attempts("stu-1")
	assert_int(attempts.size()).is_equal(2)
	assert_str(attempts[0].status).is_equal(Attempt.GAME_OVER)
	assert_int(attempts[0].lives_lost).is_equal(3)
	assert_str(attempts[1].cneb_grade).is_equal("AD")
	assert_str(attempts[1].kind).is_equal(Attempt.FINAL)
	assert_dict(_attempts.best_stars("stu-1")).is_equal({level.key(): 0})
	assert_array(_attempts.list_attempts("nadie")).is_empty()

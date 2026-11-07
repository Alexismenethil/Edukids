extends GdUnitTestSuite
## Sesión de un nivel de práctica (RF-12, RF-26, RF-29, RN-11) y lectura del manifiesto y del nivel.


func _session(items: Array) -> LevelSession:
	return LevelSession.new(SampleItems.level(items), EvaluatorRegistry.standard(), "attempt-1")


func _order(session: LevelSession) -> Array[String]:
	var ids: Array[String] = []
	var step := session.current()
	while step:
		ids.append(step.item.id)
		session.submit(_right_answer(step.item), 0)
		step = session.current()
	return ids


func _right_answer(item: Item) -> Variant:
	match item.type:
		ItemType.MULTIPLE_CHOICE:
			return item.spec["correct"]
		ItemType.TRUE_FALSE:
			var answer := {}
			for statement: Dictionary in item.spec["statements"]:
				answer[statement["id"]] = statement["answer"]
			return answer
	return null


func test_reading_units_unfold_into_their_questions() -> void:
	var session := _session([SampleItems.multiple_choice("q1"), SampleItems.reading_unit("ru"),
		SampleItems.true_false("q2")])
	assert_int(session.question_count()).is_equal(4)
	assert_str(session.current().item.id).is_equal("q1")
	assert_object(session.current().unit).is_null()
	session.submit("b", 0)
	assert_str(session.current().item.id).is_equal("ru-1")
	assert_str(session.current().unit.id).is_equal("ru")
	assert_array(_order(session)).is_equal(["ru-1", "ru-2", "q2"])
	assert_bool(session.is_finished()).is_true()


func test_a_right_answer_moves_on_with_its_feedback() -> void:
	var session := _session([SampleItems.multiple_choice("q1"), SampleItems.true_false("q2")])
	var outcome := session.submit("b", 0)
	assert_bool(outcome.is_correct()).is_true()
	assert_str(outcome.feedback).is_equal("¡Bien!")
	assert_bool(outcome.first_try).is_true()
	assert_bool(outcome.will_return).is_false()
	assert_bool(outcome.finished).is_false()
	assert_str(session.current().item.id).is_equal("q2")
	assert_int(session.current_number()).is_equal(2)


func test_an_incomplete_answer_is_not_counted() -> void:
	var session := _session([SampleItems.multiple_choice("q1")])
	var outcome := session.submit("zz", 0)
	assert_bool(outcome.accepted).is_false()
	assert_str(outcome.reason).is_equal("answer_incomplete")
	assert_str(session.current().item.id).is_equal("q1")
	assert_int(session.answered_count()).is_equal(0)


func test_a_missed_question_returns_once_at_the_end() -> void:
	var session := _session([SampleItems.multiple_choice("q1"), SampleItems.true_false("q2")])
	var missed := session.submit("a", 0)
	assert_bool(missed.will_return).is_true()
	assert_str(missed.feedback).is_equal("Fíjate en la posición.")
	assert_str(missed.solution).is_empty()
	session.submit({"s1": true, "s2": false}, 0)
	assert_str(session.current().item.id).is_equal("q1")
	assert_bool(session.current().retry).is_true()
	var again := session.submit("c", 0)
	assert_bool(again.first_try).is_false()
	assert_bool(again.will_return).is_false()
	assert_str(again.solution).is_equal("50 000")
	assert_bool(again.finished).is_true()
	var summary := session.summary()
	assert_int(summary.total).is_equal(2)
	assert_int(summary.correct).is_equal(1)
	assert_int(summary.fixed).is_equal(0)


func test_fixing_a_question_in_the_review_does_not_give_stars() -> void:
	var session := _session([SampleItems.multiple_choice("q1"), SampleItems.true_false("q2")])
	session.submit("a", 0)
	session.submit({"s1": true, "s2": false}, 0)
	assert_bool(session.submit("b", 0).is_correct()).is_true()
	var summary := session.summary()
	assert_int(summary.correct).is_equal(1)
	assert_int(summary.fixed).is_equal(1)
	assert_int(summary.valid_hits).is_equal(1)
	assert_float(summary.percent).is_equal(50.0)
	assert_int(summary.stars).is_equal(1)
	assert_bool(summary.completed).is_true()


func test_a_hint_keeps_the_answer_but_not_the_valid_hit() -> void:
	var session := _session([SampleItems.multiple_choice("q1", "Usa el tablero."), SampleItems.true_false("q2")])
	assert_str(session.take_hint()).is_equal("Usa el tablero.")
	assert_bool(session.hint_shown()).is_true()
	var outcome := session.submit("b", 0)
	assert_bool(outcome.with_hint).is_true()
	assert_bool(session.hint_shown()).is_false()
	assert_str(session.take_hint()).is_empty()
	session.submit({"s1": true, "s2": false}, 0)
	var summary := session.summary()
	assert_int(summary.correct).is_equal(2)
	assert_int(summary.valid_hits).is_equal(1)
	assert_int(summary.hints_used).is_equal(1)
	assert_int(summary.stars).is_equal(1)


func test_all_valid_hits_give_three_stars() -> void:
	var session := _session([SampleItems.multiple_choice("q1"), SampleItems.true_false("q2")])
	_order(session)
	assert_int(session.summary().stars).is_equal(3)
	assert_float(session.summary().percent).is_equal(100.0)


func test_two_misses_in_a_row_make_the_guide_offer_a_hint() -> void:
	var session := _session([SampleItems.multiple_choice("q1"), SampleItems.multiple_choice("q2"),
		SampleItems.multiple_choice("q3", "Cuenta las cifras."), SampleItems.multiple_choice("q4", "Otra pista.")])
	assert_bool(session.submit("a", 0).offer_hint).is_false()
	var second := session.submit("a", 0)
	assert_bool(second.offer_hint).is_true()
	assert_bool(session.hint_offered()).is_true()
	assert_bool(session.submit("a", 0).offer_hint).is_false()
	assert_bool(session.hint_offered()).is_false()


func test_no_offer_when_the_next_question_has_no_hint() -> void:
	var session := _session([SampleItems.multiple_choice("q1"), SampleItems.multiple_choice("q2"),
		SampleItems.multiple_choice("q3")])
	session.submit("a", 0)
	assert_bool(session.submit("a", 0).offer_hint).is_false()


func test_progress_shows_each_question() -> void:
	var session := _session([SampleItems.multiple_choice("q1"), SampleItems.true_false("q2"),
		SampleItems.multiple_choice("q3")])
	assert_array(session.progress()).is_equal([&"current", &"pending", &"pending"])
	session.submit("a", 0)
	session.submit({"s1": true, "s2": false}, 0)
	assert_array(session.progress()).is_equal([&"missed", &"right", &"current"])
	session.submit("b", 0)
	assert_array(session.progress()).is_equal([&"current", &"right", &"right"])
	session.submit("b", 0)
	assert_array(session.progress()).is_equal([&"fixed", &"right", &"right"])


func test_time_per_answer() -> void:
	var session := _session([SampleItems.multiple_choice("q1")])
	session.begin_step(1000)
	assert_int(session.submit("b", 4500).time_ms).is_equal(3500)


func test_restore_continues_where_it_stopped() -> void:
	var items := [SampleItems.multiple_choice("q1", "Pista"), SampleItems.true_false("q2"),
		SampleItems.multiple_choice("q3")]
	var played := _session(items)
	var answers: Array[AttemptAnswer] = []
	played.take_hint()
	answers.append(AttemptAnswer.from_outcome("a1", "attempt-1", played.submit("b", 0), "b", 0))
	answers.append(AttemptAnswer.from_outcome("a2", "attempt-1", played.submit({"s1": false, "s2": false}, 0), {}, 0))
	var restored := _session(items)
	assert_bool(restored.restore(answers)).is_true()
	assert_str(restored.current().item.id).is_equal("q3")
	assert_int(restored.answered_count()).is_equal(2)
	assert_array(restored.progress()).is_equal(played.progress())
	assert_int(restored.summary().hints_used).is_equal(1)
	restored.submit("b", 0)
	assert_str(restored.current().item.id).is_equal("q2")
	assert_bool(restored.current().retry).is_true()


func test_restore_rejects_answers_from_other_content() -> void:
	var stranger := AttemptAnswer.new()
	stranger.item_id = "otro"
	var answers: Array[AttemptAnswer] = [stranger]
	assert_bool(_session([SampleItems.multiple_choice("q1")]).restore(answers)).is_false()


func test_manifest_is_validated() -> void:
	var parsed := ContentPackage.parse(SampleItems.manifest(["L01", "L02"]))
	assert_bool(parsed.is_ok()).is_true()
	var package: ContentPackage = parsed.value
	assert_int(package.levels.size()).is_equal(2)
	assert_int(package.find_level("L02").position).is_equal(2)
	assert_str(package.level_key("L01")).is_equal("mod-math-6-00/L01")
	var newer := SampleItems.manifest()
	newer["format_version"] = "2.0"
	assert_str(ContentPackage.parse(newer).error).is_equal("manifest_format")
	var bad_area := SampleItems.manifest()
	bad_area["area"] = "art"
	assert_bool(ContentPackage.parse(bad_area).is_ok()).is_false()
	var unsafe := SampleItems.manifest()
	unsafe["levels"][0]["file"] = "../secreto.json"
	assert_bool(ContentPackage.parse(unsafe).is_ok()).is_false()
	assert_bool(ContentPackage.parse(SampleItems.manifest(["L01", "L01"])).is_ok()).is_false()


func test_level_file_is_validated() -> void:
	var package: ContentPackage = ContentPackage.parse(SampleItems.manifest()).value
	var entry := package.find_level("L01")
	var registry := EvaluatorRegistry.standard()
	var good := Level.parse(SampleItems.level_file([SampleItems.reading_unit("ru")]), package, entry, registry)
	assert_bool(good.is_ok()).is_true()
	assert_str((good.value as Level).key()).is_equal("mod-math-6-00/L01")
	assert_int((good.value as Level).question_count()).is_equal(2)
	var other_id := SampleItems.level_file([SampleItems.multiple_choice()], "L09")
	assert_bool(Level.parse(other_id, package, entry, registry).is_ok()).is_false()
	var repeated := SampleItems.level_file([SampleItems.multiple_choice("ru-1"), SampleItems.reading_unit("ru")])
	assert_bool(Level.parse(repeated, package, entry, registry).is_ok()).is_false()
	assert_bool(Level.parse(SampleItems.level_file([]), package, entry, registry).is_ok()).is_false()

extends GdUnitTestSuite
## Vidas, medidor de peligro y game over (RN-13 y RN-14), el desafío final (RN-10 y RN-12)
## y el orden de los niveles de un módulo (RN-18).

var _registry := EvaluatorRegistry.standard()


func _level(count: int, entry: Dictionary = {}) -> Level:
	var items: Array = []
	for index in count:
		items.append(SampleItems.multiple_choice("q%d" % (index + 1), "Pista %d" % (index + 1)))
	var raw := SampleItems.manifest(["L01"])
	for key: String in entry:
		raw["levels"][0][key] = entry[key]
	var package: ContentPackage = ContentPackage.parse(raw).value
	var parsed := Level.parse(SampleItems.level_file(items), package, package.find_level("L01"), _registry)
	assert_bool(parsed.is_ok()).override_failure_message(parsed.message).is_true()
	return parsed.value


func _session(count: int, entry: Dictionary = {}) -> LevelSession:
	return LevelSession.new(_level(count, entry), _registry, "att-1", "stu-1")


func test_a_right_answer_moves_the_danger_away() -> void:
	var session := _session(3)
	assert_int(session.danger()).is_equal(2)
	assert_int(session.lives()).is_equal(3)
	var outcome := session.submit("b", 0)
	assert_int(outcome.danger).is_equal(3)
	assert_int(outcome.streak).is_equal(1)
	assert_bool(outcome.life_lost).is_false()


func test_two_misses_in_a_row_cost_a_life_and_reset_the_meter() -> void:
	var session := _session(4)
	var first := session.submit("a", 0)
	assert_int(first.danger).is_equal(1)
	assert_bool(first.life_lost).is_false()
	var second := session.submit("a", 0)
	assert_bool(second.life_lost).is_true()
	assert_int(second.lives).is_equal(2)
	assert_int(second.danger).is_equal(2)
	assert_bool(second.game_over).is_false()
	assert_int(second.streak).is_equal(0)


func test_losing_every_life_ends_in_game_over() -> void:
	var session := _session(6)
	var outcome: AnswerOutcome
	for index in 6:
		outcome = session.submit("a", 0)
	assert_bool(outcome.game_over).is_true()
	assert_bool(outcome.finished).is_true()
	assert_bool(session.is_finished()).is_true()
	assert_object(session.current()).is_null()
	var summary := session.summary()
	assert_bool(summary.game_over).is_true()
	assert_bool(summary.completed).is_false()
	assert_int(summary.stars).is_equal(0)
	assert_int(summary.lives_lost).is_equal(3)
	assert_bool(session.submit("b", 0).accepted).is_false()


func test_the_level_can_change_lives_and_meter() -> void:
	var session := _session(2, {"lives": 1, "danger": {"start": 1, "max": 3}})
	assert_int(session.lives_max()).is_equal(1)
	assert_int(session.danger_max()).is_equal(3)
	assert_bool(session.submit("a", 0).game_over).is_true()


func test_a_lost_life_takes_away_the_third_star() -> void:
	var session := _session(20)
	session.submit("a", 0)
	session.submit("a", 0)
	while not session.is_finished():
		session.submit("b", 0)
	var summary := session.summary()
	assert_int(summary.lives_lost).is_equal(1)
	assert_int(summary.valid_hits).is_equal(18)
	assert_int(summary.stars).is_equal(2)


func test_streaks_count_right_answers_in_a_row() -> void:
	var session := _session(5)
	session.submit("b", 0)
	session.submit("b", 0)
	assert_int(session.submit("b", 0).streak).is_equal(3)
	assert_int(session.submit("a", 0).streak).is_equal(0)
	assert_int(session.summary().best_streak).is_equal(3)


func test_restoring_recomputes_the_meter_and_lives() -> void:
	var session := _session(5)
	var answers: Array[AttemptAnswer] = []
	for value in ["a", "a", "b"]:
		var outcome := session.submit(value, 0)
		answers.append(AttemptAnswer.from_outcome("ans-%d" % answers.size(), "att-1", outcome, value, 0))
	var again := _session(5)
	assert_bool(again.restore(answers)).is_true()
	assert_int(again.lives()).is_equal(session.lives())
	assert_int(again.danger()).is_equal(session.danger())
	assert_int(again.streak()).is_equal(1)


func test_the_final_challenge_has_no_meter_hints_or_second_chances() -> void:
	var session := _session(4, {"kind": "final"})
	assert_bool(session.is_final()).is_true()
	assert_int(session.lives_max()).is_equal(0)
	assert_str(session.take_hint()).is_empty()
	var wrong := session.submit("a", 0)
	assert_bool(wrong.will_return).is_false()
	assert_bool(wrong.life_lost).is_false()
	assert_array(session.progress(false)).is_equal([LevelSession.ANSWERED, LevelSession.PENDING, LevelSession.PENDING, LevelSession.PENDING])
	session.submit("b", 0)
	session.submit("b", 0)
	session.submit("b", 0)
	assert_bool(session.is_finished()).is_true()
	assert_array(session.progress(false, true)).is_equal([LevelSession.MISSED, LevelSession.RIGHT, LevelSession.RIGHT, LevelSession.RIGHT])
	var summary := session.summary()
	assert_str(summary.grade.code()).is_equal("A")
	assert_float(summary.percent).is_equal(75.0)
	assert_int(summary.stars).is_equal(0)
	var review := session.review()
	assert_int(review.size()).is_equal(4)
	assert_bool(review[0].correct).is_false()
	assert_str(review[0].feedback).is_equal("Fíjate en la posición.")
	assert_str(review[0].solution).is_equal("50 000")
	assert_bool(review[1].correct).is_true()
	assert_str(review[1].solution).is_empty()


func test_the_manifest_checks_mechanics_lives_and_attempts() -> void:
	var raw := {"id": "L01", "kind": "short", "mechanic": "caiman", "file": "levels/l01.json"}
	assert_bool(LevelEntry.parse(raw, 1).is_ok()).is_true()
	assert_int((LevelEntry.parse({"id": "DF", "kind": "final", "mechanic": "classic", "file": "levels/f.json"}, 2).value as LevelEntry).max_attempts).is_equal(2)
	assert_str(LevelEntry.parse({"id": "DF", "kind": "final", "mechanic": "chase", "file": "levels/f.json"}, 2).error).is_equal("manifest_invalid")
	assert_str(LevelEntry.parse({"id": "L1", "kind": "short", "mechanic": "chase", "file": "levels/a.json", "lives": 0}, 1).error).is_equal("manifest_invalid")
	assert_str(LevelEntry.parse({"id": "L1", "kind": "short", "mechanic": "chase", "file": "levels/a.json", "danger": {"start": 5, "max": 4}}, 1).error).is_equal("manifest_invalid")


func _entries() -> Array[LevelEntry]:
	var entries: Array[LevelEntry] = []
	var raws := [
		{"id": "L01", "kind": "short", "mechanic": "chase", "file": "levels/l01.json"},
		{"id": "L02", "kind": "regular", "mechanic": "bridge", "file": "levels/l02.json"},
		{"id": "DF", "kind": "final", "mechanic": "classic", "file": "levels/final.json", "max_attempts": 2},
	]
	for index in raws.size():
		entries.append(LevelEntry.parse(raws[index], index + 1).value)
	return entries


func test_practice_levels_open_one_after_another() -> void:
	var entries := _entries()
	assert_dict(TrailRule.states(entries, {})).is_equal({"L01": TrailRule.OPEN, "L02": TrailRule.LOCKED, "DF": TrailRule.LOCKED})
	assert_dict(TrailRule.states(entries, {"L01": true})).is_equal({"L01": TrailRule.DONE, "L02": TrailRule.OPEN, "DF": TrailRule.LOCKED})
	assert_dict(TrailRule.states(entries, {"L01": true, "L02": true})).is_equal({"L01": TrailRule.DONE, "L02": TrailRule.DONE, "DF": TrailRule.OPEN})
	assert_str(TrailRule.states(entries, {"L01": true, "L02": true, "DF": true})["DF"]).is_equal(TrailRule.DONE)


func test_the_final_challenge_has_limited_attempts() -> void:
	var entries := _entries()
	assert_int(TrailRule.attempts_left(entries[2], 0)).is_equal(2)
	assert_int(TrailRule.attempts_left(entries[2], 2)).is_equal(0)
	assert_int(TrailRule.attempts_left(entries[0], 0)).is_equal(0)
	assert_array(Chapter.stops_of(Chapter.SIERRA)).is_equal(["huamanga", "quinua", "pampa-galeras", "vilcashuaman"])

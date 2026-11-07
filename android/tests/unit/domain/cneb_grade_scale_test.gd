extends GdUnitTestSuite
## RN-12 y RF-30: escala AD, A, B y C del desafío final.


func test_default_scale(correct: int, total: int, expected_code: String, test_parameters := [
	[20, 20, "AD"],
	[18, 20, "AD"],
	[17, 19, "A"],
	[14, 20, "A"],
	[69, 100, "B"],
	[11, 20, "B"],
	[54, 100, "C"],
	[0, 20, "C"],
]) -> void:
	var scale := CnebGradeScale.new()
	assert_str(scale.grade(correct, total).code()).is_equal(expected_code)


func test_grade_keeps_the_percent() -> void:
	var grade := CnebGradeScale.new().grade(17, 20)
	assert_float(grade.percent).is_equal_approx(85.0, 0.001)
	assert_str(grade.description()).is_equal("Logro esperado")


func test_empty_challenge_is_graded_c() -> void:
	assert_str(CnebGradeScale.new().grade(0, 0).code()).is_equal("C")


func test_teacher_can_adjust_the_scale() -> void:
	var created := CnebGradeScale.create(85, 65, 50)
	assert_bool(created.is_ok()).is_true()
	var scale: CnebGradeScale = created.value
	assert_str(scale.grade(17, 20).code()).is_equal("AD")
	assert_str(scale.grade(10, 20).code()).is_equal("B")


func test_invalid_scales_are_rejected() -> void:
	assert_that(CnebGradeScale.create(70, 90, 55).error).is_equal(&"invalid_scale")
	assert_that(CnebGradeScale.create(101, 70, 55).error).is_equal(&"invalid_scale")
	assert_that(CnebGradeScale.create(90, 70, 0).error).is_equal(&"invalid_scale")

extends GdUnitTestSuite
## Respuestas escritas y numéricas: lo que el estudiante escribe y cómo se compara.


func test_text_ignores_case_accents_and_marks() -> void:
	assert_str(TextAnswer.normalize("  ¡Pero!  ")).is_equal("pero")
	assert_str(TextAnswer.normalize("ÁRBOL  Grande.")).is_equal("arbol grande")
	assert_str(TextAnswer.normalize("Ñandú")).is_equal("nandu")
	assert_bool(TextAnswer.matches("Porqué", ["porque"])).is_true()
	assert_bool(TextAnswer.matches("pues", ["porque"])).is_false()
	assert_bool(TextAnswer.matches("   ", ["porque"])).is_false()


func test_integers_and_decimals_with_comma_or_point() -> void:
	assert_float((NumberAnswer.parse("1440").value as NumberAnswer).value).is_equal(1440.0)
	assert_float((NumberAnswer.parse("1 440").value as NumberAnswer).value).is_equal(1440.0)
	assert_float((NumberAnswer.parse("0,5").value as NumberAnswer).value).is_equal(0.5)
	assert_float((NumberAnswer.parse("0.5").value as NumberAnswer).value).is_equal(0.5)
	assert_float((NumberAnswer.parse(",25").value as NumberAnswer).value).is_equal(0.25)
	assert_float((NumberAnswer.parse("-3,5").value as NumberAnswer).value).is_equal(-3.5)
	assert_str((NumberAnswer.parse("12").value as NumberAnswer).format).is_equal("decimal")


func test_fractions_and_mixed_numbers() -> void:
	var half: NumberAnswer = NumberAnswer.parse("1/2").value
	assert_float(half.value).is_equal(0.5)
	assert_str(half.format).is_equal("fraction")
	assert_float((NumberAnswer.parse("1 1/2").value as NumberAnswer).value).is_equal(1.5)
	assert_float((NumberAnswer.parse("3 / 4").value as NumberAnswer).value).is_equal(0.75)


func test_invalid_numbers() -> void:
	for text in ["", "abc", "1,2,3", "5,", "1/0", "1/", "/2", "2/3/4", "1 2"]:
		assert_bool(NumberAnswer.parse(text).is_ok()).override_failure_message(text).is_false()


func test_numbers_written_like_peruvian_books() -> void:
	assert_str(NumberAnswer.spoken(1440.0)).is_equal("1 440")
	assert_str(NumberAnswer.spoken(1254300.0)).is_equal("1 254 300")
	assert_str(NumberAnswer.spoken(480.0)).is_equal("480")
	assert_str(NumberAnswer.spoken(0.5)).is_equal("0,5")
	assert_str(NumberAnswer.spoken(-12.25)).is_equal("-12,25")


func test_equal_with_tolerance() -> void:
	assert_bool(NumberAnswer.same(0.1 + 0.2, 0.3)).is_true()
	assert_bool(NumberAnswer.same(3.2, 3.0, 0.25)).is_true()
	assert_bool(NumberAnswer.same(3.3, 3.0, 0.25)).is_false()

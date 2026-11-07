extends GdUnitTestSuite
## Nombres de estudiantes y docentes.


func test_cleans_extra_spaces() -> void:
	assert_str(PersonName.parse("  Ana   María \t Quispe ").value).is_equal("Ana María Quispe")


func test_accepts_spanish_and_quechua_names() -> void:
	for name in ["Ñusta Huamán", "José D'Ángelo", "Luz-Clara Ccori", "Ma. Sumaq", "Wayra"]:
		assert_bool(PersonName.parse(name).is_ok()).override_failure_message(name).is_true()


func test_rejects_invalid_names() -> void:
	assert_str(PersonName.parse("A").error).is_equal("name_too_short")
	assert_str(PersonName.parse("   ").error).is_equal("name_too_short")
	assert_str(PersonName.parse("x".repeat(41)).error).is_equal("name_too_long")
	assert_str(PersonName.parse("Ana 2").error).is_equal("name_invalid")
	assert_str(PersonName.parse("-Ana").error).is_equal("name_invalid")
	assert_str(PersonName.parse("Ana@").error).is_equal("name_invalid")


func test_comparison_ignores_case_and_accents() -> void:
	assert_str(PersonName.comparison_key("  ÁNGEL  Núñez ")).is_equal(PersonName.comparison_key("angel nunez"))

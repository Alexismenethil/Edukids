extends GdUnitTestSuite
## Datos de la configuración inicial: institución, secciones y código de docente (RF-01).


func test_institution_name() -> void:
	assert_str(Institution.parse_name("  I.E. N.° 38984-22  Mollepata ").value).is_equal("I.E. N.° 38984-22 Mollepata")
	assert_str(Institution.parse_name("IE").error).is_equal("institution_name_short")
	assert_str(Institution.parse_name("x".repeat(81)).error).is_equal("institution_name_long")


func test_modular_code_is_optional_and_has_seven_digits() -> void:
	assert_str(Institution.parse_modular_code("").value).is_equal("")
	assert_str(Institution.parse_modular_code(" 0123456 ").value).is_equal("0123456")
	assert_str(Institution.parse_modular_code("123456").error).is_equal("modular_code_invalid")
	assert_str(Institution.parse_modular_code("12345a7").error).is_equal("modular_code_invalid")


func test_grade_and_school_year() -> void:
	assert_bool(Institution.is_valid_grade(6)).is_true()
	assert_bool(Institution.is_valid_grade(7)).is_false()
	assert_bool(Institution.is_valid_school_year(2026)).is_true()
	assert_bool(Institution.is_valid_school_year(1999)).is_false()


func test_section_names() -> void:
	assert_str(Section.parse_name(" a ").value).is_equal("A")
	assert_str(Section.parse_name("única").value).is_equal("Única")
	assert_str(Section.parse_name("B 2").value).is_equal("B 2")
	assert_str(Section.parse_name("").error).is_equal("section_empty")
	assert_str(Section.parse_name("A/B").error).is_equal("section_invalid")
	assert_str(Section.parse_name("x".repeat(13)).error).is_equal("section_long")


func test_teacher_code() -> void:
	assert_str(TeacherCode.parse("").value).is_equal("")
	assert_str(TeacherCode.parse(" k7m-2qx ").value).is_equal("K7M2QX")
	assert_str(TeacherCode.parse("K7M2Q").error).is_equal("teacher_code_length")
	assert_str(TeacherCode.parse("K7M2Q!").error).is_equal("teacher_code_invalid")

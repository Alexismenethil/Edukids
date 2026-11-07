extends GdUnitTestSuite
## PIN del estudiante (4 números) y del docente (4 a 6, no fácil de adivinar).


func test_student_pin_has_four_digits() -> void:
	assert_str((Pin.student(" 0427 ").value as Pin).digits).is_equal("0427")
	assert_str(Pin.student("042").error).is_equal("pin_length")
	assert_str(Pin.student("04271").error).is_equal("pin_length")
	assert_str(Pin.student("04a7").error).is_equal("pin_not_digits")
	assert_str(Pin.student("").error).is_equal("pin_not_digits")


func test_student_pin_may_be_simple() -> void:
	assert_bool(Pin.student("1111").is_ok()).is_true()


func test_teacher_pin_has_four_to_six_digits() -> void:
	assert_bool(Pin.teacher("2580").is_ok()).is_true()
	assert_bool(Pin.teacher("731904").is_ok()).is_true()
	assert_str(Pin.teacher("731").error).is_equal("pin_length")
	assert_str(Pin.teacher("7319042").error).is_equal("pin_length")
	assert_str(Pin.teacher("73a9").error).is_equal("pin_not_digits")


func test_teacher_pin_rejects_easy_series() -> void:
	for easy in ["0000", "1111", "1234", "4567", "9876", "123456", "654321"]:
		assert_str(Pin.teacher(easy).error).is_equal("pin_too_easy")


func test_easy_to_guess_detection() -> void:
	assert_bool(Pin.is_easy_to_guess("2222")).is_true()
	assert_bool(Pin.is_easy_to_guess("3456")).is_true()
	assert_bool(Pin.is_easy_to_guess("3210")).is_true()
	assert_bool(Pin.is_easy_to_guess("1235")).is_false()
	assert_bool(Pin.is_easy_to_guess("9081")).is_false()

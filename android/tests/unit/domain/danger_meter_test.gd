extends GdUnitTestSuite
## RN-13: medidor de peligro.


func test_starts_at_two_with_maximum_four() -> void:
	var meter := DangerMeter.new()
	assert_int(meter.value).is_equal(2)
	assert_int(meter.maximum).is_equal(4)


func test_hit_adds_one_up_to_the_maximum() -> void:
	var meter := DangerMeter.new()
	assert_int(meter.register_hit()).is_equal(3)
	assert_int(meter.register_hit()).is_equal(4)
	assert_int(meter.register_hit()).is_equal(4)


func test_miss_subtracts_one_without_catching() -> void:
	var meter := DangerMeter.new()
	assert_bool(meter.register_miss()).is_false()
	assert_int(meter.value).is_equal(1)


func test_atoq_catches_the_avatar_at_zero_and_meter_resets() -> void:
	var meter := DangerMeter.new()
	meter.register_miss()
	assert_bool(meter.register_miss()).is_true()
	assert_int(meter.value).is_equal(2)


func test_help_mode_starts_at_three() -> void:
	var meter := DangerMeter.new(DangerMeter.HELP_MODE_START)
	assert_int(meter.value).is_equal(3)
	meter.register_miss()
	meter.register_miss()
	assert_bool(meter.register_miss()).is_true()
	assert_int(meter.value).is_equal(3)


func test_safety_ratio_follows_the_value() -> void:
	var meter := DangerMeter.new()
	assert_float(meter.safety_ratio()).is_equal_approx(0.5, 0.001)
	meter.register_hit()
	meter.register_hit()
	assert_float(meter.safety_ratio()).is_equal_approx(1.0, 0.001)


func test_create_rejects_invalid_configuration() -> void:
	assert_that(DangerMeter.create(0, 4).error).is_equal(&"invalid_start")
	assert_that(DangerMeter.create(5, 4).error).is_equal(&"invalid_start")
	assert_that(DangerMeter.create(1, 0).error).is_equal(&"invalid_maximum")


func test_create_accepts_teacher_configuration() -> void:
	var created := DangerMeter.create(3, 5)
	assert_bool(created.is_ok()).is_true()
	assert_int((created.value as DangerMeter).value).is_equal(3)

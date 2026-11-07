extends GdUnitTestSuite
## Integración: reloj, aleatoriedad e identificadores del sistema.


func test_uuid_v4_format_and_uniqueness() -> void:
	var generator := UuidV4Generator.new()
	var pattern := RegEx.create_from_string("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
	var first := generator.next_id()
	assert_object(pattern.search(first)).is_not_null()
	assert_str(generator.next_id()).is_not_equal(first)


func test_random_source_with_seed_is_reproducible() -> void:
	var first := GodotRandomSource.new(1234)
	var second := GodotRandomSource.new(1234)
	for i in 5:
		assert_int(first.next_int(1, 100)).is_equal(second.next_int(1, 100))


func test_system_clock_is_after_2025() -> void:
	assert_int(SystemClock.new().now_unix_ms()).is_greater(1_735_689_600_000)

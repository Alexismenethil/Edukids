extends GdUnitTestSuite
## RN-11: estrellas por nivel de práctica.


func test_stars_by_valid_hits_and_lives(valid_hits: int, total: int, lives_lost: int, expected: int, test_parameters := [
	[10, 10, 0, 3],
	[9, 10, 0, 3],
	[9, 10, 1, 2],
	[8, 10, 0, 2],
	[7, 10, 0, 2],
	[6, 10, 0, 1],
	[0, 10, 2, 1],
	[63, 70, 0, 3],
	[48, 70, 0, 1],
]) -> void:
	assert_int(StarRule.stars_for(valid_hits, total, lives_lost, true)).is_equal(expected)


func test_no_stars_when_the_level_is_not_completed() -> void:
	assert_int(StarRule.stars_for(10, 10, 0, false)).is_equal(0)


func test_no_stars_for_a_level_without_items() -> void:
	assert_int(StarRule.stars_for(0, 0, 0, true)).is_equal(0)


func test_hits_above_total_are_clamped() -> void:
	assert_int(StarRule.stars_for(12, 10, 0, true)).is_equal(3)

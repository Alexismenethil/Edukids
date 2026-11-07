extends GdUnitTestSuite
## Escenas narrativas: máximo 4 globos breves.


func _line(text: String = "Hola") -> DialogueLine:
	return DialogueLine.create(&"quwi", text).value


func test_line_requires_speaker_and_text() -> void:
	assert_that(DialogueLine.create(&"", "Hola").error).is_equal(&"missing_speaker")
	assert_that(DialogueLine.create(&"quwi", "   ").error).is_equal(&"empty_text")


func test_line_rejects_long_text_and_unknown_mood() -> void:
	var long_text := "a".repeat(DialogueLine.MAX_TEXT_LENGTH + 1)
	assert_that(DialogueLine.create(&"quwi", long_text).error).is_equal(&"text_too_long")
	assert_that(DialogueLine.create(&"quwi", "Hola", &"angry").error).is_equal(&"unknown_mood")


func test_line_accepts_optional_cue() -> void:
	var created := DialogueLine.create(&"quwi", "¡Mira!", &"surprise", &"knots_scatter")
	assert_bool(created.is_ok()).is_true()
	assert_that((created.value as DialogueLine).cue).is_equal(&"knots_scatter")
	assert_that(DialogueLine.create(&"quwi", "Hola", &"joy", &"no válido").error).is_equal(&"invalid_cue")


func test_line_trims_spaces() -> void:
	assert_str(_line("  ¡Hola!  ").text).is_equal("¡Hola!")


func test_scene_needs_between_one_and_four_lines() -> void:
	var empty: Array[DialogueLine] = []
	assert_that(StoryScene.create(&"intro", empty).error).is_equal(&"empty_scene")
	var five: Array[DialogueLine] = [_line(), _line(), _line(), _line(), _line()]
	assert_that(StoryScene.create(&"intro", five).error).is_equal(&"too_many_lines")
	var four: Array[DialogueLine] = [_line(), _line(), _line(), _line()]
	assert_bool(StoryScene.create(&"intro", four).is_ok()).is_true()


func test_scene_lines_cannot_be_modified_from_outside() -> void:
	var lines: Array[DialogueLine] = [_line()]
	var scene: StoryScene = StoryScene.create(&"intro", lines).value
	scene.lines.append(_line())
	lines.append(_line())
	assert_int(scene.line_count()).is_equal(1)

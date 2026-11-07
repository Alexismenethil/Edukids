extends GdUnitTestSuite
## Caso de uso GetStoryScene con un repositorio falso: sin archivos ni escenas.


class FakeStoryRepository extends StoryRepository:
	var scenes: Dictionary = {}

	func find_scene(scene_id: StringName) -> Result:
		if scenes.has(scene_id):
			return Result.ok(scenes[scene_id])
		return Result.fail(&"scene_not_found")


func _repository_with_intro() -> FakeStoryRepository:
	var repository := FakeStoryRepository.new()
	var lines: Array[DialogueLine] = [
		DialogueLine.create(&"quwi", "¡Hola!", &"joy").value,
		DialogueLine.create(&"quwi", "¡Mira!", &"surprise", &"knots_scatter").value,
	]
	repository.scenes[&"intro"] = StoryScene.create(&"intro", lines).value
	return repository


func test_returns_plain_data_for_the_view() -> void:
	var use_case := GetStoryScene.new(_repository_with_intro())
	var response := use_case.execute(StorySceneRequest.new(&"intro"))
	assert_bool(response.ok).is_true()
	assert_int(response.lines.size()).is_equal(2)
	assert_dict(response.lines[1]).is_equal({
		"speaker": "quwi", "text": "¡Mira!", "mood": "surprise", "cue": "knots_scatter",
	})


func test_reports_a_missing_scene() -> void:
	var use_case := GetStoryScene.new(FakeStoryRepository.new())
	var response := use_case.execute(StorySceneRequest.new(&"nowhere"))
	assert_bool(response.ok).is_false()
	assert_that(response.error).is_equal(&"scene_not_found")
	assert_array(response.lines).is_empty()

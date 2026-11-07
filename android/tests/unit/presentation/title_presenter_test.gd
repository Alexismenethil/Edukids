extends GdUnitTestSuite
## Presentador de la pantalla de inicio.


class FakeStoryRepository extends StoryRepository:
	var scenes: Dictionary = {}

	func find_scene(scene_id: StringName) -> Result:
		if scenes.has(scene_id):
			return Result.ok(scenes[scene_id])
		return Result.fail(&"scene_not_found")


func _presenter(repository: StoryRepository) -> TitlePresenter:
	return TitlePresenter.new(GetStoryScene.new(repository), "0.1.0")


func test_title_texts() -> void:
	var view_model := _presenter(FakeStoryRepository.new()).title()
	assert_str(view_model.play_label).is_equal("Jugar")
	assert_str(view_model.subtitle).is_equal("El quipu de los saberes")
	assert_str(view_model.version_label).is_equal("Versión 0.1.0")


func test_teaser_uses_display_names_and_keeps_cues() -> void:
	var repository := FakeStoryRepository.new()
	var lines: Array[DialogueLine] = [
		DialogueLine.create(&"mama_sisa", "Cuiden el quipu.", &"comfort").value,
		DialogueLine.create(&"quwi", "¡Oh, no!", &"surprise", &"knots_scatter").value,
	]
	repository.scenes[TitlePresenter.PROLOGUE_TEASER] = StoryScene.create(TitlePresenter.PROLOGUE_TEASER, lines).value
	var dialogue := _presenter(repository).prologue_teaser()
	assert_int(dialogue.lines.size()).is_equal(2)
	assert_str(dialogue.lines[0].speaker_name).is_equal("Mama Sisa")
	assert_that(dialogue.lines[1].cue).is_equal(&"knots_scatter")
	assert_that(dialogue.lines[1].mood).is_equal(&"surprise")


func test_teaser_falls_back_to_a_greeting() -> void:
	var dialogue := _presenter(FakeStoryRepository.new()).prologue_teaser()
	assert_int(dialogue.lines.size()).is_equal(1)
	assert_str(dialogue.lines[0].speaker_name).is_equal("Quwi")

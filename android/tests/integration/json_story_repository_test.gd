extends GdUnitTestSuite
## Integración: lectura de escenas narrativas desde JSON.

const TEMP_DIRECTORY := "user://test_story"


func before_test() -> void:
	DirAccess.make_dir_recursive_absolute(TEMP_DIRECTORY)


func after_test() -> void:
	for file_name in DirAccess.get_files_at(TEMP_DIRECTORY):
		DirAccess.remove_absolute("%s/%s" % [TEMP_DIRECTORY, file_name])
	DirAccess.remove_absolute(TEMP_DIRECTORY)


func _write(file_name: String, content: String) -> void:
	var file := FileAccess.open("%s/%s" % [TEMP_DIRECTORY, file_name], FileAccess.WRITE)
	file.store_string(content)
	file.close()


func test_reads_the_prologue_teaser_of_the_base_game() -> void:
	var found := JsonStoryRepository.new("res://content/story").find_scene(&"prologue_teaser")
	assert_bool(found.is_ok()).is_true()
	var scene: StoryScene = found.value
	assert_int(scene.line_count()).is_equal(4)
	assert_that(scene.lines[0].speaker).is_equal(&"quwi")
	assert_that(scene.lines[1].cue).is_equal(&"knots_scatter")
	assert_that(scene.lines[3].cue).is_equal(&"knots_return")


func test_missing_scene() -> void:
	var found := JsonStoryRepository.new(TEMP_DIRECTORY).find_scene(&"nowhere")
	assert_that(found.error).is_equal(&"scene_not_found")


func test_invalid_json() -> void:
	_write("broken.json", "{ esto no es json")
	assert_that(JsonStoryRepository.new(TEMP_DIRECTORY).find_scene(&"broken").error).is_equal(&"invalid_json")


func test_domain_rules_apply_to_files() -> void:
	_write("silent.json", JSON.stringify({"id": "silent", "lines": [{"speaker": "quwi", "text": " "}]}))
	assert_that(JsonStoryRepository.new(TEMP_DIRECTORY).find_scene(&"silent").error).is_equal(&"empty_text")

class_name GetStoryScene
extends RefCounted
## Caso de uso: obtener una escena narrativa lista para mostrarse.

var _stories: StoryRepository


func _init(stories: StoryRepository) -> void:
	_stories = stories


func execute(request: StorySceneRequest) -> StorySceneResponse:
	var found := _stories.find_scene(request.scene_id)
	if not found.is_ok():
		return StorySceneResponse.failed(found.error)
	return StorySceneResponse.from_scene(found.value as StoryScene)

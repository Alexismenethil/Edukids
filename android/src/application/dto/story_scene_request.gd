class_name StorySceneRequest
extends RefCounted
## Petición del caso de uso GetStoryScene.

var scene_id: StringName


func _init(requested_scene_id: StringName) -> void:
	scene_id = requested_scene_id

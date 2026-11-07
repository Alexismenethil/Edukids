extends Node
## Raíz de composición (autoload): el único lugar que crea las clases concretas y las conecta.
## Las escenas no la usan: el navegador les inyecta sus presentadores.

const STORY_DIRECTORY := "res://content/story"

var _get_story_scene: GetStoryScene
var _version: String


func _ready() -> void:
	var stories := JsonStoryRepository.new(STORY_DIRECTORY)
	_get_story_scene = GetStoryScene.new(stories)
	_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func title_presenter() -> TitlePresenter:
	return TitlePresenter.new(_get_story_scene, _version)

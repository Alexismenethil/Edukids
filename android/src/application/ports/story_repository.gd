@abstract class_name StoryRepository
extends RefCounted
## Puerto: lee las escenas narrativas del juego base o de un paquete instalado.


## Devuelve un Result con un StoryScene, o con el error si no existe o no es válida.
@abstract func find_scene(scene_id: StringName) -> Result

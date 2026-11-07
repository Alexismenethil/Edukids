class_name JsonStoryRepository
extends StoryRepository
## Adaptador de salida: lee las escenas narrativas del juego base desde archivos JSON.
## Más adelante, otra implementación leerá las escenas de los paquetes instalados.

var _directory: String


func _init(directory: String) -> void:
	_directory = directory.trim_suffix("/")


func find_scene(scene_id: StringName) -> Result:
	var path := "%s/%s.json" % [_directory, scene_id]
	if not FileAccess.file_exists(path):
		return Result.fail(&"scene_not_found", "No existe la escena %s." % scene_id)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return Result.fail(&"invalid_json", "La escena %s no es un JSON válido." % scene_id)
	var data: Variant = json.data
	if not data is Dictionary:
		return Result.fail(&"invalid_json", "La escena %s no es un JSON válido." % scene_id)
	var raw_lines: Variant = data.get("lines", [])
	if not raw_lines is Array:
		return Result.fail(&"invalid_json", "La escena %s no tiene una lista de globos." % scene_id)
	var lines: Array[DialogueLine] = []
	for raw_line: Variant in raw_lines:
		if not raw_line is Dictionary:
			return Result.fail(&"invalid_json", "Un globo de %s no es un objeto." % scene_id)
		var created := DialogueLine.create(
			StringName(str(raw_line.get("speaker", ""))),
			str(raw_line.get("text", "")),
			StringName(str(raw_line.get("mood", "joy"))),
			StringName(str(raw_line.get("cue", ""))),
		)
		if not created.is_ok():
			return created
		lines.append(created.value)
	return StoryScene.create(StringName(str(data.get("id", scene_id))), lines)

class_name StoryScene
extends RefCounted
## Escena narrativa: aparece al llegar a una parada, al recuperar una cuerda o al cerrar un capítulo.
## Tiene como máximo 4 globos de diálogo y siempre se puede saltar
## (docs/05-diseno-del-juego/01-concepto-y-narrativa.md).

const MAX_LINES := 4

var id: StringName:
	get:
		return _id

var lines: Array[DialogueLine]:
	get:
		return _lines.duplicate()

var _id: StringName
var _lines: Array[DialogueLine] = []


func _init(scene_id: StringName, scene_lines: Array[DialogueLine]) -> void:
	_id = scene_id
	_lines = scene_lines.duplicate()


static func create(scene_id: StringName, scene_lines: Array[DialogueLine]) -> Result:
	if String(scene_id).is_empty():
		return Result.fail(&"missing_id", "La escena necesita un identificador.")
	if scene_lines.is_empty():
		return Result.fail(&"empty_scene", "La escena necesita al menos un globo.")
	if scene_lines.size() > MAX_LINES:
		return Result.fail(&"too_many_lines", "Una escena admite hasta %d globos." % MAX_LINES)
	return Result.ok(StoryScene.new(scene_id, scene_lines))


func line_count() -> int:
	return _lines.size()

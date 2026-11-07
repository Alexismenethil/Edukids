class_name StorySceneResponse
extends RefCounted
## Respuesta del caso de uso GetStoryScene. Solo lleva datos simples:
## las escenas de Godot nunca reciben entidades del dominio.

var ok: bool = false
var error: StringName = &""
var scene_id: StringName = &""
## Cada globo es un Dictionary con las claves "speaker", "text", "mood" y "cue" (String).
var lines: Array[Dictionary] = []


static func from_scene(scene: StoryScene) -> StorySceneResponse:
	var response := StorySceneResponse.new()
	response.ok = true
	response.scene_id = scene.id
	for line in scene.lines:
		response.lines.append({
			"speaker": String(line.speaker),
			"text": line.text,
			"mood": String(line.mood),
			"cue": String(line.cue),
		})
	return response


static func failed(error_code: StringName) -> StorySceneResponse:
	var response := StorySceneResponse.new()
	response.error = error_code
	return response

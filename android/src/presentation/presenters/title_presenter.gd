class_name TitlePresenter
extends RefCounted
## Presentador de la pantalla de inicio: traduce los casos de uso a modelos de vista.
## No conoce escenas, archivos ni nodos.

const PROLOGUE_TEASER := &"prologue_teaser"

const SPEAKER_NAMES := {
	"quwi": "Quwi",
	"tunki": "Tunki",
	"humbi": "Humbi",
	"atoq": "Atoq",
	"mama_sisa": "Mama Sisa",
}

var _get_story_scene: GetStoryScene
var _version: String


func _init(get_story_scene: GetStoryScene, version: String) -> void:
	_get_story_scene = get_story_scene
	_version = version


func title() -> TitleViewModel:
	var view_model := TitleViewModel.new()
	view_model.subtitle = "El quipu de los saberes"
	view_model.play_label = "Jugar"
	view_model.teacher_label = "Docente"
	view_model.version_label = "Versión %s" % _version
	return view_model


## Diálogo que Quwi cuenta al tocar Jugar. Si la escena no se puede leer,
## devuelve un saludo breve para que la pantalla nunca quede vacía.
func prologue_teaser() -> DialogueViewModel:
	var view_model := DialogueViewModel.new()
	var response := _get_story_scene.execute(StorySceneRequest.new(PROLOGUE_TEASER))
	if not response.ok:
		view_model.lines.append(DialogueLineViewModel.new("Quwi", "¡Hola! Soy Quwi. ¡Muy pronto empezamos la aventura!", &"joy"))
		return view_model
	for line in response.lines:
		view_model.lines.append(DialogueLineViewModel.new(
			speaker_name(line["speaker"]), line["text"], StringName(line["mood"]), StringName(line["cue"])
		))
	return view_model


func teacher_notice() -> String:
	return "El modo docente llegará muy pronto."


static func speaker_name(speaker_id: String) -> String:
	return SPEAKER_NAMES.get(speaker_id, speaker_id.capitalize())

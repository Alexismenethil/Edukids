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
var _get_audio_settings: GetAudioSettings
var _toggle_sound: ToggleSound
var _version: String
var _session: PlaySession


func _init(get_story_scene: GetStoryScene, get_audio_settings: GetAudioSettings, toggle_sound: ToggleSound, version: String, session: PlaySession = PlaySession.new()) -> void:
	_get_story_scene = get_story_scene
	_get_audio_settings = get_audio_settings
	_toggle_sound = toggle_sound
	_version = version
	_session = session


func title() -> TitleViewModel:
	var view_model := TitleViewModel.new()
	view_model.subtitle = "El quipu de los saberes"
	view_model.play_label = "Jugar"
	view_model.teacher_label = "Docente"
	view_model.version_label = "Versión %s" % _version
	view_model.sound = _sound_view_model(_get_audio_settings.execute())
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


func toggle_sound() -> SoundToggleViewModel:
	return _sound_view_model(_toggle_sound.execute())


## Quwi cuenta su adelanto de la historia solo la primera vez en cada sesión.
func should_tell_teaser() -> bool:
	return not _session.teaser_told


func mark_teaser_told() -> void:
	_session.teaser_told = true


func not_configured_notice() -> String:
	return "Antes de jugar, tu profe debe preparar la tablet. Pídele que toque «Docente»."


static func speaker_name(speaker_id: String) -> String:
	return SPEAKER_NAMES.get(speaker_id, speaker_id.capitalize())


func _sound_view_model(response: AudioSettingsResponse) -> SoundToggleViewModel:
	var view_model := SoundToggleViewModel.new()
	view_model.sound_on = not response.muted
	view_model.label = "Sonido"
	view_model.notice = "" if response.persisted else "No se pudo guardar el ajuste de sonido."
	return view_model

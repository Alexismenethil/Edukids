class_name RestoreAudioSettings
extends RefCounted
## Caso de uso: al abrir el juego, aplica los volúmenes guardados.

var _settings: SettingsRepository
var _mixer: AudioMixer


func _init(settings: SettingsRepository, mixer: AudioMixer) -> void:
	_settings = settings
	_mixer = mixer


func execute() -> AudioSettingsResponse:
	var saved := _settings.load_audio_settings()
	_mixer.apply(saved)
	return AudioSettingsResponse.from_settings(saved)

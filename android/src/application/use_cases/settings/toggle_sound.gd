class_name ToggleSound
extends RefCounted
## Caso de uso: activar o silenciar todo el sonido. El cambio se aplica siempre;
## si no se puede guardar, la respuesta lo indica con persisted = false.

var _settings: SettingsRepository
var _mixer: AudioMixer


func _init(settings: SettingsRepository, mixer: AudioMixer) -> void:
	_settings = settings
	_mixer = mixer


func execute() -> AudioSettingsResponse:
	var updated := _settings.load_audio_settings().toggled_mute()
	var saved := _settings.save_audio_settings(updated)
	_mixer.apply(updated)
	return AudioSettingsResponse.from_settings(updated, saved.is_ok())

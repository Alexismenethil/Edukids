class_name GetAudioSettings
extends RefCounted
## Caso de uso: consultar los ajustes de sonido guardados.

var _settings: SettingsRepository


func _init(settings: SettingsRepository) -> void:
	_settings = settings


func execute() -> AudioSettingsResponse:
	return AudioSettingsResponse.from_settings(_settings.load_audio_settings())

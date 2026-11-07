class_name InMemorySettingsRepository
extends SettingsRepository
## Adaptador de respaldo: guarda los ajustes solo mientras el juego está abierto.
## Se usa si SQLite no está disponible en el dispositivo.

var _audio := AudioSettings.defaults()


func load_audio_settings() -> AudioSettings:
	return _audio


func save_audio_settings(settings: AudioSettings) -> Result:
	_audio = settings
	return Result.ok()

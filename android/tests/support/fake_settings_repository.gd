class_name FakeSettingsRepository
extends SettingsRepository
## Doble de prueba del repositorio de ajustes: guarda en memoria y puede simular fallas.

var stored := AudioSettings.defaults()
var fail_saves := false
var saves := 0


func load_audio_settings() -> AudioSettings:
	return stored


func save_audio_settings(settings: AudioSettings) -> Result:
	saves += 1
	if fail_saves:
		return Result.fail(&"disk_full", "Sin espacio.")
	stored = settings
	return Result.ok()

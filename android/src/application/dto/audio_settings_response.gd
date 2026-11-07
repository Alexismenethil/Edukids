class_name AudioSettingsResponse
extends RefCounted
## Respuesta de los casos de uso de sonido. Datos simples para el presentador.

var music_volume: float = AudioSettings.DEFAULT_MUSIC_VOLUME
var sfx_volume: float = AudioSettings.DEFAULT_SFX_VOLUME
var muted: bool = false
## Falso si el cambio se aplicó pero no se pudo guardar.
var persisted: bool = true


static func from_settings(settings: AudioSettings, was_persisted: bool = true) -> AudioSettingsResponse:
	var response := AudioSettingsResponse.new()
	response.music_volume = settings.music_volume
	response.sfx_volume = settings.sfx_volume
	response.muted = settings.muted
	response.persisted = was_persisted
	return response

@abstract class_name SettingsRepository
extends RefCounted
## Puerto: ajustes de la tablet guardados localmente (tabla setting).


## Devuelve los ajustes guardados, o los valores por defecto si no hay ninguno.
@abstract func load_audio_settings() -> AudioSettings


@abstract func save_audio_settings(settings: AudioSettings) -> Result

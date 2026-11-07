class_name AudioSettings
extends RefCounted
## Ajustes de sonido (RF-36): volumen de la música y de los efectos por separado,
## entre 0 y 1, y un silencio general. Es inmutable: cada cambio crea un objeto nuevo.

const DEFAULT_MUSIC_VOLUME := 0.7
const DEFAULT_SFX_VOLUME := 0.9

var music_volume: float:
	get:
		return _music_volume

var sfx_volume: float:
	get:
		return _sfx_volume

var muted: bool:
	get:
		return _muted

var _music_volume: float
var _sfx_volume: float
var _muted: bool


func _init(music: float = DEFAULT_MUSIC_VOLUME, sfx: float = DEFAULT_SFX_VOLUME, is_muted: bool = false) -> void:
	_music_volume = clampf(music, 0.0, 1.0)
	_sfx_volume = clampf(sfx, 0.0, 1.0)
	_muted = is_muted


static func defaults() -> AudioSettings:
	return AudioSettings.new()


## ¿Se escucha algo? Falso si está en silencio o si ambos volúmenes son cero.
func is_audible() -> bool:
	return not _muted and (_music_volume > 0.0 or _sfx_volume > 0.0)


func toggled_mute() -> AudioSettings:
	return AudioSettings.new(_music_volume, _sfx_volume, not _muted)


func with_music_volume(volume: float) -> AudioSettings:
	return AudioSettings.new(volume, _sfx_volume, _muted)


func with_sfx_volume(volume: float) -> AudioSettings:
	return AudioSettings.new(_music_volume, volume, _muted)


func equals(other: AudioSettings) -> bool:
	return other != null and is_equal_approx(_music_volume, other.music_volume) \
		and is_equal_approx(_sfx_volume, other.sfx_volume) and _muted == other.muted

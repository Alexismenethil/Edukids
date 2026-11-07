class_name GodotAudioMixer
extends AudioMixer
## Adaptador de salida: aplica los ajustes a los buses Music, SFX y Master de Godot.

const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MASTER_BUS := &"Master"


func apply(settings: AudioSettings) -> void:
	_set_volume(MUSIC_BUS, settings.music_volume)
	_set_volume(SFX_BUS, settings.sfx_volume)
	var master := AudioServer.get_bus_index(MASTER_BUS)
	if master >= 0:
		AudioServer.set_bus_mute(master, settings.muted)


func _set_volume(bus_name: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(index, volume <= 0.0)

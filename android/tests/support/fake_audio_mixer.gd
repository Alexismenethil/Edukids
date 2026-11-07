class_name FakeAudioMixer
extends AudioMixer
## Doble de prueba del mezclador: registra lo que se aplicó.

var applied: Array[AudioSettings] = []


func apply(settings: AudioSettings) -> void:
	applied.append(settings)


func last() -> AudioSettings:
	return applied.back() if not applied.is_empty() else null

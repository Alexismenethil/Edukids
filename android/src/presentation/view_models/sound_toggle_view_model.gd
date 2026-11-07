class_name SoundToggleViewModel
extends RefCounted
## Estado del botón de sonido de la pantalla de inicio.

var sound_on: bool = true
var label: String = "Sonido"
## Mensaje breve si el ajuste no se pudo guardar; vacío si todo salió bien.
var notice: String = ""

class_name StudentRowViewModel
extends RefCounted
## Fila de un estudiante en el modo docente.

var id := ""
var name := ""
var section_id := ""
var look: AvatarLookViewModel
var detail := ""
var status := ""
## &"ok", &"muted" o &"alert": el color de la etiqueta de estado.
var status_kind: StringName = &"ok"
var active := true

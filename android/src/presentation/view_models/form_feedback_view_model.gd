class_name FormFeedbackViewModel
extends RefCounted
## Resultado de enviar un formulario: si se guardó y, si no, el mensaje de cada campo.

var ok := false
## Campo → mensaje. El campo "general" es para errores que no son de un campo.
var errors: Dictionary = {}
## Aviso breve para mostrar al guardar.
var notice := ""
var id := ""

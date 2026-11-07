class_name FeedbackViewModel
extends RefCounted
## Retroalimentación de una respuesta (RF-12).

## false si la respuesta estaba incompleta: `notice` dice qué falta y la pregunta sigue abierta.
var accepted := true
var notice := ""
var correct := false
var title := ""
var message := ""
var notes: Array[String] = []
## Partes respondidas: id → true si está bien, para marcarlas con ✓ o ✗.
var parts := {}
var progress: Array[StringName] = []
var index := 0
var finished := false
var continue_label := ""
## Expresión del guía: «cheer» si acertó, «comfort» si no.
var mood: StringName = &""
## Aviso si la respuesta no se pudo guardar.
var warning := ""

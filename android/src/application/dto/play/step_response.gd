class_name StepResponse
extends RefCounted
## Una pregunta lista para mostrarse. No incluye las respuestas correctas.
## `data` depende del tipo (ver StepBuilder); `unit` trae el estímulo de la unidad de lectura.

var attempt_id := ""
var question_id := ""
var type: StringName = &""
var prompt := ""
## Ruta de la imagen del enunciado, ya resuelta, o "".
var image := ""
var number := 0
var total := 0
var retry := false
var hint_available := false
var hint_offered := false
var progress: Array[StringName] = []
var unit := {}
var data := {}

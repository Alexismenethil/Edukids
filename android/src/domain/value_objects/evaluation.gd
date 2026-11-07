class_name Evaluation
extends RefCounted
## Resultado de corregir una respuesta.
## `parts` dice qué partes respondidas por el estudiante están bien, para marcarlas en pantalla
## sin revelar la solución; `missing` cuenta lo que faltó marcar (selección múltiple).

## false si falta responder alguna parte: no se corrige ni cuenta como intento.
var complete := true
var correct := false
## Retroalimentación propia de la opción o parte equivocada; vacía si se usa la general del ítem.
var feedback := ""
var parts := {}
var missing := 0


static func incomplete() -> Evaluation:
	var evaluation := Evaluation.new()
	evaluation.complete = false
	return evaluation


static func of(is_correct: bool, part_results: Dictionary = {}, specific_feedback: String = "") -> Evaluation:
	var evaluation := Evaluation.new()
	evaluation.correct = is_correct
	evaluation.parts = part_results
	evaluation.feedback = specific_feedback
	return evaluation


## Cuántas partes respondidas están bien.
func hits() -> int:
	var count := 0
	for value: bool in parts.values():
		if value:
			count += 1
	return count

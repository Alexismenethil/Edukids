class_name Item
extends RefCounted
## Pregunta de un nivel, ya validada. Los campos propios de su tipo están en `spec`,
## normalizados por su evaluador (ver docs/03-diseno-de-software/formato-de-paquete.md).

var id := ""
var type: StringName = &""
var prompt := ""
var image := ""
var feedback_correct := ""
var feedback_incorrect := ""
var hint := ""
var metadata := {}
var spec := {}


func has_hint() -> bool:
	return not hint.is_empty()


## Retroalimentación que corresponde a una corrección: la propia de la parte equivocada
## o, si no tiene, la general del ítem.
func feedback_for(evaluation: Evaluation) -> String:
	if not evaluation.feedback.is_empty():
		return evaluation.feedback
	return feedback_correct if evaluation.correct else feedback_incorrect

class_name AttemptAnswer
extends RefCounted
## Una respuesta guardada de un intento. Se guarda apenas se responde (RNF-06).

var id := ""
var attempt_id := ""
var item_id := ""
## Lo que respondió el estudiante, tal como lo entrega la vista (texto, lista o diccionario).
var value: Variant
var is_correct := false
var first_try := true
var with_hint := false
var time_ms := 0
var answered_at_ms := 0


static func from_outcome(answer_id: String, attempt: String, outcome: AnswerOutcome, given: Variant,
		now_ms: int) -> AttemptAnswer:
	var answer := AttemptAnswer.new()
	answer.id = answer_id
	answer.attempt_id = attempt
	answer.item_id = outcome.question_id
	answer.value = given
	answer.is_correct = outcome.is_correct()
	answer.first_try = outcome.first_try
	answer.with_hint = outcome.with_hint
	answer.time_ms = outcome.time_ms
	answer.answered_at_ms = now_ms
	return answer

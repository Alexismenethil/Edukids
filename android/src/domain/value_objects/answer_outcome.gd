class_name AnswerOutcome
extends RefCounted
## Qué pasó al responder una pregunta: la corrección, la retroalimentación y lo que sigue.

## false si la respuesta no se aceptó (incompleta o el nivel ya terminó); `reason` dice por qué.
var accepted := true
var reason: StringName = &""
var evaluation: Evaluation
var question_id := ""
var feedback := ""
var first_try := true
var with_hint := false
var time_ms := 0
## La pregunta falló al primer intento y volverá al final del nivel.
var will_return := false
## El guía ofrece una pista para la siguiente pregunta (tras dos errores seguidos).
var offer_hint := false
var finished := false
## Respuesta correcta, solo cuando ya no queda otra oportunidad.
var solution := ""


static func rejected(why: StringName) -> AnswerOutcome:
	var outcome := AnswerOutcome.new()
	outcome.accepted = false
	outcome.reason = why
	outcome.evaluation = Evaluation.incomplete()
	return outcome


func is_correct() -> bool:
	return accepted and evaluation.correct

class_name AnswerResponse
extends RefCounted
## Resultado de responder una pregunta, para mostrar la retroalimentación.

## false si la respuesta estaba incompleta: la pregunta sigue abierta.
var accepted := true
var correct := false
var feedback := ""
## Partes respondidas: id → true si está bien (opciones, afirmaciones, pares, elementos o espacios).
var parts := {}
## Opciones correctas que faltó marcar (selección múltiple).
var missing := 0
var will_return := false
var offer_hint := false
var finished := false
## Respuesta correcta, solo cuando ya no queda otra oportunidad.
var solution := ""
## false si la respuesta no se pudo guardar.
var saved := true
var progress: Array[StringName] = []
## Medidor de peligro y vidas después de responder (RN-13 y RN-14).
var danger := 0
var lives := 0
var life_lost := false
var game_over := false
var streak := 0


static func from_outcome(outcome: AnswerOutcome) -> AnswerResponse:
	var response := AnswerResponse.new()
	response.accepted = outcome.accepted
	if not outcome.accepted:
		return response
	response.correct = outcome.evaluation.correct
	response.feedback = outcome.feedback
	response.parts = outcome.evaluation.parts.duplicate()
	response.missing = outcome.evaluation.missing
	response.will_return = outcome.will_return
	response.offer_hint = outcome.offer_hint
	response.finished = outcome.finished
	response.solution = outcome.solution
	response.danger = outcome.danger
	response.lives = outcome.lives
	response.life_lost = outcome.life_lost
	response.game_over = outcome.game_over
	response.streak = outcome.streak
	return response

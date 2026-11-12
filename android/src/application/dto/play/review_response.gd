class_name ReviewResponse
extends RefCounted
## Una pregunta del desafío final, revisada al entregar (RF-30).

var number := 0
var prompt := ""
var correct := false
var feedback := ""
## Respuesta correcta, si falló.
var solution := ""


static func from_review(review: QuestionReview) -> ReviewResponse:
	var response := ReviewResponse.new()
	response.number = review.number
	response.prompt = review.prompt
	response.correct = review.correct
	response.feedback = review.feedback
	response.solution = review.solution
	return response

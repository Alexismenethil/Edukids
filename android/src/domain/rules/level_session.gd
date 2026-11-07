class_name LevelSession
extends RefCounted
## Reglas de un nivel de práctica: orden de las preguntas, pistas, retroalimentación y repaso
## de los errores al final (RF-12, RF-26, RF-29 y RN-11).
## Las preguntas de una unidad de lectura se presentan una por una con el texto a la vista (RF-28).
## Las vidas y el medidor de peligro (RN-13 y RN-14) se suman con las mecánicas del Sprint 5.

## Tras dos errores seguidos, el guía ofrece una pista (RF-26).
const HINT_OFFER_AFTER_MISSES := 2

## Estado de cada pregunta, para el quipu de avance.
const PENDING := &"pending"
const CURRENT := &"current"
const RIGHT := &"right"
const MISSED := &"missed"
const FIXED := &"fixed"
const WRONG := &"wrong"

var attempt_id := ""
var student_id := ""
var level: Level

var _registry: EvaluatorRegistry
var _steps: Array[SessionStep] = []
var _questions: Array[String] = []
var _position := 0
## Primer intento de cada pregunta: id → {"correct": bool, "hint": bool}.
var _first := {}
## Repaso de las preguntas falladas: id → bool.
var _retry := {}
var _misses_in_row := 0
var _hint_shown := false
var _hint_offered := false
var _hints_used := 0
var _step_started_ms := 0
var _elapsed_ms := 0


func _init(level_to_play: Level, registry: EvaluatorRegistry, attempt: String = "", student: String = "") -> void:
	level = level_to_play
	_registry = registry
	attempt_id = attempt
	student_id = student
	for item in level.items:
		if item.type == ItemType.READING_UNIT:
			for question: Item in item.spec["items"]:
				_add_step(question, item)
		else:
			_add_step(item, null)


func question_count() -> int:
	return _questions.size()


func answered_count() -> int:
	return _first.size()


func current() -> SessionStep:
	return _steps[_position] if _position < _steps.size() else null


func is_finished() -> bool:
	return _position >= _steps.size()


## Número de la pregunta actual (desde 1), según el orden del nivel.
func current_number() -> int:
	var step := current()
	return _questions.find(step.item.id) + 1 if step else 0


## true si el guía ofrece una pista para la pregunta actual (RF-26).
func hint_offered() -> bool:
	return _hint_offered


func hint_shown() -> bool:
	return _hint_shown


## Marca cuándo empezó la pregunta actual, para medir el tiempo de respuesta.
func begin_step(now_ms: int) -> void:
	_step_started_ms = now_ms


## Muestra la pista de la pregunta actual. Desde ese momento, la pregunta deja de contar como
## acierto válido para las estrellas (RN-11). Devuelve "" si no tiene pista.
func take_hint() -> String:
	var step := current()
	if step == null or not step.item.has_hint():
		return ""
	_hint_shown = true
	return step.item.hint


func submit(answer: Variant, now_ms: int) -> AnswerOutcome:
	var step := current()
	if step == null:
		return AnswerOutcome.rejected(&"level_finished")
	var evaluation := _registry.evaluate(step.item, answer)
	if not evaluation.complete:
		return AnswerOutcome.rejected(&"answer_incomplete")
	var outcome := AnswerOutcome.new()
	outcome.evaluation = evaluation
	outcome.question_id = step.item.id
	outcome.feedback = step.item.feedback_for(evaluation)
	outcome.first_try = not step.retry
	outcome.with_hint = _hint_shown
	outcome.time_ms = maxi(0, now_ms - _step_started_ms)
	_elapsed_ms += outcome.time_ms
	outcome.will_return = not evaluation.correct and not step.retry
	if not evaluation.correct and step.retry:
		outcome.solution = _registry.solution_text(step.item)
	_apply(step, evaluation.correct, _hint_shown)
	outcome.finished = is_finished()
	outcome.offer_hint = _hint_offered
	return outcome


## Rehace la sesión con las respuestas guardadas, para continuar donde se quedó (RF-14).
## Devuelve false si no coinciden con el nivel (por ejemplo, si el contenido cambió).
func restore(answers: Array[AttemptAnswer]) -> bool:
	for answer in answers:
		var step := current()
		if step == null or step.item.id != answer.item_id or step.retry == answer.first_try:
			return false
		_apply(step, answer.is_correct, answer.with_hint)
		_elapsed_ms += answer.time_ms
	return true


## Estado de cada pregunta en el orden del nivel. Con `mark_current` en false, la siguiente
## pregunta todavía no se marca (mientras se lee la retroalimentación).
func progress(mark_current: bool = true) -> Array[StringName]:
	var states: Array[StringName] = []
	var step := current()
	var current_id := step.item.id if step and mark_current else ""
	for question_id in _questions:
		var state := PENDING
		if question_id == current_id:
			state = CURRENT
		elif _retry.has(question_id):
			state = FIXED if _retry[question_id] else WRONG
		elif _first.has(question_id):
			state = RIGHT if _first[question_id]["correct"] else MISSED
		states.append(state)
	return states


func summary() -> LevelSummary:
	var result := LevelSummary.new()
	result.total = question_count()
	for question_id: String in _first:
		if _first[question_id]["correct"]:
			result.correct += 1
			if not _first[question_id]["hint"]:
				result.valid_hits += 1
	for question_id: String in _retry:
		if _retry[question_id]:
			result.fixed += 1
	result.hints_used = _hints_used
	result.time_ms = _elapsed_ms
	result.completed = is_finished()
	if result.total > 0:
		result.percent = snappedf(100.0 * result.correct / result.total, 0.1)
	result.stars = StarRule.stars_for(result.valid_hits, result.total, result.lives_lost, result.completed)
	return result


func _add_step(item: Item, unit: Item) -> void:
	_steps.append(SessionStep.new(item, unit, false))
	_questions.append(item.id)


func _apply(step: SessionStep, correct: bool, with_hint: bool) -> void:
	if step.retry:
		_retry[step.item.id] = correct
	else:
		_first[step.item.id] = {"correct": correct, "hint": with_hint}
		if not correct:
			_steps.append(SessionStep.new(step.item, step.unit, true))
	if with_hint:
		_hints_used += 1
	_misses_in_row = 0 if correct else _misses_in_row + 1
	_position += 1
	_hint_shown = false
	_hint_offered = false
	var next := current()
	if _misses_in_row >= HINT_OFFER_AFTER_MISSES and next != null and next.item.has_hint():
		_hint_offered = true
		_misses_in_row = 0

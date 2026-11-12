class_name LevelSession
extends RefCounted
## Reglas de un nivel: orden de las preguntas, pistas, retroalimentación, repaso de los errores
## al final (RF-12, RF-26, RF-29 y RN-11), medidor de peligro y vidas (RN-13 y RN-14).
## Las preguntas de una unidad de lectura se presentan una por una con el texto a la vista (RF-28).
##
## El desafío final (RN-10) no tiene medidor, vidas, pistas ni repaso: cada pregunta se responde
## una vez y al terminar se califica con la escala del CNEB (RN-12).

## Tras dos errores seguidos, el guía ofrece una pista (RF-26).
const HINT_OFFER_AFTER_MISSES := 2

## Estado de cada pregunta, para el quipu de avance.
const PENDING := &"pending"
const CURRENT := &"current"
const RIGHT := &"right"
const MISSED := &"missed"
const FIXED := &"fixed"
const WRONG := &"wrong"
## Desafío final: respondida, sin decir todavía si está bien.
const ANSWERED := &"answered"

var attempt_id := ""
var student_id := ""
var level: Level

var _registry: EvaluatorRegistry
var _scale: CnebGradeScale
var _steps: Array[SessionStep] = []
var _questions: Array[String] = []
var _items := {}
var _position := 0
## Primer intento de cada pregunta: id → {"correct": bool, "hint": bool, "evaluation": Evaluation}.
var _first := {}
## Repaso de las preguntas falladas: id → bool.
var _retry := {}
var _misses_in_row := 0
var _hint_shown := false
var _hint_offered := false
var _hints_used := 0
var _step_started_ms := 0
var _elapsed_ms := 0
## null en el desafío final.
var _meter: DangerMeter
var _lives := 0
var _lives_lost := 0
var _game_over := false
var _streak := 0
var _best_streak := 0


func _init(level_to_play: Level, registry: EvaluatorRegistry, attempt: String = "", student: String = "",
		scale: CnebGradeScale = null) -> void:
	level = level_to_play
	_registry = registry
	_scale = scale if scale else CnebGradeScale.new()
	attempt_id = attempt
	student_id = student
	for item in level.items:
		if item.type == ItemType.READING_UNIT:
			for question: Item in item.spec["items"]:
				_add_step(question, item)
		else:
			_add_step(item, null)
	if not is_final():
		_meter = DangerMeter.new(level.entry.danger_start, level.entry.danger_max)
		_lives = level.entry.lives


func is_final() -> bool:
	return level.entry.is_final()


func question_count() -> int:
	return _questions.size()


func answered_count() -> int:
	return _first.size()


func current() -> SessionStep:
	if _game_over:
		return null
	return _steps[_position] if _position < _steps.size() else null


func is_finished() -> bool:
	return _game_over or _position >= _steps.size()


func is_game_over() -> bool:
	return _game_over


## Número de la pregunta actual (desde 1), según el orden del nivel.
func current_number() -> int:
	var step := current()
	return _questions.find(step.item.id) + 1 if step else 0


## true si el guía ofrece una pista para la pregunta actual (RF-26).
func hint_offered() -> bool:
	return _hint_offered


func hint_shown() -> bool:
	return _hint_shown


func lives() -> int:
	return _lives


func lives_max() -> int:
	return 0 if is_final() else level.entry.lives


func danger() -> int:
	return _meter.value if _meter else 0


func danger_max() -> int:
	return _meter.maximum if _meter else 0


func streak() -> int:
	return _streak


## Marca cuándo empezó la pregunta actual, para medir el tiempo de respuesta.
func begin_step(now_ms: int) -> void:
	_step_started_ms = now_ms


## Muestra la pista de la pregunta actual. Desde ese momento, la pregunta deja de contar como
## acierto válido para las estrellas (RN-11). Devuelve "" si no tiene pista o si es el desafío final.
func take_hint() -> String:
	var step := current()
	if step == null or is_final() or not step.item.has_hint():
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
	outcome.will_return = not evaluation.correct and not step.retry and not is_final()
	if not evaluation.correct and step.retry:
		outcome.solution = _registry.solution_text(step.item)
	var lives_before := _lives
	_apply(step, evaluation.correct, _hint_shown, evaluation)
	outcome.life_lost = _lives < lives_before
	outcome.game_over = _game_over
	outcome.danger = danger()
	outcome.lives = _lives
	outcome.streak = _streak
	outcome.finished = is_finished()
	outcome.offer_hint = _hint_offered
	return outcome


## Rehace la sesión con las respuestas guardadas, para continuar donde se quedó (RF-14).
## El medidor y las vidas se recalculan con las mismas reglas. Devuelve false si las respuestas
## no coinciden con el nivel (por ejemplo, si el contenido cambió).
func restore(answers: Array[AttemptAnswer]) -> bool:
	for answer in answers:
		var step := current()
		if step == null or step.item.id != answer.item_id or step.retry == answer.first_try:
			return false
		var evaluation := _registry.evaluate(step.item, answer.value)
		_apply(step, answer.is_correct, answer.with_hint, evaluation)
		_elapsed_ms += answer.time_ms
	return true


## Estado de cada pregunta en el orden del nivel. Con `mark_current` en false, la siguiente
## pregunta todavía no se marca (mientras se lee la retroalimentación). En el desafío final,
## las respondidas quedan como ANSWERED hasta que `reveal` sea true.
func progress(mark_current: bool = true, reveal: bool = false) -> Array[StringName]:
	var states: Array[StringName] = []
	var step := current()
	var current_id := step.item.id if step and mark_current else ""
	var hide := is_final() and not reveal
	for question_id in _questions:
		var state := PENDING
		if question_id == current_id:
			state = CURRENT
		elif _retry.has(question_id):
			state = FIXED if _retry[question_id] else WRONG
		elif _first.has(question_id):
			if hide:
				state = ANSWERED
			else:
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
	result.lives_lost = _lives_lost
	result.lives_left = _lives
	result.game_over = _game_over
	result.final = is_final()
	result.best_streak = _best_streak
	result.completed = is_finished() and not _game_over
	if result.total > 0:
		result.percent = snappedf(100.0 * result.correct / result.total, 0.1)
	if result.final:
		result.grade = _scale.grade(result.correct, result.total)
	else:
		result.stars = StarRule.stars_for(result.valid_hits, result.total, result.lives_lost, result.completed)
	return result


## Revisión pregunta por pregunta, en el orden del nivel (para el desafío final, RF-30).
func review() -> Array[QuestionReview]:
	var reviews: Array[QuestionReview] = []
	for index in _questions.size():
		var question_id := _questions[index]
		var item: Item = _items[question_id]
		var entry := QuestionReview.new()
		entry.number = index + 1
		entry.question_id = question_id
		entry.prompt = item.prompt
		if _first.has(question_id):
			entry.correct = _first[question_id]["correct"]
			var evaluation: Evaluation = _first[question_id]["evaluation"]
			entry.feedback = item.feedback_for(evaluation) if evaluation else ""
		if not entry.correct:
			entry.solution = _registry.solution_text(item)
		reviews.append(entry)
	return reviews


func _add_step(item: Item, unit: Item) -> void:
	_steps.append(SessionStep.new(item, unit, false))
	_questions.append(item.id)
	_items[item.id] = item


func _apply(step: SessionStep, correct: bool, with_hint: bool, evaluation: Evaluation) -> void:
	if step.retry:
		_retry[step.item.id] = correct
	else:
		_first[step.item.id] = {"correct": correct, "hint": with_hint, "evaluation": evaluation}
		if not correct and not is_final():
			_steps.append(SessionStep.new(step.item, step.unit, true))
	if with_hint:
		_hints_used += 1
	_streak = _streak + 1 if correct else 0
	_best_streak = maxi(_best_streak, _streak)
	if _meter:
		if correct:
			_meter.register_hit()
		elif _meter.register_miss():
			_lives -= 1
			_lives_lost += 1
			_game_over = _lives <= 0
	_misses_in_row = 0 if correct else _misses_in_row + 1
	_position += 1
	_hint_shown = false
	_hint_offered = false
	var next := current()
	if not is_final() and _misses_in_row >= HINT_OFFER_AFTER_MISSES and next != null and next.item.has_hint():
		_hint_offered = true
		_misses_in_row = 0

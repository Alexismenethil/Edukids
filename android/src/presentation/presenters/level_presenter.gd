class_name LevelPresenter
extends RefCounted
## Presentador de un nivel de práctica: abre el nivel elegido, muestra cada pregunta,
## corrige, da pistas y arma los resultados (RF-12, RF-14, RF-25, RF-26 y RF-29).

var _start: StartLevel
var _submit: SubmitAnswer
var _hint: RequestHint
var _continue: ContinueLevel
var _finish: FinishLevel
var _session: PlaySession
var _attempt_id := ""
var _area: AreaViewModel
var _answered := 0
var _progress: Array[StringName] = []


func _init(start: StartLevel, submit: SubmitAnswer, hint: RequestHint, continue_level: ContinueLevel,
		finish: FinishLevel, session: PlaySession) -> void:
	_start = start
	_submit = submit
	_hint = hint
	_continue = continue_level
	_finish = finish
	_session = session


func open() -> LevelIntroViewModel:
	var view_model := LevelIntroViewModel.new()
	view_model.exit_label = PlayMessages.EXIT
	view_model.exit_question = PlayMessages.EXIT_QUESTION
	view_model.exit_detail = PlayMessages.EXIT_DETAIL
	view_model.exit_confirm = PlayMessages.EXIT
	view_model.exit_cancel = PlayMessages.EXIT_CANCEL
	var started := _start.execute(_session.student_id, _session.level_package, _session.level_id)
	if not started.is_ok():
		view_model.error = PlayMessages.LEVEL_UNAVAILABLE
		view_model.area = AreaViewModel.of(&"")
		return view_model
	var start: LevelStartResponse = started.value
	_attempt_id = start.attempt_id
	_area = AreaViewModel.of(start.area)
	view_model.title = start.title
	view_model.area = _area
	view_model.total = start.total
	var lines: Array[String] = []
	if start.resumed:
		lines.append(PlayMessages.resumed(start.answered, start.total))
	else:
		lines.append_array(start.guide_intro)
	view_model.dialogue = _dialogue(lines, &"joy", PlayMessages.INTRO_CLOSE, PlayMessages.SKIP)
	if start.step:
		view_model.step = _step(start.step)
		_progress = start.step.progress
	return view_model


## Corrige la respuesta que arma la vista (texto, lista o diccionario, según la actividad).
func submit(answer: Variant) -> FeedbackViewModel:
	var view_model := FeedbackViewModel.new()
	var submitted := _submit.execute(_attempt_id, answer)
	if not submitted.is_ok():
		view_model.accepted = false
		view_model.notice = PlayMessages.LEVEL_UNAVAILABLE
		return view_model
	var response: AnswerResponse = submitted.value
	if not response.accepted:
		view_model.accepted = false
		view_model.notice = PlayMessages.INCOMPLETE
		return view_model
	view_model.correct = response.correct
	view_model.index = _progress.find(&"current")
	view_model.title = PlayMessages.right_title(_answered) if response.correct else PlayMessages.wrong_title(_answered)
	view_model.message = PlayMessages.keep_numbers_together(response.feedback)
	# Si la explicación empieza con una exclamación («¡Exacto! …»), esa es el título.
	var opening := PlayMessages.opening_exclamation(response.feedback)
	if not opening.is_empty():
		view_model.title = opening
		view_model.message = PlayMessages.keep_numbers_together(response.feedback.substr(opening.length()).strip_edges())
	view_model.parts = response.parts
	view_model.mood = &"cheer" if response.correct else &"comfort"
	if not response.correct:
		if response.missing > 0 and not response.parts.values().has(false):
			view_model.notes.append(PlayMessages.missing(response.missing))
		elif response.parts.size() > 1:
			var hits := response.parts.values().count(true)
			if hits > 0:
				view_model.notes.append(PlayMessages.partial(hits, response.parts.size()))
		if response.will_return:
			view_model.notes.append(PlayMessages.WILL_RETURN)
		if not response.solution.is_empty():
			view_model.notes.append(PlayMessages.keep_numbers_together(PlayMessages.SOLUTION % response.solution))
	view_model.progress = response.progress
	view_model.finished = response.finished
	view_model.continue_label = PlayMessages.RESULTS if response.finished else PlayMessages.CONTINUE
	view_model.warning = "" if response.saved else PlayMessages.NOT_SAVED
	_progress = response.progress
	_answered += 1
	return view_model


## La pista de la pregunta actual como globo del guía, o null si no tiene.
func hint() -> DialogueViewModel:
	var text := _hint.execute(_attempt_id)
	if text.is_empty():
		return null
	return _dialogue([text], &"think", PlayMessages.HINT_THANKS, "")


## La siguiente pregunta, o null si ya no quedan.
func next() -> StepViewModel:
	var continued := _continue.execute(_attempt_id)
	if not continued.is_ok() or continued.value == null:
		return null
	_progress = (continued.value as StepResponse).progress
	return _step(continued.value)


func finish() -> LevelResultViewModel:
	var view_model := LevelResultViewModel.new()
	view_model.area = _area
	view_model.replay_label = PlayMessages.REPLAY
	view_model.continue_label = PlayMessages.CONTINUE
	view_model.record_label = PlayMessages.RECORD
	view_model.progress = _progress
	var finished := _finish.execute(_attempt_id)
	if not finished.is_ok():
		view_model.heading = PlayMessages.result_heading(0)
		view_model.warning = PlayMessages.NOT_SAVED
		return view_model
	var summary: LevelSummaryResponse = finished.value
	view_model.heading = PlayMessages.result_heading(summary.stars)
	view_model.title = summary.title
	view_model.stars = summary.stars
	view_model.new_record = summary.stars > summary.best_before and summary.best_before > 0
	view_model.lines = PlayMessages.result_lines(summary.correct, summary.total, summary.fixed,
		summary.hints_used, summary.time_ms)
	view_model.guide_line = PlayMessages.guide_line(summary.stars, view_model.new_record)
	view_model.warning = "" if summary.saved else PlayMessages.NOT_SAVED
	return view_model


func _step(response: StepResponse) -> StepViewModel:
	var view_model := StepViewModel.new()
	view_model.question_id = response.question_id
	view_model.type = String(response.type)
	view_model.prompt = PlayMessages.keep_numbers_together(response.prompt)
	view_model.image = response.image
	view_model.counter = PlayMessages.counter(response.number, response.total)
	view_model.retry = response.retry
	view_model.retry_label = PlayMessages.RETRY
	view_model.tip = PlayMessages.TIPS.get(view_model.type, "")
	view_model.hint_available = response.hint_available
	view_model.hint_label = PlayMessages.HINT
	view_model.check_label = PlayMessages.CHECK
	view_model.offer_text = PlayMessages.HINT_OFFER if response.hint_offered else ""
	view_model.progress = response.progress
	view_model.index = response.number - 1
	view_model.unit = PlayMessages.tidy(response.unit)
	view_model.data = PlayMessages.tidy(response.data)
	view_model.area = _area
	view_model.labels = PlayMessages.LABELS
	return view_model


static func _dialogue(texts: Array[String], mood: StringName, close_label: String, skip_label: String) -> DialogueViewModel:
	var dialogue := DialogueViewModel.new()
	for text in texts:
		dialogue.lines.append(DialogueLineViewModel.new(PlayMessages.GUIDE, text, mood))
	dialogue.next_label = PlayMessages.NEXT
	dialogue.close_label = close_label
	dialogue.skip_label = skip_label
	return dialogue

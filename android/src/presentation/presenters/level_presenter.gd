class_name LevelPresenter
extends RefCounted
## Presentador de un nivel: abre el nivel elegido, muestra cada pregunta, corrige, da pistas,
## lleva las vidas y el medidor de peligro y arma los resultados, el game over o la calificación
## del desafío final (RF-12, RF-14, RF-25, RF-26, RF-29, RF-30, RN-10, RN-13 y RN-14).

var _start: StartLevel
var _submit: SubmitAnswer
var _hint: RequestHint
var _continue: ContinueLevel
var _finish: FinishLevel
var _session: PlaySession
var _get_profile: GetStudentProfile
var _attempt_id := ""
var _area: AreaViewModel
var _area_id: StringName = &""
var _mechanic: StringName = &"classic"
var _final := false
var _answered := 0
var _total := 0
var _progress: Array[StringName] = []


func _init(start: StartLevel, submit: SubmitAnswer, hint: RequestHint, continue_level: ContinueLevel,
		finish: FinishLevel, session: PlaySession, get_profile: GetStudentProfile = null) -> void:
	_start = start
	_submit = submit
	_hint = hint
	_continue = continue_level
	_finish = finish
	_session = session
	_get_profile = get_profile


func open() -> LevelIntroViewModel:
	var view_model := LevelIntroViewModel.new()
	view_model.exit_label = PlayMessages.EXIT
	view_model.exit_question = PlayMessages.EXIT_QUESTION
	view_model.exit_detail = PlayMessages.EXIT_DETAIL
	view_model.exit_confirm = PlayMessages.EXIT
	view_model.exit_cancel = PlayMessages.EXIT_CANCEL
	var profile := _get_profile.execute(_session.student_id) if _get_profile else null
	view_model.look = AvatarPalette.look_for(profile.avatar if profile else {})
	view_model.region = _session.chapter
	view_model.guide = RegionStyle.guide_of(_session.chapter)
	view_model.guide_name = RegionStyle.guide_name(_session.chapter)
	var started := _start.execute(_session.student_id, _session.level_package, _session.level_id)
	if not started.is_ok():
		view_model.error = PlayMessages.LEVEL_UNAVAILABLE
		view_model.area = AreaViewModel.of(&"")
		return view_model
	var start: LevelStartResponse = started.value
	_attempt_id = start.attempt_id
	_area_id = start.area
	_area = AreaViewModel.of(start.area)
	_final = start.final
	_mechanic = &"classic" if start.final else start.mechanic
	_total = start.total
	_answered = start.answered
	view_model.title = start.title
	view_model.area = _area
	view_model.total = start.total
	view_model.mechanic = _mechanic
	view_model.mechanic_name = MapMessages.mechanic_of(_mechanic, _final)["name"]
	view_model.final = _final
	view_model.lives = start.lives
	view_model.lives_max = start.lives_max
	view_model.danger = start.danger
	view_model.danger_max = start.danger_max
	var lines: Array[String] = []
	if start.resumed:
		lines.append(PlayMessages.resumed(start.answered, start.total))
	elif _final:
		lines.append(PlayMessages.FINAL_INTRO)
		view_model.cover = _cover(start)
	else:
		lines.append_array(start.guide_intro)
		lines.append(PlayMessages.mechanic_intro(_mechanic))
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
	view_model.index = _progress.find(&"current")
	view_model.progress = response.progress
	view_model.finished = response.finished
	view_model.warning = "" if response.saved else PlayMessages.NOT_SAVED
	_progress = response.progress
	_answered += 1
	if _final:
		# En el desafío final no se dice si la respuesta está bien hasta entregar (RN-10).
		view_model.final = true
		view_model.title = PlayMessages.ANSWER_SAVED
		view_model.continue_label = PlayMessages.FINAL_SEE if response.finished else PlayMessages.CONTINUE
		view_model.mood = &"joy"
		return view_model
	view_model.correct = response.correct
	view_model.title = PlayMessages.right_title(_answered - 1) if response.correct else PlayMessages.wrong_title(_answered - 1)
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
		if response.will_return and not response.game_over:
			view_model.notes.append(PlayMessages.WILL_RETURN)
		if not response.solution.is_empty():
			view_model.notes.append(PlayMessages.keep_numbers_together(PlayMessages.SOLUTION % response.solution))
	view_model.danger = response.danger
	view_model.lives = response.lives
	view_model.life_lost = response.life_lost
	view_model.game_over = response.game_over
	view_model.streak = response.streak
	view_model.streak_label = PlayMessages.streak(response.streak) if response.correct else ""
	if response.life_lost and not response.game_over:
		view_model.life_line = PlayMessages.life_lost(_mechanic)
		view_model.notes.insert(0, view_model.life_line)
	view_model.continue_label = PlayMessages.RESULTS if response.finished else PlayMessages.CONTINUE
	return view_model


## La pista de la pregunta actual como globo del guía, o null si no tiene.
func hint() -> DialogueViewModel:
	var text := _hint.execute(_attempt_id)
	if text.is_empty():
		return null
	return _dialogue([text], &"think", PlayMessages.HINT_THANKS, "")


## El globo del guía cuando se pierde una vida (o null si no hay nada que decir).
func life_lost_dialogue(feedback: FeedbackViewModel) -> DialogueViewModel:
	if feedback == null or feedback.life_line.is_empty():
		return null
	return _dialogue([feedback.life_line], &"comfort", PlayMessages.INTRO_CLOSE, "")


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
	view_model.mechanic = _mechanic
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
	view_model.title = summary.title
	view_model.progress = summary.progress
	view_model.lives_left = summary.lives_left
	view_model.lives_max = summary.lives_max
	view_model.warning = "" if summary.saved else PlayMessages.NOT_SAVED
	if summary.game_over:
		view_model.game_over = true
		view_model.heading = PlayMessages.game_over_title(_mechanic)
		view_model.game_over_message = PlayMessages.GAME_OVER_MESSAGE
		var answered := summary.progress.filter(func(state: StringName) -> bool:
			return state != LevelSession.PENDING and state != LevelSession.CURRENT).size()
		view_model.lines = PlayMessages.game_over_lines(answered, summary.total)
		view_model.replay_label = PlayMessages.GAME_OVER_RETRY
		view_model.continue_label = PlayMessages.BACK_TO_STOP
		return view_model
	if summary.final:
		return _final_result(view_model, summary)
	view_model.heading = PlayMessages.result_heading(summary.stars)
	view_model.stars = summary.stars
	view_model.new_record = summary.stars > summary.best_before and summary.best_before > 0
	view_model.lines = PlayMessages.result_lines(summary.correct, summary.total, summary.fixed,
		summary.hints_used, summary.time_ms)
	if summary.lives_max > 0:
		view_model.lines.append(PlayMessages.lives_left(summary.lives_left, summary.lives_max))
	view_model.guide_line = PlayMessages.guide_line(summary.stars, view_model.new_record)
	return view_model


func _final_result(view_model: LevelResultViewModel, summary: LevelSummaryResponse) -> LevelResultViewModel:
	view_model.final = true
	view_model.heading = PlayMessages.FINAL_HEADING
	view_model.grade = summary.grade
	view_model.grade_description = summary.grade_description
	view_model.grade_color = PlayMessages.GRADE_COLORS.get(summary.grade, Color.WHITE)
	view_model.percent_label = PlayMessages.percent(summary.percent)
	view_model.lines = ["Acertaste %d de %d preguntas." % [summary.correct, summary.total]]
	view_model.guide_line = PlayMessages.GRADE_LINES.get(summary.grade, "")
	view_model.cord_label = PlayMessages.cord(_area_id)
	view_model.golden_knot = summary.grade == "AD" or summary.grade == "A"
	view_model.attempts_label = MapMessages.attempts(summary.attempts_left, summary.max_attempts)
	view_model.can_replay = summary.attempts_left > 0
	view_model.replay_label = PlayMessages.GAME_OVER_RETRY
	view_model.continue_label = PlayMessages.BACK_TO_STOP
	view_model.review_title = PlayMessages.FINAL_REVIEW
	for item in summary.review:
		var review := ReviewItemViewModel.new()
		review.number = item.number
		review.prompt = PlayMessages.keep_numbers_together(item.prompt)
		review.correct = item.correct
		review.feedback = PlayMessages.keep_numbers_together(item.feedback)
		review.solution = PlayMessages.keep_numbers_together(PlayMessages.SOLUTION % item.solution) \
			if not item.solution.is_empty() else ""
		view_model.review.append(review)
	return view_model


func _cover(start: LevelStartResponse) -> FinalCoverViewModel:
	var cover := FinalCoverViewModel.new()
	cover.heading = PlayMessages.FINAL_HEADING
	cover.title = start.title
	cover.area = _area
	cover.details = PlayMessages.details(start.total, 0)
	cover.attempt_label = PlayMessages.attempt(start.attempt_number, start.max_attempts)
	cover.rules = PlayMessages.FINAL_RULES.duplicate()
	cover.start_label = PlayMessages.FINAL_START
	return cover


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
	view_model.final = _final
	view_model.hint_available = response.hint_available and not _final
	view_model.hint_label = PlayMessages.HINT
	view_model.check_label = PlayMessages.SAVE_ANSWER if _final else PlayMessages.CHECK
	view_model.offer_text = PlayMessages.HINT_OFFER if response.hint_offered else ""
	view_model.progress = response.progress
	view_model.index = response.number - 1
	view_model.unit = PlayMessages.tidy(response.unit)
	view_model.data = PlayMessages.tidy(response.data)
	view_model.area = _area
	view_model.labels = PlayMessages.LABELS
	return view_model


func _dialogue(texts: Array[String], mood: StringName, close_label: String, skip_label: String) -> DialogueViewModel:
	var dialogue := DialogueViewModel.new()
	for text in texts:
		dialogue.lines.append(DialogueLineViewModel.new(RegionStyle.guide_name(_session.chapter), text, mood))
	dialogue.next_label = PlayMessages.NEXT
	dialogue.close_label = close_label
	dialogue.skip_label = skip_label
	return dialogue

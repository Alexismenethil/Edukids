class_name LevelScreen
extends Control
## Pantalla de un nivel. Arriba, la escena de la mecánica (Atoq que persigue, el puente que se
## arma o Coco que come) con las vidas, el medidor de peligro y el quipu de avance; abajo, la
## pregunta en una tarjeta grande y Quwi en la esquina. En la mecánica clásica, Atoq se asoma por
## el costado. Al terminar: el final feliz de la mecánica y los resultados, el game over o, en el
## desafío final, la calificación con la revisión de cada pregunta.

signal exit_requested
signal finished
signal replay_requested

## Cuerda del quipu recuperada en un desafío final (vacío si no hubo): el navegador muestra el
## corto de la entrega al salir.
var cord_text := ""
var cord_color := Color("#E8833A")

const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")
const BUBBLE := preload("res://scenes/ui/components/speech_bubble.tscn")
const KNOTS_RETURN := preload("res://assets/audio/sfx/sfx_knots_return.ogg")
const STAGE_HEIGHT := 212.0
const QUWI_SCALE := 0.62
const STAGES := {&"chase": "ChaseStage", &"bridge": "BridgeStage", &"caiman": "CaimanStage"}
const METER_ICONS := {&"chase": &"fox", &"bridge": &"river", &"caiman": &"caiman", &"classic": &"fox"}

var _presenter: LevelPresenter
var _intro: LevelIntroViewModel
var _step: StepViewModel
var _feedback_model: FeedbackViewModel
var _activity: ActivityView
var _card: PanelContainer
var _content: Control
var _check: Button
var _hint: Button
var _quipu: QuipuProgress
var _quwi: GuideCharacter
var _bubble: SpeechBubble
var _feedback: FeedbackPanel
var _confetti: CPUParticles2D
var _sfx: SfxPlayer
var _waiting := false
var _hint_pulse: Tween
var _results: Control
var _stage: MechanicStage
var _lives: LivesHud
var _meter: DangerMeterView
var _cover: FinalCover
## La tarjeta vive en un soporte que baja y sube (la reacción se ve a pantalla completa).
var _card_holder: Control
var _card_tween: Tween
## Márgenes de la tarjeta: izquierda, arriba, derecha y abajo.
var _margin := Vector4(204.0, 106.0, 28.0, 24.0)
var _staged := false
var _ending := false


func setup(presenter: LevelPresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := SierraBackdrop.new()
	backdrop.veil = 0.12
	add_child(backdrop)
	_intro = _presenter.open()
	var playable := _intro.error.is_empty()
	_staged = playable and not _intro.final and STAGES.has(_intro.mechanic)
	if _staged:
		_margin = Vector4(204.0, STAGE_HEIGHT + 8.0, 28.0, 18.0)
		backdrop.visible = false
		_build_stage()
	elif playable and not _intro.final:
		_margin = Vector4(204.0, 106.0, 76.0, 24.0)
	_build_card()
	if playable and not _intro.final and not _staged:
		_build_peeking_atoq()
	_build_hud()
	_build_guide()
	_feedback = FeedbackPanel.new()
	_feedback.continue_requested.connect(_on_continue)
	add_child(_feedback)
	_confetti = _make_confetti()
	add_child(_confetti)
	_sfx = SfxPlayer.new()
	add_child(_sfx)
	if not playable:
		_show_error()
		return
	if _staged:
		_card_holder.position.y = _card_drop()
	else:
		_card.modulate.a = 0.0
	if _staged:
		_show_title_card()
	var later := create_tween()
	later.tween_interval(2.3 if _staged else 0.45)
	later.tween_callback(func() -> void:
		_quwi.enter_from(-220.0, 3)
		if _stage:
			_stage.start()
		if _intro.cover:
			_open_cover()
			return
		if _intro.dialogue == null or _intro.dialogue.lines.is_empty():
			_on_intro_finished()
			return
		_bubble.finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)
		_say(_intro.dialogue, &"joy"))


func _on_intro_finished() -> void:
	if _intro.step == null:
		_end_level()
		return
	if _staged:
		_stage.frame(MechanicStage.Shot.QUESTION, 0.9)
		_slide_card(true, 0.25)
	else:
		var tween := create_tween()
		tween.tween_property(_card, "modulate:a", 1.0, 0.25)
	_show_step(_intro.step)


# --- Armado -------------------------------------------------------------------------------

func _build_stage() -> void:
	match _intro.mechanic:
		&"chase":
			_stage = ChaseStage.new()
		&"bridge":
			_stage = BridgeStage.new()
		_:
			_stage = CaimanStage.new()
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.question_band = _margin.y
	_stage.configure(_intro)
	add_child(_stage)
	_stage.frame(MechanicStage.Shot.ACTION, 0.0)
	_stage.life_taken.connect(func() -> void:
		if _lives:
			_lives.lose_one()
		_shake())


## Letrero de entrada sobre el paisaje: el nombre de la mecánica y el del nivel, como el título de
## una película. Aparece con un rebote, se queda un momento y se va hacia arriba.
func _show_title_card() -> void:
	var card := Ui.vbox(6)
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ribbon := PanelContainer.new()
	ribbon.theme_type_variation = &"RibbonPanel"
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var mechanic := Ui.label(_intro.mechanic_name, &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER)
	mechanic.add_theme_font_size_override("font_size", 30)
	ribbon.add_child(mechanic)
	card.add_child(ribbon)
	var title := Ui.label(_intro.title, &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 900)
	title.add_theme_font_size_override("font_size", 50)
	title.add_theme_constant_override("outline_size", 16)
	card.add_child(title)
	add_child(card)
	card.reset_size()
	var width := size.x if size.x > 64.0 else get_viewport_rect().size.x
	card.position = Vector2((width - card.size.x) * 0.5, 150.0)
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.6, 0.6)
	card.modulate.a = 0.0
	var tween := card.create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(card, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(card, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.5)
	tween.tween_property(card, "position:y", card.position.y - 60.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(card, "modulate:a", 0.0, 0.4)
	tween.tween_callback(card.queue_free)


func _build_peeking_atoq() -> void:
	_stage = ClassicStage.new()
	_stage.configure(_intro)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	(_stage as ClassicStage).foot_y = 640.0
	add_child(_stage)
	resized.connect(func() -> void: (_stage as ClassicStage).foot_y = size.y - 160.0)


func _build_hud() -> void:
	var exit := Ui.compact(Ui.button(_intro.exit_label, "back", &"SoftButton"), 24)
	exit.position = Vector2(16, 12) if _staged else Vector2(24, 22)
	exit.pressed.connect(_on_exit)
	add_child(exit)
	if not _staged:
		var chip := PanelContainer.new()
		var style := ActivityStyle.box(ActivityStyle.CREAM, _intro.area.color, 6, 30, 3)
		style.content_margin_left = 10
		style.content_margin_right = 24
		style.content_margin_top = 6
		style.content_margin_bottom = 8
		chip.add_theme_stylebox_override("panel", style)
		var row := Ui.hbox(12)
		row.add_child(_emblem(_intro.area, 44.0))
		var title := ActivityStyle.label(_intro.title, 26, ActivityStyle.INK, false)
		title.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
		row.add_child(title)
		chip.add_child(row)
		chip.position = Vector2(_margin.x, 22)
		add_child(chip)
	if _intro.lives_max > 0:
		_lives = LivesHud.new()
		_lives.set_lives(_intro.lives, _intro.lives_max)
		_lives.position = Vector2(156, 20) if _staged else Vector2(30, 104)
		add_child(_lives)
		_meter = DangerMeterView.new()
		_meter.icon = METER_ICONS.get(_intro.mechanic, &"fox")
		if not _staged:
			_meter.segment_width = 24.0
		_meter.set_value(_intro.danger, _intro.danger_max, false)
		add_child(_meter)
		if _staged:
			# Como en el diseño: vidas arriba a la izquierda, medidor al centro y avance a la derecha.
			_meter.set_anchors_preset(Control.PRESET_CENTER_TOP)
			_meter.offset_left = -_meter.size.x * 0.5
			_meter.offset_right = _meter.size.x * 0.5
			_meter.offset_top = 10.0
		else:
			_meter.position = Vector2(14, 152)
	_quipu = QuipuProgress.new()
	_quipu.accent = _intro.area.deep
	_quipu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quipu.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_quipu.offset_right = -20 if _staged else -28
	_quipu.offset_top = 6 if _staged else 16
	add_child(_quipu)
	if _staged:
		_quipu.modulate = Color(1, 1, 1, 0.98)


func _build_card() -> void:
	_card_holder = Control.new()
	_card_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_card_holder)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.offset_left = _margin.x
	_card.offset_top = _margin.y
	_card.offset_right = -_margin.z
	_card.offset_bottom = -_margin.w
	_card_holder.add_child(_card)


func _build_guide() -> void:
	# El guía del capítulo: Quwi en la Sierra, Tunki en la Selva y Humbi en la Costa.
	_quwi = Cast.create(_intro.guide) as GuideCharacter
	if _quwi == null:
		_quwi = QUWI.instantiate()
	_quwi.scale = Vector2(QUWI_SCALE, QUWI_SCALE)
	_quwi.interactive = true
	add_child(_quwi)
	_bubble = BUBBLE.instantiate()
	_bubble.flipped = true
	add_child(_bubble)
	resized.connect(_place_guide)
	_place_guide()


func _place_guide() -> void:
	_quwi.position = Vector2(104, size.y - 22)
	_bubble.position = Vector2(150, size.y - 214)


## Contenido de la tarjeta para una pregunta: enunciado, actividad y botones.
func _build_content(step: StepViewModel) -> Control:
	var column := Ui.vbox(8 if _staged else 10)
	var question := Ui.vbox(8 if _staged else 10)
	question.size_flags_vertical = Control.SIZE_EXPAND_FILL
	question.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reading := not step.unit.is_empty()
	step.short = _staged
	var prompt := ActivityStyle.label(step.prompt, 27 if not reading else 24, ActivityStyle.INK, true, 300)
	prompt.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	question.add_child(prompt)
	if not step.tip.is_empty():
		question.add_child(ActivityStyle.label(step.tip, 19 if reading or _staged else 20, ActivityStyle.MUTED, true, 300))
	_activity = ActivityFactory.create(step)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _activity:
		scroll.add_child(_activity)
		_activity.changed.connect(_refresh_check)
	question.add_child(scroll)
	if reading:
		var split := Ui.hbox(24)
		split.size_flags_vertical = Control.SIZE_EXPAND_FILL
		split.add_child(ReadingPanel.new(step.unit, step.area))
		split.add_child(question)
		column.add_child(split)
	else:
		column.add_child(question)
	var footer := Ui.hbox(16)
	_hint = Ui.compact(Ui.button(step.hint_label, "hint", &"SoftButton"), 24)
	_hint.visible = step.hint_available
	_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hint.custom_minimum_size = Vector2(150, 60)
	_hint.pressed.connect(_on_hint)
	footer.add_child(_hint)
	if not step.hint_available:
		footer.add_child(Ui.spacer(150))
	# Al centro del pie: «Pregunta 3 de 8» y, en el repaso, «¡Otra oportunidad!».
	var middle := Ui.hbox(10)
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(ActivityStyle.label(step.counter, 21, ActivityStyle.MUTED, false))
	if step.retry:
		var ribbon := PanelContainer.new()
		var style := ActivityStyle.box(Color("#FFF1C9"), Color("#E0A526"), 4, 16, 3)
		style.content_margin_top = 2
		style.content_margin_bottom = 4
		ribbon.add_theme_stylebox_override("panel", style)
		ribbon.add_child(ActivityStyle.label(step.retry_label, 21, ActivityStyle.BROWN, false))
		middle.add_child(ribbon)
	footer.add_child(middle)
	_check = Ui.button(step.check_label, "check")
	_check.custom_minimum_size = Vector2(250 if not step.final else 290, 70)
	_check.pressed.connect(_on_check)
	footer.add_child(_check)
	column.add_child(footer)
	return column


# --- Flujo -------------------------------------------------------------------------------

func _open_cover() -> void:
	_cover = FinalCover.new(_intro.cover)
	_cover.started.connect(func() -> void:
		_cover = null
		_quwi.set_mood(&"cheer")
		_on_intro_finished(), CONNECT_ONE_SHOT)
	add_child(_cover)


func _show_step(step: StepViewModel) -> void:
	_step = step
	_quipu.set_states(step.progress)
	if _stage:
		_stage.question_shown(step)
	var previous := _content
	_content = _build_content(step)
	_content.modulate.a = 0.0
	_card.add_child(_content)
	if previous:
		var out := create_tween()
		out.tween_property(previous, "modulate:a", 0.0, 0.15)
		out.tween_callback(previous.queue_free)
	var tween := create_tween()
	tween.tween_interval(0.12 if previous else 0.0)
	tween.tween_property(_content, "modulate:a", 1.0, 0.25)
	_refresh_check()
	_waiting = true
	_quwi.set_mood(&"joy")
	if not step.offer_text.is_empty():
		var offer := DialogueViewModel.new()
		offer.lines.append(DialogueLineViewModel.new(_intro.guide_name, step.offer_text, &"comfort"))
		offer.close_label = "¡Bueno!"
		offer.skip_label = ""
		get_tree().create_timer(0.6).timeout.connect(func() -> void:
			if _step == step:
				_say(offer, &"comfort"))
		_pulse_hint(true)


func _refresh_check() -> void:
	if _check == null or _activity == null:
		return
	var ready := _activity.is_complete()
	_check.modulate = Color(1, 1, 1, 1.0 if ready else 0.55)


func _on_check() -> void:
	if not _waiting or _activity == null:
		return
	var feedback := _presenter.submit(_activity.answer())
	if not feedback.accepted:
		ActivityStyle.shake(_check)
		var notice := DialogueViewModel.new()
		notice.lines.append(DialogueLineViewModel.new(_intro.guide_name, feedback.notice, &"think"))
		notice.close_label = "¡Bueno!"
		notice.skip_label = ""
		_say(notice, &"think")
		return
	_waiting = false
	_feedback_model = feedback
	_pulse_hint(false)
	if _bubble.is_open():
		_bubble.close()
	_activity.lock()
	_check.disabled = true
	_hint.disabled = true
	_quipu.set_states(feedback.progress)
	if feedback.final:
		# Desafío final: solo se guarda; la corrección llega al entregar.
		_toast(feedback.title)
		_quwi.hop(22.0)
		get_tree().create_timer(0.95).timeout.connect(_on_continue)
		return
	_activity.show_result(feedback.parts)
	_quwi.set_mood(feedback.mood)
	if feedback.correct:
		_quwi.hop(34.0)
		_quwi.squeak()
		_quwi.emote(&"sparkle", 1.2)
	else:
		_quwi.emote(&"heart", 1.6)
		_confetti.global_position = _check.get_global_rect().get_center()
		_confetti.restart()
	if _meter:
		_meter.set_value(feedback.danger, _intro.danger_max)
	if _staged:
		_play_reaction(feedback)
		return
	if _stage:
		_stage.react(feedback)
	if feedback.life_lost and _lives:
		get_tree().create_timer(0.85).timeout.connect(func() -> void:
			_lives.lose_one()
			_shake())
	_present_feedback(feedback)


## La respuesta se ve en grande: la tarjeta baja, la cámara abre a toda la pantalla, la mecánica
## reacciona (salto, tropiezo, mordisco) y la tarjeta vuelve con la explicación.
func _play_reaction(feedback: FeedbackViewModel) -> void:
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void:
		_slide_card(false)
		_stage.frame(MechanicStage.Shot.ACTION, 0.55)
		var seconds := _stage.react(feedback)
		get_tree().create_timer(seconds + 0.2).timeout.connect(func() -> void:
			if _ending:
				return
			_stage.frame(MechanicStage.Shot.QUESTION, 0.6)
			_slide_card(true, 0.15)
			get_tree().create_timer(0.55).timeout.connect(_present_feedback.bind(feedback))))


func _present_feedback(feedback: FeedbackViewModel) -> void:
	if _ending:
		return
	_feedback.fill(feedback)
	_feedback.custom_minimum_size.x = _card.size.x - 40.0
	_feedback.reset_size()
	var target := Vector2(_card.position.x + 20.0, _card.position.y + _card.size.y - _feedback.size.y - 12.0)
	_feedback.slide_in(target, size.y + 20.0)


## Baja (o sube) la tarjeta de la pregunta con un rebote suave.
func _slide_card(up: bool, delay: float = 0.0) -> void:
	if _card_tween:
		_card_tween.kill()
	_card_tween = create_tween()
	if delay > 0.0:
		_card_tween.tween_interval(delay)
	if up:
		_card_tween.tween_property(_card_holder, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_card_tween.tween_property(_card_holder, "position:y", _card_drop(), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func _card_drop() -> float:
	return maxf(size.y, 800.0) - _margin.y + 60.0


func _on_continue() -> void:
	_feedback.dismiss()
	if _feedback_model and _feedback_model.finished:
		_end_level()
		return
	var next := _presenter.next()
	if next == null:
		_end_level()
		return
	_show_step(next)


func _on_hint() -> void:
	if not _waiting:
		return
	var dialogue := _presenter.hint()
	if dialogue == null:
		return
	_pulse_hint(false)
	_hint.modulate = Color(1, 1, 1, 0.6)
	_say(dialogue, &"think")


func _on_exit() -> void:
	var dialog := ConfirmDialog.new(_intro.exit_question, _intro.exit_detail, _intro.exit_confirm, _intro.exit_cancel)
	dialog.confirmed.connect(func() -> void: exit_requested.emit())
	add_child(dialog)


## Cierra el nivel: el final de la mecánica y después los resultados, el game over o la
## calificación del desafío final.
func _end_level() -> void:
	if _ending:
		return
	_ending = true
	_waiting = false
	var result := _presenter.finish()
	if result.final:
		_fade_card(0.0)
		_show_final(result)
		return
	if _stage == null:
		_show_results(result)
		return
	if _staged:
		_slide_card(false)
		_stage.frame(MechanicStage.Shot.ACTION, 0.7)
	else:
		_fade_card(0.0)
	_stage.payoff_finished.connect(func() -> void:
		if result.game_over:
			_show_game_over(result)
		else:
			_show_results(result), CONNECT_ONE_SHOT)
	if result.game_over:
		_quwi.set_mood(&"comfort")
		_stage.play_game_over()
	else:
		_quwi.celebrate()
		_stage.play_payoff()


func _fade_card(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_card, "modulate:a", alpha, 0.4)


func _show_results(result: LevelResultViewModel) -> void:
	_sfx.play(KNOTS_RETURN, 1.0, -6.0)
	var results := LevelResults.new(result)
	results.replay_requested.connect(func() -> void: replay_requested.emit())
	results.continue_requested.connect(func() -> void: finished.emit())
	_present(results)
	if _lives and result.lives_left >= result.lives_max:
		_lives.beat()
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(func() -> void:
		_quwi.celebrate()
		if result.stars >= 2:
			_confetti.global_position = Vector2(size.x * 0.5 + 90.0, size.y * 0.3)
			_confetti.restart())


func _show_game_over(result: LevelResultViewModel) -> void:
	var panel := GameOverPanel.new(result)
	panel.replay_requested.connect(func() -> void: replay_requested.emit())
	panel.continue_requested.connect(func() -> void: finished.emit())
	_present(panel)
	_quwi.set_mood(&"comfort")


func _show_final(result: LevelResultViewModel) -> void:
	# La cuerda vuelve al quipu cuando el desafío se supera (AD, A o B).
	cord_text = result.cord_label if result.grade != "C" else ""
	cord_color = result.area.color if result.area else Color("#E8833A")
	_sfx.play(KNOTS_RETURN, 1.0, -6.0)
	var panel := FinalResults.new(result)
	panel.replay_requested.connect(func() -> void: replay_requested.emit())
	panel.continue_requested.connect(func() -> void: finished.emit())
	_present(panel)
	if result.golden_knot:
		var tween := create_tween()
		tween.tween_interval(2.4)
		tween.tween_callback(func() -> void:
			_quwi.celebrate()
			_confetti.global_position = Vector2(size.x * 0.3, size.y * 0.35)
			_confetti.restart())


func _present(overlay: Control) -> void:
	_results = overlay
	add_child(overlay)
	move_child(_quwi, -1)
	move_child(_confetti, -1)


func _show_error() -> void:
	var box := Ui.vbox(18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(Ui.label(_intro.error, &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 600))
	_card.add_child(box)
	_quwi.set_mood(&"comfort")


## «¡Respuesta guardada!» sobre la tarjeta (desafío final).
func _toast(text: String) -> void:
	var pill := PanelContainer.new()
	var style := ActivityStyle.box(Color("#EEE9FA"), Color("#8B7AC0"), 6, 26, 3)
	style.content_margin_left = 22
	style.content_margin_right = 26
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	pill.add_theme_stylebox_override("panel", style)
	var row := Ui.hbox(10)
	var icon := TextureRect.new()
	icon.texture = Ui.icon("check")
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color("#5B4A99")
	row.add_child(icon)
	row.add_child(ActivityStyle.label(text, 26, Color("#3E3170"), false))
	pill.add_child(row)
	add_child(pill)
	pill.reset_size()
	var center := _card.get_global_rect().get_center() - get_global_rect().position
	pill.position = center - pill.size * 0.5
	pill.pivot_offset = pill.size * 0.5
	pill.scale = Vector2(0.6, 0.6)
	var tween := pill.create_tween()
	tween.tween_property(pill, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.55)
	tween.tween_property(pill, "modulate:a", 0.0, 0.25)
	tween.tween_callback(pill.queue_free)


## Sacudida breve de la pantalla al perder una vida.
func _shake() -> void:
	var tween := create_tween()
	for i in 6:
		tween.tween_property(self, "position", Vector2(randf_range(-7, 7), randf_range(-5, 5)), 0.04)
	tween.tween_property(self, "position", Vector2.ZERO, 0.05)


# --- Guía ---------------------------------------------------------------------------------

func _say(dialogue: DialogueViewModel, mood: StringName) -> void:
	if dialogue == null or dialogue.lines.is_empty():
		return
	_quwi.set_mood(mood)
	_quwi.talk(true)
	_bubble.play(dialogue)
	if not _bubble.finished.is_connected(_on_bubble_closed):
		_bubble.finished.connect(_on_bubble_closed)


func _on_bubble_closed() -> void:
	_quwi.talk(false)


func _pulse_hint(active: bool) -> void:
	if _hint_pulse:
		_hint_pulse.kill()
		_hint_pulse = null
	if _hint == null:
		return
	_hint.scale = Vector2.ONE
	if not active or not _hint.visible:
		return
	_hint.pivot_offset = _hint.size * 0.5
	_hint_pulse = create_tween().set_loops()
	_hint_pulse.tween_property(_hint, "scale", Vector2(1.08, 1.08), 0.45).set_trans(Tween.TRANS_SINE)
	_hint_pulse.tween_property(_hint, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_SINE)


func _emblem(area: AreaViewModel, diameter: float) -> Control:
	var circle := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = area.deep
	style.border_color = area.color
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(diameter * 0.5))
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	circle.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.texture = Ui.icon(area.icon)
	icon.custom_minimum_size = Vector2(diameter - 14.0, diameter - 14.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	circle.add_child(icon)
	return circle


func _make_confetti() -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 36
	particles.lifetime = 1.2
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 70.0
	particles.gravity = Vector2(0, 980)
	particles.initial_velocity_min = 320.0
	particles.initial_velocity_max = 560.0
	particles.angular_velocity_min = -540.0
	particles.angular_velocity_max = 540.0
	particles.damping_min = 40.0
	particles.damping_max = 80.0
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 11.0
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colors.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	colors.colors = PackedColorArray([Color("#E8833A"), Color("#3B7DD8"), Color("#3FA34D"), Color("#C2185B"), Color("#F2C14E")])
	particles.color_initial_ramp = colors
	return particles


# --- Modo demostración (para grabar el video sin tocar la pantalla) ------------------------

func demo_question_id() -> String:
	return _step.question_id if _step and _waiting else ""


func demo_answer(value: Variant) -> void:
	if _activity and _waiting:
		_activity.apply_answer(value)


func demo_check() -> void:
	_on_check()


func demo_continue() -> void:
	_feedback.press_continue()


func demo_feedback_ready() -> bool:
	return _intro.final or _feedback.is_shown()


func demo_hint() -> void:
	_on_hint()


func demo_close_bubble() -> void:
	if _bubble.is_open():
		_bubble.close()


func demo_start_cover() -> void:
	if _cover:
		_cover.press_start()


func demo_showing_results() -> bool:
	return _results != null


func demo_leave_results() -> void:
	if _results:
		finished.emit()


## Toca a Quwi con un toque de verdad (modo demostración): prueba el camino completo del dedo.
func demo_tap_guide() -> void:
	var at := _quwi.global_position + Vector2(0, -70)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		await get_tree().process_frame

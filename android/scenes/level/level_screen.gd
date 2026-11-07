class_name LevelScreen
extends Control
## Nivel de práctica con la mecánica clásica: Quwi acompaña desde la esquina y cada pregunta
## aparece en una tarjeta grande. Arriba, un quipu marca el avance. Al comprobar, la tarjeta
## marca lo que salió bien o mal y sube la retroalimentación. Las vidas, el medidor de peligro
## y Atoq llegan con las mecánicas del Sprint 5.

signal exit_requested
signal finished
signal replay_requested

const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")
const BUBBLE := preload("res://scenes/ui/components/speech_bubble.tscn")
const KNOTS_RETURN := preload("res://assets/audio/sfx/sfx_knots_return.ogg")
const CARD_MARGIN := Vector4(204.0, 106.0, 28.0, 24.0)
const QUWI_SCALE := 0.62

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
var _quwi: QuwiCharacter
var _bubble: SpeechBubble
var _feedback: FeedbackPanel
var _confetti: CPUParticles2D
var _sfx: SfxPlayer
var _waiting := false
var _hint_pulse: Tween
var _results: LevelResults


func setup(presenter: LevelPresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := SierraBackdrop.new()
	backdrop.veil = 0.12
	add_child(backdrop)
	_intro = _presenter.open()
	_build_card()
	_build_hud()
	_build_guide()
	_feedback = FeedbackPanel.new()
	_feedback.continue_requested.connect(_on_continue)
	add_child(_feedback)
	_confetti = _make_confetti()
	add_child(_confetti)
	_sfx = SfxPlayer.new()
	add_child(_sfx)
	if not _intro.error.is_empty():
		_show_error()
		return
	_card.modulate.a = 0.0
	var later := create_tween()
	later.tween_interval(0.45)
	later.tween_callback(func() -> void:
		_quwi.enter_from(-220.0, 3)
		if _intro.dialogue == null or _intro.dialogue.lines.is_empty():
			_on_intro_finished()
			return
		_bubble.finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)
		_say(_intro.dialogue, &"joy"))


func _on_intro_finished() -> void:
	if _intro.step == null:
		_show_results(_presenter.finish())
		return
	var tween := create_tween()
	tween.tween_property(_card, "modulate:a", 1.0, 0.25)
	_show_step(_intro.step)


# --- Armado -------------------------------------------------------------------------------

func _build_hud() -> void:
	var exit := Ui.compact(Ui.button(_intro.exit_label, "back", &"SoftButton"), 24)
	exit.position = Vector2(24, 22)
	exit.pressed.connect(_on_exit)
	add_child(exit)
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
	chip.position = Vector2(CARD_MARGIN.x, 22)
	add_child(chip)
	_quipu = QuipuProgress.new()
	_quipu.accent = _intro.area.deep
	_quipu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_quipu.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_quipu.offset_right = -28
	_quipu.offset_top = 16
	add_child(_quipu)


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.offset_left = CARD_MARGIN.x
	_card.offset_top = CARD_MARGIN.y
	_card.offset_right = -CARD_MARGIN.z
	_card.offset_bottom = -CARD_MARGIN.w
	add_child(_card)


func _build_guide() -> void:
	_quwi = QUWI.instantiate()
	_quwi.scale = Vector2(QUWI_SCALE, QUWI_SCALE)
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
	var column := Ui.vbox(10)
	var question := Ui.vbox(10)
	question.size_flags_vertical = Control.SIZE_EXPAND_FILL
	question.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reading := not step.unit.is_empty()
	var prompt := ActivityStyle.label(step.prompt, 28 if not reading else 25, ActivityStyle.INK, true, 300)
	prompt.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	question.add_child(prompt)
	if not step.tip.is_empty():
		question.add_child(ActivityStyle.label(step.tip, 19 if reading else 20, ActivityStyle.MUTED, true, 300))
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
		split.add_child(ReadingPanel.new(step.unit))
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
	_check.custom_minimum_size = Vector2(250, 70)
	_check.pressed.connect(_on_check)
	footer.add_child(_check)
	column.add_child(footer)
	return column


# --- Flujo -------------------------------------------------------------------------------

func _show_step(step: StepViewModel) -> void:
	_step = step
	_quipu.set_states(step.progress)
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
		offer.lines.append(DialogueLineViewModel.new(PlayMessages.GUIDE, step.offer_text, &"comfort"))
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
		notice.lines.append(DialogueLineViewModel.new(PlayMessages.GUIDE, feedback.notice, &"think"))
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
	_activity.show_result(feedback.parts)
	_quipu.set_states(feedback.progress)
	_check.disabled = true
	_hint.disabled = true
	_quwi.set_mood(feedback.mood)
	if feedback.correct:
		_quwi.hop(34.0)
		_quwi.squeak()
		_confetti.global_position = _check.get_global_rect().get_center()
		_confetti.restart()
	_feedback.fill(feedback)
	_feedback.custom_minimum_size.x = _card.size.x - 40.0
	_feedback.reset_size()
	var target := Vector2(_card.position.x + 20.0, _card.position.y + _card.size.y - _feedback.size.y - 12.0)
	_feedback.slide_in(target, size.y + 20.0)


func _on_continue() -> void:
	_feedback.dismiss()
	if _feedback_model and _feedback_model.finished:
		_show_results(_presenter.finish())
		return
	var next := _presenter.next()
	if next == null:
		_show_results(_presenter.finish())
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


func _show_results(result: LevelResultViewModel) -> void:
	_waiting = false
	_sfx.play(KNOTS_RETURN, 1.0, -6.0)
	var results := LevelResults.new(result)
	results.replay_requested.connect(func() -> void: replay_requested.emit())
	results.continue_requested.connect(func() -> void: finished.emit())
	add_child(results)
	_results = results
	move_child(_quwi, -1)
	move_child(_confetti, -1)
	var tween := create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(func() -> void:
		_quwi.celebrate()
		if result.stars >= 2:
			_confetti.global_position = Vector2(size.x * 0.5 + 90.0, size.y * 0.3)
			_confetti.restart())


func _show_error() -> void:
	var box := Ui.vbox(18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(Ui.label(_intro.error, &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 600))
	_card.add_child(box)
	_quwi.set_mood(&"comfort")


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


func demo_hint() -> void:
	_on_hint()


func demo_close_bubble() -> void:
	if _bubble.is_open():
		_bubble.close()


func demo_showing_results() -> bool:
	return _results != null


func demo_leave_results() -> void:
	if _results:
		finished.emit()

class_name ProfilePickerScreen
extends Control
## «¿Quién va a jugar hoy?» (RF-05 y CU-03): los personajes de la sección esperan de pie en
## la Sierra. Al tocar uno, salta a primer plano y su PIN se ata como nudos de un quipu.
## Vista humilde: todo lo decide el presentador.

signal back_requested
signal logged_in(needs_avatar: bool)

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")
const BIG_AVATAR_SCALE := 1.0

var _presenter: ProfilePickerPresenter
var _view_model: ProfilePickerViewModel
var _cards: Array[ProfileCardViewModel] = []
var _carousel: Carousel
var _left: Button
var _right: Button
var _sections := Ui.hbox(12)
var _section_group := ButtonGroup.new()
var _empty: Control
var _hint: Label
var _overlay: Control
var _veil: ColorRect
var _big_avatar: AvatarCharacter
var _big_rug: WovenRug
var _pin_card: PanelContainer
var _greeting: Label
var _prompt: Label
var _quipu: QuipuPin
var _feedback_title: Label
var _feedback_text: Label
var _pad: PinPad
var _not_me: Button
var _selected: ProfileCardViewModel
var _selected_card: StudentCard
var _lock_left := 0.0
var _last_lock_second := -1
var _busy := false


func setup(presenter: ProfilePickerPresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := SierraBackdrop.new()
	backdrop.ground_offset = 30.0
	add_child(backdrop)
	_build_header()
	_build_carousel()
	_build_empty_state()
	_build_overlay()
	if _presenter == null:
		return
	_view_model = _presenter.screen()
	_title_label.text = _view_model.title
	_hint.text = _view_model.hint
	_back.text = _view_model.back_label
	_prompt.text = _view_model.pin_prompt
	_not_me.text = _view_model.not_me_label
	for tab in _view_model.sections:
		var chip := Ui.chip(tab.label, _section_group)
		chip.toggled.connect(func(on: bool) -> void:
			if on:
				_show_section(tab.id))
		_sections.add_child(chip)
		if tab.id == _view_model.selected_section_id:
			chip.set_pressed_no_signal(true)
	_sections.visible = _view_model.sections.size() > 1
	_show_section(_view_model.selected_section_id)


func _process(delta: float) -> void:
	if _lock_left > 0.0:
		_lock_left -= delta
		var second := ceili(_lock_left)
		if second != _last_lock_second:
			_last_lock_second = second
			_feedback_text.text = _presenter.locked_message(second)
		if _lock_left <= 0.0:
			_lock_left = 0.0
			_feedback_title.text = ""
			_feedback_text.text = ""
			_pad.set_enabled(true)


## Para el modo demostración: abre el perfil indicado.
func choose(index: int) -> void:
	_on_card_tapped(index)


## Para el modo demostración: escribe un PIN completo.
func type_pin(pin: String) -> void:
	for digit in pin:
		_pad._press(digit)


# --- Construcción ---

var _title_label: Label
var _back: Button


func _build_header() -> void:
	_back = Ui.button("Inicio", "back", &"SoftButton")
	_back.position = Vector2(24, 22)
	_back.pressed.connect(func() -> void: back_requested.emit())
	add_child(_back)

	var top := Ui.vbox(10)
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.offset_top = 18
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	var ribbon := PanelContainer.new()
	ribbon.theme_type_variation = &"RibbonPanel"
	_title_label = Ui.label("", &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER)
	ribbon.add_child(_title_label)
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(ribbon)
	_sections.alignment = BoxContainer.ALIGNMENT_CENTER
	_sections.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(_sections)
	add_child(top)

	_hint = Ui.label("", &"SubtitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_hint.add_theme_font_size_override("font_size", 24)
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.offset_bottom = -14
	add_child(_hint)


func _build_carousel() -> void:
	_carousel = Carousel.new()
	_carousel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_carousel.offset_top = 170
	_carousel.offset_bottom = -44
	_carousel.offset_left = 96
	_carousel.offset_right = -96
	_carousel.separation = 18
	_carousel.item_tapped.connect(_on_card_tapped)
	_carousel.scrolled.connect(func(at_start: bool, at_end: bool) -> void:
		_left.visible = not at_start
		_right.visible = not at_end)
	add_child(_carousel)
	_left = _round_button("chevron_left")
	_left.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_left.offset_left = 18
	_left.offset_right = 18 + 76
	_left.offset_top = -10
	_left.offset_bottom = 66
	_left.pressed.connect(_carousel.page.bind(-1))
	add_child(_left)
	_right = _round_button("chevron_right")
	_right.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_right.offset_left = -18 - 76
	_right.offset_right = -18
	_right.offset_top = -10
	_right.offset_bottom = 66
	_right.pressed.connect(_carousel.page.bind(1))
	add_child(_right)


func _round_button(icon_name: String) -> Button:
	var button := Ui.button("", icon_name, &"SoftButton")
	button.custom_minimum_size = Vector2(76, 76)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size = Vector2(76, 76)
	return button


func _build_empty_state() -> void:
	_empty = Control.new()
	_empty.set_anchors_preset(Control.PRESET_FULL_RECT)
	_empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_empty.visible = false
	var quwi: Node2D = QUWI.instantiate()
	quwi.name = "Quwi"
	_empty.add_child(quwi)
	var bubble := PanelContainer.new()
	bubble.name = "Bubble"
	bubble.theme_type_variation = &"BubblePanel"
	var text := Ui.label("", &"ReadingLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 440)
	text.name = "Text"
	bubble.add_child(text)
	_empty.add_child(bubble)
	add_child(_empty)


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.color = Color(0.13, 0.1, 0.09, 0.62)
	_veil.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed and _lock_left <= 0.0 and not _busy:
			_close_pin())
	_overlay.add_child(_veil)
	_big_rug = WovenRug.new()
	_big_rug.radius = Vector2(150, 34)
	_overlay.add_child(_big_rug)

	_pin_card = PanelContainer.new()
	_pin_card.theme_type_variation = &"CardPanel"
	_pin_card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_pin_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_pin_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pin_card.offset_right = -44
	var columns := Ui.hbox(34)
	var info := Ui.vbox(10)
	info.custom_minimum_size.x = 330
	_greeting = Ui.label("", &"TitleLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 330)
	_greeting.add_theme_font_size_override("font_size", 40)
	_prompt = Ui.label("", &"HeadingLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 330)
	_prompt.add_theme_font_size_override("font_size", 26)
	_quipu = QuipuPin.new()
	_quipu.slots = 4
	_feedback_title = Ui.label("", &"ErrorLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 330)
	_feedback_title.add_theme_font_size_override("font_size", 26)
	_feedback_text = Ui.label("", &"HintLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 330)
	_not_me = Ui.button("", "back", &"SoftButton")
	_not_me.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_not_me.pressed.connect(_close_pin)
	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for child: Control in [_greeting, _prompt, _quipu, _feedback_title, _feedback_text, grow, _not_me]:
		info.add_child(child)
	_pad = PinPad.new()
	_pad.max_length = 4
	_pad.min_length = 4
	_pad.auto_submit = true
	_pad.changed.connect(_quipu.set_filled)
	_pad.submitted.connect(_on_pin_submitted)
	columns.add_child(info)
	columns.add_child(_pad)
	_pin_card.add_child(columns)
	_overlay.add_child(_pin_card)


# --- Secciones y tarjetas ---

func _show_section(section_id: String) -> void:
	_cards = _presenter.students(section_id)
	_carousel.clear()
	for i in _cards.size():
		var card := StudentCard.new()
		card.setup(_cards[i], i)
		_carousel.add_item(card)
	_empty.visible = _cards.is_empty()
	_carousel.visible = not _cards.is_empty()
	_hint.visible = not _cards.is_empty()
	if _cards.is_empty():
		_place_empty_state()
	else:
		_animate_cards_in()


func _place_empty_state() -> void:
	var quwi: QuwiCharacter = _empty.get_node("Quwi")
	var bubble: PanelContainer = _empty.get_node("Bubble")
	(bubble.get_node("Text") as Label).text = _view_model.empty_message if _view_model else ""
	var view := get_viewport_rect().size
	quwi.position = Vector2(view.x * 0.5 - 300, view.y - 120)
	quwi.scale = Vector2(0.9, 0.9)
	quwi.set_mood(&"think")
	bubble.position = Vector2(view.x * 0.5 - 170, view.y * 0.5 - 120)
	Ui.pop_in(bubble, 0.2)


func _animate_cards_in() -> void:
	var items := _carousel.items()
	for i in items.size():
		var card := items[i] as Control
		card.modulate.a = 0.0
		var tween := card.create_tween()
		tween.tween_interval(0.05 + i * 0.06)
		tween.tween_property(card, "modulate:a", 1.0, 0.25)
		tween.tween_callback(func() -> void:
			if is_instance_valid(card):
				(card as StudentCard).avatar.hop(16.0))


func _on_card_tapped(index: int) -> void:
	if _busy or index < 0 or index >= _cards.size() or _overlay.visible:
		return
	_selected = _cards[index]
	_selected_card = _carousel.items()[index] as StudentCard
	_selected_card.react()
	_selected_card.set_highlight(true)
	_busy = true
	var later := create_tween()
	later.tween_interval(0.35)
	later.tween_callback(_open_pin)


# --- PIN ---

func _open_pin() -> void:
	var view := get_viewport_rect().size
	_overlay.visible = true
	_overlay.modulate.a = 0.0
	_greeting.text = _presenter.greeting(_selected)
	_prompt.text = _view_model.pin_prompt
	_feedback_title.text = ""
	_feedback_text.text = ""
	_not_me.visible = true
	_pad.clear()
	_pad.set_enabled(true)
	_quipu.set_filled(0)
	_pin_card.reset_size()
	if _big_avatar:
		_big_avatar.queue_free()
	_big_avatar = AVATAR.instantiate()
	_overlay.add_child(_big_avatar)
	_overlay.move_child(_big_avatar, _big_rug.get_index() + 1)
	_big_avatar.apply(_selected.look)
	_big_avatar.shadow_scale = 0.0
	var target := Vector2(maxf(view.x - 44 - _pin_card.get_combined_minimum_size().x, 600.0) * 0.5, view.y - 150)
	_big_rug.position = target
	_big_avatar.global_position = _selected_card.feet_global()
	_big_avatar.scale = Vector2.ONE * StudentCard.AVATAR_SCALE
	_selected_card.visible = false
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.25)
	tween.tween_property(_big_avatar, "position", target, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_big_avatar, "scale", Vector2.ONE * BIG_AVATAR_SCALE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_big_rug.scale = Vector2.ZERO
	tween.tween_property(_big_rug, "scale", Vector2.ONE, 0.45).set_delay(0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pin_card.modulate.a = 0.0
	_pin_card.position.x += 80
	tween.tween_property(_pin_card, "modulate:a", 1.0, 0.3).set_delay(0.12)
	tween.tween_property(_pin_card, "position:x", _pin_card.position.x - 80, 0.4).set_delay(0.12).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void:
		_busy = false
		_big_avatar.wave())
	if _selected.locked:
		_on_pin_submitted("")


func _close_pin() -> void:
	if not _overlay.visible:
		return
	_busy = true
	_lock_left = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_overlay, "modulate:a", 0.0, 0.25)
	if _big_avatar:
		tween.tween_property(_big_avatar, "global_position", _selected_card.feet_global(), 0.3).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(_big_avatar, "scale", Vector2.ONE * StudentCard.AVATAR_SCALE, 0.3)
	tween.chain().tween_callback(func() -> void:
		_overlay.visible = false
		_selected_card.visible = true
		_selected_card.set_highlight(false)
		_busy = false)


func _on_pin_submitted(pin: String) -> void:
	var feedback := _presenter.login(_selected.id, pin)
	if feedback.ok:
		_busy = true
		_pad.set_enabled(false)
		_quipu.shine()
		_big_avatar.celebrate()
		_greeting.text = feedback.title
		_prompt.text = ""
		_feedback_title.text = ""
		_feedback_text.text = ""
		_not_me.visible = false
		var later := create_tween()
		later.tween_interval(1.7)
		later.tween_callback(func() -> void: logged_in.emit(not feedback.has_avatar))
		return
	_feedback_title.text = feedback.title
	_feedback_text.text = feedback.message
	if pin.length() > 0:
		_quipu.shake_and_drop()
		_big_avatar.shake_head()
	_pad.clear()
	if feedback.locked:
		_pad.set_enabled(false)
		_lock_left = feedback.locked_seconds
		_last_lock_second = -1

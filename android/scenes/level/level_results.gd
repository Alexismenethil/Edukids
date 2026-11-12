class_name LevelResults
extends Control
## Resultados del nivel: las estrellas aparecen una por una, el quipu del nivel queda completo
## y el guía comenta. Botones «Otra vez» y «Seguir».

signal replay_requested
signal continue_requested

var _result: LevelResultViewModel
var _stars: Array[StarShape] = []
var _card: PanelContainer


func _init(result: LevelResultViewModel = null) -> void:
	_result = result


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color(0.16, 0.13, 0.12, 0.38)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	_card.custom_minimum_size.x = 720
	add_child(_card)
	var box := Ui.vbox(6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(box)
	var emblem := _emblem()
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(emblem)
	var heading := Ui.label(_result.heading, &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	heading.add_theme_font_size_override("font_size", 40)
	box.add_child(heading)
	if not _result.title.is_empty():
		box.add_child(Ui.label(_result.title, &"HintLabel", HORIZONTAL_ALIGNMENT_CENTER))
	var row := Ui.hbox(18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for index in 3:
		var star := StarShape.new(92.0 if index == 1 else 78.0)
		star.size_flags_vertical = Control.SIZE_SHRINK_END if index != 1 else Control.SIZE_SHRINK_BEGIN
		star.modulate.a = 0.0
		row.add_child(star)
		_stars.append(star)
	box.add_child(row)
	if _result.new_record:
		var ribbon := PanelContainer.new()
		ribbon.theme_type_variation = &"RibbonPanel"
		ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var record := Ui.label(_result.record_label, &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER)
		record.add_theme_font_size_override("font_size", 28)
		ribbon.add_child(record)
		box.add_child(ribbon)
		Ui.pop_in(ribbon, 1.6)
	var quipu := QuipuProgress.new()
	quipu.accent = _result.area.deep
	quipu.set_states(_result.progress)
	quipu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(quipu)
	for line in _result.lines:
		var label := Ui.label(line, &"", HORIZONTAL_ALIGNMENT_CENTER)
		label.add_theme_font_size_override("font_size", 23)
		box.add_child(label)
	if not _result.guide_line.is_empty():
		box.add_child(_guide_quote())
	if not _result.warning.is_empty():
		box.add_child(Ui.label(_result.warning, &"ErrorLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 600))
	box.add_child(Ui.spacer())
	var replay := Ui.button(_result.replay_label, "replay", &"SoftButton")
	replay.pressed.connect(func() -> void: replay_requested.emit())
	var go_on := Ui.button(_result.continue_label, "play")
	go_on.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	go_on.pressed.connect(func() -> void: continue_requested.emit())
	var buttons := Ui.hbox(20, [replay, go_on])
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(buttons)
	_layout.call_deferred()
	resized.connect(_layout)
	Ui.pop_in(_card, 0.05)
	_reveal_stars()


func _layout() -> void:
	_card.reset_size()
	var card_size := _card.get_combined_minimum_size()
	_card.size = card_size
	_card.position = Vector2((size.x - card_size.x) * 0.5 + 90.0, (size.y - card_size.y) * 0.5)
	_card.pivot_offset = card_size * 0.5


func _reveal_stars() -> void:
	for index in _stars.size():
		var star := _stars[index]
		star.earned = index < _result.stars
		var tween := create_tween()
		tween.tween_interval(0.55 + index * 0.38)
		tween.tween_callback(func() -> void:
			star.pivot_offset = star.size * 0.5
			star.scale = Vector2(0.3, 0.3)
			star.rotation = -0.6)
		tween.tween_property(star, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(star, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(star, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if star.earned:
			tween.tween_property(star, "shine", 1.0, 0.15)
			tween.tween_property(star, "shine", 0.0, 0.6)


## La frase del guía, como una nota tejida debajo de los aciertos.
func _guide_quote() -> Control:
	var note := PanelContainer.new()
	note.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := ActivityStyle.box(Color("#FFF4DC"), Color("#E9C987"), 4, 18, 2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	note.add_theme_stylebox_override("panel", style)
	var row := Ui.hbox(10)
	var name := ActivityStyle.label("Quwi:", 22, Color("#C2185B"), false)
	name.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	row.add_child(name)
	row.add_child(ActivityStyle.label(_result.guide_line, 22, ActivityStyle.BROWN, true, 500))
	note.add_child(row)
	Ui.pop_in(note, 1.9)
	return note


func _emblem() -> Control:
	var circle := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _result.area.deep
	style.border_color = _result.area.color
	style.set_border_width_all(6)
	style.set_corner_radius_all(40)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	circle.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.texture = Ui.icon(_result.area.icon)
	icon.custom_minimum_size = Vector2(52, 52)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	circle.add_child(icon)
	return circle

class_name FinalCover
extends Control
## Portada del desafío final: el área, cuántas preguntas tiene, qué intento es y sus reglas
## (sin vidas, sin pistas y con la calificación al entregar). «¡Comenzar!» la cierra.

signal started

var _cover: FinalCoverViewModel
var _card: PanelContainer


func _init(cover: FinalCoverViewModel = null) -> void:
	_cover = cover


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color(0.16, 0.13, 0.12, 0.45)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	_card.custom_minimum_size.x = 640
	add_child(_card)
	var column := Ui.vbox(14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(column)
	var ribbon := PanelContainer.new()
	ribbon.theme_type_variation = &"RibbonPanel"
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var heading := Ui.label(_cover.heading, &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER)
	heading.add_theme_font_size_override("font_size", 34)
	ribbon.add_child(heading)
	column.add_child(ribbon)
	var title := Ui.label(_cover.title, &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER, true, 560)
	title.add_theme_font_size_override("font_size", 36)
	column.add_child(title)
	var facts := Ui.hbox(14)
	facts.alignment = BoxContainer.ALIGNMENT_CENTER
	facts.add_child(_pill(_cover.area.name, _cover.area.deep))
	facts.add_child(_pill(_cover.details, ActivityStyle.BROWN))
	facts.add_child(_pill(_cover.attempt_label, Color("#C99A1E")))
	column.add_child(facts)
	var rules := Ui.vbox(10)
	rules.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for rule in _cover.rules:
		var line := Ui.hbox(12)
		var icon := TextureRect.new()
		icon.texture = Ui.icon("check")
		icon.custom_minimum_size = Vector2(30, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = _cover.area.deep
		line.add_child(icon)
		line.add_child(ActivityStyle.label(rule, 23, ActivityStyle.INK, true, 480))
		rules.add_child(line)
	column.add_child(rules)
	var go := Ui.button(_cover.start_label, "play")
	go.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.custom_minimum_size = Vector2(280, 72)
	go.pressed.connect(_start)
	column.add_child(go)
	_layout.call_deferred()
	resized.connect(_layout)
	Ui.pop_in(_card, 0.1)


func _layout() -> void:
	_card.reset_size()
	var card_size := _card.get_combined_minimum_size()
	_card.size = card_size
	_card.position = Vector2((size.x - card_size.x) * 0.5 + 90.0, (size.y - card_size.y) * 0.5)
	_card.pivot_offset = card_size * 0.5


func press_start() -> void:
	_start()


func _start() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		started.emit()
		queue_free())


func _pill(text: String, color: Color) -> Control:
	var pill := PanelContainer.new()
	var style := ActivityStyle.box(color, color.darkened(0.25), 3, 18, 0)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 4
	style.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", style)
	pill.add_child(ActivityStyle.label(text, 20, Color.WHITE, false))
	return pill

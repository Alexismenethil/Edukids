class_name LevelPreview
extends Control
## Ficha de un nivel antes de jugar: su mecánica con un dibujo, de qué se trata, cuántas
## preguntas y vidas tiene, las estrellas logradas y «¡Jugar!». Si está cerrado, dice qué falta.

signal play_requested
signal closed

var _node: TrailNodeViewModel
var _area: AreaViewModel
var _card: PanelContainer
var _play: Button


func _init(node: TrailNodeViewModel = null, area: AreaViewModel = null) -> void:
	_node = node
	_area = area


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color(0.16, 0.13, 0.12, 0.45)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close())
	add_child(veil)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	_card.custom_minimum_size.x = 600
	add_child(_card)
	var column := Ui.vbox(12)
	_card.add_child(column)
	var head := Ui.hbox(16)
	var medal := _Medal.new()
	medal.icon = Ui.icon(_node.icon)
	medal.color = Color("#B9AE9C") if not _node.playable else (_area.deep if not _node.final else Color("#C99A1E"))
	medal.custom_minimum_size = Vector2(96, 96)
	head.add_child(medal)
	var titles := Ui.vbox(2)
	var mechanic := ActivityStyle.label(_node.mechanic_name.to_upper(), 18, _area.deep, false)
	mechanic.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	titles.add_child(mechanic)
	var title := Ui.label(_node.title, &"TitleLabel", HORIZONTAL_ALIGNMENT_LEFT, true, 440)
	title.add_theme_font_size_override("font_size", 32)
	titles.add_child(title)
	titles.add_child(ActivityStyle.label(_node.details, 20, ActivityStyle.MUTED, false))
	head.add_child(titles)
	column.add_child(head)
	column.add_child(ActivityStyle.label(_node.mechanic_about, 23, ActivityStyle.INK, true, 540))
	if _node.final:
		if not _node.grade.is_empty():
			column.add_child(ActivityStyle.label("Tu mejor calificación: %s" % _node.grade, 22, _node.grade_color.darkened(0.2), false))
		column.add_child(ActivityStyle.label(_node.attempts_text, 20, ActivityStyle.BROWN, true, 540))
	else:
		var stars := Ui.hbox(10)
		for i in 3:
			var star := StarShape.new(40.0)
			star.earned = i < _node.stars
			stars.add_child(star)
		if not _node.badge.is_empty():
			stars.add_child(ActivityStyle.label("  " + _node.badge, 20, Color("#B47E14"), false))
		column.add_child(stars)
	if not _node.locked_text.is_empty():
		var locked := Ui.hbox(10)
		var icon := TextureRect.new()
		icon.texture = Ui.icon("lock")
		icon.modulate = ActivityStyle.BROWN
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		locked.add_child(icon)
		locked.add_child(ActivityStyle.label(_node.locked_text, 21, ActivityStyle.BROWN, true, 500))
		column.add_child(locked)
	var buttons := Ui.hbox(16)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	var close := Ui.button("Cerrar", "", &"SoftButton")
	close.pressed.connect(_close)
	buttons.add_child(close)
	_play = Ui.button(_node.action_label, "play")
	_play.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_play.custom_minimum_size = Vector2(220, 70)
	_play.disabled = not _node.playable
	_play.pressed.connect(func() -> void: play_requested.emit())
	buttons.add_child(_play)
	column.add_child(buttons)
	_layout.call_deferred()
	Ui.pop_in(_card, 0.0)
	if _node.playable:
		_play.pivot_offset = _play.custom_minimum_size * 0.5
		var pulse := create_tween().set_loops()
		pulse.tween_property(_play, "scale", Vector2(1.05, 1.05), 0.5).set_trans(Tween.TRANS_SINE)
		pulse.tween_property(_play, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)


func _layout() -> void:
	_card.reset_size()
	var card_size := _card.get_combined_minimum_size()
	_card.size = card_size
	_card.position = (size - card_size) * 0.5
	_card.pivot_offset = card_size * 0.5


func press_play() -> void:
	if not _play.disabled:
		play_requested.emit()


func _close() -> void:
	closed.emit()
	queue_free()


class _Medal:
	extends Control
	var icon: Texture2D
	var color := Color.WHITE

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5
		draw_circle(center + Vector2(0, 4), radius - 2.0, Color(0.2, 0.12, 0.05, 0.25))
		draw_circle(center, radius - 2.0, Color("#5A2E16"))
		draw_circle(center, radius - 6.0, color)
		if icon:
			draw_texture_rect(icon, Rect2(center - Vector2(radius, radius) * 0.55, Vector2(radius, radius) * 1.1), false)

class_name LevelCard
extends TapCard
## Tarjeta de un nivel en el inicio del estudiante: emblema del área, título, estrellas ganadas
## y el botón «Jugar» (o «Seguir» si lo dejó a medias). Toda la tarjeta se puede tocar.

var _model: LevelCardViewModel


func _init(model: LevelCardViewModel = null) -> void:
	_model = model


func _ready() -> void:
	accent = _model.area.deep
	border_override = _model.area.color
	radius = 26
	depth = 9
	custom_minimum_size = Vector2(560, 132)
	super._ready()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.add_child(_emblem())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := ActivityStyle.label(_model.title, 26, ActivityStyle.INK, false)
	title.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	heading.add_child(title)
	if not _model.badge.is_empty():
		heading.add_child(_badge(_model.badge))
	column.add_child(heading)
	column.add_child(ActivityStyle.label(_model.details, 20, ActivityStyle.MUTED, false))
	var stars := HBoxContainer.new()
	stars.add_theme_constant_override("separation", 4)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in 3:
		var star := StarShape.new(32.0)
		star.earned = index < _model.stars
		stars.add_child(star)
	column.add_child(stars)
	row.add_child(_action())


func _emblem() -> Control:
	var circle := PanelContainer.new()
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = _model.area.deep
	style.border_color = _model.area.color
	style.set_border_width_all(5)
	style.set_corner_radius_all(42)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	circle.add_theme_stylebox_override("panel", style)
	var icon := TextureRect.new()
	icon.texture = Ui.icon(_model.area.icon)
	icon.custom_minimum_size = Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(icon)
	return circle


func _badge(text: String) -> Control:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := ActivityStyle.box(Color("#FFF1C9"), Color("#E0A526"), 3, 14, 2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 0
	style.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", style)
	pill.add_child(ActivityStyle.label(text, 18, ActivityStyle.BROWN, false))
	return pill


## Botón dibujado (la tarjeta entera responde al toque).
func _action() -> Control:
	var button := PanelContainer.new()
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := ActivityStyle.box(_model.area.deep, _model.area.deep.darkened(0.3), 7, 28, 3)
	style.content_margin_left = 20
	style.content_margin_right = 16
	button.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := ActivityStyle.label(_model.action_label, 24, Color.WHITE, false)
	text.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	row.add_child(text)
	var icon := TextureRect.new()
	icon.texture = Ui.icon("play")
	icon.custom_minimum_size = Vector2(26, 26)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	button.add_child(row)
	return button

class_name ReadingPanel
extends PanelContainer
## Estímulo de una unidad de lectura: el texto, la tabla o la imagen quedan siempre a la vista
## mientras se responde (RF-28 y RN-17), con letra grande y líneas cortas.

const WIDTH := 410.0
## Las tablas necesitan un poco más de ancho.
const TABLE_WIDTH := 470.0
const CELL_FONT := 18

var _unit := {}
var _width := WIDTH
var _accent := ActivityStyle.PRIMARY
var _area_icon := ""


func _init(unit: Dictionary = {}, area: AreaViewModel = null) -> void:
	_unit = unit
	if area:
		_accent = area.deep
		_area_icon = area.icon
	_width = TABLE_WIDTH if str(unit.get("type", "")) == "table" else WIDTH
	custom_minimum_size.x = _width
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func _ready() -> void:
	var style := ActivityStyle.box(Color("#FFFBF2"), ActivityStyle.LINE, 4, 22)
	style.content_margin_left = 26
	style.content_margin_right = 14
	style.content_margin_top = 16
	style.content_margin_bottom = 12
	add_theme_stylebox_override("panel", style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	column.add_child(_eyebrow())
	var title := str(_unit.get("title", ""))
	if not title.is_empty():
		var heading := ActivityStyle.label(title, 24, ActivityStyle.BROWN, true, _width - 70)
		heading.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
		column.add_child(heading)
	match str(_unit.get("type", "text")):
		"table":
			column.add_child(_table())
			var note := str(_unit.get("note", ""))
			if not note.is_empty():
				var note_box := PanelContainer.new()
				var note_style := ActivityStyle.box(_accent.lerp(Color.WHITE, 0.92), Color.TRANSPARENT, 0, 14, 0)
				note_style.content_margin_left = 12
				note_style.content_margin_right = 12
				note_style.content_margin_top = 6
				note_style.content_margin_bottom = 6
				note_box.add_theme_stylebox_override("panel", note_style)
				note_box.add_child(ActivityStyle.label(note, 18, ActivityStyle.INK, true, _width - 100))
				column.add_child(note_box)
		"image":
			var picture := TextureRect.new()
			picture.texture = load(str(_unit.get("file", ""))) if ResourceLoader.exists(str(_unit.get("file", ""))) else null
			picture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			column.add_child(picture)
		_:
			for paragraph: String in _unit.get("paragraphs", []):
				var text := Label.new()
				text.text = paragraph
				text.theme_type_variation = &"ReadingLabel"
				text.add_theme_font_size_override("font_size", 24)
				text.add_theme_constant_override("line_spacing", 4)
				text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				text.custom_minimum_size.x = _width - 70
				column.add_child(text)


func _eyebrow() -> Control:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var style := ActivityStyle.box(_accent, _accent, 0, 14, 0)
	style.content_margin_left = 10
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if not _area_icon.is_empty():
		var icon := TextureRect.new()
		icon.texture = Ui.icon(_area_icon)
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var label := "OBSERVA LOS DATOS" if str(_unit.get("type", "")) == "table" else "LECTURA"
	row.add_child(ActivityStyle.label(label, 16, Color.WHITE, false))
	pill.add_child(row)
	return pill


func _table() -> Control:
	var columns: Array = _unit.get("columns", [])
	var grid := GridContainer.new()
	grid.columns = columns.size()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	for header: String in columns:
		grid.add_child(_cell(header, true))
	for row: Array in _unit.get("rows", []):
		for cell: String in row:
			grid.add_child(_cell(cell, false))
	return grid


func _cell(text: String, header: bool) -> Control:
	var cell := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = _accent if header else Color("#FFF1DA")
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	cell.add_theme_stylebox_override("panel", style)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not header and _is_fraction(text):
		cell.add_child(_fraction(text))
		return cell
	var label := ActivityStyle.label(text, CELL_FONT, Color.WHITE if header else ActivityStyle.INK, false)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Se parte solo entre palabras: la columna mide al menos su palabra más larga.
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size.x = _longest_word(text)
	cell.add_child(label)
	return cell


func _is_fraction(text: String) -> bool:
	var parts := text.strip_edges().split("/")
	return parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int() and parts[1].to_int() > 0


func _fraction(text: String) -> Control:
	var parts := text.strip_edges().split("/")
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_theme_constant_override("separation", 0)
	var numerator := ActivityStyle.label(parts[0], CELL_FONT, ActivityStyle.INK, false)
	numerator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(numerator)
	var line := ColorRect.new()
	line.color = ActivityStyle.INK
	line.custom_minimum_size = Vector2(25, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(line)
	var denominator := ActivityStyle.label(parts[1], CELL_FONT, ActivityStyle.INK, false)
	denominator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(denominator)
	return stack


func _longest_word(text: String) -> float:
	var font := get_theme_default_font()
	var widest := 28.0
	for word in text.split(" ", false):
		widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, CELL_FONT).x + 4.0)
	return widest

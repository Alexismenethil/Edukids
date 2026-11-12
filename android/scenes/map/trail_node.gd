class_name TrailNode
extends Control
## Un nudo del sendero: el nivel con el icono de su mecánica. Abierto, toma el color del área;
## completado, muestra sus estrellas (o la calificación en el desafío final); cerrado, queda gris
## con candado. El siguiente sugerido late y tiene una flecha.

signal tapped

const SIZE := 88.0
const FINAL_SIZE := 108.0

var _model: TrailNodeViewModel
var _area: AreaViewModel
var _number := 1
var _icon: Texture2D
var _time := 0.0


func _init(model: TrailNodeViewModel = null, area: AreaViewModel = null, number: int = 1) -> void:
	_model = model
	_area = area
	_number = number
	var side := FINAL_SIZE if model and model.final else SIZE
	custom_minimum_size = Vector2(side, side + 30.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	if model:
		_icon = Ui.icon(model.icon)


func model() -> TrailNodeViewModel:
	return _model


func area() -> AreaViewModel:
	return _area


func _ready() -> void:
	pivot_offset = Vector2(size.x * 0.5, size.x * 0.5)
	_time = randf() * TAU


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) \
			or (event is InputEventScreenTouch and not event.pressed):
		ActivityStyle.pop(self, 0.12)
		tapped.emit()
		accept_event()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var side := size.x
	var center := Vector2(side * 0.5, side * 0.5)
	var radius := side * 0.5 - 4.0
	var locked := _model.state == &"locked"
	var done := _model.state == &"done"
	var fill := _area.color
	if locked:
		fill = Color("#B9AE9C")
	elif done:
		fill = _area.deep
	if _model.next:
		var glow := 0.3 + 0.2 * sin(_time * 4.0)
		draw_circle(center, radius + 12.0 + 3.0 * sin(_time * 4.0), Color(1.0, 0.9, 0.5, glow))
	draw_circle(center + Vector2(0, 5), radius, Color(0.2, 0.12, 0.05, 0.28))
	var ring := Color("#F2C14E") if _model.final else Color("#5A2E16")
	draw_circle(center, radius, Color("#5A2E16"))
	draw_circle(center, radius - 3.0, ring if _model.final else Color("#5A2E16"))
	draw_circle(center, radius - (9.0 if _model.final else 4.0), fill)
	draw_arc(center, radius - 13.0, PI * 1.1, PI * 1.85, 16, Color(1, 1, 1, 0.35), 4.0, true)
	if _icon:
		var icon_side := side * 0.5
		var tint := Color(1, 1, 1, 0.75) if locked else Color.WHITE
		draw_texture_rect(_icon, Rect2(center - Vector2(icon_side, icon_side) * 0.5, Vector2(icon_side, icon_side)), false, tint)
	if locked:
		var lock := Ui.icon("lock")
		var at := center + Vector2(radius * 0.55, radius * 0.55)
		draw_circle(at, 16.0, Color("#5A2E16"))
		draw_circle(at, 13.5, Color("#8C8079"))
		draw_texture_rect(lock, Rect2(at - Vector2(10, 10), Vector2(20, 20)), false)
	else:
		# Número del nivel en una bolita.
		var tag := center + Vector2(-radius * 0.68, -radius * 0.68)
		draw_circle(tag, 14.0, Color("#5A2E16"))
		draw_circle(tag, 11.5, Color("#FFF8EC"))
		var font := ThemeDB.get_project_theme().get_font("font", &"Button")
		var text := str(_number) if not _model.final else "★"
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		draw_string(font, tag + Vector2(-text_size.x * 0.5, 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#5A2E16"))
	var bottom := side + 2.0
	if _model.final and not _model.grade.is_empty():
		_draw_grade(Vector2(center.x, bottom + 12.0))
	elif not _model.final and (done or _model.stars > 0):
		for i in 3:
			_draw_star(Vector2(center.x - 24.0 + i * 24.0, bottom + 12.0 - (4.0 if i == 1 else 0.0)), 10.5, i < _model.stars)
	if not _model.badge.is_empty():
		var font := ThemeDB.get_project_theme().get_font("font", &"Button")
		var text_size := font.get_string_size(_model.badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		var rect := Rect2(Vector2(center.x - text_size.x * 0.5 - 8.0, -6.0), Vector2(text_size.x + 16.0, 22.0))
		var pill := StyleBoxFlat.new()
		pill.bg_color = Color("#E0A526")
		pill.set_corner_radius_all(11)
		draw_style_box(pill, rect)
		draw_string(font, rect.position + Vector2(8.0, 16.0), _model.badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	if _model.next:
		var bounce := absf(sin(_time * 4.0)) * 8.0
		var tip := Vector2(center.x, -10.0 - bounce)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-11, -14), tip + Vector2(11, -14)]), Color("#C2185B"))


func _draw_star(at: Vector2, radius: float, earned: bool) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + PI * i / 5.0
		var r := radius if i % 2 == 0 else radius * 0.45
		points.append(at + Vector2.from_angle(angle) * r)
	draw_colored_polygon(points, Color("#F2C14E") if earned else Color("#E3DCD3"))
	points.append(points[0])
	draw_polyline(points, Color("#B47E14") if earned else Color("#B9AE9C"), 2.0, true)


func _draw_grade(at: Vector2) -> void:
	var color := _model.grade_color
	draw_circle(at, 15.0, Color("#5A2E16"))
	draw_circle(at, 13.0, color)
	var font := ThemeDB.get_project_theme().get_font("font", &"Button")
	var text_size := font.get_string_size(_model.grade, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	draw_string(font, at + Vector2(-text_size.x * 0.5, 5.5), _model.grade, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

class_name StopScreen
extends Control
## Una parada del mapa (Huamanga): la plaza arriba y, abajo, un sendero por área. Cada sendero es
## una cuerda del quipu con un nudo por nivel: los de práctica en orden y el desafío final al
## final. Al tocar un nudo se abre su ficha con «¡Jugar!» (RN-18 y RF-22).

signal level_requested
signal back_requested

const PLAZA := preload("res://assets/art/backgrounds/huamanga/bg_huamanga_plaza.svg")
const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")
const BUBBLE := preload("res://scenes/ui/components/speech_bubble.tscn")
const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const ROW_TOP := 352.0
const ROW_HEIGHT := 142.0

var _presenter: MapPresenter
var _model: StopViewModel
var _quwi: QuwiCharacter
var _bubble: SpeechBubble
var _preview: LevelPreview
var _nodes: Array[TrailNode] = []
var _avatar: AvatarCharacter


func setup(presenter: MapPresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_model = _presenter.stop()
	var floor := _PlazaFloor.new()
	add_child(floor)
	var plaza := TextureRect.new()
	plaza.texture = PLAZA
	plaza.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plaza.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	plaza.set_anchors_preset(Control.PRESET_TOP_WIDE)
	plaza.offset_bottom = 340.0
	plaza.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plaza)
	_build_header()
	for index in _model.trails.size():
		_build_trail(_model.trails[index], ROW_TOP + index * ROW_HEIGHT, index)
	_place_avatar()
	_quwi = QUWI.instantiate()
	_quwi.scale = Vector2(0.44, 0.44)
	_quwi.interactive = true
	add_child(_quwi)
	_bubble = BUBBLE.instantiate()
	add_child(_bubble)
	resized.connect(_place)
	_place()
	var later := create_tween()
	later.tween_interval(0.5)
	later.tween_callback(func() -> void:
		_quwi.enter_from(140.0, 2)
		if _model.guide:
			_quwi.talk(true)
			_bubble.play(_model.guide)
			_bubble.finished.connect(func() -> void: _quwi.talk(false), CONNECT_ONE_SHOT))


func _place() -> void:
	_quwi.position = Vector2(size.x - 120.0, 330.0)
	_bubble.position = Vector2(size.x - 172.0, 262.0)


func _build_header() -> void:
	var back := Ui.compact(Ui.button(_model.back_label, "back", &"SoftButton"), 24)
	back.position = Vector2(20, 18)
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)
	var title := PanelContainer.new()
	title.theme_type_variation = &"RibbonPanel"
	var column := Ui.vbox(0)
	var name := Ui.label(_model.name, &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER)
	name.add_theme_font_size_override("font_size", 38)
	column.add_child(name)
	title.add_child(column)
	add_child(title)
	title.reset_size()
	title.position = Vector2((1280.0 - title.size.x) * 0.5, 14.0)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -title.size.x * 0.5
	title.offset_right = title.size.x * 0.5
	title.offset_top = 14.0
	var about := ActivityStyle.label(_model.about, 20, ActivityStyle.BROWN, false)
	about.add_theme_color_override("font_outline_color", Color("#FFF8EC"))
	about.add_theme_constant_override("outline_size", 8)
	about.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	about.set_anchors_preset(Control.PRESET_CENTER_TOP)
	about.offset_left = -300.0
	about.offset_right = 300.0
	about.offset_top = 82.0
	add_child(about)
	var stars := PanelContainer.new()
	var style := ActivityStyle.box(Color("#FFF4DC"), Color("#E0A526"), 5, 26, 3)
	style.content_margin_left = 12
	style.content_margin_right = 18
	style.content_margin_top = 4
	style.content_margin_bottom = 6
	stars.add_theme_stylebox_override("panel", style)
	var row := Ui.hbox(8)
	var star := StarShape.new(32.0)
	star.earned = true
	row.add_child(star)
	row.add_child(ActivityStyle.label(_model.stars_label, 26, ActivityStyle.BROWN, false))
	stars.add_child(row)
	stars.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stars.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	stars.offset_right = -24.0
	stars.offset_top = 20.0
	add_child(stars)


func _build_trail(trail: TrailViewModel, top: float, row_index: int) -> void:
	var cord := _Cord.new()
	cord.color = trail.area.color
	cord.deep = trail.area.deep
	cord.position = Vector2(0, top)
	cord.size = Vector2(1280, ROW_HEIGHT)
	cord.set_anchors_preset(Control.PRESET_TOP_WIDE)
	cord.offset_top = top
	cord.offset_bottom = top + ROW_HEIGHT
	add_child(cord)
	var label := _trail_label(trail)
	label.position = Vector2(18, top + 26.0)
	add_child(label)
	var count := trail.nodes.size()
	var first_x := 330.0
	var last_x := 1210.0
	var spacing := minf(170.0, (last_x - first_x) / maxf(1.0, count - 1))
	var points: Array[Vector2] = []
	for index in count:
		var x := first_x + index * spacing
		var y := top + ROW_HEIGHT * 0.42 + sin(index * 1.3 + row_index) * 10.0
		points.append(Vector2(x, y))
		var node := TrailNode.new(trail.nodes[index], trail.area, index + 1)
		node.position = Vector2(x, y) - node.size * 0.5
		node.tapped.connect(_open_preview.bind(trail.nodes[index], trail.area))
		add_child(node)
		_nodes.append(node)
		Ui.pop_in(node, 0.15 + row_index * 0.12 + index * 0.06)
	cord.knots = points.map(func(point: Vector2) -> Vector2: return point - Vector2(0, top))


func _trail_label(trail: TrailViewModel) -> Control:
	var panel := PanelContainer.new()
	var style := ActivityStyle.box(Color("#FFF8EC"), trail.area.color, 6, 22, 3)
	style.content_margin_left = 10
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.x = 250
	var row := Ui.hbox(10)
	var emblem := PanelContainer.new()
	var circle := StyleBoxFlat.new()
	circle.bg_color = trail.area.deep
	circle.set_corner_radius_all(26)
	circle.content_margin_left = 8
	circle.content_margin_right = 8
	circle.content_margin_top = 8
	circle.content_margin_bottom = 8
	emblem.add_theme_stylebox_override("panel", circle)
	var icon := TextureRect.new()
	icon.texture = Ui.icon(trail.area.icon)
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.add_child(icon)
	row.add_child(emblem)
	var texts := Ui.vbox(0)
	var name := ActivityStyle.label(trail.area.name, 22 if trail.area.name.length() < 14 else 18, ActivityStyle.INK, false)
	name.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	texts.add_child(name)
	texts.add_child(ActivityStyle.label("★ " + trail.stars_label, 19, ActivityStyle.BROWN, false))
	row.add_child(texts)
	panel.add_child(row)
	return panel


## El avatar espera junto al siguiente nudo sugerido.
func _place_avatar() -> void:
	for node in _nodes:
		if node.model().next:
			_avatar = AVATAR.instantiate()
			_avatar.scale = Vector2(0.2, 0.2)
			_avatar.shadow_scale = 0.7
			_avatar.interactive = true
			add_child(_avatar)
			_avatar.apply(_model.look)
			_avatar.position = node.position + Vector2(node.size.x * 0.5 - 52.0, node.size.y * 0.5 + 34.0)
			return


func _open_preview(node: TrailNodeViewModel, area: AreaViewModel) -> void:
	if _preview:
		return
	if _bubble.is_open():
		_bubble.close()
	_preview = LevelPreview.new(node, area)
	_preview.closed.connect(func() -> void: _preview = null)
	_preview.play_requested.connect(func() -> void:
		if _presenter.choose(node):
			level_requested.emit())
	add_child(_preview)


## Para el modo demostración: abre la ficha del nivel indicado y juega.
func demo_open(level_id: String, package_id: String = "") -> void:
	for node in _nodes:
		var model := node.model()
		if model.level_id == level_id and (package_id.is_empty() or model.package_id == package_id):
			_open_preview(model, node.area())
			return


func demo_play() -> void:
	if _preview:
		_preview.press_play()


## Piso de la plaza: losetas cálidas debajo de la ilustración.
class _PlazaFloor:
	extends Control

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#F1E3C6"))
		var tile := 64.0
		var y := 330.0
		while y < size.y:
			var x := -fmod(y * 0.5, tile)
			while x < size.x:
				draw_rect(Rect2(x + 2, y + 2, tile - 4, tile - 4), Color("#EBD9B5"))
				x += tile
			y += tile
		draw_rect(Rect2(0, 336, size.x, 10), Color(0.35, 0.18, 0.09, 0.12))


## La cuerda del sendero: torcida en dos tonos del color del área, con ondas suaves.
class _Cord:
	extends Control
	var color := Color.WHITE
	var deep := Color.WHITE
	var knots: Array = []
	var _time := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		if knots.is_empty():
			return
		var start := Vector2(262, (knots[0] as Vector2).y)
		var points := PackedVector2Array([start])
		for knot: Vector2 in knots:
			points.append(knot)
		points.append(Vector2(size.x + 20.0, (knots[-1] as Vector2).y + 8.0))
		var curve := Curve2D.new()
		for index in points.size():
			var previous := points[maxi(0, index - 1)]
			var following := points[mini(points.size() - 1, index + 1)]
			var handle := (following - previous) * 0.25
			curve.add_point(points[index], -handle, handle)
		curve.bake_interval = 5.0
		var baked := curve.get_baked_points()
		var shadow := PackedVector2Array()
		for point in baked:
			shadow.append(point + Vector2(0, 5))
		draw_polyline(shadow, Color(0.25, 0.16, 0.08, 0.18), 16.0, true)
		draw_polyline(baked, deep, 14.0, true)
		draw_polyline(baked, color, 9.0, true)
		var length := curve.get_baked_length()
		var distance := 4.0
		while distance < length:
			var a := curve.sample_baked(distance)
			var b := curve.sample_baked(distance + 5.0)
			var normal := (b - a).normalized().orthogonal()
			draw_line(a - normal * 4.0, b + normal * 4.0, color.lightened(0.35), 2.0, true)
			distance += 11.0

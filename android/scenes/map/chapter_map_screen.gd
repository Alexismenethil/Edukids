class_name ChapterMapScreen
extends Control
## Mapa del capítulo de la Sierra: el Qhapaq Ñan une las cuatro paradas (Huamanga, Quinua,
## Pampa Galeras y Vilcashuamán). Las paradas sin contenido muestran un candado y «Tu docente lo
## abrirá pronto» (RN-01). Al tocar una parada abierta, el avatar salta y el mapa se acerca.

signal stop_requested(stop_id: String)
signal edit_avatar_requested
signal exit_requested

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")
const BUBBLE := preload("res://scenes/ui/components/speech_bubble.tscn")
const CONDOR := preload("res://assets/art/characters/condor/char_condor.svg")
## Lugares de las paradas sobre la pantalla base de 1280 × 800.
const SPOTS: Array[Vector2] = [Vector2(236, 604), Vector2(560, 420), Vector2(906, 512), Vector2(1110, 330)]
const START := Vector2(40, 760)

var _presenter: MapPresenter
var _model: ChapterMapViewModel
var _land: _Road
var _pins: Array[_StopPin] = []
var _avatar: AvatarCharacter
var _quwi: QuwiCharacter
var _bubble: SpeechBubble
var _leaving := false


func setup(presenter: MapPresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_model = _presenter.chapter()
	var backdrop := SierraBackdrop.new()
	backdrop.show_road = false
	add_child(backdrop)
	var condor := CondorFlight.new()
	condor.texture = CONDOR
	condor.scale = Vector2(0.42, 0.42)
	condor.altitude = 150.0
	condor.start_x = 1400.0
	condor.end_x = -160.0
	condor.crossing_time = 20.0
	add_child(condor)
	_land = _Road.new()
	_land.spots = SPOTS
	_land.start = START
	for stop in _model.stops:
		_land.open.append(stop.available)
	add_child(_land)
	for index in mini(_model.stops.size(), SPOTS.size()):
		var pin := _StopPin.new(_model.stops[index])
		pin.position = SPOTS[index] - Vector2(70, 70)
		pin.tapped.connect(_on_stop.bind(index))
		add_child(pin)
		_pins.append(pin)
		Ui.pop_in(pin, 0.25 + 0.12 * index)
	_avatar = AVATAR.instantiate()
	_avatar.scale = Vector2(0.27, 0.27)
	_avatar.apply(_model.look)
	_avatar.position = SPOTS[_model.current] + Vector2(-92, 64)
	_avatar.interactive = true
	add_child(_avatar)
	_build_header()
	_quwi = QUWI.instantiate()
	_quwi.scale = Vector2(0.5, 0.5)
	_quwi.interactive = true
	add_child(_quwi)
	_bubble = BUBBLE.instantiate()
	_bubble.flipped = true
	add_child(_bubble)
	resized.connect(_place)
	_place()
	var later := create_tween()
	later.tween_interval(0.7)
	later.tween_callback(func() -> void:
		_avatar.wave()
		_quwi.enter_from(-140.0, 2)
		var guide := DialogueViewModel.new()
		guide.lines.append(DialogueLineViewModel.new(PlayMessages.GUIDE, _model.guide_line, &"joy"))
		guide.close_label = "¡Vamos!"
		guide.skip_label = ""
		_quwi.talk(true)
		_bubble.play(guide)
		_bubble.finished.connect(func() -> void: _quwi.talk(false), CONNECT_ONE_SHOT))


## Quwi espera junto a Huamanga y su globo sale hacia la pradera, sin tapar las paradas.
func _place() -> void:
	_quwi.position = Vector2(372.0, size.y - 12.0)
	_bubble.position = Vector2(412.0, size.y - 110.0)


func _build_header() -> void:
	var bar := Ui.hbox(14)
	bar.position = Vector2(24, 18)
	bar.size = Vector2(1232, 72)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 24
	bar.offset_right = -24
	bar.offset_top = 16
	add_child(bar)
	var badge := AvatarBadge.new()
	badge.custom_minimum_size = Vector2(70, 70)
	bar.add_child(badge)
	badge.show_look(_model.look)
	var titles := Ui.vbox(0)
	var greeting := Ui.label(_model.greeting, &"TitleLabel")
	greeting.add_theme_font_size_override("font_size", 38)
	titles.add_child(greeting)
	var chapter := PanelContainer.new()
	chapter.theme_type_variation = &"RibbonPanel"
	chapter.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var chapter_label := Ui.label("%s · %s" % [_model.chapter_name, _model.chapter_title], &"BannerLabel")
	chapter_label.add_theme_font_size_override("font_size", 22)
	chapter.add_child(chapter_label)
	titles.add_child(chapter)
	bar.add_child(titles)
	bar.add_child(Ui.spacer())
	var stars := PanelContainer.new()
	var style := ActivityStyle.box(Color("#FFF4DC"), Color("#E0A526"), 5, 26, 3)
	style.content_margin_left = 12
	style.content_margin_right = 18
	style.content_margin_top = 4
	style.content_margin_bottom = 6
	stars.add_theme_stylebox_override("panel", style)
	var row := Ui.hbox(8)
	var star := StarShape.new(34.0)
	star.earned = true
	row.add_child(star)
	row.add_child(ActivityStyle.label(_model.stars_label, 28, ActivityStyle.BROWN, false))
	stars.add_child(row)
	stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(stars)
	var edit := Ui.compact(Ui.button(_model.edit_label, "edit", &"SoftButton"), 22)
	edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	edit.pressed.connect(func() -> void: edit_avatar_requested.emit())
	bar.add_child(edit)
	var exit := Ui.compact(Ui.button(_model.exit_label, "exit", &"SoftButton"), 22)
	exit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	exit.pressed.connect(func() -> void:
		_presenter.log_out()
		exit_requested.emit())
	bar.add_child(exit)


func _on_stop(index: int) -> void:
	if _leaving:
		return
	var stop := _model.stops[index]
	if not stop.available:
		_pins[index].wiggle()
		var locked := DialogueViewModel.new()
		locked.lines.append(DialogueLineViewModel.new(PlayMessages.GUIDE, "%s: %s" % [stop.name, stop.locked_text], &"think"))
		locked.close_label = "¡Bueno!"
		locked.skip_label = ""
		_quwi.set_mood(&"think")
		_quwi.talk(true)
		_bubble.play(locked)
		return
	_leaving = true
	if _bubble.is_open():
		_bubble.close()
	_quwi.set_mood(&"cheer")
	_quwi.hop(30.0)
	var target := SPOTS[index] + Vector2(-92, 64)
	var tween := create_tween()
	if _avatar.position.distance_to(target) > 10.0:
		_avatar.run_speed = 1.0
		tween.tween_property(_avatar, "position", target, 0.9).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func() -> void: _avatar.run_speed = 0.0)
	tween.tween_callback(_avatar.celebrate)
	tween.tween_interval(0.5)
	pivot_offset = SPOTS[index]
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: stop_requested.emit(stop.id))


## Para el modo demostración.
func demo_enter_stop(index: int = 0) -> void:
	_on_stop(index)


## Camino empedrado del Qhapaq Ñan entre las paradas, con el tramo cerrado punteado.
class _Road:
	extends Control
	var spots: Array[Vector2] = []
	var start := Vector2.ZERO
	var open: Array[bool] = []
	var _time := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var points: Array[Vector2] = [start]
		points.append_array(spots)
		var curve := Curve2D.new()
		for index in points.size():
			var previous := points[maxi(0, index - 1)]
			var following := points[mini(points.size() - 1, index + 1)]
			var handle := (following - previous) * 0.22
			curve.add_point(points[index], -handle, handle)
		curve.bake_interval = 6.0
		var baked := curve.get_baked_points()
		# Sombra, borde y empedrado.
		var shadow := PackedVector2Array()
		for point in baked:
			shadow.append(point + Vector2(0, 6))
		draw_polyline(shadow, Color(0.25, 0.16, 0.08, 0.22), 30.0, true)
		draw_polyline(baked, Color("#9C7A45"), 30.0, true)
		draw_polyline(baked, Color("#E9D3A3"), 22.0, true)
		var length := curve.get_baked_length()
		var step := 22.0
		var distance := 8.0
		var index_stone := 0
		while distance < length:
			var point := curve.sample_baked(distance)
			var segment := _segment_for(curve, distance)
			var locked := segment >= 0 and segment < open.size() and not open[segment]
			var color := Color("#C9A25F") if not locked else Color("#B9AE9C")
			draw_circle(point + Vector2(float(index_stone % 3) - 1.0, float(index_stone % 2) * 2.0 - 1.0), 4.5, color)
			distance += step
			index_stone += 1
		# Brillos que caminan por el camino abierto.
		var glow := fmod(_time * 120.0, length)
		var lit := curve.sample_baked(glow)
		if open.size() > 0 and open[0]:
			draw_circle(lit, 7.0, Color(1.0, 0.95, 0.7, 0.55))

	## Tramo del camino (antes de la parada n) para una distancia.
	func _segment_for(curve: Curve2D, distance: float) -> int:
		var cumulative := 0.0
		var previous := start
		for index in spots.size():
			cumulative += previous.distance_to(spots[index]) * 1.04
			if distance <= cumulative:
				return index
			previous = spots[index]
		return spots.size() - 1


## Medallón de una parada: la ilustración del lugar, su nombre en una cinta tejida y las
## estrellas. Con candado si el docente todavía no la abre.
class _StopPin:
	extends Control
	signal tapped
	var _model: StopPinViewModel
	var _time := 0.0
	var _illustration: Texture2D
	var _press := 0.0

	func _init(model: StopPinViewModel) -> void:
		_model = model
		custom_minimum_size = Vector2(140, 176)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		_illustration = load("res://assets/art/ui/ui_%s.svg" % model.icon) if ResourceLoader.exists("res://assets/art/ui/ui_%s.svg" % model.icon) else null

	func _ready() -> void:
		pivot_offset = Vector2(70, 70)
		var ribbon := PanelContainer.new()
		var style := ActivityStyle.box(Color("#C2185B") if _model.available else Color("#9C918A"), Color("#5A2E16"), 4, 14, 2)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 2
		style.content_margin_bottom = 4
		ribbon.add_theme_stylebox_override("panel", style)
		ribbon.add_child(ActivityStyle.label(_model.name, 22, Color.WHITE, false))
		ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(ribbon)
		ribbon.reset_size()
		ribbon.position = Vector2(70.0 - ribbon.size.x * 0.5, 128.0)
		if _model.available:
			var stars := ActivityStyle.label("★ " + _model.stars_label, 19, ActivityStyle.BROWN, false)
			stars.add_theme_color_override("font_outline_color", Color("#FFF8EC"))
			stars.add_theme_constant_override("outline_size", 6)
			stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(stars)
			stars.reset_size()
			stars.position = Vector2(70.0 - stars.size.x * 0.5, 160.0)
		else:
			var soon := ActivityStyle.label("Pronto", 18, ActivityStyle.MUTED, false)
			soon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(soon)
			soon.reset_size()
			soon.position = Vector2(70.0 - soon.size.x * 0.5, 160.0)

	func _gui_input(event: InputEvent) -> void:
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed) \
				or (event is InputEventScreenTouch and not event.pressed):
			ActivityStyle.pop(self, 0.12)
			tapped.emit()
			accept_event()

	func wiggle() -> void:
		var tween := create_tween()
		for i in 3:
			tween.tween_property(self, "rotation", 0.08, 0.06)
			tween.tween_property(self, "rotation", -0.08, 0.06)
		tween.tween_property(self, "rotation", 0.0, 0.06)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(70, 66)
		var available := _model.available
		if available:
			var glow := 0.25 + 0.15 * sin(_time * 3.0)
			draw_circle(center, 72.0, Color(1.0, 0.92, 0.6, glow))
		draw_circle(center + Vector2(0, 6), 62.0, Color(0.2, 0.12, 0.05, 0.25))
		draw_circle(center, 62.0, Color("#5A2E16"))
		draw_circle(center, 57.0, Color("#FFF8EC") if available else Color("#E3DCD3"))
		# Arcos de colores: un tramo por cada área con sendero en la parada.
		var colors := _model.colors
		for index in colors.size():
			var from := -PI * 0.5 + TAU * index / colors.size() + 0.08
			var to := -PI * 0.5 + TAU * (index + 1) / colors.size() - 0.08
			draw_arc(center, 52.0, from, to, 24, colors[index], 7.0, true)
		if _illustration:
			var tint := Color.WHITE if available else Color(0.62, 0.6, 0.58, 0.85)
			draw_texture_rect(_illustration, Rect2(center - Vector2(44, 44), Vector2(88, 88)), false, tint)
		if not available:
			var lock := Ui.icon("lock")
			draw_circle(center + Vector2(38, 38), 22.0, Color("#5A2E16"))
			draw_circle(center + Vector2(38, 38), 19.0, Color("#8C8079"))
			draw_texture_rect(lock, Rect2(center + Vector2(24, 24), Vector2(28, 28)), false)
		elif _model.cords > 0:
			for i in _model.cords:
				draw_circle(center + Vector2(-40 + i * 14, 50), 7.0, Color("#F2C14E"))

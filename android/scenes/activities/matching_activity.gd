class_name MatchingActivity
extends ActivityView
## Emparejar: dos columnas que se unen con cuerdas tejidas de colores, como los hilos de un quipu.
## Se toca un elemento de la izquierda y luego su pareja, o se tiende la cuerda con el dedo.
## Respuesta: diccionario id izquierdo → id derecho.

const GAP_RATIO := 0.2
const KNOT := 10.0

var _left_cards := {}
var _right_cards := {}
var _colors := {}
var _links := {}
var _selected := ""
var _dragging := ""
var _results := {}
var _layer: Control


func build() -> void:
	var columns := HBoxContainer.new()
	center(columns)
	add_child(columns)
	var left := _column()
	var right := _column()
	var gap := Control.new()
	gap.custom_minimum_size.x = 150
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columns.add_child(left)
	columns.add_child(gap)
	columns.add_child(right)
	var lefts: Array = step.data["left"]
	for index in lefts.size():
		var entry: Dictionary = lefts[index]
		var card := _card(entry["text"])
		_colors[entry["id"]] = ActivityStyle.THREADS[index % ActivityStyle.THREADS.size()]
		card.drag_data = {"match_left": entry["id"]}
		card.preview_builder = _knot_preview.bind(_colors[entry["id"]])
		card.drag_started.connect(func() -> void: _dragging = entry["id"])
		card.tapped.connect(_on_left.bind(entry["id"]))
		left.add_child(card)
		_left_cards[entry["id"]] = card
		Ui.pop_in(card, 0.05 * index)
	var rights: Array = step.data["right"]
	for index in rights.size():
		var entry: Dictionary = rights[index]
		var card := _card(entry["text"])
		card.accepts = func(data: Variant) -> bool: return data is Dictionary and data.has("match_left")
		card.on_drop = func(data: Variant) -> void: _connect(data["match_left"], entry["id"])
		card.tapped.connect(_on_right.bind(entry["id"]))
		right.add_child(card)
		_right_cards[entry["id"]] = card
		Ui.pop_in(card, 0.05 * index + 0.1)
	_layer = Control.new()
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.draw.connect(_draw_ropes)
	add_child(_layer)


func _column() -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	return column


func _card(text: String) -> TapCard:
	var card := TapCard.new()
	card.accent = accent()
	card.depth = 6
	card.custom_minimum_size.y = 54 if compact() else 64
	var label := ActivityStyle.label(text, 21 if compact() else 24, ActivityStyle.INK, true, 120)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(label)
	return card


func _process(_delta: float) -> void:
	if not _dragging.is_empty() and not get_viewport().gui_is_dragging():
		_dragging = ""
	_layer.queue_redraw()


func _on_left(left_id: String) -> void:
	if locked:
		return
	if _links.has(left_id):
		_links.erase(left_id)
		changed.emit()
	_select("" if _selected == left_id else left_id)


func _on_right(right_id: String) -> void:
	if locked:
		return
	if not _selected.is_empty():
		_connect(_selected, right_id)
		return
	for left_id: String in _links:
		if _links[left_id] == right_id:
			_links.erase(left_id)
			_select(left_id)
			changed.emit()
			return


func _connect(left_id: String, right_id: String) -> void:
	if locked:
		return
	for other: String in _links.keys():
		if _links[other] == right_id:
			_links.erase(other)
	_links[left_id] = right_id
	_select("")
	ActivityStyle.pop(_right_cards[right_id], 0.06)
	_refresh()
	changed.emit()


func _select(left_id: String) -> void:
	_selected = left_id
	_refresh()


func _refresh() -> void:
	for left_id: String in _left_cards:
		_left_cards[left_id].state = ActivityStyle.SELECTED if left_id == _selected else ActivityStyle.NORMAL


func _anchor(card: Control, on_right_edge: bool) -> Vector2:
	var rect := card.get_global_rect()
	var point := Vector2(rect.end.x if on_right_edge else rect.position.x, rect.get_center().y)
	return get_global_transform().affine_inverse() * point


func _draw_ropes() -> void:
	for left_id: String in _left_cards:
		var start := _anchor(_left_cards[left_id], true)
		var color: Color = _colors[left_id]
		if _links.has(left_id):
			var finish := _anchor(_right_cards[_links[left_id]], false)
			var result: Variant = _results.get(left_id)
			_rope(start, finish, color if result != false else ActivityStyle.MUTED, result == false)
			if result != null:
				_result_mark((start + finish) * 0.5, result)
		elif left_id == _dragging:
			_rope(start, _layer.get_local_mouse_position(), color, false)
		_knot(start, color, left_id == _selected)
	for right_id: String in _right_cards:
		var linked := ""
		for left_id: String in _links:
			if _links[left_id] == right_id:
				linked = left_id
		_knot(_anchor(_right_cards[right_id], false), _colors[linked] if not linked.is_empty() else ActivityStyle.CREAM, false)


## Cuerda torcida: un trazo de color con vueltas más claras, colgando un poco.
func _rope(from: Vector2, to: Vector2, color: Color, dashed: bool) -> void:
	var points := PackedVector2Array()
	var sag := minf(28.0, from.distance_to(to) * 0.12)
	for index in 25:
		var t := index / 24.0
		var p0 := from
		var p1 := from + Vector2(60, sag)
		var p2 := to + Vector2(-60, sag)
		var p3 := to
		var u := 1.0 - t
		points.append(u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3)
	if dashed:
		for index in range(0, points.size() - 1, 2):
			_layer.draw_line(points[index], points[index + 1], color, 6.0, true)
		return
	_layer.draw_polyline(points, color.darkened(0.35), 10.0, true)
	_layer.draw_polyline(points, color, 7.0, true)
	var light := color.lightened(0.45)
	for index in range(1, points.size() - 1, 2):
		var direction := (points[index + 1] - points[index - 1]).normalized()
		var normal := Vector2(-direction.y, direction.x)
		_layer.draw_line(points[index] - normal * 2.5 - direction * 2.0, points[index] + normal * 2.5 + direction * 2.0, light, 2.0, true)


func _knot(at: Vector2, color: Color, glowing: bool) -> void:
	if glowing:
		_layer.draw_circle(at, KNOT + 7.0, Color(color, 0.3))
	_layer.draw_circle(at, KNOT + 2.0, ActivityStyle.BROWN)
	_layer.draw_circle(at, KNOT, color)
	_layer.draw_circle(at + Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.55))


func _result_mark(at: Vector2, right: bool) -> void:
	var fill := ActivityStyle.SUCCESS if right else ActivityStyle.ERROR
	_layer.draw_circle(at, 17.0, Color.WHITE)
	_layer.draw_circle(at, 15.0, fill)
	var icon: Texture2D = MarkBadge.CHECK if right else MarkBadge.CROSS
	_layer.draw_texture_rect(icon, Rect2(at - Vector2(11, 11), Vector2(22, 22)), false)


func _knot_preview(color: Color) -> Control:
	var holder := Control.new()
	var knot := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = ActivityStyle.BROWN
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	knot.add_theme_stylebox_override("panel", style)
	knot.size = Vector2(36, 36)
	knot.position = Vector2(-18, -18)
	holder.add_child(knot)
	return holder


func answer() -> Variant:
	return _links.duplicate()


func is_complete() -> bool:
	return _links.size() == _left_cards.size()


func show_result(parts: Dictionary) -> void:
	_results = parts.duplicate()
	for left_id: String in _left_cards:
		_left_cards[left_id].disabled = true
		if parts.has(left_id):
			_left_cards[left_id].state = ActivityStyle.RIGHT if parts[left_id] else ActivityStyle.WRONG
	for right_id: String in _right_cards:
		_right_cards[right_id].disabled = true


func apply_answer(value: Variant) -> void:
	var delay := 0.0
	for left_id: Variant in value:
		get_tree().create_timer(delay).timeout.connect(func() -> void: _select(str(left_id)))
		get_tree().create_timer(delay + 0.35).timeout.connect(_connect.bind(str(left_id), str(value[left_id])))
		delay += 0.8

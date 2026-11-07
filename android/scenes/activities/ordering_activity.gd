class_name OrderingActivity
extends ActivityView
## Ordenar: tarjetas en fila vertical con su número de posición. Se arrastran a otro lugar
## o se tocan dos para intercambiarlas. Respuesta: lista de ids en el orden elegido.

const GAP := 10.0
const SLIDE := 0.28

var _order: Array[String] = []
var _cards := {}
var _numbers := {}
var _selected := ""
var _card_height := 64.0


func build() -> void:
	clip_contents = false
	for element: Dictionary in step.data["elements"]:
		var card := TapCard.new()
		card.accent = accent()
		card.custom_minimum_size.y = 54 if compact() else 64
		card.drag_data = {"ordering": element["id"]}
		card.preview_text = element["text"]
		card.accepts = func(data: Variant) -> bool:
			return data is Dictionary and data.has("ordering") and data["ordering"] != element["id"]
		card.on_drop = func(data: Variant) -> void: _move(data["ordering"], _order.find(element["id"]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var number := MarkBadge.new("", accent(), false, 36.0 if compact() else 42.0)
		row.add_child(number)
		var text := ActivityStyle.label(element["text"], 22 if compact() else 26, ActivityStyle.INK, true, 200)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var grip := TextureRect.new()
		grip.texture = Ui.icon("grip")
		grip.modulate = ActivityStyle.LINE.darkened(0.3)
		grip.custom_minimum_size = Vector2(30, 30)
		grip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		grip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		grip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(grip)
		card.add_child(row)
		card.tapped.connect(_on_tapped.bind(element["id"]))
		add_child(card)
		_cards[element["id"]] = card
		_numbers[element["id"]] = number
		_order.append(element["id"])
	resized.connect(_layout.bind(false))
	_layout.call_deferred(false)


func _layout(animated: bool) -> void:
	if _order.is_empty() or size.x <= 0.0:
		return
	_card_height = 0.0
	for element_id in _order:
		var card: TapCard = _cards[element_id]
		card.size.x = size.x
		_card_height = maxf(_card_height, card.get_combined_minimum_size().y)
	var total := _order.size() * (_card_height + GAP) - GAP
	custom_minimum_size.y = total
	var top := maxf(0.0, (size.y - total) * 0.5)
	for index in _order.size():
		var card: TapCard = _cards[_order[index]]
		_numbers[_order[index]].text = str(index + 1)
		var target := Vector2(0.0, top + index * (_card_height + GAP))
		card.size = Vector2(size.x, _card_height)
		if animated:
			card.create_tween().tween_property(card, "position", target, SLIDE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			card.position = target


func _on_tapped(element_id: String) -> void:
	if locked:
		return
	if _selected.is_empty():
		_selected = element_id
		_cards[element_id].state = ActivityStyle.SELECTED
		return
	if _selected != element_id:
		var a := _order.find(_selected)
		var b := _order.find(element_id)
		_order[a] = element_id
		_order[b] = _selected
		_layout(true)
		changed.emit()
	_cards[_selected].state = ActivityStyle.NORMAL
	_selected = ""


## Lleva un elemento a otra posición; los demás se corren.
func _move(element_id: String, target_index: int) -> void:
	if locked or target_index < 0:
		return
	if not _selected.is_empty():
		_cards[_selected].state = ActivityStyle.NORMAL
		_selected = ""
	_order.erase(element_id)
	_order.insert(target_index, element_id)
	_layout(true)
	ActivityStyle.pop(_cards[element_id], 0.05)
	changed.emit()


func answer() -> Variant:
	return _order.duplicate()


func is_complete() -> bool:
	return _order.size() == _cards.size()


func show_result(parts: Dictionary) -> void:
	for element_id: String in _cards:
		var card: TapCard = _cards[element_id]
		card.disabled = true
		card.drag_data = null
		if parts.has(element_id):
			var state := ActivityStyle.RIGHT if parts[element_id] else ActivityStyle.WRONG
			card.state = state
			_numbers[element_id].state = state


## Recorre la lista y lleva cada elemento a su lugar, uno por uno, como lo haría un estudiante.
func apply_answer(value: Variant) -> void:
	var wanted: Array = value
	var delay := 0.0
	for index in wanted.size():
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			var element_id := str(wanted[index])
			if _order.find(element_id) != index:
				_move(element_id, index))
		delay += 0.6

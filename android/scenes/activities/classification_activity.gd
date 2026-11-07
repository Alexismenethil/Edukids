class_name ClassificationActivity
extends ActivityView
## Clasificar: las tarjetas esperan arriba y cada una va a su canasta tejida. Se arrastran
## o se tocan (tarjeta y luego canasta). Una tarjeta en una canasta vuelve arriba si se toca.
## Respuesta: diccionario id del elemento → id del grupo.

var _pile: HFlowContainer
var _cards := {}
var _baskets := {}
var _placed := {}
var _selected := ""


func build() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)
	_pile = HFlowContainer.new()
	_pile.alignment = FlowContainer.ALIGNMENT_CENTER
	_pile.add_theme_constant_override("h_separation", 10)
	_pile.add_theme_constant_override("v_separation", 10)
	_pile.custom_minimum_size.y = 64
	box.add_child(_pile)
	var elements: Array = step.data["elements"]
	for index in elements.size():
		var element: Dictionary = elements[index]
		var card := TapCard.new()
		card.accent = accent()
		card.radius = 18
		card.depth = 6
		card.custom_minimum_size = Vector2(76, 56)
		card.drag_data = {"classify": element["id"]}
		card.preview_text = element["text"]
		var label := ActivityStyle.label(element["text"], 24, ActivityStyle.INK, false)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(label)
		card.tapped.connect(_on_card.bind(element["id"]))
		_pile.add_child(card)
		_cards[element["id"]] = card
		Ui.pop_in(card, 0.04 * index)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	var groups: Array = step.data["groups"]
	for index in groups.size():
		var group: Dictionary = groups[index]
		var basket := WovenBasket.new(group["text"], ActivityStyle.THREADS[(index * 2) % ActivityStyle.THREADS.size()])
		basket.size_flags_vertical = Control.SIZE_EXPAND_FILL
		basket.accepts = func(data: Variant) -> bool: return data is Dictionary and data.has("classify")
		basket.on_drop = func(data: Variant) -> void: _place(data["classify"], group["id"])
		basket.tapped.connect(_on_basket.bind(group["id"]))
		row.add_child(basket)
		_baskets[group["id"]] = basket


func _on_card(element_id: String) -> void:
	if locked:
		return
	if _placed.has(element_id):
		_return_to_pile(element_id)
		return
	_selected = "" if _selected == element_id else element_id
	for other: String in _cards:
		if not _placed.has(other):
			_cards[other].state = ActivityStyle.SELECTED if other == _selected else ActivityStyle.NORMAL


func _on_basket(group_id: String) -> void:
	if locked or _selected.is_empty():
		return
	_place(_selected, group_id)


func _place(element_id: String, group_id: String) -> void:
	if locked:
		return
	var card: TapCard = _cards[element_id]
	card.state = ActivityStyle.NORMAL
	card.get_parent().remove_child(card)
	(_baskets[group_id] as WovenBasket).holder().add_child(card)
	_placed[element_id] = group_id
	_selected = ""
	ActivityStyle.pop(card, 0.12)
	changed.emit()


func _return_to_pile(element_id: String) -> void:
	var card: TapCard = _cards[element_id]
	card.get_parent().remove_child(card)
	_pile.add_child(card)
	_placed.erase(element_id)
	ActivityStyle.pop(card, 0.08)
	changed.emit()


func answer() -> Variant:
	return _placed.duplicate()


func is_complete() -> bool:
	return _placed.size() == _cards.size()


func show_result(parts: Dictionary) -> void:
	for basket: WovenBasket in _baskets.values():
		basket.disabled = true
	for element_id: String in _cards:
		var card: TapCard = _cards[element_id]
		card.disabled = true
		card.drag_data = null
		if parts.has(element_id):
			card.state = ActivityStyle.RIGHT if parts[element_id] else ActivityStyle.WRONG
			if not parts[element_id]:
				ActivityStyle.shake(card)


func apply_answer(value: Variant) -> void:
	var delay := 0.0
	for element_id: Variant in value:
		get_tree().create_timer(delay).timeout.connect(func() -> void: _on_card(str(element_id)))
		get_tree().create_timer(delay + 0.3).timeout.connect(_place.bind(str(element_id), str(value[element_id])))
		delay += 0.55

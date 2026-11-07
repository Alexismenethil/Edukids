class_name FillBlankActivity
extends ActivityView
## Completar: el texto fluye con espacios para llenar; abajo, las palabras para elegir.
## Se toca un espacio y luego una palabra, o se arrastra la palabra al espacio. Los espacios
## sin opciones se escriben con el teclado. Respuesta: diccionario id del espacio → texto.

const SLOT_WIDTH := 132.0

var _slots := {}
var _fields := {}
var _values := {}
var _order: Array[String] = []
var _selected := ""


func build() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	center(box)
	add_child(box)
	var paper := PanelContainer.new()
	var style := ActivityStyle.box(ActivityStyle.PAPER, ActivityStyle.LINE, 4, 18)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	paper.add_theme_stylebox_override("panel", style)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 14)
	paper.add_child(flow)
	box.add_child(paper)
	var typed: Array = step.data.get("typed", [])
	for token: Dictionary in step.data["tokens"]:
		if token.has("blank"):
			var blank_id: String = token["blank"]
			_order.append(blank_id)
			if typed.has(blank_id):
				flow.add_child(_field(blank_id))
			else:
				flow.add_child(_slot(blank_id))
		else:
			for word in token["text"].split(" ", false):
				flow.add_child(ActivityStyle.label(word, 28, ActivityStyle.INK, false))
	var bank: Array = step.data.get("bank", [])
	if not bank.is_empty():
		var caption := ActivityStyle.label(step.labels.get("bank", ""), 22, ActivityStyle.MUTED, false)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(caption)
		var words := HFlowContainer.new()
		words.alignment = FlowContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("h_separation", 14)
		words.add_theme_constant_override("v_separation", 12)
		box.add_child(words)
		for index in bank.size():
			var word: String = bank[index]
			var chip := TapCard.new()
			chip.accent = accent()
			chip.radius = 26
			chip.depth = 7
			chip.custom_minimum_size = Vector2(110, 62)
			chip.drag_data = {"word": word}
			chip.preview_text = word
			var label := ActivityStyle.label(word, 28, ActivityStyle.INK, false)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			chip.add_child(label)
			chip.tapped.connect(_on_word.bind(word))
			words.add_child(chip)
			Ui.pop_in(chip, 0.05 * index)
	_select_next_empty()


func _slot(blank_id: String) -> TapCard:
	var slot := TapCard.new()
	slot.accent = accent()
	slot.radius = 14
	slot.depth = 5
	slot.custom_minimum_size = Vector2(SLOT_WIDTH, 50)
	var label := ActivityStyle.label("", 28, accent(), false)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", accent().darkened(0.1))
	slot.add_child(label)
	slot.accepts = func(data: Variant) -> bool: return data is Dictionary and data.has("word")
	slot.on_drop = func(data: Variant) -> void: _fill(blank_id, data["word"])
	slot.tapped.connect(_on_slot.bind(blank_id))
	_slots[blank_id] = slot
	return slot


func _field(blank_id: String) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = step.labels.get("write", "")
	field.custom_minimum_size = Vector2(SLOT_WIDTH + 40, 52)
	field.add_theme_font_size_override("font_size", 26)
	field.max_length = 24
	field.text_changed.connect(func(text: String) -> void:
		_values[blank_id] = text
		changed.emit())
	_fields[blank_id] = field
	return field


func _on_slot(blank_id: String) -> void:
	if locked:
		return
	if _values.has(blank_id):
		_values.erase(blank_id)
		_show(blank_id)
		changed.emit()
	_selected = blank_id
	_refresh()


func _on_word(word: String) -> void:
	if locked:
		return
	if _selected.is_empty():
		_select_next_empty()
	if not _selected.is_empty():
		_fill(_selected, word)


func _fill(blank_id: String, word: String) -> void:
	if locked:
		return
	_values[blank_id] = word
	_show(blank_id)
	ActivityStyle.pop(_slots[blank_id], 0.1)
	_selected = ""
	_select_next_empty()
	changed.emit()


func _show(blank_id: String) -> void:
	var label: Label = _slots[blank_id].get_child(0)
	label.text = _values.get(blank_id, "")


func _select_next_empty() -> void:
	_selected = ""
	for blank_id in _order:
		if _slots.has(blank_id) and not _values.has(blank_id):
			_selected = blank_id
			break
	_refresh()


func _refresh() -> void:
	for blank_id: String in _slots:
		_slots[blank_id].state = ActivityStyle.SELECTED if blank_id == _selected else ActivityStyle.NORMAL


func answer() -> Variant:
	return _values.duplicate()


func is_complete() -> bool:
	for blank_id in _order:
		if str(_values.get(blank_id, "")).strip_edges().is_empty():
			return false
	return true


func show_result(parts: Dictionary) -> void:
	_selected = ""
	for blank_id: String in _slots:
		var slot: TapCard = _slots[blank_id]
		slot.disabled = true
		if parts.has(blank_id):
			slot.state = ActivityStyle.RIGHT if parts[blank_id] else ActivityStyle.WRONG
			var label: Label = slot.get_child(0)
			label.add_theme_color_override("font_color", ActivityStyle.INK)
	for blank_id: String in _fields:
		_fields[blank_id].editable = false
		if parts.has(blank_id):
			_fields[blank_id].add_theme_color_override("font_uneditable_color",
				ActivityStyle.SUCCESS if parts[blank_id] else ActivityStyle.ERROR)


func apply_answer(value: Variant) -> void:
	var delay := 0.0
	for blank_id: Variant in value:
		var key := str(blank_id)
		if _fields.has(key):
			_fields[key].text = str(value[blank_id])
			_values[key] = str(value[blank_id])
			continue
		get_tree().create_timer(delay).timeout.connect(_on_slot.bind(key))
		get_tree().create_timer(delay + 0.35).timeout.connect(_fill.bind(key, str(value[blank_id])))
		delay += 0.7

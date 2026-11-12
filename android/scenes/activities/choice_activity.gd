class_name ChoiceActivity
extends ActivityView
## Opción múltiple y selección múltiple: tarjetas grandes con su letra (A, B, C…).
## En selección múltiple, la letra es una casilla que se marca. Respuesta: id o lista de ids.

const LETTERS := "ABCDEFGH"
## Con textos largos, las opciones van en una columna.
const LONG_TEXT := 26

var _multiple := false
var _cards := {}
var _badges := {}
var _chosen: Array[String] = []


func build() -> void:
	_multiple = step.data.get("multiple", false)
	var options: Array = step.data["options"]
	# En la columna angosta de una lectura, las opciones siempre van en lista.
	var longest := 0
	for option: Dictionary in options:
		longest = maxi(longest, String(option["text"]).length())
	var long := compact() or longest > LONG_TEXT
	# Bajo la escena de una mecánica la tarjeta es más baja: las opciones medianas van en dos columnas.
	var short := step.short and not compact()
	var paired := short and long and longest <= 52 and options.size() >= 4
	var container: Container
	if long and not paired:
		container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 8 if compact() or short else 12)
	else:
		var grid := GridContainer.new()
		grid.columns = 2 if paired else (3 if options.size() in [3, 5, 6] else 2)
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		container = grid
	center(container)
	add_child(container)
	for index in options.size():
		var option: Dictionary = options[index]
		var card := TapCard.new()
		card.accent = accent()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if paired:
			card.custom_minimum_size.y = 76
		elif long:
			card.custom_minimum_size.y = 56 if compact() or short else 76
		else:
			card.custom_minimum_size.y = 92 if short else 108
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge := MarkBadge.new(LETTERS[index], accent(), _multiple, 40.0 if compact() else 46.0)
		row.add_child(badge)
		var text_size := 32
		if long:
			text_size = 23 if compact() or short else 26
		var text := ActivityStyle.label(option["text"], text_size, ActivityStyle.INK, true, 120)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if long else HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(text)
		card.add_child(row)
		card.tapped.connect(_toggle.bind(option["id"]))
		container.add_child(card)
		_cards[option["id"]] = card
		_badges[option["id"]] = badge
		Ui.pop_in(card, 0.05 * index)


func _toggle(option_id: String) -> void:
	if locked:
		return
	if _multiple:
		if _chosen.has(option_id):
			_chosen.erase(option_id)
		else:
			_chosen.append(option_id)
	else:
		var was_chosen := _chosen.has(option_id)
		_chosen.clear()
		if not was_chosen:
			_chosen.append(option_id)
	_refresh()
	changed.emit()


func _refresh() -> void:
	for option_id: String in _cards:
		var state := ActivityStyle.SELECTED if _chosen.has(option_id) else ActivityStyle.NORMAL
		_cards[option_id].state = state
		_badges[option_id].state = state


func answer() -> Variant:
	if _multiple:
		return _chosen.duplicate()
	return _chosen[0] if not _chosen.is_empty() else ""


func is_complete() -> bool:
	return not _chosen.is_empty()


func show_result(parts: Dictionary) -> void:
	for option_id: String in _cards:
		var card: TapCard = _cards[option_id]
		card.disabled = true
		if parts.has(option_id):
			var state := ActivityStyle.RIGHT if parts[option_id] else ActivityStyle.WRONG
			card.state = state
			_badges[option_id].state = state
			if parts[option_id]:
				ActivityStyle.pop(card, 0.06)
			else:
				ActivityStyle.shake(card)
		else:
			card.modulate = Color(1, 1, 1, 0.55)


func apply_answer(value: Variant) -> void:
	var wanted: Array = value if value is Array else [value]
	var delay := 0.0
	for option_id: Variant in wanted:
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if _cards.has(str(option_id)):
				ActivityStyle.pop(_cards[str(option_id)], 0.06)
				_toggle(str(option_id)))
		delay += 0.45

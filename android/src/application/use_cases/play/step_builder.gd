class_name StepBuilder
extends RefCounted
## Prepara la pregunta actual para mostrarla: copia solo lo que la vista necesita, sin las
## respuestas correctas, y desordena lo que debe desordenarse (elementos, columnas y palabras).

var _random: RandomSource


func _init(random: RandomSource) -> void:
	_random = random


func build(session: LevelSession) -> StepResponse:
	var step := session.current()
	if step == null:
		return null
	var item := step.item
	var response := StepResponse.new()
	response.attempt_id = session.attempt_id
	response.question_id = item.id
	response.type = item.type
	response.prompt = item.prompt
	response.image = _resolve(session.level, item.image)
	response.number = session.current_number()
	response.total = session.question_count()
	response.retry = step.retry
	response.hint_available = item.has_hint()
	response.hint_offered = session.hint_offered()
	response.progress = session.progress()
	if step.unit:
		response.unit = _unit(session.level, step.unit)
	response.data = _data(session.level, item)
	return response


func _data(level: Level, item: Item) -> Dictionary:
	var spec := item.spec
	match item.type:
		ItemType.MULTIPLE_CHOICE, ItemType.MULTI_SELECT:
			var options: Array = []
			for option: Dictionary in spec["options"]:
				options.append({"id": option["id"], "text": option["text"],
					"image": _resolve(level, str(option.get("image", "")))})
			return {"options": options, "multiple": item.type == ItemType.MULTI_SELECT}
		ItemType.TRUE_FALSE:
			return {"statements": _plain(spec["statements"])}
		ItemType.ORDERING:
			var elements := shuffled(_plain(spec["elements"]))
			if elements.size() > 1 and _in_order(elements, spec["correct_order"]):
				elements.push_back(elements.pop_front())
			return {"elements": elements}
		ItemType.MATCHING:
			return {"left": _plain(spec["left"]), "right": shuffled(_plain(spec["right"]))}
		ItemType.CLASSIFICATION:
			return {"groups": _plain(spec["groups"]), "elements": shuffled(_plain(spec["elements"]))}
		ItemType.FILL_BLANK:
			var bank: Array = []
			var seen := {}
			var typed: Array = []
			for blank: Dictionary in spec["blanks"]:
				if blank["options"].is_empty():
					typed.append(blank["id"])
				for option: String in blank["options"]:
					if not seen.has(TextAnswer.normalize(option)):
						seen[TextAnswer.normalize(option)] = true
						bank.append(option)
			return {"tokens": FillBlankEvaluator.split_text(spec["text"]), "bank": shuffled(bank), "typed": typed}
		ItemType.NUMERIC:
			var formats: Array = spec["formats"]
			return {
				"unit": spec["unit"],
				"unit_first": NumericEvaluator.PREFIX_UNITS.has(spec["unit"]),
				"decimal": formats.has(NumberAnswer.DECIMAL),
				"fraction": formats.has(NumberAnswer.FRACTION),
			}
	return {}


func _unit(level: Level, unit: Item) -> Dictionary:
	var stimulus: Dictionary = unit.spec["stimulus"]
	var data := stimulus.duplicate(true)
	data["id"] = unit.id
	data["prompt"] = unit.prompt
	if data.has("file"):
		data["file"] = _resolve(level, data["file"])
	return data


## Fisher-Yates con el puerto de azar, para que las pruebas sean reproducibles.
func shuffled(list: Array) -> Array:
	var copy := list.duplicate()
	for index in range(copy.size() - 1, 0, -1):
		var other := _random.next_int(0, index)
		var held: Variant = copy[index]
		copy[index] = copy[other]
		copy[other] = held
	return copy


static func _plain(list: Array) -> Array:
	var plain: Array = []
	for entry: Dictionary in list:
		plain.append({"id": entry["id"], "text": entry["text"]})
	return plain


## true si los elementos quedaron justo en el orden correcto (no se le da resuelto al estudiante).
static func _in_order(list: Array, order: Array) -> bool:
	for index in list.size():
		if list[index]["id"] != order[index]:
			return false
	return true


static func _resolve(level: Level, path: String) -> String:
	if path.is_empty() or level.location.is_empty():
		return path
	return level.location.path_join(path)

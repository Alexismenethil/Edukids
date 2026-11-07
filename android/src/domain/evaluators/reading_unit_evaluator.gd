class_name ReadingUnitEvaluator
extends ItemEvaluator
## Unidad de lectura: un estímulo (texto, tabla o imagen) y sus preguntas, cada una de otro tipo.
## En la práctica, la sesión presenta cada pregunta por separado con el estímulo a la vista (RF-28).
## Respuesta completa: un diccionario id de la pregunta → su respuesta.

const STIMULUS_TYPES: Array[String] = ["text", "image", "table"]
const MIN_QUESTIONS := 1
const MAX_QUESTIONS := 8

## Referencia débil: el registro guarda a este evaluador y este lo usa para las preguntas internas.
var _registry: WeakRef


func _init(registry: EvaluatorRegistry) -> void:
	_registry = weakref(registry)


func type() -> StringName:
	return ItemType.READING_UNIT


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var stimulus := _parse_stimulus(raw.get("stimulus"), item_id)
	if not stimulus.is_ok():
		return stimulus
	var raw_items: Variant = raw.get("items")
	if typeof(raw_items) != TYPE_ARRAY or raw_items.size() < MIN_QUESTIONS or raw_items.size() > MAX_QUESTIONS:
		return invalid(item_id, "«items» debe tener de %d a %d preguntas" % [MIN_QUESTIONS, MAX_QUESTIONS])
	var registry: EvaluatorRegistry = _registry.get_ref()
	var questions: Array[Item] = []
	for raw_item: Variant in raw_items:
		var parsed := registry.parse_item(raw_item, false)
		if not parsed.is_ok():
			return parsed
		questions.append(parsed.value)
	return Result.ok({"stimulus": stimulus.value, "items": questions})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	if typeof(answer) != TYPE_DICTIONARY:
		return Evaluation.incomplete()
	var registry: EvaluatorRegistry = _registry.get_ref()
	var parts := {}
	for question: Item in item.spec["items"]:
		var evaluation := registry.evaluate(question, answer.get(question.id))
		if not evaluation.complete:
			return Evaluation.incomplete()
		parts[question.id] = evaluation.correct
	return Evaluation.of(not parts.values().has(false), parts)


func solution_text(item: Item) -> String:
	var registry: EvaluatorRegistry = _registry.get_ref()
	var texts: Array[String] = []
	for question: Item in item.spec["items"]:
		texts.append(registry.solution_text(question))
	return " · ".join(texts)


static func _parse_stimulus(value: Variant, item_id: String) -> Result:
	if typeof(value) != TYPE_DICTIONARY:
		return invalid(item_id, "falta el estímulo («stimulus»)")
	var kind := str(value.get("type", "text"))
	if not STIMULUS_TYPES.has(kind):
		return invalid(item_id, "estímulo de tipo «%s» desconocido" % kind)
	var stimulus := {"type": kind, "title": str(value.get("title", "")).strip_edges()}
	match kind:
		"text":
			var content: Variant = value.get("content", "")
			var paragraphs: Array[String] = []
			for paragraph: Variant in (content if typeof(content) == TYPE_ARRAY else str(content).split("\n\n")):
				if not str(paragraph).strip_edges().is_empty():
					paragraphs.append(str(paragraph).strip_edges())
			if paragraphs.is_empty():
				return invalid(item_id, "el texto del estímulo está vacío")
			stimulus["paragraphs"] = paragraphs
		"table":
			var table: Variant = value.get("content", {})
			if typeof(table) != TYPE_DICTIONARY or typeof(table.get("columns")) != TYPE_ARRAY \
					or typeof(table.get("rows")) != TYPE_ARRAY or table["rows"].is_empty():
				return invalid(item_id, "la tabla del estímulo necesita «columns» y «rows»")
			var columns: Array = table["columns"]
			var rows: Array = []
			for row: Variant in table["rows"]:
				if typeof(row) != TYPE_ARRAY or row.size() != columns.size():
					return invalid(item_id, "cada fila de la tabla debe tener %d celdas" % columns.size())
				rows.append(row.map(func(cell: Variant) -> String: return str(cell)))
			stimulus["columns"] = columns.map(func(cell: Variant) -> String: return str(cell))
			stimulus["rows"] = rows
			stimulus["note"] = str(value.get("note", "")).strip_edges()
		"image":
			var file := str(value.get("file", "")).strip_edges()
			if file.is_empty():
				return invalid(item_id, "la imagen del estímulo necesita «file»")
			stimulus["file"] = file
	return Result.ok(stimulus)

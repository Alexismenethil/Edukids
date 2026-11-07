class_name NumericEvaluator
extends ItemEvaluator
## Respuesta numérica: valor exacto o con tolerancia, en los formatos que acepta el ítem
## («decimal» incluye los enteros; «fraction», las fracciones y los números mixtos).
## Respuesta: el texto escrito con el teclado del juego.

## Unidades que se escriben antes del número.
const PREFIX_UNITS: Array[String] = ["S/", "$", "US$"]


func type() -> StringName:
	return ItemType.NUMERIC


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var answer: Variant = raw.get("answer")
	if typeof(answer) != TYPE_INT and typeof(answer) != TYPE_FLOAT:
		return invalid(item_id, "«answer» debe ser un número")
	var tolerance: Variant = raw.get("tolerance", 0)
	if (typeof(tolerance) != TYPE_INT and typeof(tolerance) != TYPE_FLOAT) or tolerance < 0:
		return invalid(item_id, "«tolerance» debe ser un número mayor o igual que 0")
	var raw_formats: Variant = raw.get("accepted_formats", [NumberAnswer.DECIMAL])
	if typeof(raw_formats) != TYPE_ARRAY:
		return invalid(item_id, "«accepted_formats» debe ser una lista")
	var formats: Array[StringName] = []
	for entry: Variant in raw_formats:
		var format := StringName(str(entry))
		if not NumberAnswer.FORMATS.has(format):
			return invalid(item_id, "formato «%s» desconocido" % format)
		if not formats.has(format):
			formats.append(format)
	if formats.is_empty():
		return invalid(item_id, "«accepted_formats» no puede estar vacío")
	return Result.ok({
		"answer": float(answer),
		"tolerance": float(tolerance),
		"unit": str(raw.get("unit", "")).strip_edges(),
		"formats": formats,
	})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	var parsed := NumberAnswer.parse(str(answer) if answer != null else "")
	if not parsed.is_ok():
		return Evaluation.incomplete()
	var number: NumberAnswer = parsed.value
	var formats: Array = item.spec["formats"]
	var right := formats.has(number.format) and NumberAnswer.same(number.value, item.spec["answer"], item.spec["tolerance"])
	return Evaluation.of(right, {"value": right})


func solution_text(item: Item) -> String:
	return with_unit(NumberAnswer.spoken(item.spec["answer"]), item.spec["unit"])


static func with_unit(number: String, unit: String) -> String:
	if unit.is_empty():
		return number
	return "%s %s" % [unit, number] if PREFIX_UNITS.has(unit) else "%s %s" % [number, unit]

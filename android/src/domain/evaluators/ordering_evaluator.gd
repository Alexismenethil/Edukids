class_name OrderingEvaluator
extends ItemEvaluator
## Ordenar: la secuencia debe ser idéntica. Respuesta: la lista de ids en el orden elegido.

const MIN_ELEMENTS := 2
const MAX_ELEMENTS := 7


func type() -> StringName:
	return ItemType.ORDERING


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var parsed := entries(raw, "elements", item_id, MIN_ELEMENTS, MAX_ELEMENTS)
	if not parsed.is_ok():
		return parsed
	var order := id_list(raw.get("correct_order"))
	var ids := ids_of(parsed.value)
	if order.size() != ids.size() or not _same_ids(order, ids):
		return invalid(item_id, "«correct_order» debe nombrar cada elemento una sola vez")
	return Result.ok({"elements": parsed.value, "correct_order": order})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	var order := id_list(answer)
	var correct: Array = item.spec["correct_order"]
	if order.size() != correct.size() or not _same_ids(order, ids_of(item.spec["elements"])):
		return Evaluation.incomplete()
	var parts := {}
	for index in order.size():
		parts[order[index]] = order[index] == correct[index]
	return Evaluation.of(not parts.values().has(false), parts)


func solution_text(item: Item) -> String:
	var texts: Array[String] = []
	for element_id: String in item.spec["correct_order"]:
		texts.append(text_of(item.spec["elements"], element_id))
	return " → ".join(texts)


static func _same_ids(a: Array[String], b: Array[String]) -> bool:
	for entry in a:
		if not b.has(entry):
			return false
	return a.size() == b.size()

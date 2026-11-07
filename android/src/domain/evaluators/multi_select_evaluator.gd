class_name MultiSelectEvaluator
extends ItemEvaluator
## Selección múltiple: hay que marcar exactamente las opciones correctas.
## Respuesta: la lista de ids marcados.

const MIN_OPTIONS := 3
const MAX_OPTIONS := 8


func type() -> StringName:
	return ItemType.MULTI_SELECT


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var parsed := entries(raw, "options", item_id, MIN_OPTIONS, MAX_OPTIONS)
	if not parsed.is_ok():
		return parsed
	var correct: Array[String] = []
	for option: Dictionary in parsed.value:
		if option.get("correct", false) == true:
			correct.append(option["id"])
	if correct.is_empty():
		return invalid(item_id, "debe tener al menos una opción correcta")
	return Result.ok({"options": parsed.value, "correct": correct})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	if typeof(answer) != TYPE_ARRAY or answer.is_empty():
		return Evaluation.incomplete()
	var options := ids_of(item.spec["options"])
	var correct: Array = item.spec["correct"]
	var parts := {}
	var feedback := ""
	for value: Variant in answer:
		var choice := as_id(value)
		if not options.has(choice) or parts.has(choice):
			return Evaluation.incomplete()
		parts[choice] = correct.has(choice)
		if not parts[choice] and feedback.is_empty():
			feedback = feedback_of(item.spec["options"], choice)
	var missing := 0
	for option_id: String in correct:
		if not parts.has(option_id):
			missing += 1
	var evaluation := Evaluation.of(missing == 0 and not parts.values().has(false), parts, feedback)
	evaluation.missing = missing
	return evaluation


func solution_text(item: Item) -> String:
	var texts: Array[String] = []
	for option_id: String in item.spec["correct"]:
		texts.append(text_of(item.spec["options"], option_id))
	return ", ".join(texts)

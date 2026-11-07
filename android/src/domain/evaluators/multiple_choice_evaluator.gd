class_name MultipleChoiceEvaluator
extends ItemEvaluator
## Opción múltiple: una sola opción correcta. Respuesta: el id de la opción elegida.

const MIN_OPTIONS := 2
const MAX_OPTIONS := 6


func type() -> StringName:
	return ItemType.MULTIPLE_CHOICE


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var parsed := entries(raw, "options", item_id, MIN_OPTIONS, MAX_OPTIONS)
	if not parsed.is_ok():
		return parsed
	var correct: Array[String] = []
	for option: Dictionary in parsed.value:
		if option.get("correct", false) == true:
			correct.append(option["id"])
	if correct.size() != 1:
		return invalid(item_id, "debe tener exactamente una opción correcta")
	return Result.ok({"options": parsed.value, "correct": correct[0]})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	var choice := as_id(answer)
	if not ids_of(item.spec["options"]).has(choice):
		return Evaluation.incomplete()
	var right: bool = choice == item.spec["correct"]
	var feedback := "" if right else feedback_of(item.spec["options"], choice)
	return Evaluation.of(right, {choice: right}, feedback)


func solution_text(item: Item) -> String:
	return text_of(item.spec["options"], item.spec["correct"])

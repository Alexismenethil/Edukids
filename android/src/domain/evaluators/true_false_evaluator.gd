class_name TrueFalseEvaluator
extends ItemEvaluator
## Verdadero o falso: cada afirmación se corrige por separado y el ítem está bien si todas lo están.
## Respuesta: un diccionario id de la afirmación → true o false.

const MIN_STATEMENTS := 1
const MAX_STATEMENTS := 6


func type() -> StringName:
	return ItemType.TRUE_FALSE


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var parsed := entries(raw, "statements", item_id, MIN_STATEMENTS, MAX_STATEMENTS)
	if not parsed.is_ok():
		return parsed
	for statement: Dictionary in parsed.value:
		if typeof(statement.get("answer")) != TYPE_BOOL:
			return invalid(item_id, "la afirmación «%s» necesita «answer» true o false" % statement["id"])
	return Result.ok({"statements": parsed.value})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	if typeof(answer) != TYPE_DICTIONARY:
		return Evaluation.incomplete()
	var parts := {}
	var feedback := ""
	for statement: Dictionary in item.spec["statements"]:
		var given: Variant = answer.get(statement["id"])
		if typeof(given) != TYPE_BOOL:
			return Evaluation.incomplete()
		parts[statement["id"]] = given == statement["answer"]
		if not parts[statement["id"]] and feedback.is_empty():
			feedback = str(statement.get("feedback", "")).strip_edges()
	return Evaluation.of(not parts.values().has(false), parts, feedback)


func solution_text(item: Item) -> String:
	var texts: Array[String] = []
	var number := 1
	for statement: Dictionary in item.spec["statements"]:
		texts.append("%d. %s" % [number, "Verdadero" if statement["answer"] else "Falso"])
		number += 1
	return " · ".join(texts)

class_name MatchingEvaluator
extends ItemEvaluator
## Emparejar: cada elemento de la izquierda va con uno de la derecha. La derecha puede tener
## un distractor de más. Respuesta: un diccionario id izquierdo → id derecho.

const MIN_PAIRS := 2
const MAX_PAIRS := 6


func type() -> StringName:
	return ItemType.MATCHING


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var left := entries(raw, "left", item_id, MIN_PAIRS, MAX_PAIRS)
	if not left.is_ok():
		return left
	var right := entries(raw, "right", item_id, MIN_PAIRS, MAX_PAIRS + 2)
	if not right.is_ok():
		return right
	var pairs := _read_pairs(raw.get("pairs"))
	var left_ids := ids_of(left.value)
	var right_ids := ids_of(right.value)
	var used := {}
	for left_id: String in left_ids:
		var right_id: String = pairs.get(left_id, "")
		if not right_ids.has(right_id) or used.has(right_id):
			return invalid(item_id, "«pairs» debe unir cada elemento de la izquierda con uno distinto de la derecha")
		used[right_id] = true
	if pairs.size() != left_ids.size():
		return invalid(item_id, "«pairs» nombra elementos que no existen")
	return Result.ok({"left": left.value, "right": right.value, "pairs": pairs})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	if typeof(answer) != TYPE_DICTIONARY:
		return Evaluation.incomplete()
	var right_ids := ids_of(item.spec["right"])
	var parts := {}
	for left_id: String in ids_of(item.spec["left"]):
		var chosen := as_id(answer.get(left_id))
		if not right_ids.has(chosen):
			return Evaluation.incomplete()
		parts[left_id] = chosen == item.spec["pairs"][left_id]
	return Evaluation.of(not parts.values().has(false), parts)


func solution_text(item: Item) -> String:
	var texts: Array[String] = []
	for left_id: String in ids_of(item.spec["left"]):
		texts.append("%s ↔ %s" % [text_of(item.spec["left"], left_id),
			text_of(item.spec["right"], item.spec["pairs"][left_id])])
	return " · ".join(texts)


## Acepta pares como listas [izquierda, derecha] o como objetos {left, right}.
static func _read_pairs(value: Variant) -> Dictionary:
	var pairs := {}
	if typeof(value) != TYPE_ARRAY:
		return pairs
	for pair: Variant in value:
		var left_id := ""
		var right_id := ""
		if typeof(pair) == TYPE_ARRAY and pair.size() == 2:
			left_id = str(pair[0])
			right_id = str(pair[1])
		elif typeof(pair) == TYPE_DICTIONARY:
			left_id = str(pair.get("left", ""))
			right_id = str(pair.get("right", ""))
		if left_id.is_empty() or pairs.has(left_id):
			return {}
		pairs[left_id] = right_id
	return pairs

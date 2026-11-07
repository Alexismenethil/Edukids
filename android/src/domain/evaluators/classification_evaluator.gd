class_name ClassificationEvaluator
extends ItemEvaluator
## Clasificar: cada elemento debe quedar en su grupo (canasta).
## Respuesta: un diccionario id del elemento → id del grupo.

const MIN_GROUPS := 2
const MAX_GROUPS := 4
const MIN_ELEMENTS := 2
const MAX_ELEMENTS := 10


func type() -> StringName:
	return ItemType.CLASSIFICATION


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var groups := entries(raw, "groups", item_id, MIN_GROUPS, MAX_GROUPS, "label")
	if not groups.is_ok():
		return groups
	var elements := entries(raw, "elements", item_id, MIN_ELEMENTS, MAX_ELEMENTS)
	if not elements.is_ok():
		return elements
	var group_ids := ids_of(groups.value)
	for element: Dictionary in elements.value:
		if not group_ids.has(str(element.get("group", ""))):
			return invalid(item_id, "el elemento «%s» apunta a un grupo que no existe" % element["id"])
		element["group"] = str(element["group"])
	return Result.ok({"groups": groups.value, "elements": elements.value})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	if typeof(answer) != TYPE_DICTIONARY:
		return Evaluation.incomplete()
	var group_ids := ids_of(item.spec["groups"])
	var parts := {}
	for element: Dictionary in item.spec["elements"]:
		var chosen := as_id(answer.get(element["id"]))
		if not group_ids.has(chosen):
			return Evaluation.incomplete()
		parts[element["id"]] = chosen == element["group"]
	return Evaluation.of(not parts.values().has(false), parts)


func solution_text(item: Item) -> String:
	var texts: Array[String] = []
	for group: Dictionary in item.spec["groups"]:
		var members: Array[String] = []
		for element: Dictionary in item.spec["elements"]:
			if element["group"] == group["id"]:
				members.append(element["text"])
		texts.append("%s: %s" % [group["text"], ", ".join(members)])
	return " · ".join(texts)

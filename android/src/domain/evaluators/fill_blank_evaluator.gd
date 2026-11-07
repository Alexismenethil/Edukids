class_name FillBlankEvaluator
extends ItemEvaluator
## Completar: un texto con espacios marcados como {{1}}, {{2}}… Cada espacio tiene sus respuestas
## aceptadas («accepted») y, si se elige de una lista, sus opciones («options»).
## Las respuestas se comparan sin mayúsculas ni tildes. Respuesta: id del espacio → texto.

const MAX_BLANKS := 5
const OPEN := "{{"
const CLOSE := "}}"


func type() -> StringName:
	return ItemType.FILL_BLANK


func parse_spec(raw: Dictionary, item_id: String) -> Result:
	var text := str(raw.get("text", "")).strip_edges()
	var markers: Array[String] = []
	for token: Dictionary in split_text(text):
		if token.has("blank"):
			if markers.has(token["blank"]):
				return invalid(item_id, "el espacio {{%s}} aparece dos veces" % token["blank"])
			markers.append(token["blank"])
	if markers.is_empty() or markers.size() > MAX_BLANKS:
		return invalid(item_id, "«text» debe tener de 1 a %d espacios {{…}}" % MAX_BLANKS)
	var raw_blanks: Variant = raw.get("blanks")
	if typeof(raw_blanks) != TYPE_ARRAY or raw_blanks.size() != markers.size():
		return invalid(item_id, "«blanks» debe describir cada espacio del texto")
	var blanks: Array = []
	for entry: Variant in raw_blanks:
		if typeof(entry) != TYPE_DICTIONARY:
			return invalid(item_id, "cada espacio de «blanks» debe ser un objeto")
		var blank_id := str(entry.get("id", "")).strip_edges()
		var accepted := _texts(entry.get("accepted"))
		var options := _texts(entry.get("options"))
		if not markers.has(blank_id):
			return invalid(item_id, "el espacio «%s» no está en el texto" % blank_id)
		if accepted.is_empty():
			return invalid(item_id, "el espacio «%s» necesita respuestas aceptadas" % blank_id)
		if not options.is_empty() and not _any_accepted(options, accepted):
			return invalid(item_id, "las opciones del espacio «%s» no incluyen una respuesta aceptada" % blank_id)
		blanks.append({"id": blank_id, "accepted": accepted, "options": options})
	return Result.ok({"text": text, "blanks": blanks})


func evaluate(item: Item, answer: Variant) -> Evaluation:
	if typeof(answer) != TYPE_DICTIONARY:
		return Evaluation.incomplete()
	var parts := {}
	for blank: Dictionary in item.spec["blanks"]:
		var written := str(answer.get(blank["id"], ""))
		if TextAnswer.normalize(written).is_empty():
			return Evaluation.incomplete()
		parts[blank["id"]] = TextAnswer.matches(written, blank["accepted"])
	return Evaluation.of(not parts.values().has(false), parts)


func solution_text(item: Item) -> String:
	var result := ""
	for token: Dictionary in split_text(item.spec["text"]):
		if token.has("blank"):
			for blank: Dictionary in item.spec["blanks"]:
				if blank["id"] == token["blank"]:
					result += blank["accepted"][0]
		else:
			result += token["text"]
	return result


## Parte el texto en trozos: {"text": "…"} o {"blank": "id"}.
static func split_text(text: String) -> Array:
	var tokens: Array = []
	var rest := text
	while not rest.is_empty():
		var start := rest.find(OPEN)
		var finish := rest.find(CLOSE, start + OPEN.length()) if start >= 0 else -1
		if start < 0 or finish < 0:
			tokens.append({"text": rest})
			break
		if start > 0:
			tokens.append({"text": rest.substr(0, start)})
		tokens.append({"blank": rest.substr(start + OPEN.length(), finish - start - OPEN.length()).strip_edges()})
		rest = rest.substr(finish + CLOSE.length())
	return tokens


static func _texts(value: Variant) -> Array[String]:
	var texts: Array[String] = []
	if typeof(value) == TYPE_ARRAY:
		for entry: Variant in value:
			var text := str(entry).strip_edges()
			if not text.is_empty():
				texts.append(text)
	return texts


static func _any_accepted(options: Array[String], accepted: Array[String]) -> bool:
	for option in options:
		if TextAnswer.matches(option, accepted):
			return true
	return false

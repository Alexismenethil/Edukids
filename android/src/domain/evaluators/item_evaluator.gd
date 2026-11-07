@abstract class_name ItemEvaluator
extends RefCounted
## Corrector de un tipo de ítem. Todos cumplen la misma interfaz: agregar un tipo nuevo es
## escribir su evaluador (y su vista), sin tocar la sesión del nivel.


## Tipo de ítem que corrige.
@abstract func type() -> StringName


## Valida los campos propios del tipo. Devuelve un Result con el `spec` normalizado.
@abstract func parse_spec(raw: Dictionary, item_id: String) -> Result


## Corrige una respuesta. Si falta responder alguna parte, devuelve Evaluation.incomplete().
@abstract func evaluate(item: Item, answer: Variant) -> Evaluation


## La respuesta correcta en pocas palabras, para mostrarla cuando ya no queda otra oportunidad.
@abstract func solution_text(item: Item) -> String


# Utilidades para validar el contenido ---------------------------------------------------------

## Lee una lista de entradas {id, text}: ids únicos y textos no vacíos.
## `text_key` permite leer otra clave (los grupos usan «label»); siempre se guarda como «text».
static func entries(raw: Dictionary, key: String, item_id: String, minimum: int, maximum: int,
		text_key: String = "text") -> Result:
	var list: Variant = raw.get(key)
	if typeof(list) != TYPE_ARRAY:
		return invalid(item_id, "falta la lista «%s»" % key)
	if list.size() < minimum or list.size() > maximum:
		return invalid(item_id, "«%s» debe tener de %d a %d elementos" % [key, minimum, maximum])
	var seen := {}
	var parsed: Array = []
	for entry: Variant in list:
		if typeof(entry) != TYPE_DICTIONARY:
			return invalid(item_id, "cada elemento de «%s» debe ser un objeto" % key)
		var entry_id := str(entry.get("id", "")).strip_edges()
		var text := str(entry.get(text_key, "")).strip_edges()
		if entry_id.is_empty() or seen.has(entry_id):
			return invalid(item_id, "cada elemento de «%s» necesita un id único" % key)
		if text.is_empty() and str(entry.get("image", "")).is_empty():
			return invalid(item_id, "el elemento «%s» no tiene texto" % entry_id)
		seen[entry_id] = true
		var clean: Dictionary = entry.duplicate(true)
		clean.erase(text_key)
		clean["id"] = entry_id
		clean["text"] = text
		parsed.append(clean)
	return Result.ok(parsed)


static func ids_of(list: Array) -> Array[String]:
	var ids: Array[String] = []
	for entry: Dictionary in list:
		ids.append(entry["id"])
	return ids


static func text_of(list: Array, entry_id: String) -> String:
	for entry: Dictionary in list:
		if entry["id"] == entry_id:
			return entry["text"]
	return ""


## Retroalimentación propia de una entrada (por ejemplo, de un distractor).
static func feedback_of(list: Array, entry_id: String) -> String:
	for entry: Dictionary in list:
		if entry["id"] == entry_id:
			return str(entry.get("feedback", "")).strip_edges()
	return ""


## Lista de ids escritos en el contenido: textos no vacíos y sin repetir.
static func id_list(value: Variant) -> Array[String]:
	var ids: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return ids
	for entry: Variant in value:
		var entry_id := str(entry).strip_edges()
		if entry_id.is_empty() or ids.has(entry_id):
			return [] as Array[String]
		ids.append(entry_id)
	return ids


static func invalid(item_id: String, reason: String) -> Result:
	return Result.fail(&"item_invalid", "%s: %s." % [item_id, reason])


## La respuesta como texto de un id (acepta String y StringName).
static func as_id(answer: Variant) -> String:
	if answer is String or answer is StringName:
		return str(answer)
	return ""

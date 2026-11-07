class_name Level
extends RefCounted
## Nivel listo para jugar: sus datos del manifiesto, el saludo del guía y los ítems validados.

const MAX_ITEMS := 20

var package_id := ""
var package_title := ""
var package_version := ""
var area: StringName = ContentPackage.MATH
var entry: LevelEntry
var title := ""
var guide_intro: Array[String] = []
var items: Array[Item] = []
## Carpeta del paquete, para ubicar sus imágenes; la completa el almacén de paquetes.
var location := ""


## Arma el nivel desde su archivo JSON. El archivo debe tener el mismo id que el manifiesto.
static func parse(raw: Variant, package: ContentPackage, level_entry: LevelEntry, registry: EvaluatorRegistry) -> Result:
	if typeof(raw) != TYPE_DICTIONARY:
		return Result.fail(&"level_invalid", "El nivel %s no es un objeto JSON." % level_entry.id)
	if str(raw.get("id", "")) != level_entry.id:
		return Result.fail(&"level_invalid", "El archivo %s no corresponde al nivel %s." % [level_entry.file, level_entry.id])
	var level := Level.new()
	level.package_id = package.id
	level.package_title = package.title
	level.package_version = package.version
	level.area = package.area
	level.entry = level_entry
	level.title = str(raw.get("title", "")).strip_edges()
	if level.title.is_empty():
		return Result.fail(&"level_invalid", "El nivel %s no tiene título." % level_entry.id)
	var intro: Variant = raw.get("guide_intro", [])
	if typeof(intro) == TYPE_ARRAY:
		for line: Variant in intro:
			if not str(line).strip_edges().is_empty():
				level.guide_intro.append(str(line).strip_edges())
	var raw_items: Variant = raw.get("items")
	if typeof(raw_items) != TYPE_ARRAY or raw_items.is_empty() or raw_items.size() > MAX_ITEMS:
		return Result.fail(&"level_invalid", "El nivel %s debe tener de 1 a %d ítems." % [level_entry.id, MAX_ITEMS])
	var seen := {}
	for raw_item: Variant in raw_items:
		var parsed := registry.parse_item(raw_item)
		if not parsed.is_ok():
			return parsed
		for item_id in _ids_inside(parsed.value):
			if seen.has(item_id):
				return Result.fail(&"level_invalid", "El ítem %s está repetido." % item_id)
			seen[item_id] = true
		level.items.append(parsed.value)
	return Result.ok(level)


func key() -> String:
	return "%s/%s" % [package_id, entry.id]


## Cuántas preguntas tiene: cada pregunta de una unidad de lectura cuenta por separado.
func question_count() -> int:
	var count := 0
	for item in items:
		count += item.spec["items"].size() if item.type == ItemType.READING_UNIT else 1
	return count


static func _ids_inside(item: Item) -> Array[String]:
	var ids: Array[String] = [item.id]
	if item.type == ItemType.READING_UNIT:
		for question: Item in item.spec["items"]:
			ids.append(question.id)
	return ids

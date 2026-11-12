class_name ContentPackage
extends RefCounted
## Paquete de contenido (módulo oficial o reto del docente) según su manifiesto, formato v1.

const FORMAT_VERSION := "1.0"
const MODULE := &"module"
const CHALLENGE := &"challenge"
const KINDS: Array[StringName] = [MODULE, CHALLENGE]
const MATH := &"math"
const LANGUAGE := &"language"
const SCIENCE := &"science"
const AREAS: Array[StringName] = [MATH, LANGUAGE, SCIENCE]
const CHAPTERS: Array[StringName] = [&"sierra", &"selva", &"costa"]

var id := ""
var kind: StringName = MODULE
var title := ""
var area: StringName = MATH
var grade := 6
var number := 0
var chapter: StringName = &"sierra"
var stop := ""
var version := ""
## Versión mínima de la aplicación que lo puede abrir (vacía en los paquetes del juego).
var min_app_version := ""
var levels: Array[LevelEntry] = []
## Dónde está instalado; lo completa el almacén de paquetes.
var location := ""
## Viene dentro del juego (los paquetes de práctica): está habilitado para todas las secciones
## mientras el docente no diga otra cosa. Lo completa el almacén de paquetes.
var bundled := false


static func parse(raw: Variant) -> Result:
	if typeof(raw) != TYPE_DICTIONARY:
		return Result.fail(&"manifest_invalid", "El manifiesto debe ser un objeto JSON.")
	var format := str(raw.get("format_version", ""))
	if format.get_slice(".", 0) != FORMAT_VERSION.get_slice(".", 0):
		return Result.fail(&"manifest_format", "El paquete usa un formato que esta versión no conoce (%s)." % format)
	var package := ContentPackage.new()
	package.id = str(raw.get("id", "")).strip_edges()
	package.kind = StringName(str(raw.get("kind", "")))
	package.title = str(raw.get("title", "")).strip_edges()
	package.area = StringName(str(raw.get("area", "")))
	package.grade = int(raw.get("grade", 0))
	package.number = int(raw.get("number", 0))
	package.chapter = StringName(str(raw.get("chapter", "")))
	package.stop = str(raw.get("stop", "")).strip_edges()
	package.version = str(raw.get("version", "")).strip_edges()
	package.min_app_version = str(raw.get("min_app_version", "")).strip_edges()
	if package.id.is_empty() or package.title.is_empty() or package.version.is_empty():
		return Result.fail(&"manifest_invalid", "Al manifiesto le falta «id», «title» o «version».")
	if not KINDS.has(package.kind) or not AREAS.has(package.area) or not CHAPTERS.has(package.chapter):
		return Result.fail(&"manifest_invalid", "%s: tipo, área o capítulo desconocidos." % package.id)
	var raw_levels: Variant = raw.get("levels")
	if typeof(raw_levels) != TYPE_ARRAY or raw_levels.is_empty():
		return Result.fail(&"manifest_invalid", "%s: el paquete no tiene niveles." % package.id)
	for index in raw_levels.size():
		var entry := LevelEntry.parse(raw_levels[index], index + 1)
		if not entry.is_ok():
			return entry
		if package.find_level(entry.value.id) != null:
			return Result.fail(&"manifest_invalid", "%s: el nivel %s está repetido." % [package.id, entry.value.id])
		package.levels.append(entry.value)
	return Result.ok(package)


## El desafío final del módulo, si tiene.
func final_level() -> LevelEntry:
	for entry in levels:
		if entry.is_final():
			return entry
	return null


func find_level(level_id: String) -> LevelEntry:
	for entry in levels:
		if entry.id == level_id:
			return entry
	return null


## Identificador del nivel en toda la tablet: «paquete/nivel».
func level_key(level_id: String) -> String:
	return "%s/%s" % [id, level_id]

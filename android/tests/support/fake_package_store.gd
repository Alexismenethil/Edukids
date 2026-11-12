class_name FakePackageStore
extends PackageStore
## Almacén de paquetes de prueba: niveles armados con SampleItems, sin archivos.

var _packages: Array[ContentPackage] = []
var _files := {}
var _registry := EvaluatorRegistry.standard()


## Agrega un paquete con un nivel L01 hecho de los ítems indicados.
func add(area: String, items: Array, version: String = "1.0.0") -> ContentPackage:
	var raw := SampleItems.manifest(["L01"], area)
	raw["version"] = version
	var package: ContentPackage = ContentPackage.parse(raw).value
	package.location = "res://fake/%s" % package.id
	for index in _packages.size():
		if _packages[index].id == package.id:
			_packages.remove_at(index)
			break
	_packages.append(package)
	_files[package.id] = SampleItems.level_file(items)
	return package


## Agrega un módulo de una parada con varios niveles. Cada entrada es {id, kind, mechanic}
## y puede traer lives, danger y max_attempts. Todos los niveles usan los mismos ítems.
func add_module(package_id: String, area: String, entries: Array, items: Array, stop: String = "huamanga",
		number: int = 1) -> ContentPackage:
	var raw := {
		"format_version": "1.0", "id": package_id, "kind": "module", "title": "Módulo %s" % package_id,
		"area": area, "grade": 6, "number": number, "chapter": "sierra", "stop": stop, "version": "1.0.0", "levels": [],
	}
	for entry: Dictionary in entries:
		var level := {"id": entry["id"], "kind": entry.get("kind", "short"), "mechanic": entry.get("mechanic", "classic"),
			"file": "levels/%s.json" % String(entry["id"]).to_lower(), "estimated_minutes": 4}
		for key in ["lives", "danger", "max_attempts"]:
			if entry.has(key):
				level[key] = entry[key]
		raw["levels"].append(level)
	var parsed := ContentPackage.parse(raw)
	assert(parsed.is_ok(), parsed.message)
	var package: ContentPackage = parsed.value
	package.location = "res://fake/%s" % package_id
	_packages.append(package)
	for entry: Dictionary in entries:
		var file := SampleItems.level_file(items, entry["id"])
		file["title"] = "Nivel %s" % entry["id"]
		_files["%s/%s" % [package_id, entry["id"]]] = file
	return package


func list_packages() -> Array[ContentPackage]:
	return _packages.duplicate()


func load_level(package_id: String, level_id: String) -> Result:
	for package in _packages:
		if package.id == package_id and package.find_level(level_id):
			var file: Dictionary = _files.get("%s/%s" % [package_id, level_id], _files.get(package_id, {}))
			var parsed := Level.parse(file, package, package.find_level(level_id), _registry)
			if parsed.is_ok():
				(parsed.value as Level).location = package.location
			return parsed
	return Result.fail(&"level_not_found", "No existe %s/%s." % [package_id, level_id])

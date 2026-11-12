class_name FolderPackageStore
extends PackageStore
## Adaptador de salida: lee los paquetes desde carpetas, uno por subcarpeta con su manifest.json
## (formato v1): los instalados en user://packages y los que vienen con el juego
## (res://content/packages). Si un paquete está en las dos, gana la primera carpeta de la lista
## (así una versión instalada reemplaza a la del juego).

const MANIFEST := "manifest.json"

## Paquetes o niveles que no se pudieron leer, para el panel de medición.
var problems: Array[String] = []

var _folders: Array[String] = []
var _registry: EvaluatorRegistry
var _packages: Array[ContentPackage] = []
var _levels := {}
var _scanned := false


func _init(folders: Array[String], registry: EvaluatorRegistry) -> void:
	_folders = folders
	_registry = registry


func list_packages() -> Array[ContentPackage]:
	if not _scanned:
		_scan()
	return _packages.duplicate()


func load_level(package_id: String, level_id: String) -> Result:
	var key := "%s/%s" % [package_id, level_id]
	if _levels.has(key):
		return Result.ok(_levels[key])
	var package := _find(package_id)
	if package == null:
		return Result.fail(&"package_not_found", "No está instalado el paquete %s." % package_id)
	var entry := package.find_level(level_id)
	if entry == null:
		return Result.fail(&"level_not_found", "El paquete %s no tiene el nivel %s." % [package_id, level_id])
	var raw := _read_json(package.location.path_join(entry.file))
	if not raw.is_ok():
		return raw
	var parsed := Level.parse(raw.value, package, entry, _registry)
	if not parsed.is_ok():
		problems.append(parsed.message)
		return parsed
	var level: Level = parsed.value
	level.location = package.location
	_levels[key] = level
	return parsed


func refresh() -> void:
	_scanned = false
	_packages.clear()
	_levels.clear()
	problems.clear()


func _find(package_id: String) -> ContentPackage:
	for package in list_packages():
		if package.id == package_id:
			return package
	return null


func _scan() -> void:
	_scanned = true
	for folder in _folders:
		var directory := DirAccess.open(folder)
		if directory == null:
			continue
		var names := Array(directory.get_directories()).filter(func(name: String) -> bool: return not name.begins_with("."))
		names.sort()
		for name: String in names:
			var location := folder.path_join(name)
			var raw := _read_json(location.path_join(MANIFEST))
			if not raw.is_ok():
				problems.append(raw.message)
				continue
			var parsed := ContentPackage.parse(raw.value)
			if not parsed.is_ok():
				problems.append(parsed.message)
				continue
			var package: ContentPackage = parsed.value
			if _packages.any(func(known: ContentPackage) -> bool: return known.id == package.id):
				continue
			package.location = location
			package.bundled = folder.begins_with("res://")
			_packages.append(package)
	_packages.sort_custom(func(a: ContentPackage, b: ContentPackage) -> bool:
		var area_a := ContentPackage.AREAS.find(a.area)
		var area_b := ContentPackage.AREAS.find(b.area)
		if area_a != area_b:
			return area_a < area_b
		return a.number < b.number if a.number != b.number else a.id < b.id)


static func _read_json(path: String) -> Result:
	if not FileAccess.file_exists(path):
		return Result.fail(&"file_not_found", "No existe %s." % path)
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return Result.fail(&"invalid_json", "%s no es un JSON válido (línea %d: %s)." % [
			path, json.get_error_line(), json.get_error_message()])
	return Result.ok(json.data)

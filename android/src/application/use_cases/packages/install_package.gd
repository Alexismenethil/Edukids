class_name InstallPackage
extends RefCounted
## Caso de uso: instala un paquete descargado o copiado por USB (RF-07, RF-19) con el flujo
## verificado de la arquitectura: el SHA-256 del archivo (si viene del catálogo), solo rutas y
## extensiones permitidas, espacio suficiente, la lista de SHA-256 de cada archivo, el manifiesto
## válido y compatible, y cada nivel que se pueda jugar. Recién entonces lo descomprime en una
## carpeta temporal, lo mueve a su lugar y lo registra. Nunca deja un paquete a medias.

var _files: PackageFiles
var _store: PackageStore
var _packages: PackageRepository
var _registry: EvaluatorRegistry
var _app_version := ""


func _init(files: PackageFiles, store: PackageStore, packages: PackageRepository, registry: EvaluatorRegistry,
		app_version: String) -> void:
	_files = files
	_store = store
	_packages = packages
	_registry = registry
	_app_version = app_version


## Instala el ZIP de `archive_path`. `expected_sha256` es el del catálogo (vacío al importar por
## USB). Devuelve Result con un InstallResponse, o el motivo del rechazo para el docente.
func execute(archive_path: String, expected_sha256: String = "") -> Result:
	var archive_sha := _files.archive_sha256(archive_path)
	if not expected_sha256.is_empty() and archive_sha != expected_sha256.to_lower():
		return Result.fail(&"archive_damaged", "El paquete llegó dañado (su SHA-256 no coincide con el del catálogo). Vuelve a descargarlo.")
	var inspected := _files.inspect(archive_path)
	if not inspected.is_ok():
		return inspected
	var contents: Dictionary = inspected.value
	var sizes := {}
	var hashes := {}
	for path: String in contents:
		sizes[path] = int(contents[path].get("size", 0))
		if not path.ends_with("/"):
			hashes[path] = str(contents[path].get("sha256", ""))
	var checked := PackageRules.check_entries(sizes)
	if not checked.is_ok():
		return checked
	var unpacked := int(checked.value)
	var needed := PackageRules.required_space(unpacked)
	var free := _files.free_space()
	if free < needed:
		return Result.fail(&"no_space", "No hay espacio suficiente: faltan %s MB. Libera espacio en la tablet y vuelve a intentarlo." % PackageRules.megabytes(needed - free))
	var listed := _files.read_text(archive_path, PackageRules.CHECKSUMS)
	if not listed.is_ok():
		return listed
	var sums := PackageRules.parse_checksums(listed.value)
	if not sums.is_ok():
		return sums
	var verified := PackageRules.check_sums(sums.value, hashes)
	if not verified.is_ok():
		return verified
	var manifest := _read_json(archive_path, PackageRules.MANIFEST)
	if not manifest.is_ok():
		return manifest
	var parsed := ContentPackage.parse(manifest.value)
	if not parsed.is_ok():
		return parsed
	var package: ContentPackage = parsed.value
	var compatible := PackageRules.check_app_version(package.min_app_version, _app_version)
	if not compatible.is_ok():
		return compatible
	var version := SemanticVersion.parse(package.version)
	if not version.is_ok():
		return version
	for entry in package.levels:
		if not hashes.has(entry.file):
			return Result.fail(&"level_missing", "Falta el archivo del nivel %s (%s)." % [entry.id, entry.file])
		var raw := _read_json(archive_path, entry.file)
		if not raw.is_ok():
			return raw
		var level := Level.parse(raw.value, package, entry, _registry)
		if not level.is_ok():
			return Result.fail(&"level_invalid", level.message)
	var response := InstallResponse.new()
	response.package_id = package.id
	response.title = package.title
	response.version = package.version
	response.level_count = package.levels.size()
	var current := _current(package.id)
	if current:
		response.previous_version = current.version
		var installed := SemanticVersion.parse(current.version)
		if installed.is_ok():
			var order := (version.value as SemanticVersion).compare(installed.value)
			if order < 0:
				return Result.fail(&"older_version", "La tablet ya tiene la versión %s de «%s», más nueva que la %s." % [
					current.version, current.title, package.version])
			if order == 0:
				response.outcome = InstallResponse.UNCHANGED
				return Result.ok(response)
		response.outcome = InstallResponse.UPDATED
	var placed := _files.install(package.id, archive_path, PackedStringArray(contents.keys()))
	if not placed.is_ok():
		return placed
	_store.refresh()
	var registered := _register(package.id, unpacked, archive_sha)
	if not registered.is_ok():
		return registered
	return Result.ok(response)


func _current(package_id: String) -> ContentPackage:
	for package in _store.list_packages():
		if package.id == package_id:
			return package
	return null


## Registra el paquete recién instalado (ya leído desde su carpeta) con sus niveles.
func _register(package_id: String, size_bytes: int, sha256: String) -> Result:
	var package := _current(package_id)
	if package == null:
		return Result.fail(&"install_failed", "El paquete se copió pero no se pudo leer desde su carpeta.")
	var levels: Array[Level] = []
	for entry in package.levels:
		var loaded := _store.load_level(package.id, entry.id)
		if not loaded.is_ok():
			return loaded
		levels.append(loaded.value)
	return _packages.save_package(package, levels, size_bytes, sha256)


func _read_json(archive_path: String, entry: String) -> Result:
	var text := _files.read_text(archive_path, entry)
	if not text.is_ok():
		return text
	var json := JSON.new()
	if json.parse(text.value) != OK:
		return Result.fail(&"invalid_json", "«%s» no es un JSON válido (línea %d)." % [entry, json.get_error_line()])
	return Result.ok(json.data)

class_name FakePackageFiles
extends PackageFiles
## Archivos de paquetes de prueba: cada «ZIP» es un diccionario { ruta: texto } en memoria. Al
## instalar, el paquete aparece en el FakePackageStore como si se hubiera copiado a su carpeta.

var archives := {}
var space := 500 * 1024 * 1024
var installed: Array[String] = []
var candidates: Array[Dictionary] = []
var _store: FakePackageStore


func _init(store: FakePackageStore) -> void:
	_store = store


func add_archive(path: String, files: Dictionary) -> void:
	archives[path] = files


func inspect(archive_path: String) -> Result:
	if not archives.has(archive_path):
		return Result.fail(&"archive_unreadable", "No se pudo abrir «%s»." % archive_path)
	var contents := {}
	for path: String in archives[archive_path]:
		var text := String(archives[archive_path][path])
		contents[path] = {"size": text.to_utf8_buffer().size(), "sha256": PackageBuilder.sha256(text)}
	return Result.ok(contents)


func read_text(archive_path: String, entry: String) -> Result:
	var files: Dictionary = archives.get(archive_path, {})
	if not files.has(entry):
		return Result.fail(&"file_not_found", "El paquete no tiene «%s»." % entry)
	return Result.ok(String(files[entry]))


func archive_sha256(archive_path: String) -> String:
	return PackageBuilder.sha256(JSON.stringify(archives.get(archive_path, {})))


func free_space() -> int:
	return space


func install(package_id: String, archive_path: String, _entries: PackedStringArray) -> Result:
	var files: Dictionary = archives[archive_path]
	var levels := {}
	var manifest: Dictionary = JSON.parse_string(files["manifest.json"])
	for level: Dictionary in manifest["levels"]:
		levels[level["id"]] = JSON.parse_string(files[level["file"]])
	_store.add_raw(manifest, levels)
	installed.append(package_id)
	return Result.ok("user://packages/%s" % package_id)


func import_candidates() -> Array[Dictionary]:
	return candidates

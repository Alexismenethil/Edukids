class_name ZipPackageFiles
extends PackageFiles
## Adaptador de salida: lee los paquetes ZIP con ZIPReader (sin descomprimirlos), calcula sus
## SHA-256 y los instala en user://packages/<id>. Primero descomprime en una carpeta temporal y
## recién al final la mueve a su lugar, así nunca queda un paquete a medias.

const TEMP := ".tmp"
const CHUNK := 1024 * 1024

var _install_root := ""
var _import_folders: Array[String] = []


## `install_root`: dónde quedan los paquetes instalados. `import_folders`: dónde buscar los .zip
## copiados por USB o por cable.
func _init(install_root: String, import_folders: Array[String] = []) -> void:
	_install_root = install_root
	_import_folders = import_folders


func inspect(archive_path: String) -> Result:
	var reader := ZIPReader.new()
	if not FileAccess.file_exists(archive_path) or reader.open(archive_path) != OK:
		return Result.fail(&"archive_unreadable", "No se pudo abrir «%s»: no es un paquete ZIP válido." % archive_path.get_file())
	var contents := {}
	for entry in reader.get_files():
		if entry.ends_with("/"):
			contents[entry] = {"size": 0}
			continue
		var bytes := reader.read_file(entry)
		contents[entry] = {"size": bytes.size(), "sha256": _sha256(bytes)}
	reader.close()
	return Result.ok(contents)


func read_text(archive_path: String, entry: String) -> Result:
	var reader := ZIPReader.new()
	if reader.open(archive_path) != OK:
		return Result.fail(&"archive_unreadable", "No se pudo abrir «%s»." % archive_path.get_file())
	if not reader.file_exists(entry):
		reader.close()
		return Result.fail(&"file_not_found", "El paquete no tiene «%s»." % entry)
	var text := reader.read_file(entry).get_string_from_utf8()
	reader.close()
	return Result.ok(text)


func archive_sha256(archive_path: String) -> String:
	var file := FileAccess.open(archive_path, FileAccess.READ)
	if file == null:
		return ""
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	while file.get_position() < file.get_length():
		context.update(file.get_buffer(CHUNK))
	file.close()
	return context.finish().hex_encode()


func free_space() -> int:
	DirAccess.make_dir_recursive_absolute(_install_root)
	var directory := DirAccess.open(_install_root)
	return directory.get_space_left() if directory else 0


func install(package_id: String, archive_path: String, entries: PackedStringArray) -> Result:
	var reader := ZIPReader.new()
	if reader.open(archive_path) != OK:
		return Result.fail(&"archive_unreadable", "No se pudo abrir «%s»." % archive_path.get_file())
	var temp := _install_root.path_join(TEMP).path_join(package_id)
	_remove_tree(temp)
	DirAccess.make_dir_recursive_absolute(temp)
	for entry in entries:
		var target := temp.path_join(entry)
		if entry.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(target)
			continue
		DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file == null:
			reader.close()
			_remove_tree(temp)
			return Result.fail(&"install_failed", "No se pudo copiar «%s» (¿falta espacio?)." % entry)
		file.store_buffer(reader.read_file(entry))
		file.close()
	reader.close()
	var final := _install_root.path_join(package_id)
	_remove_tree(final)
	if DirAccess.rename_absolute(temp, final) != OK:
		_remove_tree(temp)
		return Result.fail(&"install_failed", "No se pudo mover el paquete a su carpeta.")
	return Result.ok(final)


func import_candidates() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for folder in _import_folders:
		var directory := DirAccess.open(folder)
		if directory == null:
			continue
		for name in directory.get_files():
			if name.get_extension().to_lower() != "zip":
				continue
			var path := folder.path_join(name)
			var file := FileAccess.open(path, FileAccess.READ)
			found.append({"path": path, "name": name, "size": file.get_length() if file else 0})
	return found


static func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()


## Borra una carpeta con todo lo que tiene (si existe).
static func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for name in directory.get_directories():
		_remove_tree(path.path_join(name))
	for name in directory.get_files():
		directory.remove(name)
	DirAccess.remove_absolute(path)

class_name ListImportFiles
extends RefCounted
## Caso de uso: los .zip que el docente copió a la tablet por USB o por cable, listos para
## importar (RF-19). Ordenados por nombre.

var _files: PackageFiles


func _init(files: PackageFiles) -> void:
	_files = files


func execute() -> Array[ImportFileResponse]:
	var found: Array[ImportFileResponse] = []
	for candidate in _files.import_candidates():
		var file := ImportFileResponse.new()
		file.path = str(candidate.get("path", ""))
		file.name = str(candidate.get("name", file.path.get_file()))
		file.size_bytes = int(candidate.get("size", 0))
		found.append(file)
	found.sort_custom(func(a: ImportFileResponse, b: ImportFileResponse) -> bool: return a.name < b.name)
	return found

class_name TestDatabase
extends RefCounted
## Bases SQLite temporales para las pruebas de integración.


static func path_for(suite_name: String) -> String:
	return "user://test_%s.db" % suite_name


## Borra la base y sus archivos auxiliares (WAL y memoria compartida).
static func remove(path: String) -> void:
	for suffix in ["", "-wal", "-shm", "-journal"]:
		var file := ProjectSettings.globalize_path(path + suffix)
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)

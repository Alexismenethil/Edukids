class_name ListPackages
extends RefCounted
## Caso de uso: los paquetes de la tablet (los del juego y los instalados) con lo que el docente
## habilitó para una sección (RF-09). Ordenados por área y número de módulo.

var _store: PackageStore
var _access: PackageAccessRepository


func _init(store: PackageStore, access: PackageAccessRepository) -> void:
	_store = store
	_access = access


func execute(section_id: String) -> Array[PackageRowResponse]:
	var saved := _access.access_of(section_id)
	var rows: Array[PackageRowResponse] = []
	for package in _store.list_packages():
		var access := PackageRules.access_for(package, saved)
		var row := PackageRowResponse.new()
		row.id = package.id
		row.title = package.title
		row.area = package.area
		row.kind = package.kind
		row.number = package.number
		row.chapter = package.chapter
		row.stop = package.stop
		row.version = package.version
		row.bundled = package.bundled
		row.level_count = package.levels.size()
		row.has_final = package.final_level() != null
		row.enabled = access["enabled"]
		row.final_open = access["final_open"] and row.has_final
		rows.append(row)
	return rows

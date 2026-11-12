class_name SetPackageAccess
extends RefCounted
## Caso de uso: el docente habilita o deshabilita un paquete para una sección y puede abrir su
## desafío final antes de que terminen la práctica (RF-09, RN-18).

var _store: PackageStore
var _access: PackageAccessRepository


func _init(store: PackageStore, access: PackageAccessRepository) -> void:
	_store = store
	_access = access


func execute(package_id: String, section_id: String, enabled: bool, final_open: bool) -> Result:
	var package: ContentPackage = null
	for known in _store.list_packages():
		if known.id == package_id:
			package = known
	if package == null:
		return Result.fail(&"package_not_found", "Ese paquete ya no está en la tablet.")
	if section_id.is_empty():
		return Result.fail(&"section_required", "Elige una sección.")
	return _access.save_access(package_id, section_id, enabled, final_open and enabled and package.final_level() != null)

class_name InMemoryPackageAccessRepository
extends PackageAccessRepository
## Adaptador de respaldo: recuerda la habilitación por sección mientras el juego está abierto.

var _access := {}


func access_of(section_id: String) -> Dictionary:
	return (_access.get(section_id, {}) as Dictionary).duplicate(true)


func save_access(package_id: String, section_id: String, enabled: bool, final_open: bool) -> Result:
	if not _access.has(section_id):
		_access[section_id] = {}
	_access[section_id][package_id] = {"enabled": enabled, "final_open": final_open}
	return Result.ok()

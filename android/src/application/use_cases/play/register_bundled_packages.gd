class_name RegisterBundledPackages
extends RefCounted
## Caso de uso: registra los paquetes de práctica que vienen con el juego,
## validando cada nivel, para que los intentos sepan a qué nivel pertenecen.
## Los paquetes descargados o copiados por USB se registrarán al instalarse (Sprint 7).

var _store: PackageStore
var _packages: PackageRepository


func _init(store: PackageStore, packages: PackageRepository) -> void:
	_store = store
	_packages = packages


## Devuelve cuántos paquetes quedaron registrados.
func execute() -> int:
	var registered := 0
	for package in _store.list_packages():
		var levels: Array[Level] = []
		for entry in package.levels:
			var loaded := _store.load_level(package.id, entry.id)
			if loaded.is_ok():
				levels.append(loaded.value)
		if not levels.is_empty() and _packages.save_package(package, levels).is_ok():
			registered += 1
	return registered

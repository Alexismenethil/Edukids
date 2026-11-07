class_name InMemoryPackageRepository
extends PackageRepository
## Adaptador de respaldo: recuerda qué paquetes se registraron mientras el juego está abierto.

var packages := {}


func save_package(package: ContentPackage, levels: Array[Level]) -> Result:
	var keys: Array[String] = []
	for level in levels:
		keys.append(level.key())
	packages[package.id] = keys
	return Result.ok()

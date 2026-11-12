class_name InMemoryPackageRepository
extends PackageRepository
## Adaptador de respaldo: recuerda qué paquetes se registraron mientras el juego está abierto.

var packages := {}
## Tamaño y SHA-256 guardados de cada paquete instalado.
var installs := {}


func save_package(package: ContentPackage, levels: Array[Level], size_bytes: int = 0, sha256: String = "") -> Result:
	var keys: Array[String] = []
	for level in levels:
		keys.append(level.key())
	packages[package.id] = keys
	installs[package.id] = {"size": size_bytes, "sha256": sha256, "version": package.version}
	return Result.ok()

class_name FakePackageStore
extends PackageStore
## Almacén de paquetes de prueba: niveles armados con SampleItems, sin archivos.

var _packages: Array[ContentPackage] = []
var _files := {}
var _registry := EvaluatorRegistry.standard()


## Agrega un paquete con un nivel L01 hecho de los ítems indicados.
func add(area: String, items: Array, version: String = "1.0.0") -> ContentPackage:
	var raw := SampleItems.manifest(["L01"], area)
	raw["version"] = version
	var package: ContentPackage = ContentPackage.parse(raw).value
	package.location = "res://fake/%s" % package.id
	for index in _packages.size():
		if _packages[index].id == package.id:
			_packages.remove_at(index)
			break
	_packages.append(package)
	_files[package.id] = SampleItems.level_file(items)
	return package


func list_packages() -> Array[ContentPackage]:
	return _packages.duplicate()


func load_level(package_id: String, level_id: String) -> Result:
	for package in _packages:
		if package.id == package_id and package.find_level(level_id):
			var parsed := Level.parse(_files[package_id], package, package.find_level(level_id), _registry)
			if parsed.is_ok():
				(parsed.value as Level).location = package.location
			return parsed
	return Result.fail(&"level_not_found", "No existe %s/%s." % [package_id, level_id])

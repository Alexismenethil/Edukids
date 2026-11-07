@abstract class_name PackageStore
extends RefCounted
## Puerto: contenido de los paquetes disponibles en la tablet (manifiestos y niveles).


## Paquetes válidos, ordenados por área y número.
@abstract func list_packages() -> Array[ContentPackage]


## Lee y valida un nivel. Devuelve un Result con el Level.
@abstract func load_level(package_id: String, level_id: String) -> Result

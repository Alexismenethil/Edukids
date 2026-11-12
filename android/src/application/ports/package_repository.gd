@abstract class_name PackageRepository
extends RefCounted
## Puerto: registro de los paquetes instalados y de sus niveles, para que los intentos
## guarden a qué nivel pertenecen.


## Registra (o actualiza) un paquete con sus niveles ya validados. Los paquetes instalados guardan
## además cuánto ocupan y el SHA-256 de su archivo.
@abstract func save_package(package: ContentPackage, levels: Array[Level], size_bytes: int = 0, sha256: String = "") -> Result

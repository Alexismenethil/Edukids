@abstract class_name PackageRepository
extends RefCounted
## Puerto: registro de los paquetes instalados y de sus niveles, para que los intentos
## guarden a qué nivel pertenecen.


## Registra (o actualiza) un paquete con sus niveles ya validados.
@abstract func save_package(package: ContentPackage, levels: Array[Level]) -> Result

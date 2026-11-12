@abstract class_name PackageAccessRepository
extends RefCounted
## Puerto: qué paquetes habilitó el docente para cada sección y si abrió antes de tiempo sus
## desafíos finales (RF-09).


## Lo guardado para la sección: { id del paquete: {"enabled": bool, "final_open": bool} }.
## Los paquetes sin fila usan el valor por defecto de PackageRules.access_for.
@abstract func access_of(section_id: String) -> Dictionary


@abstract func save_access(package_id: String, section_id: String, enabled: bool, final_open: bool) -> Result

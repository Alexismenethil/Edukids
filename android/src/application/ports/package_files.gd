@abstract class_name PackageFiles
extends RefCounted
## Puerto: los archivos de los paquetes en la tablet. Lee un ZIP descargado o copiado por USB sin
## descomprimirlo, calcula sus SHA-256, mira el espacio libre e instala la carpeta del paquete.


## Contenido del ZIP: { ruta: {"size": bytes, "sha256": hash} }. Las carpetas terminan en «/» y no
## llevan hash. Falla si el archivo no existe o no es un ZIP.
@abstract func inspect(archive_path: String) -> Result


## Texto UTF-8 de un archivo del ZIP.
@abstract func read_text(archive_path: String, entry: String) -> Result


## SHA-256 del ZIP completo, en minúsculas (para compararlo con el del catálogo).
@abstract func archive_sha256(archive_path: String) -> String


## Espacio libre en la tablet, en bytes.
@abstract func free_space() -> int


## Descomprime las entradas en una carpeta temporal y la mueve a la carpeta definitiva del paquete
## (reemplaza la versión anterior). Devuelve la ruta donde quedó instalado.
@abstract func install(package_id: String, archive_path: String, entries: PackedStringArray) -> Result


## Archivos .zip listos para importar (copiados por USB o por cable): [{path, name, size}].
@abstract func import_candidates() -> Array[Dictionary]

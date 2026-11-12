class_name PackageRules
extends RefCounted
## Reglas de un paquete que llega a la tablet (formato v1, ADR-013): solo datos y medios, rutas
## limpias, tamaño máximo, la lista de SHA-256 de cada archivo y la compatibilidad con la versión
## de la aplicación. No lee archivos: recibe lo que el instalador encontró dentro del ZIP.

const ALLOWED_EXTENSIONS: Array[String] = ["json", "webp", "png", "ogg", "sha256", "txt"]
const MANIFEST := "manifest.json"
const CHECKSUMS := "checksums.sha256"
## 100 MB como máximo por paquete (50 MB es el objetivo).
const MAX_BYTES := 100 * 1024 * 1024
const MEGABYTE := 1024 * 1024


## Revisa las entradas del ZIP: { ruta: tamaño en bytes } (las carpetas terminan en «/»).
## Devuelve Result.ok() o el primer problema con un mensaje para el docente.
static func check_entries(entries: Dictionary) -> Result:
	if entries.is_empty():
		return Result.fail(&"package_empty", "El archivo no tiene contenido.")
	var total := 0
	for path: String in entries:
		var problem := path_problem(path)
		if not problem.is_empty():
			return Result.fail(&"forbidden_content", problem)
		total += int(entries[path])
	if not entries.has(MANIFEST):
		return Result.fail(&"manifest_missing", "El paquete no tiene «manifest.json».")
	if not entries.has(CHECKSUMS):
		return Result.fail(&"checksums_missing", "El paquete no tiene «checksums.sha256» para comprobar sus archivos.")
	if total > MAX_BYTES:
		return Result.fail(&"package_too_big", "El paquete pesa %d MB y el máximo es %d MB." % [ceili(float(total) / MEGABYTE), MAX_BYTES / MEGABYTE])
	return Result.ok(total)


## Problema de una ruta del ZIP, o "" si está permitida.
static func path_problem(path: String) -> String:
	if path.is_empty() or path.begins_with("/") or path.contains("\\") or path.contains(":"):
		return "La ruta «%s» no es relativa." % path
	if path != path.to_lower():
		return "La ruta «%s» tiene mayúsculas." % path
	var segments := path.trim_suffix("/").split("/")
	for segment in segments:
		if segment.is_empty() or segment == "." or segment == "..":
			return "La ruta «%s» no está permitida." % path
	if path.ends_with("/"):
		return ""
	var extension := path.get_extension()
	if not ALLOWED_EXTENSIONS.has(extension):
		return "El archivo «%s» no está permitido: un paquete solo trae datos e imágenes." % path
	return ""


## Lee «checksums.sha256» (una línea por archivo: «hash  ruta», como sha256sum).
## Devuelve { ruta: hash en minúsculas }.
static func parse_checksums(text: String) -> Result:
	var sums := {}
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		var space := line.find(" ")
		if space != 64:
			return Result.fail(&"checksums_invalid", "La línea «%s» de checksums.sha256 no tiene el formato esperado." % line)
		var digest := line.substr(0, 64).to_lower()
		if not digest.is_valid_hex_number():
			return Result.fail(&"checksums_invalid", "La línea «%s» de checksums.sha256 no tiene un SHA-256." % line)
		var path := line.substr(space).strip_edges().trim_prefix("*")
		sums[path] = digest
	if sums.is_empty():
		return Result.fail(&"checksums_invalid", "checksums.sha256 está vacío.")
	return Result.ok(sums)


## Compara el SHA-256 de cada archivo con la lista. `actual` es { ruta: hash } de los archivos
## del ZIP (sin carpetas). Todo archivo, salvo la propia lista, debe estar en ella y coincidir.
static func check_sums(expected: Dictionary, actual: Dictionary) -> Result:
	for path: String in actual:
		if path == CHECKSUMS:
			continue
		if not expected.has(path):
			return Result.fail(&"checksum_missing", "El archivo «%s» no figura en checksums.sha256." % path)
		if String(expected[path]) != String(actual[path]).to_lower():
			return Result.fail(&"checksum_mismatch", "El archivo «%s» está dañado (su SHA-256 no coincide)." % path)
	for path: String in expected:
		if not actual.has(path):
			return Result.fail(&"checksum_missing", "Falta el archivo «%s» que figura en checksums.sha256." % path)
	return Result.ok()


## ¿La aplicación (versión `app_version`) puede abrir un paquete que pide `min_app_version`?
static func check_app_version(min_app_version: String, app_version: String) -> Result:
	if min_app_version.is_empty():
		return Result.fail(&"manifest_invalid", "Al manifiesto le falta «min_app_version».")
	var needed := SemanticVersion.parse(min_app_version)
	if not needed.is_ok():
		return needed
	var current := SemanticVersion.parse(app_version)
	if not current.is_ok():
		return current
	if (current.value as SemanticVersion).compare(needed.value) < 0:
		return Result.fail(&"app_too_old", "Este paquete necesita EduKids %s o posterior (la tablet tiene la %s)." % [min_app_version, app_version])
	return Result.ok()


## Espacio que hace falta para instalar: el paquete descomprimido más un margen de 10 MB.
static func required_space(unpacked_bytes: int) -> int:
	return unpacked_bytes + 10 * MEGABYTE


## Megabytes con un decimal, para los mensajes («faltan 12,5 MB»).
static func megabytes(bytes: int) -> String:
	return ("%.1f" % (float(bytes) / MEGABYTE)).replace(".", ",")


## Acceso de una sección a un paquete (RF-09): lo que guardó el docente o, si no guardó nada, el
## valor por defecto: los paquetes del juego vienen habilitados y los instalados esperan a que el
## docente los habilite. El desafío final solo se abre antes de tiempo si el docente lo pidió.
static func access_for(package: ContentPackage, saved: Dictionary) -> Dictionary:
	var stored: Dictionary = saved.get(package.id, {})
	return {
		"enabled": bool(stored.get("enabled", package.bundled)),
		"final_open": bool(stored.get("final_open", false)),
	}

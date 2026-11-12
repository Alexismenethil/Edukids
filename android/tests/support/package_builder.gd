class_name PackageBuilder
extends RefCounted
## Arma los archivos de un paquete de prueba (formato v1) con su checksums.sha256, y si se pide,
## lo guarda como ZIP de verdad (ZIPPacker).

var id := "chl-K7M3QX-0001"
var kind := "challenge"
var version := "1.0.0"
var min_app_version := "0.1.0"
var area := "math"
## Archivos extra { ruta: texto } (se suman a la lista de SHA-256 salvo que `unlisted` los nombre).
var extra := {}
var unlisted: Array[String] = []
## Rutas cuyo contenido se cambia después de calcular la lista (archivo dañado).
var tampered: Array[String] = []
var items: Array = []


func _init() -> void:
	items = [SampleItems.multiple_choice("q1"), SampleItems.true_false("q2")]


func manifest() -> Dictionary:
	return {
		"format_version": "1.0", "id": id, "kind": kind, "title": "Reto de fracciones", "area": area, "grade": 6,
		"number": 1, "chapter": "sierra", "stop": "huamanga", "version": version, "min_app_version": min_app_version,
		"author": {"type": "teacher", "teacher_code": "K7M3QX"}, "created_at": "2026-11-12T00:00:00Z",
		"competencies": ["MAT.CANTIDAD"],
		"levels": [{"id": "L01", "kind": "short", "mechanic": "classic", "file": "levels/l01.json", "estimated_minutes": 4},
			{"id": "FINAL", "kind": "final", "mechanic": "classic", "file": "levels/final.json", "estimated_minutes": 10}],
	}


## { ruta: texto } con el manifiesto, los niveles, los extras y checksums.sha256.
func files() -> Dictionary:
	var result := {
		"manifest.json": JSON.stringify(manifest()),
		"levels/l01.json": JSON.stringify(SampleItems.level_file(items, "L01")),
		"levels/final.json": JSON.stringify(SampleItems.level_file(items, "FINAL")),
	}
	result.merge(extra)
	var lines: Array[String] = []
	for path: String in result:
		if not unlisted.has(path):
			lines.append("%s  %s" % [sha256(result[path]), path])
	for path in tampered:
		result[path] = String(result[path]) + " "
	result["checksums.sha256"] = "\n".join(lines) + "\n"
	return result


static func sha256(text: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(text.to_utf8_buffer())
	return context.finish().hex_encode()


## Guarda el paquete como ZIP en `path` (con una carpeta «levels/» propia).
func write_zip(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var packer := ZIPPacker.new()
	packer.open(path)
	for entry: String in files():
		packer.start_file(entry)
		packer.write_file(String(files()[entry]).to_utf8_buffer())
		packer.close_file()
	packer.close()

class_name DemoPackages
extends RefCounted
## Paquete de ejemplo para la demostración del modo docente (--demo-packages): un módulo 2 de
## Matemática que abre la parada de Quinua en el mapa. Se arma como un ZIP de verdad, con su lista
## de SHA-256, y se deja en la carpeta de importación. Su contenido es solo de muestra.

const FILE_NAME := "mod-math-6-02-1.0.0.zip"
const PACKAGE_ID := "mod-math-6-02"


## Escribe el ZIP en `folder` y devuelve su ruta.
static func write_sample(folder: String) -> String:
	DirAccess.make_dir_recursive_absolute(folder)
	var files := {
		"manifest.json": JSON.stringify(_manifest(), "  "),
		"levels/l01.json": JSON.stringify(_level("L01", "Proporciones en la pampa", [_lemons(), _potatoes(), _weavers()]), "  "),
		"levels/final.json": JSON.stringify(_level("FINAL", "Desafío de Quinua", [_lemons(), _potatoes(), _weavers()]), "  "),
		"credits.txt": "Paquete de muestra de EduKids para probar la importación por USB.\n",
	}
	var lines: Array[String] = []
	for path: String in files:
		lines.append("%s  %s" % [_sha256(files[path]), path])
	files["checksums.sha256"] = "\n".join(lines) + "\n"
	var path := folder.path_join(FILE_NAME)
	var packer := ZIPPacker.new()
	packer.open(path)
	for entry: String in files:
		packer.start_file(entry)
		packer.write_file(String(files[entry]).to_utf8_buffer())
		packer.close_file()
	packer.close()
	return path


static func _manifest() -> Dictionary:
	return {
		"format_version": "1.0", "id": PACKAGE_ID, "kind": "module", "title": "Módulo 2 · Proporciones en Quinua",
		"area": "math", "grade": 6, "number": 2, "chapter": "sierra", "stop": "quinua", "version": "1.0.0",
		"min_app_version": "0.1.0", "author": {"type": "official"}, "created_at": "2026-11-12T00:00:00-05:00",
		"competencies": ["MAT.REGULARIDAD"],
		"levels": [
			{"id": "L01", "kind": "short", "mechanic": "chase", "file": "levels/l01.json", "estimated_minutes": 4,
				"lives": 3, "danger": {"start": 2, "max": 4}},
			{"id": "FINAL", "kind": "final", "mechanic": "classic", "file": "levels/final.json", "estimated_minutes": 8,
				"max_attempts": 2},
		],
	}


static func _level(level_id: String, title: String, items: Array) -> Dictionary:
	var numbered: Array = []
	for i in items.size():
		var item: Dictionary = items[i].duplicate(true)
		item["id"] = "MAT02-%s-%02d" % [level_id, i + 1]
		numbered.append(item)
	return {"id": level_id, "title": title, "guide_intro": ["En Quinua todo va en proporción: ¡a resolver!"], "items": numbered}


static func _metadata(seconds: int) -> Dictionary:
	return {"competency": "MAT.REGULARIDAD", "capacity": "Usa estrategias y procedimientos para encontrar equivalencias",
		"pisa": {"category": "change_relationships", "process": "employ"}, "difficulty": 1, "estimated_seconds": seconds}


static func _lemons() -> Dictionary:
	return {"type": "numeric", "prompt": "Para 3 jarras de limonada se usan 2 kg de limones. ¿Cuántos kilos se usan para 12 jarras?",
		"answer": 8, "tolerance": 0, "unit": "kg", "accepted_formats": ["decimal"],
		"feedback": {"correct": "¡Bien! 12 jarras son 4 veces 3 jarras: 4 × 2 = 8 kg.", "incorrect": "¿Cuántas veces cabe 3 en 12? Multiplica los kilos por ese número."},
		"metadata": _metadata(60)}


static func _potatoes() -> Dictionary:
	return {"type": "multiple_choice", "prompt": "Una receta lleva 2 papas por cada 5 personas. ¿Cuántas papas hacen falta para 20 personas?",
		"options": [{"id": "a", "text": "8", "correct": true}, {"id": "b", "text": "10", "feedback": "20 personas son 4 grupos de 5."},
			{"id": "c", "text": "4"}, {"id": "d", "text": "40"}],
		"feedback": {"correct": "¡Exacto! 4 grupos de 5 personas: 4 × 2 = 8 papas.", "incorrect": "Cuenta cuántos grupos de 5 personas hay en 20."},
		"metadata": _metadata(45)}


static func _weavers() -> Dictionary:
	return {"type": "true_false", "prompt": "Decide si cada afirmación es verdadera o falsa.",
		"statements": [{"id": "s1", "text": "Si 4 cuadernos cuestan S/ 10, entonces 8 cuadernos cuestan S/ 20.", "answer": true},
			{"id": "s2", "text": "Si 2 tejedoras hacen una manta en 6 días, 4 tejedoras la hacen en 12 días.", "answer": false,
				"feedback": "Con más tejedoras se termina antes: 4 tejedoras tardarían 3 días."}],
		"feedback": {"correct": "¡Muy bien! Distingues cuándo crecen juntas las cantidades.", "incorrect": "Piensa: ¿más tejedoras terminan antes o después?"},
		"metadata": _metadata(60)}


static func _sha256(text: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(text.to_utf8_buffer())
	return context.finish().hex_encode()

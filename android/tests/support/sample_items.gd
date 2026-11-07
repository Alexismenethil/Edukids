class_name SampleItems
extends RefCounted
## Ítems de prueba escritos como en un archivo de nivel (formato de paquete v1).


static func feedback() -> Dictionary:
	return {"correct": "¡Bien!", "incorrect": "Revisa otra vez."}


static func multiple_choice(item_id: String = "mc", hint: String = "") -> Dictionary:
	return {
		"id": item_id, "type": "multiple_choice", "prompt": "¿Cuánto vale el 5 en 1 254 300?",
		"options": [
			{"id": "a", "text": "5 000", "feedback": "Fíjate en la posición."},
			{"id": "b", "text": "50 000", "correct": true},
			{"id": "c", "text": "500"},
		],
		"feedback": feedback(), "hint": hint, "metadata": {"difficulty": 1},
	}


static func multi_select(item_id: String = "ms") -> Dictionary:
	return {
		"id": item_id, "type": "multi_select", "prompt": "Marca los múltiplos de 3.",
		"options": [
			{"id": "a", "text": "9", "correct": true},
			{"id": "b", "text": "14", "feedback": "14 ÷ 3 no es exacto."},
			{"id": "c", "text": "21", "correct": true},
			{"id": "d", "text": "25"},
		],
		"feedback": feedback(),
	}


static func true_false(item_id: String = "tf") -> Dictionary:
	return {
		"id": item_id, "type": "true_false", "prompt": "Decide si es verdadero o falso.",
		"statements": [
			{"id": "s1", "text": "El agua hierve a 100 °C a nivel del mar.", "answer": true},
			{"id": "s2", "text": "El hielo es un gas.", "answer": false, "feedback": "El hielo es sólido."},
		],
		"feedback": feedback(),
	}


static func ordering(item_id: String = "or") -> Dictionary:
	return {
		"id": item_id, "type": "ordering", "prompt": "Ordena de menor a mayor.",
		"elements": [{"id": "x", "text": "1/2"}, {"id": "y", "text": "0,1"}, {"id": "z", "text": "3"}],
		"correct_order": ["y", "x", "z"],
		"feedback": feedback(),
	}


static func matching(item_id: String = "ma") -> Dictionary:
	return {
		"id": item_id, "type": "matching", "prompt": "Une cada fracción con su decimal.",
		"left": [{"id": "l1", "text": "1/2"}, {"id": "l2", "text": "1/4"}],
		"right": [{"id": "r1", "text": "0,25"}, {"id": "r2", "text": "0,5"}, {"id": "r3", "text": "0,75"}],
		"pairs": [["l1", "r2"], {"left": "l2", "right": "r1"}],
		"feedback": feedback(),
	}


static func classification(item_id: String = "cl") -> Dictionary:
	return {
		"id": item_id, "type": "classification", "prompt": "Clasifica los números.",
		"groups": [{"id": "even", "label": "Pares"}, {"id": "odd", "label": "Impares"}],
		"elements": [
			{"id": "n2", "text": "2", "group": "even"},
			{"id": "n7", "text": "7", "group": "odd"},
			{"id": "n10", "text": "10", "group": "even"},
		],
		"feedback": feedback(),
	}


static func fill_blank(item_id: String = "fb") -> Dictionary:
	return {
		"id": item_id, "type": "fill_blank", "prompt": "Completa con el conector.",
		"text": "Quería salir, {{1}} llovía. Me quedé {{2}} estaba cansada.",
		"blanks": [
			{"id": "1", "accepted": ["pero"], "options": ["pero", "porque", "y"]},
			{"id": "2", "accepted": ["porque"]},
		],
		"feedback": feedback(),
	}


static func numeric(item_id: String = "nu", formats: Array = ["decimal", "fraction"]) -> Dictionary:
	return {
		"id": item_id, "type": "numeric", "prompt": "¿Qué parte de la torta comió?",
		"answer": 0.5, "tolerance": 0, "accepted_formats": formats,
		"feedback": feedback(),
	}


static func reading_unit(item_id: String = "ru") -> Dictionary:
	return {
		"id": item_id, "type": "reading_unit", "prompt": "Lee el texto y responde.",
		"stimulus": {"type": "text", "title": "La feria", "content": "Primer párrafo.\n\nSegundo párrafo."},
		"items": [multiple_choice(item_id + "-1"), true_false(item_id + "-2")],
	}


static func parse(raw: Dictionary) -> Item:
	return EvaluatorRegistry.standard().parse_item(raw).value


static func manifest(level_ids: Array = ["L01"], area: String = "math") -> Dictionary:
	var raw := {
		"format_version": "1.0", "id": "mod-%s-6-00" % area, "kind": "module", "title": "Muestra",
		"area": area, "grade": 6, "number": 0, "chapter": "sierra", "version": "1.0.0", "levels": [],
	}
	for level_id: String in level_ids:
		raw["levels"].append({"id": level_id, "kind": "short", "mechanic": "classic",
			"file": "levels/%s.json" % level_id.to_lower(), "estimated_minutes": 4})
	return raw


static func level_file(items: Array, level_id: String = "L01") -> Dictionary:
	return {"id": level_id, "title": "Nivel de prueba", "guide_intro": ["¡Hola!"], "items": items}


static func level(items: Array, level_id: String = "L01") -> Level:
	var package: ContentPackage = ContentPackage.parse(manifest([level_id])).value
	var parsed := Level.parse(level_file(items, level_id), package, package.find_level(level_id),
		EvaluatorRegistry.standard())
	return parsed.value

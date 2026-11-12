class_name LevelRecords
extends RefCounted
## Lo que un estudiante ya hizo en cada nivel, a partir de sus intentos: si lo completó,
## sus mejores estrellas y calificación, los intentos del desafío final y si quedó a medias.

const GRADE_ORDER: Array[String] = ["C", "B", "A", "AD"]

## «paquete/nivel» → {"completed", "stars", "grade", "finals", "open", "game_overs"}.
var _by_level := {}


static func of(attempts: Array[Attempt]) -> LevelRecords:
	var records := LevelRecords.new()
	for attempt in attempts:
		records._add(attempt)
	return records


func completed(level_key: String) -> bool:
	return _record(level_key)["completed"]


func best_stars(level_key: String) -> int:
	return _record(level_key)["stars"]


func best_grade(level_key: String) -> String:
	return _record(level_key)["grade"]


## Intentos terminados de un desafío final.
func finals_used(level_key: String) -> int:
	return _record(level_key)["finals"]


func in_progress(level_key: String) -> bool:
	return _record(level_key)["open"]


func game_overs(level_key: String) -> int:
	return _record(level_key)["game_overs"]


## Ids de los niveles del paquete que ya se completaron: id → true (para TrailRule).
func completed_ids(package: ContentPackage) -> Dictionary:
	var ids := {}
	for entry in package.levels:
		if completed(package.level_key(entry.id)):
			ids[entry.id] = true
	return ids


func _record(level_key: String) -> Dictionary:
	return _by_level.get(level_key, {"completed": false, "stars": 0, "grade": "", "finals": 0, "open": false, "game_overs": 0})


func _add(attempt: Attempt) -> void:
	var record := _record(attempt.level_key).duplicate()
	if attempt.is_open():
		record["open"] = true
	elif attempt.is_completed():
		record["completed"] = true
		record["open"] = false
		record["stars"] = maxi(record["stars"], attempt.stars)
		if attempt.kind == Attempt.FINAL:
			record["finals"] += 1
			if GRADE_ORDER.find(attempt.cneb_grade) > GRADE_ORDER.find(record["grade"]):
				record["grade"] = attempt.cneb_grade
	elif attempt.status == Attempt.GAME_OVER:
		record["game_overs"] += 1
	_by_level[attempt.level_key] = record

class_name ListLevels
extends RefCounted
## Caso de uso: niveles disponibles para el estudiante, con sus mejores estrellas y si
## dejó alguno a medias. Mientras llega el mapa (Sprint 5), los muestra el inicio del estudiante.

var _store: PackageStore
var _attempts: AttemptRepository


func _init(store: PackageStore, attempts: AttemptRepository) -> void:
	_store = store
	_attempts = attempts


func execute(student_id: String) -> Array[LevelCardResponse]:
	var cards: Array[LevelCardResponse] = []
	var best := _attempts.best_stars(student_id)
	for package in _store.list_packages():
		for entry in package.levels:
			if entry.kind == LevelEntry.FINAL:
				continue
			var loaded := _store.load_level(package.id, entry.id)
			if not loaded.is_ok():
				continue
			var level: Level = loaded.value
			var card := LevelCardResponse.new()
			card.package_id = package.id
			card.level_id = entry.id
			card.package_title = package.title
			card.title = level.title
			card.area = package.area
			card.kind = entry.kind
			card.mechanic = entry.mechanic
			card.estimated_minutes = entry.estimated_minutes
			card.question_count = level.question_count()
			card.best_stars = best.get(level.key(), 0)
			card.in_progress = _attempts.find_open_attempt(student_id, level.key()) != null
			cards.append(card)
	return cards

class_name GetChapterMap
extends RefCounted
## Caso de uso: el mapa de un capítulo. Cada parada muestra un sendero por área con sus niveles
## en orden (los de práctica primero y el desafío final al final), sus estrellas y si están
## abiertos (RN-01, RN-18 y RF-22). Solo aparecen los paquetes habilitados para la sección del
## estudiante, y el docente puede abrir antes un desafío final (RF-09). Las paradas sin paquetes
## aparecen con candado.

var _store: PackageStore
var _attempts: AttemptRepository
var _students: StudentRepository
var _access: PackageAccessRepository
var _saved := {}


func _init(store: PackageStore, attempts: AttemptRepository, students: StudentRepository = null,
		access: PackageAccessRepository = null) -> void:
	_store = store
	_attempts = attempts
	_students = students
	_access = access


func execute(student_id: String, chapter: StringName) -> ChapterMapResponse:
	var records := LevelRecords.of(_attempts.list_attempts(student_id))
	var response := ChapterMapResponse.new()
	response.chapter = chapter
	_saved = {}
	if _students and _access:
		var student := _students.find_student(student_id)
		if student:
			_saved = _access.access_of(student.section_id)
	var packages := _store.list_packages().filter(func(package: ContentPackage) -> bool:
		return package.chapter == chapter and package.kind == ContentPackage.MODULE and _enabled(package))
	packages.sort_custom(func(a: ContentPackage, b: ContentPackage) -> bool:
		return a.number < b.number if a.number != b.number else a.id < b.id)
	for stop_id in Chapter.stops_of(chapter):
		var stop := StopResponse.new()
		stop.id = stop_id
		for area in ContentPackage.AREAS:
			var trail := _trail(area, packages.filter(func(package: ContentPackage) -> bool:
				return package.stop == stop_id and package.area == area), records)
			if trail.nodes.is_empty():
				continue
			stop.trails.append(trail)
			stop.stars += trail.stars
			stop.max_stars += trail.max_stars
			for node in trail.nodes:
				if node.kind == LevelEntry.FINAL and node.state == TrailRule.DONE:
					stop.cords += 1
		stop.available = not stop.trails.is_empty()
		response.stops.append(stop)
		response.stars += stop.stars
		response.max_stars += stop.max_stars
	return response


## Sin repositorio de acceso (pruebas antiguas, vista previa) se muestran todos los paquetes.
func _enabled(package: ContentPackage) -> bool:
	return _access == null or PackageRules.access_for(package, _saved)["enabled"]


func _trail(area: StringName, packages: Array, records: LevelRecords) -> TrailResponse:
	var trail := TrailResponse.new()
	trail.area = area
	var practice: Array[TrailNodeResponse] = []
	var finals: Array[TrailNodeResponse] = []
	for package: ContentPackage in packages:
		var states := TrailRule.states(package.levels, records.completed_ids(package),
			_access != null and PackageRules.access_for(package, _saved)["final_open"])
		var previous_title := ""
		var entries := package.levels.duplicate()
		entries.sort_custom(func(a: LevelEntry, b: LevelEntry) -> bool: return a.position < b.position)
		for entry: LevelEntry in entries:
			var loaded := _store.load_level(package.id, entry.id)
			if not loaded.is_ok():
				continue
			var level: Level = loaded.value
			var node := TrailNodeResponse.new()
			node.package_id = package.id
			node.level_id = entry.id
			node.package_title = package.title
			node.title = level.title
			node.area = area
			node.kind = entry.kind
			node.mechanic = entry.mechanic
			node.question_count = level.question_count()
			node.estimated_minutes = entry.estimated_minutes
			node.lives = 0 if entry.is_final() else entry.lives
			node.state = states.get(entry.id, TrailRule.OPEN)
			node.best_stars = records.best_stars(level.key())
			node.in_progress = records.in_progress(level.key())
			if entry.is_final():
				node.best_grade = records.best_grade(level.key())
				node.max_attempts = entry.max_attempts
				node.attempts_left = TrailRule.attempts_left(entry, records.finals_used(level.key()))
				node.unlocked_by = package.title
				finals.append(node)
			else:
				node.unlocked_by = previous_title
				previous_title = level.title
				practice.append(node)
				trail.stars += node.best_stars
				trail.max_stars += 3
	trail.nodes.append_array(practice)
	trail.nodes.append_array(finals)
	return trail

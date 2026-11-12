extends GdUnitTestSuite
## Integración: las prácticas que vienen con el juego se leen y validan completas.

const BUNDLED := "res://content/packages"
const BROKEN := "user://test_packages_broken"


func _store(folders: Array[String] = [BUNDLED]) -> FolderPackageStore:
	return FolderPackageStore.new(folders, EvaluatorRegistry.standard())


func test_the_bundled_practices_are_valid() -> void:
	var store := _store()
	var packages := store.list_packages()
	var ids: Array = packages.map(func(package: ContentPackage) -> String: return package.id)
	assert_array(ids).is_equal([
		"mod-math-6-00", "mod-math-6-01", "mod-math-6-01-practica",
		"mod-language-6-00", "mod-language-6-01", "mod-language-6-01-practica",
		"mod-science-6-00", "mod-science-6-01", "mod-science-6-01-practica",
	])
	for package in packages:
		for entry in package.levels:
			var loaded := store.load_level(package.id, entry.id)
			assert_bool(loaded.is_ok()).override_failure_message(loaded.message).is_true()
			assert_int((loaded.value as Level).question_count()).is_between(5, 20)
	assert_array(store.problems).is_empty()


func test_the_bundled_modules_use_every_p1_item_type() -> void:
	var store := _store()
	var used := {}
	for package in store.list_packages():
		var level: Level = store.load_level(package.id, "L01").value
		for item in level.items:
			used[item.type] = true
			if item.type == ItemType.READING_UNIT:
				for question: Item in item.spec["items"]:
					used[question.type] = true
	for type in EvaluatorRegistry.standard().types():
		assert_bool(used.has(type)).override_failure_message("Falta el tipo %s" % type).is_true()


func test_levels_know_where_their_package_is() -> void:
	var level: Level = _store().load_level("mod-science-6-00", "L01").value
	assert_str(level.location).is_equal("res://content/packages/mod-science-6-00")
	assert_str(level.package_version).is_equal("1.0.0")


func test_the_huamanga_trails_follow_the_module_order() -> void:
	var map := GetChapterMap.new(_store(), InMemoryAttemptRepository.new()).execute("student", Chapter.SIERRA)
	var huamanga := map.stops[0]
	assert_bool(huamanga.available).is_true()
	assert_int(huamanga.trails.size()).is_equal(3)
	var math: Array = huamanga.trails[0].nodes.map(func(node: TrailNodeResponse) -> String:
		return "%s/%s" % [node.package_id, node.level_id])
	assert_array(math).is_equal([
		"mod-math-6-00/L01", "mod-math-6-01/L01", "mod-math-6-01/L02", "mod-math-6-01/L03",
		"mod-math-6-01-practica/L01", "mod-math-6-01/DF",
	])
	var mechanics: Array = huamanga.trails.map(func(trail: TrailResponse) -> String: return trail.nodes[1].mechanic)
	assert_array(mechanics).is_equal(["chase", "caiman", "bridge"])
	for stop in map.stops.slice(1):
		assert_bool(stop.available).is_false()
	for package_id in ["mod-math-6-00", "mod-language-6-00", "mod-science-6-00"]:
		var original: ContentPackage = _store().list_packages().filter(func(p: ContentPackage) -> bool: return p.id == package_id)[0]
		assert_str(original.version).is_equal("1.0.0")
		assert_int(original.levels.size()).is_equal(1)


func test_every_new_level_has_its_mechanic_and_a_final_challenge() -> void:
	var store := _store()
	for package_id in ["mod-math-6-01", "mod-language-6-01", "mod-science-6-01"]:
		var package: ContentPackage = store.list_packages().filter(func(p: ContentPackage) -> bool: return p.id == package_id)[0]
		var mechanics: Array = package.levels.map(func(entry: LevelEntry) -> String: return entry.mechanic)
		assert_array(mechanics).contains_exactly_in_any_order(["chase", "bridge", "caiman", "classic"])
		var final := package.find_level("DF")
		assert_bool(final.is_final()).is_true()
		var level: Level = store.load_level(package_id, "DF").value
		assert_int(level.question_count()).is_equal(12)


func test_fraction_table_answers_accept_equivalent_values() -> void:
	var level: Level = _store().load_level("mod-math-6-01-practica", "L01").value
	var unit: Item = level.items[0]
	var questions: Array = unit.spec["items"]
	var registry := EvaluatorRegistry.standard()
	assert_str(str(unit.spec["stimulus"]["type"])).is_equal("table")
	assert_bool(registry.evaluate(questions[0], "3/4").correct).is_true()
	assert_bool(registry.evaluate(questions[0], "6/8").correct).is_true()
	assert_bool(registry.evaluate(questions[0], "1/4").correct).is_false()
	assert_bool(registry.evaluate(questions[1], "b").correct).is_true()
	assert_bool(registry.evaluate(questions[1], "a").correct).is_false()
	assert_bool(registry.evaluate(questions[2], "14").correct).is_true()
	assert_bool(registry.evaluate(questions[2], "12").correct).is_false()
	assert_bool(registry.evaluate(level.items[2], "4").correct).is_true()
	assert_bool(registry.evaluate(level.items[4], "3/2").correct).is_true()


func test_previous_practice_attempt_resumes_with_new_challenges_installed() -> void:
	var attempts := InMemoryAttemptRepository.new()
	var sessions := InMemoryLevelSessionStore.new()
	var registry := EvaluatorRegistry.standard()
	var builder := StepBuilder.new(ScriptedRandom.new())
	var ids := SequentialIds.new()
	var clock := FakeClock.new()
	var first := StartLevel.new(_store(), attempts, sessions, registry, builder, ids, clock).execute(
		"student", "mod-math-6-00", "L01")
	assert_bool(first.is_ok()).override_failure_message(first.message).is_true()
	var started: LevelStartResponse = first.value
	var answer := SubmitAnswer.new(sessions, attempts, ids, clock).execute(started.attempt_id, "b")
	assert_bool(answer.is_ok()).is_true()
	var reopened := StartLevel.new(_store(), attempts, InMemoryLevelSessionStore.new(), registry, builder, ids, clock).execute(
		"student", "mod-math-6-00", "L01")
	assert_bool(reopened.is_ok()).override_failure_message(reopened.message).is_true()
	var resumed: LevelStartResponse = reopened.value
	assert_str(resumed.attempt_id).is_equal(started.attempt_id)
	assert_bool(resumed.resumed).is_true()
	assert_str(resumed.step.question_id).is_equal("MAT00-L01-02")


func test_broken_packages_are_skipped_and_reported() -> void:
	DirAccess.make_dir_recursive_absolute(BROKEN + "/roto")
	var file := FileAccess.open(BROKEN + "/roto/manifest.json", FileAccess.WRITE)
	file.store_string("{ no es json")
	file.close()
	var folders: Array[String] = [BROKEN, BUNDLED]
	var store := _store(folders)
	assert_int(store.list_packages().size()).is_equal(9)
	assert_int(store.problems.size()).is_equal(1)
	assert_str(store.load_level("mod-math-6-00", "L99").error).is_equal("level_not_found")
	assert_str(store.load_level("no-existe", "L01").error).is_equal("package_not_found")
	DirAccess.remove_absolute(BROKEN + "/roto/manifest.json")
	DirAccess.remove_absolute(BROKEN + "/roto")
	DirAccess.remove_absolute(BROKEN)

extends GdUnitTestSuite
## Integración: los módulos 0 que vienen con el juego se leen y validan completos.

const BUNDLED := "res://content/packages"
const BROKEN := "user://test_packages_broken"


func _store(folders: Array[String] = [BUNDLED]) -> FolderPackageStore:
	return FolderPackageStore.new(folders, EvaluatorRegistry.standard())


func test_the_three_bundled_modules_are_valid() -> void:
	var store := _store()
	var packages := store.list_packages()
	var ids: Array = packages.map(func(package: ContentPackage) -> String: return package.id)
	assert_array(ids).is_equal(["mod-math-6-00", "mod-language-6-00", "mod-science-6-00"])
	for package in packages:
		for entry in package.levels:
			var loaded := store.load_level(package.id, entry.id)
			assert_bool(loaded.is_ok()).override_failure_message(loaded.message).is_true()
			assert_int((loaded.value as Level).question_count()).is_equal(8)
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


func test_broken_packages_are_skipped_and_reported() -> void:
	DirAccess.make_dir_recursive_absolute(BROKEN + "/roto")
	var file := FileAccess.open(BROKEN + "/roto/manifest.json", FileAccess.WRITE)
	file.store_string("{ no es json")
	file.close()
	var folders: Array[String] = [BROKEN, BUNDLED]
	var store := _store(folders)
	assert_int(store.list_packages().size()).is_equal(3)
	assert_int(store.problems.size()).is_equal(1)
	assert_str(store.load_level("mod-math-6-00", "L99").error).is_equal("level_not_found")
	assert_str(store.load_level("no-existe", "L01").error).is_equal("package_not_found")
	DirAccess.remove_absolute(BROKEN + "/roto/manifest.json")
	DirAccess.remove_absolute(BROKEN + "/roto")
	DirAccess.remove_absolute(BROKEN)

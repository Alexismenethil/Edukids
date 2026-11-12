extends GdUnitTestSuite
## Instalar, listar, habilitar e importar paquetes (RF-07, RF-09 y RF-19), con el flujo verificado
## de la arquitectura: nada se instala a medias ni con archivos dañados o prohibidos.

const ZIP := "user://imports/chl-K7M3QX-0001-1.0.0.zip"

var _store: FakePackageStore
var _files: FakePackageFiles
var _packages: InMemoryPackageRepository
var _access: InMemoryPackageAccessRepository


func before_test() -> void:
	_store = FakePackageStore.new()
	_files = FakePackageFiles.new(_store)
	_packages = InMemoryPackageRepository.new()
	_access = InMemoryPackageAccessRepository.new()


func _install(builder: PackageBuilder, expected_sha := "", app_version := "0.1.0") -> Result:
	_files.add_archive(ZIP, builder.files())
	return InstallPackage.new(_files, _store, _packages, EvaluatorRegistry.standard(), app_version).execute(ZIP, expected_sha)


func test_a_valid_package_is_installed_registered_and_listed() -> void:
	var installed := _install(PackageBuilder.new())
	assert_bool(installed.is_ok()).override_failure_message(installed.message).is_true()
	var response: InstallResponse = installed.value
	assert_str(String(response.outcome)).is_equal(String(InstallResponse.INSTALLED))
	assert_int(response.level_count).is_equal(2)
	assert_array(_files.installed).contains_exactly(["chl-K7M3QX-0001"])
	assert_array(_packages.packages["chl-K7M3QX-0001"]).contains_exactly(["chl-K7M3QX-0001/L01", "chl-K7M3QX-0001/FINAL"])
	assert_int(int(_packages.installs["chl-K7M3QX-0001"]["size"])).is_greater(0)
	assert_str(str(_packages.installs["chl-K7M3QX-0001"]["sha256"])).has_length(64)


func test_a_package_damaged_in_the_download_is_rejected() -> void:
	var rejected := _install(PackageBuilder.new(), "0".repeat(64))
	assert_str(String(rejected.error)).is_equal("archive_damaged")
	assert_array(_files.installed).is_empty()


func test_a_file_that_does_not_match_its_checksum_is_rejected() -> void:
	var builder := PackageBuilder.new()
	builder.tampered = ["levels/l01.json"]
	assert_str(String(_install(builder).error)).is_equal("checksum_mismatch")
	assert_array(_files.installed).is_empty()


func test_code_or_unlisted_files_are_never_installed() -> void:
	var builder := PackageBuilder.new()
	builder.extra = {"tools/hack.gd": "extends Node"}
	assert_str(String(_install(builder).error)).is_equal("forbidden_content")
	var sneaky := PackageBuilder.new()
	sneaky.extra = {"images/extra.png": "png"}
	sneaky.unlisted = ["images/extra.png"]
	assert_str(String(_install(sneaky).error)).is_equal("checksum_missing")
	assert_array(_files.installed).is_empty()


func test_it_says_how_much_space_is_missing() -> void:
	_files.space = 1024
	var rejected := _install(PackageBuilder.new())
	assert_str(String(rejected.error)).is_equal("no_space")
	assert_str(rejected.message).contains("MB")


func test_a_package_for_a_newer_app_or_with_a_broken_level_is_rejected() -> void:
	var newer := PackageBuilder.new()
	newer.min_app_version = "9.0.0"
	assert_str(String(_install(newer).error)).is_equal("app_too_old")
	var broken := PackageBuilder.new()
	broken.items = [{"id": "q1", "type": "multiple_choice"}]
	assert_str(String(_install(broken).error)).is_equal("level_invalid")
	assert_array(_files.installed).is_empty()


func test_updates_replace_older_versions_and_never_go_back() -> void:
	assert_bool(_install(PackageBuilder.new()).is_ok()).is_true()
	var same := _install(PackageBuilder.new())
	assert_str(String((same.value as InstallResponse).outcome)).is_equal(String(InstallResponse.UNCHANGED))
	var newer := PackageBuilder.new()
	newer.version = "1.1.0"
	var updated := _install(newer)
	assert_str(String((updated.value as InstallResponse).outcome)).is_equal(String(InstallResponse.UPDATED))
	assert_str((updated.value as InstallResponse).previous_version).is_equal("1.0.0")
	var older := PackageBuilder.new()
	older.version = "0.9.0"
	assert_str(String(_install(older).error)).is_equal("older_version")


func test_installed_packages_wait_until_the_teacher_enables_them() -> void:
	_store.add("math", [SampleItems.true_false("q1")])
	_install(PackageBuilder.new())
	var rows := ListPackages.new(_store, _access).execute("sec-a")
	var by_id := {}
	for row in rows:
		by_id[row.id] = row
	assert_bool(by_id["mod-math-6-00"].enabled).is_true()
	assert_bool(by_id["mod-math-6-00"].bundled).is_true()
	assert_bool(by_id["chl-K7M3QX-0001"].enabled).is_false()
	assert_bool(by_id["chl-K7M3QX-0001"].has_final).is_true()
	var saved := SetPackageAccess.new(_store, _access).execute("chl-K7M3QX-0001", "sec-a", true, true)
	assert_bool(saved.is_ok()).is_true()
	var after := ListPackages.new(_store, _access).execute("sec-a").filter(func(row: PackageRowResponse) -> bool:
		return row.id == "chl-K7M3QX-0001")[0] as PackageRowResponse
	assert_bool(after.enabled).is_true()
	assert_bool(after.final_open).is_true()
	var other := ListPackages.new(_store, _access).execute("sec-b").filter(func(row: PackageRowResponse) -> bool:
		return row.id == "chl-K7M3QX-0001")[0] as PackageRowResponse
	assert_bool(other.enabled).is_false()


func test_disabling_a_package_also_closes_its_final_challenge() -> void:
	_install(PackageBuilder.new())
	var access := SetPackageAccess.new(_store, _access)
	access.execute("chl-K7M3QX-0001", "sec-a", false, true)
	assert_bool(_access.access_of("sec-a")["chl-K7M3QX-0001"]["final_open"]).is_false()
	assert_str(String(access.execute("nope", "sec-a", true, false).error)).is_equal("package_not_found")


func test_the_map_shows_only_what_the_section_has_enabled() -> void:
	_store.add_module("mod-math-6-01", "math", [{"id": "L01"}, {"id": "FINAL", "kind": "final"}], [SampleItems.true_false("q1")])
	var students := InMemoryStudentRepository.new()
	students.save_student(Student.new("stu-1", "sec-a", "Rosa Quispe", PinCredential.new("hash", "salt")))
	var map := GetChapterMap.new(_store, InMemoryAttemptRepository.new(), students, _access)
	assert_int(_trail_count(map.execute("stu-1", &"sierra"))).is_equal(1)
	_access.save_access("mod-math-6-01", "sec-a", false, false)
	assert_int(_trail_count(map.execute("stu-1", &"sierra"))).is_equal(0)
	_access.save_access("mod-math-6-01", "sec-a", true, true)
	var final := _node(map.execute("stu-1", &"sierra"), "FINAL")
	assert_str(String(final.state)).is_equal(String(TrailRule.OPEN))


func test_import_files_are_listed_by_name() -> void:
	_files.candidates = [{"path": "/sd/b.zip", "name": "b.zip", "size": 2048}, {"path": "/sd/a.zip", "name": "a.zip", "size": 10}]
	var found := ListImportFiles.new(_files).execute()
	assert_array(found.map(func(file: ImportFileResponse) -> String: return file.name)).contains_exactly(["a.zip", "b.zip"])
	assert_int(found[1].size_bytes).is_equal(2048)


func _trail_count(map: ChapterMapResponse) -> int:
	var count := 0
	for stop in map.stops:
		count += stop.trails.size()
	return count


func _node(map: ChapterMapResponse, level_id: String) -> TrailNodeResponse:
	for stop in map.stops:
		for trail in stop.trails:
			for node in trail.nodes:
				if node.level_id == level_id:
					return node
	return null

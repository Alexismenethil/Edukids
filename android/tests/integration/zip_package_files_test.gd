extends GdUnitTestSuite
## El instalador de verdad: un ZIP armado con ZIPPacker se revisa, se instala en su carpeta y el
## almacén de carpetas lo lee como cualquier otro paquete (RF-07 y RF-19).

const ROOT := "user://test_packages"
const IMPORTS := "user://test_imports"

var _files: ZipPackageFiles
var _store: FolderPackageStore


func before_test() -> void:
	_remove(ROOT)
	_remove(IMPORTS)
	var imports: Array[String] = [IMPORTS]
	_files = ZipPackageFiles.new(ROOT, imports)
	var folders: Array[String] = [ROOT]
	_store = FolderPackageStore.new(folders, EvaluatorRegistry.standard())


func after_test() -> void:
	_remove(ROOT)
	_remove(IMPORTS)


func test_a_real_zip_is_inspected_installed_and_read_back() -> void:
	var zip := IMPORTS.path_join("chl-K7M3QX-0001-1.0.0.zip")
	PackageBuilder.new().write_zip(zip)
	var inspected := _files.inspect(zip)
	assert_bool(inspected.is_ok()).override_failure_message(inspected.message).is_true()
	assert_dict(inspected.value).contains_keys(["manifest.json", "levels/l01.json", "checksums.sha256"])
	assert_str(str(inspected.value["manifest.json"]["sha256"])).has_length(64)
	assert_str(_files.archive_sha256(zip)).has_length(64)
	assert_int(_files.free_space()).is_greater(0)
	assert_array(_files.import_candidates().map(func(found: Dictionary) -> String: return found["name"])) \
		.contains_exactly(["chl-K7M3QX-0001-1.0.0.zip"])
	var packages := InMemoryPackageRepository.new()
	var installed := InstallPackage.new(_files, _store, packages, EvaluatorRegistry.standard(), "0.1.0").execute(zip)
	assert_bool(installed.is_ok()).override_failure_message(installed.message).is_true()
	assert_bool(FileAccess.file_exists(ROOT.path_join("chl-K7M3QX-0001/levels/l01.json"))).is_true()
	assert_bool(DirAccess.dir_exists_absolute(ROOT.path_join(".tmp/chl-K7M3QX-0001"))).is_false()
	var listed := _store.list_packages()
	assert_int(listed.size()).is_equal(1)
	assert_bool(listed[0].bundled).is_false()
	assert_bool(_store.load_level("chl-K7M3QX-0001", "FINAL").is_ok()).is_true()


func test_a_file_that_is_not_a_zip_is_rejected() -> void:
	DirAccess.make_dir_recursive_absolute(IMPORTS)
	var path := IMPORTS.path_join("roto.zip")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("no soy un zip")
	file.close()
	assert_str(String(_files.inspect(path).error)).is_equal("archive_unreadable")


static func _remove(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for name in directory.get_directories():
		_remove(path.path_join(name))
	for name in directory.get_files():
		directory.remove(name)
	DirAccess.remove_absolute(path)

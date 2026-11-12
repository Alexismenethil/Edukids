extends GdUnitTestSuite
## Reglas de los paquetes que llegan a la tablet (formato v1, ADR-013): versiones, rutas y
## extensiones, lista de SHA-256, compatibilidad y habilitación por defecto (RF-09).


func test_semantic_versions_compare_by_major_minor_and_patch() -> void:
	var a: SemanticVersion = SemanticVersion.parse("1.2.3").value
	assert_int(a.compare(SemanticVersion.parse("1.2.3").value)).is_equal(0)
	assert_int(a.compare(SemanticVersion.parse("1.10.0").value)).is_equal(-1)
	assert_int(a.compare(SemanticVersion.parse("1.2").value)).is_equal(1)
	assert_int(SemanticVersion.parse("2.0.0").value.compare(a)).is_equal(1)
	assert_str(str(SemanticVersion.parse("1.2").value)).is_equal("1.2.0")


func test_invalid_versions_are_rejected() -> void:
	for text in ["", "1", "1.x.0", "1.2.3.4", "-1.0.0", "1..2"]:
		assert_bool(SemanticVersion.parse(text).is_ok()).override_failure_message(text).is_false()


func test_paths_must_be_relative_lowercase_and_safe() -> void:
	for path in ["levels/l01.json", "images/", "readings/ficha-01/p001.webp", "credits.txt", "checksums.sha256"]:
		assert_str(PackageRules.path_problem(path)).override_failure_message(path).is_empty()
	for path in ["/etc/passwd", "../fuera.json", "levels/../../x.json", "Levels/L01.json", "c:/x.json",
			"levels\\l01.json", "levels//l01.json", "./manifest.json"]:
		assert_str(PackageRules.path_problem(path)).override_failure_message(path).is_not_empty()


func test_only_data_and_media_extensions_are_allowed() -> void:
	for path in ["script.gd", "scene.tscn", "theme.tres", "game.pck", "lib.so", "classes.dex", "app.apk", "page.html", "code.js", "foto.jpg"]:
		assert_str(PackageRules.path_problem(path)).override_failure_message(path).is_not_empty()


func test_entries_need_manifest_checksums_and_a_size_limit() -> void:
	assert_str(PackageRules.check_entries({}).error).is_equal("package_empty")
	assert_str(PackageRules.check_entries({"checksums.sha256": 10}).error).is_equal("manifest_missing")
	assert_str(PackageRules.check_entries({"manifest.json": 10}).error).is_equal("checksums_missing")
	assert_str(PackageRules.check_entries({"manifest.json": 10, "checksums.sha256": 10, "tool.gd": 5}).error).is_equal("forbidden_content")
	var big := {"manifest.json": 10, "checksums.sha256": 10, "images/big.webp": PackageRules.MAX_BYTES}
	assert_str(PackageRules.check_entries(big).error).is_equal("package_too_big")
	var fine := PackageRules.check_entries({"manifest.json": 10, "checksums.sha256": 20, "levels/": 0})
	assert_bool(fine.is_ok()).is_true()
	assert_int(fine.value).is_equal(30)


func test_checksums_are_read_like_sha256sum() -> void:
	var digest := "a".repeat(64)
	var parsed := PackageRules.parse_checksums("%s  manifest.json\n%s *levels/l01.json\n\n" % [digest, digest.to_upper()])
	assert_bool(parsed.is_ok()).is_true()
	assert_dict(parsed.value).is_equal({"manifest.json": digest, "levels/l01.json": digest})
	assert_bool(PackageRules.parse_checksums("").is_ok()).is_false()
	assert_bool(PackageRules.parse_checksums("abc manifest.json").is_ok()).is_false()
	assert_bool(PackageRules.parse_checksums("%s  manifest.json" % "z".repeat(64)).is_ok()).is_false()


func test_every_file_must_match_its_listed_checksum() -> void:
	var a := "a".repeat(64)
	var b := "b".repeat(64)
	var listed := {"manifest.json": a, "levels/l01.json": b}
	assert_bool(PackageRules.check_sums(listed, {"manifest.json": a, "levels/l01.json": b, "checksums.sha256": "x"}).is_ok()).is_true()
	assert_str(PackageRules.check_sums(listed, {"manifest.json": a, "levels/l01.json": a}).error).is_equal("checksum_mismatch")
	assert_str(PackageRules.check_sums(listed, {"manifest.json": a, "levels/l01.json": b, "images/x.png": a}).error).is_equal("checksum_missing")
	assert_str(PackageRules.check_sums(listed, {"manifest.json": a}).error).is_equal("checksum_missing")


func test_packages_can_ask_for_a_newer_app() -> void:
	assert_bool(PackageRules.check_app_version("0.1.0", "0.1.0").is_ok()).is_true()
	assert_bool(PackageRules.check_app_version("0.1.0", "1.0.0").is_ok()).is_true()
	assert_str(PackageRules.check_app_version("1.2.0", "1.0.0").error).is_equal("app_too_old")
	assert_str(PackageRules.check_app_version("", "1.0.0").error).is_equal("manifest_invalid")


func test_bundled_packages_start_enabled_and_installed_ones_wait_for_the_teacher() -> void:
	var bundled: ContentPackage = ContentPackage.parse(SampleItems.manifest()).value
	bundled.bundled = true
	var installed: ContentPackage = ContentPackage.parse(PackageBuilder.new().manifest()).value
	assert_bool(PackageRules.access_for(bundled, {})["enabled"]).is_true()
	assert_bool(PackageRules.access_for(installed, {})["enabled"]).is_false()
	assert_bool(PackageRules.access_for(installed, {})["final_open"]).is_false()
	var saved := {installed.id: {"enabled": true, "final_open": true}, bundled.id: {"enabled": false, "final_open": false}}
	assert_bool(PackageRules.access_for(installed, saved)["enabled"]).is_true()
	assert_bool(PackageRules.access_for(installed, saved)["final_open"]).is_true()
	assert_bool(PackageRules.access_for(bundled, saved)["enabled"]).is_false()


func test_a_teacher_can_open_the_final_challenge_early() -> void:
	var package: ContentPackage = ContentPackage.parse(PackageBuilder.new().manifest()).value
	var closed := TrailRule.states(package.levels, {})
	var open := TrailRule.states(package.levels, {}, true)
	assert_str(String(closed["FINAL"])).is_equal(String(TrailRule.LOCKED))
	assert_str(String(open["FINAL"])).is_equal(String(TrailRule.OPEN))
	assert_str(String(open["L01"])).is_equal(String(TrailRule.OPEN))

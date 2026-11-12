extends GdUnitTestSuite
## Integración: migraciones del esquema de la tablet (modelo-de-datos.md).

const MIGRATIONS := "res://src/infrastructure/sqlite/migrations"
const TABLES := [
	"answer", "attempt", "institution", "level", "package", "package_section", "resource_view",
	"reward", "schema_migration", "section", "setting", "student", "teacher",
]
const SEED := """
INSERT INTO institution (id, name, school_year) VALUES ('i1', 'I.E. de prueba', 2026);
INSERT INTO section (id, institution_id, name) VALUES ('s6a', 'i1', '6.° A');
INSERT INTO student (id, section_id, name, pin_hash, pin_salt) VALUES ('st1', 's6a', 'Estudiante', 'h', 's');
INSERT INTO package (id, kind, area, grade, title, version, sha256, install_path, installed_at)
	VALUES ('mod-math-6-01', 'module', 'math', 6, 'Números', '1.0.0', 'abc', 'user://packages/mod-math-6-01', '2026-11-07T00:00:00Z');
INSERT INTO level (id, package_id, kind, mechanic, position, title)
	VALUES ('mod-math-6-01:L01', 'mod-math-6-01', 'short', 'chase', 1, 'Huamanga');
"""
const ATTEMPT := "INSERT INTO attempt (id, student_id, level_id, package_version, kind, status, started_at, cneb_grade) VALUES (?, 'st1', 'mod-math-6-01:L01', '1.0.0', ?, 'completed', '2026-11-07T00:00:00Z', ?);"

var _path := TestDatabase.path_for("sqlite_migrator")
var _db: SqliteDatabase


func before_test() -> void:
	TestDatabase.remove(_path)
	_db = SqliteDatabase.open(_path).value


func after_test() -> void:
	_db.close()
	TestDatabase.remove(_path)


func _migrate_and_seed() -> void:
	SqliteMigrator.new(_db, MIGRATIONS).migrate()
	_db.execute(SEED)


func test_creates_the_documented_schema() -> void:
	var migrated := SqliteMigrator.new(_db, MIGRATIONS).migrate()
	assert_bool(migrated.is_ok()).is_true()
	assert_int(migrated.value).is_equal(2)
	var rows: Array = _db.query("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name;").value
	assert_array(rows.map(func(row: Dictionary) -> String: return str(row["name"]))).is_equal(TABLES)


func test_running_twice_changes_nothing() -> void:
	var migrator := SqliteMigrator.new(_db, MIGRATIONS)
	migrator.migrate()
	var again := migrator.migrate()
	assert_bool(again.is_ok()).is_true()
	assert_int(again.value).is_equal(2)
	assert_int(int(_db.query("SELECT COUNT(*) AS total FROM schema_migration;").value[0]["total"])).is_equal(2)


func test_finds_migrations_in_order() -> void:
	var files := SqliteMigrator.new(_db, MIGRATIONS).pending_files()
	assert_int(files.size()).is_greater_equal(2)
	assert_int(files[0]["version"]).is_equal(1)
	assert_str(files[0]["name"]).is_equal("initial_schema")


func test_only_allowed_values_are_accepted() -> void:
	_migrate_and_seed()
	var insert := "INSERT INTO package (id, kind, area, grade, title, version, sha256, install_path, installed_at) VALUES (?, ?, ?, 6, 'Prueba', '1.0.0', 'abc', 'user://p', '2026-11-07T00:00:00Z');"
	assert_bool(_db.execute(insert, ["chl-K7M3QX-0007", "challenge", "science"]).is_ok()).is_true()
	assert_bool(_db.execute(insert, ["x1", "lesson", "math"]).is_ok()).is_false()
	assert_bool(_db.execute(insert, ["x2", "module", "history"]).is_ok()).is_false()


func test_students_with_results_are_deactivated_not_deleted() -> void:
	_migrate_and_seed()
	assert_bool(_db.execute(ATTEMPT, ["a1", "practice", null]).is_ok()).is_true()
	assert_bool(_db.execute("DELETE FROM student WHERE id = 'st1';").is_ok()).is_false()
	assert_bool(_db.execute("UPDATE student SET active = 0 WHERE id = 'st1';").is_ok()).is_true()


func test_cneb_grade_only_for_final_challenges() -> void:
	_migrate_and_seed()
	assert_bool(_db.execute(ATTEMPT, ["a1", "practice", "A"]).is_ok()).is_false()
	assert_bool(_db.execute(ATTEMPT, ["a2", "final", "A"]).is_ok()).is_true()
	assert_bool(_db.execute(ATTEMPT, ["a3", "final", "Z"]).is_ok()).is_false()


func test_answers_need_an_existing_attempt() -> void:
	_migrate_and_seed()
	var answer := "INSERT INTO answer (id, attempt_id, item_id, value_json, is_correct, first_try, answered_at) VALUES ('r1', ?, 'q1', '\"b\"', 1, 1, '2026-11-07T00:00:00Z');"
	assert_bool(_db.execute(answer, ["missing"]).is_ok()).is_false()
	_db.execute(ATTEMPT, ["a1", "practice", null])
	assert_bool(_db.execute(answer, ["a1"]).is_ok()).is_true()


## Una tablet que ya tenía el esquema v1 con intentos guardados pasa al v2 sin perder nada,
## y desde entonces acepta niveles con la mecánica del caimán.
func test_version_two_keeps_attempts_and_accepts_the_caiman() -> void:
	var only_first := "user://test_migrations_v1"
	DirAccess.make_dir_recursive_absolute(only_first)
	var copy := FileAccess.open(only_first + "/001_initial_schema.sql", FileAccess.WRITE)
	copy.store_string(FileAccess.get_file_as_string(MIGRATIONS + "/001_initial_schema.sql"))
	copy.close()
	assert_int(SqliteMigrator.new(_db, only_first).migrate().value).is_equal(1)
	_db.execute(SEED)
	assert_bool(_db.execute(ATTEMPT, ["at1", "practice", null]).is_ok()).is_true()
	var caiman_v1 := "INSERT INTO level (id, package_id, kind, mechanic, position, title) VALUES ('mod-math-6-01:L02', 'mod-math-6-01', 'short', 'caiman', 2, 'Coco');"
	assert_bool(_db.execute(caiman_v1).is_ok()).is_false()
	var migrated := SqliteMigrator.new(_db, MIGRATIONS).migrate()
	assert_bool(migrated.is_ok()).override_failure_message(migrated.message).is_true()
	assert_int(migrated.value).is_equal(2)
	assert_int(int(_db.query("SELECT COUNT(*) AS total FROM attempt;").value[0]["total"])).is_equal(1)
	assert_bool(_db.execute(caiman_v1).is_ok()).is_true()
	assert_bool(_db.execute(ATTEMPT, ["at2", "practice", null]).is_ok()).is_true()
	assert_bool(_db.execute(ATTEMPT.replace("'mod-math-6-01:L01'", "'no-existe'"), ["at3", "practice", null]).is_ok()).is_false()
	DirAccess.remove_absolute(only_first + "/001_initial_schema.sql")
	DirAccess.remove_absolute(only_first)

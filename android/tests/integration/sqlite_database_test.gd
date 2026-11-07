extends GdUnitTestSuite
## Integración: conexión SQLite real (plugin godot-sqlite).

var _path := TestDatabase.path_for("sqlite_database")
var _db: SqliteDatabase


func before_test() -> void:
	TestDatabase.remove(_path)
	_db = SqliteDatabase.open(_path).value


func after_test() -> void:
	_db.close()
	TestDatabase.remove(_path)


func test_extension_is_available() -> void:
	assert_bool(SqliteDatabase.is_available()).is_true()
	assert_bool(_db.is_open()).is_true()


func test_uses_wal_and_foreign_keys() -> void:
	assert_str(str(_db.query("PRAGMA journal_mode;").value[0]["journal_mode"])).is_equal("wal")
	assert_int(int(_db.query("PRAGMA foreign_keys;").value[0]["foreign_keys"])).is_equal(1)


func test_bindings_keep_text_as_data() -> void:
	_db.execute("CREATE TABLE note (body TEXT);")
	var tricky := "x'); DROP TABLE note; --"
	assert_bool(_db.execute("INSERT INTO note (body) VALUES (?);", [tricky]).is_ok()).is_true()
	assert_str(str(_db.query("SELECT body FROM note;").value[0]["body"])).is_equal(tricky)


func test_transaction_rolls_back_everything_on_failure() -> void:
	_db.execute("CREATE TABLE counter (value INTEGER NOT NULL);")
	var outcome := _db.transaction(func() -> Result:
		_db.execute("INSERT INTO counter (value) VALUES (1);")
		return _db.execute("INSERT INTO counter (value) VALUES (NULL);"))
	assert_bool(outcome.is_ok()).is_false()
	assert_int(int(_db.query("SELECT COUNT(*) AS total FROM counter;").value[0]["total"])).is_equal(0)


func test_transaction_commits_on_success() -> void:
	_db.execute("CREATE TABLE counter (value INTEGER NOT NULL);")
	var outcome := _db.transaction(func() -> Result:
		return _db.execute("INSERT INTO counter (value) VALUES (7);"))
	assert_bool(outcome.is_ok()).is_true()
	assert_int(int(_db.query("SELECT value FROM counter;").value[0]["value"])).is_equal(7)


func test_errors_come_back_as_results() -> void:
	var outcome := _db.query("SELECT * FROM nowhere;")
	assert_that(outcome.error).is_equal(&"query_failed")
	assert_str(outcome.message).contains("nowhere")


func test_reports_engine_version() -> void:
	assert_str(_db.engine_version()).starts_with("3.")

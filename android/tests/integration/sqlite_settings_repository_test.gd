extends GdUnitTestSuite
## Integración: ajustes de sonido guardados en la tabla setting.

const MIGRATIONS := "res://src/infrastructure/sqlite/migrations"


class FixedClock extends Clock:
	func now_unix_ms() -> int:
		return 1_794_009_600_000


var _path := TestDatabase.path_for("sqlite_settings")
var _db: SqliteDatabase
var _repository: SqliteSettingsRepository


func before_test() -> void:
	TestDatabase.remove(_path)
	_db = SqliteDatabase.open(_path).value
	SqliteMigrator.new(_db, MIGRATIONS).migrate()
	_repository = SqliteSettingsRepository.new(_db, FixedClock.new())


func after_test() -> void:
	_db.close()
	TestDatabase.remove(_path)


func test_defaults_when_nothing_was_saved() -> void:
	assert_bool(_repository.load_audio_settings().equals(AudioSettings.defaults())).is_true()


func test_saves_and_reads_back() -> void:
	var settings := AudioSettings.new(0.25, 0.5, true)
	assert_bool(_repository.save_audio_settings(settings).is_ok()).is_true()
	assert_bool(_repository.load_audio_settings().equals(settings)).is_true()


func test_saving_again_updates_the_same_keys() -> void:
	_repository.save_audio_settings(AudioSettings.defaults())
	_repository.save_audio_settings(AudioSettings.defaults().toggled_mute())
	assert_int(int(_db.query("SELECT COUNT(*) AS total FROM setting;").value[0]["total"])).is_equal(3)
	assert_bool(_repository.load_audio_settings().muted).is_true()


func test_survives_reopening_the_database() -> void:
	_repository.save_audio_settings(AudioSettings.new(0.4, 0.8, true))
	_db.close()
	_db = SqliteDatabase.open(_path).value
	var reopened := SqliteSettingsRepository.new(_db, FixedClock.new())
	assert_bool(reopened.load_audio_settings().equals(AudioSettings.new(0.4, 0.8, true))).is_true()


func test_records_the_update_time_in_iso_8601() -> void:
	_repository.save_audio_settings(AudioSettings.defaults())
	var updated: String = str(_db.query("SELECT updated_at FROM setting LIMIT 1;").value[0]["updated_at"])
	assert_str(updated).is_equal("2026-11-07T00:00:00Z")

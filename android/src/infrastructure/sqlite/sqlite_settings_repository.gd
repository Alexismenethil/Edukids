class_name SqliteSettingsRepository
extends SettingsRepository
## Adaptador de salida: guarda los ajustes en la tabla setting (clave y valor).

const MUSIC_VOLUME := "audio.music_volume"
const SFX_VOLUME := "audio.sfx_volume"
const MUTED := "audio.muted"
const UPSERT := "INSERT INTO setting (key, value, updated_at) VALUES (?, ?, ?) ON CONFLICT (key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at;"

var _database: SqliteDatabase
var _clock: Clock


func _init(database: SqliteDatabase, clock: Clock) -> void:
	_database = database
	_clock = clock


func load_audio_settings() -> AudioSettings:
	var rows := _database.query("SELECT key, value FROM setting WHERE key IN (?, ?, ?);", [MUSIC_VOLUME, SFX_VOLUME, MUTED])
	if not rows.is_ok():
		return AudioSettings.defaults()
	var values := {}
	for row: Dictionary in rows.value:
		values[str(row["key"])] = str(row["value"])
	return AudioSettings.new(
		float(values.get(MUSIC_VOLUME, AudioSettings.DEFAULT_MUSIC_VOLUME)),
		float(values.get(SFX_VOLUME, AudioSettings.DEFAULT_SFX_VOLUME)),
		values.get(MUTED, "0") == "1",
	)


func save_audio_settings(settings: AudioSettings) -> Result:
	var now := Time.get_datetime_string_from_unix_time(int(_clock.now_unix_ms() / 1000.0)) + "Z"
	var entries := [
		[MUSIC_VOLUME, str(snappedf(settings.music_volume, 0.001))],
		[SFX_VOLUME, str(snappedf(settings.sfx_volume, 0.001))],
		[MUTED, "1" if settings.muted else "0"],
	]
	return _database.transaction(func() -> Result:
		for entry: Array in entries:
			var saved := _database.execute(UPSERT, [entry[0], entry[1], now])
			if not saved.is_ok():
				return saved
		return Result.ok())

extends Node
## Raíz de composición (autoload): el único lugar que crea las clases concretas y las conecta.
## Las escenas no la usan: el navegador les inyecta sus presentadores.

const STORY_DIRECTORY := "res://content/story"
const DATABASE_PATH := "user://edukids.db"
const MIGRATIONS_DIRECTORY := "res://src/infrastructure/sqlite/migrations"

## Descripción del almacenamiento para el panel de medición.
var storage_status := "Sin iniciar"

var _get_story_scene: GetStoryScene
var _get_audio_settings: GetAudioSettings
var _toggle_sound: ToggleSound
var _database: SqliteDatabase
var _version: String


func _ready() -> void:
	_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	var clock := SystemClock.new()
	var settings := _open_settings(clock)
	var mixer := GodotAudioMixer.new()
	_get_story_scene = GetStoryScene.new(JsonStoryRepository.new(STORY_DIRECTORY))
	_get_audio_settings = GetAudioSettings.new(settings)
	_toggle_sound = ToggleSound.new(settings, mixer)
	RestoreAudioSettings.new(settings, mixer).execute()
	print("EduKids %s · %s" % [_version, storage_status])


func _exit_tree() -> void:
	if _database:
		_database.close()


func title_presenter() -> TitlePresenter:
	return TitlePresenter.new(_get_story_scene, _get_audio_settings, _toggle_sound, _version)


func diagnostics() -> DiagnosticsViewModel:
	var view_model := DiagnosticsViewModel.new()
	view_model.version = _version
	view_model.storage = storage_status
	return view_model


## Abre SQLite y aplica las migraciones. Si no se puede, el juego sigue con ajustes en memoria.
func _open_settings(clock: Clock) -> SettingsRepository:
	var opened := SqliteDatabase.open(DATABASE_PATH)
	if not opened.is_ok():
		storage_status = "Memoria temporal (%s)" % opened.message
		push_warning("EduKids: %s" % opened.message)
		return InMemorySettingsRepository.new()
	var database: SqliteDatabase = opened.value
	var migrated := SqliteMigrator.new(database, MIGRATIONS_DIRECTORY).migrate()
	if not migrated.is_ok():
		database.close()
		storage_status = "Memoria temporal (%s)" % migrated.message
		push_error("EduKids: %s" % migrated.message)
		return InMemorySettingsRepository.new()
	_database = database
	storage_status = "SQLite %s · esquema v%d" % [database.engine_version(), migrated.value]
	return SqliteSettingsRepository.new(database, clock)

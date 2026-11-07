extends Node
## Raíz de composición (autoload): el único lugar que crea las clases concretas y las conecta.
## Las escenas no la usan: el navegador les inyecta sus presentadores.

const STORY_DIRECTORY := "res://content/story"
const DATABASE_PATH := "user://edukids.db"
## Base aparte para el modo demostración (--demo-data o --demo-empty): nunca toca los datos reales.
const DEMO_DATABASE_PATH := "user://edukids_demo.db"
const MIGRATIONS_DIRECTORY := "res://src/infrastructure/sqlite/migrations"

## Descripción del almacenamiento para el panel de medición.
var storage_status := "Sin iniciar"

var _session := PlaySession.new()
var _clock: Clock
var _random: RandomSource
var _ids: IdGenerator
var _hasher: PinHasher
var _institutions: InstitutionRepository
var _students: StudentRepository
var _get_story_scene: GetStoryScene
var _get_audio_settings: GetAudioSettings
var _toggle_sound: ToggleSound
var _database: SqliteDatabase
var _version: String


func _ready() -> void:
	_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	_clock = SystemClock.new()
	_random = GodotRandomSource.new()
	_ids = UuidV4Generator.new()
	_hasher = Pbkdf2PinHasher.new()
	var args := OS.get_cmdline_user_args()
	var demo := OS.is_debug_build() and (args.has("--demo-data") or args.has("--demo-empty"))
	var settings := _open_storage(DEMO_DATABASE_PATH if demo else DATABASE_PATH, demo)
	var mixer := GodotAudioMixer.new()
	_get_story_scene = GetStoryScene.new(JsonStoryRepository.new(STORY_DIRECTORY))
	_get_audio_settings = GetAudioSettings.new(settings)
	_toggle_sound = ToggleSound.new(settings, mixer)
	RestoreAudioSettings.new(settings, mixer).execute()
	if demo and args.has("--demo-data"):
		DemoClassroom.seed(_institutions, _students, _hasher, _ids)
	if demo:
		storage_status += " · base de demostración"
	print("EduKids %s · %s" % [_version, storage_status])


func _exit_tree() -> void:
	if _database:
		_database.close()


func classroom() -> ClassroomResponse:
	return GetClassroom.new(_institutions).execute()


func title_presenter() -> TitlePresenter:
	return TitlePresenter.new(_get_story_scene, _get_audio_settings, _toggle_sound, _version, _session)


func profile_picker_presenter() -> ProfilePickerPresenter:
	return ProfilePickerPresenter.new(GetClassroom.new(_institutions), ListStudents.new(_students, _clock),
		LoginStudent.new(_students, _hasher, _clock), _session)


func avatar_editor_presenter() -> AvatarEditorPresenter:
	return AvatarEditorPresenter.new(GetStudentProfile.new(_students, _clock), CustomizeAvatar.new(_students),
		SuggestAvatar.new(_random), _session)


func student_home_presenter() -> StudentHomePresenter:
	return StudentHomePresenter.new(GetStudentProfile.new(_students, _clock), _session)


func setup_presenter() -> SetupPresenter:
	return SetupPresenter.new(ConfigureInstitution.new(_institutions, _hasher, _ids), _clock)


func teacher_gate_presenter() -> TeacherGatePresenter:
	return TeacherGatePresenter.new(UnlockTeacherMode.new(_institutions, _hasher, _clock))


func teacher_panel_presenter() -> TeacherPanelPresenter:
	return TeacherPanelPresenter.new(
		GetClassroom.new(_institutions),
		ListStudents.new(_students, _clock),
		RegisterStudent.new(_institutions, _students, _hasher, _ids),
		UpdateStudent.new(_institutions, _students),
		SetStudentActive.new(_students),
		ResetStudentPin.new(_students, _hasher),
		SuggestPin.new(_random),
	)


func diagnostics() -> DiagnosticsViewModel:
	var view_model := DiagnosticsViewModel.new()
	view_model.version = _version
	view_model.storage = storage_status
	return view_model


## Abre SQLite y aplica las migraciones. Si no se puede, el juego sigue con datos en memoria.
func _open_storage(path: String, fresh: bool) -> SettingsRepository:
	if fresh:
		for suffix in ["", "-wal", "-shm"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var opened := SqliteDatabase.open(path)
	if not opened.is_ok():
		return _use_memory(opened.message)
	var database: SqliteDatabase = opened.value
	var migrated := SqliteMigrator.new(database, MIGRATIONS_DIRECTORY).migrate()
	if not migrated.is_ok():
		database.close()
		push_error("EduKids: %s" % migrated.message)
		return _use_memory(migrated.message)
	_database = database
	_institutions = SqliteInstitutionRepository.new(database)
	_students = SqliteStudentRepository.new(database)
	storage_status = "SQLite %s · esquema v%d" % [database.engine_version(), migrated.value]
	return SqliteSettingsRepository.new(database, _clock)


func _use_memory(reason: String) -> SettingsRepository:
	storage_status = "Memoria temporal (%s)" % reason
	push_warning("EduKids: %s" % reason)
	_institutions = InMemoryInstitutionRepository.new()
	_students = InMemoryStudentRepository.new()
	return InMemorySettingsRepository.new()

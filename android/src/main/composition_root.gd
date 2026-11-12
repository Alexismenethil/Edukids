extends Node
## Raíz de composición (autoload): el único lugar que crea las clases concretas y las conecta.
## Las escenas no la usan: el navegador les inyecta sus presentadores.

const STORY_DIRECTORY := "res://content/story"
const DATABASE_PATH := "user://edukids.db"
## Base aparte para el modo demostración (--demo-data o --demo-empty): nunca toca los datos reales.
const DEMO_DATABASE_PATH := "user://edukids_demo.db"
const MIGRATIONS_DIRECTORY := "res://src/infrastructure/sqlite/migrations"
## Paquetes que vienen con el juego (los módulos de práctica de la parada de Huamanga).
const BUNDLED_PACKAGES := "res://content/packages"
## Paquetes instalados (descargados o importados por USB); el modo demostración usa otra carpeta.
const INSTALLED_PACKAGES := "user://packages"
const DEMO_INSTALLED_PACKAGES := "user://packages_demo"
## Carpeta interna donde también se buscan paquetes para importar (las pruebas y la demostración).
const IMPORTS := "user://imports"

## Descripción del almacenamiento para el panel de medición.
var storage_status := "Sin iniciar"

var _session := PlaySession.new()
var _clock: Clock
var _random: RandomSource
var _ids: IdGenerator
var _hasher: PinHasher
var _institutions: InstitutionRepository
var _students: StudentRepository
var _registry: EvaluatorRegistry
var _store: FolderPackageStore
var _files: ZipPackageFiles
var _access: PackageAccessRepository
var _packages: PackageRepository
var _attempts: AttemptRepository
var _level_sessions := InMemoryLevelSessionStore.new()
var _steps: StepBuilder
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
	_registry = EvaluatorRegistry.standard()
	_steps = StepBuilder.new(_random)
	var args := LaunchArgs.all()
	var demo := OS.is_debug_build() and (args.has("--demo-data") or args.has("--demo-empty"))
	var installed := DEMO_INSTALLED_PACKAGES if demo else INSTALLED_PACKAGES
	if demo:
		_remove_folder(DEMO_INSTALLED_PACKAGES)
	var folders: Array[String] = [installed, BUNDLED_PACKAGES]
	_store = FolderPackageStore.new(folders, _registry)
	_files = ZipPackageFiles.new(installed, _import_folders())
	var settings := _open_storage(DEMO_DATABASE_PATH if demo else DATABASE_PATH, demo)
	var mixer := GodotAudioMixer.new()
	_get_story_scene = GetStoryScene.new(JsonStoryRepository.new(STORY_DIRECTORY))
	_get_audio_settings = GetAudioSettings.new(settings)
	_toggle_sound = ToggleSound.new(settings, mixer)
	RestoreAudioSettings.new(settings, mixer).execute()
	var registered := RegisterBundledPackages.new(_store, _packages).execute()
	if demo and args.has("--demo-data"):
		DemoClassroom.seed(_institutions, _students, _hasher, _ids)
	if demo:
		storage_status += " · base de demostración"
	print("EduKids %s · %s · %d paquetes" % [_version, storage_status, registered])
	for problem in _store.problems:
		push_warning("EduKids: %s" % problem)


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


func map_presenter() -> MapPresenter:
	return MapPresenter.new(GetStudentProfile.new(_students, _clock), GetChapterMap.new(_store, _attempts, _students, _access), _session)


func level_presenter() -> LevelPresenter:
	return LevelPresenter.new(
		StartLevel.new(_store, _attempts, _level_sessions, _registry, _steps, _ids, _clock),
		SubmitAnswer.new(_level_sessions, _attempts, _ids, _clock),
		RequestHint.new(_level_sessions),
		ContinueLevel.new(_level_sessions, _steps, _clock),
		FinishLevel.new(_level_sessions, _attempts, _clock),
		_session,
		GetStudentProfile.new(_students, _clock),
	)


## Parada a la que vuelve el estudiante al salir de un nivel.
func current_stop() -> String:
	return _session.stop_id


## Respuesta correcta (o una equivocada creíble) de una pregunta, solo para el modo
## demostración (grabar videos).
func demo_solution(question_id: String, wrong: bool = false) -> Variant:
	if not OS.is_debug_build():
		return null
	var question := _demo_question(question_id)
	if question == null:
		return null
	return DemoClassroom.wrong_of(question) if wrong else DemoClassroom.solution_of(question)


func _demo_question(question_id: String) -> Item:
	var loaded := _store.load_level(_session.level_package, _session.level_id)
	if not loaded.is_ok():
		return null
	var level: Level = loaded.value
	for item in level.items:
		var questions: Array = item.spec["items"] if item.type == ItemType.READING_UNIT else [item]
		for question: Item in questions:
			if question.id == question_id:
				return question
	return null


## Elige un nivel y, en la base de demostración, completa los anteriores de su módulo para
## que esté abierto (RN-18). También deja la parada lista para volver.
func demo_choose(package_id: String, level_id: String, unlock: bool = true) -> void:
	if not OS.is_debug_build():
		return
	_session.choose_level(package_id, level_id)
	for package in _store.list_packages():
		if package.id != package_id:
			continue
		_session.choose_stop(package.stop)
		if not unlock:
			return
		var target := package.find_level(level_id)
		var stars := [3, 2, 3, 2, 3]
		for entry in package.levels:
			if entry.is_final() or (target and not target.is_final() and entry.position >= target.position):
				continue
			var loaded := _store.load_level(package.id, entry.id)
			if not loaded.is_ok():
				continue
			var attempt := Attempt.start(_ids.next_id(), _session.student_id, loaded.value, _clock.now_unix_ms() - 3_600_000)
			_attempts.create_attempt(attempt)
			var summary := LevelSummary.new()
			summary.total = attempt.total_count
			summary.correct = attempt.total_count
			summary.percent = 100.0
			summary.stars = stars[entry.position % stars.size()]
			attempt.complete(summary, _clock.now_unix_ms() - 3_000_000)
			_attempts.finish_attempt(attempt)
		return


## Paquete y nivel de la primera mecánica pedida (en la parada de Huamanga), para la demostración.
func demo_find(area: StringName, mechanic: StringName) -> PackedStringArray:
	for package in _store.list_packages():
		if package.area != area and area != &"":
			continue
		for entry in package.levels:
			var is_final := entry.is_final()
			if (mechanic == &"final" and is_final) or (not is_final and entry.mechanic == mechanic):
				return PackedStringArray([package.id, entry.id])
	return PackedStringArray()


## Capítulo del mapa donde está el estudiante (sierra, selva o costa).
func current_chapter() -> StringName:
	return _session.chapter


## Entra con el primer estudiante que ya tiene personaje (modo demostración).
func demo_login() -> bool:
	if not OS.is_debug_build():
		return false
	var room := classroom()
	if room.sections.is_empty():
		return false
	for summary in ListStudents.new(_students, _clock).execute(str(room.sections[0]["id"])):
		if not summary.avatar.is_empty():
			_session.student_id = summary.id
			# Demostración: `--demo-chapter=selva` (o costa) abre los niveles con el mundo y el guía
			# de ese capítulo.
			for arg in LaunchArgs.all():
				if arg.begins_with("--demo-chapter="):
					_session.chapter = StringName(arg.get_slice("=", 1))
			return true
	return false




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


func packages_presenter() -> PackagesPresenter:
	return PackagesPresenter.new(
		ListPackages.new(_store, _access),
		SetPackageAccess.new(_store, _access),
		ListImportFiles.new(_files),
		InstallPackage.new(_files, _store, _packages, _registry, _version),
	)


## Borra una carpeta con todo su contenido (la demostración empieza sin paquetes instalados).
static func _remove_folder(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for name in directory.get_directories():
		_remove_folder(path.path_join(name))
	for name in directory.get_files():
		directory.remove(name)
	DirAccess.remove_absolute(path)


## Carpetas donde el docente deja los paquetes copiados por USB o por cable: Descargas/EduKids y
## Documentos/EduKids de la tablet, además de la carpeta interna de importación.
func _import_folders() -> Array[String]:
	var folders: Array[String] = [IMPORTS]
	for kind in [OS.SYSTEM_DIR_DOWNLOADS, OS.SYSTEM_DIR_DOCUMENTS]:
		var base := OS.get_system_dir(kind)
		if not base.is_empty():
			folders.append(base.path_join("EduKids"))
	return folders


func diagnostics() -> DiagnosticsViewModel:
	var view_model := DiagnosticsViewModel.new()
	view_model.version = _version
	view_model.storage = storage_status
	if not _store.problems.is_empty():
		view_model.storage += " · %d paquetes con problemas" % _store.problems.size()
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
	_packages = SqlitePackageRepository.new(database, _clock)
	_access = SqlitePackageAccessRepository.new(database)
	_attempts = SqliteAttemptRepository.new(database)
	storage_status = "SQLite %s · esquema v%d" % [database.engine_version(), migrated.value]
	return SqliteSettingsRepository.new(database, _clock)


func _use_memory(reason: String) -> SettingsRepository:
	storage_status = "Memoria temporal (%s)" % reason
	push_warning("EduKids: %s" % reason)
	_institutions = InMemoryInstitutionRepository.new()
	_students = InMemoryStudentRepository.new()
	_packages = InMemoryPackageRepository.new()
	_access = InMemoryPackageAccessRepository.new()
	_attempts = InMemoryAttemptRepository.new()
	return InMemorySettingsRepository.new()

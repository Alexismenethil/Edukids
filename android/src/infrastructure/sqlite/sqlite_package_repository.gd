class_name SqlitePackageRepository
extends PackageRepository
## Adaptador de salida: registra los paquetes instalados y sus niveles en SQLite.
## Al actualizar un paquete se conserva su fecha de instalación.

const UPSERT_PACKAGE := "INSERT INTO package (id, kind, area, grade, number, chapter, title, version, size_bytes, sha256, status, install_path, installed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'installed', ?, ?) ON CONFLICT (id) DO UPDATE SET kind = excluded.kind, area = excluded.area, grade = excluded.grade, number = excluded.number, chapter = excluded.chapter, title = excluded.title, version = excluded.version, size_bytes = excluded.size_bytes, sha256 = excluded.sha256, status = 'installed', install_path = excluded.install_path;"
const UPSERT_LEVEL := "INSERT INTO level (id, package_id, kind, mechanic, position, title, estimated_minutes) VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO UPDATE SET kind = excluded.kind, mechanic = excluded.mechanic, position = excluded.position, title = excluded.title, estimated_minutes = excluded.estimated_minutes;"

var _database: SqliteDatabase
var _clock: Clock


func _init(database: SqliteDatabase, clock: Clock) -> void:
	_database = database
	_clock = clock


func save_package(package: ContentPackage, levels: Array[Level], size_bytes: int = 0, sha256: String = "") -> Result:
	return _database.transaction(func() -> Result:
		var saved := _database.execute(UPSERT_PACKAGE, [
			package.id, String(package.kind), String(package.area), package.grade, package.number,
			String(package.chapter), package.title, package.version, size_bytes, sha256, package.location,
			IsoTime.from_unix_ms(_clock.now_unix_ms()),
		])
		if not saved.is_ok():
			return saved
		for level in levels:
			saved = _database.execute(UPSERT_LEVEL, [
				level.key(), package.id, String(level.entry.kind), String(level.entry.mechanic),
				level.entry.position, level.title, level.entry.estimated_minutes,
			])
			if not saved.is_ok():
				return saved
		return Result.ok())

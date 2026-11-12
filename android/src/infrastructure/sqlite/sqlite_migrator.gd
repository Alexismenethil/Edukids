class_name SqliteMigrator
extends RefCounted
## Adaptador de salida: aplica en orden las migraciones pendientes y registra cada versión
## en la tabla schema_migration. Cada migración corre en su propia transacción.
## Los archivos se llaman NNN_nombre.sql (por ejemplo, 001_initial_schema.sql).
##
## Una migración que rehace una tabla referenciada por claves foráneas empieza con la marca
## REBUILD_MARK: se aplica con las claves foráneas apagadas y, antes de confirmar, se comprueba
## que ninguna referencia quedó rota (procedimiento recomendado por SQLite).

const FILE_PATTERN := "^(\\d{3})_([a-z0-9_]+)\\.sql$"
const REBUILD_MARK := "-- rehace-tablas"

var _database: SqliteDatabase
var _directory: String


func _init(database: SqliteDatabase, directory: String) -> void:
	_database = database
	_directory = directory.trim_suffix("/")


## Devuelve un Result con la versión final del esquema.
func migrate() -> Result:
	var bootstrap := _database.execute(
		"CREATE TABLE IF NOT EXISTS schema_migration (version INTEGER PRIMARY KEY, name TEXT NOT NULL, applied_at TEXT NOT NULL);"
	)
	if not bootstrap.is_ok():
		return bootstrap
	var applied := _applied_versions()
	if not applied.is_ok():
		return applied
	for migration: Dictionary in pending_files():
		var version: int = migration["version"]
		if (applied.value as Array).has(version):
			continue
		var sql := FileAccess.get_file_as_string(migration["path"])
		if sql.strip_edges().is_empty():
			return Result.fail(&"empty_migration", "La migración %03d está vacía o no se pudo leer." % version)
		var rebuild := sql.begins_with(REBUILD_MARK)
		if rebuild:
			_database.execute("PRAGMA foreign_keys = OFF;")
		var outcome := _database.transaction(func() -> Result:
			var done := _database.execute(sql)
			if not done.is_ok():
				return done
			if rebuild:
				var broken := _database.query("PRAGMA foreign_key_check;")
				if not broken.is_ok() or not (broken.value as Array).is_empty():
					return Result.fail(&"foreign_keys_broken", "La migración dejó referencias rotas.")
			return _database.execute(
				"INSERT INTO schema_migration (version, name, applied_at) VALUES (?, ?, ?);",
				[version, migration["name"], Time.get_datetime_string_from_system(true) + "Z"]
			))
		if rebuild:
			_database.execute("PRAGMA foreign_keys = ON;")
		if not outcome.is_ok():
			return Result.fail(&"migration_failed", "Migración %03d (%s): %s" % [version, migration["name"], outcome.message])
	return Result.ok(current_version())


## Migraciones disponibles, ordenadas por versión.
func pending_files() -> Array[Dictionary]:
	var pattern := RegEx.create_from_string(FILE_PATTERN)
	var files: Array[Dictionary] = []
	for file_name in DirAccess.get_files_at(_directory):
		var found := pattern.search(file_name)
		if found:
			files.append({
				"version": int(found.get_string(1)),
				"name": found.get_string(2),
				"path": "%s/%s" % [_directory, file_name],
			})
	files.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["version"] < b["version"])
	return files


func current_version() -> int:
	var rows := _database.query("SELECT COALESCE(MAX(version), 0) AS version FROM schema_migration;")
	if not rows.is_ok() or (rows.value as Array).is_empty():
		return 0
	return int((rows.value as Array)[0]["version"])


func _applied_versions() -> Result:
	var rows := _database.query("SELECT version FROM schema_migration;")
	if not rows.is_ok():
		return rows
	var versions: Array = []
	for row: Dictionary in rows.value:
		versions.append(int(row["version"]))
	return Result.ok(versions)

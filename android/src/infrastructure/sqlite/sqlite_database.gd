class_name SqliteDatabase
extends RefCounted
## Adaptador de salida: conexión a SQLite (plugin godot-sqlite) en modo WAL y con claves foráneas.
##
## La conexión se crea con ClassDB para que el juego no se rompa si la extensión nativa no existe
## en el dispositivo (por ejemplo, un Android de 32 bits): en ese caso open() devuelve un error
## y la raíz de composición usa almacenamiento en memoria.

const EXTENSION_CLASS := &"SQLite"
const QUIET := 0

var path: String:
	get:
		return _path

var _connection: Object
var _path := ""


static func is_available() -> bool:
	return ClassDB.class_exists(EXTENSION_CLASS)


## Abre o crea la base de datos. Devuelve un Result con la conexión.
static func open(database_path: String) -> Result:
	if not is_available():
		return Result.fail(&"sqlite_unavailable", "La extensión SQLite no está disponible en este dispositivo.")
	var database := SqliteDatabase.new()
	database._path = database_path
	database._connection = ClassDB.instantiate(EXTENSION_CLASS)
	database._connection.set("path", database_path)
	database._connection.set("foreign_keys", true)
	database._connection.set("verbosity_level", QUIET)
	if not database._connection.call("open_db"):
		return Result.fail(&"open_failed", str(database._connection.get("error_message")))
	var wal := database.execute("PRAGMA journal_mode = WAL;")
	if not wal.is_ok():
		database.close()
		return wal
	return Result.ok(database)


## Ejecuta una o varias sentencias sin leer filas. Con parámetros, solo una sentencia.
func execute(sql: String, bindings: Array = []) -> Result:
	if _connection == null:
		return Result.fail(&"closed", "La base de datos está cerrada.")
	var success: bool
	if bindings.is_empty():
		success = _connection.call("query", sql)
	else:
		success = _connection.call("query_with_bindings", sql, bindings)
	if not success:
		return Result.fail(&"query_failed", str(_connection.get("error_message")))
	return Result.ok()


## Ejecuta una consulta y devuelve un Result con las filas (Array de Dictionary).
func query(sql: String, bindings: Array = []) -> Result:
	var executed := execute(sql, bindings)
	if not executed.is_ok():
		return executed
	var rows: Array = (_connection.get("query_result") as Array).duplicate(true)
	return Result.ok(rows)


## Ejecuta la acción en una transacción. La acción devuelve un Result; si falla, se revierte todo.
func transaction(action: Callable) -> Result:
	var begun := execute("BEGIN IMMEDIATE;")
	if not begun.is_ok():
		return begun
	var outcome: Result = action.call()
	if outcome == null or not outcome.is_ok():
		execute("ROLLBACK;")
		return outcome if outcome != null else Result.fail(&"transaction_failed")
	var committed := execute("COMMIT;")
	if not committed.is_ok():
		execute("ROLLBACK;")
		return committed
	return outcome


## Versión del motor SQLite, para el panel de medición.
func engine_version() -> String:
	var rows := query("SELECT sqlite_version() AS version;")
	if not rows.is_ok() or (rows.value as Array).is_empty():
		return "?"
	return str((rows.value as Array)[0]["version"])


func is_open() -> bool:
	return _connection != null


func close() -> void:
	if _connection:
		_connection.call("close_db")
		_connection = null

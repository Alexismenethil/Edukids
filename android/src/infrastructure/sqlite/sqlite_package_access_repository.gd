class_name SqlitePackageAccessRepository
extends PackageAccessRepository
## Adaptador de salida: lo que el docente habilitó por sección, en la tabla package_section
## (enabled y final_enabled, que guarda si abrió antes el desafío final).

const SELECT := "SELECT package_id, enabled, final_enabled FROM package_section WHERE section_id = ?;"
const UPSERT := "INSERT INTO package_section (package_id, section_id, enabled, final_enabled) VALUES (?, ?, ?, ?) ON CONFLICT (package_id, section_id) DO UPDATE SET enabled = excluded.enabled, final_enabled = excluded.final_enabled;"

var _database: SqliteDatabase


func _init(database: SqliteDatabase) -> void:
	_database = database


func access_of(section_id: String) -> Dictionary:
	var rows := _database.query(SELECT, [section_id])
	var access := {}
	if not rows.is_ok():
		return access
	for row: Dictionary in rows.value:
		access[str(row["package_id"])] = {"enabled": int(row["enabled"]) == 1, "final_open": int(row["final_enabled"]) == 1}
	return access


func save_access(package_id: String, section_id: String, enabled: bool, final_open: bool) -> Result:
	return _database.execute(UPSERT, [package_id, section_id, 1 if enabled else 0, 1 if final_open else 0])

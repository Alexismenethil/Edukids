class_name SqliteStudentRepository
extends StudentRepository
## Adaptador de salida: estudiantes en SQLite. El avatar se guarda como JSON y el PIN
## solo como hash y sal (RNF-08). No hay forma de borrar: se desactiva (RN-07).

const COLUMNS := "id, section_id, name, code, pin_hash, pin_salt, avatar_json, failed_attempts, locked_until, active"
const UPSERT := "INSERT INTO student (id, section_id, name, code, pin_hash, pin_salt, avatar_json, failed_attempts, locked_until, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO UPDATE SET section_id = excluded.section_id, name = excluded.name, code = excluded.code, pin_hash = excluded.pin_hash, pin_salt = excluded.pin_salt, avatar_json = excluded.avatar_json, failed_attempts = excluded.failed_attempts, locked_until = excluded.locked_until, active = excluded.active;"

var _database: SqliteDatabase


func _init(database: SqliteDatabase) -> void:
	_database = database


func list_students(section_id: String, include_inactive: bool) -> Array[Student]:
	var sql := "SELECT %s FROM student WHERE section_id = ?%s ORDER BY name COLLATE NOCASE;" % [
		COLUMNS, "" if include_inactive else " AND active = 1"]
	var students: Array[Student] = []
	var rows := _database.query(sql, [section_id])
	if not rows.is_ok():
		return students
	for row: Dictionary in rows.value:
		students.append(_to_student(row))
	return students


func find_student(student_id: String) -> Student:
	var rows := _database.query("SELECT %s FROM student WHERE id = ?;" % COLUMNS, [student_id])
	if not rows.is_ok() or (rows.value as Array).is_empty():
		return null
	return _to_student(rows.value[0])


func save_student(student: Student) -> Result:
	var avatar_json := JSON.stringify(student.avatar.to_dict()) if student.has_avatar() else "{}"
	return _database.execute(UPSERT, [
		student.id, student.section_id, student.name, null if student.code.is_empty() else student.code,
		student.credential.pin_hash, student.credential.salt, avatar_json,
		student.lockout.failures, IsoTime.from_unix_ms(student.lockout.locked_until_ms), 1 if student.active else 0,
	])


static func _to_student(row: Dictionary) -> Student:
	var student := Student.new(str(row["id"]), str(row["section_id"]), str(row["name"]),
		PinCredential.new(str(row["pin_hash"]), str(row["pin_salt"])))
	student.code = "" if row["code"] == null else str(row["code"])
	var parsed: Variant = JSON.parse_string(str(row["avatar_json"]))
	student.avatar = Avatar.from_dict(parsed) if parsed is Dictionary else null
	student.lockout = PinLockout.new(int(row["failed_attempts"]), IsoTime.to_unix_ms(row["locked_until"]))
	student.active = int(row["active"]) == 1
	return student

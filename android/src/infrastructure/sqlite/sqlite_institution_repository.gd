class_name SqliteInstitutionRepository
extends InstitutionRepository
## Adaptador de salida: institución, secciones y docente en SQLite.

const UPSERT_TEACHER := "INSERT INTO teacher (id, name, pin_hash, pin_salt, failed_attempts, locked_until) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT (id) DO UPDATE SET name = excluded.name, pin_hash = excluded.pin_hash, pin_salt = excluded.pin_salt, failed_attempts = excluded.failed_attempts, locked_until = excluded.locked_until;"

var _database: SqliteDatabase


func _init(database: SqliteDatabase) -> void:
	_database = database


func load_institution() -> Institution:
	var rows := _database.query("SELECT id, name, modular_code, grade, school_year, teacher_code FROM institution LIMIT 1;")
	if not rows.is_ok() or (rows.value as Array).is_empty():
		return null
	var row: Dictionary = rows.value[0]
	return Institution.new(str(row["id"]), str(row["name"]), _text(row["modular_code"]),
		int(row["grade"]), int(row["school_year"]), _text(row["teacher_code"]))


func load_sections() -> Array[Section]:
	var sections: Array[Section] = []
	var rows := _database.query("SELECT id, name, active FROM section ORDER BY name COLLATE NOCASE;")
	if not rows.is_ok():
		return sections
	for row: Dictionary in rows.value:
		sections.append(Section.new(str(row["id"]), str(row["name"]), int(row["active"]) == 1))
	return sections


func load_teacher() -> Teacher:
	var rows := _database.query("SELECT id, name, pin_hash, pin_salt, failed_attempts, locked_until FROM teacher LIMIT 1;")
	if not rows.is_ok() or (rows.value as Array).is_empty():
		return null
	var row: Dictionary = rows.value[0]
	return Teacher.new(str(row["id"]), str(row["name"]),
		PinCredential.new(str(row["pin_hash"]), str(row["pin_salt"])),
		PinLockout.new(int(row["failed_attempts"]), IsoTime.to_unix_ms(row["locked_until"])))


func save_setup(institution: Institution, sections: Array[Section], teacher: Teacher) -> Result:
	return _database.transaction(func() -> Result:
		var saved := _database.execute(
			"INSERT INTO institution (id, name, modular_code, grade, school_year, teacher_code) VALUES (?, ?, ?, ?, ?, ?);",
			[institution.id, institution.name, _nullable(institution.modular_code), institution.grade,
				institution.school_year, _nullable(institution.teacher_code)])
		if not saved.is_ok():
			return saved
		for section in sections:
			saved = _database.execute("INSERT INTO section (id, institution_id, name, active) VALUES (?, ?, ?, ?);",
				[section.id, institution.id, section.name, 1 if section.active else 0])
			if not saved.is_ok():
				return saved
		return _upsert_teacher(teacher))


func save_teacher(teacher: Teacher) -> Result:
	return _upsert_teacher(teacher)


func _upsert_teacher(teacher: Teacher) -> Result:
	return _database.execute(UPSERT_TEACHER, [teacher.id, teacher.name, teacher.credential.pin_hash,
		teacher.credential.salt, teacher.lockout.failures, IsoTime.from_unix_ms(teacher.lockout.locked_until_ms)])


static func _text(value: Variant) -> String:
	return "" if value == null else str(value)


static func _nullable(text: String) -> Variant:
	return null if text.is_empty() else text

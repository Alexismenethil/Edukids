extends GdUnitTestSuite
## Integración: institución, secciones, docente y estudiantes en SQLite.

const MIGRATIONS := "res://src/infrastructure/sqlite/migrations"
const NOW := 1_794_009_600_000

var _path := TestDatabase.path_for("sqlite_classroom")
var _db: SqliteDatabase
var _institutions: SqliteInstitutionRepository
var _students: SqliteStudentRepository


func before_test() -> void:
	TestDatabase.remove(_path)
	_db = SqliteDatabase.open(_path).value
	SqliteMigrator.new(_db, MIGRATIONS).migrate()
	_institutions = SqliteInstitutionRepository.new(_db)
	_students = SqliteStudentRepository.new(_db)


func after_test() -> void:
	_db.close()
	TestDatabase.remove(_path)


func _save_setup() -> void:
	var sections: Array[Section] = [Section.new("sec-b", "B"), Section.new("sec-a", "A")]
	var teacher := Teacher.new("tea-1", "Rosa Huamán", PinCredential.new("hash-docente", "sal-docente"))
	var institution := Institution.new("ins-1", "Escuela de prueba", "", 6, 2026, "")
	assert_bool(_institutions.save_setup(institution, sections, teacher).is_ok()).is_true()


func _student(id: String, name: String, section_id: String = "sec-a") -> Student:
	return Student.new(id, section_id, name, PinCredential.new("hash-" + id, "sal-" + id))


func test_empty_tablet_has_no_institution_nor_teacher() -> void:
	assert_object(_institutions.load_institution()).is_null()
	assert_object(_institutions.load_teacher()).is_null()
	assert_array(_institutions.load_sections()).is_empty()


func test_saves_and_reads_the_setup() -> void:
	_save_setup()
	var institution := _institutions.load_institution()
	assert_str(institution.name).is_equal("Escuela de prueba")
	assert_str(institution.modular_code).is_equal("")
	assert_str(institution.teacher_code).is_equal("")
	assert_int(institution.school_year).is_equal(2026)
	assert_array(_institutions.load_sections().map(func(s: Section) -> String: return s.name)).is_equal(["A", "B"])
	assert_str(_institutions.load_teacher().credential.pin_hash).is_equal("hash-docente")


func test_optional_codes_are_stored_as_null() -> void:
	_save_setup()
	var row: Dictionary = _db.query("SELECT modular_code, teacher_code FROM institution;").value[0]
	assert_object(row["modular_code"]).is_null()
	assert_object(row["teacher_code"]).is_null()


func test_setup_is_all_or_nothing() -> void:
	var sections: Array[Section] = [Section.new("sec-a", "A"), Section.new("sec-a", "A otra vez")]
	var teacher := Teacher.new("tea-1", "Rosa", PinCredential.new("h", "s"))
	var saved := _institutions.save_setup(Institution.new("ins-1", "Escuela", "", 6, 2026, ""), sections, teacher)
	assert_bool(saved.is_ok()).is_false()
	assert_object(_institutions.load_institution()).is_null()


func test_teacher_lockout_survives_in_iso_8601() -> void:
	_save_setup()
	var teacher := _institutions.load_teacher()
	teacher.lockout = PinLockout.new(0, NOW + 300_000)
	_institutions.save_teacher(teacher)
	var stored: String = str(_db.query("SELECT locked_until FROM teacher;").value[0]["locked_until"])
	assert_str(stored).is_equal("2026-11-07T00:05:00Z")
	assert_bool(_institutions.load_teacher().lockout.is_locked(NOW + 299_000)).is_true()


func test_saves_finds_and_updates_a_student() -> void:
	_save_setup()
	var student := _student("est-1", "Wayra Quispe")
	assert_bool(_students.save_student(student).is_ok()).is_true()
	student.avatar = Avatar.create({"body": "boy", "skin": 4, "hair_style": 1, "hair_color": 0, "top_color": 2, "bottom_color": 7}).value
	student.lockout = PinLockout.new(2, 0)
	_students.save_student(student)
	var found := _students.find_student("est-1")
	assert_str(found.name).is_equal("Wayra Quispe")
	assert_bool(found.avatar.equals(student.avatar)).is_true()
	assert_int(found.lockout.failures).is_equal(2)
	assert_int(int(_db.query("SELECT COUNT(*) AS total FROM student;").value[0]["total"])).is_equal(1)


func test_a_student_without_avatar_keeps_an_empty_json() -> void:
	_save_setup()
	_students.save_student(_student("est-1", "Killa"))
	assert_str(str(_db.query("SELECT avatar_json FROM student;").value[0]["avatar_json"])).is_equal("{}")
	assert_bool(_students.find_student("est-1").has_avatar()).is_false()


func test_lists_by_section_and_hides_inactive() -> void:
	_save_setup()
	_students.save_student(_student("est-1", "Wayra"))
	_students.save_student(_student("est-2", "Ana"))
	_students.save_student(_student("est-3", "Kusi", "sec-b"))
	var inactive := _student("est-4", "Luz")
	inactive.active = false
	_students.save_student(inactive)
	assert_array(_students.list_students("sec-a", false).map(func(s: Student) -> String: return s.name)).is_equal(["Ana", "Wayra"])
	assert_int(_students.list_students("sec-a", true).size()).is_equal(3)


func test_a_student_needs_an_existing_section() -> void:
	_save_setup()
	assert_bool(_students.save_student(_student("est-1", "Nadie", "sec-z")).is_ok()).is_false()


func test_survives_reopening_the_database() -> void:
	_save_setup()
	_students.save_student(_student("est-1", "Sumaq"))
	_db.close()
	_db = SqliteDatabase.open(_path).value
	assert_str(SqliteStudentRepository.new(_db).find_student("est-1").name).is_equal("Sumaq")
	assert_str(SqliteInstitutionRepository.new(_db).load_institution().name).is_equal("Escuela de prueba")

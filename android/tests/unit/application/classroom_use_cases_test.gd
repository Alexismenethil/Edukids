extends GdUnitTestSuite
## Casos de uso del aula con repositorios en memoria, un reloj falso y un hash de prueba.

var _institutions: InMemoryInstitutionRepository
var _students: InMemoryStudentRepository
var _hasher: PlainPinHasher
var _clock: FakeClock
var _ids: SequentialIds


func before_test() -> void:
	_institutions = InMemoryInstitutionRepository.new()
	_students = InMemoryStudentRepository.new()
	_hasher = PlainPinHasher.new()
	_clock = FakeClock.new()
	_ids = SequentialIds.new()


func _setup_request() -> SetupRequest:
	var request := SetupRequest.new()
	request.institution_name = "Escuela de prueba"
	request.modular_code = "0123456"
	request.grade = 6
	request.school_year = 2026
	request.section_names = PackedStringArray(["b", "A"])
	request.teacher_name = "Rosa Huamán"
	request.teacher_pin = "2580"
	request.teacher_pin_confirmation = "2580"
	request.teacher_code = "k7m2qx"
	return request


func _configure() -> ClassroomResponse:
	ConfigureInstitution.new(_institutions, _hasher, _ids).execute(_setup_request())
	return GetClassroom.new(_institutions).execute()


func _section_id(classroom: ClassroomResponse, section_name: String) -> String:
	for section in classroom.sections:
		if section["name"] == section_name:
			return section["id"]
	return ""


func _register(section_id: String, name: String, pin: String = "4702") -> FormResponse:
	var form := StudentForm.new()
	form.name = name
	form.section_id = section_id
	form.pin = pin
	return RegisterStudent.new(_institutions, _students, _hasher, _ids).execute(form)


# --- Configuración inicial (RF-01) ---

func test_a_new_tablet_is_not_configured() -> void:
	assert_bool(GetClassroom.new(_institutions).execute().configured).is_false()


func test_configures_the_institution_sections_and_teacher() -> void:
	var response := ConfigureInstitution.new(_institutions, _hasher, _ids).execute(_setup_request())
	assert_bool(response.ok).is_true()
	var classroom := GetClassroom.new(_institutions).execute()
	assert_bool(classroom.configured).is_true()
	assert_str(classroom.institution_name).is_equal("Escuela de prueba")
	assert_str(classroom.teacher_name).is_equal("Rosa Huamán")
	assert_str(classroom.teacher_code).is_equal("K7M2QX")
	assert_array(classroom.sections.map(func(s: Dictionary) -> String: return s["name"])).is_equal(["A", "B"])


func test_the_teacher_pin_is_never_stored_in_clear() -> void:
	ConfigureInstitution.new(_institutions, _hasher, _ids).execute(_setup_request())
	var teacher := _institutions.load_teacher()
	assert_str(teacher.credential.pin_hash).is_not_equal("2580")
	assert_str(teacher.credential.salt).is_not_empty()


func test_reports_every_invalid_field() -> void:
	var request := SetupRequest.new()
	request.grade = 9
	request.school_year = 1990
	request.section_names = PackedStringArray(["A", "a"])
	request.teacher_pin = "1234"
	request.teacher_code = "XYZ"
	var response := ConfigureInstitution.new(_institutions, _hasher, _ids).execute(request)
	assert_bool(response.ok).is_false()
	assert_dict(response.errors).is_equal({
		"institution_name": &"institution_name_short",
		"grade": &"grade_invalid",
		"school_year": &"school_year_invalid",
		"sections": &"section_duplicated",
		"teacher_name": &"name_too_short",
		"teacher_pin": &"pin_too_easy",
		"teacher_code": &"teacher_code_length",
	})
	assert_object(_institutions.load_institution()).is_null()


func test_needs_at_least_one_section_and_a_matching_confirmation() -> void:
	var request := _setup_request()
	request.section_names = PackedStringArray()
	request.teacher_pin_confirmation = "2581"
	var errors := ConfigureInstitution.new(_institutions, _hasher, _ids).validate(request)
	assert_str(errors["sections"]).is_equal("sections_empty")
	assert_str(errors["teacher_pin_confirmation"]).is_equal("pin_mismatch")


func test_cannot_configure_twice() -> void:
	_configure()
	var again := ConfigureInstitution.new(_institutions, _hasher, _ids).execute(_setup_request())
	assert_str(again.errors["general"]).is_equal("already_configured")


# --- PIN docente (RF-03) ---

func test_teacher_mode_opens_only_with_the_right_pin() -> void:
	_configure()
	var unlock := UnlockTeacherMode.new(_institutions, _hasher, _clock)
	assert_bool(unlock.execute("2580").ok).is_true()
	var wrong := unlock.execute("2581")
	assert_bool(wrong.ok).is_false()
	assert_str(wrong.error).is_equal(PinCheckResponse.WRONG_PIN)
	assert_int(wrong.attempts_left).is_equal(4)


func test_teacher_mode_locks_after_five_failures() -> void:
	_configure()
	var unlock := UnlockTeacherMode.new(_institutions, _hasher, _clock)
	for i in 4:
		unlock.execute("0000")
	var fifth := unlock.execute("0000")
	assert_str(fifth.error).is_equal(PinCheckResponse.LOCKED)
	assert_int(fifth.locked_seconds).is_equal(300)
	assert_str(unlock.execute("2580").error).is_equal(PinCheckResponse.LOCKED)
	_clock.advance(300_000)
	assert_bool(unlock.execute("2580").ok).is_true()


func test_teacher_mode_needs_a_configured_tablet() -> void:
	assert_str(UnlockTeacherMode.new(_institutions, _hasher, _clock).execute("2580").error).is_equal(PinCheckResponse.NOT_CONFIGURED)


# --- Estudiantes (RF-04) ---

func test_registers_students_in_a_section() -> void:
	var section_a := _section_id(_configure(), "A")
	assert_bool(_register(section_a, "  Wayra   Quispe ").ok).is_true()
	_register(section_a, "Ana Ccori")
	var listed := ListStudents.new(_students, _clock).execute(section_a)
	assert_array(listed.map(func(s: StudentSummary) -> String: return s.name)).is_equal(["Ana Ccori", "Wayra Quispe"])
	assert_dict(listed[0].avatar).is_empty()


func test_rejects_invalid_student_data() -> void:
	_configure()
	var response := _register("seccion-que-no-existe", "A", "12")
	assert_dict(response.errors).is_equal({"name": &"name_too_short", "section": &"section_not_found", "pin": &"pin_length"})


func test_two_students_of_a_section_cannot_share_a_name() -> void:
	var classroom := _configure()
	var section_a := _section_id(classroom, "A")
	_register(section_a, "Ángel Núñez")
	assert_str(_register(section_a, "angel nunez").errors["name"]).is_equal("name_taken")
	assert_bool(_register(_section_id(classroom, "B"), "Ángel Núñez").ok).is_true()


func test_a_deactivated_student_is_kept_and_hidden() -> void:
	var section_a := _section_id(_configure(), "A")
	var id := _register(section_a, "Luz Mamani").id
	assert_bool(SetStudentActive.new(_students).execute(id, false).is_ok()).is_true()
	assert_array(ListStudents.new(_students, _clock).execute(section_a)).is_empty()
	assert_int(ListStudents.new(_students, _clock).execute(section_a, true).size()).is_equal(1)
	assert_str(_register(section_a, "Luz Mamani").errors["name"]).is_equal("name_taken_inactive")
	assert_str(LoginStudent.new(_students, _hasher, _clock).execute(id, "4702").error).is_equal(PinCheckResponse.INACTIVE)


func test_updates_the_name_and_the_section() -> void:
	var classroom := _configure()
	var section_b := _section_id(classroom, "B")
	var id := _register(_section_id(classroom, "A"), "Kusi Rojas").id
	var form := StudentForm.new()
	form.student_id = id
	form.name = "Kusi Rojas Paz"
	form.section_id = section_b
	assert_bool(UpdateStudent.new(_institutions, _students).execute(form).ok).is_true()
	var moved := ListStudents.new(_students, _clock).execute(section_b)
	assert_str(moved[0].name).is_equal("Kusi Rojas Paz")


# --- Ingreso del estudiante (RF-05 y CU-03) ---

func test_student_logs_in_only_with_the_right_pin() -> void:
	var id := _register(_section_id(_configure(), "A"), "Sumaq Tito", "8315").id
	var login := LoginStudent.new(_students, _hasher, _clock)
	var wrong := login.execute(id, "8316")
	assert_str(wrong.error).is_equal(PinCheckResponse.WRONG_PIN)
	var right := login.execute(id, "8315")
	assert_bool(right.ok).is_true()
	assert_str(right.name).is_equal("Sumaq Tito")
	assert_bool(right.has_avatar).is_false()


func test_student_profile_locks_after_five_failures() -> void:
	var id := _register(_section_id(_configure(), "A"), "Sumaq Tito", "8315").id
	var login := LoginStudent.new(_students, _hasher, _clock)
	for i in 5:
		login.execute(id, "0000")
	assert_str(login.execute(id, "8315").error).is_equal(PinCheckResponse.LOCKED)
	var listed := ListStudents.new(_students, _clock).execute(_students.find_student(id).section_id)
	assert_bool(listed[0].locked).is_true()
	_clock.advance(300_000)
	assert_bool(login.execute(id, "8315").ok).is_true()


func test_unknown_student_cannot_log_in() -> void:
	assert_str(LoginStudent.new(_students, _hasher, _clock).execute("nadie", "1234").error).is_equal(PinCheckResponse.NOT_FOUND)


# --- Restablecer PIN (RF-17) ---

func test_reset_pin_replaces_the_old_one_and_unlocks() -> void:
	var id := _register(_section_id(_configure(), "A"), "Inti Ccahuana", "1357").id
	var login := LoginStudent.new(_students, _hasher, _clock)
	for i in 5:
		login.execute(id, "0000")
	assert_bool(ResetStudentPin.new(_students, _hasher).execute(id, "2468").ok).is_true()
	assert_str(login.execute(id, "1357").error).is_equal(PinCheckResponse.WRONG_PIN)
	assert_bool(login.execute(id, "2468").ok).is_true()
	assert_str(ResetStudentPin.new(_students, _hasher).execute(id, "24").errors["pin"]).is_equal("pin_length")


# --- Avatar (RF-31) ---

func test_customizes_the_avatar() -> void:
	var id := _register(_section_id(_configure(), "A"), "Killa Soto").id
	var traits := {"body": "girl", "skin": 3, "hair_style": 3, "hair_color": 1, "top_color": 0, "bottom_color": 5}
	assert_bool(CustomizeAvatar.new(_students).execute(id, traits).is_ok()).is_true()
	assert_dict(GetStudentProfile.new(_students, _clock).execute(id).avatar).is_equal(traits)
	assert_bool(LoginStudent.new(_students, _hasher, _clock).execute(id, "4702").has_avatar).is_true()
	assert_bool(CustomizeAvatar.new(_students).execute(id, {"body": "dragon"}).is_ok()).is_false()


func test_suggested_pin_is_never_an_easy_series() -> void:
	var random := ScriptedRandom.new([1, 1, 1, 1, 4, 7, 0, 2])
	assert_str(SuggestPin.new(random).execute()).is_equal("4702")


func test_suggested_avatar_never_repeats_the_outfit_color() -> void:
	var traits := SuggestAvatar.new(ScriptedRandom.new([2])).execute(&"boy")
	assert_str(traits["body"]).is_equal("boy")
	assert_int(traits["top_color"]).is_not_equal(traits["bottom_color"])
	assert_bool(Avatar.create(traits).is_ok()).is_true()

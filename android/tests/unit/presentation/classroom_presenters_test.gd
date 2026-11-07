extends GdUnitTestSuite
## Presentadores del aula: textos, mensajes y modelos de vista, con repositorios en memoria.

var _institutions: InMemoryInstitutionRepository
var _students: InMemoryStudentRepository
var _hasher: PlainPinHasher
var _clock: FakeClock
var _ids: SequentialIds
var _session: PlaySession


func before_test() -> void:
	_institutions = InMemoryInstitutionRepository.new()
	_students = InMemoryStudentRepository.new()
	_hasher = PlainPinHasher.new()
	_clock = FakeClock.new()
	_ids = SequentialIds.new()
	_session = PlaySession.new()


func _setup_data() -> Dictionary:
	return {
		"institution_name": "Escuela de prueba", "modular_code": "", "grade": 6, "school_year": 2026,
		"sections": ["A", "B"], "teacher_name": "Rosa Huamán", "teacher_pin": "2580",
		"teacher_pin_confirmation": "2580", "teacher_code": "",
	}


func _setup_presenter() -> SetupPresenter:
	return SetupPresenter.new(ConfigureInstitution.new(_institutions, _hasher, _ids), _clock)


func _panel() -> TeacherPanelPresenter:
	return TeacherPanelPresenter.new(GetClassroom.new(_institutions), ListStudents.new(_students, _clock),
		RegisterStudent.new(_institutions, _students, _hasher, _ids), UpdateStudent.new(_institutions, _students),
		SetStudentActive.new(_students), ResetStudentPin.new(_students, _hasher), SuggestPin.new(ScriptedRandom.new([4, 7, 0, 2])))


func _picker() -> ProfilePickerPresenter:
	return ProfilePickerPresenter.new(GetClassroom.new(_institutions), ListStudents.new(_students, _clock),
		LoginStudent.new(_students, _hasher, _clock), _session)


func test_setup_suggests_this_school_year_and_validates_each_step() -> void:
	var presenter := _setup_presenter()
	assert_int(presenter.screen().default_school_year).is_equal(2026)
	var data := _setup_data()
	data["institution_name"] = ""
	data["teacher_pin"] = "1234"
	assert_dict(presenter.validate_step(0, data)).contains_keys(["institution_name"])
	assert_dict(presenter.validate_step(1, data)).is_empty()
	assert_str(presenter.validate_step(2, data)["teacher_pin"]).contains("difícil de adivinar")


func test_setup_saves_and_reports_the_first_step_with_errors() -> void:
	var presenter := _setup_presenter()
	assert_bool(presenter.submit(_setup_data()).ok).is_true()
	assert_int(presenter.first_step_with_errors({"teacher_name": "x"})).is_equal(2)
	assert_str(presenter.submit(_setup_data()).errors["general"]).is_equal("Esta tablet ya está configurada.")


func test_panel_lists_sections_with_the_grade_and_registers_students() -> void:
	_setup_presenter().submit(_setup_data())
	var panel := _panel()
	var view_model := panel.panel()
	assert_array(view_model.sections.map(func(tab: SectionTabViewModel) -> String: return tab.label)).is_equal(["6.° A", "6.° B"])
	assert_str(panel.suggest_pin()).is_equal("4702")
	var saved := panel.register("Wayra Quispe", view_model.sections[0].id, "4702")
	assert_bool(saved.ok).is_true()
	assert_str(saved.notice).contains("4702")
	var rows := panel.students(view_model.sections[0].id)
	assert_str(rows[0].status).is_equal("Activo")
	assert_str(rows[0].detail).is_equal("Todavía no crea su personaje")
	assert_bool(rows[0].look.silhouette).is_true()


func test_panel_explains_invalid_data_in_spanish() -> void:
	_setup_presenter().submit(_setup_data())
	var panel := _panel()
	var section_id := panel.panel().sections[0].id
	var feedback := panel.register("A", section_id, "12")
	assert_str(feedback.errors["name"]).is_equal("Escribe el nombre (al menos 2 letras).")
	assert_str(feedback.errors["pin"]).is_equal("El PIN tiene 4 números.")


func test_panel_marks_deactivated_and_locked_students() -> void:
	_setup_presenter().submit(_setup_data())
	var panel := _panel()
	var section_id := panel.panel().sections[0].id
	var killa := panel.register("Killa Soto", section_id, "1357").id
	var inti := panel.register("Inti Rojas", section_id, "2468").id
	panel.set_active(killa, false)
	var login := LoginStudent.new(_students, _hasher, _clock)
	for i in 5:
		login.execute(inti, "0000")
	var rows := panel.students(section_id)
	assert_str(rows[0].status).is_equal("Bloqueado 5:00")
	assert_str(rows[1].status).is_equal("Desactivado")


func test_picker_cards_split_names_and_remember_the_section() -> void:
	_setup_presenter().submit(_setup_data())
	var section_id := _panel().panel().sections[1].id
	_panel().register("Sumaq Tito Rojas", section_id, "1357")
	var cards := _picker().students(section_id)
	assert_str(cards[0].first_line).is_equal("Sumaq")
	assert_str(cards[0].second_line).is_equal("Tito Rojas")
	assert_str(_picker().screen().selected_section_id).is_equal(section_id)


func test_picker_login_feedback_is_kind_and_counts_attempts() -> void:
	_setup_presenter().submit(_setup_data())
	var section_id := _panel().panel().sections[0].id
	var id := _panel().register("Sumaq Tito", section_id, "1357").id
	var picker := _picker()
	assert_str(picker.login(id, "0000").message).is_equal("Inténtalo otra vez.")
	picker.login(id, "0000")
	assert_str(picker.login(id, "0000").message).contains("Te quedan 2 intentos")
	assert_str(picker.login(id, "0000").message).contains("Te queda 1 intento")
	var locked := picker.login(id, "0000")
	assert_bool(locked.locked).is_true()
	assert_str(locked.message).contains("5:00")
	_clock.advance(300_000)
	var welcome := picker.login(id, "1357")
	assert_bool(welcome.ok).is_true()
	assert_str(welcome.title).is_equal("¡Qué bueno verte, Sumaq!")
	assert_str(_session.student_id).is_equal(id)


func test_avatar_editor_starts_new_profiles_with_a_suggestion() -> void:
	_setup_presenter().submit(_setup_data())
	var section_id := _panel().panel().sections[0].id
	_session.student_id = _panel().register("Kusi Mamani", section_id, "1357").id
	var editor := AvatarEditorPresenter.new(GetStudentProfile.new(_students, _clock), CustomizeAvatar.new(_students),
		SuggestAvatar.new(ScriptedRandom.new([1])), _session)
	var view_model := editor.editor()
	assert_str(view_model.title).is_equal("¡Crea tu personaje!")
	assert_str(view_model.greeting).contains("Kusi")
	assert_str(editor.bottom_label(view_model.traits)).is_equal("Pantalón")
	assert_bool(editor.save(view_model.traits).ok).is_true()
	assert_str(editor.editor().title).is_equal("Cambia tu personaje")


func test_title_tells_the_teaser_once_per_session() -> void:
	var settings := FakeSettingsRepository.new()
	var title := TitlePresenter.new(GetStoryScene.new(JsonStoryRepository.new("res://content/story")),
		GetAudioSettings.new(settings), ToggleSound.new(settings, FakeAudioMixer.new()), "0.1.0", _session)
	assert_bool(title.should_tell_teaser()).is_true()
	title.mark_teaser_told()
	assert_bool(title.should_tell_teaser()).is_false()
	assert_str(title.not_configured_notice()).contains("Docente")

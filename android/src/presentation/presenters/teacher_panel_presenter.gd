class_name TeacherPanelPresenter
extends RefCounted
## Presentador del modo docente: estudiantes por sección (RF-04), PIN (RF-17), la pestaña de
## paquetes (la arma PackagesPresenter) y las de lo que viene en los próximos sprints.

const AUTO_LOCK_SECONDS := 300

var _get_classroom: GetClassroom
var _list_students: ListStudents
var _register: RegisterStudent
var _update: UpdateStudent
var _set_active: SetStudentActive
var _reset_pin: ResetStudentPin
var _suggest_pin: SuggestPin


func _init(get_classroom: GetClassroom, list_students: ListStudents, register: RegisterStudent, update: UpdateStudent,
		set_active: SetStudentActive, reset_pin: ResetStudentPin, suggest_pin: SuggestPin) -> void:
	_get_classroom = get_classroom
	_list_students = list_students
	_register = register
	_update = update
	_set_active = set_active
	_reset_pin = reset_pin
	_suggest_pin = suggest_pin


func panel() -> TeacherPanelViewModel:
	var classroom := _get_classroom.execute()
	var view_model := TeacherPanelViewModel.new()
	view_model.title = classroom.institution_name
	view_model.subtitle = "Modo docente · %d.° grado · %d · %s" % [classroom.grade, classroom.school_year, classroom.teacher_name]
	view_model.exit_label = "Salir"
	view_model.add_label = "Agregar estudiante"
	view_model.empty_message = "Todavía no hay estudiantes en esta sección.\nToca «Agregar estudiante» para registrar al primero."
	view_model.auto_lock_seconds = AUTO_LOCK_SECONDS
	view_model.tabs = [
		{"id": "students", "label": "Estudiantes", "enabled": true, "soon": ""},
		{"id": "packages", "label": "Paquetes", "enabled": true, "soon": ""},
		{"id": "reports", "label": "Reportes", "enabled": false, "soon": "Sprint 10"},
		{"id": "settings", "label": "Ajustes", "enabled": false, "soon": "Sprint 8"},
	]
	for section in classroom.sections:
		view_model.sections.append(SectionTabViewModel.create(section["id"], "%d.° %s" % [classroom.grade, section["name"]]))
	return view_model


func students(section_id: String) -> Array[StudentRowViewModel]:
	var rows: Array[StudentRowViewModel] = []
	for summary in _list_students.execute(section_id, true):
		var row := StudentRowViewModel.new()
		row.id = summary.id
		row.name = summary.name
		row.section_id = summary.section_id
		row.look = AvatarPalette.look_for(summary.avatar)
		row.active = summary.active
		row.detail = "Ya creó su personaje" if not summary.avatar.is_empty() else "Todavía no crea su personaje"
		if not summary.active:
			row.status = "Desactivado"
			row.status_kind = &"muted"
		elif summary.locked:
			row.status = "Bloqueado %s" % ClassroomMessages.clock_text(summary.locked_seconds)
			row.status_kind = &"alert"
		else:
			row.status = "Activo"
			row.status_kind = &"ok"
		rows.append(row)
	return rows


func suggest_pin() -> String:
	return _suggest_pin.execute()


func register(name: String, section_id: String, pin: String) -> FormFeedbackViewModel:
	var form := StudentForm.new()
	form.name = name
	form.section_id = section_id
	form.pin = pin
	var feedback := _feedback(_register.execute(form))
	if feedback.ok:
		feedback.notice = "Estudiante registrado. Anota su PIN: %s" % pin.strip_edges()
	return feedback


func update(student_id: String, name: String, section_id: String) -> FormFeedbackViewModel:
	var form := StudentForm.new()
	form.student_id = student_id
	form.name = name
	form.section_id = section_id
	var feedback := _feedback(_update.execute(form))
	if feedback.ok:
		feedback.notice = "Cambios guardados."
	return feedback


func reset_pin(student_id: String, pin: String) -> FormFeedbackViewModel:
	var feedback := _feedback(_reset_pin.execute(student_id, pin))
	if feedback.ok:
		feedback.notice = "PIN nuevo guardado: %s. El anterior ya no funciona." % pin.strip_edges()
	return feedback


func set_active(student_id: String, active: bool) -> String:
	var saved := _set_active.execute(student_id, active)
	if not saved.is_ok():
		return ClassroomMessages.text_for(&"save_failed")
	return "Estudiante reactivado." if active else "Estudiante desactivado. Sus resultados se conservan."


static func _feedback(response: FormResponse) -> FormFeedbackViewModel:
	var feedback := FormFeedbackViewModel.new()
	feedback.ok = response.ok
	feedback.id = response.id
	feedback.errors = ClassroomMessages.field_messages(response.errors)
	return feedback

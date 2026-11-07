class_name ProfilePickerPresenter
extends RefCounted
## Presentador de «¿Quién va a jugar hoy?»: secciones, tarjetas de estudiantes y PIN (RF-05).

var _get_classroom: GetClassroom
var _list_students: ListStudents
var _login: LoginStudent
var _session: PlaySession


func _init(get_classroom: GetClassroom, list_students: ListStudents, login: LoginStudent, session: PlaySession) -> void:
	_get_classroom = get_classroom
	_list_students = list_students
	_login = login
	_session = session


func screen() -> ProfilePickerViewModel:
	var view_model := ProfilePickerViewModel.new()
	view_model.title = "¿Quién va a jugar hoy?"
	view_model.hint = "Busca tu nombre y toca tu personaje."
	view_model.back_label = "Inicio"
	view_model.empty_message = "Todavía no hay estudiantes en esta sección.\nPide a tu profe que los registre en el modo docente."
	view_model.pin_prompt = "Escribe tu PIN secreto"
	view_model.not_me_label = "No soy yo"
	var classroom := _get_classroom.execute()
	for section in classroom.sections:
		view_model.sections.append(SectionTabViewModel.create(section["id"], "%d.° %s" % [classroom.grade, section["name"]]))
	view_model.selected_section_id = _session.section_id
	var known := view_model.sections.any(func(tab: SectionTabViewModel) -> bool: return tab.id == _session.section_id)
	if not known and not view_model.sections.is_empty():
		view_model.selected_section_id = view_model.sections[0].id
	return view_model


func students(section_id: String) -> Array[ProfileCardViewModel]:
	_session.section_id = section_id
	var cards: Array[ProfileCardViewModel] = []
	for summary in _list_students.execute(section_id):
		var card := ProfileCardViewModel.new()
		card.id = summary.id
		card.name = summary.name
		var parts := ClassroomMessages.split_name(summary.name)
		card.first_line = parts[0]
		card.second_line = parts[1]
		card.look = AvatarPalette.look_for(summary.avatar)
		card.has_avatar = not summary.avatar.is_empty()
		card.locked = summary.locked
		cards.append(card)
	return cards


func greeting(card: ProfileCardViewModel) -> String:
	return "¡Hola, %s!" % card.first_line


func login(student_id: String, pin: String) -> PinFeedbackViewModel:
	var response := _login.execute(student_id, pin)
	var feedback := PinFeedbackViewModel.new()
	feedback.ok = response.ok
	if response.ok:
		_session.student_id = response.id
		feedback.name = ClassroomMessages.split_name(response.name)[0]
		feedback.has_avatar = response.has_avatar
		feedback.title = "¡Qué bueno verte, %s!" % feedback.name
		return feedback
	match response.error:
		PinCheckResponse.LOCKED:
			feedback.locked = true
			feedback.locked_seconds = response.locked_seconds
			feedback.title = "Tu perfil está descansando"
			feedback.message = "Vuelve a intentarlo en %s. Si no recuerdas tu PIN, pide ayuda a tu profe." % ClassroomMessages.clock_text(response.locked_seconds)
		PinCheckResponse.WRONG_PIN:
			feedback.title = "¡Uy! Ese no es tu PIN"
			feedback.message = _attempts_message(response.attempts_left)
		_:
			feedback.title = "No pudimos abrir tu perfil"
			feedback.message = "Pide ayuda a tu profe."
	return feedback


## Texto del bloqueo mientras corre la cuenta regresiva.
func locked_message(seconds: int) -> String:
	return "Vuelve a intentarlo en %s. Si no recuerdas tu PIN, pide ayuda a tu profe." % ClassroomMessages.clock_text(seconds)


static func _attempts_message(left: int) -> String:
	if left > 2:
		return "Inténtalo otra vez."
	if left == 2:
		return "Te quedan 2 intentos. Si no lo recuerdas, pide ayuda a tu profe."
	return "Te queda 1 intento. Si no lo recuerdas, pide ayuda a tu profe."

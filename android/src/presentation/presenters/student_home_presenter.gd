class_name StudentHomePresenter
extends RefCounted
## Presentador del inicio del estudiante, mientras llega el mapa de la aventura (Sprint 5).

var _get_profile: GetStudentProfile
var _session: PlaySession


func _init(get_profile: GetStudentProfile, session: PlaySession) -> void:
	_get_profile = get_profile
	_session = session


func home() -> StudentHomeViewModel:
	var view_model := StudentHomeViewModel.new()
	var profile := _get_profile.execute(_session.student_id)
	var first_name := ClassroomMessages.split_name(profile.name)[0] if profile else ""
	view_model.greeting = "¡Hola, %s!" % first_name
	view_model.message = "Quwi está preparando el mapa de la aventura."
	view_model.sign_title = "Mapa de la Sierra"
	view_model.sign_text = "¡Muy pronto!"
	view_model.look = AvatarPalette.look_for(profile.avatar if profile else {})
	view_model.edit_label = "Mi personaje"
	view_model.exit_label = "Salir"
	return view_model


func log_out() -> void:
	_session.log_out()

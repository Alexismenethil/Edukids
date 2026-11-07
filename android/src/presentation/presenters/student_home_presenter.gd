class_name StudentHomePresenter
extends RefCounted
## Presentador del inicio del estudiante. Mientras llega el mapa de la aventura (Sprint 5),
## muestra los niveles disponibles con sus estrellas.

var _get_profile: GetStudentProfile
var _list_levels: ListLevels
var _session: PlaySession


func _init(get_profile: GetStudentProfile, list_levels: ListLevels, session: PlaySession) -> void:
	_get_profile = get_profile
	_list_levels = list_levels
	_session = session


func home() -> StudentHomeViewModel:
	var view_model := StudentHomeViewModel.new()
	var profile := _get_profile.execute(_session.student_id)
	var first_name := ClassroomMessages.split_name(profile.name)[0] if profile else ""
	view_model.greeting = "¡Hola, %s!" % first_name
	view_model.message = PlayMessages.HOME_MESSAGE
	view_model.levels_title = PlayMessages.HOME_LEVELS
	view_model.look = AvatarPalette.look_for(profile.avatar if profile else {})
	view_model.edit_label = "Mi personaje"
	view_model.exit_label = "Salir"
	for card in _list_levels.execute(_session.student_id):
		var level := LevelCardViewModel.new()
		level.package_id = card.package_id
		level.level_id = card.level_id
		level.title = card.title
		level.area = AreaViewModel.of(card.area)
		level.details = "%s · %s" % [level.area.name, PlayMessages.details(card.question_count, card.estimated_minutes)]
		level.stars = card.best_stars
		level.action_label = PlayMessages.RESUME if card.in_progress else PlayMessages.PLAY
		level.badge = PlayMessages.HALF_DONE if card.in_progress else ""
		view_model.levels.append(level)
	return view_model


## Recuerda qué nivel eligió para que la pantalla del nivel lo abra.
func choose(level: LevelCardViewModel) -> void:
	_session.choose_level(level.package_id, level.level_id)


func log_out() -> void:
	_session.log_out()

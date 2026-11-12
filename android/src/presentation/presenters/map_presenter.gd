class_name MapPresenter
extends RefCounted
## Presentador del mapa: el capítulo con sus paradas y cada parada con sus senderos
## (RN-01, RN-18 y RF-22). Desde el mapa del capítulo se llega a un nivel en tres toques:
## la parada, el nudo del sendero y «¡Jugar!».

var _get_profile: GetStudentProfile
var _get_map: GetChapterMap
var _session: PlaySession


func _init(get_profile: GetStudentProfile, get_map: GetChapterMap, session: PlaySession) -> void:
	_get_profile = get_profile
	_get_map = get_map
	_session = session


func chapter() -> ChapterMapViewModel:
	var view_model := ChapterMapViewModel.new()
	var profile := _get_profile.execute(_session.student_id)
	var first_name := ClassroomMessages.split_name(profile.name)[0] if profile else ""
	view_model.chapter_name = MapMessages.CHAPTER_NAME
	view_model.chapter_title = MapMessages.CHAPTER_TITLE
	view_model.greeting = MapMessages.greeting(first_name)
	view_model.guide_line = MapMessages.MAP_GUIDE
	view_model.look = AvatarPalette.look_for(profile.avatar if profile else {})
	view_model.edit_label = MapMessages.EDIT
	view_model.story_label = MapMessages.STORY
	view_model.exit_label = MapMessages.EXIT
	var map := _get_map.execute(_session.student_id, _session.chapter)
	view_model.stars_label = str(map.stars)
	for index in map.stops.size():
		var stop := map.stops[index]
		var pin := StopPinViewModel.new()
		pin.id = stop.id
		pin.name = MapMessages.stop_name(stop.id)
		pin.about = MapMessages.stop_about(stop.id)
		pin.icon = MapMessages.stop_icon(stop.id)
		pin.available = stop.available
		pin.locked_text = "" if stop.available else MapMessages.LOCKED
		pin.stars = stop.stars
		pin.max_stars = stop.max_stars
		pin.stars_label = MapMessages.stars(stop.stars, stop.max_stars)
		pin.cords = stop.cords
		for trail in stop.trails:
			pin.colors.append(AreaPalette.color_of(trail.area))
		view_model.stops.append(pin)
	view_model.current = -1
	for index in view_model.stops.size():
		if view_model.stops[index].id == _session.stop_id:
			view_model.current = index
	for index in view_model.stops.size():
		if view_model.current < 0 and view_model.stops[index].available:
			view_model.current = index
	view_model.current = maxi(view_model.current, 0)
	return view_model


## La parada elegida (o la última visitada) con sus senderos.
func stop(stop_id: String = "") -> StopViewModel:
	if not stop_id.is_empty():
		_session.choose_stop(stop_id)
	var view_model := StopViewModel.new()
	view_model.id = _session.stop_id
	view_model.name = MapMessages.stop_name(_session.stop_id)
	view_model.about = MapMessages.stop_about(_session.stop_id)
	view_model.back_label = MapMessages.BACK
	var profile := _get_profile.execute(_session.student_id)
	view_model.look = AvatarPalette.look_for(profile.avatar if profile else {})
	var guide := DialogueViewModel.new()
	guide.lines.append(DialogueLineViewModel.new(PlayMessages.GUIDE, MapMessages.STOP_GUIDE, &"joy"))
	guide.close_label = "¡Vamos!"
	guide.skip_label = ""
	view_model.guide = guide
	var map := _get_map.execute(_session.student_id, _session.chapter)
	for found in map.stops:
		if found.id != _session.stop_id:
			continue
		view_model.stars_label = MapMessages.stars(found.stars, found.max_stars)
		for trail in found.trails:
			view_model.trails.append(_trail(trail))
	return view_model


## Recuerda qué nivel eligió para que la pantalla del nivel lo abra.
func choose(node: TrailNodeViewModel) -> bool:
	if not node.playable:
		return false
	_session.choose_level(node.package_id, node.level_id)
	return true


func log_out() -> void:
	_session.log_out()


func _trail(trail: TrailResponse) -> TrailViewModel:
	var view_model := TrailViewModel.new()
	view_model.area = AreaViewModel.of(trail.area)
	view_model.title = MapMessages.trail_title(view_model.area.name)
	view_model.stars_label = MapMessages.stars(trail.stars, trail.max_stars)
	var suggested := false
	for node in trail.nodes:
		var item := _node(node)
		if not suggested and item.playable and (item.state == TrailRule.OPEN or node.in_progress):
			item.next = true
			suggested = true
		view_model.nodes.append(item)
	return view_model


func _node(node: TrailNodeResponse) -> TrailNodeViewModel:
	var view_model := TrailNodeViewModel.new()
	view_model.package_id = node.package_id
	view_model.level_id = node.level_id
	view_model.title = node.title
	view_model.final = node.kind == LevelEntry.FINAL
	var mechanic := MapMessages.mechanic_of(node.mechanic, view_model.final)
	view_model.mechanic = &"final" if view_model.final else node.mechanic
	view_model.mechanic_name = mechanic["name"]
	view_model.mechanic_about = mechanic["about"]
	view_model.icon = mechanic["icon"]
	var details := PlayMessages.details(node.question_count, node.estimated_minutes)
	view_model.details = details if view_model.final else "%s · %s" % [details, MapMessages.lives(node.lives)]
	view_model.state = node.state
	view_model.stars = node.best_stars
	view_model.grade = node.best_grade
	view_model.grade_color = PlayMessages.GRADE_COLORS.get(node.best_grade, Color("#8C8079"))
	view_model.badge = MapMessages.HALF_DONE if node.in_progress else ""
	view_model.playable = node.state != TrailRule.LOCKED
	if node.state == TrailRule.LOCKED:
		view_model.locked_text = MapMessages.final_locked(node.unlocked_by) if view_model.final \
			else MapMessages.locked_by(node.unlocked_by)
	if view_model.final:
		view_model.attempts_text = MapMessages.attempts(node.attempts_left, node.max_attempts)
		if node.attempts_left <= 0 and not node.in_progress:
			view_model.playable = false
	if node.in_progress:
		view_model.action_label = MapMessages.RESUME
	elif node.state == TrailRule.DONE:
		view_model.action_label = MapMessages.REPLAY
	else:
		view_model.action_label = MapMessages.PLAY
	return view_model

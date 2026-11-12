class_name ChaseStage
extends MechanicStage
## Persecución: el avatar corre y Atoq lo persigue. El mundo de su región pasa sin fin: el valle
## del Qhapaq Ñan en la Sierra, la selva del Apurímac o la costa (WorldSets). Cada acierto hace que el avatar acelere y
## salte una piedra con un giro; cada error, que tropiece y Atoq se acerque riendo. Si el medidor
## llega a 0, Atoq se lanza, lo alcanza y se lleva un nudo. Al final, el avatar cruza el arco tejido.

const WORLD := "res://assets/art/worlds/valley/"
const AVATAR_SCALE := 0.5
const ATOQ_SCALE := 0.72
const TROT := 150.0
const SPRINT := 620.0
const RUNNER_X := 760.0
const PROPS := ["prop_stone", "prop_apacheta", "prop_ichu"]

var _avatar: AvatarCharacter
var _atoq: AtoqCharacter
var _track: Node2D
var _speed := 0.0
var _target := 0.0
var _gap := 520.0
var _gap_target := 420.0
var _finishing := false
var _caught := false
var _arch: Sprite2D
var _arch_knot: KnotSprite
var _lines: _SpeedLines
## Variantes que tocan en orden barajado, para que dos respuestas seguidas no se vean igual.
var _good_moves: Array[StringName] = []
var _bad_moves: Array[StringName] = []
var _glance := 2.0
var _warm := Color(1.0, 0.93, 0.82)
## Obstáculos en el camino: {"node", "jump", "life_lost", "done"}.
var _obstacles: Array[Dictionary] = []


func _build_world() -> void:
	ground_y = 652.0
	focus_x = 640.0
	# El mundo de la región del nivel: el valle en la Sierra, la selva o la costa.
	var place := WorldSets.build(world, WorldSets.REGION_WORLDS.get(region, &"valley"))
	_track = place["track"]
	actors = place["stage"]
	_lines = _SpeedLines.new()
	actors.add_child(_lines)
	_avatar = _make_avatar(AVATAR_SCALE)
	_avatar.position = Vector2(RUNNER_X, ground_y)
	actors.add_child(_avatar)
	_atoq = AtoqCharacter.new()
	_atoq.scale = Vector2.ONE * ATOQ_SCALE
	_atoq.position = Vector2(RUNNER_X - _gap, ground_y)
	_atoq.curious = false
	_atoq.interactive = true
	actors.add_child(_atoq)
	_atoq.look_toward(Vector2(1.0, -0.3))
	watch(_avatar, true)
	watch(_atoq)
	_gap_target = _gap_for(danger)


func start() -> void:
	_target = TROT


func _gap_for(value: int) -> float:
	var ratio := clampf(float(value - 1) / maxf(1.0, danger_max - 1.0), 0.0, 1.0)
	return 150.0 + ratio * 330.0


func _process(delta: float) -> void:
	super(delta)
	if world == null:
		return
	_speed = move_toward(_speed, _target, delta * 900.0)
	world.cam_x += _speed * delta
	var running := _speed > 8.0
	_avatar.run_speed = clampf(_speed / TROT, 0.8, 2.2) if running else 0.0
	_atoq.speed = clampf(_speed / TROT, 0.7, 2.4) if running else 0.0
	_gap = lerpf(_gap, _gap_target, minf(1.0, delta * 2.4))
	_atoq.position.x = RUNNER_X - _gap + sin(_time * 2.4) * 8.0
	_lines.strength = clampf((_speed - TROT * 1.6) / (SPRINT - TROT * 1.6), 0.0, 1.0)
	_lines.origin = _avatar.position + Vector2(-60, -90)
	_update_mood(delta)
	_update_obstacles()
	if _arch and _finishing and not _caught:
		var arch_x := _arch.position.x - world.cam_x
		if arch_x <= RUNNER_X + 10.0 and _target > 0.0:
			_reach_goal()


## El avatar corre decidido; si Atoq está cerca, se preocupa y mira hacia atrás de reojo.
func _update_mood(delta: float) -> void:
	if _finishing or _caught:
		return
	var close := _gap < 240.0
	_avatar.set_expression(&"worry" if close else (&"determined" if _speed > TROT * 2.0 else &"neutral"))
	_atoq.set_expression(&"determined" if close else &"neutral")
	_glance -= delta
	if _glance <= 0.0:
		_glance = randf_range(1.8, 3.4) if close else randf_range(3.5, 6.0)
		if close or randf() < 0.5:
			_avatar.look_toward(Vector2(-1.0, 0.1), 0.7)


## Los obstáculos guionados: el avatar salta (o tropieza) cuando le llegan a los pies.
func _update_obstacles() -> void:
	for obstacle in _obstacles:
		var node: Node2D = obstacle["node"]
		var screen_x := node.position.x - world.cam_x
		if not obstacle["done"] and screen_x - RUNNER_X < (120.0 if obstacle["jump"] else 36.0):
			obstacle["done"] = true
			match obstacle.get("move", &""):
				&"double":
					_double_hop()
				&"knot":
					_grab_knot(node)
				&"trip":
					_trip(obstacle["life_lost"])
				_:
					_jump()
	_obstacles = _obstacles.filter(func(obstacle: Dictionary) -> bool:
		var node: Node2D = obstacle["node"]
		if node.position.x - world.cam_x < -400.0:
			node.queue_free()
			return false
		return true)


func react(feedback: FeedbackViewModel) -> float:
	danger = feedback.danger
	if feedback.correct:
		_target = SPRINT
		_gap_target = _gap_for(danger) + 60.0
		# Cada acierto se ve distinto: voltereta sobre una piedra, dos saltitos, un nudo que atrapa
		# en el aire o una carrera a toda velocidad. La racha de tres siempre es la carrera.
		var move := &"dash" if feedback.streak > 0 and feedback.streak % 3 == 0 else _next_move(_good_moves, [&"flip", &"double", &"knot", &"dash"])
		match move:
			&"dash":
				_dash(feedback.streak >= 3)
			&"double":
				_place_obstacle(true, false, &"double", "prop_ichu")
				_place_obstacle(true, false, &"none", "prop_ichu", 190.0)
			&"knot":
				_place_knot()
			_:
				_place_obstacle(true, false, &"flip", "prop_stone" if randf() < 0.6 else "prop_apacheta")
		return 1.9
	_target = TROT * 1.6
	if feedback.life_lost:
		_place_obstacle(false, true, &"trip")
		return 3.3
	# Los errores también varían: un tropezón, Atoq que se acerca agazapado o que se burla aullando.
	match _next_move(_bad_moves, [&"trip", &"sneak", &"taunt"]):
		&"sneak":
			_atoq_gag(&"sneak", "¡Shh!")
		&"taunt":
			_atoq_gag(&"howl", "¡Auuu!")
		_:
			_place_obstacle(false, false, &"trip")
	return 1.9


## Siguiente variante de una lista barajada; al acabarse se vuelve a barajar sin repetir la última.
func _next_move(queue: Array[StringName], options: Array[StringName]) -> StringName:
	if queue.is_empty():
		var last: StringName = get_meta(&"last_move", &"")
		queue.assign(options)
		queue.shuffle()
		if queue.size() > 1 and queue[queue.size() - 1] == last:
			queue.reverse()
	var move: StringName = queue.pop_back()
	set_meta(&"last_move", move)
	return move


func _place_obstacle(jump: bool, life_lost: bool, move: StringName = &"flip", prop: String = "", extra: float = 0.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(WORLD + (prop if not prop.is_empty() else PROPS[randi() % PROPS.size()]) + ".svg")
	sprite.scale = Vector2.ONE * 0.5
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5 + 6.0)
	var ahead := (600.0 if jump else 300.0) + extra
	sprite.position = Vector2(world.cam_x + RUNNER_X + ahead, ground_y + 4.0)
	_track.add_child(sprite)
	_obstacles.append({"node": sprite, "jump": jump, "life_lost": life_lost, "done": move == &"none", "move": move})


## Un nudo dorado flota sobre el camino: el avatar salta y lo atrapa.
func _place_knot() -> void:
	var knot := KnotSprite.new()
	knot.color = StageFx.KNOT_COLORS[randi() % StageFx.KNOT_COLORS.size()]
	knot.radius = 15.0
	knot.position = Vector2(world.cam_x + RUNNER_X + 600.0, ground_y - 250.0)
	_track.add_child(knot)
	var bob := knot.create_tween().set_loops()
	bob.tween_property(knot, "position:y", knot.position.y - 14.0, 0.4).set_trans(Tween.TRANS_SINE)
	bob.tween_property(knot, "position:y", knot.position.y, 0.4).set_trans(Tween.TRANS_SINE)
	_obstacles.append({"node": knot, "jump": true, "life_lost": false, "done": false, "move": &"knot"})


func _grab_knot(knot: Node2D) -> void:
	ToonFx.puff(actors, _avatar.position + Vector2(-20, -4), 5, 13.0, Vector2(-120.0, 0.0))
	_avatar.leap(128.0, false)
	_avatar.look_toward(Vector2(0.4, -1.0), 0.5)
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(func() -> void:
		if is_instance_valid(knot):
			knot.visible = false
		ToonFx.ring(actors, _avatar.position + Vector2(20, -270), 22.0, Color(1.0, 0.92, 0.6, 0.9))
		ToonFx.sparkles(actors, _avatar.position + Vector2(20, -270), 12, 70.0)
		ToonFx.stars(actors, _avatar.position + Vector2(20, -250), 6)
		StageFx.float_text(actors, "¡Nudo!", _avatar.position + Vector2(90, -300), Color("#FFF3B0"), 40)
		punch(0.04))
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void:
		_atoq.surprise(0.9)
		_gap_target = _gap_for(danger)
		if not _finishing:
			_target = TROT)


## Dos matas seguidas: dos saltitos rápidos.
func _double_hop() -> void:
	StageFx.float_text(actors, "¡Hop, hop!", _avatar.position + Vector2(70, -250), Color("#FFF3B0"), 38)
	var tween := create_tween()
	for i in 2:
		tween.tween_callback(func() -> void:
			Sounds.play(&"hop", 1.1 + i * 0.12, -7.0)
			_avatar.hop(74.0, 0.34))
		tween.tween_interval(0.36)
	tween.tween_callback(func() -> void:
		ToonFx.stars(actors, _avatar.position + Vector2(0, -24), 5)
		_atoq.surprise(0.8)
		_atoq.emote(&"sweat", 1.0)
		_gap_target = _gap_for(danger)
		if not _finishing:
			_target = TROT)


## Carrera a toda velocidad: el mundo pasa volando y Atoq se queda muy atrás.
func _dash(streak: bool) -> void:
	Sounds.play(&"whoosh", 1.0, -3.0)
	_target = SPRINT * 1.35
	_avatar.set_expression(&"determined")
	_avatar.look_reset()
	ToonFx.streaks(actors, _avatar.position + Vector2(-10, -90), 12, 110.0)
	ToonFx.puff(actors, _avatar.position + Vector2(-30, -4), 8, 16.0, Vector2(-260.0, 0.0))
	StageFx.float_text(actors, "¡Racha!" if streak else "¡Zuum!", _avatar.position + Vector2(70, -250), Color("#FFF3B0"), 44 if streak else 40)
	_gap_target = _gap_for(danger_max) + 120.0
	_atoq.surprise(1.2)
	_atoq.emote(&"sweat", 1.2)
	if streak:
		punch(0.05)
		ToonFx.stars(actors, _avatar.position + Vector2(0, -120), 10, 15.0)
		ToonFx.sparkles(actors, _avatar.position + Vector2(0, -140), 14, 120.0)
	var tween := create_tween()
	tween.tween_interval(1.25)
	tween.tween_callback(func() -> void:
		_gap_target = _gap_for(danger)
		if not _finishing:
			_target = TROT)


## Atoq hace de las suyas en vez de que el avatar tropiece: se acerca agazapado o se burla.
func _atoq_gag(clip: StringName, text: String) -> void:
	_gap_target = _gap_for(maxi(1, danger))
	_avatar.express(&"worry", 1.4)
	_avatar.look_toward(Vector2(-1.0, 0.1), 1.2)
	_atoq.play(clip)
	StageFx.float_text(actors, text, _atoq.position + Vector2(30, -230), Color("#FFE0C2"), 36)
	var tween := create_tween()
	tween.tween_interval(1.1)
	tween.tween_callback(func() -> void:
		_atoq.laugh(0.9)
		if not _finishing and not _caught:
			_target = TROT)


## Acierto: salto grande con giro, polvo al despegar y al caer, chispas y Atoq que se queda atrás.
func _jump() -> void:
	ToonFx.puff(actors, _avatar.position + Vector2(-20, -4), 6, 15.0, Vector2(-140.0, 0.0))
	ToonFx.streaks(actors, _avatar.position + Vector2(0, -60), 8, 70.0)
	_avatar.leap(118.0, true)
	StageFx.float_text(actors, "¡Hop!", _avatar.position + Vector2(70, -250), Color("#FFF3B0"), 40)
	var tween := create_tween()
	tween.tween_interval(0.36)
	tween.tween_callback(func() -> void: ToonFx.sparkles(actors, _avatar.position + Vector2(0, -230), 8, 80.0))
	tween.tween_interval(0.35)
	tween.tween_callback(func() -> void:
		ToonFx.ring(actors, _avatar.position + Vector2(0, -4), 26.0, Color(1, 1, 1, 0.85), 0.3)
		ToonFx.stars(actors, _avatar.position + Vector2(0, -24), 7)
		punch(0.045)
		shake(4.0, 0.2)
		_atoq.surprise(0.9)
		_atoq.emote(&"sweat", 1.0)
		_gap_target = _gap_for(danger))
	tween.tween_interval(0.55)
	tween.tween_callback(func() -> void:
		if not _finishing:
			_target = TROT)


## Error: tropieza con la piedra y Atoq se acerca riendo. Si se pierde una vida, Atoq se lanza,
## lo alcanza y se lleva un nudo.
func _trip(life_lost: bool) -> void:
	_avatar.stumble()
	_target = 30.0
	shake(7.0, 0.3)
	hit_stop(0.06)
	ToonFx.impact(actors, _avatar.position + Vector2(46, -22), 38.0)
	ToonFx.puff(actors, _avatar.position + Vector2(20, -6), 7, 15.0, Vector2(90.0, 0.0))
	StageFx.float_text(actors, "¡Uy!", _avatar.position + Vector2(80, -230), Color("#FFD1D8"), 40)
	_atoq.laugh(1.4)
	_gap_target = 230.0 if life_lost else _gap_for(maxi(1, danger))
	var tween := create_tween()
	if life_lost:
		tween.tween_interval(0.5)
		tween.tween_callback(func() -> void:
			cinema(true)
			light(Color(0.86, 0.9, 1.0), 0.4)
			close_on(Vector2(RUNNER_X - 110.0, ground_y - 90.0), 0.4)
			_gap_target = 205.0
			_atoq.lunge(52.0))
		tween.tween_interval(0.42)
		tween.tween_callback(func() -> void:
			shake(10.0, 0.35)
			hit_stop(0.1)
			flash(Color(1, 1, 1, 0.35), 0.35)
			punch(0.07)
			ToonFx.impact(actors, _avatar.position + Vector2(-62, -120), 50.0)
			life_taken.emit()
			_avatar.startle()
			StageFx.fly_knot(actors, _avatar.position + Vector2(-20, -120), _atoq.position + Vector2(10, -150),
				StageFx.KNOT_COLORS[randi() % StageFx.KNOT_COLORS.size()], 0.5)
			_atoq.laugh(2.0)
			StageFx.float_text(actors, "¡Je, je!", _atoq.position + Vector2(30, -230), Color("#FFE0C2"), 38))
		tween.tween_interval(1.0)
		tween.tween_callback(func() -> void:
			_gap_target = _gap_for(maxi(1, danger))
			cinema(false)
			light(journey_light(), 0.6))
	tween.tween_interval(0.55)
	tween.tween_callback(func() -> void:
		if not _finishing and not _caught:
			_target = TROT)


func play_payoff() -> void:
	_finishing = true
	_target = SPRINT * 0.75
	for obstacle in _obstacles:
		(obstacle["node"] as Node2D).queue_free()
	_obstacles.clear()
	_arch = Sprite2D.new()
	_arch.texture = load(WORLD + "prop_arch.svg")
	_arch.scale = Vector2.ONE * 0.5
	_arch.offset = Vector2(0, -_arch.texture.get_height() * 0.5)
	_arch.position = Vector2(world.cam_x + RUNNER_X + 900.0, ground_y + 6.0)
	_track.add_child(_arch)
	_arch_knot = KnotSprite.new()
	_arch_knot.color = Color("#F2C14E")
	_arch_knot.radius = 16.0
	_arch_knot.position = Vector2(0, -150.0)
	_arch.add_child(_arch_knot)


func play_game_over() -> void:
	_caught = true
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(func() -> void:
		_target = 0.0
		_gap_target = 200.0
		cinema(true)
		light(Color(0.84, 0.88, 1.0), 0.8)
		close_on(Vector2(RUNNER_X - 120.0, ground_y - 100.0), 0.6)
		_avatar.set_expression(&"sad")
		_avatar.look_toward(Vector2(-1.0, 0.2))
		_atoq.laugh(1.6))
	tween.tween_interval(0.7)
	tween.tween_callback(func() -> void:
		for i in 3:
			StageFx.fly_knot(actors, _avatar.position + Vector2(-10, -120), _atoq.position + Vector2(20, -150),
				StageFx.KNOT_COLORS[i], 0.45 + i * 0.12)
		_avatar.play(&"sad"))
	tween.tween_interval(0.9)
	tween.tween_callback(func() -> void: _atoq.play(&"howl"))
	tween.tween_interval(1.4)
	tween.tween_callback(payoff_finished.emit)


## La meta: el avatar atraviesa el arco tejido, el nudo dorado sale volando y Atoq rueda.
func _reach_goal() -> void:
	_target = 0.0
	close_on(Vector2(RUNNER_X - 40.0, ground_y - 110.0), 0.6)
	var knot_at := _arch.position - Vector2(world.cam_x, 0.0) + Vector2(0, -75.0)
	if _arch_knot:
		_arch_knot.queue_free()
		_arch_knot = null
	cinema(true)
	light(_warm, 0.9)
	flash(Color(1.0, 0.96, 0.8, 0.4), 0.5)
	punch(0.06)
	ToonFx.ring(actors, knot_at, 40.0, Color(1.0, 0.92, 0.6, 0.9), 1.0, 3.2, 0.6)
	ToonFx.stars(actors, knot_at, 12, 15.0)
	ToonFx.sparkles(actors, knot_at, 14, 120.0)
	ToonFx.confetti(self, size.x, 80)
	StageFx.fly_knot(actors, knot_at, _avatar.position + Vector2(0, -260), Color("#F2C14E"), 0.7)
	_avatar.set_expression(&"happy")
	_avatar.look_reset()
	_avatar.celebrate()
	_atoq.stumble()
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func() -> void: _gap_target = _gap + 120.0)
	tween.tween_interval(1.2)
	tween.tween_callback(func() -> void: _avatar.play(&"dance"))
	tween.tween_interval(1.5)
	tween.tween_callback(payoff_finished.emit)


## Líneas de velocidad detrás del avatar cuando acelera.
class _SpeedLines:
	extends Node2D
	var strength := 0.0
	var origin := Vector2.ZERO
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		if strength <= 0.01:
			return
		for i in 6:
			var lane := float(i) / 5.0
			var y := origin.y - 70.0 + lane * 150.0
			var run := fposmod(_time * 1400.0 + i * 173.0, 420.0)
			var x := origin.x - run
			var length := 60.0 + 50.0 * fposmod(i * 0.37, 1.0)
			draw_line(Vector2(x, y), Vector2(x - length, y), Color(1, 1, 1, 0.55 * strength), 4.0, true)

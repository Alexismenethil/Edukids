class_name ChaseStage
extends MechanicStage
## Persecución: el avatar corre por el Qhapaq Ñan y Atoq lo persigue. El valle pasa sin fin
## (cerros nevados, lomas con chacras, molles y retamas). Cada acierto hace que el avatar acelere y
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
var _glance := 2.0
var _warm := Color(1.0, 0.93, 0.82)
## Obstáculos en el camino: {"node", "jump", "life_lost", "done"}.
var _obstacles: Array[Dictionary] = []


func _build_world() -> void:
	ground_y = 652.0
	focus_x = 640.0
	world.add_sky(PackedColorArray([Color("#4FAEEA"), Color("#9AD6F2"), Color("#FFF0D6"), Color("#FFD9AE")]),
		PackedFloat32Array([0.0, 0.45, 0.78, 1.0]), -260.0, 600.0, Vector2(0.8, 395.0), 44.0)
	var clouds: Array[Texture2D] = []
	for i in 4:
		clouds.append(load(WORLD + "cloud_%d.svg" % i))
	world.add_clouds(clouds, [
		{"x": 0.0, "y": 150.0, "texture": 0, "speed": 7.0},
		{"x": 760.0, "y": 95.0, "texture": 1, "speed": 10.0, "scale": 0.9},
		{"x": 1350.0, "y": 210.0, "texture": 2, "speed": 6.0},
		{"x": 2100.0, "y": 130.0, "texture": 3, "speed": 12.0},
		{"x": 2700.0, "y": 240.0, "texture": 1, "speed": 8.0, "scale": 0.75, "alpha": 0.9},
	])
	var birds := BirdFlock.new()
	birds.world = world
	world.add_child(birds)
	world.add_layer(load(WORLD + "valley_far.svg"), 0.1, 250.0, 1.0)
	world.add_rays(Vector2(0.8, 395.0), 0.13)
	world.add_layer(load(WORLD + "valley_mid.svg"), 0.3, 410.0, 1.25)
	world.add_fog(560.0, 640.0, 0.45, Color(1.0, 0.97, 0.9, 0.5))
	world.add_layer(load(WORLD + "valley_near.svg"), 0.6, 300.0, 1.5)
	world.add_layer(load(WORLD + "valley_ground.svg"), 1.0, 596.0, 2.0)
	_track = world.add_plane(1.0)
	actors = world.add_stage()
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
	var front := world.add_layer(load(WORLD + "valley_front.svg"), 1.35, 650.0, 1.5)
	world.sway(front, 5.0, 1.4)
	world.add_fill(814.0, 4000.0, Color("#2F7740"))
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.MOTES, 26, 0.9, Vector2(300, 700)))
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.PETALS, 7, 1.1, Vector2(220, 760),
		PackedColorArray([Color("#FF8FB3"), Color("#FFD23F"), Color("#FFFFFF")])))
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
			if obstacle["jump"]:
				_jump()
			else:
				_trip(obstacle["life_lost"])
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
		_place_obstacle(true, false)
		_gap_target = _gap_for(danger) + 60.0
		return 1.9
	_target = TROT * 1.6
	_place_obstacle(false, feedback.life_lost)
	return 3.3 if feedback.life_lost else 1.9


func _place_obstacle(jump: bool, life_lost: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(WORLD + PROPS[randi() % PROPS.size()] + ".svg")
	sprite.scale = Vector2.ONE * 0.5
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5 + 6.0)
	var ahead := 600.0 if jump else 300.0
	sprite.position = Vector2(world.cam_x + RUNNER_X + ahead, ground_y + 4.0)
	_track.add_child(sprite)
	_obstacles.append({"node": sprite, "jump": jump, "life_lost": life_lost, "done": false})


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
			light(Color.WHITE, 0.6))
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

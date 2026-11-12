class_name CaimanStage
extends MechanicStage
## Coco, el caimán glotón: en la laguna vive un caimán que ama las frutas de la feria de Huamanga.
## Cada acierto lanza una fruta y Coco salta fuera del agua para atraparla al vuelo (¡Ñam!). Cada
## error lo pone gruñón: se acerca al muelle, salpica con la cola y muerde el aire (¡Ñac!). Si el
## medidor llega a 0, salta hasta el muelle y se lleva un nudo de un mordisco. Al final, lleno y
## con sueño, lleva al avatar en su lomo hasta la otra orilla.

const WORLD := "res://assets/art/worlds/lagoon/"
const VALLEY := "res://assets/art/worlds/valley/"
const AVATAR_SCALE := 0.46
const COCO_SCALE := 1.0
const DECK := 600.0
const STAND_X := 250.0
const FLOAT_Y := 668.0
const FRONT_WATER := 650.0
const FRUITS: Array[StringName] = [&"tuna", &"palta", &"choclo", &"lucuma", &"tuna", &"papa"]

var _avatar: AvatarCharacter
var _coco: CaimanCharacter
var _coco_plane: Node2D
var _ripples: _Ripples
var _basket: _Basket
var _thrown := 0
var _fed := 0
var _coco_x := 900.0
var _riding := false
var _busy := false
var _follow := false


func _build_world() -> void:
	ground_y = DECK
	focus_x = 520.0
	action_zoom = 1.05
	action_ground = 0.7
	world.add_sky(PackedColorArray([Color("#4FAEEA"), Color("#9AD6F2"), Color("#FFF0D6"), Color("#FFD9AE")]),
		PackedFloat32Array([0.0, 0.45, 0.8, 1.0]), -320.0, 560.0, Vector2(0.72, 360.0), 42.0)
	var clouds: Array[Texture2D] = []
	for i in 4:
		clouds.append(load(VALLEY + "cloud_%d.svg" % i))
	world.add_clouds(clouds, [
		{"x": 0.0, "y": 140.0, "texture": 0, "speed": 6.0},
		{"x": 800.0, "y": 80.0, "texture": 2, "speed": 8.0, "scale": 0.9},
		{"x": 1600.0, "y": 190.0, "texture": 1, "speed": 10.0},
		{"x": 2400.0, "y": 110.0, "texture": 3, "speed": 7.0},
	])
	var birds := BirdFlock.new()
	birds.world = world
	world.add_child(birds)
	world.add_layer(load(VALLEY + "valley_far.svg"), 0.08, 200.0, 1.0)
	world.add_rays(Vector2(0.72, 360.0), 0.12)
	world.add_layer(load(WORLD + "lagoon_far.svg"), 0.25, 360.0, 1.0, false, -700.0)
	world.add_layer(load(WORLD + "lagoon_mid.svg"), 0.5, 340.0, 1.2, false, -700.0)
	world.add_water(572.0, 1600.0, 0.9, 14.0, Color("#8FDCEB"), Color("#3A9CC8"))
	_coco_plane = world.add_plane(1.0)
	_coco = CaimanCharacter.new()
	_coco.scale = Vector2.ONE * COCO_SCALE
	_coco.position = Vector2(1500.0, FLOAT_Y)
	_coco_plane.add_child(_coco)
	var front := world.add_water(FRONT_WATER, 1600.0, 1.0, 14.0, Color("#78CFE4"), Color("#3A9CC8"))
	(front.material as ShaderMaterial).set_shader_parameter("opacity", 0.84)
	(front.material as ShaderMaterial).set_shader_parameter("depth_span", 260.0)
	var floating := world.add_plane(1.0)
	_ripples = _Ripples.new()
	_ripples.stage = self
	floating.add_child(_ripples)
	for spec in [Vector2(820, 700), Vector2(1080, 676), Vector2(560, 742), Vector2(1260, 760)]:
		var lily := Sprite2D.new()
		lily.texture = load(WORLD + "prop_lily.svg")
		lily.scale = Vector2.ONE * 0.5
		lily.position = spec
		floating.add_child(lily)
	world.add_layer(load(WORLD + "lagoon_near.svg"), 1.0, 360.0, 1.4, false, -700.0)
	world.add_fill(900.0, 4000.0, Color("#3A9CC8"))
	actors = world.add_plane(1.0)
	_basket = _Basket.new()
	_basket.position = Vector2(STAND_X - 110.0, DECK - 6.0)
	_basket.texture = load(WORLD + "prop_basket.svg")
	actors.add_child(_basket)
	_avatar = _make_avatar(AVATAR_SCALE)
	_avatar.position = Vector2(STAND_X, DECK - 8.0)
	actors.add_child(_avatar)
	watch(_avatar)
	_coco.curious = false
	_coco.interactive = true
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.BUTTERFLIES, 5, 1.0, Vector2(430, 580),
		PackedColorArray([Color("#FFD23F"), Color("#FF8FB3"), Color("#9FD8FF")])))
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.MOTES, 22, 0.8, Vector2(280, 640)))
	_coco_x = _x_for(danger)


func start() -> void:
	_coco_x = _x_for(danger)
	_basket.remaining = maxi(0, total)
	var tween := create_tween()
	tween.tween_property(_coco, "position:x", _coco_x, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_coco.open_wide(0.3)
		var close := create_tween()
		close.tween_interval(0.6)
		close.tween_callback(func() -> void: _coco.chomp(0.4)))


func _x_for(value: int) -> float:
	var ratio := clampf(float(value - 1) / maxf(1.0, danger_max - 1.0), 0.0, 1.0)
	return 640.0 + ratio * 420.0


func _mouth() -> Vector2:
	return _coco.position + Vector2(-193.0, -68.0) * COCO_SCALE


func _process(delta: float) -> void:
	super(delta)
	if world == null:
		return
	if not _busy and not _riding:
		_coco.position.y = FLOAT_Y + sin(_time * 1.6) * 5.0
		_coco.rotation = sin(_time * 1.1) * 0.02
	if _riding:
		_avatar.position = _coco.position + Vector2(10.0, -118.0)
	var target := clampf(_avatar.position.x - 700.0, 0.0, 700.0) if _follow else 0.0
	world.cam_x = lerpf(world.cam_x, target, minf(1.0, delta * 2.5))


func react(feedback: FeedbackViewModel) -> float:
	danger = feedback.danger
	if feedback.correct:
		_feed()
		return 2.4
	if feedback.life_lost:
		_bite_knot()
		return 3.0
	_grumble()
	return 2.0


func play_payoff() -> void:
	_busy = true
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func() -> void:
		cinema(true)
		light(Color(1.0, 0.93, 0.82), 1.0)
		_coco.look_reset()
		_coco.fall_asleep())
	tween.tween_interval(1.4)
	tween.tween_property(_coco, "position", Vector2(STAND_X + 330.0, FLOAT_Y + 6.0), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		_avatar.hop(60.0)
		var jump := create_tween()
		jump.tween_property(_avatar, "position", _coco.position + Vector2(10.0, -118.0), 0.42).set_trans(Tween.TRANS_SINE)
		jump.tween_callback(func() -> void:
			_riding = true
			_follow = true
			StageFx.burst(actors, _coco.position + Vector2(0, -20), &"splash", 16)))
	tween.tween_interval(0.7)
	tween.tween_property(_coco, "position:x", 1180.0, 2.6).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func() -> void:
		_riding = false
		_avatar.hop(56.0)
		var off := create_tween()
		off.tween_property(_avatar, "position", Vector2(1330.0, 586.0), 0.42).set_trans(Tween.TRANS_SINE)
		off.tween_callback(func() -> void:
			_avatar.celebrate()
			ToonFx.confetti(self, size.x, 80)
			StageFx.burst(actors, _avatar.position + Vector2(0, -180), &"sparkle", 36)
			StageFx.burst(actors, _coco.position + Vector2(-120, -120), &"hearts", 14)))
	tween.tween_interval(1.5)
	tween.tween_callback(func() -> void: _avatar.play(&"dance"))
	tween.tween_interval(1.6)
	tween.tween_callback(payoff_finished.emit)


func play_game_over() -> void:
	_busy = true
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_property(_coco, "position:x", STAND_X + 380.0, 0.6).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func() -> void:
		_coco.open_wide(0.15)
		for i in 3:
			StageFx.fly_knot(actors, _avatar.position + Vector2(-20, -130), _mouth(), StageFx.KNOT_COLORS[i], 0.4 + i * 0.12))
	tween.tween_interval(0.6)
	tween.tween_callback(func() -> void:
		_coco.chomp(1.6)
		_avatar.play(&"sad")
		cinema(true)
		light(Color(0.84, 0.88, 1.0), 0.8)
		close_on(Vector2(STAND_X + 140.0, DECK - 90.0), 0.6)
		StageFx.float_text(actors, "¡Hip!", _mouth() + Vector2(0, -80), Color("#FFF3B0"), 40))
	tween.tween_interval(1.9)
	tween.tween_callback(payoff_finished.emit)


## Acierto: el avatar lanza una fruta en arco y Coco salta fuera del agua para atraparla al vuelo.
func _feed() -> void:
	_busy = true
	var kind: StringName = FRUITS[_thrown % FRUITS.size()]
	_thrown += 1
	_fed += 1
	_basket.remaining = maxi(0, total - _thrown)
	_coco.set_mood(&"calm")
	_avatar.hop(26.0)
	var fruit := FruitSprite.new()
	fruit.kind = kind
	fruit.size_factor = 2.0
	fruit.position = _avatar.position + Vector2(30, -150)
	fruit.z_index = 4
	actors.add_child(fruit)
	var start := _coco.position
	var apex := start + Vector2(-30.0, -150.0)
	var catch_at := apex + Vector2(-193.0, -68.0) * COCO_SCALE + Vector2(-10.0, -24.0)
	var from := fruit.position
	var throw := create_tween()
	throw.tween_method(func(t: float) -> void:
		var peak := Vector2((from.x + catch_at.x) * 0.5, minf(from.y, catch_at.y) - 160.0)
		fruit.position = from.lerp(peak, t).lerp(peak.lerp(catch_at, t), t)
		fruit.rotation = t * 7.0
		_avatar.look_at_point(fruit.global_position, 0.4)
		_coco.look_at_point(fruit.global_position, 0.4), 0.0, 1.0, 0.85).set_trans(Tween.TRANS_SINE)
	throw.tween_callback(fruit.queue_free)
	var leap := create_tween()
	leap.tween_interval(0.3)
	leap.tween_property(_coco, "position:y", start.y + 14.0, 0.14).set_trans(Tween.TRANS_SINE)
	leap.tween_callback(func() -> void:
		_coco.open_wide(0.25)
		StageFx.burst(actors, Vector2(start.x - 40.0, FRONT_WATER), &"splash", 26))
	leap.tween_property(_coco, "position", apex, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	leap.parallel().tween_property(_coco, "rotation", 0.32, 0.38)
	leap.tween_callback(func() -> void:
		_coco.chomp(1.3)
		_coco.fullness = clampf(float(_fed) / maxf(1.0, total), 0.0, 1.0)
		var mouth := _mouth()
		hit_stop(0.07)
		punch(0.05)
		ToonFx.impact(actors, mouth, 44.0, Color("#FFE27A"))
		_avatar.play(&"clap")
		StageFx.burst(actors, mouth, &"crumbs", 16)
		StageFx.burst(actors, mouth + Vector2(40, -40), &"hearts", 10)
		StageFx.float_text(actors, "¡Ñam!", mouth + Vector2(60, -110), Color("#FFF3B0"), 44))
	leap.tween_property(_coco, "position", Vector2(start.x - 50.0, start.y + 20.0), 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	leap.parallel().tween_property(_coco, "rotation", -0.18, 0.36)
	leap.tween_callback(func() -> void:
		StageFx.burst(actors, Vector2(start.x - 60.0, FRONT_WATER), &"splash", 34)
		_ripples.ring(Vector2(start.x - 60.0, FRONT_WATER + 6.0))
		shake(4.0, 0.25))
	leap.tween_property(_coco, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	leap.tween_callback(func() -> void:
		_busy = false
		_coco_x = _x_for(danger)
		create_tween().tween_property(_coco, "position:x", _coco_x, 1.0).set_trans(Tween.TRANS_SINE))


## Error: Coco se pone gruñón, se acerca, salpica con la cola y muerde el aire.
func _grumble() -> void:
	_coco_x = _x_for(danger)
	var tween := create_tween()
	tween.tween_property(_coco, "position:x", _coco_x, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_coco.snap(70.0)
		_avatar.startle()
		_avatar.express(&"worry", 1.6)
		shake(5.0, 0.3)
		StageFx.float_text(actors, "¡Ñac!", _mouth() + Vector2(-20, -90), Color("#FFD1D8"), 42)
		StageFx.burst(actors, Vector2(_coco.position.x + 190.0, FRONT_WATER), &"splash", 30)
		_ripples.ring(Vector2(_coco.position.x + 190.0, FRONT_WATER + 6.0)))
	tween.tween_interval(1.2)
	tween.tween_callback(_coco.set_mood.bind(&"calm"))


## Vida perdida: Coco se lanza hasta el muelle y se lleva un nudo de un mordisco.
func _bite_knot() -> void:
	_busy = true
	var tween := create_tween()
	tween.tween_property(_coco, "position:x", STAND_X + 420.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		cinema(true)
		light(Color(0.86, 0.9, 1.0), 0.4)
		close_on(Vector2(STAND_X + 170.0, DECK - 100.0), 0.35))
	tween.tween_property(_coco, "position", Vector2(STAND_X + 380.0, FLOAT_Y - 70.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_coco, "rotation", 0.25, 0.22)
	tween.tween_callback(func() -> void:
		_coco.snap(40.0)
		_avatar.startle()
		shake(10.0, 0.35)
		hit_stop(0.1)
		flash(Color(1, 1, 1, 0.35), 0.35)
		punch(0.07)
		ToonFx.impact(actors, _avatar.position + Vector2(70, -130), 52.0)
		life_taken.emit()
		StageFx.burst(actors, Vector2(STAND_X + 300.0, FRONT_WATER), &"splash", 30)
		StageFx.fly_knot(actors, _avatar.position + Vector2(0, -130), _mouth(),
			StageFx.KNOT_COLORS[randi() % StageFx.KNOT_COLORS.size()], 0.35)
		StageFx.float_text(actors, "¡Ñac!", _mouth() + Vector2(-10, -90), Color("#FFD1D8"), 44))
	tween.tween_interval(0.45)
	tween.tween_property(_coco, "position", Vector2(STAND_X + 420.0, FLOAT_Y), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_coco, "rotation", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		_coco.chomp(0.9)
		StageFx.burst(actors, Vector2(STAND_X + 380.0, FRONT_WATER), &"splash", 22)
		cinema(false)
		light(Color.WHITE, 0.6)
		frame(Shot.ACTION, 0.4))
	tween.tween_interval(0.7)
	tween.tween_callback(func() -> void:
		_busy = false
		_coco_x = _x_for(danger)
		_coco.set_mood(&"calm"))
	tween.tween_property(_coco, "position:x", _x_for(danger), 1.0).set_trans(Tween.TRANS_SINE)


## Ondas en el agua: alrededor de Coco y donde algo cae.
class _Ripples:
	extends Node2D
	var stage: CaimanStage
	var _time := 0.0
	var _rings: Array[Vector3] = []

	func ring(at: Vector2) -> void:
		_rings.append(Vector3(at.x, at.y, 0.0))

	func _process(delta: float) -> void:
		_time += delta
		for i in _rings.size():
			_rings[i].z += delta
		_rings = _rings.filter(func(item: Vector3) -> bool: return item.z < 1.2)
		queue_redraw()

	func _draw() -> void:
		if stage == null or stage._coco == null:
			return
		var coco := stage._coco
		for ring_index in 2:
			var grow := fmod(_time * 0.55 + ring_index * 0.5, 1.0)
			_ellipse(Vector2(coco.position.x - 10.0, CaimanStage.FRONT_WATER + 6.0), Vector2(230.0 + grow * 80.0, 12.0 + grow * 6.0),
				Color(1, 1, 1, 0.45 * (1.0 - grow)))
		for item in _rings:
			var grow := item.z / 1.2
			_ellipse(Vector2(item.x, item.y), Vector2(40.0 + grow * 120.0, 6.0 + grow * 10.0), Color(1, 1, 1, 0.7 * (1.0 - grow)))

	func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
		var points := PackedVector2Array()
		for i in 33:
			var angle := PI * 0.06 + PI * 0.88 * i / 32.0
			points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		draw_polyline(points, color, 2.5, true)


## La canasta tejida con las frutas que quedan.
class _Basket:
	extends Node2D
	var texture: Texture2D
	var remaining := 0:
		set(value):
			remaining = value
			queue_redraw()

	func _draw() -> void:
		for i in mini(5, remaining):
			var fruit_at := Vector2(-30.0 + i * 15.0, -44.0 - (i % 2) * 8.0)
			FruitSprite.paint(self, fruit_at, CaimanStage.FRUITS[i % CaimanStage.FRUITS.size()], 1.4)
		if texture:
			var size := Vector2(110, 80) * 0.75
			draw_texture_rect(texture, Rect2(Vector2(-size.x * 0.5, -size.y), size), false)

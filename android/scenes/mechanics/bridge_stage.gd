class_name BridgeStage
extends MechanicStage
## El puente colgante: hay que cruzar el cañón armando el puente, un tramo por pregunta. Cada
## acierto hace caer un tramo de tablas desde el cielo; con cada error sopla el viento y el puente
## se sacude. Si el medidor llega a 0, el avatar cae al río y un cóndor lo rescata y lo lleva de
## vuelta a la orilla (pierde una vida). Si una pregunta del repaso vuelve a fallar, Quwi amarra
## una soga en su lugar para poder seguir. Al final, el avatar cruza y sale un arco iris.

const WORLD := "res://assets/art/worlds/canyon/"
const VALLEY := "res://assets/art/worlds/valley/"
const CONDOR := preload("res://assets/art/characters/condor/char_condor.svg")
const AVATAR_SCALE := 0.42
const LEFT := 300.0
const RIGHT := 1080.0
const DECK := 470.0
const SAG := 40.0
const RAIL := 86.0
const RIVER := 778.0
const ROPE := Color("#A57B45")
const ROPE_DARK := Color("#6E4C2A")
const ROPE_LIGHT := Color("#E2BE7E")

var _avatar: AvatarCharacter
var _cheers := 0
## Tramos puestos: índice → {"kind": &"wood" | &"gold" | &"rope", "t": 0..1 de su caída, "fall"?}.
var _planks := {}
var _wobble := 0.0
var _walking := false
var _avatar_slot := -1
var _plane: Node2D
var _back: _BridgeBack
var _front: _BridgeFront
var _rainbow: _Rainbow
var _textures := {}


func _build_world() -> void:
	ground_y = DECK
	focus_x = 690.0
	action_zoom = 1.0
	action_ground = 0.5
	question_zoom = 0.72
	_textures = {&"wood": load(WORLD + "plank_wood.svg"), &"gold": load(WORLD + "plank_gold.svg"),
		&"rope": load(WORLD + "plank_rope.svg")}
	world.add_sky(PackedColorArray([Color("#4FAEEA"), Color("#9AD6F2"), Color("#FFF0D6"), Color("#FFD9AE")]),
		PackedFloat32Array([0.0, 0.45, 0.8, 1.0]), -300.0, 560.0, Vector2(0.78, 330.0), 40.0)
	var clouds: Array[Texture2D] = []
	for i in 4:
		clouds.append(load(VALLEY + "cloud_%d.svg" % i))
	world.add_clouds(clouds, [
		{"x": 0.0, "y": 110.0, "texture": 2, "speed": 6.0},
		{"x": 900.0, "y": 60.0, "texture": 0, "speed": 9.0, "scale": 0.85},
		{"x": 1700.0, "y": 170.0, "texture": 3, "speed": 11.0},
		{"x": 2500.0, "y": 90.0, "texture": 1, "speed": 7.0},
	])
	world.add_layer(load(VALLEY + "valley_far.svg"), 0.08, 170.0, 1.0)
	world.add_rays(Vector2(0.78, 330.0), 0.12)
	world.add_layer(load(WORLD + "canyon_far.svg"), 0.25, 420.0, 0.9, false, -700.0)
	_add_condors()
	world.add_layer(load(WORLD + "canyon_mid.svg"), 0.55, 320.0, 1.1, false, -700.0)
	world.add_water(RIVER, 1500.0, 0.8, 70.0)
	world.add_fog(700.0, 800.0, 0.8, Color(1.0, 0.98, 0.94, 0.55))
	world.add_layer(load(WORLD + "canyon_near.svg"), 1.0, 200.0, 1.4, false, -700.0)
	world.add_fill(1012.0, 4000.0, Color("#8E5238"))
	_plane = world.add_plane(1.0)
	_rainbow = _Rainbow.new()
	_rainbow.position = Vector2(690.0, 560.0)
	_plane.add_child(_rainbow)
	_back = _BridgeBack.new()
	_back.stage = self
	_plane.add_child(_back)
	actors = _plane
	_avatar = _make_avatar(AVATAR_SCALE)
	_plane.add_child(_avatar)
	_front = _BridgeFront.new()
	_front.stage = self
	_plane.add_child(_front)
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.BUTTERFLIES, 5, 1.0, Vector2(360, 460),
		PackedColorArray([Color("#FFD23F"), Color("#FF8FB3"), Color("#9FD8FF")])))
	world.add_child(AmbientField.new().setup(world, AmbientField.Kind.MOTES, 20, 0.7, Vector2(250, 760)))
	for index in progress.size():
		var kind := _kind_for(progress[index])
		if kind != &"":
			_planks[index] = {"kind": kind, "t": 1.0}
	_avatar_slot = _reach()
	_place_avatar()


func _add_condors() -> void:
	var plane := world.add_plane(0.3)
	for i in 2:
		var condor := CondorFlight.new()
		condor.texture = CONDOR
		condor.scale = Vector2.ONE * (0.42 - i * 0.12)
		condor.start_x = 1900.0 + i * 300.0
		condor.end_x = -500.0
		condor.altitude = 250.0 + i * 70.0
		condor.crossing_time = 30.0 + i * 8.0
		condor.first_delay = 1.0 + i * 9.0
		plane.add_child(condor)


func start() -> void:
	_place_avatar()
	_avatar.wave()


func _slots() -> int:
	return maxi(1, total)


func _slot_x(index: int) -> float:
	return LEFT + slot_width() * (index + 0.5)


func slot_width() -> float:
	return (RIGHT - LEFT) / _slots()


## Altura de la cubierta en x: comba de las sogas y el vaivén del viento.
func deck_y(x: float) -> float:
	var middle := (LEFT + RIGHT) * 0.5
	var half := (RIGHT - LEFT) * 0.5
	var ratio := clampf((x - middle) / half, -1.0, 1.0)
	var bend := 1.0 - ratio * ratio
	return DECK + SAG * bend + _wobble * sin(_time * 9.0 + x * 0.018) * bend


func _kind_for(state: StringName) -> StringName:
	match state:
		&"right":
			return &"wood"
		&"fixed":
			return &"gold"
		&"wrong":
			return &"rope"
	return &""


## Último tramo seguido desde la orilla izquierda (-1 si no hay ninguno).
func _reach() -> int:
	var last := -1
	for index in _slots():
		if not _planks.has(index):
			break
		last = index
	return last


func _stand_x(slot: int) -> float:
	return LEFT - 70.0 if slot < 0 else _slot_x(slot)


func _ground_at(x: float) -> float:
	return deck_y(x) if x >= LEFT and x <= RIGHT else DECK


func _place_avatar() -> void:
	if _avatar and not _walking:
		var x := _stand_x(_avatar_slot)
		_avatar.position = Vector2(x, _ground_at(x))


func _process(delta: float) -> void:
	super(delta)
	if world == null:
		return
	_wobble = move_toward(_wobble, 0.0, delta * 7.0)
	for index: int in _planks:
		_planks[index]["t"] = minf(1.0, _planks[index]["t"] + delta * 1.8)
		if _planks[index].has("fall"):
			_planks[index]["fall"] += delta
	if _avatar and not _walking and _avatar.visible:
		_avatar.position.y = _ground_at(_avatar.position.x)
	# La cámara se desliza siguiendo al avatar (las capas lejanas se mueven menos).
	var target := clampf((_avatar.position.x - 690.0) * 0.55, -220.0, 220.0)
	world.cam_x = lerpf(world.cam_x, target, minf(1.0, delta * 2.0))
	_back.queue_redraw()
	_front.queue_redraw()


func react(feedback: FeedbackViewModel) -> float:
	danger = feedback.danger
	progress = feedback.progress
	var index := feedback.index
	var state: StringName = progress[index] if index >= 0 and index < progress.size() else &""
	var kind := _kind_for(state)
	if kind != &"":
		_planks[index] = {"kind": kind, "t": 0.0}
		_avatar.look_toward(Vector2(0.6, -1.0), 0.6)
		var land := create_tween()
		land.tween_interval(0.5)
		land.tween_callback(func() -> void:
			var at := Vector2(_slot_x(index), deck_y(_slot_x(index)))
			_wobble = 6.0
			shake(3.5, 0.18)
			punch(0.03)
			Sounds.play(&"plank", randf_range(0.94, 1.08), -4.0)
			if feedback.correct:
				# El festejo cambia cada vez: aplaude, baila o salta de alegría.
				_cheers += 1
				_avatar.play([&"clap", &"dance", &"cheer"][_cheers % 3])
			StageFx.burst(_plane, at, &"dust", 12)
			if kind == &"rope":
				StageFx.float_text(_plane, "¡Quwi te amarra una soga!", at + Vector2(0, -110), Color("#FFF3B0"), 28)
			else:
				StageFx.burst(_plane, at + Vector2(0, -10), &"sparkle", 14)
				StageFx.float_text(_plane, "¡Toc!", at + Vector2(0, -100), Color("#FFF3B0"), 38))
	if feedback.life_lost:
		_wobble = 26.0
		_gust()
		_fall(true)
		return 4.2
	if not feedback.correct:
		_wobble = 22.0
		_gust()
		_avatar.startle()
		_avatar.express(&"worry", 1.8)
		shake(5.0, 0.3)
		StageFx.float_text(_plane, "¡Uyuyuy!", _avatar.position + Vector2(0, -210), Color("#FFD1D8"), 36)
	var walk := create_tween()
	walk.tween_interval(0.95)
	walk.tween_callback(_walk_to_reach)
	return 2.3 if feedback.correct else 1.9


## Ráfaga de viento: hojas que cruzan el cañón.
func _gust() -> void:
	for i in 3:
		StageFx.burst(_plane, Vector2(LEFT - 120.0 + i * 60.0, DECK - 160.0 + i * 40.0), &"leaves", 8)


func play_payoff() -> void:
	var tween := create_tween()
	tween.tween_interval(0.4)
	tween.tween_callback(func() -> void:
		_walk_to(RIGHT + 110.0, func() -> void:
			_avatar.celebrate()
			_rainbow.show_up()
			cinema(true)
			light(Color(1.0, 0.94, 0.84), 0.9)
			flash(Color(1.0, 0.96, 0.8, 0.35), 0.5)
			ToonFx.confetti(self, size.x, 80)
			StageFx.burst(_plane, _avatar.position + Vector2(0, -180), &"sparkle", 36)
			var done := create_tween()
			done.tween_interval(1.3)
			done.tween_callback(func() -> void: _avatar.play(&"dance"))
			done.tween_interval(1.5)
			done.tween_callback(payoff_finished.emit)))


func play_game_over() -> void:
	_wobble = 30.0
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void:
		for index: int in _planks.keys():
			_planks[index]["fall"] = randf_range(-0.3, 0.0)
		cinema(true)
		light(Color(0.84, 0.88, 1.0), 0.8)
		_fall(false))
	tween.tween_interval(2.2)
	tween.tween_callback(payoff_finished.emit)


## El avatar cae al río (¡splash!). Si todavía tiene vidas, un cóndor baja, lo saca del agua y lo
## deja en la orilla de partida.
func _fall(comes_back: bool) -> void:
	_walking = true
	var start := _avatar.position
	var water := RIVER + 18.0
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_callback(func() -> void:
		_avatar.startle()
		_avatar.express(&"worry", 1.2)
		if comes_back:
			cinema(true)
			light(Color(0.88, 0.92, 1.0), 0.4))
	tween.tween_property(_avatar, "position:y", start.y - 50.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_avatar, "position:y", water + 60.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_avatar, "rotation", 1.6, 0.6)
	tween.tween_callback(func() -> void:
		StageFx.burst(_plane, Vector2(start.x, water), &"splash", 40)
		StageFx.float_text(_plane, "¡Splash!", Vector2(start.x, water - 120.0), Color("#DFF4FB"), 40)
		shake(8.0, 0.35)
		hit_stop(0.08)
		punch(0.05)
		ToonFx.ring(_plane, Vector2(start.x, water), 34.0, Color(1, 1, 1, 0.8), 0.3, 3.4, 0.7)
		if comes_back:
			life_taken.emit()
		_avatar.visible = false)
	if not comes_back:
		return
	# Kuntur, el cóndor, baja en picada, lo agarra con las garras y lo lleva de vuelta.
	var condor := Cast.create(&"condor") as CondorCharacter
	condor.scale = Vector2.ONE * 0.62
	condor.position = Vector2(start.x + 700.0, DECK - 420.0)
	condor.curious = false
	_plane.add_child(condor)
	condor.flap = 1.4
	condor.set_expression(&"determined")
	condor.look_toward(Vector2(-0.8, 0.6))
	var grip := Vector2(0, 174.0)
	tween.tween_interval(0.25)
	tween.tween_property(condor, "position", Vector2(start.x, water - 52.0), 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		StageFx.burst(_plane, Vector2(start.x, water), &"splash", 20)
		condor.play(&"grab")
		condor.flap = 2.0
		condor.look_toward(Vector2(-1.0, -0.3))
		_avatar.rotation = 0.0
		_avatar.visible = true
		_avatar.set_expression(&"wow")
		_avatar.position = Vector2(start.x, water + 40.0))
	var carry := func(point: Vector2) -> void:
		condor.position = point + Vector2(0, 18.0)
		_avatar.position = condor.position + grip
	tween.tween_method(carry, Vector2(start.x, water - 70.0), Vector2(LEFT - 70.0, DECK - 230.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		_avatar_slot = -1
		cinema(false)
		light(journey_light(), 0.6)
		_avatar.settle()
		_avatar.set_expression(&"neutral")
		condor.flap = 1.2
		condor.set_expression(&"neutral")
		condor.play(&"screech")
		StageFx.burst(_plane, Vector2(LEFT - 70.0, DECK), &"dust", 12))
	tween.tween_property(_avatar, "position", Vector2(LEFT - 70.0, DECK), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(condor, "position", Vector2(LEFT - 900.0, DECK - 520.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_walking = false
		_avatar.hop(26.0)
		_walk_to_reach())
	tween.tween_interval(1.0)
	tween.tween_callback(condor.queue_free)


func _walk_to_reach() -> void:
	var target_slot := _reach()
	if target_slot == _avatar_slot and not _walking:
		return
	_avatar_slot = target_slot
	_walk_to(_stand_x(target_slot), func() -> void: pass)


func _walk_to(x: float, done: Callable) -> void:
	_walking = true
	_avatar.run_speed = 0.8
	var distance := absf(x - _avatar.position.x)
	var tween := create_tween()
	tween.tween_method(func(value: float) -> void:
		_avatar.position = Vector2(value, _ground_at(value))
		_wobble = maxf(_wobble, 3.0), _avatar.position.x, x, maxf(0.35, distance / 210.0))
	tween.tween_callback(func() -> void:
		_avatar.run_speed = 0.0
		_walking = false
		done.call())


## Parte de atrás del puente: la soga lejana de la baranda, las sogas de la cubierta y las tablas.
class _BridgeBack:
	extends Node2D
	var stage: BridgeStage

	func _draw() -> void:
		if stage == null:
			return
		_rope(func(x: float) -> float: return stage.deck_y(x) - RAIL - 10.0, ROPE.darkened(0.1), 3.0)
		_rope(func(x: float) -> float: return stage.deck_y(x) + 6.0, ROPE_DARK, 5.0)
		var width := stage.slot_width()
		for index in stage._slots():
			var cx := stage._slot_x(index)
			var y := stage.deck_y(cx)
			if stage._planks.has(index):
				var plank: Dictionary = stage._planks[index]
				var t: float = plank["t"]
				var drop := (1.0 - _ease_out_back(t)) * -320.0
				var angle := (1.0 - t) * 1.4
				if plank.has("fall") and plank["fall"] > 0.0:
					var fall: float = plank["fall"]
					drop = fall * fall * 600.0
					angle = fall * (2.4 if index % 2 == 0 else -2.4)
				var slope := atan2(stage.deck_y(cx + 10.0) - stage.deck_y(cx - 10.0), 20.0)
				var texture: Texture2D = stage._textures[plank["kind"]]
				var size := Vector2(width - 4.0, 26.0)
				draw_set_transform(Vector2(cx, y + drop), slope + angle, Vector2.ONE)
				draw_texture_rect(texture, Rect2(-size * 0.5, size), false)
				draw_set_transform(Vector2.ZERO)
			elif stage.progress.size() > index and stage.progress[index] == &"current":
				var glow := 0.45 + 0.35 * sin(stage._time * 5.0)
				var color := stage.area.color if stage.area else Color.WHITE
				var rect := Rect2(cx - (width - 8.0) * 0.5, y - 9.0, width - 8.0, 20.0)
				draw_rect(rect, Color(color, glow * 0.35))
				draw_rect(rect, Color(color, glow), false, 3.0, true)
		_rope(func(x: float) -> float: return stage.deck_y(x) + 2.0, ROPE, 5.0)

	func _rope(height: Callable, color: Color, width: float) -> void:
		var points := PackedVector2Array()
		var x := BridgeStage.LEFT - 14.0
		while x <= BridgeStage.RIGHT + 14.0:
			points.append(Vector2(x, height.call(clampf(x, BridgeStage.LEFT, BridgeStage.RIGHT))))
			x += 18.0
		draw_polyline(points, color, width, true)

	func _ease_out_back(t: float) -> float:
		var c := 1.70158
		return 1.0 + (c + 1.0) * pow(t - 1.0, 3.0) + c * pow(t - 1.0, 2.0)


## Parte de adelante: la baranda cercana con sus tirantes y el trenzado de la soga.
class _BridgeFront:
	extends Node2D
	var stage: BridgeStage

	func _draw() -> void:
		if stage == null:
			return
		var rail := PackedVector2Array()
		var x := BridgeStage.LEFT - 14.0
		while x <= BridgeStage.RIGHT + 14.0:
			var clamped := clampf(x, BridgeStage.LEFT, BridgeStage.RIGHT)
			rail.append(Vector2(x, stage.deck_y(clamped) - RAIL))
			x += 18.0
		for index in stage._slots() + 1:
			var hx := BridgeStage.LEFT + stage.slot_width() * index
			draw_line(Vector2(hx, stage.deck_y(hx) - RAIL), Vector2(hx, stage.deck_y(hx) + 4.0), ROPE_DARK, 3.0, true)
		draw_polyline(rail, ROPE_DARK, 7.0, true)
		draw_polyline(rail, ROPE, 4.5, true)
		for i in rail.size() - 1:
			var middle := (rail[i] + rail[i + 1]) * 0.5
			draw_line(middle + Vector2(-3, -2), middle + Vector2(3, 2), ROPE_LIGHT, 2.0, true)
		for side in [BridgeStage.LEFT - 14.0, BridgeStage.RIGHT + 14.0]:
			draw_circle(Vector2(side, BridgeStage.DECK - RAIL), 7.0, ROPE_DARK, true, -1.0, true)
			draw_circle(Vector2(side, BridgeStage.DECK - RAIL), 4.5, ROPE_LIGHT, true, -1.0, true)


## Arco iris que aparece cuando el puente queda completo.
class _Rainbow:
	extends Node2D
	const COLORS := [Color("#FF6B6B"), Color("#FFA94D"), Color("#FFD43B"), Color("#69DB7C"), Color("#4DABF7"), Color("#9775FA")]
	var amount := 0.0

	func show_up() -> void:
		var tween := create_tween()
		tween.tween_property(self, "amount", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	func _process(_delta: float) -> void:
		if amount > 0.0:
			queue_redraw()

	func _draw() -> void:
		if amount <= 0.01:
			return
		for i in COLORS.size():
			var radius := 560.0 - i * 18.0
			draw_arc(Vector2.ZERO, radius, PI, PI + PI * amount, 64, Color(COLORS[i], 0.55), 18.0, true)

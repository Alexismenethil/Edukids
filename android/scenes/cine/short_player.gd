class_name ShortPlayer
extends CineStage
## Reproductor de cortos: arma el mundo del guion, pone a los personajes y ejecuta sus pasos uno a
## uno (ver ShortScript). Los diálogos esperan el toque del estudiante y todo el corto se puede
## saltar. Al terminar emite `finished`.

signal finished

const BUBBLE := preload("res://scenes/ui/components/speech_bubble.tscn")
const SQUEAK := preload("res://assets/audio/sfx/sfx_quwi_squeak.ogg")
const KNOTS := preload("res://assets/audio/sfx/sfx_knots_return.ogg")
const SOUNDS := {&"squeak": SQUEAK, &"knots": KNOTS}

## Los diálogos avanzan solos (modo demostración y grabaciones).
var auto_advance := false
## Aspecto del avatar del estudiante, si el corto lo usa.
var look: AvatarLookViewModel
## Planos y medidas del mundo (lo que devuelve WorldSets.build).
var place: Dictionary = {}
## Plano de los objetos que van detrás de los personajes.
var track: Node2D

var _script: ShortScript
var _cast: Dictionary = {}
var _run := 0
var _bubble: SpeechBubble
var _speaker: Puppet
var _skip: Button
var _card: Control
var _sfx: SfxPlayer
var _done := false


## Empieza el corto. Llamar después de agregar el reproductor al árbol.
func play(script: ShortScript, avatar_look: AvatarLookViewModel = null) -> void:
	_script = script
	_script.player = self
	look = avatar_look
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	action_zoom = 1.0
	action_ground = 0.8
	question_zoom = 1.0
	close_zoom = 1.5
	open_world()
	frame(Shot.ACTION, 0.0)
	_build_overlay()
	_run += 1
	_play_all(_run)


func _build_world() -> void:
	place = WorldSets.build(world, _script.place(), _script.mood())
	actors = place["actors"]
	track = place["track"]
	ground_y = place["ground"]
	focus_x = (place["focus"] as Vector2).x
	_script.setup()


func _build_overlay() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_sfx = SfxPlayer.new()
	_sfx.voices = 3
	add_child(_sfx)
	_bubble = BUBBLE.instantiate()
	_bubble.above = true
	add_child(_bubble)
	_skip = Ui.compact(Ui.button("Saltar", "", &"GhostButton"), 22)
	_skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip.offset_right = -22.0
	_skip.offset_top = 16.0
	_skip.pressed.connect(skip)
	add_child(_skip)


## Un personaje del corto por su nombre.
func actor(actor_name: StringName) -> Puppet:
	return _cast.get(actor_name)


## Salta el corto.
func skip() -> void:
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	_run += 1
	if _bubble and _bubble.is_open():
		_bubble.close()
	finished.emit()


## Un toque en cualquier parte avanza el diálogo.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _bubble and _bubble.is_open():
			_bubble.advance()
			accept_event()


func _process(delta: float) -> void:
	super(delta)
	if _bubble and _bubble.is_open() and is_instance_valid(_speaker):
		_bubble.position = _bubble_point(_speaker)


# --- Ejecución de los pasos --------------------------------------------------------------------

func _play_all(run: int) -> void:
	await get_tree().process_frame
	for beat: Dictionary in _script.beats():
		if run != _run:
			return
		if beat.get("join", false):
			_do(beat, run)
		else:
			await _do(beat, run)
	if run == _run:
		_finish()


func _do(beat: Dictionary, run: int) -> void:
	if beat.has("wait"):
		await _pause(float(beat["wait"]))
	elif beat.has("together"):
		var pending := [0]
		for inner: Dictionary in beat["together"]:
			pending[0] += 1
			_do_counted(inner, run, pending)
		while pending[0] > 0 and run == _run:
			await get_tree().process_frame
	elif beat.has("cast"):
		_beat_cast(beat)
	elif beat.has("enter"):
		await _beat_enter(beat)
	elif beat.has("move"):
		await _beat_move(actor(beat["move"]), _point(beat["to"]), beat)
	elif beat.has("exit"):
		var leaving := actor(beat["exit"])
		if leaving:
			var side := 1.0 if str(beat.get("to", "right")) == "right" else -1.0
			var edge := world.cam_x + 640.0 + side * (760.0 / world.zoom + 200.0)
			await _beat_move(leaving, Vector2(edge, leaving.position.y), beat)
			leaving.visible = false
	elif beat.has("play"):
		var who := actor(beat["play"])
		if who:
			var playback := who.play(beat["clip"], {"amount": beat.get("amount", 1.0), "speed": beat.get("speed", 1.0)})
			if not playback.done:
				await _pause(playback.clip.length / maxf(0.1, float(beat.get("speed", 1.0))))
	elif beat.has("face"):
		var who := actor(beat["face"])
		if who:
			if beat.has("time"):
				who.express(beat["is"], float(beat["time"]))
			else:
				who.set_expression(beat["is"])
	elif beat.has("emote"):
		var who := actor(beat["emote"])
		if who:
			who.emote(beat.get("kind", &"alert"), float(beat.get("time", 1.4)))
	elif beat.has("look"):
		var who := actor(beat["look"])
		if who:
			_beat_look(who, beat.get("at"))
	elif beat.has("turn"):
		var who := actor(beat["turn"])
		if who:
			who.facing = int(beat.get("facing", -who.facing))
	elif beat.has("hop"):
		var who := actor(beat["hop"])
		if who:
			who.hop(float(beat.get("height", 36.0)))
			await _pause(0.45)
	elif beat.has("say"):
		await _beat_say(beat, run)
	elif beat.has("shot"):
		await _beat_shot(beat)
	elif beat.has("fx"):
		_beat_fx(beat)
	elif beat.has("shake"):
		shake(float(beat["shake"]), float(beat.get("time", 0.35)))
	elif beat.has("punch"):
		punch(float(beat["punch"]))
	elif beat.has("flash"):
		flash(Color(Color(str(beat["flash"])), float(beat.get("alpha", 0.4))), float(beat.get("time", 0.4)))
	elif beat.has("hit_stop"):
		hit_stop(float(beat["hit_stop"]))
	elif beat.has("cinema"):
		cinema(bool(beat["cinema"]))
	elif beat.has("light"):
		light(Color(str(beat["light"])), float(beat.get("time", 0.8)))
	elif beat.has("title"):
		await _beat_title(beat)
	elif beat.has("sound"):
		_sfx.play(SOUNDS.get(beat["sound"]), float(beat.get("pitch", 1.0)))
	elif beat.has("call"):
		var result: Variant = _script.callv(str(beat["call"]), beat.get("args", []))
		if beat.has("time"):
			await _pause(float(beat["time"]))
		elif result is float or result is int:
			await _pause(float(result))
	else:
		push_warning("Corto: paso desconocido %s" % beat)


func _do_counted(beat: Dictionary, run: int, pending: Array) -> void:
	await _do(beat, run)
	pending[0] -= 1


func _pause(seconds: float) -> void:
	if seconds > 0.0 and is_inside_tree():
		await get_tree().create_timer(seconds).timeout


## Un punto del guion: [x] (en el suelo), [x, y], el nombre de un personaje o un Vector2.
func _point(value: Variant, offset: Variant = null) -> Vector2:
	var point := Vector2(640.0, ground_y)
	if value is Vector2:
		point = value
	elif value is Array:
		point = Vector2(float(value[0]), float(value[1]) if value.size() > 1 else ground_y)
	elif value is StringName or value is String:
		var who := actor(StringName(value))
		if who:
			point = who.position
	if offset is Array:
		point += Vector2(float(offset[0]), float(offset[1]))
	elif offset is Vector2:
		point += offset
	return point


func _beat_cast(beat: Dictionary) -> void:
	var id: StringName = beat["cast"]
	var actor_name: StringName = beat.get("as", id)
	var puppet := Cast.create(id, look)
	if puppet == null:
		return
	puppet.scale = Vector2.ONE * float(beat.get("scale", Cast.size_of(id)))
	puppet.facing = int(beat.get("facing", 1))
	puppet.position = _point(beat.get("at", [640.0]))
	puppet.visible = not beat.get("hidden", false)
	puppet.interactive = true
	puppet.curious = beat.get("curious", false)
	var parent: Node2D = track if beat.get("behind", false) else actors
	parent.add_child(puppet)
	puppet.set_meta(&"cast_id", id)
	_cast[actor_name] = puppet
	watch(puppet)


func _beat_enter(beat: Dictionary) -> void:
	var who := actor(beat["enter"])
	if who == null:
		return
	var target := _point(beat.get("to", [who.position.x]))
	var from: Variant = beat.get("from", "left")
	if from is String:
		var side := -1.0 if from == "left" else 1.0
		who.position = Vector2(world.cam_x + 640.0 + side * (700.0 / world.zoom + 160.0), target.y)
	else:
		who.position = _point(from)
	who.visible = true
	who.settle()
	await _beat_move(who, target, beat)


## Lleva a un personaje hasta un punto: corriendo (su ciclo de carrera), a saltitos o deslizándose.
func _beat_move(who: Puppet, target: Vector2, beat: Dictionary) -> void:
	if who == null:
		return
	var distance := who.position.distance_to(target)
	var seconds := float(beat.get("time", clampf(distance / 420.0, 0.4, 2.4)))
	if absf(target.x - who.position.x) > 4.0 and beat.get("face_travel", true):
		who.facing = 1 if target.x > who.position.x else -1
	var hops := int(beat.get("hops", 0))
	var running: bool = beat.get("run", false)
	if running:
		_set_run(who, float(beat.get("speed", 1.4)))
	var tween := create_tween()
	if hops > 0:
		var from := who.position
		for i in hops:
			tween.tween_callback(who.hop.bind(float(beat.get("height", 30.0)), seconds / hops * 0.9))
			tween.tween_property(who, "position", from.lerp(target, float(i + 1) / hops), seconds / hops).set_trans(Tween.TRANS_SINE)
	else:
		tween.tween_property(who, "position", target, seconds).set_trans(Tween.TRANS_SINE if not running else Tween.TRANS_LINEAR)
	await tween.finished
	if running and is_instance_valid(who):
		_set_run(who, 0.0)
	if beat.has("facing") and is_instance_valid(who):
		who.facing = int(beat["facing"])


func _set_run(who: Puppet, speed: float) -> void:
	if who is AvatarCharacter:
		(who as AvatarCharacter).run_speed = speed
	elif who is AtoqCharacter:
		(who as AtoqCharacter).speed = speed
	else:
		who.set_cycle(&"run", speed)
		who.set_cycle(&"walk", speed)


func _beat_look(who: Puppet, target: Variant) -> void:
	if target == null:
		who.look_reset()
	elif target is StringName or target is String:
		var other := actor(StringName(target))
		if other:
			who.look_toward(((other.position + other.body_center * other.scale.y) - (who.position + who.body_center * who.scale.y)).normalized())
	elif target is Array:
		who.look_toward((_point(target) - (who.position + who.body_center * who.scale.y)).normalized())


func _beat_say(beat: Dictionary, run: int) -> void:
	var who := actor(beat["say"])
	if who == null:
		return
	var mood: StringName = beat.get("mood", &"neutral")
	if who.has_method("set_mood"):
		who.call("set_mood", mood)
	else:
		who.set_expression(mood)
	_speaker = who
	var screen := _bubble_point(who)
	_bubble.flipped = screen.x < size.x * 0.5
	_bubble.position = screen
	var speaker_id: StringName = who.get_meta(&"cast_id", &"")
	var dialogue := DialogueViewModel.new()
	dialogue.lines.append(DialogueLineViewModel.new(str(beat.get("name", Cast.display_name(speaker_id))), str(beat["text"]), mood))
	dialogue.close_label = "Seguir"
	dialogue.skip_label = ""
	who.talk(true)
	_bubble.play(dialogue)
	var state := {"shown": false, "closed": false}
	var on_shown := func(_index: int) -> void:
		state["shown"] = true
		if is_instance_valid(who):
			who.talk(false)
	var on_closed := func() -> void: state["closed"] = true
	_bubble.line_shown.connect(on_shown)
	_bubble.finished.connect(on_closed, CONNECT_ONE_SHOT)
	var waited := 0.0
	while not state["closed"] and run == _run:
		await get_tree().process_frame
		if auto_advance and state["shown"]:
			waited += get_process_delta_time()
			if waited > float(beat.get("hold", 1.1 + str(beat["text"]).length() * 0.022)):
				_bubble.advance()
	_bubble.line_shown.disconnect(on_shown)
	if is_instance_valid(who):
		who.talk(false)


## Punta del globo: justo encima de la cabeza del personaje, en la pantalla.
func _bubble_point(who: Puppet) -> Vector2:
	var head := who.position + Vector2(0.0, who.emote_anchor.y + 16.0) * who.scale.y
	var parent := who.get_parent() as Node2D
	if parent:
		head += parent.position
	var screen := world.to_screen(head)
	return Vector2(clampf(screen.x, 110.0, size.x - 110.0), clampf(screen.y, 282.0, size.y - 120.0))


func _beat_shot(beat: Dictionary) -> void:
	var seconds := float(beat.get("time", 0.8))
	var kind := str(beat["shot"])
	var focus := Vector2(focus_x, ground_y - 120.0)
	if beat.has("on"):
		focus = _point(beat["on"], beat.get("offset"))
		if beat["on"] is StringName or beat["on"] is String:
			var who := actor(StringName(beat["on"]))
			if who:
				focus += who.body_center * who.scale.y
	match kind:
		"close":
			shoot(focus, float(beat.get("zoom", 1.5)), seconds, Vector2(0.5, 0.56))
		"wide":
			shoot(focus if beat.has("on") else Vector2(focus_x, ground_y - 150.0), float(beat.get("zoom", 0.82)), seconds, Vector2(0.5, 0.6))
		"free":
			shoot(focus, float(beat.get("zoom", 1.0)), seconds, Vector2(0.5, 0.58))
		_:
			shoot(focus if beat.has("on") else Vector2(focus_x, ground_y - 130.0), float(beat.get("zoom", 1.0)), seconds, Vector2(0.5, 0.62))
	if not beat.get("join", false):
		await _pause(seconds)


func _beat_fx(beat: Dictionary) -> void:
	var at := _point(beat.get("on", [640.0]), beat.get("offset"))
	var amount := int(beat.get("amount", 0))
	match StringName(beat["fx"]):
		&"puff":
			ToonFx.puff(actors, at, amount if amount > 0 else 6)
		&"stars":
			ToonFx.stars(actors, at, amount if amount > 0 else 8)
		&"sparkles":
			ToonFx.sparkles(actors, at, amount if amount > 0 else 10, float(beat.get("radius", 70.0)))
		&"impact":
			ToonFx.impact(actors, at, float(beat.get("size", 46.0)))
		&"ring":
			ToonFx.ring(actors, at, float(beat.get("size", 30.0)))
		&"splash":
			ToonFx.splash(actors, at, amount if amount > 0 else 14)
		&"hearts":
			ToonFx.hearts(actors, at, amount if amount > 0 else 5)
		&"leaves":
			ToonFx.leaves(actors, at, amount if amount > 0 else 16)
		&"streaks":
			ToonFx.streaks(actors, at, amount if amount > 0 else 10)
		&"confetti":
			# El papel picado cae por delante del mundo y por detrás del globo de diálogo.
			move_child(ToonFx.confetti(self, size.x, amount if amount > 0 else 80), _bubble.get_index())
		_:
			push_warning("Corto: efecto desconocido «%s»." % beat["fx"])


## Cartel con título y subtítulo, centrado, que entra y sale.
func _beat_title(beat: Dictionary) -> void:
	var card := VBoxContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_bottom = -size.y * float(beat.get("lift", 0.3))
	card.add_theme_constant_override("separation", 4)
	if beat.has("subtitle"):
		var small := _card_label(str(beat["subtitle"]), 30, Color("#FFE9A8"))
		card.add_child(small)
	card.add_child(_card_label(str(beat["title"]), int(beat.get("size", 64)), Color("#FFFDF6")))
	add_child(card)
	move_child(card, _bubble.get_index())
	card.modulate.a = 0.0
	Sounds.play(&"title", 1.0, -3.0)
	var tween := card.create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.5)
	tween.tween_interval(float(beat.get("time", 2.2)))
	tween.tween_property(card, "modulate:a", 0.0, 0.5)
	tween.tween_callback(card.queue_free)
	if not beat.get("join", false):
		await _pause(float(beat.get("time", 2.2)) + 0.6)


func _card_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", ThemeDB.get_project_theme().get_font("font", &"Button"))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#3A2418"))
	label.add_theme_constant_override("outline_size", maxi(8, font_size / 5))
	return label

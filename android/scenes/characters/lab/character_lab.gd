class_name CharacterLab
extends Control
## Laboratorio de personajes: un escenario para ver y probar cada títere con todos sus gestos,
## caras y emotes. Se abre con `--lab` (o `--demo-lab` para que se recorra solo, útil para grabar).
## Aquí se revisa un personaje nuevo antes de ponerlo en una escena del juego.

signal back_requested

const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")
const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const EMOTES: Array[StringName] = [&"heart", &"alert", &"question", &"idea", &"note", &"zzz", &"sweat", &"anger",
	&"dizzy", &"sparkle"]
const PANEL_WIDTH := 470.0
const CAST := [
	{"id": &"quwi", "name": "Quwi", "scale": 1.45},
	{"id": &"girl", "name": "Niña", "scale": 1.12},
	{"id": &"boy", "name": "Niño", "scale": 1.12},
	{"id": &"atoq", "name": "Atoq", "scale": 1.5},
	{"id": &"coco", "name": "Coco", "scale": 1.25},
]
const GIRL := {"body": "girl", "skin": 2, "hair_color": 0, "top_color": 0, "bottom_color": 2, "hair_style": 3}
const GIRL_TAIL := {"body": "girl", "skin": 3, "hair_color": 1, "top_color": 5, "bottom_color": 6, "hair_style": 4}
const BOY := {"body": "boy", "skin": 3, "hair_color": 0, "top_color": 3, "bottom_color": 7, "hair_style": 2}

## Recorre solo a todos los personajes al abrir (modo demostración).
var auto_tour := false

var _stage: Node2D
var _puppet: Puppet
var _current := 0
var _girl_tail := false
var _moves: HFlowContainer
var _faces: HFlowContainer
var _emotes: HFlowContainer
var _chips: Array[Button] = []
var _run: HSlider
var _title: Label
var _demo: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := SierraBackdrop.new()
	backdrop.show_near = false
	add_child(backdrop)
	_stage = Node2D.new()
	add_child(_stage)
	_build_panel()
	resized.connect(_place)
	_show(0)
	if auto_tour:
		demo_tour()


func _build_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -PANEL_WIDTH - 20.0
	panel.offset_right = -20.0
	panel.offset_top = 20.0
	panel.offset_bottom = -20.0
	add_child(panel)
	var column := Ui.vbox(10)
	panel.add_child(column)
	var header := Ui.hbox(10)
	var back := Ui.compact(Ui.button("Salir", "back", &"GhostButton"), 20)
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	_title = Ui.label("Laboratorio", &"CardTitle")
	header.add_child(_title)
	column.add_child(header)
	var cast := HFlowContainer.new()
	cast.add_theme_constant_override("h_separation", 6)
	cast.add_theme_constant_override("v_separation", 6)
	var group := ButtonGroup.new()
	for i in CAST.size():
		var chip := Ui.chip(CAST[i]["name"], group)
		chip.custom_minimum_size.y = 46
		chip.add_theme_font_size_override("font_size", 20)
		chip.pressed.connect(_show.bind(i))
		cast.add_child(chip)
		_chips.append(chip)
	column.add_child(cast)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var body := Ui.vbox(8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	body.add_child(Ui.label("Gestos", &"FieldLabel"))
	_moves = _flow(body)
	body.add_child(Ui.label("Caras", &"FieldLabel"))
	_faces = _flow(body)
	body.add_child(Ui.label("Emotes", &"FieldLabel"))
	_emotes = _flow(body)
	for kind in EMOTES:
		_add_button(_emotes, String(kind), func() -> void: _puppet.emote(kind, 1.8))
	body.add_child(Ui.label("Correr", &"FieldLabel"))
	_run = HSlider.new()
	_run.min_value = 0.0
	_run.max_value = 2.2
	_run.step = 0.05
	_run.custom_minimum_size.y = 36
	_run.value_changed.connect(_set_run)
	body.add_child(_run)
	var toggles := _flow(body)
	_add_button(toggles, "Hablar", func() -> void: _puppet.talk(not _puppet.face.talking))
	_add_button(toggles, "Voltear", func() -> void: _puppet.facing = -_puppet.facing)
	_add_button(toggles, "Saltar", func() -> void: _puppet.hop(60.0))
	_add_button(toggles, "Otro peinado", func() -> void:
		_girl_tail = not _girl_tail
		if CAST[_current]["id"] == &"girl":
			_show(_current))
	var hint := Ui.label("Tócalo, acarícialo o mueve el dedo por la pantalla: te sigue con la mirada.", &"Hint",
		HORIZONTAL_ALIGNMENT_LEFT, true, PANEL_WIDTH - 60.0)
	body.add_child(hint)


func _flow(parent: Control) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	parent.add_child(flow)
	return flow


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Ui.compact(Ui.button(text, "", &"GhostButton"), 18)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _show(index: int) -> void:
	_current = index
	_chips[index].set_pressed_no_signal(true)
	if _puppet:
		_puppet.queue_free()
	var entry: Dictionary = CAST[index]
	match entry["id"]:
		&"quwi":
			_puppet = QUWI.instantiate()
		&"girl", &"boy":
			var avatar: AvatarCharacter = AVATAR.instantiate()
			var traits: Dictionary = BOY if entry["id"] == &"boy" else (GIRL_TAIL if _girl_tail else GIRL)
			avatar.apply(AvatarPalette.look_for(traits))
			_puppet = avatar
		&"atoq":
			_puppet = AtoqCharacter.new()
		_:
			_puppet = CaimanCharacter.new()
	_puppet.scale = Vector2.ONE * float(entry["scale"])
	_puppet.interactive = true
	_stage.add_child(_puppet)
	_title.text = "Laboratorio · %s" % entry["name"]
	_run.set_value_no_signal(0.0)
	_place()
	for child in _moves.get_children():
		child.queue_free()
	for child in _faces.get_children():
		child.queue_free()
	var names: Array[StringName] = _puppet.own_clips()
	for library_clip in PuppetMoves.names():
		if not names.has(library_clip):
			names.append(library_clip)
	for clip_name in names:
		_add_button(_moves, String(clip_name), func() -> void: _puppet.play(clip_name))
	for expression in _puppet.expressions():
		_add_button(_faces, String(expression), func() -> void: _puppet.express(expression, 2.2))
	_puppet.hop(40.0)


func _place() -> void:
	if _puppet == null:
		return
	var view := size if size.x > 64.0 else Vector2(1280, 800)
	var floor_y := view.y * 0.5 + 262.0
	if CAST[_current]["id"] == &"coco":
		floor_y -= 20.0
	_puppet.position = Vector2((view.x - PANEL_WIDTH - 20.0) * 0.5, floor_y)
	_puppet.settle()


func _set_run(value: float) -> void:
	if _puppet is AvatarCharacter:
		(_puppet as AvatarCharacter).run_speed = value
	elif _puppet is AtoqCharacter:
		(_puppet as AtoqCharacter).speed = value
	elif _puppet is CaimanCharacter:
		(_puppet as CaimanCharacter).swim = value / 2.2
	else:
		_puppet.travel = Vector2(value * 160.0, 0.0)


# --- Recorrido automático (modo demostración) ----------------------------------------------------

## Recorre solo a todos los personajes: gestos, caras, carrera y la mirada que sigue un punto.
func demo_tour() -> void:
	if _demo:
		_demo.kill()
	_demo = create_tween()
	for index in CAST.size():
		_demo.tween_callback(_show.bind(index))
		_demo.tween_interval(1.2)
		_demo.tween_callback(func() -> void: _tour_character())
		_demo.tween_interval(13.0)


func _tour_character() -> void:
	var tour := create_tween()
	var clips: Array[StringName] = _puppet.own_clips()
	var puppet := _puppet
	# La mirada sigue un punto que da una vuelta.
	tour.tween_method(func(t: float) -> void:
		if is_instance_valid(puppet):
			puppet.look_at_point(puppet.global_position + Vector2(cos(t * TAU), sin(t * TAU) * 0.6) * 420.0 + Vector2(0, -200), 0.3),
		0.0, 1.0, 1.8)
	for i in mini(4, clips.size()):
		var clip_name := clips[i]
		tour.tween_callback(func() -> void:
			if is_instance_valid(puppet):
				puppet.play(clip_name))
		tour.tween_interval(1.7)
	tour.tween_callback(func() -> void:
		if is_instance_valid(puppet):
			_fake_tap(puppet))
	tour.tween_interval(1.5)
	tour.tween_callback(func() -> void:
		if is_instance_valid(puppet):
			_run.value = 1.6)
	tour.tween_interval(1.8)
	tour.tween_callback(func() -> void:
		if is_instance_valid(puppet):
			_run.value = 0.0
			puppet.play(&"flip"))


## Un toque de verdad sobre el personaje: prueba el camino completo del dedo.
func _fake_tap(puppet: Puppet) -> void:
	var at := puppet.global_position + (puppet.hit_rect.get_center() * puppet.scale)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		await get_tree().process_frame

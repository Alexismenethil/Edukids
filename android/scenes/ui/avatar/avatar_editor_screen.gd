class_name AvatarEditorScreen
extends Control
## «¡Crea tu personaje!» (RF-31 y CU-11): niña o niño, piel, peinado, cabello y ropa.
## El personaje reacciona a cada cambio. Vista humilde: guarda a través del presentador.

signal finished
signal back_requested

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")

var _presenter: AvatarEditorPresenter
var _view_model: AvatarEditorViewModel
var _traits: Dictionary = {}
var _avatar: AvatarCharacter
var _rug: WovenRug
var _card: PanelContainer
var _greeting: Label
var _bottom_caption: Label
var _girl: Button
var _boy: Button
var _groups := {}
var _tiles: Array[HairStyleTile] = []
var _confetti: CPUParticles2D
var _saving := false


func setup(presenter: AvatarEditorPresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(SierraBackdrop.new())
	_view_model = _presenter.editor()
	_traits = _view_model.traits.duplicate()
	_build_stage()
	_build_card()
	_build_confetti()
	_sync_controls()
	_refresh_look(false)
	Ui.pop_in(_card, 0.15)
	_avatar.hop(30.0)
	var later := create_tween()
	later.tween_interval(0.6)
	later.tween_callback(_avatar.wave)


## Para el modo demostración: aplica un personaje al azar.
func surprise() -> void:
	_on_surprise()


## Para el modo demostración: elige un rasgo.
func pick(trait_name: String, value: Variant) -> void:
	_set_trait(trait_name, value)
	_sync_controls()


func save() -> void:
	_on_done()


func _build_stage() -> void:
	var back := Ui.button(_view_model.back_label, "back", &"SoftButton")
	back.position = Vector2(24, 22)
	back.pressed.connect(func() -> void: back_requested.emit())
	add_child(back)

	var stage := Control.new()
	stage.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	stage.offset_right = 520
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	var ribbon := PanelContainer.new()
	ribbon.theme_type_variation = &"RibbonPanel"
	var title := Ui.label(_view_model.title, &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_size_override("font_size", 36)
	ribbon.add_child(title)
	ribbon.position = Vector2(56, 134)
	stage.add_child(ribbon)
	_greeting = Ui.label(_view_model.greeting, &"SubtitleLabel", HORIZONTAL_ALIGNMENT_CENTER, true)
	_greeting.add_theme_font_size_override("font_size", 24)
	_greeting.custom_minimum_size.x = 420
	_greeting.position = Vector2(50, 212)
	stage.add_child(_greeting)
	_rug = WovenRug.new()
	_rug.radius = Vector2(160, 36)
	stage.add_child(_rug)
	_avatar = AVATAR.instantiate()
	_avatar.scale = Vector2.ONE * 1.12
	_avatar.shadow_scale = 0.0
	stage.add_child(_avatar)
	var layout := func() -> void:
		var feet := Vector2(270, stage.size.y - 70)
		_rug.position = feet
		_avatar.position = feet
	stage.resized.connect(layout)
	layout.call_deferred()


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.theme_type_variation = &"CardPanel"
	_card.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH
	_card.offset_right = -36
	var rows := Ui.vbox(14)
	var body_group := ButtonGroup.new()
	_girl = Ui.chip(_view_model.girl_label, body_group)
	_boy = Ui.chip(_view_model.boy_label, body_group)
	_girl.custom_minimum_size.x = 150
	_boy.custom_minimum_size.x = 150
	_girl.toggled.connect(func(on: bool) -> void:
		if on:
			_set_trait("body", "girl"))
	_boy.toggled.connect(func(on: bool) -> void:
		if on:
			_set_trait("body", "boy"))
	rows.add_child(_row(_view_model.body_label, [_girl, _boy]))
	rows.add_child(_row(_view_model.skin_label, _swatches("skin", _view_model.skin_colors)))
	var style_group := ButtonGroup.new()
	var tiles: Array[Control] = []
	for index in _view_model.hair_style_names.size():
		var tile := HairStyleTile.new()
		tile.style_index = index
		tile.button_group = style_group
		tile.tooltip_text = _view_model.hair_style_names[index]
		tile.toggled.connect(func(on: bool) -> void:
			if on:
				_set_trait("hair_style", index))
		_tiles.append(tile)
		tiles.append(tile)
	_groups["hair_style"] = style_group
	rows.add_child(_row(_view_model.hair_style_label, tiles))
	rows.add_child(_row(_view_model.hair_color_label, _swatches("hair_color", _view_model.hair_colors)))
	rows.add_child(_row(_view_model.top_label, _swatches("top_color", _view_model.outfit_colors)))
	var bottom_row := _row(_presenter.bottom_label(_traits), _swatches("bottom_color", _view_model.outfit_colors))
	_bottom_caption = bottom_row.get_child(0) as Label
	rows.add_child(bottom_row)
	var surprise := Ui.button(_view_model.surprise_label, "dice", &"SoftButton")
	surprise.pressed.connect(_on_surprise)
	var done := Ui.button(_view_model.done_label, "check")
	done.pressed.connect(_on_done)
	var actions := Ui.hbox(16, [surprise, Ui.spacer(), done])
	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	rows.add_child(gap)
	rows.add_child(actions)
	_card.add_child(rows)
	add_child(_card)


func _row(caption: String, controls: Array) -> HBoxContainer:
	var label := Ui.label(caption, &"FieldLabel")
	label.custom_minimum_size.x = 112
	label.add_theme_font_size_override("font_size", 24)
	var row := Ui.hbox(10, [label])
	for control: Control in controls:
		row.add_child(control)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	return row


func _swatches(trait_name: String, colors: Array[Color]) -> Array[Control]:
	var group := ButtonGroup.new()
	_groups[trait_name] = group
	var buttons: Array[Control] = []
	for index in colors.size():
		var swatch := SwatchButton.new()
		swatch.color = colors[index]
		swatch.button_group = group
		swatch.toggled.connect(func(on: bool) -> void:
			if on:
				_set_trait(trait_name, index))
		buttons.append(swatch)
	return buttons


func _build_confetti() -> void:
	_confetti = CPUParticles2D.new()
	_confetti.emitting = false
	_confetti.one_shot = true
	_confetti.amount = 60
	_confetti.lifetime = 1.6
	_confetti.explosiveness = 0.95
	_confetti.direction = Vector2(0, -1)
	_confetti.spread = 70.0
	_confetti.initial_velocity_min = 380.0
	_confetti.initial_velocity_max = 620.0
	_confetti.gravity = Vector2(0, 900)
	_confetti.angular_velocity_min = -360.0
	_confetti.angular_velocity_max = 360.0
	_confetti.scale_amount_min = 6.0
	_confetti.scale_amount_max = 11.0
	var ramp := Gradient.new()
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	ramp.colors = PackedColorArray([Color("#E8833A"), Color("#3B7DD8"), Color("#3FA34D"), Color("#C2185B"), Color("#F2C14E")])
	_confetti.color_initial_ramp = ramp
	add_child(_confetti)


func _set_trait(trait_name: String, value: Variant) -> void:
	if _traits.get(trait_name) == value:
		return
	_traits[trait_name] = value
	_refresh_look(true, trait_name)


func _sync_controls() -> void:
	_girl.set_pressed_no_signal(str(_traits.get("body")) == "girl")
	_boy.set_pressed_no_signal(str(_traits.get("body")) == "boy")
	for trait_name: String in _groups:
		var buttons: Array[BaseButton] = (_groups[trait_name] as ButtonGroup).get_buttons()
		for index in buttons.size():
			var selected := index == int(_traits.get(trait_name, -1))
			if buttons[index].button_pressed != selected:
				buttons[index].set_pressed_no_signal(selected)


func _refresh_look(react: bool, trait_name: String = "") -> void:
	var look := _presenter.look(_traits)
	_avatar.apply(look)
	for tile in _tiles:
		tile.show_look(look)
	_bottom_caption.text = _presenter.bottom_label(_traits)
	if not react:
		return
	if trait_name in ["body", "hair_style"]:
		_avatar.hop(22.0)
	else:
		var tween := _avatar.create_tween()
		tween.tween_property(_avatar, "squash", Vector2(1.06, 0.95), 0.08)
		tween.tween_property(_avatar, "squash", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_surprise() -> void:
	_traits = _presenter.surprise(_traits)
	_sync_controls()
	_refresh_look(true, "body")
	_avatar.wave()


func _on_done() -> void:
	if _saving:
		return
	var feedback := _presenter.save(_traits)
	if not feedback.ok:
		_greeting.text = feedback.errors.get("general", "")
		return
	_saving = true
	_avatar.celebrate()
	_confetti.global_position = _avatar.global_position + Vector2(0, -260)
	_confetti.restart()
	var later := create_tween()
	later.tween_interval(1.5)
	later.tween_callback(func() -> void: finished.emit())

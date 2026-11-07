class_name StudentHomeScreen
extends Control
## Inicio del estudiante: su personaje saluda junto a Quwi y, al lado, los niveles para practicar
## con sus estrellas. El mapa de la aventura los reemplazará en el Sprint 5.

signal edit_avatar_requested
signal exit_requested
signal level_requested

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")

var _presenter: StudentHomePresenter
var _avatar: AvatarCharacter
var _quwi: QuwiCharacter
var _rug: WovenRug
var _stage: Control
var _levels: VBoxContainer


func setup(presenter: StudentHomePresenter) -> void:
	_presenter = presenter


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(SierraBackdrop.new())
	var view_model := _presenter.home()
	var exit := Ui.button(view_model.exit_label, "exit", &"SoftButton")
	exit.position = Vector2(24, 22)
	exit.pressed.connect(func() -> void:
		_presenter.log_out()
		exit_requested.emit())
	add_child(exit)
	var edit := Ui.button(view_model.edit_label, "edit", &"SoftButton")
	edit.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	edit.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	edit.offset_right = -24
	edit.offset_top = 22
	edit.pressed.connect(func() -> void: edit_avatar_requested.emit())
	add_child(edit)

	var top := Ui.vbox(8)
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.offset_top = 96
	var ribbon := PanelContainer.new()
	ribbon.theme_type_variation = &"RibbonPanel"
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var greeting := Ui.label(view_model.greeting, &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER)
	greeting.add_theme_font_size_override("font_size", 46)
	ribbon.add_child(greeting)
	top.add_child(ribbon)
	var message := Ui.label(view_model.message, &"SubtitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	message.add_theme_font_size_override("font_size", 26)
	top.add_child(message)
	add_child(top)
	Ui.pop_in(ribbon, 0.1)

	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)
	move_child(_stage, 1)
	_rug = WovenRug.new()
	_rug.radius = Vector2(130, 30)
	_stage.add_child(_rug)
	_avatar = AVATAR.instantiate()
	_avatar.shadow_scale = 0.0
	_stage.add_child(_avatar)
	_avatar.apply(view_model.look)
	_quwi = QUWI.instantiate()
	_quwi.scale = Vector2(0.78, 0.78)
	_stage.add_child(_quwi)
	_levels = _make_levels(view_model)
	add_child(_levels)
	_stage.resized.connect(_layout_stage)
	_layout_stage.call_deferred()
	var later := create_tween()
	later.tween_interval(0.35)
	later.tween_callback(func() -> void:
		_avatar.hop(30.0)
		_avatar.wave()
		_quwi.wave())


func _layout_stage() -> void:
	var left := minf(_stage.size.x * 0.24, 330.0)
	var ground := _stage.size.y - 92
	_rug.position = Vector2(left, ground)
	_avatar.position = Vector2(left, ground)
	_quwi.position = Vector2(left + 190, ground + 6)
	_levels.reset_size()
	_levels.position = Vector2(_stage.size.x - _levels.size.x - 40, maxf(214.0, (_stage.size.y - _levels.size.y) * 0.5 + 60.0))


func _make_levels(view_model: StudentHomeViewModel) -> VBoxContainer:
	var column := Ui.vbox(14)
	var title := Ui.label(view_model.levels_title, &"HeadingLabel")
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	for index in view_model.levels.size():
		var model := view_model.levels[index]
		var card := LevelCard.new(model)
		card.tapped.connect(func() -> void:
			_presenter.choose(model)
			level_requested.emit())
		column.add_child(card)
		Ui.pop_in(card, 0.25 + 0.1 * index)
	return column

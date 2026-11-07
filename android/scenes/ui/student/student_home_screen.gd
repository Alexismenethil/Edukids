class_name StudentHomeScreen
extends Control
## Inicio del estudiante: su personaje saluda junto a Quwi. Mientras el mapa de la aventura
## llega (Sprint 5), un letrero lo anuncia. Vista humilde.

signal edit_avatar_requested
signal exit_requested

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const QUWI := preload("res://scenes/characters/quwi/quwi.tscn")

var _presenter: StudentHomePresenter
var _avatar: AvatarCharacter
var _quwi: QuwiCharacter
var _rug: WovenRug
var _stage: Control
var _sign: Control


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
	_sign = _make_sign(view_model.sign_title, view_model.sign_text)
	_stage.add_child(_sign)
	_stage.resized.connect(_layout_stage)
	_layout_stage.call_deferred()
	var later := create_tween()
	later.tween_interval(0.35)
	later.tween_callback(func() -> void:
		_avatar.hop(30.0)
		_avatar.wave()
		_quwi.wave())


func _layout_stage() -> void:
	var middle := _stage.size.x * 0.5
	var ground := _stage.size.y - 96
	_rug.position = Vector2(middle - 150, ground)
	_avatar.position = Vector2(middle - 150, ground)
	_quwi.position = Vector2(middle + 70, ground + 6)
	_sign.position = Vector2(middle + 230, ground - 300)


func _make_sign(title: String, text: String) -> Control:
	var sign := Control.new()
	sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var post := ColorRect.new()
	post.color = Color("#7A4A2A")
	post.position = Vector2(118, 120)
	post.size = Vector2(22, 190)
	sign.add_child(post)
	var board := PanelContainer.new()
	var wood := StyleBoxFlat.new()
	wood.bg_color = Color("#B07A4C")
	wood.border_color = Color("#5A2E16")
	wood.set_border_width_all(5)
	wood.border_width_bottom = 10
	wood.set_corner_radius_all(18)
	wood.content_margin_left = 26
	wood.content_margin_right = 26
	wood.content_margin_top = 14
	wood.content_margin_bottom = 18
	wood.shadow_color = Color(0.16, 0.13, 0.12, 0.3)
	wood.shadow_size = 10
	wood.shadow_offset = Vector2(0, 6)
	board.add_theme_stylebox_override("panel", wood)
	board.rotation = -0.04
	var heading := Ui.label(title, &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	heading.add_theme_color_override("font_color", Color("#FFF4E4"))
	heading.add_theme_font_size_override("font_size", 28)
	var soon := Ui.label(text, &"BannerLabel", HORIZONTAL_ALIGNMENT_CENTER)
	soon.add_theme_font_size_override("font_size", 34)
	board.add_child(Ui.vbox(2, [heading, soon]))
	board.position = Vector2(0, 40)
	sign.add_child(board)
	return sign

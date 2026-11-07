class_name StudentCard
extends Control
## Tarjeta de un estudiante: su personaje de pie sobre un tapete tejido y su nombre en una
## cinta. Quien todavía no creó su personaje aparece como silueta con un signo de pregunta.

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const LOCK_ICON := preload("res://assets/art/ui/ui_icon_lock.svg")
const CARD_SIZE := Vector2(210, 436)
const FEET := Vector2(105, 336)
const AVATAR_SCALE := 0.64

var card: ProfileCardViewModel
var avatar: AvatarCharacter
var _rug: WovenRug
var _index := 0
var _mystery: Control
var _time := 0.0


func setup(view_model: ProfileCardViewModel, index: int) -> void:
	card = view_model
	_index = index


func _ready() -> void:
	custom_minimum_size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rug = WovenRug.new()
	_rug.position = FEET
	_rug.radius = Vector2(82, 20)
	_rug.palette_shift = _index
	add_child(_rug)
	avatar = AVATAR.instantiate()
	avatar.position = FEET
	avatar.scale = Vector2.ONE * AVATAR_SCALE
	avatar.shadow_scale = 0.0
	add_child(avatar)
	avatar.apply(card.look)
	_add_name_ribbon()
	if not card.has_avatar:
		_add_mystery_mark()
	if card.locked:
		_add_lock_badge()


func _process(delta: float) -> void:
	if _mystery:
		_time += delta
		_mystery.position.y = 34.0 + sin(_time * 2.4 + _index) * 5.0


## Dónde están los pies del personaje, en coordenadas globales.
func feet_global() -> Vector2:
	return avatar.global_position


func react() -> void:
	avatar.hop(20.0)
	avatar.wave()


func set_highlight(on: bool) -> void:
	_rug.highlighted = on
	var tween := create_tween()
	pivot_offset = Vector2(FEET.x, CARD_SIZE.y)
	tween.tween_property(self, "scale", Vector2.ONE * (1.06 if on else 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _add_name_ribbon() -> void:
	var ribbon := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FFF8EC")
	style.border_color = Color("#5A2E16")
	style.set_border_width_all(3)
	style.border_width_bottom = 6
	style.set_corner_radius_all(20)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 8
	style.shadow_color = Color(0.16, 0.13, 0.12, 0.25)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	ribbon.add_theme_stylebox_override("panel", style)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines := Ui.vbox(-4)
	var first := Ui.label(card.first_line, &"NameCardLabel", HORIZONTAL_ALIGNMENT_CENTER)
	first.add_theme_font_size_override("font_size", 27)
	first.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lines.add_child(first)
	if not card.second_line.is_empty():
		var second := Ui.label(card.second_line, &"HintLabel", HORIZONTAL_ALIGNMENT_CENTER)
		second.add_theme_font_size_override("font_size", 20)
		second.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lines.add_child(second)
	ribbon.add_child(lines)
	ribbon.custom_minimum_size.x = 196
	ribbon.size = Vector2(196, 0)
	ribbon.position = Vector2((CARD_SIZE.x - 196) * 0.5, 358)
	add_child(ribbon)


func _add_mystery_mark() -> void:
	_mystery = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FFFFFF")
	style.border_color = Color("#1F7A70")
	style.set_border_width_all(4)
	style.set_corner_radius_all(30)
	style.content_margin_left = 14
	style.content_margin_right = 14
	_mystery.add_theme_stylebox_override("panel", style)
	_mystery.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mark := Ui.label("?", &"HeadingLabel", HORIZONTAL_ALIGNMENT_CENTER)
	mark.add_theme_color_override("font_color", Color("#1F7A70"))
	mark.add_theme_font_size_override("font_size", 34)
	_mystery.add_child(mark)
	_mystery.position = Vector2(FEET.x + 26, 34)
	add_child(_mystery)


func _add_lock_badge() -> void:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"BadgeAlert"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lock := TextureRect.new()
	lock.texture = LOCK_ICON
	lock.custom_minimum_size = Vector2(26, 26)
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.add_child(lock)
	badge.position = Vector2(CARD_SIZE.x - 64, 70)
	add_child(badge)

class_name HairStyleTile
extends Button
## Botón de peinado del editor: muestra la cabeza del personaje con ese peinado.

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")
const OUTLINE := Color("#5A2E16")
const RING := Color("#1F7A70")
const TILE := Vector2(72, 72)

var style_index := 0
var _avatar: AvatarCharacter
var _grow := 0.0


func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_contents = true
	custom_minimum_size = TILE
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())


func _ready() -> void:
	_avatar = AVATAR.instantiate()
	_avatar.lively = false
	_avatar.shadow_scale = 0.0
	_avatar.scale = Vector2.ONE * 0.27
	_avatar.position = Vector2(TILE.x * 0.5, TILE.y * 0.5 + 300 * 0.27 - 2)
	_avatar.show_behind_parent = false
	add_child(_avatar)


func _process(delta: float) -> void:
	var goal := 1.0 if button_pressed else 0.0
	if not is_equal_approx(_grow, goal):
		_grow = move_toward(_grow, goal, delta * 7.0)
		queue_redraw()


func show_look(look: AvatarLookViewModel) -> void:
	var copy := AvatarLookViewModel.new()
	copy.is_girl = look.is_girl
	copy.skin = look.skin
	copy.hair = look.hair
	copy.top = look.top
	copy.bottom = look.bottom
	copy.hair_style = style_index
	if _avatar:
		_avatar.apply(copy)


func _draw() -> void:
	var rect := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#E9F4F8")
	box.set_corner_radius_all(18)
	box.border_color = RING if _grow > 0.5 else Color(OUTLINE, 0.25)
	box.set_border_width_all(3 + int(_grow * 2.0))
	draw_style_box(box, rect)

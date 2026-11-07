class_name AvatarBadge
extends Control
## Retrato redondo del personaje (la cabeza), para listas y diálogos.

const AVATAR := preload("res://scenes/characters/avatar/avatar_character.tscn")

@export var badge_size := 72.0
@export var background := Color("#DCEFF6")

var _avatar: AvatarCharacter
var _look: AvatarLookViewModel


func _ready() -> void:
	custom_minimum_size = Vector2(badge_size, badge_size)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# La cabeza (con el cabello) mide unas 190 unidades: así llena el círculo.
	var zoom := badge_size / 190.0
	_avatar = AVATAR.instantiate()
	_avatar.lively = false
	_avatar.shadow_scale = 0.0
	_avatar.scale = Vector2.ONE * zoom
	_avatar.position = Vector2(badge_size * 0.5, badge_size * 0.5 + 286.0 * zoom)
	add_child(_avatar)
	if _look:
		_avatar.apply(_look)


func show_look(look: AvatarLookViewModel) -> void:
	_look = look
	if _avatar:
		_avatar.apply(look)


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, badge_size * 0.5 - 1.0, background)
	draw_arc(center, badge_size * 0.5 - 2.0, 0.0, TAU, 40, Color("#5A2E16", 0.25), 3.0, true)

class_name KeyboardAvoider
extends Node
## Mantiene una tarjeta centrada en la pantalla aunque cambie su contenido y, en Android,
## la sube cuando el teclado de la pantalla tapa el campo que se está escribiendo.

## La tarjeta que se acomoda.
@export var target: Control
## Espacio reservado arriba (por ejemplo, para un título o una barra de avance).
@export var top_margin := 0.0
@export var margin := 24.0

var _offset := 0.0


func _process(_delta: float) -> void:
	if target == null or not target.is_visible_in_tree():
		return
	var view := target.get_viewport_rect().size
	target.size = target.get_combined_minimum_size()
	var free := view.y - top_margin
	var base := top_margin + maxf((free - target.size.y) * 0.5, 0.0)
	var wanted := 0.0
	var keyboard := DisplayServer.virtual_keyboard_get_height()
	var focused := target.get_viewport().gui_get_focus_owner()
	if keyboard > 0 and focused is LineEdit and target.is_ancestor_of(focused):
		var screen := DisplayServer.screen_get_size()
		var keyboard_top := view.y - keyboard * view.y / maxf(screen.y, 1.0)
		# Si el campo está en un bloque con su mensaje de error debajo, también se deja a la vista.
		var area: Control = focused.get_parent() if focused.get_parent() is VBoxContainer else focused
		var bottom := maxf(focused.get_global_rect().end.y, area.get_global_rect().end.y) + margin - _offset
		wanted = minf(keyboard_top - bottom, 0.0)
	_offset = lerpf(_offset, wanted, 0.35)
	target.position = Vector2((view.x - target.size.x) * 0.5, base + _offset)

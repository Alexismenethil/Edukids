class_name MarkBadge
extends Control
## Insignia redonda (o cuadrada, para marcar varias) con una letra, un número, ✓ o ✗.
## Se dibuja con código para que sea nítida en cualquier tableta.

const CHECK := preload("res://assets/art/ui/ui_icon_check.svg")
const CROSS := preload("res://assets/art/ui/ui_icon_cross.svg")

var text := "":
	set(value):
		text = value
		queue_redraw()
var accent := ActivityStyle.PRIMARY
var state: StringName = ActivityStyle.NORMAL:
	set(value):
		state = value
		queue_redraw()
## true: cuadrado redondeado (casilla de «marca varias»).
var square := false
var diameter := 46.0


func _init(label_text: String = "", badge_accent: Color = ActivityStyle.PRIMARY, is_square: bool = false,
		size_px: float = 46.0) -> void:
	text = label_text
	accent = badge_accent
	square = is_square
	diameter = size_px
	custom_minimum_size = Vector2(size_px, size_px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _draw() -> void:
	var center := size * 0.5
	var radius := diameter * 0.5
	var fill := ActivityStyle.CREAM
	var ring := ActivityStyle.LINE.darkened(0.2)
	var ink := ActivityStyle.BROWN
	match state:
		ActivityStyle.SELECTED:
			fill = accent
			ring = accent.darkened(0.25)
			ink = Color.WHITE
		ActivityStyle.RIGHT:
			fill = ActivityStyle.SUCCESS
			ring = ActivityStyle.SUCCESS.darkened(0.25)
			ink = Color.WHITE
		ActivityStyle.WRONG:
			fill = ActivityStyle.ERROR
			ring = ActivityStyle.ERROR.darkened(0.25)
			ink = Color.WHITE
	var rect := Rect2(center - Vector2(radius, radius), Vector2(diameter, diameter))
	if square:
		var box := StyleBoxFlat.new()
		box.bg_color = fill
		box.border_color = ring
		box.set_border_width_all(3)
		box.set_corner_radius_all(int(diameter * 0.26))
		box.anti_aliasing = true
		draw_style_box(box, rect)
	else:
		draw_circle(center, radius, fill)
		draw_arc(center, radius - 1.5, 0.0, TAU, 40, ring, 3.0, true)
	var icon: Texture2D = null
	if state == ActivityStyle.RIGHT or (square and state == ActivityStyle.SELECTED):
		icon = CHECK
	elif state == ActivityStyle.WRONG:
		icon = CROSS
	if icon:
		var icon_size := Vector2.ONE * diameter * 0.66
		draw_texture_rect(icon, Rect2(center - icon_size * 0.5, icon_size), false)
	elif not text.is_empty():
		var font := get_theme_default_font()
		var font_size := int(diameter * 0.5)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var ascent := font.get_ascent(font_size)
		var descent := font.get_descent(font_size)
		draw_string(font, center + Vector2(-width * 0.5, (ascent - descent) * 0.5), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)

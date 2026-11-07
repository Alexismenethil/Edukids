class_name SwatchButton
extends Button
## Muestra de color redonda para el editor del personaje. Al elegirla, crece y muestra un visto.

const OUTLINE := Color("#5A2E16")
const RING := Color("#1F7A70")

@export var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()

var _grow := 0.0


func _init() -> void:
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(56, 56)
	flat = true
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())


## La marca de elegido sigue al estado del botón, aunque se cambie sin señal.
func _process(delta: float) -> void:
	var goal := 1.0 if button_pressed else 0.0
	if not is_equal_approx(_grow, goal):
		_grow = move_toward(_grow, goal, delta * 7.0)
		queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 4.0
	if _grow > 0.01:
		draw_circle(center, radius + 3.0 * _grow, Color(RING, _grow))
	draw_circle(center + Vector2(0, 2), radius - 3.0, Color(0.2, 0.12, 0.05, 0.18))
	draw_circle(center, radius - 3.0 - 2.0 * _grow, Color.WHITE)
	draw_circle(center, radius - 7.0 - 2.0 * _grow, color)
	draw_arc(center, radius - 7.0 - 2.0 * _grow, 0.0, TAU, 32, Color(OUTLINE, 0.35), 2.0, true)
	if _grow > 0.5:
		var dark := color.get_luminance() > 0.6
		var mark := Color("#2A2220") if dark else Color.WHITE
		var points := PackedVector2Array([center + Vector2(-8, 0), center + Vector2(-2.5, 6), center + Vector2(9, -7)])
		draw_polyline(points, mark, 4.0, true)

class_name ActivityStyle
extends RefCounted
## Colores y estilos de las actividades, a juego con el tema de EduKids (guía de arte).
## Bien y mal nunca dependen solo del color: siempre llevan ✓ o ✗ y una animación.

const INK := Color("#2A2220")
const CREAM := Color("#FFFDF8")
const PAPER := Color("#FFF8EC")
const LINE := Color(0.353, 0.18, 0.086, 0.3)
const BROWN := Color("#5A2E16")
const PRIMARY := Color("#1F7A70")
const ACCENT := Color("#F2C14E")
const SUCCESS := Color("#2E9E5B")
const SUCCESS_SOFT := Color("#E3F4E8")
const ERROR := Color("#D1495B")
const ERROR_SOFT := Color("#FBE5E7")
const MUTED := Color("#8C8079")
## Hilos de colores textiles de la Sierra, para cuerdas y canastas.
const THREADS: Array[Color] = [Color("#C2185B"), Color("#1FA2A6"), Color("#F28C28"), Color("#6A4FB3"),
	Color("#3FA34D"), Color("#3B7DD8")]

const NORMAL := &"normal"
const SELECTED := &"selected"
const RIGHT := &"right"
const WRONG := &"wrong"


static func box(fill: Color, border: Color, bottom: int = 8, radius: int = 22, width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.border_width_bottom = maxi(bottom, width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.anti_aliasing = true
	return style


## Relleno y borde de una tarjeta según su estado.
static func colors_for(state: StringName, accent: Color) -> Array[Color]:
	match state:
		SELECTED:
			return [accent.lerp(Color.WHITE, 0.84), accent]
		RIGHT:
			return [SUCCESS_SOFT, SUCCESS]
		WRONG:
			return [ERROR_SOFT, ERROR]
	return [CREAM, LINE]


static func label(text: String, size: int = 26, color: Color = INK, wrap: bool = true, min_width: float = 0.0) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size.x = min_width
	return result


## Pequeño salto de una tarjeta al tocarla o al recibir algo.
static func pop(control: Control, amount: float = 0.08) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2.ONE * (1.0 + amount), 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Sacudida suave de «no»: nunca regaña, solo avisa.
static func shake(control: Control) -> void:
	var origin := control.position
	var tween := control.create_tween()
	for offset in [10.0, -8.0, 6.0, -4.0, 0.0]:
		tween.tween_property(control, "position:x", origin.x + offset, 0.05)

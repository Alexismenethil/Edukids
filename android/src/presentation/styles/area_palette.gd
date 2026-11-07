class_name AreaPalette
extends RefCounted
## Color, icono y nombre de cada área (guía de arte). Cada área se reconoce por su color
## y por su icono: nudos para Matemática, libro para Comunicación y hoja con lupa para Ciencia.
## `deep` es el tono oscuro que lleva texto blanco con buen contraste (WCAG AA).

const NAMES := {&"math": "Matemática", &"language": "Comunicación", &"science": "Ciencia y Tecnología"}
const COLORS := {&"math": Color("#E8833A"), &"language": Color("#3B7DD8"), &"science": Color("#3FA34D")}
const DEEP := {&"math": Color("#B4561A"), &"language": Color("#2A5EA8"), &"science": Color("#2B7A37")}
const ICONS := {&"math": "area_math", &"language": "area_language", &"science": "area_science"}


static func name_of(area: StringName) -> String:
	return NAMES.get(area, "")


static func color_of(area: StringName) -> Color:
	return COLORS.get(area, Color("#1F7A70"))


static func deep_of(area: StringName) -> Color:
	return DEEP.get(area, Color("#1F7A70"))


static func icon_of(area: StringName) -> String:
	return ICONS.get(area, "star")

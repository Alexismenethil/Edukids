class_name AvatarPalette
extends RefCounted
## Colores del avatar (RF-31). El dominio guarda índices; aquí se decide cómo se ven.
## Los tonos de piel van de claro a oscuro, sin caricaturas (guía de arte: representación cultural).
## Cada color es el tono iluminado: el dibujo lo oscurece un poco en la base y más en las sombras.

const SKIN: Array[Color] = [
	Color("#FCE3CF"), Color("#F4CDA8"), Color("#E3AF83"),
	Color("#CC9364"), Color("#A97048"), Color("#7C4C2F"),
]
const HAIR: Array[Color] = [
	Color("#3A2C28"), Color("#553828"), Color("#7A4B30"), Color("#A65E33"), Color("#C9944F"),
]
## Colores textiles de la Sierra para la chompa, el pantalón y la falda.
const OUTFIT: Array[Color] = [
	Color("#D02466"), Color("#F7922F"), Color("#22AEB2"), Color("#4286E8"),
	Color("#45AF53"), Color("#F7C955"), Color("#8A63D2"), Color("#50699A"),
]
const SILHOUETTE := Color("#B4C8D8")
const HAIR_STYLE_NAMES: Array[String] = ["Corto", "Rulos", "Erizo", "Trenzas", "Cola", "Melena"]
## Peinado y ropa de la silueta de quien todavía no tiene personaje.
const SILHOUETTE_STYLE := 0


## Aspecto de un avatar a partir de sus rasgos. Sin rasgos, devuelve la silueta.
static func look_for(traits: Dictionary) -> AvatarLookViewModel:
	var look := AvatarLookViewModel.new()
	if traits.is_empty():
		look.silhouette = true
		look.hair_style = SILHOUETTE_STYLE
		look.skin = SILHOUETTE
		look.hair = SILHOUETTE
		look.top = SILHOUETTE
		look.bottom = SILHOUETTE
		return look
	look.is_girl = str(traits.get("body", "")) == "girl"
	look.skin = _pick(SKIN, traits.get("skin", 0))
	look.hair = _pick(HAIR, traits.get("hair_color", 0))
	look.top = _pick(OUTFIT, traits.get("top_color", 0))
	look.bottom = _pick(OUTFIT, traits.get("bottom_color", 0))
	look.hair_style = clampi(int(traits.get("hair_style", 0)), 0, HAIR_STYLE_NAMES.size() - 1)
	return look


static func _pick(colors: Array[Color], index: Variant) -> Color:
	return colors[clampi(int(index), 0, colors.size() - 1)]

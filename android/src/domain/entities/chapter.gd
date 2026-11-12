class_name Chapter
extends RefCounted
## Capítulos del mapa y sus paradas, en el orden del camino (diseño del juego, capítulo 03).
## Los paquetes indican su capítulo y su parada en el manifiesto.

const SIERRA := &"sierra"
const SELVA := &"selva"
const COSTA := &"costa"

const STOPS := {
	SIERRA: ["huamanga", "quinua", "pampa-galeras", "vilcashuaman"],
	SELVA: ["rio-apurimac", "chacra-de-cacao", "bosque-de-neblina"],
	COSTA: ["islas-y-puerto", "nasca"],
}


static func stops_of(chapter: StringName) -> Array[String]:
	var stops: Array[String] = []
	stops.assign(STOPS.get(chapter, []))
	return stops

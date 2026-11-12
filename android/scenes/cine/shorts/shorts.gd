class_name Shorts
extends RefCounted
## Catálogo de cortos del juego. Para sumar uno: crear su guion (una clase que hereda de
## ShortScript) y agregarlo aquí.

const CATALOG := {
	&"prologue": "res://scenes/cine/shorts/short_prologue.gd",
	&"rope": "res://scenes/cine/shorts/short_rope.gd",
	&"selva": "res://scenes/cine/shorts/short_selva.gd",
	&"costa": "res://scenes/cine/shorts/short_costa.gd",
}


static func ids() -> Array[StringName]:
	var list: Array[StringName] = []
	for id: StringName in CATALOG:
		if ResourceLoader.exists(CATALOG[id]):
			list.append(id)
	return list


static func create(id: StringName) -> ShortScript:
	if not CATALOG.has(id) or not ResourceLoader.exists(CATALOG[id]):
		push_warning("Cortos: no existe «%s»." % id)
		return null
	return (load(CATALOG[id]) as GDScript).new()

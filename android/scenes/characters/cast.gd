class_name Cast
extends RefCounted
## El elenco del juego: cada personaje con su nombre visible, su escena y su tamaño habitual.
## Los cortos, el laboratorio y las escenas piden un personaje por su identificador:
##
##   var quwi := Cast.create(&"quwi")
##   var avatar := Cast.create(&"avatar", look)     # el avatar necesita su aspecto
##
## `GUIDES` dice quién guía cada capítulo del mapa.
##
## Para sumar un personaje al juego basta con agregarlo aquí (ver scenes/characters/README.md).

const ROSTER := {
	&"avatar": {"name": "", "path": "res://scenes/characters/avatar/avatar_character.tscn", "scale": 0.5, "lab": 1.12},
	&"quwi": {"name": "Quwi", "path": "res://scenes/characters/quwi/quwi.tscn", "scale": 0.62, "lab": 1.45},
	&"tunki": {"name": "Tunki", "path": "res://scenes/characters/tunki/tunki.gd", "scale": 0.62, "lab": 1.45},
	&"humbi": {"name": "Humbi", "path": "res://scenes/characters/humbi/humbi.gd", "scale": 0.62, "lab": 1.45},
	&"atoq": {"name": "Atoq", "path": "res://scenes/characters/atoq/atoq.gd", "scale": 0.72, "lab": 1.5},
	&"coco": {"name": "Coco", "path": "res://scenes/characters/caiman/caiman.gd", "scale": 1.0, "lab": 1.25},
	&"sisa": {"name": "Mama Sisa", "path": "res://scenes/characters/sisa/sisa.gd", "scale": 0.56, "lab": 1.15},
	&"condor": {"name": "Kuntur", "path": "res://scenes/characters/condor/condor.gd", "scale": 0.7, "lab": 1.2},
}

## Guía de cada capítulo.
const GUIDES := {&"sierra": &"quwi", &"selva": &"tunki", &"costa": &"humbi"}


## Guía de un capítulo (Quwi si el capítulo no tiene guía propio).
static func guide_of(chapter: StringName) -> GuideCharacter:
	return create(GUIDES.get(chapter, &"quwi")) as GuideCharacter


static func ids() -> Array[StringName]:
	var list: Array[StringName] = []
	for id: StringName in ROSTER:
		if ResourceLoader.exists(ROSTER[id]["path"]):
			list.append(id)
	return list


static func has(id: StringName) -> bool:
	return ROSTER.has(id) and ResourceLoader.exists(ROSTER[id]["path"])


## Nombre que se muestra en los globos de diálogo.
static func display_name(id: StringName) -> String:
	return ROSTER[id]["name"] if ROSTER.has(id) else String(id).capitalize()


## Tamaño habitual en una escena (`lab` = en el laboratorio).
static func size_of(id: StringName, lab: bool = false) -> float:
	if not ROSTER.has(id):
		return 1.0
	return ROSTER[id]["lab" if lab else "scale"]


## Crea el personaje. `look` viste al avatar (se ignora en los demás).
static func create(id: StringName, look: AvatarLookViewModel = null) -> Puppet:
	if not has(id):
		push_warning("Elenco: no existe el personaje «%s»." % id)
		return null
	var resource: Resource = load(ROSTER[id]["path"])
	var puppet: Puppet
	if resource is PackedScene:
		puppet = (resource as PackedScene).instantiate()
	else:
		puppet = (resource as GDScript).new()
	puppet.name = String(id).capitalize()
	if look and puppet is AvatarCharacter:
		(puppet as AvatarCharacter).apply(look)
	return puppet

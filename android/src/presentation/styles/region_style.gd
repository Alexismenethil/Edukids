class_name RegionStyle
extends RefCounted
## Cómo se presenta cada capítulo del mapa: quién lo guía y cómo se llama. El dominio guarda el
## identificador del capítulo (sierra, selva o costa); aquí se decide cómo se ve.

const GUIDES := {&"sierra": &"quwi", &"selva": &"tunki", &"costa": &"humbi"}
const GUIDE_NAMES := {&"quwi": "Quwi", &"tunki": "Tunki", &"humbi": "Humbi"}
const NAMES := {&"sierra": "Sierra", &"selva": "Selva", &"costa": "Costa"}


## Identificador del guía de un capítulo (Quwi si el capítulo no se conoce).
static func guide_of(chapter: StringName) -> StringName:
	return GUIDES.get(chapter, &"quwi")


## Nombre visible del guía de un capítulo.
static func guide_name(chapter: StringName) -> String:
	return GUIDE_NAMES[guide_of(chapter)]


static func name_of(chapter: StringName) -> String:
	return NAMES.get(chapter, "Sierra")
